local default = {
  close_key = "q",
  confirm_key = "<cr>",
  style = {
    border = "rounded",
  },
}

local M = {}

M.merge = function (opts)
  default = vim.tbl_deep_extend("force", {}, default, opts or {})
end

M.get = function ()
  return default
end

return M
