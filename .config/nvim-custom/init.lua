-- Some plugins still call the deprecated `vim.lsp.get_active_clients()`, which
-- prints a warning on every startup. Point the old name at the new function so
-- the warning never fires (identical signature, so this is safe).
if vim.lsp.get_clients then
  vim.lsp.get_active_clients = vim.lsp.get_clients
end

require("core.autocommands")
require("core.options")
require("core.keymaps")
require("core.lazy")
require("core.colorscheme")
