const std       = @import("std");
const ArrayList = std.ArrayList;

const Uuid = @import("../../uuid.zig").Uuid;


pub const PlayerProfile = struct {
    uuid : Uuid,
    name : ArrayList(u8),

    pub fn free(self : PlayerProfile) void {
        self.name.deinit();
    }
};
