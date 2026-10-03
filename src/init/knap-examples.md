<!-- k4o init knap-examples v1 -->
# knap worked examples

The three examples shipped with k4o, end to end: template, data, and the
bytes each output format produces. Textile is the default; `--format
markdown` is strict CommonMark 0.31.2; `--format gfm` changes only table
rendering.

## Heading — `{{ value | filter }}` and chains

Template (`heading.knap`):

```text
{{ title | h1 }}

{{ subtitle | italic }}
```

Data (`heading.json`):

```json
{"title":"The Machine Stops","subtitle":"A reading note"}
```

Textile (default):

```text
h1. The Machine Stops

_A reading note_
```

CommonMark (`--format markdown`):

```text
# The Machine Stops

*A reading note*
```

## List — arrays and the `list` filter

Template (`list.knap`):

```text
{{ "Sections" | h2 }}

{{ sections | list }}
```

Data (`list.json`):

```json
{"sections":["The Air-Ship","The Mending Apparatus","The Homeless"]}
```

Textile:

```text
h2. Sections

* The Air-Ship
* The Mending Apparatus
* The Homeless
```

CommonMark (`--format markdown`):

```text
## Sections

- The Air-Ship
- The Mending Apparatus
- The Homeless
```

## Table — rows of rows, three renderings

Template (`table.knap`):

```text
{{ rows | table }}
```

Data (`table.json`):

```json
{"rows":[["name","age"],["Walter","5"],["Florence","6"]]}
```

Textile:

```text
|_. name|_. age|
|Walter|5|
|Florence|6|
```

CommonMark has no pipe tables, so `--format markdown` emits an HTML block:

```text
<table>
<thead>
<tr><th>name</th><th>age</th></tr>
</thead>
<tbody>
<tr><td>Walter</td><td>5</td></tr>
<tr><td>Florence</td><td>6</td></tr>
</tbody>
</table>
```

`--format gfm` emits a pipe table instead (GFM is opt-in for Obsidian-style
consumers; strict CommonMark parsers read it as a paragraph):

```text
|  |  |
| - | - |
| name | age |
| Walter | 5 |
| Florence | 6 |
```

## Reproduce these locally

```sh
k4o lint examples/heading.knap
k4o render examples/heading.knap --data examples/heading.json
k4o render examples/heading.knap --data examples/heading.json --format markdown
```

Errors exit 1 with a diagnostic on stderr and nothing on stdout — output is
buffered, so a failed render never half-emits.
