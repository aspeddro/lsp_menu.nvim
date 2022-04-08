local cache = require("lsp_menu.cache")
local codelens = require("lsp_menu.codelens")
local codeaction = require("lsp_menu.codeaction")

local M = {}

--- On attach
--- @param client table lsp client
--- @param bufnr? number buffer number
M.on_attach = function(client, bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  cache.set(bufnr, client.id)
end

M.codelens = codelens
M.codeaction = codeaction

return M
