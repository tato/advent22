const std = @import("std");

fn solve(input: []const u8, required_rocks: u64) !void {
    const chamber = try gpa.allocator().alloc(u7, 1 << 20);
    for (chamber) |*c| c.* = 0;
    chamber[0] = 0b1111111;

    var highest_rock_y: u64 = 1;
    var stopped_rocks: u64 = 0;
    var move_index: u64 = 0;

    while (stopped_rocks < required_rocks) : (stopped_rocks += 1) {
        const rock_shape = rock_shapes[stopped_rocks % rock_shapes.len];
        var rock_x: u3 = 2;
        var rock_y = highest_rock_y + 3;

        var is_rock_stopped = false;
        while (!is_rock_stopped) : (move_index += 1) {
            const next_rock_x = switch (input[move_index % input.len]) {
                '<' => rock_x -| 1,
                '>' => @min(rock_x +| 1, 6),
                else => unreachable,
            };
            if (!collide(chamber, rock_shape, next_rock_x, rock_y))
                rock_x = next_rock_x;

            if (!collide(chamber, rock_shape, rock_x, rock_y - 1)) {
                rock_y -= 1;
            } else {
                for (rock_shape) |rock_row, rock_row_index| {
                    const positioned_rock_row = rock_row >> rock_x;
                    chamber[rock_y + rock_row_index] |= positioned_rock_row;
                }

                highest_rock_y = @max(highest_rock_y, rock_y + rock_shape.len);

                is_rock_stopped = true;
            }
        }
    }

    std.debug.print("Rock Height: {d}\n", .{highest_rock_y - 1});
}

const rock_shapes: []const []const u7 = &.{
    &.{
        0b1111000,
    },
    &.{
        0b0100000,
        0b1110000,
        0b0100000,
    },
    &.{
        0b1110000,
        0b0010000,
        0b0010000,
    },
    &.{
        0b1000000,
        0b1000000,
        0b1000000,
        0b1000000,
    },
    &.{
        0b1100000,
        0b1100000,
    },
};

fn collide(chamber: []u7, rock_shape: []const u7, rock_x: u3, rock_y: u64) bool {
    for (rock_shape) |rock_row, rock_row_index| {
        const positioned_rock_row = rock_row >> rock_x;
        if (@popCount(positioned_rock_row) != @popCount(rock_row))
            return true;
        if (chamber[rock_y + rock_row_index] & positioned_rock_row != 0)
            return true;
    }
    return false;
}

var gpa = std.heap.GeneralPurposeAllocator(.{}){};

test "solve a" {
    try solve(@embedFile("input.txt"), 2022);
}

test "solve b" {
    // try solve(@embedFile("input.txt"), 1_000_000_000_000);
}

test "exa01 a" {
    try solve(">>><<><>><<<>><>>><<<>>><<<><<<>><>><<>>", 2022);
}
