const std = @import("std");

fn solve(input: []const u8) !void {
    const cave = try gpa.allocator().create(Cave);
    for (cave) |*m| m.* = .air;
    try initCave(cave, input, false);

    const abyss_sand = fillCave(cave);

    for (cave) |*m| m.* = .air;
    try initCave(cave, input, true);

    const floor_sand = fillCave(cave);

    std.debug.print("Abyss Sand: {d}, Floor Sand: {d}\n", .{ abyss_sand, floor_sand });
}

const sand_source = [2]u32{ 500, 0 };
const cave_width: usize = 1_000;
const cave_height: usize = 200;
const Material = enum { air, rock, sand };
const Cave = [cave_width * cave_height]Material;

fn get(cave: *Cave, point: [2]u32) *Material {
    return &cave[point[1] * cave_width + point[0]];
}

fn initCave(cave: *Cave, input: []const u8, with_floor: bool) !void {
    var hightest_y: u32 = 0;
    var rock_path = std.ArrayList([2]u32).init(gpa.allocator());
    var i = std.mem.tokenize(u8, input, "\n");
    while (i.next()) |rock_path_line| {
        var ii = std.mem.tokenize(u8, rock_path_line, " ->");
        while (ii.next()) |point_string| {
            var point_split = std.mem.split(u8, point_string, ",");
            const a = try std.fmt.parseInt(u32, point_split.first(), 10);
            const b = try std.fmt.parseInt(u32, point_split.rest(), 10);
            try rock_path.append(.{ a, b });
        }

        for (rock_path.items[1..]) |end, index| {
            const start = rock_path.items[index];
            const line_axis: u32 = if (start[0] != end[0]) 0 else if (start[1] != end[1]) 1 else unreachable;
            const const_axis = (line_axis + 1) % 2;
            var coord: u32 = @min(start[line_axis], end[line_axis]);
            while (coord <= @max(start[line_axis], end[line_axis])) : (coord += 1) {
                var p = [2]u32{ 0, 0 };
                p[line_axis] = coord;
                p[const_axis] = start[const_axis];
                get(cave, p).* = .rock;

                hightest_y = @max(hightest_y, p[1]);
            }
        }

        rock_path.clearRetainingCapacity();
    }

    if (with_floor) {
        var x: u32 = 0;
        while (x < cave_width) : (x += 1) {
            get(cave, .{ x, hightest_y + 2 }).* = .rock;
        }
    }
}

fn fillCave(cave: *Cave) u32 {
    var total_sand: u32 = 0;

    while (true) {
        var sand_position = sand_source;
        while (sand_position[1] < cave_height - 1) {
            const next_positions: []const [2]u32 = &.{
                .{ sand_position[0] + 0, sand_position[1] + 1 },
                .{ sand_position[0] - 1, sand_position[1] + 1 },
                .{ sand_position[0] + 1, sand_position[1] + 1 },
            };
            sand_position = for (next_positions) |next_position| {
                if (get(cave, next_position).* == .air)
                    break next_position;
            } else {
                get(cave, sand_position).* = .sand;
                total_sand += 1;

                if (sand_position[0] == sand_source[0] and sand_position[1] == sand_source[1])
                    return total_sand;

                break;
            };
        } else return total_sand;
    }
}

var gpa = std.heap.GeneralPurposeAllocator(.{}){};

test "solve" {
    try solve(@embedFile("input.txt"));
}

test "exa01" {
    try solve(@embedFile("exa01.txt"));
}
