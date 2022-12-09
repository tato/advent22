const std = @import("std");

fn solve(input: []const u8) !void {
    const two = try countTailVisits(try initRope(2), input);
    const ten = try countTailVisits(try initRope(10), input);

    std.debug.print("Two: {d}, Ten: {d}\n", .{ two, ten });
}

fn initRope(length: usize) ![][2]i32 {
    const rope = try gpa.allocator().alloc([2]i32, length);
    for (rope) |*knot| knot.* = .{ 0, 0 };
    return rope;
}

fn countTailVisits(rope: [][2]i32, trajectory: []const u8) !usize {
    var visited = std.AutoHashMap([2]i32, void).init(gpa.allocator());
    try visited.put(rope[rope.len - 1], {});

    var i = std.mem.split(u8, std.mem.trim(u8, trajectory, &std.ascii.spaces), "\n");
    while (i.next()) |move| {
        const amount = try std.fmt.parseInt(i32, move[2..], 10);
        for (@as([*]void, undefined)[0..@intCast(usize, amount)]) |stepIndex| {
            _ = stepIndex;
            moveStep(rope, move[0]);
            try visited.put(rope[rope.len - 1], {});
        }
    }

    return visited.count();
}

fn moveStep(rope: [][2]i32, direction: u8) void {
    switch (direction) {
        'R' => rope[0][0] += 1,
        'L' => rope[0][0] -= 1,
        'D' => rope[0][1] += 1,
        'U' => rope[0][1] -= 1,
        else => unreachable,
    }
    for (rope[1..]) |*knot, index| {
        follow(&rope[index], knot);
    }
}

fn follow(head: *[2]i32, tail: *[2]i32) void {
    const dx = std.math.absInt(head[0] - tail[0]) catch unreachable;
    const dy = std.math.absInt(head[1] - tail[1]) catch unreachable;
    if (dx >= 2 or dy >= 2) {
        tail[0] = tail[0] + std.math.sign(head[0] - tail[0]);
        tail[1] = tail[1] + std.math.sign(head[1] - tail[1]);
    }
}

var gpa = std.heap.GeneralPurposeAllocator(.{}){};

test "solve" {
    try solve(@embedFile("input.txt"));
}

test "exa01" {
    try solve(@embedFile("exa01.txt"));
}

test "exa02" {
    try solve(@embedFile("exa02.txt"));
}
