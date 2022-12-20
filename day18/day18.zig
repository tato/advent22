const std = @import("std");

fn solve(input: []const u8) !void {
    const cubes = try parseCubes(input);

    var exposed_sides: u64 = 0;
    for (cubes) |cube| {
        var cube_exposed_sides: u64 = 6;
        for (cubes) |comparison_cube| {
            const distance_x = try std.math.absInt(cube[0] - comparison_cube[0]);
            const distance_y = try std.math.absInt(cube[1] - comparison_cube[1]);
            const distance_z = try std.math.absInt(cube[2] - comparison_cube[2]);
            if (distance_x + distance_y + distance_z == 1) {
                cube_exposed_sides -= 1;
            }
        }
        exposed_sides += cube_exposed_sides;
    }

    std.debug.print("Exposed Sides: {d}\n", .{exposed_sides});
}

const CubeElem = i16;
const Cube = [3]CubeElem;

fn parseCubes(input: []const u8) ![]const Cube {
    var cubes = std.ArrayList(Cube).init(gpa.allocator());

    var i = std.mem.tokenize(u8, input, "\n ");
    while (i.next()) |cube_line| {
        var coordinate_i = std.mem.split(u8, cube_line, ",");
        try cubes.append(.{
            try std.fmt.parseInt(CubeElem, coordinate_i.next().?, 10),
            try std.fmt.parseInt(CubeElem, coordinate_i.next().?, 10),
            try std.fmt.parseInt(CubeElem, coordinate_i.next().?, 10),
        });
    }

    return try cubes.toOwnedSlice();
}

var gpa = std.heap.GeneralPurposeAllocator(.{}){};

test "solve" {
    try solve(@embedFile("input.txt"));
}
