#!/usr/bin/env python3
"""Black-box differential and CommonMark structure checks (no knap source)."""

import argparse
from html.parser import HTMLParser
import json
from pathlib import Path
import re
import subprocess
import sys
import tempfile


ROOT = Path(__file__).resolve().parents[2]
CORPUS = Path(__file__).resolve().parent
KNAP_VERSION = "0.6.0"
TIMEOUT = 8

# These pre-existing Textile fixtures cannot have byte-identical output against
# knap 0.6.0 without changing k4o's language/data semantics, or emitting a
# GFM-only table. They are still checked against .markdown and parsed by Oliver.
EXCLUDED_FIXTURES = {
    "examples/table": "Knap emits a GFM pipe table; CommonMark has no table syntax",
    "fixtures/filter-table-basic": "Knap emits a GFM pipe table; CommonMark has no table syntax",
    "fixtures/filter-codeblock-basic": "Knap has code_block, not k4o's codeblock filter",
    "fixtures/filter-numbered-basic": "Knap has list:numbered, not k4o's numbered filter",
    "fixtures/filter-numbered-nested": "Knap has list:numbered, not k4o's numbered filter",
    "fixtures/filter-link-basic": "Knap takes URL as input and label as argument; k4o does the reverse",
    "fixtures/filter-link-data-arg": "Knap takes URL as input and label as argument; k4o does the reverse",
    "fixtures/filter-link-literal-arg": "Knap takes URL as input and label as argument; k4o does the reverse",
    "fixtures/logic-contains-object": "Knap compares objects by identity; k4o compares structure",
    "fixtures/logic-eq-array-nested": "Knap compares arrays by identity; k4o compares structure",
    "fixtures/logic-eq-object-order": "Knap compares objects by identity; k4o compares structure",
    "fixtures/loop-nested": "Knap strips leading whitespace at nested standalone tags",
    "fixtures/loop-values": "Knap strips whitespace before the following tag",
}


class Tags(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.names = []

    def handle_starttag(self, tag, attrs):
        self.names.append(tag)


def invoke(command, *, input=None):
    try:
        return subprocess.run(command, input=input, capture_output=True, timeout=TIMEOUT)
    except subprocess.TimeoutExpired as error:
        raise AssertionError(f"timeout: {command[0]} ({TIMEOUT}s)") from error
    except OSError as error:
        raise AssertionError(f"could not execute {command[0]}: {error}") from error


def check_result(result, name, status):
    if status == "ok":
        assert result.returncode == 0 and not result.stderr, (
            f"{name}: expected clean exit 0, got {result.returncode}: {result.stderr!r}"
        )
    else:
        assert result.returncode == 1 and not result.stdout and result.stderr.strip(), (
            f"{name}: error must exit 1 with empty stdout and diagnostic; "
            f"got {result.returncode}, stdout={result.stdout!r}, stderr={result.stderr!r}"
        )


def compare(name, template, data, status, expected, k4o, knap, directory):
    path = directory / "case.knap"
    json_path = directory / "data.json"
    path.write_bytes(template)
    json_path.write_bytes(json.dumps(data, ensure_ascii=False).encode())
    ours = invoke([k4o, "render", str(path), "--data", str(json_path), "--format", "markdown"])
    theirs = invoke([knap, "render", str(path), "--data", str(json_path)])
    check_result(ours, f"k4o {name}", status)
    check_result(theirs, f"knap {name}", status)
    assert ours.stdout == theirs.stdout == expected, (
        f"{name}: byte mismatch\nk4o: {ours.stdout!r}\nknap: {theirs.stdout!r}\n"
        f"committed oracle: {expected!r}"
    )
    return ours.stdout


def expected_tag(name):
    stem = name.split("/")[-1]
    if stem.startswith("filter-h") and re.match(r"filter-h[1-6]-", stem):
        return "h" + stem[len("filter-h")]
    if stem.startswith("filter-list-"):
        return "ul"
    if stem.startswith("filter-numbered-"):
        return "ol"
    if stem.startswith("filter-table-") or name == "examples/table":
        return "table"
    return {
        "filter-bold-basic": "strong",
        "filter-italic-basic": "em",
        "filter-code-basic": "code",
        "filter-codeblock-basic": "pre",
        "filter-blockquote-basic": "blockquote",
        "filter-link-basic": "a",
        "filter-link-data-arg": "a",
        "filter-link-literal-arg": "a",
        "filter-chain-h2-italic": "h2",
        "heading": "h1",
        "list": "ul",
    }.get(stem)


def check_commonmark(name, markdown, oliver, required=None):
    required = required or expected_tag(name)
    table = required == "table"
    command = [oliver, "render", "--from", "markdown", "--raw-html", "allowed" if table else "rejected"]
    result = invoke(command, input=markdown)
    assert result.returncode == 0 and not result.stderr, (
        f"{name}: Oliver rejected Markdown: {result.returncode}: {result.stderr!r}"
    )
    assert b"{{" not in markdown and b"{%" not in markdown, f"{name}: template tag leaked"
    html = result.stdout.decode("utf-8")
    tags = Tags()
    tags.feed(html)
    if required:
        assert required in tags.names, f"{name}: expected <{required}> in {html!r}"
    if required == "table":
        assert {"table", "thead", "th", "tbody", "td"} <= set(tags.names), (
            f"{name}: missing table structure in {html!r}"
        )
        assert markdown.startswith(b"<table>\n"), f"{name}: GFM pipe table is not CommonMark"
    if name.endswith("list-nested"):
        assert tags.names.count("ul") >= 2, f"{name}: nested list not nested in {html!r}"
    if name.endswith("numbered-nested"):
        assert tags.names.count("ol") >= 2, f"{name}: nested ordered list not nested in {html!r}"
    if name.endswith("chain-h2-italic"):
        assert "<h2><em>" in html, f"{name}: heading/emphasis chain not parsed: {html!r}"
    if name.endswith("codeblock-basic"):
        assert "<pre><code>" in html, f"{name}: fenced block not parsed: {html!r}"
    if name.endswith("link-basic"):
        assert '<a href="https://example.com/">' in html, f"{name}: link target lost: {html!r}"
    return html


def run(k4o, knap, oliver):
    version = invoke([knap, "--version"])
    assert version.returncode == 0 and version.stdout.decode().strip() == KNAP_VERSION, (
        f"wrong knap version: {version.stdout!r} {version.stderr!r}"
    )
    cases = json.loads((CORPUS / "cases.json").read_text())
    expected = json.loads((CORPUS / "expected.json").read_text())
    assert set(expected) == {case["name"] for case in cases}, "corpus and oracle snapshots differ"
    fixture_paths = sorted([*ROOT.glob("fixtures/*.knap"), *ROOT.glob("examples/*.knap")])
    fixture_names = {str(path.relative_to(ROOT).with_suffix("")) for path in fixture_paths}
    assert EXCLUDED_FIXTURES.keys() <= fixture_names, "stale fixture exclusions"
    checks = 0
    with tempfile.TemporaryDirectory(prefix="k4o-differential-") as tmp:
        directory = Path(tmp)
        for case in cases:
            name = case["name"]
            snapshot = expected[name]
            status = case.get("status", "ok")
            assert snapshot["status"] == status, f"{name}: snapshot status changed"
            output = compare(
                name, case["template"].encode(), case["data"], status,
                snapshot["stdout"].encode(), k4o, knap, directory,
            )
            if status == "ok":
                check_commonmark(name, output, oliver)
            checks += 1
        for path in fixture_paths:
            name = str(path.relative_to(ROOT).with_suffix(""))
            data = json.loads(path.with_suffix(".json").read_text())
            expected_markdown = path.with_suffix(".markdown").read_bytes()
            if name not in EXCLUDED_FIXTURES:
                compare(name, path.read_bytes(), data, "ok", expected_markdown, k4o, knap, directory)
            else:
                ours = invoke([k4o, "render", str(path), "--data", str(path.with_suffix(".json")), "--format=markdown"])
                check_result(ours, f"k4o {name}", "ok")
                assert ours.stdout == expected_markdown, f"{name}: Markdown fixture differs"
            check_commonmark(name, expected_markdown, oliver)
            checks += 1
        # Dedicated cases for constructs absent from the knap CLI or outside
        # CommonMark's pipe-table syntax, including HTML-escaped table cells.
        structural = [
            ("table-escaped", '{{ rows | table }}', {"rows": [["A&B", "<name>"], ["x", "y"]]}, "table"),
            ("code-fence-backticks", '{{ text | codeblock }}', {"text": "```\ncode"}, "pre"),
            ("inline-code-backticks", '{{ text | code }}', {"text": "a`b"}, "code"),
            ("bold-punctuation", '{{ text | bold }}', {"text": "*"}, "strong"),
            ("italic-punctuation", '{{ text | italic }}', {"text": "*"}, "em"),
            ("bold-whitespace", '{{ text | bold }}', {"text": "  space  "}, "strong"),
            ("heading-raw-html", '{{ text | h2 }}', {"text": "<script>"}, "h2"),
            ("list-raw-html", '{{ items | list }}', {"items": ["<script>"]}, "ul"),
            ("list-leading-nested", '{{ items | list }}', {"items": [["child"], "parent"]}, "ul"),
            ("list-leading-siblings", '{{ items | list }}', {"items": [["one"], ["two"]]}, "ul"),
            ("list-heading-text", '{{ items | list }}', {"items": ["# not a heading"]}, "ul"),
            ("blockquote-raw-html", '{{ text | blockquote }}', {"text": "<script>"}, "blockquote"),
            ("link-raw-html", '{{ text | link:"https://example.com/" }}', {"text": "<script>"}, "a"),
        ]
        for name, template, data, tag in structural:
            path = directory / "case.knap"
            json_path = directory / "data.json"
            path.write_text(template)
            json_path.write_text(json.dumps(data))
            ours = invoke([k4o, "render", str(path), "--data", str(json_path), "--format", "markdown"])
            check_result(ours, f"k4o {name}", "ok")
            html = check_commonmark(name, ours.stdout, oliver, tag)
            assert f"<{tag}" in html, f"{name}: expected {tag}: {html!r}"
            if name == "table-escaped":
                assert "A&amp;B" in html and "&lt;name&gt;" in html, f"{name}: unescaped HTML: {html!r}"
            if "raw-html" in name:
                assert "<script>" not in html and "&lt;script&gt;" in html, f"{name}: raw HTML leaked: {html!r}"
            if name.startswith("list-"):
                assert "<pre>" not in html and "<h1>" not in html, f"{name}: list item misparsed: {html!r}"
            checks += 1
    print(f"PASS {checks} cases: {len(fixture_paths) - len(EXCLUDED_FIXTURES) + len(cases)} "
          f"byte-identical to knap {KNAP_VERSION}; {len(EXCLUDED_FIXTURES)} documented "
          "fixture incompatibilities checked with Oliver")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--k4o", default=str(ROOT / "zig-out/bin/k4o"))
    parser.add_argument("--knap", default=str(CORPUS / "node_modules/.bin/knap"))
    parser.add_argument("--oliver", default="oliver")
    args = parser.parse_args()
    try:
        run(str(Path(args.k4o).resolve()), str(Path(args.knap).resolve()), args.oliver)
    except (AssertionError, UnicodeError, ValueError, KeyError) as error:
        print(f"FAIL {error}", file=sys.stderr)
        sys.exit(1)
