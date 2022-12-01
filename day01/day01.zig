const std = @import("std");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};

fn solve(input: []const u8, n: u64) !void {
    var elves = std.ArrayList(u64).init(gpa.allocator());
    try elves.append(0);

    var i = std.mem.split(u8, input, "\n");
    while (i.next()) |token| {
        if (token.len == 0) {
            try elves.append(0);
        } else {
            elves.items[elves.items.len - 1] += try std.fmt.parseInt(u64, token, 10);
        }
    }

    std.sort.sort(u64, elves.items, {}, std.sort.desc(u64));

    var sum = @as(u64, 0);
    for (elves.items[0..n]) |elf| {
        sum += elf;
    }

    std.debug.print("{d}\n", .{sum});
}

test "input a" {
    try solve(@embedFile("input.txt"), 1);
}

test "input b" {
    try solve(@embedFile("input.txt"), 3);
}

test "exa01 a" {
    try solve(@embedFile("exa01.txt"), 1);
}

test "exa01 b" {
    try solve(@embedFile("exa01.txt"), 3);
}
