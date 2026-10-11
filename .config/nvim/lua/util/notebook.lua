-- Notebook helpers: keep jupytext.nvim from destroying .ipynb files, and run
-- a whole fenced code cell under molten.
--
-- Why the guard exists. jupytext.nvim reads notebook metadata with a single
-- unguarded expression (lua/jupytext/utils.lua:16):
--
--   vim.json.decode(io.open(filename, "r"):read "a")["metadata"]
--   ... metadata.kernelspec.language
--
-- Every failure mode of that line is reachable in normal use, and all three
-- were reproduced on this machine:
--
--   file does not exist  -> io.open returns nil  -> "attempt to index a nil value"
--   file is 0 bytes      -> vim.json.decode("")  -> "Expected value but found T_END"
--   no kernelspec        -> metadata.kernelspec is nil -> index a nil value
--                           (jupytext's OWN cli writes such notebooks:
--                            `jupytext --to ipynb` from markdown omits kernelspec)
--
-- The error comes from a BufReadCmd autocommand, so the buffer is never set
-- up: filetype stays empty and jupytext never attaches. Nothing warns you.
-- Write that buffer and plain markdown is saved under a .ipynb name, which no
-- notebook reader can open - the file is then silently not a notebook any
-- more. `nvim notebook.ipynb` on a new file hits this every time, which is
-- how testnb.ipynb ended up 0 bytes with its contents gone.
local M = {}

-- Minimal notebook that satisfies both jupytext and jupyter. nbformat 4.5 is
-- what jupyter itself writes; the kernelspec has to name a language because
-- that is the field jupytext indexes to choose its conversion.
local function skeleton()
  return vim.json.encode({
    cells = {},
    metadata = {
      kernelspec = { display_name = "Python 3", language = "python", name = "python3" },
      language_info = { name = "python" },
    },
    nbformat = 4,
    nbformat_minor = 5,
  })
end

---@param path string
---@return string[]|nil
local function read_lines(path)
  if vim.fn.filereadable(path) ~= 1 then
    return nil
  end
  return vim.fn.readfile(path)
end

-- Make `path` something jupytext can read, repairing in place where that is
-- lossless and refusing to guess where it is not.
---@param path string
function M.ensure_valid(path)
  path = vim.fn.resolve(vim.fn.expand(path))

  local lines = read_lines(path)

  -- Missing or empty: there is nothing to preserve, so just lay down a valid
  -- empty notebook. This does mean `nvim new.ipynb` creates the file on disk
  -- immediately rather than at first write - unavoidable, because jupytext
  -- shells out to the `jupytext` binary and that needs a real file to read.
  if not lines or #lines == 0 or table.concat(lines, "") == "" then
    vim.fn.writefile({ skeleton() }, path)
    return
  end

  local raw = table.concat(lines, "\n")
  local ok, decoded = pcall(vim.json.decode, raw)

  if not ok or type(decoded) ~= "table" then
    -- Non-empty but not JSON - almost always a previous session having saved
    -- raw markdown over the notebook. The content is real work, so it is
    -- copied aside before anything replaces it, and the path is reported
    -- rather than logged quietly.
    local backup = path:gsub("%.ipynb$", "") .. ".recovered-" .. os.date("%Y%m%d-%H%M%S") .. ".md"
    vim.fn.writefile(lines, backup)
    vim.fn.writefile({ skeleton() }, path)
    vim.schedule(function()
      vim.notify(
        ("%s was not a valid notebook.\nIts contents were saved to:\n  %s\nA blank notebook was put in its place."):format(
          vim.fn.fnamemodify(path, ":~"),
          vim.fn.fnamemodify(backup, ":~")
        ),
        vim.log.levels.WARN,
        { title = "notebook recovered" }
      )
    end)
    return
  end

  -- Valid JSON but missing the one field jupytext indexes. Patching it keeps
  -- every cell intact, so this is done silently.
  local meta = decoded.metadata
  if type(meta) ~= "table" or type(meta.kernelspec) ~= "table" or not meta.kernelspec.language then
    decoded.metadata = decoded.metadata or {}
    decoded.metadata.kernelspec =
      { display_name = "Python 3", language = "python", name = "python3" }
    vim.fn.writefile({ vim.json.encode(decoded) }, path)
  end
end

-- Find the fenced code cell the cursor sits in.
--
-- Done by scanning for ``` fences rather than with treesitter. A notebook in
-- jupytext's markdown style has exactly one level of fencing and no nesting,
-- so a scan is both sufficient and immune to the parser not having attached
-- yet - and it works identically whether or not treesitter has caught up.
--
---@param buf integer
---@param lnum integer 1-based cursor line
---@return integer|nil first 1-based first line of cell content
---@return integer|nil last  1-based last line of cell content
---@return string|nil  lang  the fence's info string, e.g. "python"
function M.cell_range(buf, lnum)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local open, lang = nil, nil
  for i, line in ipairs(lines) do
    local info = line:match("^%s*```(.*)$")
    if info ~= nil then
      if open == nil then
        open, lang = i, vim.trim(info)
      else
        -- The cursor counts as inside the cell when it is on either fence,
        -- so running from the ```python line does what you meant.
        if lnum >= open and lnum <= i then
          return open + 1, i - 1, lang
        end
        open, lang = nil, nil
      end
    end
  end
  return nil, nil, nil
end

-- Evaluate the whole cell under the cursor.
--
-- molten has no concept of a markdown cell: MoltenEvaluateLine does one line
-- and MoltenReevaluateCell only works on a span molten already knows about,
-- so neither runs a cell you just typed. Passing the fence-delimited range to
-- MoltenEvaluateRange both defines the cell and runs it.
--
-- MoltenEvaluateRange is a pynvim *function*, not a command, so it is called
-- rather than :executed, and its line arguments are 1-based inclusive (it
-- subtracts 1 internally).
function M.run_cell()
  local lnum = vim.api.nvim_win_get_cursor(0)[1]
  local first, last, lang = M.cell_range(0, lnum)

  if not first then
    vim.notify("Not inside a ``` code cell", vim.log.levels.WARN, { title = "notebook" })
    return
  end
  if last < first then
    vim.notify("Cell is empty", vim.log.levels.WARN, { title = "notebook" })
    return
  end
  if lang ~= "" and lang ~= "python" then
    vim.notify(
      ("Cell is a %s cell, not python - running it anyway under the active kernel"):format(lang),
      vim.log.levels.WARN,
      { title = "notebook" }
    )
  end

  local ok, err = pcall(vim.fn.MoltenEvaluateRange, first, last)
  if not ok then
    -- Overwhelmingly this is "no kernel": MoltenInit has to run once per
    -- buffer before anything can be evaluated, and the raw error does not say
    -- so.
    vim.notify(
      ("Could not run cell (lines %d-%d).\nRun <leader>ji to start a kernel first.\n\n%s"):format(
        first,
        last,
        tostring(err)
      ),
      vim.log.levels.ERROR,
      { title = "notebook" }
    )
  end
end

return M
