const std = @import("std");

var debug: bool = false;
pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const ally = gpa.allocator();

    const exa01 = try parse(ally, @embedFile("exa01.txt"));
    const input = try parse(ally, @embedFile("input.txt"));

    std.debug.print("Example Part 1: {s}\n", .{try part1(ally, exa01)});
    std.debug.print("Part 1: {s}\n", .{try part1(ally, input)});
    std.debug.print("Example Part 2: {d}\n", .{try part2(ally, exa01)});
    std.debug.print("Part 2: {d}\n", .{try part2(ally, input)});
}

const Snafu = []const u8;

fn parse(ally: std.mem.Allocator, input: []const u8) ![]Snafu {
    var snafus = std.ArrayList(Snafu).init(ally);
    errdefer snafus.deinit();
    var lines = std.mem.tokenize(u8, input, "\r\n");
    while (lines.next()) |line| {
        try snafus.append(std.mem.trim(u8, line, &std.ascii.whitespace));
    }
    return try snafus.toOwnedSlice();
}

fn part1(ally: std.mem.Allocator, snafus: []const Snafu) !Snafu {
    var sum: i64 = 0;
    for (snafus) |snafu|
        sum += try numberFromSnafu(snafu);
    return try snafuFromNumber(ally, sum);
}

fn part2(ally: std.mem.Allocator, input: []const Snafu) !u64 {
    _ = ally;
    _ = input;
    return 0;
}

fn digitFromSnafuDigit(digit: u8) i8 {
    return switch (digit) {
        '=' => -2,
        '-' => -1,
        '0' => 0,
        '1' => 1,
        '2' => 2,
        else => unreachable,
    };
}

fn snafuDigitFromDigit(digit: i8) u8 {
    return switch (digit) {
        -2 => '=',
        -1 => '-',
        0 => '0',
        1 => '1',
        2 => '2',
        else => unreachable,
    };
}

fn numberFromSnafu(snafu: Snafu) !i64 {
    var number: i64 = 0;
    for (0..snafu.len) |index|
        number += digitFromSnafuDigit(snafu[snafu.len - index - 1]) *
            try std.math.powi(i64, 5, @as(i64, @intCast(index)));
    return number;
}

fn snafuFromNumber(ally: std.mem.Allocator, number: i64) !Snafu {
    const abs = std.math.absCast;
    var pow: i64 = 1;
    while (abs(pow - number) > abs(pow * 5 - number)) pow *= 5;

    var rest: i64 = number;
    var snafu = std.ArrayList(u8).init(ally);
    while (pow > 1) {
        var best_digit: i8 = 0;
        var best_distance: u64 = std.math.maxInt(i64);

        var digit: i8 = -2;
        while (digit <= 2) : (digit += 1) {
            const distance: u64 = abs(digit * pow - rest);
            if (distance < best_distance) {
                best_digit = digit;
                best_distance = distance;
            }
        }

        rest -= best_digit * pow;

        try snafu.append(snafuDigitFromDigit(@intCast(best_digit)));
        pow = @divExact(pow, 5);
    }

    std.debug.assert(rest >= -2 and rest <= 2);
    try snafu.append(snafuDigitFromDigit(@intCast(rest)));

    return try snafu.toOwnedSlice();
}
