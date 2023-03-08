local menu = require("lsp_menu.menu")

local M = {}

---@see https://github.com/neovim/neovim/blob/0b71960ab1bcbcc42f2d6abba4c72cd6ac3c840b/runtime/lua/vim/lsp/buf.lua#L122
---@private
---@return table {start={row, col}, end={row, col}} using (1, 0) indexing
local function range_from_selection()
  -- TODO: Use `vim.region()` instead https://github.com/neovim/neovim/pull/13896

  -- [bufnum, lnum, col, off]; both row and column 1-indexed
  local start = vim.fn.getpos('v')
  local end_ = vim.fn.getpos('.')
  local start_row = start[2]
  local start_col = start[3]
  local end_row = end_[2]
  local end_col = end_[3]

  -- A user can start visual selection at the end and move backwards
  -- Normalize the range to start < end
  if start_row == end_row and end_col < start_col then
    end_col, start_col = start_col, end_col
  elseif end_row < start_row then
    start_row, end_row = end_row, start_row
    start_col, end_col = end_col, start_col
  end
  return {
    ['start'] = { start_row, start_col - 1 },
    ['end'] = { end_row, end_col - 1 },
  }
end

---Format code action table
---@param tuples table
---@return string[]
M.format = function(tuples)
  local result = {}
  for index, tuple in ipairs(tuples) do
    local content = tuple[2]
    table.insert(
      result,
      string.format("[%d] %s", index, content.title:gsub("\n", ""))
    )
  end
  return result
end

---@private
---@see https://github.com/neovim/neovim/blob/0b71960ab1bcbcc42f2d6abba4c72cd6ac3c840b/runtime/lua/vim/lsp/buf.lua#L591
M.on_code_action_results = function(results, ctx, options)
  local action_tuples = {}

  ---@private
  local function action_filter(a)
    -- filter by specified action kind
    if options and options.context and options.context.only then
      if not a.kind then
        return false
      end
      local found = false
      for _, o in ipairs(options.context.only) do
        -- action kinds are hierarchical with . as a separator: when requesting only
        -- 'quickfix' this filter allows both 'quickfix' and 'quickfix.foo', for example
        if a.kind:find('^' .. o .. '$') or a.kind:find('^' .. o .. '%.') then
          found = true
          break
        end
      end
      if not found then
        return false
      end
    end
    -- filter by user function
    if options and options.filter and not options.filter(a) then
      return false
    end
    -- no filter removed this action
    return true
  end

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
        -- Not using command directly to exclude extra properties,
        -- see https://github.com/python-lsp/python-lsp-server/issues/146
        local params = {
          command = command.command,
          arguments = command.arguments,
          workDoneToken = command.workDoneToken,
        }
        client.request("workspace/executeCommand", params, nil, ctx.bufnr)
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
      and vim.tbl_get(client.server_capabilities, 'codeActionProvider', 'resolveProvider')
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
    end
  })
end

---Run code action
---@param options? table
---@return nil
---@see https://github.com/neovim/neovim/blob/0b71960ab1bcbcc42f2d6abba4c72cd6ac3c840b/runtime/lua/vim/lsp/buf.lua#L750
M.run = function(options)
  options = options or {}
  -- Detect old API call code_action(context) which should now be
  -- code_action({ context = context} )
  if options.diagnostics or options.only then
    options = { options = options }
  end
  local context = options.context or {}

  local bufnr = vim.api.nvim_get_current_buf()
  if not context.diagnostics then
    context.diagnostics = vim.lsp.diagnostic.get_line_diagnostics(bufnr)
  end
  local params
  local mode = vim.api.nvim_get_mode().mode
  if options.range then
    assert(type(options.range) == 'table', 'code_action range must be a table')
    local start = assert(options.range.start, 'range must have a `start` property')
    local end_ = assert(options.range['end'], 'range must have a `end` property')
    params = vim.lsp.util.make_given_range_params(start, end_)
  elseif mode == 'v' or mode == 'V' then
    local range = range_from_selection()
    params = vim.lsp.util.make_given_range_params(range.start, range['end'])
  else
    params = vim.lsp.util.make_range_params()
  end
  params.context = context

  local method = "textDocument/codeAction"

  vim.lsp.buf_request_all(bufnr, method, params, function(results)
    M.on_code_action_results(
      results,
      { bufnr = bufnr, method = method, params = params },
      options
    )
  end)
end

return M
