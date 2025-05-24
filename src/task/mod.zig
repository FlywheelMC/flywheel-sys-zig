const std = @import("std");
const mem = std.mem;

const time      = @import("../time.zig");
const Instant   = time.Instant;
const Duration  = time.Duration;

pub const schedule_at = @import("private.zig").schedule_at;


pub fn schedule_in(dur : Duration, function : anytype, args : anytype) void {
    schedule_at(Instant.now().add(dur), function, args);
}
