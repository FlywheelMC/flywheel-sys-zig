const std       = @import("std");
const Alignment = std.mem.Alignment;
const panic     = std.debug.panic;

pub const allocator = std.heap.page_allocator;


export fn flywheel_alloc(len : u32, alignment : u32) u32 {
    const ptr = allocator.rawAlloc(len, Alignment.fromByteUnits(alignment), 0) orelse null;
    if (ptr == null) { panic("allocation failed", .{}); }
    return @intFromPtr(ptr);
}
