const sin = @import("std").math.sin;

const flywheel_sys = @import("flywheel-sys");
const allocator = flywheel_sys.allocator;
const App       = flywheel_sys.App;
const Player    = flywheel_sys.game.Player;
const BlockPos  = flywheel_sys.game.data.BlockPos;
const ChunkPos  = flywheel_sys.game.data.ChunkPos;
const info      = flywheel_sys.log.info;
const pass      = flywheel_sys.log.pass;


export fn flywheel_main() void {
    var app = App.new();
    app
        .on_player_joined(player_joined)
        .on_world_chunk_loading(load_chunk)
        .run();
}


fn player_joined(player : Player) void {
    const maybe_profile = player.fetch_profile();
    if (maybe_profile != null) {
        const profile = maybe_profile.?;
        defer profile.free();

        player.send_title(
            "<orange><b><u>Sine World</></></>", .{},
            "<yellow>Welcome, {s}!</>", .{ profile.name.items },
            0, 2500, 1000
        );
    }
}


const SINE_FREQ : f32 = 0.0625;
const SIME_AMP  : f32 = 5.0;
fn load_chunk(player : Player, chunk : ChunkPos) void {
    var batch = player.world.batch_set(allocator);
    const min = chunk.min_block();
    for (0..16) |dx| {
        for (0..16) |dz| {
            const x  = min.x + dx;
            const z  = min.z + dz;
            const hx = @as(f32, @floatFromInt(x)) * SINE_FREQ;
            const hz = @as(f32, @floatFromInt(z)) * SINE_FREQ;
            const h  = @as(usize, @intFromFloat((sin(hx) * sin(hz) + 1.0) * SIME_AMP));
            const mat = if ((dx == 0) or (dz == 0) or (dx == 15) or (dz == 15))
                "minecraft:black_concrete" else "minecraft:white_concrete";
            for (0..(h + 1)) |y| {
                batch.put(BlockPos.new(x, y, z), .{ .mat = mat });
            }
        }
    }
    batch.submit();
    player.world.mark_ready(chunk);
}
