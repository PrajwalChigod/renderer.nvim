# Architecture

This file is the map of the codebase. Read it before changing anything under
`lua/renderer/core/`, `handler/`, `render/` or `format/`.

How to read it:

- **Part 1 describes code that exists.** Every path, function and field named
  there is on `main`. If part 1 and the code disagree, the code is right and
  part 1 has a bug: fix it in the same change.
- **Part 2 describes code that does not exist yet.** Nothing named only in
  part 2 can be required, called or assumed. It is the agreed design for
  future work, to be followed when that work is done.
- When a part 2 design is implemented, move its text into part 1 in the same
  change and rewrite it in the present tense.
- Update part 1 when a change adds or moves a module, changes the lifecycle,
  or changes one of the rules below. Bug fixes and new options inside an
  existing block do not need an update.

---

# Part 1: how it works today

## What the plugin does

It makes a buffer easier to read without changing its text. A treesitter
parser reads the buffer, the plugin turns syntax nodes into extmarks (icons,
highlights, concealed characters, virtual lines), and neovim draws them. When
the cursor moves onto a line, the marks on that line are removed so the raw
text can be edited. Turning the plugin off removes every mark and the buffer
is exactly as it was.

It is built for markdown. HTML, LaTeX and YAML are handled because they appear
inside markdown, and HTML is also rendered as a file of its own. What the core
needs to know about a file type is declared in one place, a format, so that
more file types can be added as files. Markdown, plain HTML, CSV, TSV, PSV and
DOCX are the formats today. The CSV family is the first one built from nothing: it
adds files and edits none of `core/`. DOCX is the first file that is not text: the
convert layer turns it into a read only markdown buffer, which then renders like
any other.

## The pipeline in one view

```text
buffer text
  -> treesitter parser          one tree per language, injections included
  -> handler (one per language) runs a query, each capture goes to a renderer
  -> renderer (one per capture) emits renderer.Mark values through `Marks`
  -> Extmark (one per mark)     stored on the buffer's Decorator
  -> display                    each extmark shown or hidden for the cursor
```

Everything else is support for this path: `core/manager.lua` decides which
buffers enter it, `core/ui.lua` decides when it runs, `format/` and
`lib/config.lua` decide how it is configured for a buffer.

## Vocabulary

These words have one meaning each in the code and in this file.

| Term      | Meaning                                                                    | Lives in                    |
| --------- | -------------------------------------------------------------------------- | --------------------------- |
| format    | Declaration of a file type: root language, parsers, handlers, defaults     | `format/<name>.lua`         |
| language  | A treesitter language. One buffer has a root language and injected ones    | from the parser             |
| handler   | Turns one language tree into marks: a query plus a capture to renderer map | `handler/<language>.lua`    |
| renderer  | Turns one captured node into marks. Has `setup()` and `run()`              | `render/<language>/*.lua`   |
| mark      | A `renderer.Mark`: a position plus extmark options, not yet applied        | `lib/marks.lua`             |
| extmark   | A mark wrapped so it can be shown and hidden                               | `lib/extmark.lua`           |
| decorator | Per buffer store of extmarks, plus the debounce timer and `changedtick`    | `lib/decorator.lua`         |
| context   | State for one parse of one buffer, discarded after                         | `request/context.lua`       |
| view      | The visible row ranges of a buffer. Only these are parsed and queried      | `request/view.lua`          |
| parse     | The expensive step: compute marks from the trees                           | `Updater:parse` in `ui.lua` |
| display   | The cheap step: show or hide stored extmarks for the cursor position       | `Updater:display`           |
| component | A per buffer config block such as `heading` or `html`                      | `settings.lua`              |
| job       | An external process run in the background, its result cached by input      | `lib/job.lua`               |
| converted | A read only buffer holding a converter's output for a file that is not text | `convert/init.lua`          |

## Rules that must hold

Breaking one of these does not fail loudly. It produces wrong widths, stale
marks or generated files that drift.

1. **The buffer text is never changed.** Everything is extmarks in the
   namespace `ui.ns`. Turning the plugin off must leave the buffer as it was.
2. **Renderers never call the extmark API.** They add marks through the
   `Marks` helper (`self.marks:start`, `:over`, `:add`, `:replace`).
3. **The markdown handler runs last, latex just before it.** The order is set
   in `handlers.run`. Every other handler creates its marks with
   `Marks.new(context, true)`, which records what it conceals and what inline
   text it adds, so that markdown can measure real on screen widths. A new
   handler for a language that can appear inside markdown must pass `true`.
4. **The context lives for one parse.** Get it with `Context.get(buf)`. Do
   not keep state on it across passes, and do not cache it.
5. **Expensive work belongs in parse, not display.** Display runs on every
   cursor move.
6. **Nodes with a syntax error are skipped.** `View:nodes` drops any captured
   node where `has_error()` is true, so a renderer never sees one.
7. **A format is found by root treesitter language, never by filetype.**
8. **Two formats that name the same language must name the same handler
   module.** `format.handler` asserts it.
9. **Config starts in `settings.lua`.** `types.lua` and the config sections
   of `README.md` and `doc/renderer.txt` are generated by `just update`: do
   not edit them by hand. The `M.default` table in `init.lua` must stay a
   literal table, because `scripts/update.py` parses it.
10. **A new component is listed in three places:** its block in
    `settings.lua`, its line in `M.default` in `init.lua`, and its name in
    `Config.components` in `lib/config.lua`.
11. **Highlight groups are `Renderer*`,** defined in `core/colors.lua` as
    default links to standard groups, never as fixed colors.
12. **Neovim 0.12 is the minimum.** There is no compatibility layer, so use
    0.12 APIs directly.
13. **A converted buffer is never writable.** `convert/init.lua` sets
    `buftype = 'nowrite'` before the buffer holds any converted text, so `:w`
    cannot overwrite the original file, and refuses any write of a converted
    buffer to a file matching its format's patterns.

## Layout

| Path                        | Role                                                              |
| --------------------------- | ----------------------------------------------------------------- |
| `plugin/renderer.lua`       | Entry point: version guard, then setup and init of the core       |
| `lua/renderer/init.lua`     | `setup()`, the default config table, config resolution            |
| `lua/renderer/settings.lua` | Every config block: default value, types and validation schema    |
| `lua/renderer/types.lua`    | User facing config types, generated by `just update`              |
| `lua/renderer/state.lua`    | Global config and the per buffer config cache                     |
| `lua/renderer/api.lua`      | Public functions, each also a `:Renderer <name>` command          |
| `lua/renderer/core/`        | The engine: attach, update loop, cursor, handler dispatch, logs   |
| `lua/renderer/handler/`     | One file per treesitter language: a query and a capture map       |
| `lua/renderer/render/`      | One renderer per kind of node, grouped by language                |
| `lua/renderer/format/`      | The format registry and one declaration per format                |
| `lua/renderer/convert/`     | Opens files that are not text as read only converted buffers      |
| `lua/renderer/request/`     | State that lives for one render pass                              |
| `lua/renderer/lib/`         | Helpers: marks, nodes, lines, display width, entities, config, jobs |
| `lua/renderer/parser/`      | The pipe table parser                                             |
| `lua/renderer/integ/`       | Completion sources (LSP, blink, cmp, coq)                         |
| `lua/renderer/debug/`       | Mark inspector, config diff, schema validator                     |
| `lua/renderer/health.lua`   | `:checkhealth renderer`                                           |
| `tests/`, `benches/`        | Plenary specs and benchmarks                                      |

## Lifecycle

### 1. Startup

`plugin/renderer.lua` runs once. It refuses neovim older than 0.12, then:

1. `require('renderer').setup(vim.g.renderer_config)` resolves the config:
   defaults, then the preset, then the user's table, merged in that order.
   Plugin managers differ in whether they call `setup` before or after the
   plugin directory loads, so `setup` ignores an empty call once it has been
   initialized.
2. `state.setup(config)` stores the global values and clears the per buffer
   config cache. It calls `core/ts.lua` to add configured treesitter
   injections, `core/ui.lua` to clear existing marks, and `convert/init.lua`
   to register a `BufReadCmd` for each converted format in `file_types`.
3. `colors.init()` defines the `Renderer*` highlight groups, each linked to a
   standard group.
4. `command.init()` creates `:Renderer`. `log.init()` picks the log file and
   arranges for buffered entries to be written on exit.
5. `manager.init()` registers a `FileType` autocmd for every buffer and a
   global `WinResized` autocmd.

### 2. Attach

`core/manager.lua` decides which buffers the plugin owns. On `FileType`,
`should_attach(buf)` rejects the buffer if it is already attached, invalid,
its filetype is not in `file_types`, its file is larger than `max_file_size`,
or the user's `ignore` function returns true. A converted buffer is checked
against the name of its source format (`docx`) instead of its filetype, against
the size of its converted text instead of the file, and is rejected when its
output has no format, as plain `text` output has not.

For an accepted buffer it builds the buffer's config, calls the `on.attach`
callback, and runs one time setup (`state.attach`): disabling some treesitter
highlight patterns and starting the completion integration. It then registers
autocmds on that buffer for the events that can change what should be shown
(cursor movement, text changes, mode changes, scrolling, window enter), plus
the insert mode versions when rendering is enabled in insert mode. Each event
calls `ui.update(buf, win, event, force)`.

### 3. Update

`core/ui.lua` holds the render loop. `ui.update` creates an `Updater`:

```text
Updater:start   skip if buffer or window is gone
                debounce through the buffer's Decorator, unless the event is 'Job'
Updater:run     read the mode
                render? = config.enabled
                          and the mode is a render mode
                          and the window is not scrolled sideways (leftcol == 0),
                              unless the buffer's format sets scroll
                          and not in diff mode (unless render.diff)
                set win_options to their 'rendered' or 'default' value
                render -> Updater:render, otherwise clear every mark
Updater:render  if forced, or the buffer changed, or the visible range is new:
                  parse, then replace the stored marks
                display
```

The debounce runs the first update and drops every other one that arrives
within `debounce` ms. An update sent when a job finishes (event `'Job'`) is
not debounced: dropped, the job's output would not be drawn until the next
event.

There are two separate steps, and the difference matters for performance:

- **Parse** computes marks. It is the expensive step and runs only when the
  buffer text changed (tracked with `changedtick`), the visible range moved
  outside what was computed, or the update was forced.
- **Display** decides which of the stored marks are shown right now. It runs
  on every update, including each cursor move, and is cheap.

### 4. Parse

```text
vim.treesitter.get_parser(buf)          no parser -> log an error, stop
Context.new(buf, win, config)           fresh state for this pass
view:parse(parser)                      parse only the visible ranges
handlers.run(context, parser)           -> renderer.Mark[]
Extmark.new for each mark               -> stored on the Decorator
```

The `View` (`request/view.lua`) is the set of row ranges visible in any window
showing the buffer, plus ten rows of padding. Only those ranges are parsed and
queried, which is what keeps large files fast.

### 5. Display

`Updater:display` works out the rows to leave raw: the cursor row plus
`anti_conceal.above` and `below`, or the selected rows in visual mode. For
each stored mark it calls `Updater:hide`, which hides a mark when its modes do
not include the current mode, or when it overlaps those rows and is
concealable. `anti_conceal.ignore` can keep chosen kinds of mark, such as
signs, visible on the cursor row.

`lib/decorator.lua` then shows or hides each extmark. It also handles
**replace marks**: a mark that hides whole lines and supplies virtual lines to
stand in for them, used by wrapped table rows. Neovim does not draw virtual
lines attached to a hidden row, so `lib/replacements.lua` moves them above the
next visible row.

`core/cursor.lua` keeps the cursor off lines Neovim hides with `conceal_lines`.
Neovim does not skip them itself: `j` moves one buffer line at a time, so the
cursor walks through a hidden head or list tag with nothing changing on
screen. `cursor.skip` asks `nvim_win_text_height` whether the cursor row has
height 0, which already accounts for `concealcursor` and so is false whenever
anti-conceal reveals the row, then moves to the nearest visible row in the
direction of travel, keeping the wanted column. It is called from two places:

- the `CursorMoved` autocmd in `core/manager.lua`, before the update is
  scheduled. Neovim draws the screen between the autocmd and a scheduled
  callback, so moving the cursor any later shows it on the hidden line for one
  frame. A mark with `reveal` (see Marks) is a problem here: its rows are
  hidden until the update reveals it, so this skip would push the cursor out
  of rows it is meant to reveal. `ui.reveal` runs first, and when a shown mark
  with `reveal` would be hidden for the new cursor row it runs the display step
  at once (`Updater:show`, which ends with the skip), otherwise the skip runs
  on its own. It only gives up when the text changed, not when the view moved
  past the parsed rows, since marks keep their positions until an edit. It
  runs on every cursor move, so `Decorator` keeps the marks with `reveal` in
  their own list and `ui.reveal` returns at once when that list is empty. Known
  limit: after an edit (an undo, for example) that puts the cursor on a hidden
  row of a block, the stored rows are stale and the early skip runs, so the
  cursor can land on another row of the block;
- the end of `Updater:display`, for marks that are drawn under a cursor that
  did not move: the first render, and a jump into rows that had not been
  parsed.

A count is left as Neovim applies it, in buffer lines, because that is what
the number column shows: with `relativenumber` the line labelled 5 is reached
with `5j` whether or not hidden lines lie between. Only the landing line is
corrected. It runs in normal and visual modes and can be turned off with
`anti_conceal.skip_hidden`. The last row and direction of each window are kept
in `cursor.last`, which `cursor.forget` clears when the window closes
(`WinClosed` in `core/manager.lua`) or stops being rendered.

When nothing visible lies ahead, at either end of the buffer, the cursor goes
back to the last visible row. One case is left alone: scrolling can carry the
cursor onto hidden rows at the end of the buffer, because Neovim keeps it
`scrolloff` lines below the top of the window. The last visible row is then
closer to the top than that, and putting the cursor back on it makes Neovim
undo the scroll, so the window would bounce instead of reaching the end.
`cursor.fits` measures the screen lines above the row and the cursor only goes
back when there are enough, otherwise it stays on the hidden row, where Neovim
put it.

Rows hidden by a replace mark are skipped like any other, so a wrapped table
row, or an HTML table replaced as a whole, stays drawn and the cursor steps
over it. `Updater:hide` has an older answer to the same problem: it hides a
replace mark whose first row holds the cursor, so that the source shows. With
skipping on the cursor never rests there, so that rule only acts when skipping
is off.

## Handlers and renderers

`core/handlers.lua` walks every language tree in the buffer, including
injected ones, and keeps a tree when:

- there is a custom or builtin handler for its language. Builtin handlers
  are found through the format registry, required on first use and cached;
- nesting allows it: `nested` is true, or the tree has at most one markdown
  tree in its chain of ancestors. The count is 0 for a root tree of another
  language, such as `html` in a `.html` file, 1 for markdown or a language
  injected into it, and 2 or more for markdown nested in markdown. Only the
  last is what `nested = false` turns off;
- its root overlaps the view.

Trees are grouped by language and the languages run in a fixed order:
`markdown` last, `latex` just before it, every other language before those.
The order exists because of a dependency between handlers. The inline
handlers record what they conceal and what inline text they add into the
request context. The markdown handler runs last so that when it measures a
table cell or a heading, it knows the width the text will really have on
screen.

A handler has one function:

```lua
---@class renderer.Handler
---@field extends? boolean
---@field parse fun(ctx: renderer.handler.Context): renderer.Mark[]

---@class renderer.handler.Context
---@field buf integer
---@field root TSNode
---@field last boolean      true for the last tree of this language
```

Users can supply their own through `custom_handlers`, keyed by language. A
custom handler replaces the builtin one unless it sets `extends`.

Every builtin handler has the same shape: a treesitter query, a table from
capture name to renderer, and a loop.

| Handler                       | Captures and their renderers                                                                   |
| ----------------------------- | ---------------------------------------------------------------------------------------------- |
| `handler/markdown.lua`        | code (then mermaid), dash, document, footnote, heading, list, paragraph, quote, section, table |
| `handler/markdown_inline.lua` | code, highlight, link, shortcut                                                                |
| `handler/html.lua`            | comment, tag, doctype, entity, raw                                                             |
| `handler/csv.lua`             | row                                                                                            |
| `handler/yaml.lua`            | bullet, link                                                                                   |
| `handler/latex.lua`           | no query: collects formula nodes, converts them with an external tool, emits virtual lines     |

A renderer extends `render/base.lua` and implements two methods. `setup()`
reads config and returns false to skip the node. `run()` emits marks.
`Base:execute` creates an instance per node and returns what `setup()`
returned.

### HTML renderers

`handler/html.lua` runs for HTML inside markdown and for a whole `.html` file,
so its renderers fall in two groups. The `tag` capture goes to
`render/html/tag.lua`, which hides tags and applies the `html.tag` config, and
then to one element renderer chosen by tag name, through the `elements` table
in `handler/html.lua`. Element renderers extend `render/html/element.lua`,
which resolves the tag name, start tag and end tag, skips the node when its own
`enabled()` returns false, and offers `alone` and `hide`: a tag alone on its
lines is hidden with
`conceal_lines`, otherwise only the tag is concealed. Renderers that replace
lines with virtual lines (`head`, `raw`, `table`) also check `replaceable`,
which needs `conceallevel` 2 or more because Neovim does not hide lines below
that.

A virtual line cannot hold the cursor, so `head.lua` avoids one where it can:
when the `title` has a line of its own, that line stays, with its tags
concealed, and only the lines around it are hidden. The title is then a real
line the cursor can rest on and the first line of the page. A title that
shares its line with other tags is still shown as a virtual line.

| Renderer in `render/html/` | Applies to                              | Group     | Switch                     |
| -------------------------- | --------------------------------------- | --------- | -------------------------- |
| `doctype.lua`              | `doctype`                               | structure | `html.structure`           |
| `page.lua`                 | `html`, `body`                          | structure | `html.structure`           |
| `head.lua`                 | `head`, shows the title                 | structure | `html.structure`           |
| `raw.lua`                  | `script`, `style` summaries             | structure | `html.structure`           |
| `list.lua`                 | `ul`, `ol`, `li`                        | block     | `html.list`, `bullet`      |
| `quote.lua`                | `blockquote`                            | block     | `html.quote`, `quote`      |
| `pre.lua`                  | `pre`                                   | block     | `html.pre`, `code`         |
| `rule.lua`                 | `hr`                                    | block     | `html.rule`, `dash`        |
| `table.lua`                | `table`, drawn from `pipe_table` config | block     | `html.table`, `pipe_table` |
| `heading.lua`              | `h1` to `h6`, `.html` file only         | structure | `heading`                  |
| `link.lua`                 | `a` with `href`                         | block     | `link`                     |
| `entity.lua`               | `entity`, decoded by `lib/entities.lua` | block     | `html.entity`              |

Structure renderers and `heading.lua` skip the node unless
`context.format.name == 'html'` (`Element:file`), so a markdown buffer
containing `<html>` or `<body>` keeps those lines. Block renderers run wherever HTML appears and reuse
the config and highlights of their markdown counterparts. `html.tag` is not
extended: new element behaviour goes in its own renderer.

`table.lua` is built from the marks of what is inside its cells, so the
handler runs it after every other capture, once the inline marks exist. Those
marks only exist for rows in the view, which is why a table is drawn only when
`View:covers` says it lies fully inside. It reads cell text with
`lib/display.lua` and lays the grid out with the helpers of `parser/table.lua`
that markdown wrapped rows use. A table it cannot draw (spans, a table inside
a cell, an end tag missing) is left as source.

The grid is put on screen in one of two ways. Where it can be, each row is
drawn over the first line of its `tr`: the text of that line is concealed, the
row is laid over it as overlay virtual text, and every other line of the table
is hidden. Borders, and the further lines of a row that wraps, are virtual
lines above the next kept line, and what follows the last row is a replace mark
on the end tag. The rows are then lines of the buffer, which the cursor can
rest on and move through. This needs every `tr` to start on a line of its own
between the tags of the table, and that line to fit the window, because a line
that wraps takes more than one line on screen even with its text concealed.
Otherwise the whole element is replaced with one `marks:replace`, and the
cursor steps over it.

### CSV renderers

`handler/csv.lua` serves `csv`, `tsv` and `psv`. It collects the rows in view,
asks `render/csv/widths.lua` for the column widths, and only then runs
`render/csv/row.lua` for each row, because a row is padded to the widest field
of its column and so needs widths that come from other rows.

`row.lua` walks the children of a `row` node: a named child is a field, an
anonymous child is a separator. Each field gets inline virtual text up to the
column width, after the field for text and before it for `number` and `float`
(and a number the grammar read as text because of its sign). Each separator is
overlaid with `csv.border`, except a tab: a tab fills to the next tab stop,
which moves with the padding in front of it, so it is concealed and the border
added inline next to it. A border that is not one cell wide is added the same
way, drawn over the separator it would cover the field after it. A field wider
than its column, which `max_width` caps, is cut: what fits is kept, the rest
concealed and an `…` added in its place. The first row of the document, when
`csv.header` is true, uses `csv.head` and gets one virtual line below it as a
rule, with `virt_lines_overflow = 'scroll'` so it moves sideways with the rows.
A row that spans several lines, because a quoted field holds a line break, is
left as source and takes no part in the widths.

The handler map is shared between formats, so a `csv` block fenced in a
markdown file reaches `handler/csv.lua` as an injected tree. The handler
returns no marks unless the buffer's own format is one of the csv family, and
the block stays a code block.

`widths.lua` keeps one small cache per buffer, keyed by `changedtick`, `sample_rows`
and `max_width`. It is filled from the first `sample_rows` rows and every row that
comes into view, a width only grows, and any change of the buffer starts it again.
Measuring the whole file is too slow and measuring only the view makes columns
jump while scrolling. This is the one place state outlives a parse (rule 4 is about
the request context), so it is the only module to clear on `BufWipeout`.

### Mermaid renderer

`render/markdown/mermaid.lua` draws a fenced block whose language is `mermaid`
as its diagram. It is not a capture of its own: `handler/markdown.lua` keeps a
table of extra renderers per capture, and runs it after `render/markdown/code.lua`
on every `code` node. The code renderer draws the block as usual, and the
mermaid renderer adds to it or, in `setup()`, returns false and adds nothing.
It needs no treesitter parser for mermaid, no format and no handler.

`setup()` sends the text between the fences (`Render.input`, which removes
the block's indentation from every line but the first) to `mermaid.converter`
through `lib/job.lua`. On a miss the job starts and the block stays a code
block. The job's callback runs `ui.update(buf, win, 'Job', true)`, at most once
per batch of callbacks and only while rendering is still enabled for the
buffer, and the next parse finds the result in the cache. A failure is cached
too, logged at `debug` (half typed diagrams fail on every edit), and also leaves
the code block. Carriage returns are dropped from the output and tabs expanded,
since virtual text would show them as `^M` and `^I`. The block is
also left alone when it has no body, sits in a `block_quote` (the quote bar is
not drawn on virtual lines), `conceallevel` is below 2, or the converter is not
executable.

On a hit `run()` adds two marks:

- `conceal_lines` over the body and the closing fence;
- the diagram as `virt_lines` below the opening fence, padded to one width,
  after the indent line and the fence column.

The opening fence keeps the code renderer's language header and is a real
line the cursor can rest on, and virtual lines below a visible line are always
drawn, which is why this is not a replace mark. Both marks set `reveal` to the
rows from the opening to the closing fence (see Marks), so the cursor on any of
those rows shows the source, and the cursor walks into the block from either
side: from above it lands on the fence line, from below on the closing fence
or, when the code renderer hides the closing fence, `cursor.skip` moves it up
into the body. Jumps and searches stay on the row they reach, see `ui.reveal`
under the cursor notes above.
This follows `anti_conceal` like every mark, unless `mermaid.always_reveal`
sets `reveal.always`.

## Formats

`lua/renderer/format/init.lua` is the registry, with one file per format next
to it. A format declares what the core needs to know about a file type:

```lua
---@class renderer.Format
---@field name string
---@field root string                        root treesitter language
---@field languages table<string, boolean>   treesitter language -> required
---@field handlers table<string, string>     treesitter language -> handler module
---@field defaults? renderer.partial.UserConfig
---@field scroll? boolean                    keep rendering when scrolled sideways
---@field source? renderer.format.Source     a file that is not text

---@class renderer.format.Source
---@field patterns string[]                  BufReadCmd patterns, e.g. '*.docx'
---@field config string                      key under `convert` holding converters
---@field takeover? fun()                    remove a competing BufReadCmd
```

There are six formats: `markdown`, `html`, `csv`, `tsv`, `psv` and `docx`:

```lua
-- format/markdown.lua
return {
    name = 'markdown',
    root = 'markdown',
    languages = {
        markdown = true,
        markdown_inline = true,
        html = false,
        latex = false,
        yaml = false,
    },
    handlers = {
        html = 'renderer.handler.html',
        latex = 'renderer.handler.latex',
        markdown = 'renderer.handler.markdown',
        markdown_inline = 'renderer.handler.markdown_inline',
        yaml = 'renderer.handler.yaml',
    },
}

-- format/html.lua
return {
    name = 'html',
    root = 'html',
    languages = { html = true },
    handlers = { html = 'renderer.handler.html' },
}

-- format/csv.lua, one builder called for csv, tsv and psv
local function build(name)
    return {
        name = name,
        root = name,
        languages = { [name] = true },
        handlers = { [name] = 'renderer.handler.csv' },
        scroll = true,
        defaults = {
            win_options = {
                wrap = { default = vim.o.wrap, rendered = false },
            },
        },
    }
end
return { build('csv'), build('tsv'), build('psv') }

-- format/docx.lua
return {
    name = 'docx',
    root = 'docx',
    languages = { markdown = true, markdown_inline = true, html = false, latex = false },
    handlers = {},
    source = {
        patterns = { '*.docx' },
        config = 'docx',
        takeover = function() --[[ clear the zip plugin's *.docx BufReadCmd ]] end,
    },
}
```

A converted format has no root language of its own: its buffers hold markdown
and resolve to the markdown format. Its `root` is its own name, which no
treesitter language has, so that `registry.root` finds it from `file_types` for
the health check. It has no handlers, and `languages` lists the parsers its
output needs.

The three grammars share one definition and differ in the separator, so each
is its own format with its own root language. A format file returns either one
format or a list of them, and `format.all()` accepts both. A new handler module
can serve several languages: `handler/csv.lua` reads the language from the root
of the buffer's format and keeps one compiled query per language, because
`ts.parse` caches by query text alone.

A format has exactly one root language. **Lookup is by root treesitter
language, not filetype.** `format.get(buf)` resolves
`vim.treesitter.language.get_lang(filetype)` and returns the format whose
`root` matches. Users list filetypes such as `rmd` or `codecompanion` in
`file_types` and map them to the markdown parser, and those resolve to
markdown. A root language with no format (`gitcommit` with its markdown
injection, or a `custom_handlers` only setup) returns nil: no defaults, and
the buffer still attaches and renders through whatever handlers exist.

Who reads it:

| Consumer              | Reads             | For                                              |
| --------------------- | ----------------- | ------------------------------------------------ |
| `core/handlers.lua`   | `handlers`        | the builtin handler for a language               |
| `request/context.lua` | the format itself | `context.format`, so a handler knows its host    |
| `lib/config.lua`      | `defaults`        | per buffer config, applied before the overrides  |
| `core/ui.lua`         | `scroll`          | whether to keep rendering when scrolled sideways |
| `health.lua`          | `languages`       | the parsers `:checkhealth` reports               |
| `health.lua`          | `source`          | the converter `:checkhealth` reports             |
| `convert/init.lua`    | `source`          | the `BufReadCmd` and the converters to run       |

The handler map is keyed by language and shared between formats.
`format.handler(language)` looks across all formats, and if two formats name
the same language they must name the same module; the registry asserts this.

Only the CSV family sets `defaults` and `scroll`: its rows are wider than the
window, so `wrap` is off while rendered and rendering continues when scrolled
sideways. `context.format` is read by the HTML structure renderers. Only DOCX
sets `source`.

## Convert layer

`lua/renderer/convert/init.lua` turns a file that is not text into a buffer the
pipeline can render. It adds no renderers: the output is markdown, and the
markdown format draws it.

```text
setup            for each format with a source, in file_types, converter installed:
                   BufReadCmd on its patterns, takeover() now and on SourcePost
BufWritePre etc  throw when a converted buffer is written to its patterns
BufReadCmd       file gone and buffer converted before?  say so, stop
                 buftype nowrite, noswapfile
                 cached?  set lines at once
                 no       placeholder line -> job.run(converter, disk = true)
  on success     set lines, lock the buffer, set filetype to the converter's output
  on failure     show the command and stderr, filetype left empty
FileType         manager.attach, the normal pipeline from here
```

The converters of a format are under `convert.<config>` in the global config,
each a `cmd` in which `{file}` is replaced with the path, and an `output`
filetype. The first whose executable is installed is used. The convert block is
global, not a component: the `BufReadCmd` is registered at setup, before any
buffer exists.

The buffer contract:

| Property     | Value                | Why                                            |
| ------------ | -------------------- | ---------------------------------------------- |
| name         | the real file path   | `:e`, buffer lists and pickers behave normally |
| `buftype`    | `nowrite`            | `:w` cannot overwrite the binary with text     |
| `modifiable` | false                | nothing to edit                                |
| `swapfile`   | false                | no swap file next to a document                |
| `filetype`   | `markdown` or `text` | set by the converter's `output`                |

`buftype = 'nowrite'` is the safety property of the whole feature and has its
own spec. It stops `:w` and `:w!`, but not a write to another name: `:w other.md`
saves the converted text, which is wanted, and after `:saveas other.md` a
`:w! file.docx` would write it over the original. So `BufWritePre`,
`FileWritePre` and `FileAppendPre` on the format's patterns throw for a buffer
that has `b:renderer_convert`, which aborts the write. It has to be a Vimscript
`throw` (`convert.guard`): an error from a Lua callback is reported but a typed
`:w!` still writes, it only aborts when the write runs inside `vim.cmd`. The spec
runs its writes in a child neovim for this reason. `nowrite` also keeps language
servers started by `vim.lsp.enable` away, as those skip buffers with a
`buftype`. The lines are set with `undolevels = -1`, so `u` has nothing to undo.

Converted buffers get `overrides.convert`, by default `render_modes = true` with
`anti_conceal` off. It is not keyed on `buftype`: other plugins (diffview,
fugitive) make `nowrite` buffers too, and those keep the normal config.

What `should_attach` needs is kept in `vim.b[buf].renderer_convert`
(`convert.get(buf)`): the source format name, the size of the converted text,
and the id of the read that filled the buffer. A conversion that finishes after
the buffer was read again carries an older id and is dropped, and so is one for
a buffer that was unloaded meanwhile, since setting its lines would load it
again. Setting the filetype attaches a buffer seen for the first time, which
renders it. Reading an attached buffer again (`:e`) replaces its lines and forces
an update instead, since `FileType` does not attach twice.

The request passes the path in `cmd` and the file's mtime and size as `key`, so
the file is converted again only when it changes, and sets `disk` so the result
outlives the session. A file that does not exist is left as an empty, ordinary
buffer, unless the buffer was converted before: then the file was moved or
deleted, and the buffer says so and stays read only. Nothing reads the file
again on its own, `autoread` and `:checktime` do not see a converted buffer
change, so `:e` is the way to pick up a new version.

Without a converter, or without the format in `file_types`, nothing is
registered and `.docx` keeps opening in the zip browser. The zip plugin can be
sourced after this plugin at startup, so `takeover` runs once at setup and again
on every `SourcePost` of a `plugin/` file. It removes only the zip plugin's
`*.docx` autocmd, every other archive stays with it.

## Marks

A renderer never calls the extmark API. It adds a `renderer.Mark` through the
`Marks` helper (`lib/marks.lua`):

```lua
---@class renderer.Mark
---@field modes? renderer.Modes          extra modes this mark shows in
---@field conceal boolean|string         hide on the cursor row? or a kind name
---@field start_row integer
---@field start_col integer
---@field opts vim.api.keyset.set_extmark
---@field replace? renderer.mark.Line[]  virtual lines standing in for hidden rows
---@field reveal? renderer.mark.Reveal   rows that reveal the mark, see below
```

`conceal` controls anti conceal. `true` means hide the mark near the cursor,
`false` means always show it, and a string names a kind (`'sign'`,
`'table_border'`, `'virtual_lines'`) that `anti_conceal.ignore` can keep
visible.

A mark is revealed when the cursor rows overlap its own rows. `reveal.rows`
replaces those rows, so that a mark can be revealed from rows it does not
cover, such as the mermaid diagram attached to the fence line and revealed by
every row of its block. `Marks:add` takes it as a last argument and
`Extmark.new` uses the rows as the range `Extmark:overlaps` checks.
`reveal.always` makes the cursor reveal the mark even when anti-conceal is
disabled or the mode is in `disabled_modes`: `Updater:display` works out the
cursor rows twice, `Updater:hidden(false)` for every mark and
`Updater:hidden(true)`, which ignores those two settings, for these.

`Marks.new(context, update)` takes a flag. When it is true, each mark is also
recorded in the request context (what it conceals, what inline text it adds).
The inline, HTML, YAML and LaTeX handlers set it. The markdown handler does
not, since it runs last and nothing reads its marks.

## Request context

`request/context.lua` is created fresh for each parse and thrown away after.
Handlers reach it with `Context.get(buf)`.

| Field        | Holds                                                                    |
| ------------ | ------------------------------------------------------------------------ |
| `format`     | the buffer's format, nil when its root language has none                 |
| `view`       | visible row ranges, and the query helpers that respect them              |
| `config`     | the buffer's resolved config                                             |
| `conceal`    | how many cells of a text range are concealed, used to measure width      |
| `highlights` | concealed ranges and highlight groups per row, from treesitter and marks |
| `inline`     | inline virtual text added per row, also for measuring width              |
| `used`       | empty rows already taken by a border, so two borders do not collide      |
| `callout`    | callouts found in block quotes, shared between quote and paragraph       |
| `checkbox`   | checkboxes found in list items, shared between list and paragraph        |
| `latex`      | formula nodes collected until the last latex tree                        |

## Configuration

`settings.lua` is the source of truth. Each block has a `default` table, type
annotations and a `schema()` function. `init.lua` assembles the blocks into
`M.default`. `lib/config.lua` keeps one list of block names,
`Config.components`, and builds both the per buffer config and its schema
from it. `scripts/update.py` reads both files to generate `types.lua` and
the config sections of the README and vimdoc, so config changes start in
`settings.lua` and are followed by `just update`.

Config values are of two kinds:

- **Global** (`renderer.state.Config`): `file_types`, `max_file_size`,
  `nested`, `injections`, `custom_handlers` and similar. Stored on
  `state.lua`.
- **Per buffer** (`renderer.partial.Config`): `enabled`, `render_modes`, and
  every rendering block such as `heading`, `code`, `html`. Built by
  `lib/config.lua` the first time a buffer is seen and cached.

The per buffer config starts from the root config, applies the `defaults` of
the buffer's format, and then applies `overrides` in this order, later ones
winning: `buflisted`, `buftype`, `filetype`, `convert` (for a converted
buffer), `preview` (for the preview buffer), then any config passed to
`api.render`. This is how hover windows,
which are `nofile` buffers, get different settings from files. A preview
buffer uses the format of its source buffer, as it does for the overrides.
Format `defaults` are applied on top of the user's top level config, so a
user can only change a value that a format sets through `overrides`.

`:checkhealth renderer` validates the whole config against the schemas. It
reports the parsers of every format reachable from `file_types`: the required
ones, then the optional ones whose config block is enabled. A language that
is required by one format and optional in another is reported as required.

## How to make common changes

| To do this                                | Change these                                                                                                |
| ----------------------------------------- | ----------------------------------------------------------------------------------------------------------- |
| Render a new node type in a language      | capture in the query and entry in `renders` in `handler/<language>.lua`, new `render/<language>/<name>.lua` |
| Change how an existing node renders       | its renderer under `render/`                                                                                |
| Render a new HTML element                 | its tag in `elements` in `handler/html.lua`, new `render/html/<name>.lua` extending `element.lua`           |
| Add an option to an existing component    | type, default and schema in `settings.lua`, then `just update`                                              |
| Add a component                           | rule 10, then `just update`                                                                                 |
| Add a highlight group                     | `M.colors` in `core/colors.lua`, and the highlight table in `README.md`                                     |
| Add a `:Renderer` subcommand              | a function in `api.lua`, `core/command.lua` picks it up                                                     |
| Support a language injected into a format | `languages` and `handlers` in the format file, new `handler/<language>.lua` (rule 3)                        |
| Add a format                              | `format/<name>.lua`, its name in `M.names` in `format/init.lua`, a handler for its root language            |
| Change when rendering is on or off        | `Updater:run` in `core/ui.lua`                                                                              |
| Change which buffers are picked up        | `should_attach` in `core/manager.lua`                                                                       |
| Change what the cursor row reveals        | `Updater:hidden` and `Updater:hide` in `core/ui.lua`                                                        |

A new renderer has this shape:

```lua
local Base = require('renderer.render.base')

---@class renderer.render.html.Comment: renderer.Render
---@field private config renderer.html.Config
local Render = setmetatable({}, Base)
Render.__index = Render

---@protected
---@return boolean
function Render:setup()
    self.config = self.context.config.html
    return true -- false skips the node
end

---@protected
function Render:run()
    -- self.node, self.context and self.marks are set by Base:execute
    self.marks:over(self.config, true, self.node, { conceal = '' })
end

return Render
```

Every user facing change also needs a spec (see Tests) and a line under
`## Pre-release` in `CHANGELOG.md`.

## Other parts

- **Commands.** Every function in `api.lua` is a `:Renderer` subcommand,
  generated in `core/command.lua`. `render` is callable from Lua only.
- **Preview.** `core/preview.lua` opens a side split with a read only copy of
  the buffer that stays rendered, and turns rendering off in the source so it
  can be edited raw. Lines, cursor and events are mirrored across.
- **Completions.** `integ/` offers callout and checkbox completions through
  an in process LSP server or a completion plugin.
- **External tools.** `lib/job.lua` runs them for mermaid and the convert
  layer, see below.
  LaTeX does not use it yet: `handler/latex.lua` starts the converter for
  each formula with `vim.system` and waits for it to exit inside the render
  pass, with results cached by formula text.
- **Jobs.** `job.run(request, callback)` returns the cached result of a
  request, or starts the process and returns nil, never waiting for it. The
  callback runs once on the main loop when the process exits.

  ```lua
  ---@class renderer.job.Request
  ---@field cmd string[]
  ---@field stdin? string
  ---@field timeout? integer     ms, default 5000
  ---@field key? string          extra text mixed into the cache key
  ---@field disk? boolean         also keep a successful result on disk

  ---@class renderer.job.Result
  ---@field ok boolean
  ---@field stdout string
  ---@field stderr string
  ```

  The cache key is a hash of `cmd`, `stdin` and `key`. A request already in
  flight for the same key is joined, not restarted. Failures are cached as
  well, otherwise a broken input would start a process on every render; they
  clear when the input changes, since the key changes with it. At most
  `job.limit` (4) processes run at once and the rest queue. A timeout, a non
  zero exit, or `vim.system` throwing are all failures. A timeout (exit code
  124 with a signal) is cached for `job.retry` (30 s) only, so a run that was
  slow under load is tried again; not at once, because the refresh after the
  failure would start it again forever. The cache lives in memory for the
  session; `job.clear()` empties it and `job.reset()` also drops queued and
  running jobs, whose callbacks are then never called, for specs. A request
  with `disk` also writes a successful result to `job.dir`
  (`stdpath('cache')/renderer/`), one file per key, written to a temporary file
  and renamed, and reads it back on a memory miss. The folder is created `0700`
  and the files `0600`, since they hold the text of private documents. A short
  write, as on a full disk, fails the save and removes the temporary file, so a
  cut off text is never served later. Failures never reach the disk. Nothing
  prunes that folder.
- **Logging.** `core/log.lua` writes to a file under `stdpath('state')` at the
  configured level.
- **Debug.** `:Renderer debug` lists the marks on the cursor row,
  `:Renderer config` prints the difference from the defaults.

## Tests

Specs are plenary busted files under `tests/`, with unit specs for single
modules under `tests/unit/`. `tests/minimal_init.lua` loads the dependencies,
installs the parsers, and starts the treesitter highlighter for `markdown`,
`html`, `csv`, `tsv` and `psv` buffers. `benches/` holds timing specs for larger files.

`tests/helpers/system.lua` stubs `vim.system` for converters. A call with an
exit callback, as `lib/job.lua` makes, finishes on the main loop, can be held
back until `release()`, and fails for an output given as `false`. Mermaid specs
wait for the second render with a few short `vim.wait` calls.
`tests/unit/job_spec.lua` uses real commands (`cat`, `sh`, `sleep`) instead,
and so does `tests/convert_spec.lua`, whose converters print a fixture file, so
the `:w` guard is covered with no external tool installed. Its one `pandoc` spec
is only defined when `pandoc` is installed. Specs that take a file over from the
zip plugin source `zipPlugin.vim` themselves, as `--noplugin` skips it.

A render spec sets up a scratch buffer and asserts two things: the exact list
of marks, and the text on screen.

```lua
local util = require('tests.util')

it('inline bold', function()
    -- lines, config, filetype (defaults to 'markdown')
    local config = { file_types = { 'markdown', 'html' } }
    util.setup.text({ '<b>bold</b>' }, config, 'html')
    local marks = util.marks()
    -- row or { start_row, end_row }, col or { start_col, end_col }, extmark opts
    marks:add({ 0, 0 }, { 0, 3 }, util.conceal())
    marks:add({ 0, 0 }, { 3, 7 }, { hl_eol = false, hl_group = 'RmHtmlBold' })
    marks:add({ 0, 0 }, { 7, 11 }, util.conceal())
    util.assert_view(marks, { 'bold' })
end)
```

In expected marks the `Renderer` prefix of a highlight group is written `Rm`.
`tests/helpers/details.lua` shortens the actual names the same way.

Run one file with `PlenaryBustedDirectory` and the minimal init, as shown in
`CLAUDE.md`. `PlenaryBustedFile` skips the minimal init and every render spec
fails. A spec for a filetype other than `markdown` or `html` needs that
filetype added to the highlighter autocmd in `tests/minimal_init.lua`.

## Where the code assumes markdown

The format registry removed the assumptions that sat in the handler table,
the config block lists, the sideways scroll check and the health check. These
remain, and each is addressed by a planned change in part 2.

| Where                              | Assumption                                              | Effect on other formats                           |
| ---------------------------------- | ------------------------------------------------------- | ------------------------------------------------- |
| `core/ui.lua` `Updater:parse`      | the buffer has a treesitter parser                      | text output (PDF) is not rendered, only shown     |
| `handler/latex.lua`                | waits for its converter inside the render pass          | slow formulas block rendering, unlike mermaid     |
| `tests/util.lua`, `minimal_init`   | highlighter started for markdown, html and csv only     | a spec for another filetype needs `minimal_init`  |

---

# Part 2: planned design (not implemented)

Nothing in this part exists in the code. Do not require these modules or rely
on these fields. When one of them is built, follow the design here and move
its section into part 1.

The goal is to render more than markdown: data files, diagrams inside
markdown, and documents that are not text. The format registry, plain HTML
files, CSV files, mermaid diagrams, the job runner and the convert layer with
DOCX, described in part 1, are done. What remains:

| Work               | Module                                 | Needs                                    |
| ------------------ | -------------------------------------- | ---------------------------------------- |
| PDF files          | `format/pdf.lua`                       | text output decorated once at load       |
| LaTeX through jobs | `handler/latex.lua`                    | nothing new, the runner is in place      |
| HTML reader view   | `core/reader.lua`                      | the convert layer, from a buffer of text |

## Principles

1. Keep the handler seam. New formats are new handlers, not a new pipeline.
2. One declaration per format. Whatever the core needs to know about a format
   it reads from that declaration.
3. One way to run an external tool: asynchronous, cached, argv only.
4. A file that is not text is converted into a read only buffer. The original
   is never written.
5. Nothing is downloaded. Parsers and tools are installed by the user and
   reported by `:checkhealth`.
6. Markdown users see no change. The existing specs are the proof.

## Two models

**A. Decorate in place.** The buffer holds the file's text, a parser reads it,
a handler emits marks. Editable, anti conceal works. Cannot reflow. Used for
HTML, CSV, TSV, PSV, and markdown itself.

**B. Convert, then decorate.** A tool turns the file into markdown, the result
goes into a read only buffer, the markdown format renders it. No new renderers.
Used for DOCX, and planned for PDF, the HTML reader view, and later ODT, EPUB,
notebooks.

A third case sits inside a document rather than being one: **converted
blocks**. A node's text is sent to a tool and the output is shown in its place.
Mermaid diagrams work this way through the job runner, and LaTeX formulas will.

## Text output

The convert layer sets the filetype of a converted buffer to its converter's
`output`, and a `text` buffer is shown but not rendered: it has no format, so
`should_attach` rejects it. `pdftotext -layout` output parsed as markdown would
turn every indented line into a code block, so PDF needs `text`, and one more
field on `renderer.format.Source`:

```lua
---@field decorate? fun(buf: integer)        one time marks for text output
```

Text buffers are decorated once at load by the format's `decorate` function in
the convert layer's own namespace (page separators, page numbers), which is
safe because the buffer cannot change. This is why no non-treesitter path is
added to the render loop. PDF is then a `format/pdf.lua` with a `source`, and a
`convert.pdf` block in `settings.lua` with `pdftotext -layout {file} -`.

## LaTeX through the job runner

`handler/latex.lua` still starts its converter with `vim.system` and waits for
it inside the render pass, with a dead `vim.fn.system` branch. Moving it onto
`job.run` drops both: a formula then renders raw until its output is ready, as
a mermaid block does, and `lib/job.lua` becomes the only place that starts a
process.

## Converted blocks

A pattern on top of the job runner, not a module of its own. A renderer that
owns a node sends its text through `job.run`:

- hit: show the output in place of the node;
- miss: render the node as it would render without this feature;
- failure: same as miss, with the stderr logged.

Mermaid is the first user (part 1). It shows its output as virtual lines below
the fence line and hides the rest of the block, rather than with a replace mark,
so that the cursor can enter the block to edit it. With `vim.ui.img` the same
pattern produces an image instead of text, and only the converter and the mark
change.

## Module map after the planned work

```text
lua/renderer/
  format/            ADD   pdf.lua
  convert/init.lua   CHG   text decoration
  core/reader.lua    NEW   HTML reader view
  handler/latex.lua  CHG   formulas through lib/job.lua
  settings.lua       ADD   convert.pdf, reader blocks
```

`init.lua` keeps its literal `default` table, because `scripts/update.py`
parses it.

## Recipes

**In place format** (CSV is built this way):

1. `format/csv.lua`, and its name in the list in `format/init.lua`.
2. `handler/csv.lua`: a query and a capture to renderer map.
3. `render/csv/*.lua`: renderers extending `render/base.lua`.
4. A `csv` block in `settings.lua` with types and schema, its name in the
   component list, and its line in `init.lua` `default`.

**Converted format** (DOCX is built this way):

1. `format/docx.lua` with a `source`, and its name in `format/init.lua`.
2. Converters under `convert.docx` in `settings.lua`, with their schema.

**Converted format using a tool already supported** (ODT through pandoc): a
format file with a `source` and a `convert` block naming the tool.

**Converted block**: a config block with a `converter` list, and a call to
`job.run` in the renderer that owns the node, as `render/markdown/mermaid.lua`
does.

None of the recipes edits `core/` or `health.lua`, and `lib/config.lua` only
gains a name in `Config.components`. If one ever has to do more, the registry
is missing a field and the fix belongs there.

## Testing the new parts

- Format specs use `tests/util.lua` `setup.text` with a filetype, and live in
  their own files that leave the markdown specs alone. `minimal_init` starts
  the highlighter for each new format's filetype.
- Converters are tested with trivial commands that print a fixture, as
  `tests/convert_spec.lua` is, plus one real fixture spec per converter,
  skipped when the tool is absent. CI installs `pandoc`, and will need
  `poppler-utils` for PDF.

## Alternatives rejected

- **A non-treesitter handler path** for CSV or PDF text. It would fork the
  render loop. The treesitter CSV grammars and the load time decoration of
  read only text buffers make it unnecessary.
- **A registry keyed by filetype.** Breaks filetypes that users map onto the
  markdown parser.
- **CSV converted to a markdown table.** Loses editing, which is the point of
  the in place model.
- **A dedicated filetype for converted buffers.** It would need the markdown
  parser registered for it and the highlighter started by hand, and gains
  only the ability to tell the buffers apart, which `buftype` already gives.
- **DOCX on by default once pandoc is installed.** Users with pandoc installed
  for other reasons would lose the zip browser for `.docx` files without asking
  for it. Like HTML and CSV it is opt in through `file_types`.
- **Downloading parsers or tools on demand.** Bypasses the user's plugin
  manager, fails offline, supply chain risk.
- **Building the job runner and convert layer before their first user.** Their
  interfaces would be guesses.

## Not verified

- lazy.nvim replaying `BufReadCmd` after loading the plugin on a pattern
  event.
- `vim.ui.img` function signatures.
