const std = @import("std");

fn solve(input: []const u8) !void {
    var count_fully_contained: u64 = 0;
    var count_overlaps: u64 = 0;

    var i = std.mem.tokenize(u8, input, "\n");
    while (i.next()) |line| {
        const l_dash_index = std.mem.indexOfScalar(u8, line, '-').?;
        const r_dash_index = std.mem.lastIndexOfScalar(u8, line, '-').?;
        const comma_index = std.mem.indexOfScalar(u8, line, ',').?;

        const parseInt = std.fmt.parseInt;
        const group = [_]u64{
            try parseInt(u64, line[0..l_dash_index], 10),
            try parseInt(u64, line[l_dash_index + 1 .. comma_index], 10),
            try parseInt(u64, line[comma_index + 1 .. r_dash_index], 10),
            try parseInt(u64, line[r_dash_index + 1 ..], 10),
        };

        const l_contains = group[0] >= group[2] and group[1] <= group[3];
        const r_contains = group[2] >= group[0] and group[3] <= group[1];
        if (l_contains or r_contains) {
            count_fully_contained += 1;
        }

        if (!(group[0] > group[3] or group[1] < group[2])) {
            count_overlaps += 1;
        }
    }

    std.debug.print(
        "Contained: {d}, Overlaps: {d}\n",
        .{ count_fully_contained, count_overlaps },
    );
}

test "exa01" {
    try solve(@embedFile("exa01.txt"));
}

test "input" {
    try solve(@embedFile("input.txt"));
}
