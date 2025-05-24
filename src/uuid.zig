const std                = @import("std");
const mem                = std.mem;
const bufPrintIntToSlice = std.fmt.bufPrintIntToSlice;


pub fn format_hyphenless(uuid : u128) [32]u8 {
    var buf = mem.zeroes([32]u8);
    _ = bufPrintIntToSlice(&buf, uuid, 16, .lower, .{
        .width     = 32,
        .alignment = .right,
        .fill      = '0'
    });
    return buf;
}


pub fn format(uuid : u128) [36]u8 {
    const hyphenless = format_hyphenless(uuid);
    return (hyphenless[0..8] ++ "-" ++ hyphenless[8..12] ++ "-" ++ hyphenless[12..16] ++ "-" ++ hyphenless[16..20] ++ "-" ++ hyphenless[20..32]).*;
}
