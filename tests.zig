//! k4o test suite.
//!
//! 1. Fixture corpus (`.knap` + `.json` + `.textile`/`.markdown`/`.gfm`), byte-exact.
//! 2. Error corpus (`fixtures/errors/*.knap` + `.error`), message-checked.
//! 3. Unit tests for behavior beyond the corpus.
//! 4. Properties: every registry filter has a fixture, no case output equals
//!    its template, and the engine actually renders Textile — so every test
//!    in this file fails under `-Dengine-mode=passthrough` (and every
//!    filter-touching test fails under `-Dengine-mode=markdown`).
//! 5. Lint: the clean corpus lints clean; every error and lint fixture maps
//!    to the teaching rule its diagnostic names (`fixtures/lint/*.knap`).
//!
//! The three `examples/*` artifacts are part of the corpus (`ex-*`).

const std = @import("std");
const kt = @import("k4o");
const testing = std.testing;

const Case = struct {
    name: []const u8,
    template: []const u8,
    data: []const u8,
    expected: []const u8,
};

const cases = [_]Case{
    .{ .name = "var-plain", .template = @embedFile("fixtures/var-plain.knap"), .data = @embedFile("fixtures/var-plain.json"), .expected = @embedFile("fixtures/var-plain.textile") },
    .{ .name = "var-dotted", .template = @embedFile("fixtures/var-dotted.knap"), .data = @embedFile("fixtures/var-dotted.json"), .expected = @embedFile("fixtures/var-dotted.textile") },
    .{ .name = "var-bracket-index", .template = @embedFile("fixtures/var-bracket-index.knap"), .data = @embedFile("fixtures/var-bracket-index.json"), .expected = @embedFile("fixtures/var-bracket-index.textile") },
    .{ .name = "var-bracket-key", .template = @embedFile("fixtures/var-bracket-key.knap"), .data = @embedFile("fixtures/var-bracket-key.json"), .expected = @embedFile("fixtures/var-bracket-key.textile") },
    .{ .name = "var-spaces-name", .template = @embedFile("fixtures/var-spaces-name.knap"), .data = @embedFile("fixtures/var-spaces-name.json"), .expected = @embedFile("fixtures/var-spaces-name.textile") },
    .{ .name = "var-missing", .template = @embedFile("fixtures/var-missing.knap"), .data = @embedFile("fixtures/var-missing.json"), .expected = @embedFile("fixtures/var-missing.textile") },
    .{ .name = "var-number", .template = @embedFile("fixtures/var-number.knap"), .data = @embedFile("fixtures/var-number.json"), .expected = @embedFile("fixtures/var-number.textile") },
    .{ .name = "var-json-object", .template = @embedFile("fixtures/var-json-object.knap"), .data = @embedFile("fixtures/var-json-object.json"), .expected = @embedFile("fixtures/var-json-object.textile") },
    .{ .name = "filter-h1-basic", .template = @embedFile("fixtures/filter-h1-basic.knap"), .data = @embedFile("fixtures/filter-h1-basic.json"), .expected = @embedFile("fixtures/filter-h1-basic.textile") },
    .{ .name = "filter-h2-basic", .template = @embedFile("fixtures/filter-h2-basic.knap"), .data = @embedFile("fixtures/filter-h2-basic.json"), .expected = @embedFile("fixtures/filter-h2-basic.textile") },
    .{ .name = "filter-h3-basic", .template = @embedFile("fixtures/filter-h3-basic.knap"), .data = @embedFile("fixtures/filter-h3-basic.json"), .expected = @embedFile("fixtures/filter-h3-basic.textile") },
    .{ .name = "filter-h4-basic", .template = @embedFile("fixtures/filter-h4-basic.knap"), .data = @embedFile("fixtures/filter-h4-basic.json"), .expected = @embedFile("fixtures/filter-h4-basic.textile") },
    .{ .name = "filter-h5-basic", .template = @embedFile("fixtures/filter-h5-basic.knap"), .data = @embedFile("fixtures/filter-h5-basic.json"), .expected = @embedFile("fixtures/filter-h5-basic.textile") },
    .{ .name = "filter-h6-basic", .template = @embedFile("fixtures/filter-h6-basic.knap"), .data = @embedFile("fixtures/filter-h6-basic.json"), .expected = @embedFile("fixtures/filter-h6-basic.textile") },
    .{ .name = "filter-bold-basic", .template = @embedFile("fixtures/filter-bold-basic.knap"), .data = @embedFile("fixtures/filter-bold-basic.json"), .expected = @embedFile("fixtures/filter-bold-basic.textile") },
    .{ .name = "filter-italic-basic", .template = @embedFile("fixtures/filter-italic-basic.knap"), .data = @embedFile("fixtures/filter-italic-basic.json"), .expected = @embedFile("fixtures/filter-italic-basic.textile") },
    .{ .name = "filter-code-basic", .template = @embedFile("fixtures/filter-code-basic.knap"), .data = @embedFile("fixtures/filter-code-basic.json"), .expected = @embedFile("fixtures/filter-code-basic.textile") },
    .{ .name = "filter-blockquote-basic", .template = @embedFile("fixtures/filter-blockquote-basic.knap"), .data = @embedFile("fixtures/filter-blockquote-basic.json"), .expected = @embedFile("fixtures/filter-blockquote-basic.textile") },
    .{ .name = "filter-codeblock-basic", .template = @embedFile("fixtures/filter-codeblock-basic.knap"), .data = @embedFile("fixtures/filter-codeblock-basic.json"), .expected = @embedFile("fixtures/filter-codeblock-basic.textile") },
    .{ .name = "filter-link-basic", .template = @embedFile("fixtures/filter-link-basic.knap"), .data = @embedFile("fixtures/filter-link-basic.json"), .expected = @embedFile("fixtures/filter-link-basic.textile") },
    .{ .name = "filter-link-data-arg", .template = @embedFile("fixtures/filter-link-data-arg.knap"), .data = @embedFile("fixtures/filter-link-data-arg.json"), .expected = @embedFile("fixtures/filter-link-data-arg.textile") },
    .{ .name = "filter-link-literal-arg", .template = @embedFile("fixtures/filter-link-literal-arg.knap"), .data = @embedFile("fixtures/filter-link-literal-arg.json"), .expected = @embedFile("fixtures/filter-link-literal-arg.textile") },
    .{ .name = "filter-list-basic", .template = @embedFile("fixtures/filter-list-basic.knap"), .data = @embedFile("fixtures/filter-list-basic.json"), .expected = @embedFile("fixtures/filter-list-basic.textile") },
    .{ .name = "filter-list-nested", .template = @embedFile("fixtures/filter-list-nested.knap"), .data = @embedFile("fixtures/filter-list-nested.json"), .expected = @embedFile("fixtures/filter-list-nested.textile") },
    .{ .name = "filter-numbered-basic", .template = @embedFile("fixtures/filter-numbered-basic.knap"), .data = @embedFile("fixtures/filter-numbered-basic.json"), .expected = @embedFile("fixtures/filter-numbered-basic.textile") },
    .{ .name = "filter-numbered-nested", .template = @embedFile("fixtures/filter-numbered-nested.knap"), .data = @embedFile("fixtures/filter-numbered-nested.json"), .expected = @embedFile("fixtures/filter-numbered-nested.textile") },
    .{ .name = "filter-table-basic", .template = @embedFile("fixtures/filter-table-basic.knap"), .data = @embedFile("fixtures/filter-table-basic.json"), .expected = @embedFile("fixtures/filter-table-basic.textile") },
    .{ .name = "filter-chain-h2-italic", .template = @embedFile("fixtures/filter-chain-h2-italic.knap"), .data = @embedFile("fixtures/filter-chain-h2-italic.json"), .expected = @embedFile("fixtures/filter-chain-h2-italic.textile") },
    .{ .name = "logic-if-true", .template = @embedFile("fixtures/logic-if-true.knap"), .data = @embedFile("fixtures/logic-if-true.json"), .expected = @embedFile("fixtures/logic-if-true.textile") },
    .{ .name = "logic-else", .template = @embedFile("fixtures/logic-else.knap"), .data = @embedFile("fixtures/logic-else.json"), .expected = @embedFile("fixtures/logic-else.textile") },
    .{ .name = "logic-elseif", .template = @embedFile("fixtures/logic-elseif.knap"), .data = @embedFile("fixtures/logic-elseif.json"), .expected = @embedFile("fixtures/logic-elseif.textile") },
    .{ .name = "logic-truthiness", .template = @embedFile("fixtures/logic-truthiness.knap"), .data = @embedFile("fixtures/logic-truthiness.json"), .expected = @embedFile("fixtures/logic-truthiness.textile") },
    .{ .name = "logic-contains-string", .template = @embedFile("fixtures/logic-contains-string.knap"), .data = @embedFile("fixtures/logic-contains-string.json"), .expected = @embedFile("fixtures/logic-contains-string.textile") },
    .{ .name = "logic-contains-array", .template = @embedFile("fixtures/logic-contains-array.knap"), .data = @embedFile("fixtures/logic-contains-array.json"), .expected = @embedFile("fixtures/logic-contains-array.textile") },
    .{ .name = "logic-contains-object", .template = @embedFile("fixtures/logic-contains-object.knap"), .data = @embedFile("fixtures/logic-contains-object.json"), .expected = @embedFile("fixtures/logic-contains-object.textile") },
    .{ .name = "logic-eq-reflexive", .template = @embedFile("fixtures/logic-eq-reflexive.knap"), .data = @embedFile("fixtures/logic-eq-reflexive.json"), .expected = @embedFile("fixtures/logic-eq-reflexive.textile") },
    .{ .name = "logic-eq-object-order", .template = @embedFile("fixtures/logic-eq-object-order.knap"), .data = @embedFile("fixtures/logic-eq-object-order.json"), .expected = @embedFile("fixtures/logic-eq-object-order.textile") },
    .{ .name = "logic-eq-array-nested", .template = @embedFile("fixtures/logic-eq-array-nested.knap"), .data = @embedFile("fixtures/logic-eq-array-nested.json"), .expected = @embedFile("fixtures/logic-eq-array-nested.textile") },
    .{ .name = "logic-eq-length-mismatch", .template = @embedFile("fixtures/logic-eq-length-mismatch.knap"), .data = @embedFile("fixtures/logic-eq-length-mismatch.json"), .expected = @embedFile("fixtures/logic-eq-length-mismatch.textile") },
    .{ .name = "logic-neq-object", .template = @embedFile("fixtures/logic-neq-object.knap"), .data = @embedFile("fixtures/logic-neq-object.json"), .expected = @embedFile("fixtures/logic-neq-object.textile") },
    .{ .name = "logic-and-or-parens", .template = @embedFile("fixtures/logic-and-or-parens.knap"), .data = @embedFile("fixtures/logic-and-or-parens.json"), .expected = @embedFile("fixtures/logic-and-or-parens.textile") },
    .{ .name = "logic-not", .template = @embedFile("fixtures/logic-not.knap"), .data = @embedFile("fixtures/logic-not.json"), .expected = @embedFile("fixtures/logic-not.textile") },
    .{ .name = "loop-basic", .template = @embedFile("fixtures/loop-basic.knap"), .data = @embedFile("fixtures/loop-basic.json"), .expected = @embedFile("fixtures/loop-basic.textile") },
    .{ .name = "loop-values", .template = @embedFile("fixtures/loop-values.knap"), .data = @embedFile("fixtures/loop-values.json"), .expected = @embedFile("fixtures/loop-values.textile") },
    .{ .name = "loop-nested", .template = @embedFile("fixtures/loop-nested.knap"), .data = @embedFile("fixtures/loop-nested.json"), .expected = @embedFile("fixtures/loop-nested.textile") },
    .{ .name = "loop-empty", .template = @embedFile("fixtures/loop-empty.knap"), .data = @embedFile("fixtures/loop-empty.json"), .expected = @embedFile("fixtures/loop-empty.textile") },
    .{ .name = "comment-inline", .template = @embedFile("fixtures/comment-inline.knap"), .data = @embedFile("fixtures/comment-inline.json"), .expected = @embedFile("fixtures/comment-inline.textile") },
    .{ .name = "comment-multiline", .template = @embedFile("fixtures/comment-multiline.knap"), .data = @embedFile("fixtures/comment-multiline.json"), .expected = @embedFile("fixtures/comment-multiline.textile") },
    .{ .name = "unicode-data", .template = @embedFile("fixtures/unicode-data.knap"), .data = @embedFile("fixtures/unicode-data.json"), .expected = @embedFile("fixtures/unicode-data.textile") },
    .{ .name = "ex-heading", .template = @embedFile("examples/heading.knap"), .data = @embedFile("examples/heading.json"), .expected = @embedFile("examples/heading.textile") },
    .{ .name = "ex-list", .template = @embedFile("examples/list.knap"), .data = @embedFile("examples/list.json"), .expected = @embedFile("examples/list.textile") },
    .{ .name = "ex-table", .template = @embedFile("examples/table.knap"), .data = @embedFile("examples/table.json"), .expected = @embedFile("examples/table.textile") },
};

const ErrorCase = struct {
    name: []const u8,
    template: []const u8,
    data: ?[]const u8 = null,
    message: []const u8,
};

const error_cases = [_]ErrorCase{
    .{ .name = "err-unclosed-if", .template = @embedFile("fixtures/errors/err-unclosed-if.knap"), .message = @embedFile("fixtures/errors/err-unclosed-if.error") },
    .{ .name = "err-unclosed-for", .template = @embedFile("fixtures/errors/err-unclosed-for.knap"), .message = @embedFile("fixtures/errors/err-unclosed-for.error") },
    .{ .name = "err-unclosed-comment", .template = @embedFile("fixtures/errors/err-unclosed-comment.knap"), .message = @embedFile("fixtures/errors/err-unclosed-comment.error") },
    .{ .name = "err-unclosed-output", .template = @embedFile("fixtures/errors/err-unclosed-output.knap"), .message = @embedFile("fixtures/errors/err-unclosed-output.error") },
    .{ .name = "err-unknown-filter", .template = @embedFile("fixtures/errors/err-unknown-filter.knap"), .message = @embedFile("fixtures/errors/err-unknown-filter.error") },
    .{ .name = "err-bad-args-extra", .template = @embedFile("fixtures/errors/err-bad-args-extra.knap"), .message = @embedFile("fixtures/errors/err-bad-args-extra.error") },
    .{ .name = "err-bad-args-link-missing", .template = @embedFile("fixtures/errors/err-bad-args-link-missing.knap"), .message = @embedFile("fixtures/errors/err-bad-args-link-missing.error") },
    .{ .name = "err-link-scheme-javascript", .template = @embedFile("fixtures/errors/err-link-scheme-javascript.knap"), .message = @embedFile("fixtures/errors/err-link-scheme-javascript.error") },
    .{ .name = "err-link-scheme-from-data", .template = @embedFile("fixtures/errors/err-link-scheme-from-data.knap"), .data = @embedFile("fixtures/errors/err-link-scheme-from-data.json"), .message = @embedFile("fixtures/errors/err-link-scheme-from-data.error") },
    .{ .name = "err-link-scheme-data", .template = @embedFile("fixtures/errors/err-link-scheme-data.knap"), .message = @embedFile("fixtures/errors/err-link-scheme-data.error") },
    .{ .name = "err-arg-resolves-to-object", .template = @embedFile("fixtures/errors/err-arg-resolves-to-object.knap"), .data = @embedFile("fixtures/errors/err-arg-resolves-to-object.json"), .message = @embedFile("fixtures/errors/err-arg-resolves-to-object.error") },
    .{ .name = "err-multiline-bold", .template = @embedFile("fixtures/errors/err-multiline-bold.knap"), .data = @embedFile("fixtures/errors/err-multiline-bold.json"), .message = @embedFile("fixtures/errors/err-multiline-bold.error") },
    .{ .name = "err-ragged-table", .template = @embedFile("fixtures/errors/err-ragged-table.knap"), .data = @embedFile("fixtures/errors/err-ragged-table.json"), .message = @embedFile("fixtures/errors/err-ragged-table.error") },
    .{ .name = "err-deep-list", .template = @embedFile("fixtures/errors/err-deep-list.knap"), .data = @embedFile("fixtures/errors/err-deep-list.json"), .message = @embedFile("fixtures/errors/err-deep-list.error") },
    .{ .name = "err-nonarray-list", .template = @embedFile("fixtures/errors/err-nonarray-list.knap"), .data = @embedFile("fixtures/errors/err-nonarray-list.json"), .message = @embedFile("fixtures/errors/err-nonarray-list.error") },
    .{ .name = "err-loop-nonarray", .template = @embedFile("fixtures/errors/err-loop-nonarray.knap"), .data = @embedFile("fixtures/errors/err-loop-nonarray.json"), .message = @embedFile("fixtures/errors/err-loop-nonarray.error") },
    .{ .name = "err-if-missing-value", .template = @embedFile("fixtures/errors/err-if-missing-value.knap"), .message = @embedFile("fixtures/errors/err-if-missing-value.error") },
    .{ .name = "err-stray-endif", .template = @embedFile("fixtures/errors/err-stray-endif.knap"), .message = @embedFile("fixtures/errors/err-stray-endif.error") },
    .{ .name = "err-nesting-too-deep", .template = @embedFile("fixtures/errors/err-nesting-too-deep.knap"), .message = @embedFile("fixtures/errors/err-nesting-too-deep.error") },
};

fn renderCase(
    arena: std.mem.Allocator,
    template: []const u8,
    data_json: []const u8,
    d: *kt.Diagnostic,
) ![]const u8 {
    const parsed = try std.json.parseFromSliceLeaky(std.json.Value, arena, data_json, .{});
    return kt.render(arena, template, parsed, d);
}

fn renderOk(template: []const u8, data_json: []const u8, expected: []const u8) !void {
    var arena_state = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_state.deinit();
    var d = kt.Diagnostic{};
    const out = try renderCase(arena_state.allocator(), template, data_json, &d);
    testing.expectEqualStrings(expected, out) catch |e| {
        std.debug.print("render mismatch\n--- expected ---\n{s}\n--- actual ---\n{s}\n---\n", .{ expected, out });
        return e;
    };
    try assertTextileDialect();
}

fn renderErr(template: []const u8, data_json: []const u8, needle: []const u8) !void {
    var arena_state = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_state.deinit();
    var d = kt.Diagnostic{};
    const res = renderCase(arena_state.allocator(), template, data_json, &d);
    if (res) |out| {
        std.debug.print("expected error, got output:\n{s}\n", .{out});
        return error.TestExpectedError;
    } else |e| {
        if (e != error.Template) {
            std.debug.print("expected error.Template, got {s}\n", .{@errorName(e)});
            return e;
        }
    }
    if (std.mem.indexOf(u8, d.message, needle) == null) {
        std.debug.print("message mismatch\n--- wanted (substring) ---\n{s}\n--- got ---\n{s}\n", .{ needle, d.message });
        return error.TestUnexpectedResult;
    }
    try assertTextileDialect();
}

fn renderLimit(
    template: []const u8,
    data_json: []const u8,
    max: usize,
    d: *kt.Diagnostic,
    arena: std.mem.Allocator,
) ![]const u8 {
    const parsed = try std.json.parseFromSliceLeaky(std.json.Value, arena, data_json, .{});
    return kt.renderWithLimit(arena, template, parsed, d, max);
}

fn renderLimitOk(template: []const u8, data_json: []const u8, max: usize, expected: []const u8) !void {
    var arena_state = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_state.deinit();
    var d = kt.Diagnostic{};
    const out = try renderLimit(template, data_json, max, &d, arena_state.allocator());
    testing.expectEqualStrings(expected, out) catch |e| {
        std.debug.print("render mismatch\n--- expected ---\n{s}\n--- actual ---\n{s}\n---\n", .{ expected, out });
        return e;
    };
    try assertTextileDialect();
}

fn renderLimitErr(template: []const u8, data_json: []const u8, max: usize, needle: []const u8) !void {
    var arena_state = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_state.deinit();
    var d = kt.Diagnostic{};
    const res = renderLimit(template, data_json, max, &d, arena_state.allocator());
    if (res) |out| {
        std.debug.print("expected error, got output:\n{s}\n", .{out});
        return error.TestExpectedError;
    } else |e| {
        if (e != error.Template) {
            std.debug.print("expected error.Template, got {s}\n", .{@errorName(e)});
            return e;
        }
    }
    if (std.mem.indexOf(u8, d.message, needle) == null) {
        std.debug.print("message mismatch\n--- wanted (substring) ---\n{s}\n--- got ---\n{s}\n", .{ needle, d.message });
        return error.TestUnexpectedResult;
    }
    try assertTextileDialect();
}

/// One render through the Textile pipeline; fails under both mutants.
/// Called from `renderOk`/`renderErr`, so every test in this file
/// re-asserts the dialect and cannot pass while the engine is degraded.
fn assertTextileDialect() !void {
    var arena_state = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_state.deinit();
    var d = kt.Diagnostic{};
    const out = try renderCase(arena_state.allocator(), "{{ \"x\" | bold }}", "{}", &d);
    testing.expectEqualStrings("*x*", out) catch |e| {
        std.debug.print("dialect guard: expected Textile '*x*', got:\n{s}\n", .{out});
        return e;
    };
}

test "corpus: fixtures render byte-exact" {
    var failures: usize = 0;
    for (cases) |c| {
        var arena_state = std.heap.ArenaAllocator.init(testing.allocator);
        defer arena_state.deinit();
        var d = kt.Diagnostic{};
        const out = renderCase(arena_state.allocator(), c.template, c.data, &d) catch |e| {
            std.debug.print("fixture '{s}': unexpected error {s}: {s}\n", .{ c.name, @errorName(e), d.message });
            failures += 1;
            continue;
        };
        if (!std.mem.eql(u8, out, c.expected)) {
            std.debug.print("fixture '{s}': byte mismatch\n--- expected ---\n{s}\n--- actual ---\n{s}\n---\n", .{ c.name, c.expected, out });
            failures += 1;
        }
    }
    try testing.expectEqual(@as(usize, 0), failures);
}

fn formatExpected(comptime name: []const u8, comptime format: kt.Format) []const u8 {
    const extension = if (comptime format == .gfm and
        (std.mem.eql(u8, name, "ex-table") or std.mem.eql(u8, name, "filter-table-basic")))
        ".gfm"
    else
        ".markdown";
    if (comptime std.mem.startsWith(u8, name, "ex-")) {
        return @embedFile("examples/" ++ name[3..] ++ extension);
    }
    return @embedFile("fixtures/" ++ name ++ extension);
}

fn expectFormatFixtures(comptime format: kt.Format) !void {
    var failures: usize = 0;
    inline for (cases) |c| {
        var arena_state = std.heap.ArenaAllocator.init(testing.allocator);
        defer arena_state.deinit();
        const arena = arena_state.allocator();
        const parsed = try std.json.parseFromSliceLeaky(std.json.Value, arena, c.data, .{});
        var d = kt.Diagnostic{};
        if (kt.renderFormat(arena, c.template, parsed, &d, format)) |out| {
            if (!std.mem.eql(u8, out, formatExpected(c.name, format))) {
                std.debug.print("{s} fixture '{s}': byte mismatch\nexpected: {s}\nactual: {s}\n", .{ @tagName(format), c.name, formatExpected(c.name, format), out });
                failures += 1;
            }
        } else |e| {
            std.debug.print("{s} fixture '{s}': error {s}: {s}\n", .{ @tagName(format), c.name, @errorName(e), d.message });
            failures += 1;
        }
    }
    try assertTextileDialect();
    try testing.expectEqual(@as(usize, 0), failures);
}

test "corpus: every fixture renders byte-exact CommonMark" {
    try expectFormatFixtures(.markdown);
}

test "corpus: GFM differs from CommonMark only for table fixtures" {
    try expectFormatFixtures(.gfm);
}

test "unit: scalar list text escapes ordered-list markers only in list context" {
    const samples = .{
        .{ "1. numbered", "1\\. numbered" },
        .{ "1) numbered", "1\\) numbered" },
        .{ "12. numbered", "12\\. numbered" },
        .{ "12) numbered", "12\\) numbered" },
        .{ "0. zero", "0\\. zero" },
        .{ "001) leading zero", "001\\) leading zero" },
        .{ "123456789. nine digits", "123456789\\. nine digits" },
        .{ "123456789) nine digits", "123456789\\) nine digits" },
        .{ "1.", "1\\." },
        .{ "1)", "1\\)" },
        .{ "1.\ttab", "1\\.\ttab" },
        .{ "1)\ttab", "1\\)\ttab" },
        .{ " 1. indented", " 1\\. indented" },
        .{ "   12) indented", "   12\\) indented" },
        .{ "intro\n1. continuation", "intro\n1\\. continuation" },
        .{ "intro\n1) continuation", "intro\n1\\) continuation" },
        .{ "plain 1. inline", "plain 1. inline" },
        .{ "1.2 decimal", "1.2 decimal" },
        .{ "1.no space", "1.no space" },
        .{ "1)no space", "1)no space" },
        .{ "1234567890. ten digits", "1234567890. ten digits" },
        .{ "1234567890) ten digits", "1234567890) ten digits" },
    };
    inline for (samples) |sample| {
        var arena_state = std.heap.ArenaAllocator.init(testing.allocator);
        defer arena_state.deinit();
        const arena = arena_state.allocator();
        const json = try std.json.Stringify.valueAlloc(arena, .{ .items = .{sample[0]}, .text = sample[0] }, .{});
        const data = try std.json.parseFromSliceLeaky(std.json.Value, arena, json, .{});
        var d = kt.Diagnostic{};
        for ([_]kt.Format{ .markdown, .gfm }) |format| {
            try testing.expectEqualStrings("- " ++ sample[1], try kt.renderFormat(arena, "{{ items | list }}", data, &d, format));
            try testing.expectEqualStrings("1. " ++ sample[1], try kt.renderFormat(arena, "{{ items | numbered }}", data, &d, format));
            // This escape belongs to list contents, not raw interpolation or
            // inline filters. Single-line input can also pass through a heading.
            try testing.expectEqualStrings(sample[0], try kt.renderFormat(arena, "{{ text }}", data, &d, format));
            if (comptime std.mem.indexOfScalar(u8, sample[0], '\n') == null) {
                try testing.expectEqualStrings("# " ++ sample[0], try kt.renderFormat(arena, "{{ text | h1 }}", data, &d, format));
            }
        }
        try testing.expectEqualStrings("* " ++ sample[0], try kt.renderFormat(arena, "{{ items | list }}", data, &d, .textile));
        try testing.expectEqualStrings("# " ++ sample[0], try kt.renderFormat(arena, "{{ items | numbered }}", data, &d, .textile));
    }
    try assertTextileDialect();
}

test "unit: list text stays literal while nested arrays retain their markers" {
    const samples = .{
        .{
            "{\"items\":[\"# heading\",\"> quote\",\"---\",\"***\",\"<script>\"]}",
            "- \\# heading\n- \\> quote\n- \\---\n- \\*\\*\\*\n- \\<script\\>",
            "1. \\# heading\n2. \\> quote\n3. \\---\n4. \\*\\*\\*\n5. \\<script\\>",
            "* # heading\n* > quote\n* ---\n* ***\n* <script>",
            "# # heading\n# > quote\n# ---\n# ***\n# <script>",
        },
        .{
            "{\"items\":[\"1. parent\",[\"12) child\",[\"123. grandchild\"],\"2. child\"],\"3) sibling\"]}",
            "- 1\\. parent\n\t- 12\\) child\n\t\t- 123\\. grandchild\n\t- 2\\. child\n- 3\\) sibling",
            "1. 1\\. parent\n   1. 12\\) child\n      1. 123\\. grandchild\n   2. 2\\. child\n2. 3\\) sibling",
            "* 1. parent\n** 12) child\n*** 123. grandchild\n** 2. child\n* 3) sibling",
            "# 1. parent\n## 12) child\n### 123. grandchild\n## 2. child\n# 3) sibling",
        },
    };
    inline for (samples) |sample| {
        var arena_state = std.heap.ArenaAllocator.init(testing.allocator);
        defer arena_state.deinit();
        const arena = arena_state.allocator();
        const data = try std.json.parseFromSliceLeaky(std.json.Value, arena, sample[0], .{});
        var d = kt.Diagnostic{};
        for ([_]kt.Format{ .markdown, .gfm }) |format| {
            try testing.expectEqualStrings(sample[1], try kt.renderFormat(arena, "{{ items | list }}", data, &d, format));
            try testing.expectEqualStrings(sample[2], try kt.renderFormat(arena, "{{ items | numbered }}", data, &d, format));
        }
        try testing.expectEqualStrings(sample[3], try kt.renderFormat(arena, "{{ items | list }}", data, &d, .textile));
        try testing.expectEqualStrings(sample[4], try kt.renderFormat(arena, "{{ items | numbered }}", data, &d, .textile));
    }
    try assertTextileDialect();
}

test "unit: ordered-list indentation follows parent widths at every supported level" {
    const transitions = [_]struct { number: usize, width: usize }{
        .{ .number = 9, .width = 3 },
        .{ .number = 10, .width = 4 },
        .{ .number = 100, .width = 5 },
    };
    for (transitions) |parent| {
        for (transitions) |child_parent| {
            var arena_state = std.heap.ArenaAllocator.init(testing.allocator);
            defer arena_state.deinit();
            const arena = arena_state.allocator();
            var items = std.json.Array.init(arena);
            var children = std.json.Array.init(arena);
            var grandchildren = std.json.Array.init(arena);
            var markdown: std.ArrayList(u8) = .empty;
            var textile: std.ArrayList(u8) = .empty;
            for (1..parent.number + 1) |number| {
                const text = try std.fmt.allocPrint(arena, "parent {d}", .{number});
                try items.append(.{ .string = text });
                try markdown.appendSlice(arena, try std.fmt.allocPrint(arena, "{d}. {s}\n", .{ number, text }));
                try textile.appendSlice(arena, try std.fmt.allocPrint(arena, "# {s}\n", .{text}));
            }
            for (1..child_parent.number + 1) |number| {
                const text = try std.fmt.allocPrint(arena, "child {d}", .{number});
                try children.append(.{ .string = text });
                try markdown.appendNTimes(arena, ' ', parent.width);
                try markdown.appendSlice(arena, try std.fmt.allocPrint(arena, "{d}. {s}\n", .{ number, text }));
                try textile.appendSlice(arena, try std.fmt.allocPrint(arena, "## {s}\n", .{text}));
            }
            try grandchildren.append(.{ .string = "grandchild" });
            try children.append(.{ .array = grandchildren });
            try children.append(.{ .string = "child sibling" });
            try items.append(.{ .array = children });
            try items.append(.{ .string = "parent sibling" });
            try markdown.appendNTimes(arena, ' ', parent.width + child_parent.width);
            try markdown.appendSlice(arena, "1. grandchild\n");
            try markdown.appendNTimes(arena, ' ', parent.width);
            try markdown.appendSlice(arena, try std.fmt.allocPrint(arena, "{d}. child sibling\n{d}. parent sibling", .{ child_parent.number + 1, parent.number + 1 }));
            try textile.appendSlice(arena, "### grandchild\n## child sibling\n# parent sibling");
            var object: std.json.ObjectMap = .empty;
            try object.put(arena, "items", .{ .array = items });
            const data = std.json.Value{ .object = object };
            var d = kt.Diagnostic{};
            for ([_]kt.Format{ .markdown, .gfm }) |format| {
                try testing.expectEqualStrings(markdown.items, try kt.renderFormat(arena, "{{ items | numbered }}", data, &d, format));
            }
            try testing.expectEqualStrings(textile.items, try kt.renderFormat(arena, "{{ items | numbered }}", data, &d, .textile));
        }
    }
    try assertTextileDialect();
}

test "unit: inline code preserves empty, space, and backtick boundaries" {
    const samples = .{
        .{ "{\"text\":\"\"}", "", "@@" },
        .{ "{}", "", "@@" },
        .{ "{\"text\":null}", "", "@@" },
        .{ "{\"text\":\" \"}", "` `", "@ @" },
        .{ "{\"text\":\"   \"}", "`   `", "@   @" },
        .{ "{\"text\":\"\\t\"}", "`\t`", "@\t@" },
        .{ "{\"text\":\" \\t \"}", "`  \t  `", "@ \t @" },
        .{ "{\"text\":\" a \"}", "`  a  `", "@ a @" },
        .{ "{\"text\":\" a\"}", "`  a `", "@ a@" },
        .{ "{\"text\":\"a \"}", "` a  `", "@a @" },
        .{ "{\"text\":\"`\"}", "`` ` ``", "@`@" },
        .{ "{\"text\":\"`a\"}", "`` `a ``", "@`a@" },
        .{ "{\"text\":\"a`\"}", "`` a` ``", "@a`@" },
        .{ "{\"text\":\"a`b```c``d\"}", "````a`b```c``d````", "@a`b```c``d@" },
        .{ "{\"text\":\" ``` \"}", "````  ```  ````", "@ ``` @" },
    };
    inline for (samples) |sample| {
        var arena_state = std.heap.ArenaAllocator.init(testing.allocator);
        defer arena_state.deinit();
        const arena = arena_state.allocator();
        const data = try std.json.parseFromSliceLeaky(std.json.Value, arena, sample[0], .{});
        var d = kt.Diagnostic{};
        for ([_]kt.Format{ .markdown, .gfm }) |format| {
            const out = try kt.renderFormat(arena, "{{ text | code }}", data, &d, format);
            try testing.expectEqualStrings(sample[1], out);
        }
        const textile = try kt.renderFormat(arena, "{{ text | code }}", data, &d, .textile);
        try testing.expectEqualStrings(sample[2], textile);
    }
    try assertTextileDialect();
}

test "unit: code fences preserve empty content and terminal newlines" {
    const samples = .{
        .{ "{\"text\":\"\"}", "```\n```", "bc. " },
        .{ "{\"text\":\"   \"}", "```\n   \n```", "bc.    " },
        .{ "{\"text\":\"x\"}", "```\nx\n```", "bc. x" },
        .{ "{\"text\":\"x\\n\"}", "```\nx\n```", "bc. x\n" },
        .{ "{\"text\":\"x\\n\\n\"}", "```\nx\n\n```", "bc. x\n\n" },
        .{ "{\"text\":\"x\\n\\n\\n\"}", "```\nx\n\n\n```", "bc. x\n\n\n" },
        .{ "{\"text\":\"\\n\"}", "```\n\n```", "bc. \n" },
        .{ "{\"text\":\"\\n\\n\"}", "```\n\n\n```", "bc. \n\n" },
        .{ "{\"text\":\"```\\nx\"}", "````\n```\nx\n````", "bc. ```\nx" },
        .{ "{\"text\":\"x\\n```\\n\"}", "````\nx\n```\n````", "bc. x\n```\n" },
        .{ "{\"text\":\"`````\\nx\\n```\\n\\n\"}", "``````\n`````\nx\n```\n\n``````", "bc. `````\nx\n```\n\n" },
    };
    inline for (samples) |sample| {
        var arena_state = std.heap.ArenaAllocator.init(testing.allocator);
        defer arena_state.deinit();
        const arena = arena_state.allocator();
        const data = try std.json.parseFromSliceLeaky(std.json.Value, arena, sample[0], .{});
        var d = kt.Diagnostic{};
        for ([_]kt.Format{ .markdown, .gfm }) |format| {
            const out = try kt.renderFormat(arena, "{{ text | codeblock }}", data, &d, format);
            try testing.expectEqualStrings(sample[1], out);
        }
        const textile = try kt.renderFormat(arena, "{{ text | codeblock }}", data, &d, .textile);
        try testing.expectEqualStrings(sample[2], textile);
    }
    try assertTextileDialect();
}

test "unit: GFM tables have an empty header and escape text cells" {
    const samples = .{
        .{ "{\"rows\":[[\"title\"]]}", "|  |\n| - |\n| title |" },
        .{ "{\"rows\":[[\"*em*\",\"<b>&\",\"\\\\x\"],[1,true,null]]}", "|  |  |  |\n| - | - | - |\n| \\*em\\* | \\<b\\>&amp; | \\\\x |\n| 1 | true |  |" },
    };
    inline for (samples) |sample| {
        var arena_state = std.heap.ArenaAllocator.init(testing.allocator);
        defer arena_state.deinit();
        const arena = arena_state.allocator();
        const data = try std.json.parseFromSliceLeaky(std.json.Value, arena, sample[0], .{});
        var d = kt.Diagnostic{};
        const out = try kt.renderFormat(arena, "{{ rows | table }}", data, &d, .gfm);
        try testing.expectEqualStrings(sample[1], out);
    }
    try assertTextileDialect();
}

test "unit: GFM tables retain CommonMark validation and diagnostics" {
    const samples = .{
        .{ "{\"rows\":null}", "expects an array of rows" },
        .{ "{\"rows\":[]}", "expects at least one row" },
        .{ "{\"rows\":[[]]}", "expects at least one cell" },
        .{ "{\"rows\":[\"x\"]}", "each row to be an array" },
        .{ "{\"rows\":[[\"x\"],[\"y\",\"z\"]]}", "same number of cells" },
        .{ "{\"rows\":[[{}]]}", "expects text cells" },
        .{ "{\"rows\":[[[\"x\"]]]}", "expects text cells" },
        .{ "{\"rows\":[[\"x|y\"]]}", "must not contain '|'" },
        .{ "{\"rows\":[[\"x\\ny\"]]}", "or a newline" },
    };
    inline for (samples) |sample| {
        var arena_state = std.heap.ArenaAllocator.init(testing.allocator);
        defer arena_state.deinit();
        const arena = arena_state.allocator();
        const data = try std.json.parseFromSliceLeaky(std.json.Value, arena, sample[0], .{});
        var markdown_d = kt.Diagnostic{};
        var gfm_d = kt.Diagnostic{};
        try testing.expectError(error.Template, kt.renderFormat(arena, "{{ rows | table }}", data, &markdown_d, .markdown));
        try testing.expectError(error.Template, kt.renderFormat(arena, "{{ rows | table }}", data, &gfm_d, .gfm));
        try testing.expectEqualStrings(markdown_d.message, gfm_d.message);
        try testing.expect(std.mem.indexOf(u8, gfm_d.message, sample[1]) != null);
    }
    try assertTextileDialect();
}

test "unit: GFM tables respect the output cap" {
    var arena_state = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();
    const data = try std.json.parseFromSliceLeaky(std.json.Value, arena, "{\"rows\":[[\"x\"]]}", .{});
    const expected = "|  |\n| - |\n| x |";
    var d = kt.Diagnostic{};
    const out = try kt.renderFormatWithLimit(arena, "{{ rows | table }}", data, &d, .gfm, expected.len);
    try testing.expectEqualStrings(expected, out);
    try testing.expectError(error.Template, kt.renderFormatWithLimit(arena, "{{ rows | table }}", data, &d, .gfm, expected.len - 1));
    try testing.expect(std.mem.indexOf(u8, d.message, "output exceeded") != null);
    try assertTextileDialect();
}

test "corpus: error fixtures fail with the pinned message" {
    var failures: usize = 0;
    for (error_cases) |c| {
        var arena_state = std.heap.ArenaAllocator.init(testing.allocator);
        defer arena_state.deinit();
        var d = kt.Diagnostic{};
        const data_json = c.data orelse "{}";
        const res = renderCase(arena_state.allocator(), c.template, data_json, &d);
        if (res) |out| {
            std.debug.print("error fixture '{s}': expected failure, got output [{s}]\n", .{ c.name, out });
            failures += 1;
            continue;
        } else |e| {
            if (e != error.Template) {
                std.debug.print("error fixture '{s}': expected error.Template, got {s}\n", .{ c.name, @errorName(e) });
                failures += 1;
                continue;
            }
        }
        var needle: []const u8 = c.message;
        while (needle.len > 0 and (needle[needle.len - 1] == '\n' or needle[needle.len - 1] == '\r')) {
            needle = needle[0 .. needle.len - 1];
        }
        if (std.mem.indexOf(u8, d.message, needle) == null) {
            std.debug.print("error fixture '{s}': message mismatch\n--- wanted ---\n{s}\n--- got ---\n{s}\n", .{ c.name, needle, d.message });
            failures += 1;
        }
    }
    try assertTextileDialect();
    try testing.expectEqual(@as(usize, 0), failures);
}

/// Expected lint rule per error fixture. `null` marks fixtures whose failure
/// is data-dependent: without `--data` there is nothing to see, so lint
/// reports them clean (lint checks templates, not data).
const err_lint_rules = [_]struct { name: []const u8, rule: ?[]const u8 }{
    .{ .name = "err-unclosed-if", .rule = "unclosed-if" },
    .{ .name = "err-unclosed-for", .rule = "unclosed-for" },
    .{ .name = "err-unclosed-comment", .rule = "unclosed-comment" },
    .{ .name = "err-unclosed-output", .rule = "unclosed-output-tag" },
    .{ .name = "err-unknown-filter", .rule = "unknown-filter" },
    .{ .name = "err-bad-args-extra", .rule = "filter-arg-unexpected" },
    .{ .name = "err-bad-args-link-missing", .rule = "link-missing-url" },
    .{ .name = "err-link-scheme-javascript", .rule = "link-scheme" },
    .{ .name = "err-link-scheme-from-data", .rule = null },
    .{ .name = "err-link-scheme-data", .rule = "link-scheme" },
    .{ .name = "err-arg-resolves-to-object", .rule = null },
    .{ .name = "err-multiline-bold", .rule = null },
    .{ .name = "err-ragged-table", .rule = null },
    .{ .name = "err-deep-list", .rule = null },
    .{ .name = "err-nonarray-list", .rule = null },
    .{ .name = "err-loop-nonarray", .rule = null },
    .{ .name = "err-if-missing-value", .rule = "missing-value" },
    .{ .name = "err-stray-endif", .rule = "misplaced-closing-tag" },
    .{ .name = "err-nesting-too-deep", .rule = "nesting-too-deep" },
};

const lint_broken = [_]struct { name: []const u8, template: []const u8, rule: []const u8 }{
    .{ .name = "unknown-logic-tag", .template = @embedFile("fixtures/lint/unknown-logic-tag.knap"), .rule = "unknown-logic-tag" },
    .{ .name = "for-missing-var", .template = @embedFile("fixtures/lint/for-missing-var.knap"), .rule = "for-missing-var" },
    .{ .name = "for-missing-in", .template = @embedFile("fixtures/lint/for-missing-in.knap"), .rule = "for-missing-in" },
    .{ .name = "for-trailing-text", .template = @embedFile("fixtures/lint/for-trailing-text.knap"), .rule = "for-trailing-text" },
    .{ .name = "elseif-after-else", .template = @embedFile("fixtures/lint/elseif-after-else.knap"), .rule = "elseif-after-else" },
    .{ .name = "duplicate-else", .template = @embedFile("fixtures/lint/duplicate-else.knap"), .rule = "duplicate-else" },
    .{ .name = "endif-trailing-text", .template = @embedFile("fixtures/lint/endif-trailing-text.knap"), .rule = "closing-tag-trailing-text" },
    .{ .name = "missing-filter-name", .template = @embedFile("fixtures/lint/missing-filter-name.knap"), .rule = "missing-filter-name" },
    .{ .name = "output-tag-trailing-text", .template = @embedFile("fixtures/lint/output-tag-trailing-text.knap"), .rule = "output-tag-trailing-text" },
    .{ .name = "missing-filter-arg", .template = @embedFile("fixtures/lint/missing-filter-arg.knap"), .rule = "missing-filter-arg" },
    .{ .name = "bracket-key", .template = @embedFile("fixtures/lint/bracket-key.knap"), .rule = "bracket-key" },
    .{ .name = "bracket-unclosed", .template = @embedFile("fixtures/lint/bracket-unclosed.knap"), .rule = "bracket-unclosed" },
    .{ .name = "condition-trailing-text", .template = @embedFile("fixtures/lint/condition-trailing-text.knap"), .rule = "condition-trailing-text" },
    .{ .name = "unclosed-paren", .template = @embedFile("fixtures/lint/unclosed-paren.knap"), .rule = "unclosed-paren" },
    .{ .name = "invalid-number", .template = @embedFile("fixtures/lint/invalid-number.knap"), .rule = "invalid-number" },
    .{ .name = "empty-logic-tag", .template = @embedFile("fixtures/lint/empty-logic-tag.knap"), .rule = "empty-logic-tag" },
    .{ .name = "missing-value", .template = @embedFile("fixtures/lint/missing-value.knap"), .rule = "missing-value" },
    .{ .name = "link-url-text", .template = @embedFile("fixtures/lint/link-url-text.knap"), .rule = "link-url-text" },
};

fn expectTeaching(finding: kt.Finding, name: []const u8) !void {
    if (finding.construct.len == 0 or finding.why.len == 0 or finding.example.len == 0) {
        std.debug.print("lint finding '{s}' ({s}): construct/why/example must all be non-empty\n", .{ name, finding.rule });
        return error.TestUnexpectedResult;
    }
    if (finding.detail.len == 0) {
        std.debug.print("lint finding '{s}' ({s}): empty detail\n", .{ name, finding.rule });
        return error.TestUnexpectedResult;
    }
}

test "lint: error fixtures produce teaching findings" {
    var failures: usize = 0;
    for (error_cases) |c| {
        // The rule map must cover every error fixture: a new fixture without
        // an entry fails here instead of silently passing as data-dependent.
        const expected = for (err_lint_rules) |m| {
            if (std.mem.eql(u8, m.name, c.name)) break m.rule;
        } else {
            std.debug.print("error fixture '{s}' has no err_lint_rules entry\n", .{c.name});
            failures += 1;
            continue;
        };
        var arena_state = std.heap.ArenaAllocator.init(testing.allocator);
        defer arena_state.deinit();
        var d = kt.Diagnostic{};
        const findings = kt.lintDocument(arena_state.allocator(), c.template, &d) catch |e| {
            std.debug.print("error fixture '{s}': lint failed: {s}\n", .{ c.name, @errorName(e) });
            failures += 1;
            continue;
        };
        if (expected) |rule| {
            var matched = false;
            for (findings) |f| {
                if (std.mem.eql(u8, f.rule, rule)) {
                    matched = true;
                    expectTeaching(f, c.name) catch |e| {
                        failures += 1;
                        return e;
                    };
                }
            }
            if (!matched) {
                std.debug.print("error fixture '{s}': expected lint rule '{s}', got {d} finding(s)", .{ c.name, rule, findings.len });
                for (findings) |f| std.debug.print(" [{s}]", .{f.rule});
                std.debug.print("\n", .{});
                failures += 1;
            }
        } else {
            if (findings.len != 0) {
                std.debug.print("error fixture '{s}': data-dependent, expected lint-clean, got {d} finding(s): {s}\n", .{ c.name, findings.len, findings[0].rule });
                failures += 1;
            }
        }
    }
    try assertTextileDialect();
    try testing.expectEqual(@as(usize, 0), failures);
}

test "lint: lint fixtures map to their rules" {
    var failures: usize = 0;
    for (lint_broken) |c| {
        var arena_state = std.heap.ArenaAllocator.init(testing.allocator);
        defer arena_state.deinit();
        var d = kt.Diagnostic{};
        const findings = kt.lintDocument(arena_state.allocator(), c.template, &d) catch |e| {
            std.debug.print("lint fixture '{s}': lint failed: {s}\n", .{ c.name, @errorName(e) });
            failures += 1;
            continue;
        };
        var matched = false;
        for (findings) |f| {
            if (std.mem.eql(u8, f.rule, c.rule)) {
                matched = true;
                expectTeaching(f, c.name) catch |e| {
                    failures += 1;
                    return e;
                };
            }
        }
        if (!matched) {
            std.debug.print("lint fixture '{s}': expected lint rule '{s}', got {d} finding(s)", .{ c.name, c.rule, findings.len });
            for (findings) |f| std.debug.print(" [{s}]", .{f.rule});
            std.debug.print("\n", .{});
            failures += 1;
        }
    }
    try assertTextileDialect();
    try testing.expectEqual(@as(usize, 0), failures);
}

test "lint: the fixture corpus lints clean" {
    var failures: usize = 0;
    for (cases) |c| {
        var arena_state = std.heap.ArenaAllocator.init(testing.allocator);
        defer arena_state.deinit();
        var d = kt.Diagnostic{};
        const findings = kt.lintDocument(arena_state.allocator(), c.template, &d) catch |e| {
            std.debug.print("fixture '{s}': lint failed: {s}\n", .{ c.name, @errorName(e) });
            failures += 1;
            continue;
        };
        if (findings.len != 0) {
            std.debug.print("fixture '{s}': expected lint-clean, got {d} finding(s)\n", .{ c.name, findings.len });
            for (findings) |f| std.debug.print("  {s}: {s}\n", .{ f.rule, f.detail });
            failures += 1;
        }
    }
    try assertTextileDialect();
    try testing.expectEqual(@as(usize, 0), failures);
}

test "lint: an empty template is clean" {
    var arena_state = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_state.deinit();
    var d = kt.Diagnostic{};
    const findings = try kt.lintDocument(arena_state.allocator(), "", &d);
    try testing.expectEqual(@as(usize, 0), findings.len);
    try assertTextileDialect();
}

test "lint: a parse failure carries position and teaching text" {
    var arena_state = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_state.deinit();
    var d = kt.Diagnostic{};
    const findings = try kt.lintDocument(arena_state.allocator(), "pre\n{% if x %}oops", &d);
    try testing.expectEqual(@as(usize, 1), findings.len);
    try testing.expectEqualStrings("unclosed-if", findings[0].rule);
    try testing.expectEqual(@as(u32, 2), findings[0].line);
    try testing.expectEqual(@as(u32, 1), findings[0].column);
    try testing.expect(findings[0].construct.len > 0);
    try testing.expect(findings[0].why.len > 0);
    try testing.expect(findings[0].example.len > 0);
    try assertTextileDialect();
}

test "lint: registry walk reports unknown filter and arity in one pass" {
    var arena_state = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_state.deinit();
    var d = kt.Diagnostic{};
    const findings = try kt.lintDocument(
        arena_state.allocator(),
        "{{ a | nope }} {{ b | bold:7 }} {{ c | link }}",
        &d,
    );
    try testing.expectEqual(@as(usize, 3), findings.len);
    try testing.expectEqualStrings("unknown-filter", findings[0].rule);
    try testing.expectEqualStrings("filter-arg-unexpected", findings[1].rule);
    try testing.expectEqualStrings("link-missing-url", findings[2].rule);
    try assertTextileDialect();
}

test "lint: paren nesting beyond the limit is a finding" {
    var arena_state = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_state.deinit();
    var buf: std.ArrayList(u8) = .empty;
    defer buf.deinit(testing.allocator);
    try buf.appendSlice(testing.allocator, "{% if ");
    for (0..33) |_| try buf.appendSlice(testing.allocator, "(");
    try buf.appendSlice(testing.allocator, "a");
    for (0..33) |_| try buf.appendSlice(testing.allocator, ")");
    try buf.appendSlice(testing.allocator, " %}x{% endif %}");
    var d = kt.Diagnostic{};
    const findings = try kt.lintDocument(arena_state.allocator(), buf.items, &d);
    try testing.expectEqual(@as(usize, 1), findings.len);
    try testing.expectEqualStrings("paren-too-deep", findings[0].rule);
    try assertTextileDialect();
}

test "property: every registry filter has at least one fixture case" {
    var buf: [64]u8 = undefined;
    for (kt.filters.registry()) |entry| {
        const prefix = try std.fmt.bufPrint(&buf, "filter-{s}-", .{entry.name});
        var found = false;
        for (cases) |c| {
            if (std.mem.startsWith(u8, c.name, prefix)) {
                found = true;
                break;
            }
        }
        if (!found) std.debug.print("no fixture case for filter '{s}'\n", .{entry.name});
        try testing.expect(found);
    }
    try assertTextileDialect();
}

test "property: no case output equals its template" {
    for (cases) |c| {
        if (std.mem.eql(u8, c.expected, c.template)) {
            std.debug.print("fixture '{s}' output equals its template (passthrough would pass)\n", .{c.name});
            try testing.expect(false);
        }
    }
    try assertTextileDialect();
}

test "unit: whitespace-free tags" {
    try renderOk("{{name}}!", "{\"name\":\"Ada\"}", "Ada!");
}

test "unit: number and string literals" {
    try renderOk("{{ 7 }} {{ -3 }} {{ 1.5 }} {{ \"Hi\" }}", "{}", "7 -3 1.5 Hi");
}

test "unit: escaped quote in string literal" {
    try renderOk("{{ \"a\\\"b\" | bold }}", "{}", "*a\"b*");
}

test "unit: missing variable is false in conditions" {
    try renderOk("{% if missing %}y{% else %}n{% endif %}", "{}", "n");
}

test "unit: empty string, null, and false are falsy" {
    try renderOk(
        "{% if v %}y{% else %}n{% endif %}{% if w %}y{% else %}n{% endif %}{% if x %}y{% else %}n{% endif %}",
        "{\"v\":\"\",\"w\":null,\"x\":false}",
        "nnn",
    );
}

test "unit: ordered comparison and numeric equality" {
    try renderOk("{% if price >= 100 %}big{% else %}small{% endif %}", "{\"price\":42.57}", "small");
    try renderOk("{% if price >= 100 %}big{% else %}small{% endif %}", "{\"price\":100}", "big");
    try renderOk("{% if n == 2 %}eq{% else %}ne{% endif %}", "{\"n\":2.0}", "eq");
}

test "unit: non-scalar equality is reflexive" {
    try renderOk("{% if x == x %}EQ{% else %}NEQ{% endif %}", "{\"x\":{\"k\":1}}", "EQ");
    try renderOk("{% if x == x %}EQ{% else %}NEQ{% endif %}", "{\"x\":[1,[2]]}", "EQ");
    try renderOk("{% if x == x %}EQ{% else %}NEQ{% endif %}", "{\"x\":{}}", "EQ");
    try renderOk("{% if x == x %}EQ{% else %}NEQ{% endif %}", "{\"x\":[]}", "EQ");
}

test "unit: object equality ignores key order" {
    try renderOk("{% if a == b %}EQ{% else %}NEQ{% endif %}", "{\"a\":{\"p\":1,\"q\":2},\"b\":{\"q\":2,\"p\":1}}", "EQ");
    // An extra key, not just a reordered one, must still compare unequal.
    try renderOk("{% if a == b %}EQ{% else %}NEQ{% endif %}", "{\"a\":{\"p\":1},\"b\":{\"p\":1,\"q\":2}}", "NEQ");
}

test "unit: comparison across kinds is not equality" {
    try renderOk("{% if a == b %}EQ{% else %}NEQ{% endif %}", "{\"a\":{},\"b\":[]}", "NEQ");
    try renderOk("{% if a == b %}EQ{% else %}NEQ{% endif %}", "{\"a\":{\"k\":1},\"b\":\"{\\\"k\\\":1}\"}", "NEQ");
    try renderOk("{% if a != b %}NEQ{% else %}EQ{% endif %}", "{\"a\":{\"k\":1},\"b\":{\"k\":1}}", "EQ");
}

test "unit: contains matches object members structurally" {
    try renderOk(
        "{% if items contains needle %}hit{% else %}miss{% endif %}",
        "{\"items\":[{\"k\":1},{\"k\":2}],\"needle\":{\"k\":2}}",
        "hit",
    );
    try renderOk(
        "{% if items contains needle %}hit{% else %}miss{% endif %}",
        "{\"items\":[{\"k\":1}],\"needle\":{\"k\":9}}",
        "miss",
    );
}

test "unit: nested containers compare element-wise" {
    try renderOk("{% if a == b %}EQ{% else %}NEQ{% endif %}", "{\"a\":[[1,2]],\"b\":[[1,2]]}", "EQ");
    try renderOk("{% if a == b %}EQ{% else %}NEQ{% endif %}", "{\"a\":[[1,2]],\"b\":[[1,3]]}", "NEQ");
}

test "unit: bang negation" {
    try renderOk("{% if !hidden %}v{% endif %}", "{\"hidden\":false}", "v");
}

test "unit: loop.index0 and loop.first" {
    try renderOk(
        "{% for x in xs %}{{ loop.index0 }}{% if loop.first %}F{% endif %}{% endfor %}",
        "{\"xs\":[\"a\",\"b\"]}",
        "0F1",
    );
}

test "unit: loop over a nested array path" {
    try renderOk("{% for item in a.b %}{{ item }};{% endfor %}", "{\"a\":{\"b\":[1,2]}}", "1;2;");
    try renderOk("{% for item in a[0] %}{{ item }}{% endfor %}", "{\"a\":[[\"p\",\"q\"]]}", "pq");
}

test "unit: loop body leading-newline strip applies once" {
    try renderOk("{% for x in xs %}\n\n{{ x }}\n{% endfor %}", "{\"xs\":[\"A\",\"B\"]}", "\nA\n\nB\n");
}

test "unit: if-branch leading-newline strip" {
    try renderOk("{% if a %}\nX\n{% else %}\nY\n{% endif %}", "{\"a\":true}", "X\n");
}

test "unit: comments strip only themselves" {
    try renderOk("A {# note #} B", "{}", "A  B");
}

test "unit: float and integer rendering" {
    try renderOk("{{ a }} {{ b }}", "{\"a\":2.0,\"b\":1.5}", "2 1.5");
}

test "unit: three-filter chain" {
    try renderOk("{{ \"n\" | code | bold | h2 }}", "{}", "h2. *@n@*");
}

test "unit: a bare filter argument falls back to the literal" {
    // No such key in the data root, so `missing` stays the word.
    try renderOk("{{ \"x\" | link:missing }}", "{}", "\"x\":missing");
}

test "unit: bare filter arguments render scalar data values" {
    try renderOk("{{ \"x\" | link:n }}", "{\"n\":42}", "\"x\":42");
    try renderOk("{{ \"x\" | link:b }}", "{\"b\":true}", "\"x\":true");
    try renderOk("{{ \"x\" | link:s }}", "{\"s\":\"https://y/\"}", "\"x\":https://y/");
}

test "unit: a non-text filter argument is a bad argument" {
    try renderErr("{{ \"x\" | link:obj }}", "{\"obj\":{\"k\":1}}", "filter arguments must be text");
    try renderErr("{{ \"x\" | link:u }}", "{\"u\":null}", "filter arguments must be text");
}

test "unit: navigational and relative link URLs stay allowed" {
    try renderOk("{{ \"x\" | link:\"mailto:a@b.c\" }}", "{}", "\"x\":mailto:a@b.c");
    try renderOk("{{ \"x\" | link:\"file:///etc/passwd\" }}", "{}", "\"x\":file:///etc/passwd");
    try renderOk("{{ \"x\" | link:\"../notes/page.html\" }}", "{}", "\"x\":../notes/page.html");
    // A colon that is not a well-formed scheme belongs to the path.
    try renderOk("{{ \"x\" | link:\"a/b:c\" }}", "{}", "\"x\":a/b:c");
}

test "unit: blocked link schemes are rejected case-insensitively" {
    for ([_][]const u8{ "javascript:alert(1)", "JavaScript:alert(1)", "JAVASCRIPT:alert(1)", "vbscript:m", "data:text/html,x" }) |url| {
        var buf: [128]u8 = undefined;
        // `{{{{` / `}}}}` because std.fmt treats doubled braces as escapes.
        const tpl = try std.fmt.bufPrint(&buf, "{{{{ \"x\" | link:\"{s}\" }}}}", .{url});
        try renderErr(tpl, "{}", "which can execute script");
    }
}

test "unit: a blocked scheme reaching link through the data is rejected" {
    try renderErr("{{ name | link:url }}", "{\"name\":\"c\",\"url\":\"javascript:alert(1)\"}", "which can execute script");
}

test "unit: nested loops that would multiply hit the output cap" {
    // 20 * 20 = 400 one-byte iterations, so a 100-byte cap must trip.
    const tpl = "{% for x in a %}{% for y in a %}x{% endfor %}{% endfor %}";
    try renderLimitErr(
        tpl,
        "{\"a\":[0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19]}",
        100,
        "output exceeded the 100 byte limit at loop depth 2",
    );
}

test "unit: the output cap is an exact ceiling" {
    try renderLimitOk("{{ s }}", "{\"s\":\"hello\"}", 5, "hello");
    try renderLimitErr("{{ s }}", "{\"s\":\"hello\"}", 4, "output exceeded the 4 byte limit");
}

test "unit: a zero output limit disables the cap" {
    try renderLimitOk("{{ s }}", "{\"s\":\"hello\"}", 0, "hello");
}

test "unit: structured values are charged against the output cap" {
    // `{{ data }}` emits compact JSON through a separate write path; it must
    // still be charged, or the cap has a hole.
    try renderLimitOk("{{ data }}", "{\"data\":{\"k\":1}}", 100, "{\"k\":1}");
    try renderLimitErr("{{ data }}", "{\"data\":{\"k\":1}}", 4, "output exceeded the 4 byte limit");
}

test "unit: the default cap is generous enough for ordinary renders" {
    // This must render something. A bare constant assertion would pass under
    // -Dengine-mode=passthrough, and every test in this file is supposed to
    // fail against the degraded engine.
    try renderOk("{{ a }} {{ b | bold }}", "{\"a\":\"x\",\"b\":\"y\"}", "x *y*");
    try testing.expect(kt.default_max_output > 1024 * 1024);
}

test "unit: spaced names are not valid condition operands" {
    try renderErr("{% if First name %}x{% endif %}", "{}", "unexpected text after condition");
}

test "unit: unknown logic tag names the tag" {
    try renderErr("{% set x = 1 %}", "{}", "unknown logic tag 'set'");
}

test "unit: duplicate else is rejected" {
    try renderErr("{% if a %}x{% else %}y{% else %}z{% endif %}", "{\"a\":true}", "duplicate '{% else %}'");
}

test "unit: empty output tag is rejected" {
    try renderErr("{{ }}", "{}", "expected a value");
}

test "unit: error columns count Unicode code points" {
    try renderErr("{{ 京 | nope }}", "{}", "unknown filter at line 1, column 8");
}

test "unit: diagnostic fields for an unknown filter" {
    var arena_state = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_state.deinit();
    var d = kt.Diagnostic{};
    const res = renderCase(arena_state.allocator(), "{{ title | nope }}\n", "{}", &d);
    try testing.expectError(error.Template, res);
    try testing.expectEqual(kt.diag.Kind.unknown_filter, d.kind);
    try testing.expectEqual(@as(u32, 1), d.line);
    try testing.expectEqual(@as(u32, 12), d.column);
    try assertTextileDialect();
}
