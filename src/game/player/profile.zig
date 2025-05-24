const std       = @import("std");
const ArrayList = std.ArrayList;


pub const PlayerProfile = struct {
    uuid : u128,
    name : ArrayList(u8),

    pub fn free(self : PlayerProfile) void {
        self.name.deinit();
    }
};
