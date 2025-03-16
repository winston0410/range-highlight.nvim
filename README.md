# range-highlight.nvim

An extremely lightweight plugin (~ 120loc) that hightlights ranges you have entered in commandline.

![Demo for using range-highlight](./demo.gif)

## Features

- Single line range highlight (`:10`)

- Absolute range highlight (`:20,15`)

- Semicolon separated range highlight (`:20;15`)

- Backward range highlight (`:20,15`)

- Shorthand range highlight (`:,15`)

- Dot range highlight (`:.,-2`, `:5,.`)

- Relative range highlight (`:+5,-2`)

- Multiple relative range highlight (`:10+5--,5+3-2`)

- Mark range highlight (`:'a,20`)

- Last line and whole file highlight (`:4,$`, `:%`)

- Pattern range highlight (`:/hello/d`, `?world?d`)

## Installation

`range-highlight.nvim` requires a minimum version of NeoVim 0.10.0.

You can install it using any NeoVim package manager. For example:

### `lazy.nvim`

```lua
{
    "winston0410/range-highlight.nvim",
    branch = "refactor/0.10.x",
    event = { "CmdlineEnter" },
    opts = {},
},
```

## Configuration

This is the default configuration. It is likely that you don't need to change anything.

```lua
require("range-highlight").setup({ 
	highlight = {
		group = "Visual",
		priority = 10,
	},
})
```

### Range highlight not working for your command?

If the range highlight doesn't work for your command, you can contribute it into the above list

## Acknowledgement

Thank you folks from [gitters](https://gitter.im/neovim/neovim) for helping me out with this plugin.
