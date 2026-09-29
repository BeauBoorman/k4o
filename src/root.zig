//! knap-textile: a Knap template engine that emits Textile.
//!
//! Public API surface:
//!
//!     const kt = @import("knap_textile");
//!
//!     var d: kt.Diagnostic = .{};
//!     const out = try kt.render(arena, template_bytes, json_value, &d);

pub const diag = @import("diag.zig");
pub const parse = @import("parse.zig");
pub const filters = @import("filters.zig");
pub const engine = @import("engine.zig");

pub const Diagnostic = diag.Diagnostic;
pub const render = engine.render;
pub const Error = engine.Error;
