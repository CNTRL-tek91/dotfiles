-- Compile-and-run the current file, with the output in a float you can read.
--
-- LazyVim has no "run this file" binding of its own. Overseer (the editor.
-- overseer extra) covers PROJECT builds - it auto-detects make, cmake, npm and
-- so on - but the common case while learning a language is a single file that
-- is not part of any build system yet. That is what this covers; use
-- <leader>oo for real project tasks.
--
-- <leader>cr is NOT used for this: LazyVim binds it to LSP rename, and
-- inc-rename rebinds it again.
local M = {}

-- Where compiled binaries go. Deliberately under the cache dir rather than
-- beside the source, so running a file never litters a git worktree.
local function bindir()
  local d = vim.fn.stdpath("cache") .. "/run"
  vim.fn.mkdir(d, "p")
  return d
end

-- Pick the interpreter an ML project actually wants: an activated venv first,
-- then a project-local one, and only then the system python. Arch's python is
-- externally managed (PEP 668), so system-wide installs are refused - in
-- practice the venv is where the libraries will be.
function M.python()
  if vim.env.VIRTUAL_ENV and vim.env.VIRTUAL_ENV ~= "" then
    return vim.env.VIRTUAL_ENV .. "/bin/python"
  end
  local ok, root = pcall(function()
    return LazyVim.root()
  end)
  if ok and root then
    for _, name in ipairs({ ".venv", "venv" }) do
      local p = root .. "/" .. name .. "/bin/python"
      if vim.uv.fs_stat(p) then
        return p
      end
    end
  end
  return "python3"
end

-- Build the shell command for the current buffer, or nil plus a reason.
-- Returns: cmd, err
function M.command(file, ft, args, compile_only)
  local esc = vim.fn.shellescape
  args = args or ""

  if ft == "python" then
    if compile_only then
      return nil, "python is interpreted - nothing to build"
    end
    return M.python() .. " " .. esc(file) .. (args ~= "" and " " .. args or "")
  end

  if ft == "cpp" or ft == "c" then
    local cc = ft == "cpp" and "g++ -std=c++23" or "gcc -std=c23"
    local bin = bindir() .. "/" .. vim.fn.fnamemodify(file, ":t:r")
    -- -g and -O0 so the binary is debuggable with the same flags codelldb sees.
    local build = ("%s -Wall -Wextra -Wpedantic -g -O0 -o %s %s"):format(cc, esc(bin), esc(file))
    if compile_only then
      return build
    end
    return build .. " && " .. esc(bin) .. (args ~= "" and " " .. args or "")
  end

  return nil, ("no run command for filetype %q"):format(ft == "" and "none" or ft)
end

-- Run it. Keeps the float open after the process exits - otherwise a program
-- that prints and returns immediately would flash past unread.
function M.run(opts)
  opts = opts or {}
  local file = vim.api.nvim_buf_get_name(0)
  if file == "" then
    vim.notify("Buffer has no file to run", vim.log.levels.WARN)
    return
  end
  if vim.bo.modified then
    vim.cmd.write()
  end

  local args = ""
  if opts.prompt then
    args = vim.fn.input("Arguments: ")
  end

  local cmd, err = M.command(file, vim.bo.filetype, args, opts.compile_only)
  if not cmd then
    vim.notify(err, vim.log.levels.WARN)
    return
  end

  local wrapped = ("%s; printf '\\n[exit %%s] press any key to close' $?; read -n1 -s"):format(cmd)
  Snacks.terminal({ "bash", "-lc", wrapped }, {
    cwd = vim.fn.fnamemodify(file, ":h"),
    interactive = true,
    win = { position = "float", title = " run: " .. vim.fn.fnamemodify(file, ":t") .. " ", title_pos = "center" },
  })
end

return M
