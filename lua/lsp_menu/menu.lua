local config = require("lsp_menu.config")

local M = {}

---Open a floating menu
---@param opts table with fields
---            - content: string[]
---            - on_select: callback function
---@return nil
M.open = function(opts)
  opts.floating = config.get()

  local buffer_opts = {
    filetype = "markdown",
    modifiable = false,
    bufhidden = "wipe",
  }
  local win_opts = {
    foldenable = false,
  }

  local content = opts.content

  local width, height = vim.lsp.util._make_floating_popup_size(
    content,
    opts.floating.style
  )
  local floting_opts = vim.lsp.util.make_floating_popup_options(
    width,
    height,
    opts.floating.style
  )

  local bufnr = vim.api.nvim_create_buf(false, true)
  local winnr = vim.api.nvim_open_win(bufnr, true, floting_opts)

  if vim.fn.mode(1) == "v" then
    vim.api.nvim_input("<esc>")
  end

  for option, value in pairs(win_opts) do
    vim.api.nvim_win_set_option(winnr, option, value)
  end

  vim.api.nvim_buf_set_lines(bufnr, 0, -1, true, content)

  for option, value in pairs(buffer_opts) do
    vim.api.nvim_buf_set_option(bufnr, option, value)
  end

  local augroup_id = vim.api.nvim_create_augroup("LspMenu", { clear = true })

  vim.api.nvim_create_autocmd("WinLeave", {
    group = augroup_id,
    callback = function()
      if vim.api.nvim_win_is_valid(winnr) then
        vim.api.nvim_win_close(winnr, true)
      end
    end,
  })

  vim.keymap.set(
    "n",
    opts.floating.close_key,
    function ()
      vim.api.nvim_buf_delete(bufnr, { force = true })
    end,
    { buffer = bufnr }
  )

  vim.keymap.set("n", opts.floating.confirm_key, function()
    local lnum = vim.api.nvim_win_get_cursor(winnr)[1]
    if vim.api.nvim_buf_is_valid(bufnr) then
      vim.api.nvim_buf_delete(bufnr, { force = true })
    end
    opts.on_select(lnum)
  end, { buffer = bufnr })

  for lnum, _ in ipairs(content) do
    vim.keymap.set("n", tostring(lnum), function()
      if vim.api.nvim_buf_is_valid(bufnr) then
        vim.api.nvim_buf_delete(bufnr, { force = true })
      end
      opts.on_select(lnum)
    end, { buffer = bufnr })
  end

end

return M
