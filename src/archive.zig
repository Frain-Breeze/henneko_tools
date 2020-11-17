const std = @import("std");

const ENTRY_SIZE = 0x10;

pub const ArchInfo = struct {
    size: u64,
    entryCount: u32,
    entries: std.ArrayList(ArchEntry),
};

pub const ArchEntry = struct {
    name: []u8,
    offset: u64,
    size: u32,
    nameOffset: u32,
};

pub fn readArch(_fin: []const u8, _mode32: bool, _arch: *ArchInfo) !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    var allocator = &arena.allocator;
    std.debug.print("extracting file {}\n", .{_fin});
    const hdr = try allocator.alloc(u8, 0x10);
    var fin = try std.fs.cwd().openFile(_fin, .{ .read = true });
    _ = try fin.read(hdr);
    defer fin.close();

    var arch: ArchInfo = undefined;

    var sig = std.mem.bytesToValue(u32, hdr[0..4]);
    if (sig != 0x41445047) { //"GPDA"
        std.debug.print("signature isn't what we expected!\n", .{});
        return;
    }

    if (_mode32) {
        arch.size = std.mem.bytesToValue(u32, hdr[4..8]);
    } else {
        arch.size = std.mem.bytesToValue(u64, hdr[4..12]);
    }
    std.debug.print("signature: 0x{x}\n", .{sig});
    arch.entryCount = std.mem.bytesToValue(u32, hdr[12..16]);
    std.debug.print("entryCount: {}\n", .{arch.entryCount});

    const entryInf = try allocator.alloc(u8, ENTRY_SIZE * arch.entryCount);
    _ = try fin.read(entryInf);
    var i: u32 = 0;
    while (i < arch.entryCount) : (i += 1) {
        var offset: u32 = i * ENTRY_SIZE;
        //const cEnt = try allocator.create(ArchEntry);
        var cEnt: ArchEntry = undefined;

        if (_mode32) {
            cEnt.offset = std.mem.bytesToValue(u32, entryInf[offset..][0..4]);
        } else {
            cEnt.offset = std.mem.bytesToValue(u64, entryInf[offset..][0..8]);
        }

        cEnt.size = std.mem.bytesToValue(u32, entryInf[offset..][8..12]);
        cEnt.nameOffset = std.mem.bytesToValue(u32, entryInf[offset..][12..16]);

        try fin.seekTo(cEnt.nameOffset);
        std.debug.print("offset: {}\n", .{cEnt.offset});

        var finr = fin.reader();
        var nameLen: u32 = try finr.readIntNative(u32);
        std.debug.print("nameLen: {}\n", .{nameLen});
        cEnt.name = try allocator.alloc(u8, nameLen);
        _ = try fin.read(cEnt.name);

        _ = try _arch.entries.append(cEnt);
        std.debug.print("name: {}\n", .{cEnt.name});

        std.debug.print("\n", .{});
    }
}
