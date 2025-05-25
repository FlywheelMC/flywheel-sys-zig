const std                = @import("std");
const mem                = std.mem;
const fmt                = std.fmt;
const bufPrintIntToSlice = std.fmt.bufPrintIntToSlice;


pub const Uuid = struct {
    bytes : [16]u8,

    pub const ZERO : Uuid = Uuid.from_bytes([_]u8{ 0 } ** 16);

    pub const MAX : Uuid = Uuid.from_bytes([_]u8{ 0xff } ** 16);

    pub fn from_fields(d1 : u32, d2 : u16, d3 : u16, d4 : [8]u8) Uuid {
        return Uuid.from_bytes([16]u8{
            d1 >> 24,
            d1 >> 16,
            d1 >> 8,
            d1,
            d2 >> 8,
            d2,
            d3 >> 8,
            d3,
            d4[0],
            d4[1],
            d4[2],
            d4[3],
            d4[4],
            d4[5],
            d4[6],
            d4[7]
        });
    }

    pub fn from_fields_le(d1 : u32, d2 : u16, d3 : u16, d4 : [8]u8) Uuid {
        return Uuid.from_bytes([16]u8{
            d1,
            d1 >> 8,
            d1 >> 16,
            d1 >> 24,
            d2,
            d2 >> 8,
            d3,
            d3 >> 8,
            d4[0],
            d4[1],
            d4[2],
            d4[3],
            d4[4],
            d4[5],
            d4[6],
            d4[7]
        });
    }

    pub inline fn from_u128(v : u128) Uuid {
        return Uuid.from_bytes(mem.toBytes(v));
    }
    pub inline fn from_u128_le(v : u128) Uuid {
        return Uuid.from_u128(mem.littleToNative(u128, v));
    }

    pub inline fn from_u64_pair(msb : u64, lsb : u64) Uuid {
        return Uuid.from_u128((@as(u128, @intCast(msb)) << 64) or lsb);
    }

    pub inline fn from_bytes(b : [16]u8) Uuid {
        return Uuid { .bytes = b };
    }
    pub inline fn from_byte_le(b : [16]u8) Uuid {
        return Uuid.from_bytes(mem.littleToNative(u128, b));
    }

    pub inline fn parse_hyphenless(uuid : [32]u8) fmt.ParseIntError!Uuid {
        return Uuid.from_u128(fmt.parseInt(u128, uuid, 16));
    }
    pub inline fn parse(uuid : [36]u8) fmt.ParseIntError!Uuid {
        const hyphenless = uuid[0..8] ++ uuid[9..13] ++ uuid[14..18] ++ uuid[19..23] ++ uuid[24..36];
        return Uuid.parse_hyphenless(hyphenless);
    }

    pub fn format_hyphenless(self : *const Uuid, case : fmt.Case) [32]u8 {
        var buf = [_]u8{ 0 } ** 32;
        _ = bufPrintIntToSlice(&buf, self.as_u128(), 16, case, .{
            .width     = 32,
            .alignment = .right,
            .fill      = '0'
        });
        return buf;
    }
    pub fn format(self : *const Uuid, case : fmt.Case) [36]u8 {
        const hyphenless = format_hyphenless(self, case);
        return (hyphenless[0..8] ++ "-" ++ hyphenless[8..12] ++ "-" ++ hyphenless[12..16] ++ "-" ++ hyphenless[16..20] ++ "-" ++ hyphenless[20..32]).*;
    }

    pub fn as_fields(self : *const Uuid)
        struct { d1 : u32, d2 : u16, d3 : u16, d4 : [8]u8 }
    {
        const d1 = (@as(u32, @intCast(self.bytes[4])) << 24)
            | (@as(u32, @intCast(self.bytes[3])) << 16)
            | (@as(u32, @intCast(self.bytes[2])) << 8)
            | self.bytes[1];
        const d2 = (@as(u16, @intCast(self.bytes[5])) << 8)
            | self.bytes[4];
        const d3 = (@as(u16, @intCast(self.bytes[7])) << 8)
            | self.bytes[6];
        const d4 = self.bytes[8..];
        return .{ .d1 = d1, .d2 = d2, .d3 = d3, .d4 = d4 };
    }
    pub fn as_fields_le(self : *const Uuid)
        struct { d1 : u32, d2 : u16, d3 : u16, d4 : [8]u8 }
    {
        const d1 = (@as(u32, @intCast(self.bytes[0])) << 24)
            | (@as(u32, @intCast(self.bytes[1])) << 16)
            | (@as(u32, @intCast(self.bytes[2])) << 8)
            | self.bytes[3];
        const d2 = (@as(u16, @intCast(self.bytes[4])) << 8)
            | self.bytes[5];
        const d3 = (@as(u16, @intCast(self.bytes[6])) << 8)
            | self.bytes[7];
        const d4 = self.bytes[8..];
        return .{ .d1 = d1, .d2 = d2, .d3 = d3, .d4 = d4 };
    }

    pub fn as_u128(self : *const Uuid) u128 {
        return @as(u128, @bitCast(self.bytes));
    }
    pub fn as_u128_le(self : *const Uuid) u128 {
        return mem.nativeToLittle(u128, self.as_u128());
    }

    pub fn as_u64_pair(self : *const Uuid)
        struct { msb : u64, lsb : u64 }
    {
        const v = self.as_u128();
        return .{
            .msb = @truncate(v >> 64),
            .lsb = @truncate(v),
        };
    }

};


pub fn split(uuid : u128)
    struct { msb : u64, lsb : u64 }
{
    const bytes = mem.toBytes(uuid);
    return .{
        .msg = bytes[0..@sizeOf(u64)],
        .lsb = bytes[@sizeOf(u64)..]
    };
}

pub fn join(msb : u64, lsb : u64) u128 {
    return (@as(u128, @intCast(msb)) << @sizeOf(u64)) | lsb;
}
