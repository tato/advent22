const std = @import("std");

fn solvePartA(input: []const u8) !void {
    var sum: usize = 0;

    var i = std.mem.split(u8, input, "\n");
    while (i.next()) |rucksack| {
        var left: u52 = 0;
        for (rucksack[0 .. rucksack.len / 2]) |item|
            left |= @as(u52, 1) << priority(item);

        var right: u52 = 0;
        for (rucksack[rucksack.len / 2 ..]) |item|
            right |= @as(u52, 1) << priority(item);

        sum += @ctz(left & right) + 1;
    }

    std.debug.print("[{d}]\n", .{sum});
}

fn solvePartB(input: []const u8) !void {
    var sum: usize = 0;

    var i = std.mem.split(u8, input, "\n");
    while (i.next()) |rucksack| {
        var elf1: u52 = 0;
        for (rucksack) |item|
            elf1 |= @as(u52, 1) << priority(item);

        var elf2: u52 = 0;
        for (i.next().?) |item|
            elf2 |= @as(u52, 1) << priority(item);

        var elf3: u52 = 0;
        for (i.next().?) |item|
            elf3 |= @as(u52, 1) << priority(item);

        sum += @ctz(elf1 & elf2 & elf3) + 1;
    }

    std.debug.print("[{d}]\n", .{sum});
}

fn priority(item: u8) u6 {
    if (item >= 'a' and item <= 'z') {
        return @truncate(u6, item - 'a');
    }
    if (item >= 'A' and item <= 'Z') {
        return @truncate(u6, item - 'A' + 26);
    }
    std.debug.panic("Invalid item: {d}", .{item});
}

test "exa01 a" {
    try solvePartA(@embedFile("exa01.txt"));
}

test "input a" {
    try solvePartA(@embedFile("input.txt"));
}

test "exa01 b" {
    try solvePartB(@embedFile("exa01.txt"));
}

test "input b" {
    try solvePartB(@embedFile("input.txt"));
}
