# nova_cs.nvim

**A dynamic palette manager for Neovim.**

`nova_cs.nvim` lets you generate, preview, manage, and switch color palettes without editing your colorscheme. It is designed to work with **NovaCS-compatible colorschemes**, which read their colors from the currently selected NovaCS palette.

A palette is generated from a simple terminal colorscheme (compatible with Alacritty TOML themes) using the companion Rust CLI, which computes a large set of additional derived colors from 14 base colors.

This allows you to very simply change the appearance of your editor by only having to manipulate 14 colors!

---

## Features

- Generate nova_cs palettes from Alacritty-compatible TOML themes
- Telescope integration - browse palettes and see them applied in real-time
- Live preview a palette before saving it
- Store multiple palettes
- Instant palette switching

---

## Requirements

- Neovim 0.10+
- Rust toolchain (Cargo) - required to compile the CLI binary
- [Telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) (optional, for palette picker with live preview)

---

## Installation

Using **lazy.nvim**:

```lua
-- lazy.nvim
{
    "5ohue/nova_cs.nvim",
    build = function()
        require("nova_cs").build()
    end,
    -- If setup runs earlier than some plugins (like bufferline), it may cause problems
    priority = 1000,
    opts = {
        colorscheme = "soup_nova",
    },
}
```

---

## Configuration

```lua
{
    -- Directory where the generated palettes will be stored
    palette_dir = vim.fs.joinpath(vim.fn.stdpath("data"), "nova_cs/palettes/"),

    -- Directory where the `nova_cs_gen` CLI will be clones
    cli_repo_dir = vim.fs.joinpath(vim.fn.stdpath("data"), "nova_cs/bin/nova_cs_gen"),

    -- `nova_cs_gen` CLI clone URL
    cli_repo_url = "https://github.com/5ohue/nova_cs_gen",

    -- Automatically set the colorscheme at the start
    auto_load = true,

    -- Default palette to use when current palette can't be used
    default_palette = "everforest",

    -- The palette that will be always used on start
    palette_override = nil,

    -- `nova_cs` compatible colorscheme that will be set
    colorscheme = nil,
}
```

---

## Commands

### Generate a palette

Generate from the current buffer:

```vim
:NovaCS generate %
```

Generate from a file:

```vim
:NovaCS generate theme.toml
```

Specify the palette name:

```vim
:NovaCS generate theme.toml my_theme
```

---

### Preview a palette

Preview the current buffer:

```vim
:NovaCS preview %
```

Preview a file:

```vim
:NovaCS preview theme.toml
```

The preview is temporary, does not overwrite the current palette and won't be saved.

---

### Select a palette

Open the palette picker:

```vim
:NovaCS select
```

Or directly choose one:

```vim
:NovaCS select breeze
```

The selected palette becomes the default and will persist after you restart neovim.

---

### Delete a palette

Interactive:

```vim
:NovaCS delete
```

Directly:

```vim
:NovaCS delete breeze
```

---

### Show current palette

```vim
:NovaCS current
```

Will print something like:
```
[nova_cs] Current palette is everforest
```

---

### Change colorscheme

```vim
:NovaCS theme soup_nova
```

---

## NovaCS-compatible colorschemes

A NovaCS-compatible colorscheme simply loads the currently selected palette:

```lua
local p = require("nova_cs.palette").get_current_palette_table()
```

The colorscheme does **not** contain any hardcoded colors. Instead, it builds all highlight groups from the active NovaCS palette. This allows changing the entire appearance of the colorscheme simply by selecting another palette.

Currently the only NovaCS-compatible colorscheme is [soup_nova](https://github.com/5ohue/soup_nova.nvim). If you want to create your own one, you can fork and play with it as a starting point! I suggest adding a `_nova` suffix to your colorscheme name to indicate that it is NovaCS-compatible.

---

## Palette storage

Generated palettes are stored inside

```
stdpath("data")/nova_cs/palettes/
```

The current palette selection is stored separately, allowing you to keep multiple generated palettes and switch between them instantly.
