const sin = @import("std").math.sin;

const flywheel_sys = @import("flywheel-sys");
const App       = flywheel_sys.App;
const task      = flywheel_sys.task;
const Instant   = flywheel_sys.time.Instant;
const Duration  = flywheel_sys.time.Duration;
const pass      = flywheel_sys.log.pass;


const CHARS = "0123456789:";


export fn flywheel_main() void {
    var app = App.new();
    app
        .on_start(plot_started)
        .run();
}


fn plot_started() void {
    update_clock(Instant.now());
}

fn update_clock(at : Instant) void {
    pass(@src(), "Beep", .{});

    const next_at = at.add(Duration.SECOND);
    task.schedule_at(next_at, update_clock, .{ next_at });
}
