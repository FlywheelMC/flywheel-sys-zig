const std       = @import("std");
const mem       = std.mem;
const ArrayList = std.ArrayList;
const panic     = std.debug.panic;

const allocator = @import("alloc.zig").allocator;
const Player    = @import("../game/player/mod.zig").Player;
const ChunkPos  = @import("../game/data.zig").ChunkPos;


extern fn flywheel_refuel() void;
extern fn flywheel_next_event(out_id_ptr : u32, out_id_len : u32, out_args_ptr : u32, out_args_len : u32) u32;


const OnStart              = *const fn() void;
const OnPlayerJoined       = *const fn(Player,) void;
const OnPlayerLeft         = *const fn(Player,) void;
const OnWorldChunkLoading  = *const fn(Player, ChunkPos,) void;
const OnWorldChunkUnloaded = *const fn(Player, ChunkPos,) void;

pub const App = struct {
    callback_on_start                : ArrayList(OnStart),
    callback_on_player_joined        : ArrayList(OnPlayerJoined),
    callback_on_player_left          : ArrayList(OnPlayerLeft),
    callback_on_world_chunk_loading  : ArrayList(OnWorldChunkLoading),
    callback_on_world_chunk_unloaded : ArrayList(OnWorldChunkUnloaded),

    pub fn new() App {
        return App {
            .callback_on_start                = ArrayList(OnStart).init(allocator),
            .callback_on_player_joined        = ArrayList(OnPlayerJoined).init(allocator),
            .callback_on_player_left          = ArrayList(OnPlayerLeft).init(allocator),
            .callback_on_world_chunk_loading  = ArrayList(OnWorldChunkLoading).init(allocator),
            .callback_on_world_chunk_unloaded = ArrayList(OnWorldChunkUnloaded).init(allocator)
        };
    }


    pub fn on_start(self : *App, callback : OnStart) *App {
        self.callback_on_start.append(callback) catch panic("out of memory", .{});
        return self;
    }

    pub fn on_player_joined(self : *App, callback : OnPlayerJoined) *App {
        self.callback_on_player_joined.append(callback) catch panic("out of memory", .{});
        return self;
    }
    pub fn on_player_left(self : *App, callback : OnPlayerLeft) *App {
        self.callback_on_player_left.append(callback) catch panic("out of memory", .{});
        return self;
    }

    pub fn on_world_chunk_loading(self : *App, callback : OnWorldChunkLoading) *App {
        self.callback_on_world_chunk_loading.append(callback) catch panic("out of memory", .{});
        return self;
    }
    pub fn on_world_chunk_unloaded(self : *App, callback : OnWorldChunkUnloaded) *App {
        self.callback_on_world_chunk_unloaded.append(callback) catch panic("out of memory", .{});
        return self;
    }


    pub fn run(self : *App) void {
        for (self.callback_on_start.items) |f| { f(); }
        while (true) {
            const maybe_event = App.read_event();
            if (maybe_event != null) {
                const event = maybe_event.?;

                if (mem.eql(u8, event.id, "flywheel_player_joined")) {
                    const session_id = mem.readInt(u64, event.args[0..8], .little);
                    const player     = Player.from_session_id(session_id);
                    for (self.callback_on_player_joined.items) |f| { f(player); }
                }
                else if (mem.eql(u8, event.id, "flywheel_player_left")) {
                    const session_id = mem.readInt(u64, event.args[0..8], .little);
                    const player     = Player.from_session_id(session_id);
                    for (self.callback_on_player_left.items) |f| { f(player); }
                }

                else if (mem.eql(u8, event.id, "flywheel_world_chunk_loading")) {
                    const session_id = mem.readInt(u64, event.args[0..8], .little);
                    const player     = Player.from_session_id(session_id);
                    const x          = mem.readInt(i32, event.args[8..12], .little);
                    const z          = mem.readInt(i32, event.args[12..16], .little);
                    const pos        = ChunkPos.new(x, z);
                    for (self.callback_on_world_chunk_loading.items) |f| { f(player, pos); }
                }
                else if (mem.eql(u8, event.id, "flywheel_world_chunk_unloaded")) {
                    const session_id = mem.readInt(u64, event.args[0..8], .little);
                    const player     = Player.from_session_id(session_id);
                    const x          = mem.readInt(i32, event.args[8..12], .little);
                    const z          = mem.readInt(i32, event.args[12..16], .little);
                    const pos        = ChunkPos.new(x, z);
                    for (self.callback_on_world_chunk_unloaded.items) |f| { f(player, pos); }
                }

                allocator.free(event.id);
                allocator.free(event.args);
            }
        }
    }

    fn read_event()
        ?struct { id : []u8, args : []u8 }
    {
        var id_ptr   = @as(u32, 0);
        var id_len   = @as(u32, 0);
        var args_ptr = @as(u32, 0);
        var args_len = @as(u32, 0);
        if (flywheel_next_event(
            @intFromPtr(&id_ptr),
            @intFromPtr(&id_len),
            @intFromPtr(&args_ptr),
            @intFromPtr(&args_len)
        ) == 0) {
            return null;
        } else {
            const id   = @as([*]u8, @ptrFromInt(id_ptr))[0..id_len];
            const args = @as([*]u8, @ptrFromInt(args_ptr))[0..args_len];
            return .{ .id = id, .args = args };
        }
    }

};
