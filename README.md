# range-highlight.nvim

An extremely lightweight plugin (~ 120loc) that highlights ranges you have entered in command line.

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

- Pattern range highlight (`:/hello/d, ?world?d`)

## Installation

`range-highlight.nvim` requires a minimum version of NeoVim 0.10.0.

You can install it using any NeoVim package manager. For example:

### `lazy.nvim`

```lua
require("lazy").setup({
    {
        "winston0410/range-highlight.nvim",
        event = { "CmdlineEnter" },
        opts = {},
    }
})
,
```

## Configuration

This is the default configuration. It is likely that you don't need to change anything.

```lua
require("range-highlight").setup({ 
	highlight = {
		group = "Visual",
		priority = 10,
		-- if you want to highlight empty line, set it to true
		to_eol = false,
	},
	-- disable range highlight, if the cmd is matched here. Value here does not accept shorthand
	excluded = { cmd = {} },
})
```

### Disable highlight when you run `:%s`

If you want to prevent range highlighting, when using a substitute command, you can use the following exclusion list.

```lua
require("range-highlight").setup({ 
	excluded = { cmd = { "substitute" } },
})
```

