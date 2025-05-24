const std            = @import("std");
const SourceLocation = std.builtin.SourceLocation;
const mem            = std.mem;
const allocPrint     = std.fmt.allocPrint;
const panic          = std.debug.panic;

const allocator = @import("internal/alloc.zig").allocator;


extern fn flywheel_trace(in_msg : u32, msg_len : u32) void;
extern fn flywheel_debug(in_msg : u32, msg_len : u32) void;
extern fn flywheel_info(in_msg : u32, msg_len : u32) void;
extern fn flywheel_pass(in_msg : u32, msg_len : u32) void;
extern fn flywheel_warn(in_msg : u32, msg_len : u32) void;
extern fn flywheel_error(in_msg : u32, msg_len : u32) void;
extern fn flywheel_fatal(in_msg : u32, msg_len : u32) void;


pub fn trace(comptime s : SourceLocation, comptime fmt : []const u8, args : anytype) void {
    log(s, fmt, args, flywheel_trace);
}

pub fn debug(comptime s : SourceLocation, comptime fmt : []const u8, args : anytype) void {
    log(s, fmt, args, flywheel_debug);
}

pub fn info(comptime s : SourceLocation, comptime fmt : []const u8, args : anytype) void {
    log(s, fmt, args, flywheel_info);
}

pub fn pass(comptime s : SourceLocation, comptime fmt : []const u8, args : anytype) void {
    log(s, fmt, args, flywheel_pass);
}

pub fn warn(comptime s : SourceLocation, comptime fmt : []const u8, args : anytype) void {
    log(s, fmt, args, flywheel_warn);
}

pub fn err(comptime s : SourceLocation, comptime fmt : []const u8, args : anytype) void {
    log(s, fmt, args, flywheel_error);
}

pub fn fatal(comptime s : SourceLocation, comptime fmt : []const u8, args : anytype) void {
    log(s, fmt, args, flywheel_fatal);
}


fn log(comptime s : SourceLocation, comptime fmt : []const u8, args : anytype, callback : *const fn(u32, u32) callconv(.c) void) void {
    const file = comptime strip_dotzig(s.file);
    const msg = allocPrint(allocator,
        "[{s}:{}:{}] " ++ fmt,
        .{ file, s.line, s.column } ++ args
    ) catch panic("out of memory", .{});
    callback(@intFromPtr(msg.ptr), msg.len);
    allocator.free(msg);
}

fn strip_dotzig(comptime file : []const u8) []const u8 {
    if (file.len < 4) {
        return file;
    }
    const suffix = file[(file.len - 4)..(file.len)];
    if (! mem.eql(u8, suffix, ".zig")) {
        return file;
    }
    return file[0..(file.len - 4)];
}
