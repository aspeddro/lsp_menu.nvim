# lsp_menu.nvim

> WIP

A simple menu to handle some LSP requests.

> This plugin just changes the `vim.ui.select` interface to a floating menu.

Supported methods:

- `textDocument/codeAction`
- `textDocument/codeLens`

## Requirements

- Neovim 0.7
  - `vim.keymap` and `vim.api.nvim_create_autocmd` required

## Installation

*packer.nvim*

```lua
use 'aspeddro/lsp_menu.nvim'
```

## Usage

```lua
local on_attach = function(client, bufnr)
  require('lsp_menu').on_attach(client, bufnr)

  -- Add keymap
  vim.keymap.set('n', '<space>ca', require'lsp_menu'.codeaction.run, { buffer = bufnr })
  vim.keymap.set('n', '<space>lr', require'lsp_menu'.codelens.run, { buffer = bufnr })
end
```

## Customize Menu

Default options:

```lua
{
  close_key = "q",
  confirm_key = "<cr>",
  style = {
    border = "rounded",
  }
}
```

Examples:

```lua
vim.keymap.set('n', '<space>ca', function()
  require('lsp_menu').codeaction.run{style = { border = 'single' }}
end, { buffer - bufnr })
```
