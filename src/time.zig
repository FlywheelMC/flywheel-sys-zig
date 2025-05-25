const std    = @import("std");
const mem    = std.mem;
const maxInt = std.math.maxInt;
const panic  = std.debug.panic;


extern fn flywheel_system_dur_since_epoch( out_secs : u32, out_nanos : u32 ) void;


const NANOS_PER_SEC   = @as(u32, 1_000_000_000);
const NANOS_PER_MILLI = @as(u32, 1_000_000);
const NANOS_PER_MICRO = @as(u32, 1_000);
const MILLIS_PER_SEC  = @as(u64, 1_000);
const MICROS_PER_SEC  = @as(u64, 1_000_000);

pub const Duration = struct {
    private : [@sizeOf(u64) + @sizeOf(u32)]u8,

    pub const ZERO        = Duration.from_nanos(0);
    pub const SECOND      = Duration.from_secs(1);
    pub const MILLISECOND = Duration.from_millis(1);
    pub const MICROSECOND = Duration.from_micros(1);
    pub const NANOSECOND  = Duration.from_nanos(1);
    pub const TICK        = Duration.from_ticks(1);
    pub const MAX         = Duration.new(maxInt(u64), NANOS_PER_SEC - 1);

    pub fn new(secs : u64, nanos : u32) Duration {
        if (nanos < NANOS_PER_SEC) {
            return Duration.new_unchecked(secs, nanos);
        } else {
            const real_secs  = secs + (nanos / NANOS_PER_SEC);
            const real_nanos = nanos % NANOS_PER_SEC;
            return Duration.new_unchecked(real_secs, real_nanos);
        }
    }
    inline fn new_unchecked(secs : u64, nanos : u32) Duration {
        var data = [_]u8{ 0 } ** (@sizeOf(u64) + @sizeOf(u32));
        mem.writeInt(u64, data[0..@sizeOf(u64)], secs, .little);
        mem.writeInt(u32, data[@sizeOf(u64)..], nanos, .little);
        return Duration { .private = data };
    }

    pub inline fn from_secs(secs : u64) Duration {
        return Duration.new(secs, 0);
    }
    pub inline fn from_millis(millis : u64) Duration {
        const secs        = millis / MILLIS_PER_SEC;
        const real_millis = millis % MILLIS_PER_SEC;
        const real_nanos  = real_millis * NANOS_PER_MILLI;
        return Duration.new(secs, real_nanos);
    }
    pub inline fn from_micros(micros : u64) Duration {
        const secs        = micros / MICROS_PER_SEC;
        const real_micros = micros % MICROS_PER_SEC;
        const real_nanos  = real_micros * NANOS_PER_MICRO;
        return Duration.new(secs, real_nanos);
    }
    pub inline fn from_nanos(nanos : u64) Duration {
        const secs       = nanos / NANOS_PER_SEC;
        const real_nanos = nanos % NANOS_PER_SEC;
        return Duration.new(secs, real_nanos);
    }
    pub inline fn from_ticks(ticks : u64) Duration {
        return Duration.from_millis(ticks * 50);
    }

    pub inline fn is_zero(self : *const Duration) bool {
        return (self.as_secs() == 0) and (self.subsec_nanos() == 0);
    }
    pub inline fn as_secs(self : *const Duration) u64 {
        return mem.readInt(u64, self.private[0..@sizeOf(u64)], .little);
    }
    pub inline fn subsec_millis(self : *const Duration) u32 {
        return self.subsec_nanos() / NANOS_PER_MILLI;
    }
    pub inline fn subsec_micros(self : *const Duration) u32 {
        return self.subsec_nanos() / NANOS_PER_MICRO;
    }
    pub inline fn subsec_nanos(self : *const Duration) u32 {
        return mem.readInt(u32, self.private[@sizeOf(u64)..], .little);
    }
    pub inline fn as_millis(self : *const Duration) u128 {
        const secs  = @as(u128, @intCast(self.as_secs())) * MILLIS_PER_SEC;
        const nanos = self.subsec_nanos() / NANOS_PER_MILLI;
        return secs + nanos;
    }
    pub inline fn as_micros(self : *const Duration) u128 {
        const secs  = @as(u128, @intCast(self.as_secs())) * MICROS_PER_SEC;
        const nanos = self.subsec_nanos() / NANOS_PER_MICRO;
        return secs + nanos;
    }
    pub inline fn as_nanos(self : *const Duration) u128 {
        const secs = @as(u128, @intCast(self.as_secs())) * NANOS_PER_SEC;
        return secs + self.subsec_nanos();
    }
    pub inline fn as_ticks(self : *const Duration) u128 {
        return self.as_millis() / 50;
    }

    pub inline fn abs_diff(self : *const Duration, other : Duration) Duration {
        return self.checked_sub(other) orelse other.checked_sub(self) orelse unreachable;
    }

    pub inline fn add(self : *const Duration, other : Duration) Duration {
        return Duration.new(self.as_secs() + other.as_secs(), self.subsec_nanos() + other.subsec_nanos());
    }
    pub inline fn sub(self : *const Duration, other : Duration) Duration {
        return Duration.new(self.as_secs() - other.as_secs(), self.subsec_nanos() - other.subsec_nanos());
    }
    pub fn gt(self : *const Duration, other : Duration) bool {
        const self_secs = self.as_secs();
        const other_secs = other.as_secs();
        if (self_secs > other_secs) { return true; }
        if (self_secs < other_secs) { return false; }
        const self_nanos = self.subsec_nanos();
        const other_nanos = other.subsec_nanos();
        return self_nanos > other_nanos;
    }
    pub fn gte(self : *const Duration, other : Duration) bool {
        const self_secs = self.as_secs();
        const other_secs = other.as_secs();
        if (self_secs > other_secs) { return true; }
        if (self_secs < other_secs) { return false; }
        const self_nanos = self.subsec_nanos();
        const other_nanos = other.subsec_nanos();
        return self_nanos >= other_nanos;
    }
    pub fn lt(self : *const Duration, other : Duration) bool {
        const self_secs = self.as_secs();
        const other_secs = other.as_secs();
        if (self_secs < other_secs) { return true; }
        if (self_secs > other_secs) { return false; }
        const self_nanos = self.subsec_nanos();
        const other_nanos = other.subsec_nanos();
        return self_nanos < other_nanos;
    }
    pub fn lte(self : *const Duration, other : Duration) bool {
        const self_secs = self.as_secs();
        const other_secs = other.as_secs();
        if (self_secs < other_secs) { return true; }
        if (self_secs > other_secs) { return false; }
        const self_nanos = self.subsec_nanos();
        const other_nanos = other.subsec_nanos();
        return self_nanos <= other_nanos;
    }

};


pub const Instant = struct {
    after_epoch : Duration,

    pub const UNIX_EPOCH = Instant {
        .after_epoch = Duration.ZERO
    };

    pub fn now() Instant {
        var secs  = @as(u64, 0);
        var nanos = @as(u32, 0);
        flywheel_system_dur_since_epoch(
            @intFromPtr(&secs),
            @intFromPtr(&nanos)
        );
        return Instant {
            .after_epoch = Duration.new(secs, nanos)
        };
    }

    pub inline fn elapsed(self : *Instant) Duration {
        return Instant.now().duration_since(self);
    }

    pub fn add(self : *const Instant, dur : Duration) Instant {
        return Instant { .after_epoch = self.after_epoch.add(dur) };
    }
    pub fn sub(self : *const Instant, dur : Duration) Instant {
        return Instant { .after_epoch = self.after_epoch.sub(dur) };
    }
    pub fn duration_since(self : *const Instant, earlier : Instant) Duration {
        return self.after_epoch.sub(earlier.after_epoch);
    }

    pub inline fn gt(self : *const Instant, other : Instant) bool {
        return self.after_epoch.gt(other.after_epoch);
    }
    pub inline fn gte(self : *const Instant, other : Instant) bool {
        return self.after_epoch.gte(other.after_epoch);
    }
    pub inline fn lt(self : *const Instant, other : Instant) bool {
        return self.after_epoch.lt(other.after_epoch);
    }
    pub inline fn lte(self : *const Instant, other : Instant) bool {
        return self.after_epoch.lte(other.after_epoch);
    }

};
