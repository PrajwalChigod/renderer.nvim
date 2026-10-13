# CLAUDE.md

Neovim plugin that renders markdown (and HTML, LaTeX, YAML frontmatter)
inside buffers using treesitter and extmarks. Requires neovim >= 0.12.

## Layout

- `plugin/renderer.lua`: entry point, version guard
- `lua/renderer/settings.lua`: all config defaults, types and schemas
- `lua/renderer/format/`: format registry, one file per format declaring its
  root language, parsers, handlers and defaults (`csv.lua` declares `csv`,
  `tsv` and `psv`)
- `lua/renderer/handler/`: one handler per treesitter language, runs
  queries and dispatches captures to renderers
- `lua/renderer/render/`: renderers grouped by language, each extends
  `render/base.lua` with `setup()` and `run()`
- `lua/renderer/core/colors.lua`: `Renderer*` highlight groups
- `lua/renderer/core/cursor.lua`: moves the cursor off lines that are hidden
  completely
- `tests/`: plenary busted specs, `tests/util.lua` holds helpers

## Commands

- `just test`: run all specs, needs `nvim-treesitter`, `mini.nvim` and
  `plenary.nvim` in the neovim data directory plus the `html`, `latex`,
  `markdown`, `markdown_inline` and `yaml` parsers
- `just check`: `selene` lint and `stylua --check`
- `just update`: regenerate README and vimdoc config sections from
  `settings.lua`

Run a single spec with:

```sh
nvim --headless --noplugin -u tests/minimal_init.lua \
  -c "PlenaryBustedDirectory tests/html_spec.lua { minimal_init = 'tests/minimal_init.lua', sequential = true }"
```

Use `PlenaryBustedDirectory` even for a single file, `PlenaryBustedFile` runs
without the minimal init and every render spec fails.

## Conventions

- Format with `stylua` (80 columns, 4 spaces, single quotes)
- Config changes go in `settings.lua` first, then mirror them into the
  `README.md` and `doc/renderer.txt` config blocks
- New highlight groups go in `core/colors.lua` and the README highlight table
- Add specs for new rendering behavior, asserting both marks and screen
- Add user facing changes under `## Pre-release` in `CHANGELOG.md`

## Design docs

- `architecture.md`: part 1 is how the code works today, part 2 is the planned
  design for rendering more file types. Read it before changing `core/`,
  `handler/` or `render/`
- `plan.md`: roadmap and release order
- `issues/issue-N.md`: full spec for each planned change

## Working on a planned issue

- Find the spec path in the task or the GitHub issue body, then read that file
  and `architecture.md` before writing code
- Follow its Implementation and Testing sections
- Use its commit message and commit description
- Do not bump `M.version` or cut a release unless asked
- When the change adds or moves modules, update part 1 of `architecture.md`
  and the Layout section above

## Releasing

Only when asked. The release workflow (`.github/workflows/release.yml`) checks
all three:

- move the `## Pre-release` entries in `CHANGELOG.md` under
  `## <version> (<date>)`, leaving an empty `## Pre-release` above it
- set `M.version` in `lua/renderer/health.lua` to the same version
- publish a release tagged with the bare version, no `v` prefix

## Commits

- Use conventional commits: `feat:`, `fix:`, `refactor:`, `test:`, `chore:`
- Do not add `Claude-Session:` lines to commit messages or PR descriptions
