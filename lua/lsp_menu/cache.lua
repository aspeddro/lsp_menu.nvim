local M = {}

-- Get client id by bufnr
local trigger_by_buf = setmetatable({}, {
  __index = function(t, b)
    local key = b > 0 and b or vim.api.nvim_get_current_buf()
    return rawget(t, key)
  end,
})

--- Get Client id by bufnr
--- @param bufnr number
--- @return number client id
M.get = function(bufnr)
  return trigger_by_buf[bufnr]
end

--- Check if buf exists in cache
--- @param bufnr number
--- @return boolean
M.has = function(bufnr)
  return M.get(bufnr) ~= nil
end

--- Set cache
--- @param bufnr number
--- @param client_id number
--- @return boolean|nil
M.set = function(bufnr, client_id)
  if M.has(bufnr) then
    return
  end
  trigger_by_buf[bufnr] = client_id
  return true
end

return M
