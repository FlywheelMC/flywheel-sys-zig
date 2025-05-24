const Build = @import("std").Build;

pub fn build(b : *Build) void {
    const mode = b.standardReleaseOptions();
    const lib  = b.addSharedLibrary("flywheel-sys", "src/lib.zig", b.version(0, 1, 0));
    lib.setBuildMode(mode);
}
