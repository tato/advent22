const std = @import("std");

fn solve(input: []const u8) !void {
    var part1_score: u64 = 0;
    var part2_score: u64 = 0;

    var moves = std.mem.split(u8, input, "\n");
    while (moves.next()) |move| {
        const their = move[0] - 'A';
        const your = move[2] - 'X';

        play(their, your, &part1_score);

        const your_part2 = (their + your + 2) % 3;
        play(their, your_part2, &part2_score);
    }

    std.debug.print("[{d}] [{d}]\n", .{ part1_score, part2_score });
}

fn play(their: u8, your: u8, score: *u64) void {
    if (their == your)
        score.* += 3;

    if ((their + 1) % 3 == your)
        score.* += 6;

    score.* += your + 1;
}

test "input" {
    try solve(@embedFile("input.txt"));
}

test "exa01" {
    try solve(@embedFile("exa01.txt"));
}
