# Change Log

## Pre-release

### Features

- render CSV, TSV and PSV files as aligned tables when `csv`, `tsv` or `psv`
  is added to `file_types` and its tree-sitter parser is installed: every column
  is padded to one width, separators become a border, numbers are right aligned
  and the first row is the header with a rule below it, switch with
  `csv.enabled` and `csv.header`. The file is not changed and stays editable,
  and `wrap` is turned off while rendered. A field longer than `csv.max_width` is
  cut and ends with `…`. A row holding a quoted line break is left as source

## 0.2.1 (2026-10-10)

### Bug Fixes

- render an HTML `<hr>` as a line when another tag follows it, and leave it as
  source when text follows it on the same line

## 0.2.0 (2026-10-04)

### Features

- render plain HTML files when `html` is added to `file_types`: page structure is
  hidden, and lists, quotes, `<pre>`, rules, headings and entities render like
  their markdown counterparts, each switchable under `html`. A page title keeps
  its own line so the cursor can reach the first line of the page
- render HTML `<table>` as a bordered grid using the `pipe_table` config, with
  cell text wrapped to fit the window, switch with `html.table`. Rows are drawn
  over the first line of each `<tr>` so the cursor moves through a table row by
  row. A table whose rows share a line, or have a first line wider than the
  window, is drawn as virtual lines instead
- the cursor moves past lines that are hidden completely, such as the head of an
  HTML file, when anti conceal is off, instead of stalling on them. Scrolling is
  not held back: when it carries the cursor onto hidden lines at the end of a
  buffer it stays there, so the window still reaches the end. Switch with
  `anti_conceal.skip_hidden`

### Bug Fixes

- the cursor no longer shows the source of a wrapped markdown table row: it
  steps over the row like any other hidden line when anti conceal is off

## 0.1.2 (2026-10-04)

### Internal

- file formats are now described in one place, with no change in behaviour

## 0.1.1 (2026-10-04)

### Bug Fixes

- buffers whose root language is not markdown now render when `nested = false`

## 0.1.0 (2026-10-03)

First release of this fork, based on
[render-markdown.nvim](https://github.com/MeanderingProgrammer/render-markdown.nvim) 8.14.0.

### Breaking Changes

- renamed to `renderer.nvim`: module `require('renderer')`, command `:Renderer`,
  highlight groups `Renderer*`, config global `vim.g.renderer_config`,
  health check `:checkhealth renderer`
- require neovim >= 0.12, support for older versions is dropped along with the compatibility layer

### Features

- render common HTML tags (bold, italic, headings, links, images, etc.) in HTML blocks and inline within paragraphs, including `align="center"` and `<center>`
