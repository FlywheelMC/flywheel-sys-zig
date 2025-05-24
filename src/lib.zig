const internal = @import("internal/mod.zig");
pub const allocator = internal.alloc.allocator;
pub const App       = internal.scheduler.App;

pub const game = @import("game/mod.zig");

pub const log = @import("log.zig");
