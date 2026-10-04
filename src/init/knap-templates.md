<!-- k4o init knap-templates v2 -->
# knap starter templates

Copy one, replace the data keys, verify with `k4o lint`, render with
`k4o render <file> --data <data.json>`. Every template here is lint-clean
and pinned by the k4o test suite.

## Reading note (heading + emphasis)

```text
{{ title | h1 }}

{{ subtitle | italic }}
```

```json
{"title":"The Machine Stops","subtitle":"A reading note"}
```

## List page

```text
{{ "Sections" | h2 }}

{{ sections | list }}
```

```json
{"sections":["The Air-Ship","The Mending Apparatus","The Homeless"]}
```

Nested arrays nest the list (up to 3 levels):

```json
{"sections":["Part One",["The Air-Ship","The Mending Apparatus"]]}
```

## Numbered steps

```text
{{ "Steps" | h2 }}

{{ steps | numbered }}
```

```json
{"steps":["Board at 8","Change at York","Arrive by noon"]}
```

## Table

Every row is an array; all rows must have the same cell count, and cells
must not contain `|` or newlines.

```text
{{ rows | table }}
```

```json
{"rows":[["name","age"],["Walter","5"],["Florence","6"]]}
```

## Conditional banner

```text
{% if draft %}{{ "DRAFT — not for publication" | bold }}
{% endif %}{{ title | h1 }}
```

```json
{"draft":true,"title":"The Machine Stops"}
```

The newline before `{% endif %}` is preserved, so the banner sits on its own
line above the heading; when `draft` is false the heading comes first with
no gap. Literal template text passes through unescaped — keep markup in
filters, not in the template, so both output formats stay correct.

## Fallback with `elseif` / `else`

```text
{% if status == "published" %}Live{% elseif status == "review" %}In review{% else %}Unknown status{% endif %}
```

```json
{"status":"review"}
```

## Link row

```text
{{ name | link:url }}
```

```json
{"name":"Example","url":"https://example.com/post"}
```

The bare word `url` resolves against the top-level data key; quote it
(`link:"url"`) to send the literal four characters instead. Blocked schemes
(`javascript:`, `vbscript:`, `data:`) are refused.

## Loop with an index

```text
{% for item in items %}{{ loop.index }}. {{ item }}
{% endfor %}
```

```json
{"items":["Air-Ship","Mending Apparatus","Homeless"]}
```

`loop` also carries `index0`, `first`, `last` and `length`.

## Code block

```text
{{ "zig build test" | codeblock }}
```

Content keeps every existing newline; a missing terminal newline gets one
before the closing fence. Content with a blank line is emitted with Textile's
extended `bc..` signature so it stays one block downstream — template text
right after it then needs its own block signature. For inline code use
`{{ "k4o render" | code }}`.
