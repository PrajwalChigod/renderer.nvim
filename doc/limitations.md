# Limitations

## Concealed text keeps unnecessary line breaks

[Upstream ISSUE #82](https://github.com/MeanderingProgrammer/render-markdown.nvim/issues/82)

When text is concealed and line wrapping is enabled the place where the line break
happens will always remain the same. This means even if enough text is concealed
to avoid the need for line wrapping that will not "free up" any lines.

This problem manifests in many different ways and is particularly impactful when
rendering tables with links. The result will often be what appear like random line
breaks, and overall "ugly" results.

This problem stems from how neovim handles character-level concealment and line
wrapping. Concealing more characters cannot remove those screen lines.
Worse yet the issue seems incredibly complicated and unlikely to be solved any time
soon [neovim ISSUE #14409](https://github.com/neovim/neovim/issues/14409).

For tables `pipe_table.wrap = true`, which is the default, provides an alternative
by completely replacing the lines with virtual lines.

## `block` Width Removes Column Features

[Upstream ISSUE #385](https://github.com/MeanderingProgrammer/render-markdown.nvim/issues/385)

This problem impacts both `code` & `heading` rendering when using
`{ width = 'block' }`. Regardless of how wide the actual content is all `colorcolumn`
icons will be hidden on the intersecting lines and `cursorline` will not work.

This occurs because there is no way to create a background highlight that starts
and ends at specific columns. So instead to achieve the effect we combine 2 highlights:

1. `hl_group` + `hl_eol`: results in the entire line being highlighted
2. `virt_text` with many spaces using the background highlight + `virt_text_win_col`:
   results in hiding the highlight after our target column

Why does it work like this? To explain that lets see how else we could implement
this. The starting point would be to avoid highlighting the entire line, so we don't
then need to hide the highlight. This part is easy, just remove `hl_eol = true`
from the first mark, done!

Now we have all the inner text highlighted with the background, so the problem is
now to extend each one of these so it reaches our target column.

Your first thought might be to use `virt_text_pos = 'eol'`, and do some basic math
to figure out how long to make each line. Well, unfortunately `eol` does not mean
right at the end of the line, there's actually a space that gets added before the
mark starts that we cannot get rid of, so this one is a non-starter.

Your second thought might be to use `virt_text_win_col`, but set it to be right
after each line, after that it's the same as the previous approach. To make this
work we need to compute the width of each line exactly. If we make it one too large
we'll have an empty space, too small and we'll cut off text in the code block. To
do this correctly we'll need to properly handle concealed ranges for all of the
code blocks. This isn't impossible but it is slow and error prone since we also
need to handle the odd case where another `markdown` block is nested.

To avoid all this additional complexity we take the approach of using 2 highlights
which works because the simple string width calculation is if anything going to
be an over-estimate which is not really a big deal, just adds some extra padding
in the worst case but the block remains contiguous.

The `colorcolumn` will also be missing on any `virt_lines` marks. This applies to
the lines above and below pipe tables, heading borders, latex formulas, and potentially
others added after the time of writing. With this limitation we have no way around
it other than re-implementing `colorcolumn` in this plugin, which is not something
the author has any interest in doing. Ideally neovim would be able to detect new
virtual lines and apply the `colorcolumn` to them, I do not believe there is any
intentions to do this since virtual lines exist mostly outside the standard buffer.

Below are a few things to try out to improve the aesthetic:

- Use `win_options` to disable `colorcolumn` when rendering, this is my personal
  favorite since `colorcolumn` is really only helpful when editing

```lua
require('renderer').setup({
    win_options = {
        colorcolumn = { default = vim.o.colorcolumn, rendered = '' },
    },
})
```

- Set the `min_width` options to the same value as `colorcolumn`

```lua
require('renderer').setup({
    heading = { width = 'block', min_width = tonumber(vim.o.colorcolumn) },
    code = { width = 'block', min_width = tonumber(vim.o.colorcolumn) },
})
```

- Do not use `block` width, keep the default value of `full`

```lua
require('renderer').setup({
    heading = { width = 'full' },
    code = { width = 'full' },
})
```

## `latex` Formula Positioning

[Upstream ISSUE #6](https://github.com/MeanderingProgrammer/render-markdown.nvim/issues/6)

`latex` formulas that span more than one line cannot be overlaid on the text, so
they are placed above or below it. Only a single line formula can be centered with
`latex.position = 'center'`.

A way around this is to use a separate plugin for `latex` and disable that feature
in this plugin. Different plugins will have different setups, below are some examples:

[latex.nvim](https://github.com/ryleelyman/latex.nvim)

```lua
{
    { 'ryleelyman/latex.nvim', opts = {} },
    {
        'PrajwalChigod/renderer.nvim',
        dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-mini/mini.nvim' },
        opts = {
            latex = { enabled = false },
            win_options = { conceallevel = { rendered = 2 } },
        },
    },
}
```

[nabla.nvim](https://github.com/jbyuki/nabla.nvim)

```lua
{
    { 'jbyuki/nabla.nvim' },
    {
        'PrajwalChigod/renderer.nvim',
        dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-mini/mini.nvim' },
        opts = {
            latex = { enabled = false },
            win_options = { conceallevel = { rendered = 2 } },
            on = {
                render = function()
                    require('nabla').enable_virt({ autogen = true })
                end,
                clear = function()
                    require('nabla').disable_virt()
                end,
            },
        },
    },
}
```

> [!NOTE]
>
> These plugins can rely on a specific `conceallevel` to work properly, which
> you will need to configure in this plugin like in the examples above.

## Does Not Run in Telescope Preview

[Upstream ISSUE #98](https://github.com/MeanderingProgrammer/render-markdown.nvim/issues/98)

Telescope has a special way of previewing files that does not work like a
standard buffer: [info](https://github.com/nvim-telescope/telescope.nvim?tab=readme-ov-file#previewers)

Due to this the events this plugin relies on to attach to and render buffers
do not get triggered.

## HTML Cannot Be Reflowed

Marks decorate the text of the buffer, they cannot move it. Minified HTML, or a
page with many elements on one line, is still hard to read. A reader view for
this is planned.

## Some HTML Tables Are Not Rendered

A `<table>` is replaced by virtual lines, so it is drawn as a grid even when its
cells span lines. These tables are left as source:

- tables with `colspan` or `rowspan` cells, which do not fit a grid
- tables with another table inside a cell, the inner table still renders
- tables that share a line with other text
- tables that do not fit fully inside the visible lines of the window
  (including the margin around it), as the text of a cell comes from the marks
  of the tags inside it
- tables when `conceallevel` is below 2, as Neovim does not hide lines then

Cells are plain text, so block content inside a cell is flattened to one line
of wrapped text.

## The Cursor Cannot Enter Some HTML Tables

Each row of a table is drawn over the first line of its `<tr>`, so the cursor
moves through a table row by row. When that is not possible the whole table is
drawn as virtual lines, which cannot hold the cursor, and with anti conceal off
the cursor steps over the table. This is the case when:

- two rows share a line, or a row shares a line with `<table>` or `</table>`
- the first line of a row is wider than the window and `wrap` is on, as a line
  that wraps takes more than one line on screen even when its text is hidden

# Resolved Limitations

## Telescope Opening File

[Upstream FIX 4ab8359](https://github.com/MeanderingProgrammer/render-markdown.nvim/commit/4ab835985de62b46b6785ae160f5f709b77a0f92)

Should no longer be an issue on any version of neovim if up to date.

Since `telescope` performs several mode change operations to enable previewing and
other nice things like setting `marks` when changing buffers there are scenarios
where a `markdown` file will not render when it is initially opened through `telescope`.

An example of this is when opening a file using `live_grep` and default settings.
The issue stems from `telescope` running two `normal` mode commands in the process
of opening a file. At the time of writing these are:

- Center preview windows on the correct line: [here](https://github.com/nvim-telescope/telescope.nvim/blob/master/lua/telescope/previewers/buffer_previewer.lua#L549)
- Set a `mark` prior to opening a file: [here](https://github.com/nvim-telescope/telescope.nvim/blob/master/lua/telescope/actions/set.lua#L177)

Something about the way these are done causes the file to appear be opened in `insert`
mode despite being in `normal` mode. Additionally there is no `ModeChanged` event
that occurs after this to go back to `normal` mode.

## Which Key Limiting Modes

This is no longer the case as of `which-key` v3 release.

[Upstream ISSUE #43](https://github.com/MeanderingProgrammer/render-markdown.nvim/issues/43)

Since `which-key` interjects when writing commands it can effectively limit the
number of modes available to the user.

This varies by configuration. An example is having the `operators` preset enabled
will prevent the user from entering the operator pending mode. Since this mode cannot
be reached this plugin cannot not do anything special in the operator pending state,
since it effectively does not exist.

This is expected behavior by `which-key`: [which-key ISSUE #534](https://github.com/folke/which-key.nvim/issues/534)

## `csv` Separator Is Fixed Per File Type

Each tree-sitter grammar has its separator built in: `csv` splits on commas, `tsv`
on tabs and `psv` on pipes. A file that uses another separator, such as the
semicolons Excel writes in many European locales, does not parse as `csv` and is
left as it is.

The same grammars decide what a field is, so a quoted field that holds a line break
is left as source, and it is not counted when column widths are measured.

## `csv` Blocks In Markdown Are Not Tables

A fenced code block tagged `csv`, `tsv` or `psv` inside a markdown file is drawn as
a code block. Only a file of one of these types is drawn as a table.
