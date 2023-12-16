const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const ally = gpa.allocator();

    const exa01 = try parse(ally, @embedFile("exa01.txt"));
    const input = try parse(ally, @embedFile("input.txt"));

    std.debug.print("Example Part 1: {d}\n", .{try part1(ally, exa01)});
    std.debug.print("Part 1: {d}\n", .{try part1(ally, input)});
    std.debug.print("Example Part 2: {d}\n", .{try part2(ally, exa01)});
    std.debug.print("Part 2: {d}\n", .{try part2(ally, input)});
}

fn parse(ally: std.mem.Allocator, input: []const u8) ![]const i64 {
    var numbers = std.ArrayList(i64).init(ally);
    var i = std.mem.tokenize(u8, input, " \n\r");
    while (i.next()) |number|
        try numbers.append(try std.fmt.parseInt(i64, number, 10));
    return try numbers.toOwnedSlice();
}

fn part1(ally: std.mem.Allocator, input: []const i64) !i64 {
    const numbers = try ally.dupe(i64, input);
    defer ally.free(numbers);

    const indices = try ally.alloc(usize, numbers.len);
    defer ally.free(indices);
    for (indices, 0..) |*index, i| index.* = i;

    try mix(ally, numbers, indices);

    return coordinatesSum(numbers, indices);
}

fn part2(ally: std.mem.Allocator, input: []const i64) !i64 {
    const numbers = try ally.dupe(i64, input);
    defer ally.free(numbers);
    for (numbers) |*n| n.* *= 811589153;

    const indices = try ally.alloc(usize, numbers.len);
    defer ally.free(indices);
    for (indices, 0..) |*index, i| index.* = i;

    for (0..10) |_| try mix(ally, numbers, indices);

    return coordinatesSum(numbers, indices);
}

fn mix(ally: std.mem.Allocator, numbers: []const i64, indices: []usize) !void {
    for (0..numbers.len) |index|
        rotate(numbers, indices, index);

    const copy = try ally.dupe(i64, numbers);
    defer ally.free(copy);
}

fn rotate(numbers: []const i64, indices: []usize, index: usize) void {
    const number = numbers[index];

    if (number == 0)
        return;

    const old_index = std.mem.indexOfScalar(usize, indices, index).?;
    const new_index: usize = @intCast(@mod(
        @as(i64, @intCast(old_index)) + number,
        @as(i64, @intCast(numbers.len)) - 1,
    ));

    if (old_index < new_index) {
        std.mem.copyForwards(
            usize,
            indices[old_index..new_index],
            indices[old_index + 1 .. new_index + 1],
        );
    } else {
        std.mem.copyBackwards(
            usize,
            indices[new_index + 1 .. old_index + 1],
            indices[new_index..old_index],
        );
    }
    indices[new_index] = index;
}

fn coordinatesSum(numbers: []const i64, indices: []const usize) i64 {
    const zero_index = std.mem.indexOfScalar(i64, numbers, 0).?;
    const zero_index_index = std.mem.indexOfScalar(usize, indices, zero_index).?;
    const coord0 = numbers[indices[(zero_index_index +% 1000) % numbers.len]];
    const coord1 = numbers[indices[(zero_index_index +% 2000) % numbers.len]];
    const coord2 = numbers[indices[(zero_index_index +% 3000) % numbers.len]];
    return coord0 + coord1 + coord2;
}
