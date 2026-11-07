# renderer.nvim

Improve viewing Markdown in Neovim

<!-- panvimdoc-ignore-start -->

> [!NOTE]
> This project started as a fork of
> [render-markdown.nvim](https://github.com/MeanderingProgrammer/render-markdown.nvim)
> by MeanderingProgrammer, as of version 8.14.0. It has since taken a different
> direction and is maintained independently, without syncing upstream changes.

| Screenshot | Video     |
| ---------- | --------- |
| ![Heading](https://github.com/user-attachments/assets/40655575-b091-4ab8-b830-38f8004d7746) | ![Heading](https://github.com/user-attachments/assets/03f629ea-f6da-4f05-a035-827fd944e8be) |
| ![Table](https://github.com/user-attachments/assets/7d021918-e89c-4b7d-b33a-869390f9a826)   | ![Table](https://github.com/user-attachments/assets/fdbcfbfa-5f9e-49b7-8c19-f7e837979a7a)   |
| ![Quote](https://github.com/user-attachments/assets/822ae62c-bc0f-40a7-b8bb-fb3a885a95f9)   | ![Quote](https://github.com/user-attachments/assets/aa002ac7-b30f-4079-bba9-505160a4ad78)   |
| ![Callout](https://github.com/user-attachments/assets/e468a463-bc8d-420c-bb4c-da1263795092) | ![Callout](https://github.com/user-attachments/assets/d56cc5c7-43cd-4ce7-ad33-6164c2e23875) |
| ![Latex](https://github.com/user-attachments/assets/68f27ff3-49c8-42b5-bb7a-3b89c1e98401)   | ![Latex](https://github.com/user-attachments/assets/41e657a6-bcc2-464d-ab8c-a23bfcb80b0f)   |

<!-- panvimdoc-ignore-end -->

# Features

- Contained: runs entirely inside Neovim with no external windows
- Configurable: all components, padding, icons, and colors can be modified
- File type agnostic: can render `markdown` injected into any file
  - Automatically runs on lazy load file types defined in `lazy.nvim` `ft`
- Injections: can directly manipulate treesitter to add logical `markdown` sections
- Modal rendering: changes between `rendered` and `raw` view based on mode
- Anti-conceal: hides virtual text added by this plugin on cursor line
- Window options: changes option values between `rendered` and `raw` view
- Large files: only renders visible range, can be entirely disabled based on size
- Custom rendering: provides extension point where user can add anything
- Data files: opt in rendering of `csv`, `tsv` and `psv` files as aligned tables
- Renders the following `markdown` components out of the box:
  - Headings: icon, color, border, padding, width
  - Code blocks: background, language icon [^1], border, padding, width
  - Code inline: background
  - Horizontal breaks: icon, color, width
  - List bullets: icon, color, padding
  - Checkboxes: icon, color, user defined states
  - Block quotes: icon, color, line breaks
  - Callouts: icon, color, user defined values, Github & Obsidian defaults
  - Tables: border, color, alignment indicator, auto align cells
  - Links: icon, color, user defined destinations
  - Latex blocks [^2]: renders formulas
  - Org indent mode: per level padding

[^1]: Requires icon provider, `mini.icons` or `nvim-web-devicons`
[^2]: Requires `latex` parser and `pylatexenc`

# Requirements

- Neovim `>= 0.12.0`
- Nerd font symbols: [more details](https://github.com/MeanderingProgrammer/render-markdown.nvim/wiki/Fonts)
- [treesitter](https://github.com/nvim-treesitter/nvim-treesitter) parsers:
  - [markdown & markdown_inline](https://github.com/tree-sitter-grammars/tree-sitter-markdown):
    Used to parse `markdown` files
  - [html](https://github.com/tree-sitter/tree-sitter-html) (Optional):
    Used to conceal `HTML` comments and render `HTML` blocks
  - [latex](https://github.com/latex-lsp/tree-sitter-latex) (Optional):
    Used to get `latex` blocks from `markdown` files
  - [yaml](https://github.com/tree-sitter-grammars/tree-sitter-yaml) (Optional):
    Used to render elements in `frontmatter` metadata
  - [csv, tsv & psv](https://github.com/tree-sitter-grammars/tree-sitter-csv) (Optional):
    Used to render `CSV`, `TSV` and `PSV` files
- Icon provider plugin (Optional): Used for icon above code blocks
  - [mini.icons](https://github.com/nvim-mini/mini.nvim/blob/main/readmes/mini-icons.md)
  - [nvim-web-devicons](https://github.com/nvim-tree/nvim-web-devicons)
- System dependencies:
  - [libtexprintf](https://github.com/bartp5/libtexprintf) (Optional):
    Used to transform `latex` strings to appropriate unicode using `utftex`
  - [pylatexenc](https://pypi.org/project/pylatexenc/) (Optional):
    Used to transform `latex` strings to appropriate unicode using `latex2text`

# Install

## vim.pack

```lua
vim.pack.add({
    'https://github.com/nvim-treesitter/nvim-treesitter',
    'https://github.com/nvim-mini/mini.nvim',            -- if you use the mini.nvim suite
    -- 'https://github.com/nvim-mini/mini.icons',        -- if you use standalone mini plugins
    -- 'https://github.com/nvim-tree/nvim-web-devicons', -- if you prefer nvim-web-devicons
    'https://github.com/PrajwalChigod/renderer.nvim',
})
require('renderer').setup({}) -- only mandatory if you want to set custom options
```

## lazy.nvim

```lua
{
    'PrajwalChigod/renderer.nvim',
    dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-mini/mini.nvim' },            -- if you use the mini.nvim suite
    -- dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-mini/mini.icons' },        -- if you use standalone mini plugins
    -- dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-tree/nvim-web-devicons' }, -- if you prefer nvim-web-devicons
    ---@module 'renderer'
    ---@type renderer.UserConfig
    opts = {},
}
```

## packer.nvim

```lua
use({
    'PrajwalChigod/renderer.nvim',
    after = { 'nvim-treesitter' },
    requires = { 'nvim-mini/mini.nvim', opt = true },            -- if you use the mini.nvim suite
    -- requires = { 'nvim-mini/mini.icons', opt = true },        -- if you use standalone mini plugins
    -- requires = { 'nvim-tree/nvim-web-devicons', opt = true }, -- if you prefer nvim-web-devicons
    config = function()
        require('renderer').setup({})
    end,
})
```

# Commands

| Command                   | Lua Function                         | Description                                       |
| ------------------------- | ------------------------------------ | ------------------------------------------------- |
| `:Renderer`               | `require('renderer').enable()`       | Alias for `enable`                                |
| `:Renderer enable`        | `require('renderer').enable()`       | Alias for `set(true)`                             |
| `:Renderer buf_enable`    | `require('renderer').buf_enable()`   | Alias for `set_buf(true)`                         |
| `:Renderer disable`       | `require('renderer').disable()`      | Alias for `set(false)`                            |
| `:Renderer buf_disable`   | `require('renderer').buf_disable()`  | Alias for `set_buf(false)`                        |
| `:Renderer toggle`        | `require('renderer').toggle()`       | Alias for `set()`                                 |
| `:Renderer buf_toggle`    | `require('renderer').buf_toggle()`   | Alias for `set_buf()`                             |
| `:Renderer get`           | `require('renderer').get()`          | Return current state                              |
| `:Renderer set bool?`     | `require('renderer').set(bool?)`     | Sets state, `nil` to toggle                       |
| `:Renderer set_buf bool?` | `require('renderer').set_buf(bool?)` | Sets state for current buffer, `nil` to toggle    |
| `:Renderer preview`       | `require('renderer').preview()`      | Show rendered buffer to the side                  |
| `:Renderer log`           | `require('renderer').log()`          | Opens the log file for this plugin                |
| `:Renderer expand`        | `require('renderer').expand()`       | Increase anti-conceal margin above and below by 1 |
| `:Renderer contract`      | `require('renderer').contract()`     | Decrease anti-conceal margin above and below by 1 |
| `:Renderer debug`         | `require('renderer').debug()`        | Prints information about marks on current line    |
| `:Renderer config`        | `require('renderer').config()`       | Prints difference between config and default      |

# Completions

This plugin provides completions for both checkboxes and callouts provided you follow
the relevant setup.

## in-process lsp

The recommended way of getting completions from this plugin. Only requires being
enabled with no additional configuration, assuming you have general LSP completions.

Works automatically with `nvim-cmp` and `blink.cmp`.

```lua
require('renderer').setup({
    completions = { lsp = { enabled = true } },
})
```

## coq_nvim

```lua
require('renderer').setup({
    completions = { coq = { enabled = true } },
})
```

# Setup

Checkout the [Wiki](https://github.com/MeanderingProgrammer/render-markdown.nvim/wiki)
for examples and images associated with different configuration options.

The full default configuration is provided below for reference.

Any part of it can be modified however for many fields this does not make much sense.

Some of the more useful fields are discussed further down.

<details>

<summary>Default Configuration</summary>

```lua
require('renderer').setup({
    -- Whether markdown should be rendered by default.
    enabled = true,
    -- Vim modes that will show a rendered view of the markdown file, :h mode(), for all enabled
    -- components. Individual components can be enabled for other modes. Remaining modes will be
    -- unaffected by this plugin.
    render_modes = { 'n', 'c', 't' },
    -- Milliseconds that must pass before updating marks, updates occur.
    -- within the context of the visible window, not the entire buffer.
    debounce = 100,
    -- Pre configured settings that will attempt to mimic various target user experiences.
    -- User provided settings will take precedence.
    -- | obsidian | mimic Obsidian UI                                          |
    -- | lazy     | will attempt to stay up to date with LazyVim configuration |
    -- | none     | does nothing                                               |
    preset = 'none',
    -- The level of logs to write to file: vim.fn.stdpath('state') .. '/renderer.log'.
    -- Only intended to be used for plugin development / debugging.
    log_level = 'error',
    -- Print runtime of main update method.
    -- Only intended to be used for plugin development / debugging.
    log_runtime = false,
    -- Filetypes this plugin will run on.
    file_types = { 'markdown' },
    -- Maximum file size (in MB) that this plugin will attempt to render.
    -- File larger than this will effectively be ignored.
    max_file_size = 10.0,
    -- Takes buffer as input, if it returns true this plugin will not attach to the buffer.
    ignore = function()
        return false
    end,
    -- Whether markdown should be rendered when nested inside markdown, i.e. markdown code block
    -- inside markdown file.
    nested = true,
    -- Additional events that will trigger this plugin's render loop.
    change_events = {},
    -- Whether the treesitter highlighter should be restarted after this plugin attaches to its
    -- first buffer for the first time. May be necessary if this plugin is lazy loaded to clear
    -- highlights that have been dynamically disabled.
    restart_highlighter = false,
    injections = {
        -- Out of the box language injections for known filetypes that allow markdown to be interpreted
        -- in specified locations, see :h treesitter-language-injections.
        -- Set enabled to false in order to disable.

        gitcommit = {
            enabled = true,
            query = [[
                ((message) @injection.content
                    (#set! injection.combined)
                    (#set! injection.include-children)
                    (#set! injection.language "markdown"))
            ]],
        },
    },
    patterns = {
        -- Highlight patterns to disable for filetypes, i.e. lines concealed around code blocks

        markdown = {
            disable = true,
            directives = {
                { id = 17, name = 'conceal_lines' },
                { id = 18, name = 'conceal_lines' },
            },
        },
    },
    anti_conceal = {
        -- This enables hiding added text on the line the cursor is on.
        enabled = true,
        -- Modes to disable anti conceal feature.
        disabled_modes = false,
        -- Number of lines above cursor to show.
        above = 0,
        -- Number of lines below cursor to show.
        below = 0,
        -- Move the cursor past lines that are hidden completely, so that it always lands on a line
        -- that can be seen. This includes lines drawn as something else, such as a wrapped table
        -- row, which otherwise show their source under the cursor. Only has an effect where a hidden
        -- line stays hidden under the cursor, which is the case when `enabled` is false. Counts are
        -- unchanged, `5j` moves 5 buffer lines.
        skip_hidden = true,
        -- Which elements to always show, ignoring anti conceal behavior. Values can either be
        -- booleans to fix the behavior or string lists representing modes where anti conceal
        -- behavior will be ignored. Valid values are:
        --   bullet
        --   callout
        --   check_icon, check_scope
        --   code_background, code_border, code_language
        --   dash
        --   head_background, head_border, head_icon
        --   indent
        --   latex
        --   link
        --   quote
        --   sign
        --   table_border
        --   virtual_lines
        ignore = {
            code_background = true,
            indent = true,
            sign = true,
            virtual_lines = true,
        },
    },
    padding = {
        -- Highlight to use when adding whitespace, should blend in with background.
        highlight = 'RendererPadding',
    },
    latex = {
        -- Turn on / off latex rendering.
        enabled = true,
        -- Additional modes to render latex.
        render_modes = false,
        -- Executable used to convert latex formula to rendered unicode.
        -- If a list is provided the commands run in order until the first success.
        converter = { 'utftex', 'latex2text' },
        -- Render inline latex formulas.
        inline = true,
        -- Render block latex formulas.
        block = true,
        -- Highlight for latex blocks.
        highlight = 'RendererMath',
        -- Determines where latex formula is rendered relative to block.
        -- | above  | above latex block                               |
        -- | below  | below latex block                               |
        -- | center | centered with latex block (must be single line) |
        position = 'center',
        -- Number of empty lines above latex blocks.
        top_pad = 0,
        -- Number of empty lines below latex blocks.
        bottom_pad = 0,
    },
    on = {
        -- Called when plugin initially attaches to a buffer.
        attach = function() end,
        -- Called before adding marks to the buffer for the first time.
        initial = function() end,
        -- Called after plugin renders a buffer.
        render = function() end,
        -- Called after plugin clears a buffer.
        clear = function() end,
    },
    completions = {
        -- Settings for blink.cmp completions source
        blink = { enabled = false },
        -- Settings for coq_nvim completions source
        coq = { enabled = false },
        -- Settings for in-process language server completions
        lsp = { enabled = false },
        filter = {
            callout = function()
                -- example to exclude obsidian callouts
                -- return value.category ~= 'obsidian'
                return true
            end,
            checkbox = function()
                return true
            end,
        },
    },
    heading = {
        -- Useful context to have when evaluating values.
        -- | level    | the number of '#' in the heading marker         |
        -- | sections | for each level how deeply nested the heading is |

        -- Turn on / off heading icon & background rendering.
        enabled = true,
        -- Additional modes to render headings.
        render_modes = false,
        -- Turn on / off atx heading rendering.
        atx = true,
        -- Turn on / off setext heading rendering.
        setext = true,
        -- Turn on / off sign column related rendering.
        sign = true,
        -- Replaces '#+' of 'atx_h._marker'.
        -- Output is evaluated depending on the type.
        -- | function | `value(context)`              |
        -- | string[] | `cycle(value, context.level)` |
        icons = { '󰲡 ', '󰲣 ', '󰲥 ', '󰲧 ', '󰲩 ', '󰲫 ' },
        -- Determines how icons fill the available space.
        -- | eol     | '#'s are concealed and icon is placed at right most column   |
        -- | right   | '#'s are concealed and icon is appended to right side        |
        -- | inline  | '#'s are concealed and icon is inlined on left side          |
        -- | overlay | icon is left padded with spaces and overlayed hiding all '#' |
        position = 'overlay',
        -- Added to the sign column if enabled.
        -- Output is evaluated by `cycle(value, context.level)`.
        signs = { '󰫎 ' },
        -- Width of the heading background.
        -- | block | width of the heading text |
        -- | full  | full width of the window  |
        -- Can also be a list of the above values evaluated by `clamp(value, context.level)`.
        width = 'full',
        -- Amount of margin to add to the left of headings.
        -- Margin available space is computed after accounting for padding.
        -- If a float < 1 is provided it is treated as a percentage of available window space.
        -- Can also be a list of numbers evaluated by `clamp(value, context.level)`.
        left_margin = 0,
        -- Amount of padding to add to the left of headings.
        -- Output is evaluated using the same logic as 'left_margin'.
        left_pad = 0,
        -- Amount of padding to add to the right of headings when width is 'block'.
        -- Output is evaluated using the same logic as 'left_margin'.
        right_pad = 0,
        -- Minimum width to use for headings when width is 'block'.
        -- Can also be a list of integers evaluated by `clamp(value, context.level)`.
        min_width = 0,
        -- Determines if a border is added above and below headings.
        -- Can also be a list of booleans evaluated by `clamp(value, context.level)`.
        border = false,
        -- Always use virtual lines for heading borders instead of attempting to use empty lines.
        border_virtual = false,
        -- Highlight the start of the border using the foreground highlight.
        border_prefix = false,
        -- Used above heading for border.
        above = '▄',
        -- Used below heading for border.
        below = '▀',
        -- Highlight for the heading icon and extends through the entire line.
        -- Output is evaluated by `clamp(value, context.level)`.
        backgrounds = {
            'RendererH1Bg',
            'RendererH2Bg',
            'RendererH3Bg',
            'RendererH4Bg',
            'RendererH5Bg',
            'RendererH6Bg',
        },
        -- Highlight for the heading and sign icons.
        -- Output is evaluated using the same logic as 'backgrounds'.
        foregrounds = {
            'RendererH1',
            'RendererH2',
            'RendererH3',
            'RendererH4',
            'RendererH5',
            'RendererH6',
        },
        -- Define custom heading patterns which allow you to override various properties based on
        -- the contents of a heading.
        -- The key is for healthcheck and to allow users to change its values, value type below.
        -- | pattern    | matched against the heading text @see :h lua-patterns |
        -- | icon       | optional override for the icon                        |
        -- | background | optional override for the background                  |
        -- | foreground | optional override for the foreground                  |
        custom = {},
    },
    paragraph = {
        -- Useful context to have when evaluating values.
        -- | text | text value of the node |

        -- Turn on / off paragraph rendering.
        enabled = true,
        -- Additional modes to render paragraphs.
        render_modes = false,
        -- Amount of margin to add to the left of paragraphs.
        -- If a float < 1 is provided it is treated as a percentage of available window space.
        -- Output is evaluated depending on the type.
        -- | function | `value(context)` |
        -- | number   | `value`          |
        left_margin = 0,
        -- Amount of padding to add to the first line of each paragraph.
        -- Output is evaluated using the same logic as 'left_margin'.
        indent = 0,
        -- Minimum width to use for paragraphs.
        min_width = 0,
    },
    code = {
        -- Turn on / off code block & inline code rendering.
        enabled = true,
        -- Additional modes to render code blocks.
        render_modes = false,
        -- Turn on / off sign column related rendering.
        sign = true,
        -- Whether to conceal nodes at the top and bottom of code blocks.
        conceal_delimiters = true,
        -- Turn on / off language heading related rendering.
        language = true,
        -- Determines where language icon is rendered.
        -- | center | center of code block |
        -- | right  | right of code block  |
        -- | left   | left of code block   |
        position = 'left',
        -- Whether to include the language icon above code blocks.
        language_icon = true,
        -- Whether to include the language name above code blocks.
        language_name = true,
        -- Whether to include the language info above code blocks.
        language_info = true,
        -- Amount of padding to add around the language.
        -- If a float < 1 is provided it is treated as a percentage of available window space.
        language_pad = 0,
        -- A list of language names for which rendering will be disabled.
        disable = {},
        -- A list of language names for which background highlighting will be disabled.
        -- Likely because that language has background highlights itself.
        -- Use a boolean to make behavior apply to all languages.
        -- Borders above & below blocks will continue to be rendered.
        disable_background = { 'diff' },
        -- Number of lines from start/end to skip rendering background.
        background_inset = 1,
        -- Width of the code block background.
        -- | block | width of the code block  |
        -- | full  | full width of the window |
        width = 'full',
        -- Amount of margin to add to the left of code blocks.
        -- If a float < 1 is provided it is treated as a percentage of available window space.
        -- Margin available space is computed after accounting for padding.
        left_margin = 0,
        -- Amount of padding to add to the left of code blocks.
        -- If a float < 1 is provided it is treated as a percentage of available window space.
        left_pad = 0,
        -- Amount of padding to add to the right of code blocks when width is 'block'.
        -- If a float < 1 is provided it is treated as a percentage of available window space.
        right_pad = 0,
        -- Minimum width to use for code blocks when width is 'block'.
        min_width = 0,
        -- Determines how the top / bottom of code block are rendered.
        -- | none  | do not render a border                               |
        -- | thick | use the same highlight as the code body              |
        -- | thin  | when lines are empty overlay the above & below icons |
        -- | hide  | conceal lines unless language name or icon is added  |
        border = 'hide',
        -- Used above code blocks to fill remaining space around language.
        language_border = '█',
        -- Added to the left of language.
        language_left = '',
        -- Added to the right of language.
        language_right = '',
        -- Used above code blocks for thin border.
        above = '▄',
        -- Used below code blocks for thin border.
        below = '▀',
        -- Turn on / off inline code related rendering.
        inline = true,
        -- Icon to add to the left of inline code.
        inline_left = '',
        -- Icon to add to the right of inline code.
        inline_right = '',
        -- Padding to add to the left & right of inline code.
        inline_pad = 0,
        -- Priority to assign to code background highlight.
        priority = 140,
        -- Highlight for code blocks.
        highlight = 'RendererCode',
        -- Highlight for code info section, after the language.
        highlight_info = 'RendererCodeInfo',
        -- Highlight for language, overrides icon provider value.
        highlight_language = nil,
        -- Highlight for border, use false to add no highlight.
        highlight_border = 'RendererCodeBorder',
        -- Highlight for language, used if icon provider does not have a value.
        highlight_fallback = 'RendererCodeFallback',
        -- Highlight for inline code.
        highlight_inline = 'RendererCodeInline',
        -- Highlight for inline code left icon, default to reverse of highlight_inline.
        highlight_inline_left = nil,
        -- Highlight for inline code right icon, default to reverse of highlight_inline.
        highlight_inline_right = nil,
        -- Determines how code blocks & inline code are rendered.
        -- | none     | { enabled = false }                           |
        -- | normal   | { language = false }                          |
        -- | language | { disable_background = true, inline = false } |
        -- | full     | uses all default values                       |
        style = 'full',
    },
    csv = {
        -- Turn on / off csv, tsv and psv rendering, only applies to buffers whose filetype is
        -- listed in `file_types`.
        enabled = true,
        -- Additional modes to render csv, tsv and psv.
        render_modes = false,
        -- Treat the first row as the header.
        header = true,
        -- Number of rows from the top of the file measured to size the columns, the rows on screen
        -- are always measured as well.
        sample_rows = 200,
        -- Maximum width of a column, longer values are cut.
        max_width = 40,
        -- Replaces the separator between fields.
        border = '│',
        -- Highlight for the header row and the line below it.
        head = 'RendererTableHead',
        -- Highlight for every other row.
        row = 'RendererTableRow',
    },
    dash = {
        -- Useful context to have when evaluating values.
        -- | width | width of the current window |

        -- Turn on / off thematic break rendering.
        enabled = true,
        -- Additional modes to render dash.
        render_modes = false,
        -- Replaces '---'|'***'|'___'|'* * *' of 'thematic_break'.
        -- The icon gets repeated across the window's width.
        icon = '─',
        -- Width of the generated line.
        -- If a float < 1 is provided it is treated as a percentage of available window space.
        -- Output is evaluated depending on the type.
        -- | function | `value(context)`    |
        -- | number   | `value`             |
        -- | full     | width of the window |
        width = 'full',
        -- Amount of margin to add to the left of dash.
        -- If a float < 1 is provided it is treated as a percentage of available window space.
        left_margin = 0,
        -- Priority to assign to dash.
        priority = nil,
        -- Highlight for the whole line generated from the icon.
        highlight = 'RendererDash',
    },
    document = {
        -- Turn on / off document rendering.
        enabled = true,
        -- Additional modes to render document.
        render_modes = false,
        -- Ability to conceal arbitrary ranges of text based on lua patterns, @see :h lua-patterns.
        -- Relies entirely on user to set patterns that handle their edge cases.
        conceal = {
            -- Matched ranges will be concealed using character level conceal.
            char_patterns = {},
            -- Matched ranges will be concealed using line level conceal.
            line_patterns = {},
        },
    },
    bullet = {
        -- Useful context to have when evaluating values.
        -- | level | how deeply nested the list is, 1-indexed          |
        -- | index | how far down the item is at that level, 1-indexed |
        -- | value | text value of the marker node                     |

        -- Turn on / off list bullet rendering
        enabled = true,
        -- Additional modes to render list bullets
        render_modes = false,
        -- Replaces '-'|'+'|'*' of 'list_item'.
        -- If the item is a 'checkbox' a conceal is used to hide the bullet instead.
        -- Output is evaluated depending on the type.
        -- | function   | `value(context)`                                    |
        -- | string     | `value`                                             |
        -- | string[]   | `cycle(value, context.level)`                       |
        -- | string[][] | `clamp(cycle(value, context.level), context.index)` |
        icons = { '●', '○', '◆', '◇' },
        -- Replaces 'n.'|'n)' of 'list_item'.
        -- Output is evaluated using the same logic as 'icons'.
        ordered_icons = function(ctx)
            local value = vim.trim(ctx.value)
            local index = tonumber(value:sub(1, #value - 1))
            return ('%d.'):format(index > 1 and index or ctx.index)
        end,
        -- Padding to add to the left of bullet point.
        -- Output is evaluated depending on the type.
        -- | function | `value(context)` |
        -- | integer  | `value`          |
        left_pad = 0,
        -- Padding to add to the right of bullet point.
        -- Output is evaluated using the same logic as 'left_pad'.
        right_pad = 0,
        -- Highlight for the bullet icon.
        -- Output is evaluated using the same logic as 'icons'.
        highlight = 'RendererBullet',
        -- Highlight for item associated with the bullet point.
        -- Output is evaluated using the same logic as 'icons'.
        scope_highlight = {},
        -- Priority to assign to scope highlight.
        scope_priority = nil,
    },
    checkbox = {
        -- Checkboxes are a special instance of a 'list_item' that start with a 'shortcut_link'.
        -- There are two special states for unchecked & checked defined in the markdown grammar.

        -- Turn on / off checkbox state rendering.
        enabled = true,
        -- Additional modes to render checkboxes.
        render_modes = false,
        -- Render the bullet point before the checkbox.
        bullet = false,
        -- Padding to add to the left of checkboxes.
        left_pad = 0,
        -- Padding to add to the right of checkboxes.
        right_pad = 1,
        unchecked = {
            -- Replaces '[ ]' of 'task_list_marker_unchecked'.
            icon = '󰄱 ',
            -- Highlight for the unchecked icon.
            highlight = 'RendererUnchecked',
            -- Highlight for item associated with unchecked checkbox.
            scope_highlight = nil,
        },
        checked = {
            -- Replaces '[x]' of 'task_list_marker_checked'.
            icon = '󰱒 ',
            -- Highlight for the checked icon.
            highlight = 'RendererChecked',
            -- Highlight for item associated with checked checkbox.
            scope_highlight = nil,
        },
        -- Define custom checkbox states, more involved, not part of the markdown grammar.
        -- The key is for healthcheck and to allow users to change its values, value type below.
        -- | raw             | matched against the raw text of a 'shortcut_link'           |
        -- | rendered        | replaces the 'raw' value when rendering                     |
        -- | highlight       | highlight for the 'rendered' icon                           |
        -- | scope_highlight | optional highlight for item associated with custom checkbox |
        -- stylua: ignore
        custom = {
            todo = { raw = '[-]', rendered = '󰥔 ', highlight = 'RendererTodo', scope_highlight = nil },
        },
        -- Priority to assign to scope highlight.
        scope_priority = nil,
    },
    quote = {
        -- Turn on / off block quote & callout rendering.
        enabled = true,
        -- Additional modes to render quotes.
        render_modes = false,
        -- Replaces '>' of 'block_quote'.
        icon = '▋',
        -- Whether to repeat icon on wrapped lines. This will obscure text
        -- if incorrectly configured with :h 'showbreak', :h 'breakindent' and :h 'breakindentopt'.
        -- A combination of these that is likely to work follows.
        -- | showbreak      | '  ' (2 spaces)   |
        -- | breakindent    | true              |
        -- | breakindentopt | '' (empty string) |
        -- These are not validated by this plugin. If you want to avoid adding these to your main
        -- configuration then set them in win_options for this plugin.
        repeat_linebreak = false,
        -- Highlight for the quote icon.
        -- If a list is provided output is evaluated by `cycle(value, level)`.
        highlight = {
            'RendererQuote1',
            'RendererQuote2',
            'RendererQuote3',
            'RendererQuote4',
            'RendererQuote5',
            'RendererQuote6',
        },
    },
    render = {
        -- Whether to render when window is in diff-mode.
        diff = false,
    },
    pipe_table = {
        -- Turn on / off pipe table rendering.
        enabled = true,
        -- Additional modes to render pipe tables.
        render_modes = false,
        -- Pre configured settings largely for setting table border easier.
        -- | heavy  | use thicker border characters     |
        -- | double | use double line border characters |
        -- | round  | use round border corners          |
        -- | none   | does nothing                      |
        preset = 'none',
        -- Determines how individual cells of a table are rendered.
        -- | overlay | writes completely over the table, removing conceal behavior and highlights |
        -- | raw     | replaces only the '|' characters in each row, leaving the cells unmodified |
        -- | padded  | raw + cells are padded to maximum visual width for each column             |
        -- | trimmed | padded except empty space is subtracted from visual width calculation      |
        cell = 'padded',
        -- Fit wide tables to the current window by wrapping individual cells.
        wrap = true,
        -- Adjust the computed width of table cells using custom logic.
        cell_offset = function()
            return 0
        end,
        -- Amount of space to put between cell contents and border.
        padding = 1,
        -- Minimum column width to use for padded or trimmed cell.
        min_width = 0,
        -- Characters used to replace table border.
        -- Correspond to top(3), delimiter(3), bottom(3), vertical, & horizontal.
        -- stylua: ignore
        border = {
            '┌', '┬', '┐',
            '├', '┼', '┤',
            '└', '┴', '┘',
            '│', '─',
        },
        -- Turn on / off top & bottom lines.
        border_enabled = true,
        -- Always use virtual lines for table borders instead of attempting to use empty lines.
        -- Will be automatically enabled if indentation module is enabled.
        border_virtual = false,
        -- Gets placed in delimiter row for each column, position is based on alignment.
        alignment_indicator = '━',
        -- Highlight for table heading, delimiter, and the line above.
        head = 'RendererTableHead',
        -- Highlight for everything else, main table rows and the line below.
        row = 'RendererTableRow',
        -- Determines how the table as a whole is rendered.
        -- | none   | { enabled = false }        |
        -- | normal | { border_enabled = false } |
        -- | full   | uses all default values    |
        style = 'full',
    },
    callout = {
        -- Callouts are a special instance of a 'block_quote' that start with a 'shortcut_link'.
        -- The key is for healthcheck and to allow users to change its values, value type below.
        -- | raw        | matched against the raw text of a 'shortcut_link', case insensitive |
        -- | rendered   | replaces the 'raw' value when rendering                             |
        -- | highlight  | highlight for the 'rendered' text and quote markers                 |
        -- | quote_icon | optional override for quote.icon value for individual callout       |
        -- | category   | optional metadata useful for filtering                              |

        note      = { raw = '[!NOTE]',      rendered = '󰋽 Note',      highlight = 'RendererInfo',    category = 'github'   },
        tip       = { raw = '[!TIP]',       rendered = '󰌶 Tip',       highlight = 'RendererSuccess', category = 'github'   },
        important = { raw = '[!IMPORTANT]', rendered = '󰅾 Important', highlight = 'RendererHint',    category = 'github'   },
        warning   = { raw = '[!WARNING]',   rendered = '󰀪 Warning',   highlight = 'RendererWarn',    category = 'github'   },
        caution   = { raw = '[!CAUTION]',   rendered = '󰳦 Caution',   highlight = 'RendererError',   category = 'github'   },
        -- Obsidian: https://help.obsidian.md/Editing+and+formatting/Callouts
        abstract  = { raw = '[!ABSTRACT]',  rendered = '󰨸 Abstract',  highlight = 'RendererInfo',    category = 'obsidian' },
        summary   = { raw = '[!SUMMARY]',   rendered = '󰨸 Summary',   highlight = 'RendererInfo',    category = 'obsidian' },
        tldr      = { raw = '[!TLDR]',      rendered = '󰨸 Tldr',      highlight = 'RendererInfo',    category = 'obsidian' },
        info      = { raw = '[!INFO]',      rendered = '󰋽 Info',      highlight = 'RendererInfo',    category = 'obsidian' },
        todo      = { raw = '[!TODO]',      rendered = '󰗡 Todo',      highlight = 'RendererInfo',    category = 'obsidian' },
        hint      = { raw = '[!HINT]',      rendered = '󰌶 Hint',      highlight = 'RendererSuccess', category = 'obsidian' },
        success   = { raw = '[!SUCCESS]',   rendered = '󰄬 Success',   highlight = 'RendererSuccess', category = 'obsidian' },
        check     = { raw = '[!CHECK]',     rendered = '󰄬 Check',     highlight = 'RendererSuccess', category = 'obsidian' },
        done      = { raw = '[!DONE]',      rendered = '󰄬 Done',      highlight = 'RendererSuccess', category = 'obsidian' },
        question  = { raw = '[!QUESTION]',  rendered = '󰘥 Question',  highlight = 'RendererWarn',    category = 'obsidian' },
        help      = { raw = '[!HELP]',      rendered = '󰘥 Help',      highlight = 'RendererWarn',    category = 'obsidian' },
        faq       = { raw = '[!FAQ]',       rendered = '󰘥 Faq',       highlight = 'RendererWarn',    category = 'obsidian' },
        attention = { raw = '[!ATTENTION]', rendered = '󰀪 Attention', highlight = 'RendererWarn',    category = 'obsidian' },
        failure   = { raw = '[!FAILURE]',   rendered = '󰅖 Failure',   highlight = 'RendererError',   category = 'obsidian' },
        fail      = { raw = '[!FAIL]',      rendered = '󰅖 Fail',      highlight = 'RendererError',   category = 'obsidian' },
        missing   = { raw = '[!MISSING]',   rendered = '󰅖 Missing',   highlight = 'RendererError',   category = 'obsidian' },
        danger    = { raw = '[!DANGER]',    rendered = '󱐌 Danger',    highlight = 'RendererError',   category = 'obsidian' },
        error     = { raw = '[!ERROR]',     rendered = '󱐌 Error',     highlight = 'RendererError',   category = 'obsidian' },
        bug       = { raw = '[!BUG]',       rendered = '󰨰 Bug',       highlight = 'RendererError',   category = 'obsidian' },
        example   = { raw = '[!EXAMPLE]',   rendered = '󰉹 Example',   highlight = 'RendererHint' ,   category = 'obsidian' },
        quote     = { raw = '[!QUOTE]',     rendered = '󱆨 Quote',     highlight = 'RendererQuote',   category = 'obsidian' },
        cite      = { raw = '[!CITE]',      rendered = '󱆨 Cite',      highlight = 'RendererQuote',   category = 'obsidian' },
    },
    link = {
        -- Turn on / off inline link icon rendering.
        enabled = true,
        -- Additional modes to render links.
        render_modes = false,
        -- How to handle footnote links, start with a '^'.
        footnote = {
            -- Turn on / off footnote rendering.
            enabled = true,
            -- Inlined with content.
            icon = '󰯔 ',
            -- Custom processing for footnote body to show.
            -- Runs before prefix / suffix are added and superscript processing.
            body = function(ctx)
                return ctx.text
            end,
            -- Replace value with superscript equivalent.
            superscript = true,
            -- Added before link content.
            prefix = '',
            -- Added after link content.
            suffix = '',
        },
        -- Inlined with 'image' elements.
        image = '󰥶 ',
        -- Check custom for 'image' elements.
        image_custom = true,
        -- Inlined with 'email_autolink' elements.
        email = '󰀓 ',
        -- Fallback icon for 'inline_link' and 'uri_autolink' elements.
        hyperlink = '󰌹 ',
        -- Applies to the inlined icon as a fallback.
        highlight = 'RendererLink',
        -- Applies to the link title.
        highlight_title = 'RendererLinkTitle',
        -- Applies to WikiLink elements.
        wiki = {
            -- Turn on / off WikiLink rendering.
            enabled = true,
            -- Inlined with content.
            icon = '󱗖 ',
            -- Hide destination if there is an alias.
            conceal_destination = true,
            -- Custom processing for WikiLink body to show.
            body = function()
                return nil
            end,
            -- Applies to the inlined icon.
            highlight = 'RendererWikiLink',
            -- Highlight for item associated with the WikiLink.
            scope_highlight = nil,
        },
        -- Define custom destination patterns so icons can quickly inform you of what a link
        -- contains. Applies to 'image', 'inline_link', 'uri_autolink', and WikiLink nodes.
        -- When multiple patterns match a link the one with the longer pattern is used.
        -- The key is for healthcheck and to allow users to change its values, value type below.
        -- | icon      | gets inlined before the link text                               |
        -- | pattern   | matched against the destination text                            |
        -- | kind      | optional determines how pattern is checked                      |
        -- |           | pattern | @see :h lua-patterns, is the default if not set       |
        -- |           | suffix  | @see :h vim.endswith()                                |
        -- |           | url     | similar to pattern with additional prefix checks      |
        -- | priority  | optional used when multiple match, uses pattern length if empty |
        -- | highlight | optional highlight for 'icon', uses fallback highlight if empty |
        -- stylua: ignore
        custom = {
            web = { icon = '󰖟 ', pattern = '^http' },
            apple = { icon = ' ', pattern = 'apple%.com', kind = 'url' },
            discord = { icon = '󰙯 ', pattern = 'discord%.com', kind = 'url' },
            github = { icon = '󰊤 ', pattern = 'github%.com', kind = 'url' },
            gitlab = { icon = '󰮠 ', pattern = 'gitlab%.com', kind = 'url' },
            google = { icon = '󰊭 ', pattern = 'google%.com', kind = 'url' },
            hackernews = { icon = ' ', pattern = 'ycombinator%.com', kind = 'url' },
            linkedin = { icon = '󰌻 ', pattern = 'linkedin%.com', kind = 'url' },
            microsoft = { icon = ' ', pattern = 'microsoft%.com', kind = 'url' },
            neovim = { icon = ' ', pattern = 'neovim%.io', kind = 'url' },
            reddit = { icon = '󰑍 ', pattern = 'reddit%.com', kind = 'url' },
            slack = { icon = '󰒱 ', pattern = 'slack%.com', kind = 'url' },
            stackoverflow = { icon = '󰓌 ', pattern = 'stackoverflow%.com', kind = 'url' },
            steam = { icon = ' ', pattern = 'steampowered%.com', kind = 'url' },
            twitter = { icon = ' ', pattern = 'twitter%.com', kind = 'url' },
            wikipedia = { icon = '󰖬 ', pattern = 'wikipedia%.org', kind = 'url' },
            x = { icon = ' ', pattern = 'x%.com', kind = 'url' },
            youtube = { icon = '󰗃 ', pattern = 'youtube[^.]*%.com', kind = 'url' },
            youtube_short = { icon = '󰗃 ', pattern = 'youtu%.be', kind = 'url' },
        },
    },
    sign = {
        -- Turn on / off sign rendering.
        enabled = true,
        -- Priority to assign to sign.
        priority = nil,
        -- Applies to background of sign text.
        highlight = 'RendererSign',
    },
    inline_highlight = {
        -- Mimics Obsidian inline highlights when content is surrounded by double equals.
        -- The equals on both ends are concealed and the inner content is highlighted.

        -- Turn on / off inline highlight rendering.
        enabled = true,
        -- Additional modes to render inline highlights.
        render_modes = false,
        -- Applies to background of surrounded text.
        highlight = 'RendererInlineHighlight',
        -- Define custom highlights based on text prefix.
        -- The key is for healthcheck and to allow users to change its values, value type below.
        -- | prefix    | matched against text body, @see :h vim.startswith() |
        -- | highlight | highlight for text body                             |
        custom = {},
    },
    indent = {
        -- Mimic org-indent-mode behavior by indenting everything under a heading based on the
        -- level of the heading. Indenting starts from level 2 headings onward by default.

        -- Turn on / off org-indent-mode.
        enabled = false,
        -- Additional modes to render indents.
        render_modes = false,
        -- Amount of additional padding added for each heading level.
        per_level = 2,
        -- Heading levels <= this value will not be indented.
        -- Use 0 to begin indenting from the very first level.
        skip_level = 1,
        -- Do not indent heading titles, only the body.
        skip_heading = false,
        -- Prefix added when indenting, one per level.
        icon = '▎',
        -- Priority to assign to extmarks.
        priority = 0,
        -- Applied to icon.
        highlight = 'RendererIndent',
    },
    html = {
        -- Turn on / off all HTML rendering.
        enabled = true,
        -- Additional modes to render HTML.
        render_modes = false,
        -- Hide the doctype, html, head and body tags and collapse style and script
        -- elements into one line, only applies to a whole HTML file.
        structure = true,
        -- Replace ul, ol and li tags with bullets and numbers, uses `bullet` config.
        list = true,
        -- Replace blockquote tags with the quote icon, uses `quote` config.
        quote = true,
        -- Add a background to pre elements, uses `code` config.
        pre = true,
        -- Replace hr with a line, uses `dash` config.
        rule = true,
        -- Replace table elements with a bordered grid, uses `pipe_table` config.
        -- Tables with colspan / rowspan or another table inside, and tables that do
        -- not fit fully inside the visible range of the window are left as is.
        table = true,
        -- Replace entities like &amp; and &#169; with the character they stand for.
        entity = true,
        comment = {
            -- Useful context to have when evaluating values.
            -- | text | text value of the comment node |

            -- Turn on / off HTML comment concealing.
            conceal = true,
            -- Text to inline before the concealed comment.
            -- Output is evaluated depending on the type.
            -- | function | `value(context)` |
            -- | string   | `value`          |
            -- | nil      | nothing          |
            text = nil,
            -- Highlight for the inlined text.
            highlight = 'RendererHtmlComment',
        },
        -- HTML tags whose start and end will be hidden and icon shown.
        -- The key is matched against the tag name, value type below.
        -- | icon            | optional icon inlined at start of tag             |
        -- | highlight       | optional highlight for the icon                   |
        -- | scope_highlight | optional highlight for item associated with tag   |
        -- | attribute       | optional attribute whose value is inlined at tag  |
        -- Tags work inside HTML blocks and inline within paragraphs.
        -- Elements with align="center" / align="right" and <center> are aligned.
        tag = {
            -- Text styles
            b = { scope_highlight = 'RendererHtmlBold' },
            strong = { scope_highlight = 'RendererHtmlBold' },
            i = { scope_highlight = 'RendererHtmlItalic' },
            em = { scope_highlight = 'RendererHtmlItalic' },
            cite = { scope_highlight = 'RendererHtmlItalic' },
            u = { scope_highlight = 'RendererHtmlUnderline' },
            ins = { scope_highlight = 'RendererHtmlUnderline' },
            s = { scope_highlight = 'RendererHtmlStrike' },
            del = { scope_highlight = 'RendererHtmlStrike' },
            strike = { scope_highlight = 'RendererHtmlStrike' },
            code = { scope_highlight = 'RendererCodeInline' },
            kbd = { scope_highlight = 'RendererCodeInline' },
            tt = { scope_highlight = 'RendererCodeInline' },
            mark = { scope_highlight = 'RendererInlineHighlight' },
            sub = {},
            sup = {},
            -- Links & images
            a = { scope_highlight = 'RendererLink' },
            img = {
                icon = '󰥶 ',
                highlight = 'RendererLink',
                attribute = 'alt',
            },
            -- Headings
            h1 = { scope_highlight = 'RendererH1' },
            h2 = { scope_highlight = 'RendererH2' },
            h3 = { scope_highlight = 'RendererH3' },
            h4 = { scope_highlight = 'RendererH4' },
            h5 = { scope_highlight = 'RendererH5' },
            h6 = { scope_highlight = 'RendererH6' },
            -- Structure, tags are only hidden
            br = {},
            p = {},
            div = {},
            span = {},
            center = {},
            picture = {},
            details = {},
            summary = { scope_highlight = 'RendererHtmlBold' },
        },
    },
    win_options = {
        -- Window options to use that change between rendered and raw view.

        -- @see :h 'conceallevel'
        conceallevel = {
            -- Used when not being rendered, get user setting.
            default = vim.o.conceallevel,
            -- Used when being rendered, concealed text is completely hidden.
            rendered = 3,
        },
        -- @see :h 'concealcursor'
        concealcursor = {
            -- Used when not being rendered, get user setting.
            default = vim.o.concealcursor,
            -- Used when being rendered, show concealed text in all modes.
            rendered = '',
        },
    },
    overrides = {
        -- More granular configuration mechanism, allows different aspects of buffers to have their own
        -- behavior. Values default to the top level configuration if no override is provided. Supports
        -- the following fields:
        --   enabled, render_modes, debounce, anti_conceal, bullet, callout, checkbox, code, csv,
        --   dash, document, heading, html, indent, inline_highlight, latex, link, padding, paragraph,
        --   pipe_table, quote, sign, win_options, yaml

        -- Override for different buflisted values, @see :h 'buflisted'.
        buflisted = {},
        -- Override for different buftype values, @see :h 'buftype'.
        buftype = {
            nofile = {
                render_modes = true,
                sign = { enabled = false },
            },
        },
        -- Override for different filetype values, @see :h 'filetype'.
        filetype = {},
        -- Override for preview buffer.
        preview = {
            render_modes = true,
        },
    },
    custom_handlers = {
        -- Mapping from treesitter language to user defined handlers.
        -- @see [Custom Handlers](doc/custom-handlers.md)
    },
    yaml = {
        -- Turn on / off all yaml rendering.
        enabled = true,
        -- Additional modes to render yaml.
        render_modes = false,
    },
})
```

</details>

We use the following definitions when discussing indexing into lists:

1. Cycle: Indexed `mod` the length.
   Example: `{ 1, 2, 3 }` @ 4 = 1.
2. Clamp: Indexed normally but larger values use the last value in the list.
   Example: `{ 1, 2, 3 }` @ 4 = 3.

## Headings

[Wiki Page](https://github.com/MeanderingProgrammer/render-markdown.nvim/wiki/Headings)

<details>

<summary>Heading Configuration</summary>

```lua
require('renderer').setup({
    heading = {
        -- Useful context to have when evaluating values.
        -- | level    | the number of '#' in the heading marker         |
        -- | sections | for each level how deeply nested the heading is |

        -- Turn on / off heading icon & background rendering.
        enabled = true,
        -- Additional modes to render headings.
        render_modes = false,
        -- Turn on / off atx heading rendering.
        atx = true,
        -- Turn on / off setext heading rendering.
        setext = true,
        -- Turn on / off sign column related rendering.
        sign = true,
        -- Replaces '#+' of 'atx_h._marker'.
        -- Output is evaluated depending on the type.
        -- | function | `value(context)`              |
        -- | string[] | `cycle(value, context.level)` |
        icons = { '󰲡 ', '󰲣 ', '󰲥 ', '󰲧 ', '󰲩 ', '󰲫 ' },
        -- Determines how icons fill the available space.
        -- | eol     | '#'s are concealed and icon is placed at right most column   |
        -- | right   | '#'s are concealed and icon is appended to right side        |
        -- | inline  | '#'s are concealed and icon is inlined on left side          |
        -- | overlay | icon is left padded with spaces and overlayed hiding all '#' |
        position = 'overlay',
        -- Added to the sign column if enabled.
        -- Output is evaluated by `cycle(value, context.level)`.
        signs = { '󰫎 ' },
        -- Width of the heading background.
        -- | block | width of the heading text |
        -- | full  | full width of the window  |
        -- Can also be a list of the above values evaluated by `clamp(value, context.level)`.
        width = 'full',
        -- Amount of margin to add to the left of headings.
        -- Margin available space is computed after accounting for padding.
        -- If a float < 1 is provided it is treated as a percentage of available window space.
        -- Can also be a list of numbers evaluated by `clamp(value, context.level)`.
        left_margin = 0,
        -- Amount of padding to add to the left of headings.
        -- Output is evaluated using the same logic as 'left_margin'.
        left_pad = 0,
        -- Amount of padding to add to the right of headings when width is 'block'.
        -- Output is evaluated using the same logic as 'left_margin'.
        right_pad = 0,
        -- Minimum width to use for headings when width is 'block'.
        -- Can also be a list of integers evaluated by `clamp(value, context.level)`.
        min_width = 0,
        -- Determines if a border is added above and below headings.
        -- Can also be a list of booleans evaluated by `clamp(value, context.level)`.
        border = false,
        -- Always use virtual lines for heading borders instead of attempting to use empty lines.
        border_virtual = false,
        -- Highlight the start of the border using the foreground highlight.
        border_prefix = false,
        -- Used above heading for border.
        above = '▄',
        -- Used below heading for border.
        below = '▀',
        -- Highlight for the heading icon and extends through the entire line.
        -- Output is evaluated by `clamp(value, context.level)`.
        backgrounds = {
            'RendererH1Bg',
            'RendererH2Bg',
            'RendererH3Bg',
            'RendererH4Bg',
            'RendererH5Bg',
            'RendererH6Bg',
        },
        -- Highlight for the heading and sign icons.
        -- Output is evaluated using the same logic as 'backgrounds'.
        foregrounds = {
            'RendererH1',
            'RendererH2',
            'RendererH3',
            'RendererH4',
            'RendererH5',
            'RendererH6',
        },
        -- Define custom heading patterns which allow you to override various properties based on
        -- the contents of a heading.
        -- The key is for healthcheck and to allow users to change its values, value type below.
        -- | pattern    | matched against the heading text @see :h lua-patterns |
        -- | icon       | optional override for the icon                        |
        -- | background | optional override for the background                  |
        -- | foreground | optional override for the foreground                  |
        custom = {},
    },
})
```

</details>

## Paragraphs

[Wiki Page](https://github.com/MeanderingProgrammer/render-markdown.nvim/wiki/Paragraphs)

<details>

<summary>Paragraph Configuration</summary>

```lua
require('renderer').setup({
    paragraph = {
        -- Useful context to have when evaluating values.
        -- | text | text value of the node |

        -- Turn on / off paragraph rendering.
        enabled = true,
        -- Additional modes to render paragraphs.
        render_modes = false,
        -- Amount of margin to add to the left of paragraphs.
        -- If a float < 1 is provided it is treated as a percentage of available window space.
        -- Output is evaluated depending on the type.
        -- | function | `value(context)` |
        -- | number   | `value`          |
        left_margin = 0,
        -- Amount of padding to add to the first line of each paragraph.
        -- Output is evaluated using the same logic as 'left_margin'.
        indent = 0,
        -- Minimum width to use for paragraphs.
        min_width = 0,
    },
})
```

</details>

## Code Blocks

[Wiki Page](https://github.com/MeanderingProgrammer/render-markdown.nvim/wiki/CodeBlocks)

<details>

<summary>Code Block Configuration</summary>

```lua
require('renderer').setup({
    code = {
        -- Turn on / off code block & inline code rendering.
        enabled = true,
        -- Additional modes to render code blocks.
        render_modes = false,
        -- Turn on / off sign column related rendering.
        sign = true,
        -- Whether to conceal nodes at the top and bottom of code blocks.
        conceal_delimiters = true,
        -- Turn on / off language heading related rendering.
        language = true,
        -- Determines where language icon is rendered.
        -- | center | center of code block |
        -- | right  | right of code block  |
        -- | left   | left of code block   |
        position = 'left',
        -- Whether to include the language icon above code blocks.
        language_icon = true,
        -- Whether to include the language name above code blocks.
        language_name = true,
        -- Whether to include the language info above code blocks.
        language_info = true,
        -- Amount of padding to add around the language.
        -- If a float < 1 is provided it is treated as a percentage of available window space.
        language_pad = 0,
        -- A list of language names for which rendering will be disabled.
        disable = {},
        -- A list of language names for which background highlighting will be disabled.
        -- Likely because that language has background highlights itself.
        -- Use a boolean to make behavior apply to all languages.
        -- Borders above & below blocks will continue to be rendered.
        disable_background = { 'diff' },
        -- Number of lines from start/end to skip rendering background.
        background_inset = 1,
        -- Width of the code block background.
        -- | block | width of the code block  |
        -- | full  | full width of the window |
        width = 'full',
        -- Amount of margin to add to the left of code blocks.
        -- If a float < 1 is provided it is treated as a percentage of available window space.
        -- Margin available space is computed after accounting for padding.
        left_margin = 0,
        -- Amount of padding to add to the left of code blocks.
        -- If a float < 1 is provided it is treated as a percentage of available window space.
        left_pad = 0,
        -- Amount of padding to add to the right of code blocks when width is 'block'.
        -- If a float < 1 is provided it is treated as a percentage of available window space.
        right_pad = 0,
        -- Minimum width to use for code blocks when width is 'block'.
        min_width = 0,
        -- Determines how the top / bottom of code block are rendered.
        -- | none  | do not render a border                               |
        -- | thick | use the same highlight as the code body              |
        -- | thin  | when lines are empty overlay the above & below icons |
        -- | hide  | conceal lines unless language name or icon is added  |
        border = 'hide',
        -- Used above code blocks to fill remaining space around language.
        language_border = '█',
        -- Added to the left of language.
        language_left = '',
        -- Added to the right of language.
        language_right = '',
        -- Used above code blocks for thin border.
        above = '▄',
        -- Used below code blocks for thin border.
        below = '▀',
        -- Turn on / off inline code related rendering.
        inline = true,
        -- Icon to add to the left of inline code.
        inline_left = '',
        -- Icon to add to the right of inline code.
        inline_right = '',
        -- Padding to add to the left & right of inline code.
        inline_pad = 0,
        -- Priority to assign to code background highlight.
        priority = 140,
        -- Highlight for code blocks.
        highlight = 'RendererCode',
        -- Highlight for code info section, after the language.
        highlight_info = 'RendererCodeInfo',
        -- Highlight for language, overrides icon provider value.
        highlight_language = nil,
        -- Highlight for border, use false to add no highlight.
        highlight_border = 'RendererCodeBorder',
        -- Highlight for language, used if icon provider does not have a value.
        highlight_fallback = 'RendererCodeFallback',
        -- Highlight for inline code.
        highlight_inline = 'RendererCodeInline',
        -- Highlight for inline code left icon, default to reverse of highlight_inline.
        highlight_inline_left = nil,
        -- Highlight for inline code right icon, default to reverse of highlight_inline.
        highlight_inline_right = nil,
        -- Determines how code blocks & inline code are rendered.
        -- | none     | { enabled = false }                           |
        -- | normal   | { language = false }                          |
        -- | language | { disable_background = true, inline = false } |
        -- | full     | uses all default values                       |
        style = 'full',
    },
})
```

</details>

## Dashed Line

[Wiki Page](https://github.com/MeanderingProgrammer/render-markdown.nvim/wiki/DashedLine)

<details>

<summary>Dashed Line Configuration</summary>

```lua
require('renderer').setup({
    dash = {
        -- Useful context to have when evaluating values.
        -- | width | width of the current window |

        -- Turn on / off thematic break rendering.
        enabled = true,
        -- Additional modes to render dash.
        render_modes = false,
        -- Replaces '---'|'***'|'___'|'* * *' of 'thematic_break'.
        -- The icon gets repeated across the window's width.
        icon = '─',
        -- Width of the generated line.
        -- If a float < 1 is provided it is treated as a percentage of available window space.
        -- Output is evaluated depending on the type.
        -- | function | `value(context)`    |
        -- | number   | `value`             |
        -- | full     | width of the window |
        width = 'full',
        -- Amount of margin to add to the left of dash.
        -- If a float < 1 is provided it is treated as a percentage of available window space.
        left_margin = 0,
        -- Priority to assign to dash.
        priority = nil,
        -- Highlight for the whole line generated from the icon.
        highlight = 'RendererDash',
    },
})
```

</details>

## List Bullets

[Wiki Page](https://github.com/MeanderingProgrammer/render-markdown.nvim/wiki/ListBullets)

<details>

<summary>Bullet Point Configuration</summary>

```lua
require('renderer').setup({
    bullet = {
        -- Useful context to have when evaluating values.
        -- | level | how deeply nested the list is, 1-indexed          |
        -- | index | how far down the item is at that level, 1-indexed |
        -- | value | text value of the marker node                     |

        -- Turn on / off list bullet rendering
        enabled = true,
        -- Additional modes to render list bullets
        render_modes = false,
        -- Replaces '-'|'+'|'*' of 'list_item'.
        -- If the item is a 'checkbox' a conceal is used to hide the bullet instead.
        -- Output is evaluated depending on the type.
        -- | function   | `value(context)`                                    |
        -- | string     | `value`                                             |
        -- | string[]   | `cycle(value, context.level)`                       |
        -- | string[][] | `clamp(cycle(value, context.level), context.index)` |
        icons = { '●', '○', '◆', '◇' },
        -- Replaces 'n.'|'n)' of 'list_item'.
        -- Output is evaluated using the same logic as 'icons'.
        ordered_icons = function(ctx)
            local value = vim.trim(ctx.value)
            local index = tonumber(value:sub(1, #value - 1))
            return ('%d.'):format(index > 1 and index or ctx.index)
        end,
        -- Padding to add to the left of bullet point.
        -- Output is evaluated depending on the type.
        -- | function | `value(context)` |
        -- | integer  | `value`          |
        left_pad = 0,
        -- Padding to add to the right of bullet point.
        -- Output is evaluated using the same logic as 'left_pad'.
        right_pad = 0,
        -- Highlight for the bullet icon.
        -- Output is evaluated using the same logic as 'icons'.
        highlight = 'RendererBullet',
        -- Highlight for item associated with the bullet point.
        -- Output is evaluated using the same logic as 'icons'.
        scope_highlight = {},
        -- Priority to assign to scope highlight.
        scope_priority = nil,
    },
})
```

</details>

## Checkboxes

[Wiki Page](https://github.com/MeanderingProgrammer/render-markdown.nvim/wiki/Checkboxes)

<details>

<summary>Checkbox Configuration</summary>

```lua
require('renderer').setup({
    checkbox = {
        -- Checkboxes are a special instance of a 'list_item' that start with a 'shortcut_link'.
        -- There are two special states for unchecked & checked defined in the markdown grammar.

        -- Turn on / off checkbox state rendering.
        enabled = true,
        -- Additional modes to render checkboxes.
        render_modes = false,
        -- Render the bullet point before the checkbox.
        bullet = false,
        -- Padding to add to the left of checkboxes.
        left_pad = 0,
        -- Padding to add to the right of checkboxes.
        right_pad = 1,
        unchecked = {
            -- Replaces '[ ]' of 'task_list_marker_unchecked'.
            icon = '󰄱 ',
            -- Highlight for the unchecked icon.
            highlight = 'RendererUnchecked',
            -- Highlight for item associated with unchecked checkbox.
            scope_highlight = nil,
        },
        checked = {
            -- Replaces '[x]' of 'task_list_marker_checked'.
            icon = '󰱒 ',
            -- Highlight for the checked icon.
            highlight = 'RendererChecked',
            -- Highlight for item associated with checked checkbox.
            scope_highlight = nil,
        },
        -- Define custom checkbox states, more involved, not part of the markdown grammar.
        -- The key is for healthcheck and to allow users to change its values, value type below.
        -- | raw             | matched against the raw text of a 'shortcut_link'           |
        -- | rendered        | replaces the 'raw' value when rendering                     |
        -- | highlight       | highlight for the 'rendered' icon                           |
        -- | scope_highlight | optional highlight for item associated with custom checkbox |
        -- stylua: ignore
        custom = {
            todo = { raw = '[-]', rendered = '󰥔 ', highlight = 'RendererTodo', scope_highlight = nil },
        },
        -- Priority to assign to scope highlight.
        scope_priority = nil,
    },
})
```

</details>

## Block Quotes

[Wiki Page](https://github.com/MeanderingProgrammer/render-markdown.nvim/wiki/BlockQuotes)

<details>

<summary>Block Quote Configuration</summary>

```lua
require('renderer').setup({
    quote = {
        -- Turn on / off block quote & callout rendering.
        enabled = true,
        -- Additional modes to render quotes.
        render_modes = false,
        -- Replaces '>' of 'block_quote'.
        icon = '▋',
        -- Whether to repeat icon on wrapped lines. This will obscure text
        -- if incorrectly configured with :h 'showbreak', :h 'breakindent' and :h 'breakindentopt'.
        -- A combination of these that is likely to work follows.
        -- | showbreak      | '  ' (2 spaces)   |
        -- | breakindent    | true              |
        -- | breakindentopt | '' (empty string) |
        -- These are not validated by this plugin. If you want to avoid adding these to your main
        -- configuration then set them in win_options for this plugin.
        repeat_linebreak = false,
        -- Highlight for the quote icon.
        -- If a list is provided output is evaluated by `cycle(value, level)`.
        highlight = {
            'RendererQuote1',
            'RendererQuote2',
            'RendererQuote3',
            'RendererQuote4',
            'RendererQuote5',
            'RendererQuote6',
        },
    },
})
```

</details>

## Tables

[Wiki Page](https://github.com/MeanderingProgrammer/render-markdown.nvim/wiki/Tables)

<details>

<summary>Table Configuration</summary>

```lua
require('renderer').setup({
    pipe_table = {
        -- Turn on / off pipe table rendering.
        enabled = true,
        -- Additional modes to render pipe tables.
        render_modes = false,
        -- Pre configured settings largely for setting table border easier.
        -- | heavy  | use thicker border characters     |
        -- | double | use double line border characters |
        -- | round  | use round border corners          |
        -- | none   | does nothing                      |
        preset = 'none',
        -- Determines how individual cells of a table are rendered.
        -- | overlay | writes completely over the table, removing conceal behavior and highlights |
        -- | raw     | replaces only the '|' characters in each row, leaving the cells unmodified |
        -- | padded  | raw + cells are padded to maximum visual width for each column             |
        -- | trimmed | padded except empty space is subtracted from visual width calculation      |
        cell = 'padded',
        -- Fit wide tables to the current window by wrapping individual cells.
        wrap = true,
        -- Adjust the computed width of table cells using custom logic.
        cell_offset = function()
            return 0
        end,
        -- Amount of space to put between cell contents and border.
        padding = 1,
        -- Minimum column width to use for padded or trimmed cell.
        min_width = 0,
        -- Characters used to replace table border.
        -- Correspond to top(3), delimiter(3), bottom(3), vertical, & horizontal.
        -- stylua: ignore
        border = {
            '┌', '┬', '┐',
            '├', '┼', '┤',
            '└', '┴', '┘',
            '│', '─',
        },
        -- Turn on / off top & bottom lines.
        border_enabled = true,
        -- Always use virtual lines for table borders instead of attempting to use empty lines.
        -- Will be automatically enabled if indentation module is enabled.
        border_virtual = false,
        -- Gets placed in delimiter row for each column, position is based on alignment.
        alignment_indicator = '━',
        -- Highlight for table heading, delimiter, and the line above.
        head = 'RendererTableHead',
        -- Highlight for everything else, main table rows and the line below.
        row = 'RendererTableRow',
        -- Determines how the table as a whole is rendered.
        -- | none   | { enabled = false }        |
        -- | normal | { border_enabled = false } |
        -- | full   | uses all default values    |
        style = 'full',
    },
})
```

</details>

## Callouts

[Wiki Page](https://github.com/MeanderingProgrammer/render-markdown.nvim/wiki/Callouts)

<details>

<summary>Callout Configuration</summary>

```lua
require('renderer').setup({
    callout = {
        -- Callouts are a special instance of a 'block_quote' that start with a 'shortcut_link'.
        -- The key is for healthcheck and to allow users to change its values, value type below.
        -- | raw        | matched against the raw text of a 'shortcut_link', case insensitive |
        -- | rendered   | replaces the 'raw' value when rendering                             |
        -- | highlight  | highlight for the 'rendered' text and quote markers                 |
        -- | quote_icon | optional override for quote.icon value for individual callout       |
        -- | category   | optional metadata useful for filtering                              |

        note      = { raw = '[!NOTE]',      rendered = '󰋽 Note',      highlight = 'RendererInfo',    category = 'github'   },
        tip       = { raw = '[!TIP]',       rendered = '󰌶 Tip',       highlight = 'RendererSuccess', category = 'github'   },
        important = { raw = '[!IMPORTANT]', rendered = '󰅾 Important', highlight = 'RendererHint',    category = 'github'   },
        warning   = { raw = '[!WARNING]',   rendered = '󰀪 Warning',   highlight = 'RendererWarn',    category = 'github'   },
        caution   = { raw = '[!CAUTION]',   rendered = '󰳦 Caution',   highlight = 'RendererError',   category = 'github'   },
        -- Obsidian: https://help.obsidian.md/Editing+and+formatting/Callouts
        abstract  = { raw = '[!ABSTRACT]',  rendered = '󰨸 Abstract',  highlight = 'RendererInfo',    category = 'obsidian' },
        summary   = { raw = '[!SUMMARY]',   rendered = '󰨸 Summary',   highlight = 'RendererInfo',    category = 'obsidian' },
        tldr      = { raw = '[!TLDR]',      rendered = '󰨸 Tldr',      highlight = 'RendererInfo',    category = 'obsidian' },
        info      = { raw = '[!INFO]',      rendered = '󰋽 Info',      highlight = 'RendererInfo',    category = 'obsidian' },
        todo      = { raw = '[!TODO]',      rendered = '󰗡 Todo',      highlight = 'RendererInfo',    category = 'obsidian' },
        hint      = { raw = '[!HINT]',      rendered = '󰌶 Hint',      highlight = 'RendererSuccess', category = 'obsidian' },
        success   = { raw = '[!SUCCESS]',   rendered = '󰄬 Success',   highlight = 'RendererSuccess', category = 'obsidian' },
        check     = { raw = '[!CHECK]',     rendered = '󰄬 Check',     highlight = 'RendererSuccess', category = 'obsidian' },
        done      = { raw = '[!DONE]',      rendered = '󰄬 Done',      highlight = 'RendererSuccess', category = 'obsidian' },
        question  = { raw = '[!QUESTION]',  rendered = '󰘥 Question',  highlight = 'RendererWarn',    category = 'obsidian' },
        help      = { raw = '[!HELP]',      rendered = '󰘥 Help',      highlight = 'RendererWarn',    category = 'obsidian' },
        faq       = { raw = '[!FAQ]',       rendered = '󰘥 Faq',       highlight = 'RendererWarn',    category = 'obsidian' },
        attention = { raw = '[!ATTENTION]', rendered = '󰀪 Attention', highlight = 'RendererWarn',    category = 'obsidian' },
        failure   = { raw = '[!FAILURE]',   rendered = '󰅖 Failure',   highlight = 'RendererError',   category = 'obsidian' },
        fail      = { raw = '[!FAIL]',      rendered = '󰅖 Fail',      highlight = 'RendererError',   category = 'obsidian' },
        missing   = { raw = '[!MISSING]',   rendered = '󰅖 Missing',   highlight = 'RendererError',   category = 'obsidian' },
        danger    = { raw = '[!DANGER]',    rendered = '󱐌 Danger',    highlight = 'RendererError',   category = 'obsidian' },
        error     = { raw = '[!ERROR]',     rendered = '󱐌 Error',     highlight = 'RendererError',   category = 'obsidian' },
        bug       = { raw = '[!BUG]',       rendered = '󰨰 Bug',       highlight = 'RendererError',   category = 'obsidian' },
        example   = { raw = '[!EXAMPLE]',   rendered = '󰉹 Example',   highlight = 'RendererHint' ,   category = 'obsidian' },
        quote     = { raw = '[!QUOTE]',     rendered = '󱆨 Quote',     highlight = 'RendererQuote',   category = 'obsidian' },
        cite      = { raw = '[!CITE]',      rendered = '󱆨 Cite',      highlight = 'RendererQuote',   category = 'obsidian' },
    },
})
```

</details>

## Links

[Wiki Page](https://github.com/MeanderingProgrammer/render-markdown.nvim/wiki/Links)

<details>

<summary>Link Configuration</summary>

```lua
require('renderer').setup({
    link = {
        -- Turn on / off inline link icon rendering.
        enabled = true,
        -- Additional modes to render links.
        render_modes = false,
        -- How to handle footnote links, start with a '^'.
        footnote = {
            -- Turn on / off footnote rendering.
            enabled = true,
            -- Inlined with content.
            icon = '󰯔 ',
            -- Custom processing for footnote body to show.
            -- Runs before prefix / suffix are added and superscript processing.
            body = function(ctx)
                return ctx.text
            end,
            -- Replace value with superscript equivalent.
            superscript = true,
            -- Added before link content.
            prefix = '',
            -- Added after link content.
            suffix = '',
        },
        -- Inlined with 'image' elements.
        image = '󰥶 ',
        -- Check custom for 'image' elements.
        image_custom = true,
        -- Inlined with 'email_autolink' elements.
        email = '󰀓 ',
        -- Fallback icon for 'inline_link' and 'uri_autolink' elements.
        hyperlink = '󰌹 ',
        -- Applies to the inlined icon as a fallback.
        highlight = 'RendererLink',
        -- Applies to the link title.
        highlight_title = 'RendererLinkTitle',
        -- Applies to WikiLink elements.
        wiki = {
            -- Turn on / off WikiLink rendering.
            enabled = true,
            -- Inlined with content.
            icon = '󱗖 ',
            -- Hide destination if there is an alias.
            conceal_destination = true,
            -- Custom processing for WikiLink body to show.
            body = function()
                return nil
            end,
            -- Applies to the inlined icon.
            highlight = 'RendererWikiLink',
            -- Highlight for item associated with the WikiLink.
            scope_highlight = nil,
        },
        -- Define custom destination patterns so icons can quickly inform you of what a link
        -- contains. Applies to 'image', 'inline_link', 'uri_autolink', and WikiLink nodes.
        -- When multiple patterns match a link the one with the longer pattern is used.
        -- The key is for healthcheck and to allow users to change its values, value type below.
        -- | icon      | gets inlined before the link text                               |
        -- | pattern   | matched against the destination text                            |
        -- | kind      | optional determines how pattern is checked                      |
        -- |           | pattern | @see :h lua-patterns, is the default if not set       |
        -- |           | suffix  | @see :h vim.endswith()                                |
        -- |           | url     | similar to pattern with additional prefix checks      |
        -- | priority  | optional used when multiple match, uses pattern length if empty |
        -- | highlight | optional highlight for 'icon', uses fallback highlight if empty |
        -- stylua: ignore
        custom = {
            web = { icon = '󰖟 ', pattern = '^http' },
            apple = { icon = ' ', pattern = 'apple%.com', kind = 'url' },
            discord = { icon = '󰙯 ', pattern = 'discord%.com', kind = 'url' },
            github = { icon = '󰊤 ', pattern = 'github%.com', kind = 'url' },
            gitlab = { icon = '󰮠 ', pattern = 'gitlab%.com', kind = 'url' },
            google = { icon = '󰊭 ', pattern = 'google%.com', kind = 'url' },
            hackernews = { icon = ' ', pattern = 'ycombinator%.com', kind = 'url' },
            linkedin = { icon = '󰌻 ', pattern = 'linkedin%.com', kind = 'url' },
            microsoft = { icon = ' ', pattern = 'microsoft%.com', kind = 'url' },
            neovim = { icon = ' ', pattern = 'neovim%.io', kind = 'url' },
            reddit = { icon = '󰑍 ', pattern = 'reddit%.com', kind = 'url' },
            slack = { icon = '󰒱 ', pattern = 'slack%.com', kind = 'url' },
            stackoverflow = { icon = '󰓌 ', pattern = 'stackoverflow%.com', kind = 'url' },
            steam = { icon = ' ', pattern = 'steampowered%.com', kind = 'url' },
            twitter = { icon = ' ', pattern = 'twitter%.com', kind = 'url' },
            wikipedia = { icon = '󰖬 ', pattern = 'wikipedia%.org', kind = 'url' },
            x = { icon = ' ', pattern = 'x%.com', kind = 'url' },
            youtube = { icon = '󰗃 ', pattern = 'youtube[^.]*%.com', kind = 'url' },
            youtube_short = { icon = '󰗃 ', pattern = 'youtu%.be', kind = 'url' },
        },
    },
})
```

</details>

## Signs

[Wiki Page](https://github.com/MeanderingProgrammer/render-markdown.nvim/wiki/Signs)

<details>

<summary>Sign Configuration</summary>

```lua
require('renderer').setup({
    sign = {
        -- Turn on / off sign rendering.
        enabled = true,
        -- Priority to assign to sign.
        priority = nil,
        -- Applies to background of sign text.
        highlight = 'RendererSign',
    },
})
```

</details>

## Indent

[Wiki Page](https://github.com/MeanderingProgrammer/render-markdown.nvim/wiki/Indent)

<details>

<summary>Indent Configuration</summary>

```lua
require('renderer').setup({
    indent = {
        -- Mimic org-indent-mode behavior by indenting everything under a heading based on the
        -- level of the heading. Indenting starts from level 2 headings onward by default.

        -- Turn on / off org-indent-mode.
        enabled = false,
        -- Additional modes to render indents.
        render_modes = false,
        -- Amount of additional padding added for each heading level.
        per_level = 2,
        -- Heading levels <= this value will not be indented.
        -- Use 0 to begin indenting from the very first level.
        skip_level = 1,
        -- Do not indent heading titles, only the body.
        skip_heading = false,
        -- Prefix added when indenting, one per level.
        icon = '▎',
        -- Priority to assign to extmarks.
        priority = 0,
        -- Applied to icon.
        highlight = 'RendererIndent',
    },
})
```

</details>

# Colors

The table below shows all the highlight groups with their default link

| Highlight Group         | Default Group                      | Description                |
| ----------------------- | ---------------------------------- | -------------------------- |
| RendererH1              | @markup.heading.1.markdown         | H1 icons                   |
| RendererH2              | @markup.heading.2.markdown         | H2 icons                   |
| RendererH3              | @markup.heading.3.markdown         | H3 icons                   |
| RendererH4              | @markup.heading.4.markdown         | H4 icons                   |
| RendererH5              | @markup.heading.5.markdown         | H5 icons                   |
| RendererH6              | @markup.heading.6.markdown         | H6 icons                   |
| RendererH1Bg            | DiffText                           | H1 background line         |
| RendererH2Bg            | DiffAdd                            | H2 background line         |
| RendererH3Bg            | DiffChange                         | H3 background line         |
| RendererH4Bg            | DiffDelete                         | H4 background line         |
| RendererH5Bg            | Visual                             | H5 background line         |
| RendererH6Bg            | CursorColumn                       | H6 background line         |
| RendererCode            | ColorColumn                        | Code block background      |
| RendererCodeInfo        | @label                             | Code info, after language  |
| RendererCodeBorder      | RendererCode                       | Code border background     |
| RendererCodeFallback    | Normal                             | Fallback for code language |
| RendererCodeInline      | RendererCode                       | Inline code background     |
| RendererQuote           | @markup.quote                      | Default for block quote    |
| RendererQuote1          | RendererQuote                      | Level 1 block quote marker |
| RendererQuote2          | RendererQuote                      | Level 2 block quote marker |
| RendererQuote3          | RendererQuote                      | Level 3 block quote marker |
| RendererQuote4          | RendererQuote                      | Level 4 block quote marker |
| RendererQuote5          | RendererQuote                      | Level 5 block quote marker |
| RendererQuote6          | RendererQuote                      | Level 6 block quote marker |
| RendererInlineHighlight | RendererCodeInline                 | Inline highlights contents |
| RendererBullet          | Normal                             | List item bullet points    |
| RendererDash            | LineNr                             | Thematic break line        |
| RendererSign            | SignColumn                         | Sign column background     |
| RendererMath            | @markup.math                       | Latex lines                |
| RendererIndent          | Whitespace                         | Indent icon                |
| RendererHtmlComment     | @comment                           | HTML comment inline text   |
| RendererHtmlBold        | @markup.strong                     | HTML bold tags             |
| RendererHtmlItalic      | @markup.italic                     | HTML italic tags           |
| RendererHtmlUnderline   | @markup.underline                  | HTML underline tags        |
| RendererHtmlStrike      | @markup.strikethrough              | HTML strikethrough tags    |
| RendererLink            | @markup.link.label.markdown_inline | Link icon                  |
| RendererLinkTitle       | @markup.link.markdown_inline       | Link title                 |
| RendererWikiLink        | RendererLink                       | WikiLink icon              |
| RendererUnchecked       | @markup.list.unchecked             | Unchecked checkbox         |
| RendererChecked         | @markup.list.checked               | Checked checkbox           |
| RendererTodo            | @markup.raw                        | Todo custom checkbox       |
| RendererTableHead       | @markup.heading                    | Pipe table heading rows    |
| RendererTableRow        | Normal                             | Pipe table body rows       |
| RendererSuccess         | DiagnosticOk                       | Success related callouts   |
| RendererInfo            | DiagnosticInfo                     | Info related callouts      |
| RendererHint            | DiagnosticHint                     | Hint related callouts      |
| RendererWarn            | DiagnosticWarn                     | Warning related callouts   |
| RendererError           | DiagnosticError                    | Error related callouts     |

# Info

## vimwiki

> [!NOTE]
>
> [vimwiki](https://github.com/vimwiki/vimwiki) overrides the `filetype` of
> `markdown` files, as such there are additional setup steps.
>
> - Add `vimwiki` to the `file_types` configuration of this plugin
>
> ```lua
> require('renderer').setup({
>     file_types = { 'markdown', 'vimwiki' },
> })
> ```
>
> - Register `markdown` as the parser for `vimwiki` files
>
> ```lua
> vim.treesitter.language.register('markdown', 'vimwiki')
> ```

## obsidian.nvim

> [!NOTE]
>
> [obsidian.nvim](https://github.com/epwalsh/obsidian.nvim) provides UI functionality
> that is enabled by default. While there may be a way to have the 2 work together,
> for the foreseeable future only one of these plugins should be used for the UI.
> If you choose this plugin disable the `obsidian.nvim` UI with:
>
> ```lua
> require('obsidian').setup({
>     ui = { enable = false },
> })
> ```
>
> You can also do something more custom like lazy loading this plugin via a command
> and adding logic to the config method to disable `obsidian.nvim` as suggested
> in [#116](https://github.com/MeanderingProgrammer/render-markdown.nvim/issues/116),
> though things like this can break at any time given the reliance on internal logic.

## HTML Files

HTML files render too, they are opt in. Add `html` to `file_types`:

```lua
require('renderer').setup({
    file_types = { 'markdown', 'html' },
})
```

The buffer keeps the HTML source and stays editable, the source of the line
under the cursor is shown as usual. On top of the inline tags that work inside
markdown, an HTML file gets:

- the doctype, `<html>`, `<head>` and `<body>` hidden, with only the `<title>`
  text shown, and `<style>` and `<script>` collapsed to one line each
- bullets and numbers for `<ul>`, `<ol>` and `<li>`, using the `bullet` config
- quote icons for `<blockquote>`, using the `quote` config
- a background for `<pre>`, using the `code` config
- a line for `<hr>`, using the `dash` config
- a bordered grid for `<table>`, using the `pipe_table` config
- icons and backgrounds for `<h1>` to `<h6>`, using the `heading` config
- the `link.hyperlink` icon for `<a href>`
- entities like `&amp;` and `&#169;` shown as the character they stand for

The page structure rules and the heading icons only apply to a whole HTML file.
The rest also apply to HTML inside markdown, and can be turned off with the `html`
options `structure`, `list`, `quote`, `pre`, `rule`, `table` and `entity`.

See [Limitations](doc/limitations.md) for what is not rendered.

## CSV, TSV and PSV Files

Files with comma, tab or pipe separated values render as a table too, they are opt
in. Install the parsers with `:TSInstall csv tsv psv` and add the file types to
`file_types`:

```lua
require('renderer').setup({
    file_types = { 'markdown', 'csv', 'tsv', 'psv' },
})
```

Neovim does not detect `.psv` files by default, so for those also add:

```lua
vim.filetype.add({ extension = { psv = 'psv' } })
```

The file is not changed and stays editable, the source of the line under the
cursor is shown as usual. Every column is padded to one width, each separator is
drawn as the `csv.border` character, numbers are right aligned and the first row is
the header, with a rule below it. `wrap` is turned off while rendered. The `csv`
options set the `header`, the highlights and the widths:

- the width of a column comes from the first `sample_rows` rows and every row that
  has been on screen, and it only grows until the file changes, so columns do not
  jump while scrolling
- a field longer than `max_width` is cut and ends with `…`, the rest is shown
  again on the cursor line

See [Limitations](doc/limitations.md) for what is not rendered.

## Images

> [!NOTE]
>
> Images are only supported so far as this plugin will not interfere with others
> like [image.nvim](https://github.com/3rd/image.nvim), however nothing is done
> natively by this plugin.
> It is recommended to enable the `only_render_image_at_cursor` option.

## Additional

- [Limitations](doc/limitations.md): Known limitations of this plugin
- [Custom Handlers](doc/custom-handlers.md): Allow users to integrate custom rendering
  for either unsupported languages or to override / extend builtin implementations
- [Troubleshooting Guide](doc/troubleshooting.md)
- [Purpose](doc/purpose.md): Why this plugin exists
- [Markdown Ecosystem](doc/markdown-ecosystem.md): Information about other `markdown`
  related plugins and how they co-exist

# Acknowledgments

- [headlines.nvim](https://github.com/lukas-reineke/headlines.nvim): The plugin
  that inspired me to create this one and whose implementation I used as a reference
  for the original version
- [crates.nvim](https://github.com/Saecki/crates.nvim): Used the in-process lsp
  implementation as an awesome reference [lsp.lua](https://github.com/saecki/crates.nvim/blob/main/lua/crates/lsp.lua)

