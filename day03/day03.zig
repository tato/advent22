const std = @import("std");

fn solvePartA(input: []const u8) !void {
    var sum: usize = 0;

    var left = std.AutoHashMap(u8, void).init(gpa.allocator());

    var i = std.mem.split(u8, input, "\n");
    loop_lines: while (i.next()) |rucksack| {
        defer left.clearRetainingCapacity();

        for (rucksack[0 .. rucksack.len / 2]) |item| {
            try left.put(item, {});
        }

        for (rucksack[rucksack.len / 2 ..]) |item| {
            if (left.contains(item)) {
                sum += priority(item);
                continue :loop_lines;
            }
        }
    }

    std.debug.print("[{d}]\n", .{sum});
}

fn solvePartB(input: []const u8) !void {
    var sum: usize = 0;

    var elf1 = std.AutoHashMap(u8, void).init(gpa.allocator());
    var elf2 = std.AutoHashMap(u8, void).init(gpa.allocator());

    var i = std.mem.split(u8, input, "\n");
    loop_groups: while (true) {
        const elf1_rucksack = i.next() orelse break;
        const elf2_rucksack = i.next().?;
        const elf3_rucksack = i.next().?;

        defer elf1.clearRetainingCapacity();
        defer elf2.clearRetainingCapacity();

        for (elf1_rucksack) |item| {
            try elf1.put(item, {});
        }

        for (elf2_rucksack) |item| {
            if (elf1.contains(item)) {
                try elf2.put(item, {});
            }
        }

        for (elf3_rucksack) |item| {
            if (elf2.contains(item)) {
                sum += priority(item);
                continue :loop_groups;
            }
        }
    }

    std.debug.print("[{d}]\n", .{sum});
}

var gpa = std.heap.GeneralPurposeAllocator(.{}){};

fn priority(item: u8) u8 {
    if (item >= 'a' and item <= 'z') {
        return item - 'a' + 1;
    }
    if (item >= 'A' and item <= 'Z') {
        return item - 'A' + 27;
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
