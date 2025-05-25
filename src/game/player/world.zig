const std           = @import("std");
const meta          = std.meta;
const mem           = std.mem;
const panic         = std.debug.panic;
const Allocator     = std.mem.Allocator;
const ArrayList     = std.ArrayList;
const HashMap       = std.AutoHashMap;
const StringHashMap = std.StringHashMap;

const default_allocator = @import("../../internal/alloc.zig").allocator;
const BlockPos          = @import("../data.zig").BlockPos;
const ChunkPos          = @import("../data.zig").ChunkPos;

const Block    = struct { mat : []const u8, states : StringHashMap([]const u8) };
const BlockMap = HashMap(BlockPos, Block);


extern fn flywheel_world_mark_ready(session_id : u64, x : i32, z : i32) void;


pub const World = struct {
    session_id : u64,

    pub inline fn from_session_id(session_id : u64) World {
        return World { .session_id = session_id };
    }

    pub fn mark_ready(self : *const World, chunk : ChunkPos) void {
        flywheel_world_mark_ready(self.session_id, chunk.x, chunk.z);
    }

    pub fn set(self : *const World, pos : BlockPos, block : anytype) void {
        var b = self.batch_set(default_allocator);
        b.put(pos, block);
        b.submit();
    }

    pub inline fn batch_set(self : *const World, allocator : Allocator) BatchSet {
        return BatchSet {
            .session_id = self.session_id,
            .blocks     = BlockMap.init(allocator),
            .allocator  = allocator
        };
    }

};



extern fn flywheel_world_set_blocks(session_id : u64, in_data : u32) void;

pub const BatchSet = struct {
    session_id : u64,
    blocks     : BlockMap,
    allocator  : Allocator,

    pub fn put(self : *BatchSet, pos : BlockPos, block : anytype) void {
        const mat    : []const u8 = block.mat;
        var   states              = StringHashMap([]const u8).init(self.allocator);

        const block_fields = meta.fields(@TypeOf(block));
        inline for (block_fields) |field| {
            if (! mem.eql(u8, field.name, "mat")) {
                states.put(field.name, @field(block, field.name)) catch panic("out of memory", .{});
            }
        }
        self.blocks.put(pos, .{ .mat = mat, .states = states }) catch panic("out of memory", .{});
    }

    pub fn with(self : BatchSet, pos : BlockPos, block : anytype) BatchSet {
        self.put(pos, block);
        return self;
    }


    pub fn submit(self : BatchSet) void {
        var data   = ArrayList(u8).init(default_allocator);
        defer data.deinit();
        data.appendSlice(&[_]u8{ 0 } ** @sizeOf(u32)) catch panic("out of memory", .{});

        var count  = @as(u32, 0);
        var blocks = self.blocks.iterator();
        while (blocks.next()) |block_entry| {
            const pos   = block_entry.key_ptr;
            const block = block_entry.value_ptr;
            count += 1;
            var buf4 = [_]u8{ 0 } ** @sizeOf(u32);
            var buf8 = [_]u8{ 0 } ** @sizeOf(u64);
            mem.writeInt(i64, &buf8, pos.x, .little);
            data.appendSlice(&buf8) catch panic("out of memory", .{});
            mem.writeInt(i64, &buf8, pos.y, .little);
            data.appendSlice(&buf8) catch panic("out of memory", .{});
            mem.writeInt(i64, &buf8, pos.z, .little);
            data.appendSlice(&buf8) catch panic("out of memory", .{});
            mem.writeInt(u32, &buf4, block.mat.len, .little);
            data.appendSlice(&buf4) catch panic("out of memory", .{});
            data.appendSlice(block.mat) catch panic("out of memory", .{});
            data.append(mem.nativeToLittle(u8, @intCast(block.states.count()))) catch panic("out of memory", .{});
            var states = block.states.iterator();
            while (states.next()) |state_entry| {
                const state = state_entry.key_ptr.*;
                const value = state_entry.value_ptr.*;
                mem.writeInt(u32, &buf4, state.len, .little);
                data.appendSlice(&buf4) catch panic("out of memory", .{});
                data.appendSlice(state) catch panic("out of memory", .{});
                mem.writeInt(u32, &buf4, value.len, .little);
                data.appendSlice(&buf4) catch panic("out of memory", .{});
                data.appendSlice(value) catch panic("out of memory", .{});
            }
        }

        if (count == 0) { return; }
        mem.writeInt(u32, data.items[0..@sizeOf(u32)], count, .little);
        flywheel_world_set_blocks(self.session_id, @intFromPtr(data.items.ptr));

        self.deinit();
    }


    pub fn deinit(self : BatchSet) void {
        var iter = self.blocks.iterator();
        while (iter.next()) |entry| {
            entry.value_ptr.states.deinit();
        }

        var blocks = self.blocks;
        blocks.deinit();
    }

};
