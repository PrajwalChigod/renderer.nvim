---@meta

---@class (exact) renderer.UserConfig: renderer.partial.UserConfig, renderer.state.UserConfig
---@field preset? renderer.config.Preset
---@field overrides? renderer.overrides.UserConfig

---@class (exact) renderer.partial.UserConfig: renderer.base.UserConfig
---@field debounce? integer
---@field anti_conceal? renderer.anti.conceal.UserConfig
---@field bullet? renderer.bullet.UserConfig
---@field callout? renderer.callout.UserConfigs
---@field checkbox? renderer.checkbox.UserConfig
---@field code? renderer.code.UserConfig
---@field csv? renderer.csv.UserConfig
---@field dash? renderer.dash.UserConfig
---@field document? renderer.document.UserConfig
---@field heading? renderer.heading.UserConfig
---@field html? renderer.html.UserConfig
---@field indent? renderer.indent.UserConfig
---@field inline_highlight? renderer.inline.highlight.UserConfig
---@field latex? renderer.latex.UserConfig
---@field link? renderer.link.UserConfig
---@field padding? renderer.padding.UserConfig
---@field paragraph? renderer.paragraph.UserConfig
---@field pipe_table? renderer.table.UserConfig
---@field quote? renderer.quote.UserConfig
---@field render? renderer.render.UserConfig
---@field sign? renderer.sign.UserConfig
---@field win_options? renderer.window.UserConfigs
---@field yaml? renderer.yaml.UserConfig

---@class (exact) renderer.state.UserConfig
---@field log_level? renderer.log.Level
---@field log_runtime? boolean
---@field file_types? string[]
---@field max_file_size? number
---@field ignore? fun(buf: integer): boolean
---@field nested? boolean
---@field change_events? string[]
---@field restart_highlighter? boolean
---@field injections? renderer.injection.UserConfigs
---@field patterns? renderer.pattern.UserConfigs
---@field on? renderer.on.UserConfig
---@field completions? renderer.completions.UserConfig
---@field custom_handlers? table<string, renderer.Handler>

---@class (exact) renderer.anti.conceal.UserConfig
---@field enabled? boolean
---@field disabled_modes? renderer.Modes
---@field above? integer
---@field below? integer
---@field skip_hidden? boolean
---@field ignore? renderer.conceal.Ignore

---@class (exact) renderer.base.UserConfig
---@field enabled? boolean
---@field render_modes? renderer.Modes

---@class (exact) renderer.bullet.UserConfig: renderer.base.UserConfig
---@field icons? renderer.bullet.String
---@field ordered_icons? renderer.bullet.String
---@field left_pad? renderer.bullet.Integer
---@field right_pad? renderer.bullet.Integer
---@field highlight? renderer.bullet.String
---@field scope_highlight? renderer.bullet.String
---@field scope_priority? integer

---@class (exact) renderer.raw.UserConfig
---@field raw? string

---@alias renderer.callout.UserConfigs table<string, renderer.callout.UserConfig>

---@class (exact) renderer.callout.UserConfig: renderer.raw.UserConfig
---@field rendered? string
---@field highlight? string
---@field quote_icon? string
---@field category? string

---@class (exact) renderer.checkbox.UserConfig: renderer.base.UserConfig
---@field bullet? boolean
---@field left_pad? number
---@field right_pad? integer
---@field unchecked? renderer.checkbox.component.UserConfig
---@field checked? renderer.checkbox.component.UserConfig
---@field custom? table<string, renderer.checkbox.custom.UserConfig>
---@field scope_priority? integer

---@class (exact) renderer.checkbox.component.UserConfig
---@field icon? string
---@field highlight? string
---@field scope_highlight? string

---@class (exact) renderer.checkbox.custom.UserConfig: renderer.raw.UserConfig
---@field rendered? string
---@field highlight? string
---@field scope_highlight? string

---@class (exact) renderer.code.UserConfig: renderer.base.UserConfig
---@field sign? boolean
---@field conceal_delimiters? boolean
---@field language? boolean
---@field position? renderer.code.Position
---@field language_icon? boolean
---@field language_name? boolean
---@field language_info? boolean
---@field language_pad? number
---@field disable? string[]
---@field disable_background? boolean|string[]
---@field background_inset? integer
---@field width? renderer.code.Width
---@field left_margin? number
---@field left_pad? number
---@field right_pad? number
---@field min_width? integer
---@field border? renderer.code.Border
---@field language_border? string
---@field language_left? string
---@field language_right? string
---@field above? string
---@field below? string
---@field inline? boolean
---@field inline_left? string
---@field inline_right? string
---@field inline_pad? integer
---@field priority? integer
---@field highlight? string
---@field highlight_info? string
---@field highlight_language? string
---@field highlight_border? false|string
---@field highlight_fallback? string
---@field highlight_inline? string
---@field highlight_inline_left? string
---@field highlight_inline_right? string
---@field style? renderer.code.Style

---@class (exact) renderer.completions.UserConfig
---@field blink? renderer.completion.UserConfig
---@field coq? renderer.completion.UserConfig
---@field lsp? renderer.completion.UserConfig
---@field filter? renderer.completion.filter.UserConfig

---@class (exact) renderer.completion.UserConfig
---@field enabled? boolean

---@class (exact) renderer.completion.filter.UserConfig
---@field callout? fun(value: renderer.callout.UserConfig): boolean
---@field checkbox? fun(value: renderer.checkbox.custom.UserConfig): boolean

---@class (exact) renderer.csv.UserConfig: renderer.base.UserConfig
---@field header? boolean
---@field sample_rows? integer
---@field max_width? integer
---@field border? string
---@field head? string
---@field row? string

---@class (exact) renderer.dash.UserConfig: renderer.base.UserConfig
---@field icon? string
---@field width? renderer.dash.Width
---@field left_margin? number
---@field priority? integer
---@field highlight? string

---@class (exact) renderer.document.UserConfig: renderer.base.UserConfig
---@field conceal? renderer.document.conceal.UserConfig

---@class (exact) renderer.document.conceal.UserConfig
---@field char_patterns? string[]
---@field line_patterns? string[]

---@class (exact) renderer.heading.UserConfig: renderer.base.UserConfig
---@field atx? boolean
---@field setext? boolean
---@field sign? boolean
---@field icons? renderer.heading.String
---@field position? renderer.heading.Position
---@field signs? string[]
---@field width? renderer.heading.Width|(renderer.heading.Width)[]
---@field left_margin? number|number[]
---@field left_pad? number|number[]
---@field right_pad? number|number[]
---@field min_width? integer|integer[]
---@field border? boolean|boolean[]
---@field border_virtual? boolean
---@field border_prefix? boolean
---@field above? string
---@field below? string
---@field backgrounds? string[]
---@field foregrounds? string[]
---@field custom? table<string, renderer.heading.Custom>

---@class (exact) renderer.html.UserConfig: renderer.base.UserConfig
---@field structure? boolean
---@field list? boolean
---@field quote? boolean
---@field pre? boolean
---@field rule? boolean
---@field table? boolean
---@field entity? boolean
---@field comment? renderer.html.comment.UserConfig
---@field tag? table<string, renderer.html.Tag>

---@class (exact) renderer.html.comment.UserConfig
---@field conceal? boolean
---@field text? renderer.html.comment.String
---@field highlight? string

---@class (exact) renderer.indent.UserConfig: renderer.base.UserConfig
---@field per_level? integer
---@field skip_level? integer
---@field skip_heading? boolean
---@field icon? string
---@field priority? integer
---@field highlight? string

---@alias renderer.injection.UserConfigs table<string, renderer.injection.UserConfig>

---@class (exact) renderer.injection.UserConfig
---@field enabled? boolean
---@field query? string

---@class (exact) renderer.inline.highlight.UserConfig: renderer.base.UserConfig
---@field highlight? string
---@field custom? table<string, renderer.inline.highlight.custom.UserConfig>

---@class (exact) renderer.inline.highlight.custom.UserConfig
---@field prefix? string
---@field highlight? string

---@class (exact) renderer.latex.UserConfig: renderer.base.UserConfig
---@field converter? string|string[]
---@field inline? boolean
---@field block? boolean
---@field highlight? string
---@field position? renderer.latex.Position
---@field top_pad? integer
---@field bottom_pad? integer

---@class (exact) renderer.link.UserConfig: renderer.base.UserConfig
---@field footnote? renderer.link.footnote.UserConfig
---@field image? string
---@field image_custom? boolean
---@field email? string
---@field hyperlink? string
---@field highlight? string
---@field highlight_title? string
---@field wiki? renderer.link.wiki.UserConfig
---@field custom? table<string, renderer.link.custom.UserConfig>

---@class (exact) renderer.link.footnote.UserConfig
---@field enabled? boolean
---@field icon? string
---@field body? fun(ctx: renderer.link.footnote.Context): string?
---@field superscript? boolean
---@field prefix? string
---@field suffix? string

---@class (exact) renderer.link.wiki.UserConfig
---@field enabled? boolean
---@field icon? string
---@field conceal_destination? boolean
---@field body? fun(ctx: renderer.link.wiki.Context): renderer.mark.Text|string?
---@field highlight? string
---@field scope_highlight? string

---@class (exact) renderer.link.custom.UserConfig
---@field icon? string
---@field pattern? string
---@field kind? renderer.link.custom.Kind
---@field priority? integer
---@field highlight? string

---@class (exact) renderer.on.UserConfig
---@field attach? fun(ctx: renderer.on.attach.Context)
---@field initial? fun(ctx: renderer.on.render.Context)
---@field render? fun(ctx: renderer.on.render.Context)
---@field clear? fun(ctx: renderer.on.render.Context)

---@class (exact) renderer.overrides.UserConfig
---@field buflisted? table<boolean, renderer.partial.UserConfig>
---@field buftype? table<string, renderer.partial.UserConfig>
---@field filetype? table<string, renderer.partial.UserConfig>
---@field preview? renderer.partial.UserConfig

---@class (exact) renderer.padding.UserConfig
---@field highlight? string

---@class (exact) renderer.paragraph.UserConfig: renderer.base.UserConfig
---@field left_margin? renderer.paragraph.Number
---@field indent? renderer.paragraph.Number
---@field min_width? integer

---@alias renderer.pattern.UserConfigs table<string, renderer.pattern.UserConfig>

---@class (exact) renderer.pattern.UserConfig
---@field disable? boolean
---@field directives? renderer.directive.UserConfig[]

---@class (exact) renderer.directive.UserConfig
---@field id? integer
---@field name? string

---@class (exact) renderer.table.UserConfig: renderer.base.UserConfig
---@field preset? renderer.table.Preset
---@field cell? renderer.table.Cell
---@field wrap? boolean
---@field cell_offset? fun(ctx: renderer.table.cell.Context): integer
---@field padding? integer
---@field min_width? integer
---@field border? string[]
---@field border_enabled? boolean
---@field border_virtual? boolean
---@field alignment_indicator? string
---@field head? string
---@field row? string
---@field style? renderer.table.Style

---@class (exact) renderer.quote.UserConfig: renderer.base.UserConfig
---@field icon? string|string[]
---@field repeat_linebreak? boolean
---@field highlight? string|string[]

---@class (exact) renderer.render.UserConfig
---@field diff? boolean

---@class (exact) renderer.sign.UserConfig
---@field enabled? boolean
---@field priority? integer
---@field highlight? string

---@alias renderer.window.UserConfigs table<string, renderer.window.UserConfig>

---@class (exact) renderer.window.UserConfig
---@field default? renderer.option.Value
---@field rendered? renderer.option.Value

---@class (exact) renderer.yaml.UserConfig: renderer.base.UserConfig
