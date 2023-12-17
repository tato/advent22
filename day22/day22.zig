const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const ally = gpa.allocator();

    const exa01 = try parse(ally, @embedFile("exa01.txt"));
    const input = try parse(ally, @embedFile("input.txt"));

    std.debug.print("Example Part 1: {d}\n", .{part1(exa01)});
    std.debug.print("Part 1: {d}\n", .{part1(input)});
    std.debug.print("Example Part 2: {d}\n", .{part2(exa01)});
    std.debug.print("Part 2: {d}\n", .{part2(input)});
}

const Input = struct {
    board: []u8,
    w: u16,
    h: u16,
    moves: []const Move,
    fn index(input: Input, x: i64, y: i64) usize {
        std.debug.assert(x > 0 and x < input.w and y > 0 and y < input.h);
        return @as(usize, @intCast(y)) * input.w + @as(usize, @intCast(x));
    }
    fn get(input: Input, x: i64, y: i64) u8 {
        return input.board[input.index(x, y)];
    }
};
const Move = union(enum) { walk: u32, l, r };
const Orientation = enum(u2) { r, d, l, u };

fn parse(ally: std.mem.Allocator, input: []const u8) !Input {
    var rows = std.ArrayList([]const u8).init(ally);
    defer rows.deinit();
    var width: u16 = 0;

    var moves = std.ArrayList(Move).init(ally);
    errdefer moves.deinit();

    var lines = std.mem.tokenize(u8, input, "\r\n");
    while (lines.next()) |line| {
        if (std.ascii.isDigit(line[0])) {
            try parseMoves(line, &moves);
        } else {
            width = @max(width, @as(u16, @intCast(line.len)));
            try rows.append(line);
        }
    }

    var board = try std.ArrayList(u8).initCapacity(ally, rows.items.len * width);
    errdefer board.deinit();

    for (rows.items) |row| {
        board.appendSliceAssumeCapacity(row);
        if (row.len < width)
            board.appendNTimesAssumeCapacity(' ', width - row.len);
    }

    return Input{
        .board = try board.toOwnedSlice(),
        .w = width,
        .h = @intCast(rows.items.len),
        .moves = try moves.toOwnedSlice(),
    };
}

fn parseMoves(input: []const u8, moves: *std.ArrayList(Move)) !void {
    var index: usize = 0;
    while (index < input.len) : (index += 1) {
        if (input[index] == 'L') {
            try moves.append(.l);
        } else if (input[index] == 'R') {
            try moves.append(.r);
        } else {
            var i = std.mem.tokenize(u8, input[index..], "LR");
            try moves.append(.{ .walk = try std.fmt.parseInt(u32, i.next().?, 10) });
        }
    }
}

var debug: bool = false;
fn part1(input: Input) i64 {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const debug_board = gpa.allocator().dupe(u8, input.board) catch unreachable;

    var x: i64 = @intCast(std.mem.indexOfScalar(u8, input.board, '.') orelse 0);
    var y: i64 = 0;
    var facing = Orientation.r;
    for (input.moves) |move| {
        switch (move) {
            .l => facing = @enumFromInt(@intFromEnum(facing) -% 1),
            .r => facing = @enumFromInt(@intFromEnum(facing) +% 1),
            .walk => |walk_amount| {
                for (0..walk_amount) |_| {
                    var dx: i64 = 0;
                    var dy: i64 = 0;
                    switch (facing) {
                        .r => dx += 1,
                        .d => dy += 1,
                        .l => dx -= 1,
                        .u => dy -= 1,
                    }

                    var xx = @mod(x + dx, input.w);
                    var yy = @mod(y + dy, input.h);
                    while (input.get(xx, yy) == ' ') {
                        xx = @mod(xx + dx, input.w);
                        yy = @mod(yy + dy, input.h);
                    }
                    if (input.get(xx, yy) == '#')
                        break;
                    x = xx;
                    y = yy;

                    if (debug)
                        debug_board[input.index(x, y)] = debugOrientationChar(facing);
                }
            },
        }

        if (debug)
            debug_board[input.index(x, y)] = debugOrientationChar(facing);
    }

    if (debug) {
        for (0..input.h) |debug_row| {
            std.debug.print(
                "{s}\n",
                .{debug_board[debug_row * input.w .. (debug_row + 1) * input.w]},
            );
        }
    }

    return 1000 * (y + 1) + 4 * (x + 1) + @intFromEnum(facing);
}

fn part2(input: Input) u64 {
    _ = input;
    return 0;
}

fn debugOrientationChar(ori: Orientation) u8 {
    return switch (ori) {
        .l => '<',
        .r => '>',
        .u => '^',
        .d => 'v',
    };
}
