const std = @import("std");
const archLib = @import("archive.zig");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    var arch: *archLib.ArchInfo = try allocator.create(archLib.ArchInfo);
    _ = try arch.entries.init(allocator);
    try archLib.readArch("RES.DAT", true, arch);
    for (arch.entries.items) |ent, i| {
        std.debug.print("entry {}'s name: {}", .{ i, ent.name });
    }
}
