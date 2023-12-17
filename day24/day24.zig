const std = @import("std");

var debug: bool = false;
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

const Input = struct {
    cells: []const u8,
    w: u16,
    h: u16,
    start_x: u16,
    start_y: u16,
    target_x: u16,
    target_y: u16,
};
const Spot = struct {
    minute: u32,
    x: u16,
    y: u16,
};
const SpotList = std.SinglyLinkedList(Spot);
const SeenMap = std.AutoHashMap(Spot, void);

fn parse(ally: std.mem.Allocator, input: []const u8) !Input {
    var cells = std.ArrayList(u8).init(ally);
    errdefer cells.deinit();
    var w: usize = 0;
    var h: usize = 0;

    var lines = std.mem.tokenize(u8, input, "\r\n");
    while (lines.next()) |line| {
        if (w == 0) w = line.len else std.debug.assert(w == line.len);
        h += 1;
        try cells.appendSlice(line);
    }

    return Input{
        .cells = try cells.toOwnedSlice(),
        .w = @intCast(w),
        .h = @intCast(h),
        .start_x = 1,
        .start_y = 0,
        .target_x = @intCast(w - 2),
        .target_y = @intCast(h - 1),
    };
}

fn part1(ally: std.mem.Allocator, input: Input) !u64 {
    return try navigate(
        ally,
        input,
        Spot{ .minute = 0, .x = input.start_x, .y = input.start_y },
        Spot{ .minute = 0, .x = input.target_x, .y = input.target_y },
    );
}

fn part2(ally: std.mem.Allocator, input: Input) !u64 {
    const trip1 = try navigate(
        ally,
        input,
        Spot{ .minute = 0, .x = input.start_x, .y = input.start_y },
        Spot{ .minute = 0, .x = input.target_x, .y = input.target_y },
    );
    const trip2 = try navigate(
        ally,
        input,
        Spot{ .minute = trip1, .x = input.target_x, .y = input.target_y },
        Spot{ .minute = 0, .x = input.start_x, .y = input.start_y },
    );
    const trip3 = try navigate(
        ally,
        input,
        Spot{ .minute = trip2, .x = input.start_x, .y = input.start_y },
        Spot{ .minute = 0, .x = input.target_x, .y = input.target_y },
    );
    return trip3;
}

fn navigate(
    ally: std.mem.Allocator,
    input: Input,
    starting_spot: Spot,
    target_spot: Spot,
) !u32 {
    if (debug) {
        var stdout = std.io.bufferedWriter(std.io.getStdOut().writer());
        for (0..10) |minute| {
            try stdout.writer().print("== Minute {d} ==\n", .{minute});
            try printBlizzards(input, @intCast(minute), stdout.writer());
            _ = try stdout.write("\n");
            try stdout.flush();
        }
    }

    var spot_pool = std.heap.MemoryPool(SpotList.Node).init(ally);
    defer spot_pool.deinit();

    var spots = SpotList{};
    defer while (spots.popFirst()) |spot|
        spot_pool.destroy(spot);

    const first_spot = try ally.create(SpotList.Node);
    first_spot.data = starting_spot;
    spots.prepend(first_spot);

    var seen = SeenMap.init(ally);
    defer seen.deinit();
    try seen.put(first_spot.data, {});

    while (true) {
        const node = spots.popFirst().?;
        defer spot_pool.destroy(node);
        const spot = node.data;

        if (spot.x == target_spot.x and spot.y == target_spot.y)
            return spot.minute;

        try possiblyInsert(&spot_pool, input, &spots, &seen, Spot{
            .x = spot.x,
            .y = spot.y,
            .minute = spot.minute + 1,
        }, target_spot);
        try possiblyInsert(&spot_pool, input, &spots, &seen, Spot{
            .x = spot.x + 1,
            .y = spot.y,
            .minute = spot.minute + 1,
        }, target_spot);
        try possiblyInsert(&spot_pool, input, &spots, &seen, Spot{
            .x = spot.x - 1,
            .y = spot.y,
            .minute = spot.minute + 1,
        }, target_spot);
        if (spot.y + 1 < input.h) {
            try possiblyInsert(&spot_pool, input, &spots, &seen, Spot{
                .x = spot.x,
                .y = spot.y + 1,
                .minute = spot.minute + 1,
            }, target_spot);
        }
        if (spot.y > 0) {
            try possiblyInsert(&spot_pool, input, &spots, &seen, Spot{
                .x = spot.x,
                .y = spot.y - 1,
                .minute = spot.minute + 1,
            }, target_spot);
        }
    }
}

const BlizzardCell = std.BoundedArray(u8, 4);
fn forecastBlizzards(input: Input, spot: Spot) BlizzardCell {
    const x: i64 = @intCast(spot.x);
    const y: i64 = @intCast(spot.y);
    const minute: i64 = @intCast(spot.minute);

    const x_e = @mod(x - minute - 1, input.w - 2) + 1;
    const x_w = @mod(x + minute - 1, input.w - 2) + 1;
    const y_n = @mod(y + minute - 1, input.h - 2) + 1;
    const y_s = @mod(y - minute - 1, input.h - 2) + 1;

    var r = BlizzardCell{};
    if (input.cells[@intCast(y * input.w + x_e)] == '>')
        r.appendAssumeCapacity('>');
    if (input.cells[@intCast(y * input.w + x_w)] == '<')
        r.appendAssumeCapacity('<');
    if (input.cells[@intCast(y_n * input.w + x)] == '^')
        r.appendAssumeCapacity('^');
    if (input.cells[@intCast(y_s * input.w + x)] == 'v')
        r.appendAssumeCapacity('v');
    return r;
}

fn printBlizzards(input: Input, minute: u32, writer: anytype) !void {
    for (0..input.h) |y| {
        for (0..input.w) |x| {
            if (input.cells[y * input.w + x] == '#') {
                try writer.writeByte('#');
                continue;
            }

            const cell = forecastBlizzards(
                input,
                .{ .x = @intCast(x), .y = @intCast(y), .minute = minute },
            );
            if (cell.len == 0) {
                try writer.writeByte('.');
            } else if (cell.len == 1) {
                try writer.writeByte(cell.slice()[0]);
            } else if (cell.len == 2) {
                try writer.writeByte('2');
            } else if (cell.len == 3) {
                try writer.writeByte('3');
            } else if (cell.len == 4) {
                try writer.writeByte('4');
            }
        }
        try writer.writeByte('\n');
    }
}

fn spotDistance(a: Spot, b: Spot) u16 {
    return @intCast(std.math.absCast(@as(i32, a.x) - @as(i32, b.x)) +
        std.math.absCast(@as(i32, a.y) - @as(i32, b.y)));
}

fn insertOrdered(spots: *SpotList, spot: *SpotList.Node, target: Spot) !void {
    const d = spotDistance(target, spot.data);

    var prev: ?*SpotList.Node = null;
    var curr = spots.first;
    while (curr) |other_spot| : ({
        prev = curr;
        curr = curr.?.next;
    }) {
        if (spotDistance(target, other_spot.data) > d and
            other_spot.data.minute > spot.data.minute)
        {
            break;
        }
    }

    if (prev) |node|
        node.insertAfter(spot)
    else
        spots.prepend(spot);
}

fn possiblyInsert(
    pool: *std.heap.MemoryPool(SpotList.Node),
    input: Input,
    spots: *SpotList,
    seen: *SeenMap,
    spot: Spot,
    target: Spot,
) !void {
    if (!seen.contains(spot) and
        input.cells[spot.y * input.w + spot.x] != '#' and
        forecastBlizzards(input, spot).len == 0)
    {
        const node = try pool.create();
        node.data = spot;
        try insertOrdered(spots, node, target);
        try seen.put(spot, {});
    }
}
