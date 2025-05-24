pub const ChunkPos = struct {
    x : i32,
    z : i32,

    pub const ZERO = ChunkPos { .x = 0, .z = 0 };

    pub inline fn new(x : i32, z : i32) ChunkPos {
        return ChunkPos { .x = x, .z = z };
    }

    pub inline fn splat(v : i32) ChunkPos {
        return ChunkPos.new(v, v);
    }

    pub inline fn south(self : *const ChunkPos, offset : i32) ChunkPos {
        return ChunkPos.new(self.x, self.z + offset);
    }

    pub inline fn north(self : *const ChunkPos, offset : i32) ChunkPos {
        return ChunkPos.new(self.x, self.z - offset);
    }

    pub inline fn east(self : *const ChunkPos, offset : i32) ChunkPos {
        return ChunkPos.new(self.x + offset, self.z);
    }

    pub inline fn west(self : *const ChunkPos, offset : i32) ChunkPos {
        return ChunkPos.new(self.x - offset, self.z);
    }

    pub inline fn min_block(self : *const ChunkPos) BlockPos {
        return BlockPos.new(
            self.x * 16,
            0,
            self.z * 16
        );
    }

};


pub const BlockPos = struct {
    x : i64,
    y : i64,
    z : i64,

    pub const ZERO = BlockPos { .x = 0, .y = 0, .z = 0 };

    pub inline fn new(x : i64, y : i64, z : i64) BlockPos {
        return BlockPos { .x = x, .y = y, .z = z };
    }

    pub inline fn splat(v : i32) BlockPos {
        return BlockPos.new(v, v, v);
    }

    pub inline fn south(self : *const BlockPos, offset : i32) BlockPos {
        return BlockPos.new(self.x, self.y, self.z + offset);
    }

    pub inline fn north(self : *const BlockPos, offset : i32) BlockPos {
        return BlockPos.new(self.x, self.y, self.z - offset);
    }

    pub inline fn up(self : *const BlockPos, offset : i32) BlockPos {
        return BlockPos.new(self.x, self.y + offset, self.z);
    }

    pub inline fn down(self : *const BlockPos, offset : i32) BlockPos {
        return BlockPos.new(self.x, self.y - offset, self.z);
    }

    pub inline fn east(self : *const BlockPos, offset : i32) BlockPos {
        return BlockPos.new(self.x + offset, self.y, self.z);
    }

    pub inline fn west(self : *const BlockPos, offset : i32) BlockPos {
        return BlockPos.new(self.x - offset, self.y, self.z);
    }

    pub inline fn chunk(self : *const BlockPos) ChunkPos {
        return ChunkPos.new(
            self.x / 16,
            self.z / 16
        );
    }

};


pub const SoundCategory = enum(u32) {
    master  = 0,
    music   = 1,
    records = 2,
    weather = 3,
    blocks  = 4,
    hostile = 5,
    neutral = 6,
    players = 7,
    ambient = 8,
    voice   = 9
};
