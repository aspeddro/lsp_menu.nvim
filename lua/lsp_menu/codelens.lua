local cache = require("lsp_menu.cache")
local menu = require("lsp_menu.menu")

local M = {}

---@private
---@see https://github.com/neovim/neovim/blob/0b71960ab1bcbcc42f2d6abba4c72cd6ac3c840b/runtime/lua/vim/lsp/codelens.lua#L30
M.execute_lens = function(lens, bufnr, client_id)
  local client = vim.lsp.get_client_by_id(client_id)
  if not client then
    vim.notify("Client is required to execute lens", vim.log.levels.WARN)
    return
  end
  local command = lens.command
  local fn = client.commands[command.command]
    or vim.lsp.commands[command.command]
  if fn then
    fn(command, { bufnr = bufnr, client_id = client.id })
    return
  end
  local command_provider = client.server_capabilities.executeCommandProvider
  local commands = type(command_provider) == "table"
      and command_provider.commands
    or {}
  if not vim.tbl_contains(commands, command.command) then
    vim.notify(
      string.format(
        "Language server does not support command `%s`. This command may require a client extension.",
        command.command
      ),
      vim.log.levels.WARN
    )
    return
  end
  client.request("workspace/executeCommand", command, function(...)
    local result = vim.lsp.handlers["workspace/executeCommand"](...)
    vim.lsp.codelens.refresh()
    return result
  end, bufnr)
end

---Format lens
---@private
---@param lenses table
---@return string[]
M.format = function(lenses)
  local result = {}
  for index, lens in ipairs(lenses) do
    table.insert(result, string.format("[%d] %s", index, lens.command.title))
  end
  return result
end

---Run codelens
---@return nil
M.run = function()
  local bufnr = vim.api.nvim_get_current_buf()
  local linen = vim.api.nvim_win_get_cursor(0)[1]

  local lenses = vim.lsp.codelens.get(bufnr)

  local lenses_on_current_line = vim.tbl_filter(function(lens)
    return lens.range.start.line == (linen - 1)
  end, lenses)

  if vim.tbl_isempty(lenses_on_current_line) then
    vim.notify(
      "No executable codelens found at current line",
      vim.log.levels.INFO
    )
    return
  end

  local content = M.format(lenses_on_current_line)

  menu.open({
    content = content,
    on_select = function(lnum)
      M.execute_lens(lenses_on_current_line[lnum], bufnr, cache.get(bufnr))
    end
  })
end

return M
