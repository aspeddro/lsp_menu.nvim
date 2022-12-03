local config = require("lsp_menu.config")
local cache = require("lsp_menu.cache")
local codelens = require("lsp_menu.codelens")
local codeaction = require("lsp_menu.codeaction")

local M = {}

---On attach
---@param client table lsp client
---@param bufnr? number buffer number
---@param opts? table
M.on_attach = function(client, bufnr, opts)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  cache.set(bufnr, client.id)
  config.merge(opts)
end

M.codelens = codelens
M.codeaction = codeaction

return M
