local autocmd = vim.api.nvim_create_autocmd

-- Dynamic terminal padding for kitty, you can apply the same logic for other terminals
autocmd("VimEnter", {
  command = ":silent !kitty @ set-spacing padding=0",
})

autocmd("VimLeavePre", {
  command = ":silent !kitty @ set-spacing padding=10",
})

-- Auto-cd to the current file's directory. compiler.nvim refuses to run
-- anything while cwd is $HOME, so this keeps it usable without a manual :cd.
autocmd("BufEnter", {
  desc = "Auto-cd to the current file's directory",
  callback = function(args)
    local bufname = vim.api.nvim_buf_get_name(args.buf)
    if bufname == "" or vim.bo[args.buf].buftype ~= "" then
      return
    end
    local dir = vim.fn.fnamemodify(bufname, ":p:h")
    if vim.fn.isdirectory(dir) == 1 then
      vim.cmd.cd(dir)
    end
  end,
})
