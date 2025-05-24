const flywheel_sys = @import("flywheel-sys");
const App    = flywheel_sys.App;
const Player = flywheel_sys.game.Player;
const info   = flywheel_sys.log.info;
const pass   = flywheel_sys.log.pass;


export fn flywheel_main() void {
    var app = App.new();
    app
        .on_start(plot_started)
        .on_player_joined(player_joined)
        .run();
}


fn plot_started() void {
    pass(@src(), "WASM is running!", .{});
}


fn player_joined(player : Player) void {
    info(@src(), "WASM detected session {} joined", .{ player.session_id });
    const maybe_profile = player.fetch_profile();
    if (maybe_profile != null) {
        const profile = maybe_profile.?;
        defer profile.free();

        player.send_chat(
            "<green>Hello, {s}!</green>\n <yellow>Your UUID is {}.",
            .{
                profile.name.items,
                profile.uuid
            }
        );
    }
}
