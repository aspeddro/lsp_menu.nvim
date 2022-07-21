# lsp_menu.nvim

A simple menu to handle some LSP requests.

> This plugin just changes the `vim.ui.select` interface to a floating menu.

Supported methods:

- `textDocument/codeAction`
- `textDocument/codeLens`

## Screenshots

<table>
  <tr>
    <td>Code Action</td>
    <td>Code Lens</td>
  </tr>
  <tr>
    <td><img src="https://user-images.githubusercontent.com/16160544/162342857-277c4c26-4e7f-4174-81d5-a2b5b75e12fd.png"></td>
    <td><img src="https://user-images.githubusercontent.com/16160544/162342939-6f0d3672-fcf6-4d7b-a5b8-d1ddc5227f20.png"></td>
  </tr>
</table>
<sup>LSP: rust_analyzer</sup>

Use the `confirm_key` or the number shortcut to execute the command.

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
end, { buffer = bufnr })
```
