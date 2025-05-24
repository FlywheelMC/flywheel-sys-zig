const Build = @import("std").Build;

pub fn build(b : *Build) void {

    const target   = b.resolveTargetQuery(.{ .cpu_arch = .wasm32, .os_tag = .freestanding });
    const optimize = .ReleaseSmall;

    const flywheel_sys = b.addModule("flywheel-sys", .{
        .root_source_file = b.path("../../src/lib.zig"),
        .target           = target,
        .optimize         = optimize
    });

    const exe = b.addExecutable(.{
        .name = "big_clock",
        .root_source_file = b.path("src/lib.zig"),
        .target   = target,
        .optimize = optimize
    });
    exe.root_module.addImport("flywheel-sys", flywheel_sys);
    exe.entry    = .disabled;
    exe.rdynamic = true;
    b.installArtifact(exe);
}
