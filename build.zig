const std = @import("std");

pub fn build(b: *std.build.Builder) !void {
    const mode = b.standardReleaseOptions();
    const target = b.standardTargetOptions(.{});

    const d = try std.fs.cwd().openIterableDir(".", .{});
    var i = d.iterate();
    while (try i.next()) |entry| {
        if (entry.kind != .Directory) continue;
        if (!std.mem.startsWith(u8, entry.name, "day")) continue;

        const impl_name = try std.mem.concat(b.allocator, u8, &.{ entry.name, ".zig" });
        const impl_path = try std.fs.path.join(b.allocator, &.{ entry.name, impl_name });

        const impl = b.addTest(impl_path);
        impl.setBuildMode(mode);
        impl.setTarget(target);

        b.step(entry.name, "Run the specified day").dependOn(&impl.step);
    }
}
