const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // const advent = b.addModule("advent", .{
    //     .source_file = .{ .path = "advent.zig" },
    // });

    const d = try std.fs.cwd().openIterableDir(".", .{});
    var i = d.iterate();
    while (try i.next()) |entry| {
        if (entry.kind != .directory) continue;
        if (!std.mem.startsWith(u8, entry.name, "day")) continue;

        const impl_name = try std.mem.concat(b.allocator, u8, &.{ entry.name, ".zig" });
        const impl_path = b.pathJoin(&.{ entry.name, impl_name });

        const impl = b.addExecutable(.{
            .name = entry.name,
            .root_source_file = .{ .path = impl_path },
            .target = target,
            .optimize = optimize,
        });
        // impl.addModule("advent", advent);
        const impl_run = b.addRunArtifact(impl);

        b.step(entry.name, "Run the day's solution").dependOn(&impl_run.step);
    }
}
