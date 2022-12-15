const std = @import("std");

fn solve(input: []const u8, mystery_row: i32) !void {
    const sensors = try parse(input);

    var ranges_buffer = try std.ArrayList([2]i32).initCapacity(gpa.allocator(), 8);
    try getRangesForRow(sensors, mystery_row, &ranges_buffer);

    var count: i32 = 0;
    for (ranges_buffer.items) |range| count += range[1] - range[0];
    ranges_buffer.clearRetainingCapacity();

    var row: i32 = 0;
    const lost_beacon_position = while (row <= 4_000_000) : (row += 1) {
        try getRangesForRow(sensors, row, &ranges_buffer);
        if (ranges_buffer.items.len > 1) {
            const smallest_end = @min(ranges_buffer.items[0][1], ranges_buffer.items[1][1]);
            break [2]i32{ smallest_end + 1, row };
        }
        ranges_buffer.clearRetainingCapacity();
    } else unreachable;

    const lost_beacon_tuning =
        @as(i64, lost_beacon_position[0]) * 4_000_000 + @as(i64, lost_beacon_position[1]);

    std.debug.print("Mystery Count: {d}, Lost Beacon Tuning: {d}\n", .{ count, lost_beacon_tuning });
}

const Sensor = struct {
    x: i32,
    y: i32,
    reach: i32,
};

fn parse(input: []const u8) ![]const Sensor {
    var sensors = std.ArrayList(Sensor).init(gpa.allocator());

    var i = std.mem.tokenize(u8, input, "\n");
    while (i.next()) |sensor_line| {
        var ii = std.mem.tokenize(u8, sensor_line, "Sensor at x=, y=: closest beacon is at x=, y=");

        const sensor = try sensors.addOne();

        sensor.x = try std.fmt.parseInt(i32, ii.next().?, 10);
        sensor.y = try std.fmt.parseInt(i32, ii.next().?, 10);

        const beacon_x = try std.fmt.parseInt(i32, ii.next().?, 10);
        const beacon_y = try std.fmt.parseInt(i32, ii.next().?, 10);

        const sensor_reach_x = try std.math.absInt(beacon_x - sensor.x);
        const sensor_reach_y = try std.math.absInt(beacon_y - sensor.y);
        sensor.reach = sensor_reach_x + sensor_reach_y;
    }

    return try sensors.toOwnedSlice();
}

fn overlapOrTouch(a: [2]i32, b: [2]i32) bool {
    return !(a[0] - 1 > b[1] or a[1] + 1 < b[0]);
}

fn insertRange(ranges: *std.ArrayList([2]i32), range: [2]i32) !void {
    for (ranges.items) |merge_range, merge_index| {
        if (overlapOrTouch(range, merge_range)) {
            _ = ranges.swapRemove(merge_index);

            return insertRange(ranges, .{
                @min(range[0], merge_range[0]),
                @max(range[1], merge_range[1]),
            });
        }
    }

    try ranges.append(range);
}

fn getRangesForRow(sensors: []const Sensor, row: i32, out_ranges: *std.ArrayList([2]i32)) !void {
    for (sensors) |sensor| {
        const sensor_distance_to_row = try std.math.absInt(row - sensor.y);
        const sensor_reach_in_row = sensor.reach - sensor_distance_to_row;
        if (sensor_reach_in_row < 0)
            continue;

        const sensor_range_in_row = [2]i32{
            sensor.x - sensor_reach_in_row,
            sensor.x + sensor_reach_in_row,
        };

        try insertRange(out_ranges, sensor_range_in_row);
    }
}

var gpa = std.heap.GeneralPurposeAllocator(.{}){};

test "solve" {
    try solve(@embedFile("input.txt"), 2_000_000);
}

test "exa01" {
    try solve(@embedFile("exa01.txt"), 10);
}
