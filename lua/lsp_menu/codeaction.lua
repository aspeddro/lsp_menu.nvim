local menu = require("lsp_menu.menu")

local M = {}

-- Format code action table
--- @param tuples table
--- @return string[]
M.format = function(tuples)
  local result = {}
  for index, tuple in ipairs(tuples) do
    local content = tuple[2]
    table.insert(result, string.format("[%d] %s", index, content.title))
  end
  return result
end

M.on_code_action_results = function(results, ctx, opts)
  local action_tuples = {}
  for client_id, result in pairs(results) do
    for _, action in pairs(result.result or {}) do
      table.insert(action_tuples, { client_id, action })
    end
  end
  if #action_tuples == 0 then
    vim.notify("No code actions available", vim.log.levels.INFO)
    return
  end

  ---@private
  local function apply_action(action, client)
    if action.edit then
      vim.lsp.util.apply_workspace_edit(action.edit, client.offset_encoding)
    end
    if action.command then
      local command = type(action.command) == "table" and action.command
        or action
      local fn = client.commands[command.command]
        or vim.lsp.commands[command.command]
      if fn then
        local enriched_ctx = vim.deepcopy(ctx)
        enriched_ctx.client_id = client.id
        fn(command, enriched_ctx)
      else
        vim.lsp.buf.execute_command(command)
      end
    end
  end

  ---@private
  local function on_user_choice(action_tuple)
    if not action_tuple then
      return
    end
    -- textDocument/codeAction can return either Command[] or CodeAction[]
    --
    -- CodeAction
    --  ...
    --  edit?: WorkspaceEdit    -- <- must be applied before command
    --  command?: Command
    --
    -- Command:
    --  title: string
    --  command: string
    --  arguments?: any[]
    --
    local client = vim.lsp.get_client_by_id(action_tuple[1])
    local action = action_tuple[2]
    if
      not action.edit
      and client
      and type(client.resolved_capabilities.code_action) == "table"
      and client.resolved_capabilities.code_action.resolveProvider
    then
      client.request(
        "codeAction/resolve",
        action,
        function(err, resolved_action)
          if err then
            vim.notify(err.code .. ": " .. err.message, vim.log.levels.ERROR)
            return
          end
          apply_action(resolved_action, client)
        end
      )
    else
      apply_action(action, client)
    end
  end

  local content = M.format(action_tuples)

  menu.open({
    content = content,
    on_select = function(lnum)
      on_user_choice(action_tuples[lnum])
    end,
    floating = opts,
  })
end

-- Run code action
---@param opts? table floating menu options, @see |vim.lsp.util.make_floating_popup_options|
--- @return nil
M.run = function(opts)
  local bufnr = vim.api.nvim_get_current_buf()
  local context = {}
  context.diagnostics = vim.lsp.diagnostic.get_line_diagnostics()

  local params = vim.lsp.util.make_range_params()
  params.context = context

  local method = "textDocument/codeAction"

  vim.lsp.buf_request_all(bufnr, method, params, function(results)
    M.on_code_action_results(
      results,
      { bufnr = bufnr, method = method, params = params },
      opts
    )
  end)
end

return M
