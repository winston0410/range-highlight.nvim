# range-highlight.nvim

An extremely lightweight plugin (~ 120loc) that hightlights ranges you have entered in commandline.

![Demo for using range-highlight](./demo.gif)

## Features

- Single line range highlight (`:10`)

- Absolute range highlight (`:20,15`)

- Semicolon separated range highlight (`:20;15`)

- Backward range highlight (`:20,15`)

- Shorthand range highlight (`:,15`)

- Relative range highlight (`:+5,-2`)

- Multiple relative range highlight (`:10+5--,5+3-2`)

- Mark range highlight (`:'a,20`)

- Dot range highlight (`:.,-2`, `:5,.`)

- Last line and whole file highlight (`:4,$`, `:%`)

- Pattern range highlight (`:/hello/d`, `?world?d`)

## Installation

### `paq.nvim`

```lua
paq{'winston0410/cmd-parser.nvim'}
paq{'winston0410/range-highlight.nvim'}
require'range-highlight'.setup{}
```

## Configuration

This is the default configuration. It is likely that you don't need to change anything.

```lua
require("range-highlight").setup {
    highlight = "Visual",
	highlight_with_out_range = {
        d = true,
        delete = true,
        m = true,
        move = true,
        y = true,
        yank = true,
        c = true,
        change = true,
        j = true,
        join = true,
        ["<"] = true,
        [">"] = true,
        s = true,
        subsititue = true,
        sno = true,
        snomagic = true,
        sm = true,
        smagic = true,
        ret = true,
        retab = true,
        t = true,
        co = true,
        copy = true,
        ce = true,
        center = true,
        ri = true,
        right = true,
        le = true,
        left = true,
        sor = true,
        sort = true
	}
}
```

## Acknowledgement

Thank you folks from [gitters](https://gitter.im/neovim/neovim) for helping me out with this plugin.
