const std = @import("std");

fn solve(input: []const u8) !void {
    const cubes = try parseCubes(input);

    const reachability = try gpa.allocator().create(ReachabilityMatrix);
    try calculateReachability(reachability, cubes);

    var exposed_sides: u64 = 0;
    var exterior_sides: u64 = 0;

    for (cubes.keys()) |cube| {
        var cube_exposed_sides: u64 = 6;
        var cube_exterior_sides: u64 = 6;

        var neighbours = Neighbours{};
        for (cubeNeighbours(cube, &neighbours).slice()) |neighbour| {
            if (cubes.contains(neighbour))
                cube_exposed_sides -= 1;
            if (!reachability[neighbour[0]][neighbour[1]][neighbour[2]]) {
                cube_exterior_sides -= 1;
            }
        }

        exposed_sides += cube_exposed_sides;
        exterior_sides += cube_exterior_sides;
    }

    std.debug.print("Exposed Sides: {d}, Exterior Sides: {d}\n", .{ exposed_sides, exterior_sides });
}

const CubeElem = u16;
const Cube = [3]CubeElem;
const CubeArray = std.AutoArrayHashMap(Cube, void);
const ReachabilityMatrix = [exterior_elem][exterior_elem][exterior_elem]bool;
const exterior_elem = 25;
const Neighbours = std.BoundedArray(Cube, 6);

fn parseCubes(input: []const u8) !CubeArray {
    var cubes = CubeArray.init(gpa.allocator());

    var i = std.mem.tokenize(u8, input, "\n ");
    while (i.next()) |cube_line| {
        var coordinate_i = std.mem.split(u8, cube_line, ",");
        try cubes.put(.{
            try std.fmt.parseInt(CubeElem, coordinate_i.next().?, 10),
            try std.fmt.parseInt(CubeElem, coordinate_i.next().?, 10),
            try std.fmt.parseInt(CubeElem, coordinate_i.next().?, 10),
        }, {});
    }

    return cubes;
}

fn cubeNeighbours(cube: Cube, neighbours: *Neighbours) *Neighbours {
    inline for (.{ cube[0] -% 1, cube[0] +% 1 }) |x| {
        if (x < exterior_elem)
            neighbours.appendAssumeCapacity(.{ x, cube[1], cube[2] });
    }
    inline for (.{ cube[1] -% 1, cube[1] +% 1 }) |y| {
        if (y < exterior_elem)
            neighbours.appendAssumeCapacity(.{ cube[0], y, cube[2] });
    }
    inline for (.{ cube[2] -% 1, cube[2] +% 1 }) |z| {
        if (z < exterior_elem)
            neighbours.appendAssumeCapacity(.{ cube[0], cube[1], z });
    }
    return neighbours;
}

fn calculateReachability(reachability: *ReachabilityMatrix, cubes: CubeArray) !void {
    for (std.mem.sliceAsBytes(reachability)) |*b| b.* = 0;

    var queue = std.AutoArrayHashMap(Cube, void).init(gpa.allocator());
    try queue.put(.{ exterior_elem - 1, exterior_elem - 1, exterior_elem - 1 }, {});

    var index: usize = 0;
    while (index < queue.count()) : (index += 1) {
        const cube = queue.keys()[index];

        reachability[cube[0]][cube[1]][cube[2]] = true;

        var neighbours = Neighbours{};
        for (cubeNeighbours(cube, &neighbours).slice()) |neighbour| {
            if (!cubes.contains(neighbour))
                try queue.put(neighbour, {});
        }
    }
}

var gpa = std.heap.GeneralPurposeAllocator(.{}){};

test "solve" {
    try solve(@embedFile("input.txt"));
}
