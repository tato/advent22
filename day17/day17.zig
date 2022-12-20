const std = @import("std");

fn solve(input: []const u8, required_rocks: u64, paint: bool) !void {
    const chamber_wall = 0b100000001;
    const chamber = try gpa.allocator().alloc(u9, 1 << 20);
    defer gpa.allocator().free(chamber);
    for (chamber) |*c| c.* = chamber_wall;
    chamber[0] = 0b111111111;

    var memories = std.AutoArrayHashMap(ChamberId, ChamberStats).init(gpa.allocator());
    defer memories.deinit();

    var highest_rock_y: u64 = 0;
    var stopped_rocks: u64 = 0;
    var move_index: u32 = 0;

    while (stopped_rocks < required_rocks) : (stopped_rocks += 1) {
        var state = ChamberId{
            .rock_shape_index = @intCast(u32, stopped_rocks % rock_shapes.len),
            .move_index = move_index % @intCast(u32, input.len),
            .chamber_state = .{0} ** ChamberId.state_len,
        };
        if (highest_rock_y >= ChamberId.state_len) {
            state.chamber_state = chamber[highest_rock_y - ChamberId.state_len ..][0..ChamberId.state_len].*;
        }

        const entry = try memories.getOrPut(state);
        if (entry.found_existing) {
            const period_height = highest_rock_y - entry.value_ptr.height;
            const period_rocks = stopped_rocks - entry.value_ptr.stopped_rocks;

            const remaining_rocks = required_rocks - stopped_rocks;
            const remaining_full_periods = remaining_rocks / period_rocks;

            if (remaining_full_periods > 0) {
                highest_rock_y += remaining_full_periods * period_height;

                const extra_rocks = remaining_rocks % period_rocks;
                const extra_index = entry.index + extra_rocks;
                highest_rock_y += memories.values()[extra_index].height - entry.value_ptr.height;

                break;
            }
        } else {
            entry.value_ptr.* = .{
                .height = highest_rock_y,
                .stopped_rocks = stopped_rocks,
            };
        }

        var rock = rock_shapes[state.rock_shape_index];
        var rock_y: u64 = highest_rock_y + 4;

        if (paint)
            try paintChamber(chamber[0..@max(highest_rock_y, rock_y + 4)], rock, rock_y);

        while (true) {
            const pushed_rock = shiftRock(rock, input[move_index % @intCast(u32, input.len)]);
            if (!collide(chamber, pushed_rock, rock_y))
                rock = pushed_rock;
            defer move_index += 1;

            if (!collide(chamber, rock, rock_y - 1)) {
                rock_y -= 1;
            } else {
                for (rock) |rock_row, rock_row_index|
                    chamber[rock_y + rock_row_index] |= rock_row;

                while (chamber[highest_rock_y + 1] != chamber_wall) : (highest_rock_y += 1) {}

                break;
            }
        }
    }

    std.debug.print("Rock Height: {d}\n", .{highest_rock_y});
}

const RockRow = u9;
const RockShape = [4]RockRow;
const rock_shapes: []const RockShape = &.{
    .{ 0b000111100, 0b000000000, 0b000000000, 0b000000000 }, // _
    .{ 0b000010000, 0b000111000, 0b000010000, 0b000000000 }, // +
    .{ 0b000111000, 0b000001000, 0b000001000, 0b000000000 }, // ⅃
    .{ 0b000100000, 0b000100000, 0b000100000, 0b000100000 }, // |
    .{ 0b000110000, 0b000110000, 0b000000000, 0b000000000 }, // ◾
};
const ChamberId = struct {
    rock_shape_index: u32,
    move_index: u32,
    chamber_state: [state_len]RockRow,
    const state_len = 12;
};
const ChamberStats = struct {
    height: u64,
    stopped_rocks: u64,
};

fn shiftRock(rock: RockShape, push: u8) RockShape {
    var shifted_rock = rock;
    for (shifted_rock) |*row| {
        switch (push) {
            '>' => row.* >>= 1,
            '<' => row.* <<= 1,
            else => unreachable,
        }
    }
    return shifted_rock;
}

fn collide(chamber: []RockRow, rock_shape: RockShape, rock_y: u64) bool {
    for (rock_shape) |rock_row, rock_row_index| {
        if (chamber[rock_y + rock_row_index] & rock_row != 0)
            return true;
    }
    return false;
}

fn paintChamber(chamber: []const RockRow, falling: ?RockShape, falling_y: u64) !void {
    var stderr = std.io.bufferedWriter(std.io.getStdErr().writer());
    const writer = stderr.writer();

    try writer.writeAll("\n");

    var y = chamber.len - 1;
    while (y > 0) : (y -= 1) {
        try writer.writeAll("|");

        const falling_row = if (falling != null and y >= falling_y and y < falling_y + falling.?.len)
            falling.?[y - falling_y]
        else
            0;

        var x: u4 = 7;
        while (x > 0) : (x -= 1) {
            if ((falling_row >> x) & 1 != 0) {
                try writer.writeAll("@");
            } else if ((chamber[y] >> x) & 1 != 0) {
                try writer.writeAll("#");
            } else {
                try writer.writeAll(".");
            }
        }
        try writer.writeAll("|\n");
    }

    try writer.writeAll("+-------+\n");
    try stderr.flush();
}

var gpa = std.heap.GeneralPurposeAllocator(.{}){};

test "solve a" {
    try solve(@embedFile("input.txt"), 2022, false);
}

test "solve b" {
    try solve(@embedFile("input.txt"), 1_000_000_000_000, false);
}

test "exa01 a" {
    try solve(">>><<><>><<<>><>>><<<>>><<<><<<>><>><<>>", 2022, false);
}

test "exa01 b" {
    try solve(">>><<><>><<<>><>>><<<>>><<<><<<>><>><<>>", 1_000_000_000_000, false);
}
