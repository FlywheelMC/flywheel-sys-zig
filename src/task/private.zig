const std       = @import("std");
const mem       = std.mem;
const Alignment = mem.Alignment;
const ArrayList = std.ArrayList;
const Mutex     = std.Thread.Mutex;
const panic     = std.debug.panic;

const allocator = @import("../internal/alloc.zig").allocator;
const Instant   = @import("../time.zig").Instant;


const QueuedTask = struct {
    at         : Instant,
    args_bytes : []u8,
    call       : *const fn([]u8) void
};
const QueuedTasks = ArrayList(QueuedTask);

var QUEUED_TASKS : [@sizeOf(QueuedTasks)]u8 align(@alignOf(QueuedTasks)) = undefined;
var RUNNING_LOCK = Mutex{};
var TASK_LOCK    = Mutex{};


pub fn init() void {
    if (! RUNNING_LOCK.tryLock()) {
        panic("flywheel application already running", .{});
    }
    TASK_LOCK.lock();
    QUEUED_TASKS = mem.toBytes(QueuedTasks.init(allocator));
    TASK_LOCK.unlock();
}

pub fn deinit() void {
    TASK_LOCK.lock();
    const queued_tasks = @as(*QueuedTasks, @ptrCast(&QUEUED_TASKS));
    for (queued_tasks.items) |task| {
        allocator.free(task.args_bytes);
    }
    queued_tasks.*.deinit();
    TASK_LOCK.unlock();
    RUNNING_LOCK.unlock();
}


pub fn schedule_at(at : Instant, function : anytype, args : anytype) void {
    const A = @TypeOf(args);
    const args1 = allocator.create(A) catch panic("out of memory", .{});
    args1.* = args;

    TASK_LOCK.lock();
    const queued_tasks = @as(*QueuedTasks, @ptrCast(&QUEUED_TASKS));
    queued_tasks.append(QueuedTask {
        .at         = at,
        .args_bytes = @as([*]u8, @ptrCast(args1))[0..@sizeOf(A)],
        .call       = struct { fn call(args2 : []u8) void {
            const args3 = @as(*A, @ptrCast(args2.ptr));
            @call(.auto, function, args3.*);
        } }.call
    }) catch panic("out of memory", .{});
    TASK_LOCK.unlock();
}


pub fn run_queued_tasks() void {
    const queued_tasks = @as(*QueuedTasks, @ptrCast(&QUEUED_TASKS));
    const now = Instant.now();
    var i = @as(usize, 0);
    while (i < queued_tasks.items.len) {
        if (now.gte(queued_tasks.items[i].at)) {
            const task = queued_tasks.swapRemove(i);
            _ = task.args_bytes.len;
            task.call(task.args_bytes);
            allocator.free(task.args_bytes);
        } else {
            i += 1;
        }
    }
}
