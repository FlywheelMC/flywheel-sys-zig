const std = @import("std");
const ArrayList  = std.ArrayList;
const Allocator  = std.mem.Allocator;
const allocPrint = std.fmt.allocPrint;
const panic      = std.debug.panic;

const allocator     = @import("../../internal/alloc.zig").allocator;
const Duration      = @import("../../time.zig").Duration;
const SoundCategory = @import("../data.zig").SoundCategory;


const profile = @import("profile.zig");
pub const PlayerProfile = profile.PlayerProfile;

const world = @import("world.zig");
pub const World = world.World;


extern fn flywheel_player_exists(session_id : u64) u32;
extern fn flywheel_profile_from_session(
    session_id   : u64,
    out_uuid     : u32,
    out_name_ptr : u32,
    out_name_len : u32
) u32;

extern fn flywheel_player_send_chat(session_id : u64, in_msg : u32, msg_len : u32) void;
extern fn flywheel_player_send_actionbar(session_id : u64, in_msg : u32, msg_len : u32) void;
extern fn flywheel_player_send_title(
    session_id   : u64,
    in_title     : u32,
    title_len    : u32,
    in_subtitle  : u32,
    subtitle_len : u32,
    fade_in      : u32,
    stay         : u32,
    fade_out     : u32
) void;
extern fn flywheel_player_send_sound(
    session_id : u64,
    in_id      : u32,
    id_len     : u32,
    category   : u32,
    volume     : f32,
    pitch      : f32,
    seed       : u64
) void;


pub const Player = struct {
    session_id : u64,
    world      : World,

    pub inline fn from_session_id(session_id : u64) Player {
        return Player {
            .session_id = session_id,
            .world      = World.from_session_id(session_id)
        };
    }

    pub fn exists(self : *const Player) bool {
        return flywheel_player_exists(self.session_id);
    }

    pub fn fetch_profile(self : *const Player) ?PlayerProfile {
        var name_ptr = @as(u32, 0);
        var name_len = @as(u32, 0);
        var uuid     = @as(u128, 0);
        if (flywheel_profile_from_session(
            self.session_id,
            @intFromPtr(&uuid),
            @intFromPtr(&name_ptr),
            @intFromPtr(&name_len)
        ) == 0) {
            return null;
        } else {
            const name_slice = @as([*]u8, @ptrFromInt(name_ptr))[0..name_len];
            const name       = ArrayList(u8).fromOwnedSlice(allocator, name_slice);
            return PlayerProfile {
                .uuid = uuid,
                .name = name
            };
        }
    }


    pub fn send_chat(self : *const Player, comptime fmt : []const u8, args : anytype) void {
        const msg = allocPrint(allocator, fmt, args) catch panic("out of memory", .{});
        flywheel_player_send_chat(self.session_id, @intFromPtr(msg.ptr), msg.len);
        allocator.free(msg);
    }

    pub fn send_actionbar(self : *const Player, comptime fmt : []const u8, args : anytype) void {
        const msg = allocPrint(allocator, fmt, args) catch panic("out of memory", .{});
        flywheel_player_send_actionbar(self.session_id, @intFromPtr(msg.ptr), msg.len);
        allocator.free(msg);
    }

    pub fn send_title(self : *const Player,
        comptime title_fmt : []const u8,
        title_args    : anytype,
        comptime subtitle_fmt : []const u8,
        subtitle_args : anytype,
        fade_in_ms    : Duration,
        stay_ms       : Duration,
        fade_out_ms   : Duration
    ) void {
        const title    = allocPrint(allocator, title_fmt,    title_args    ) catch panic("out of memory", .{});
        const subtitle = allocPrint(allocator, subtitle_fmt, subtitle_args ) catch panic("out of memory", .{});
        flywheel_player_send_title(
            self.session_id,
            @intFromPtr(title.ptr), title.len,
            @intFromPtr(subtitle.ptr), subtitle.len,
            @intCast(fade_in_ms.as_ticks() / 50),
            @intCast(stay_ms.as_ticks() / 50),
            @intCast(fade_out_ms.as_ticks() / 50)
        );
        allocator.free(title);
        allocator.free(subtitle);
    }

    pub fn send_sound(self : *const Player,
        id       : []u8,
        category : SoundCategory,
        volume   : f32,
        pitch    : f32,
        seed     : u64
    ) void {
        flywheel_player_send_sound(
            self.session_id,
            @intFromPtr(id.ptr), id.len,
            category,
            volume, pitch, seed
        );
    }

};
