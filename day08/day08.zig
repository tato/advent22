const std = @import("std");

fn solve(input: []const u8) !void {
    var field = TreeField{
        .trees = try std.ArrayList(u8).initCapacity(gpa.allocator(), 1 << 10),
        .visibility = std.ArrayList(bool).init(gpa.allocator()),
    };

    try readTrees(&field, input);

    try findVisibility(&field);

    var visible_count: usize = 0;
    for (field.visibility.items) |visible|
        visible_count += if (visible) 1 else 0;

    var most_scenic: u64 = 0;
    for (field.trees.items) |_, index|
        most_scenic = @max(try findScenic(&field, index), most_scenic);

    std.debug.print("Visible {d}, Scenic: {d}\n", .{ visible_count, most_scenic });
}

const TreeField = struct {
    trees: std.ArrayList(u8),
    width: usize = 0,
    height: usize = 0,
    visibility: std.ArrayList(bool),
};

fn readTrees(field: *TreeField, input: []const u8) !void {
    var input_lines = std.mem.split(u8, input, "\n");
    field.width = input_lines.first().len;
    input_lines.reset();

    while (input_lines.next()) |row| {
        try field.trees.appendSlice(row);
    }

    field.height = field.trees.items.len / field.width;
}

fn findVisibility(field: *TreeField) !void {
    try field.visibility.appendNTimes(false, field.trees.items.len);

    var y: usize = 0;
    while (y < field.height) : (y += 1) {
        findVisibilityForLine(field, .x, y);
        findVisibilityForLine(field, .reverse_x, y);
    }

    var x: usize = 0;
    while (x < field.width) : (x += 1) {
        findVisibilityForLine(field, .y, x);
        findVisibilityForLine(field, .reverse_y, x);
    }
}

fn findVisibilityForLine(field: *TreeField, axis: LineIterator.Axis, fixed: usize) void {
    var tallest_tree: u8 = 0;

    var i = LineIterator{ .wide = field.width, .high = field.height, .axis = axis, .fixed = fixed };
    while (i.next()) |index| {
        if (field.trees.items[index] > tallest_tree) {
            field.visibility.items[index] = true;
            tallest_tree = field.trees.items[index];
        }
    }
}

fn findScenic(field: *TreeField, tree_index: usize) !u64 {
    var scenic: u64 = 1;
    scenic *= findTreeDistanceForLine(field, tree_index, .x);
    scenic *= findTreeDistanceForLine(field, tree_index, .reverse_x);
    scenic *= findTreeDistanceForLine(field, tree_index, .y);
    scenic *= findTreeDistanceForLine(field, tree_index, .reverse_y);
    return scenic;
}

fn findTreeDistanceForLine(f: *TreeField, tree_index: usize, axis: LineIterator.Axis) u64 {
    var i = LineIterator{ .wide = f.width, .high = f.height, .axis = axis, .fixed = 0 };

    switch (axis) {
        .x, .reverse_x => i.fixed = tree_index / f.width,
        .y, .reverse_y => i.fixed = tree_index % f.width,
    }
    var skips = switch (axis) {
        .x => tree_index % f.width,
        .reverse_x => f.width - (tree_index % f.width) - 1,
        .y => tree_index / f.width,
        .reverse_y => f.height - (tree_index / f.width) - 1,
    };

    _ = i.next();
    while (skips > 0) : (skips -= 1)
        _ = i.next();

    var distance: u64 = 0;

    while (i.next()) |index| {
        distance += 1;
        if (f.trees.items[index] >= f.trees.items[tree_index])
            break;
    }
    return distance;
}

const LineIterator = struct {
    const Axis = enum { x, y, reverse_x, reverse_y };
    wide: usize,
    high: usize,
    axis: Axis,
    fixed: usize,

    current: usize = 0,

    fn next(i: *@This()) ?usize {
        switch (i.axis) {
            .x, .reverse_x => if (i.current >= i.wide) return null,
            .y, .reverse_y => if (i.current >= i.high) return null,
        }

        const index = switch (i.axis) {
            .x => i.fixed * i.wide + i.current,
            .reverse_x => i.fixed * i.wide + (i.wide - i.current - 1),
            .y => i.current * i.wide + i.fixed,
            .reverse_y => (i.high - i.current - 1) * i.wide + i.fixed,
        };

        i.current += 1;

        return index;
    }
};

var gpa = std.heap.GeneralPurposeAllocator(.{}){};

test "solve" {
    try solve(@embedFile("input.txt"));
}

test "exa01" {
    try solve(@embedFile("exa01.txt"));
}
