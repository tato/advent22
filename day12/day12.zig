const std = @import("std");

fn solve(input: []const u8) !void {
    var search = try parse(input);
    try searchSignal(&search);
    std.debug.print(
        "Normal Distance: {d}, Shortest Distance: {d}\n",
        .{ search.starting_index_distance, search.shortest_start_distance },
    );
}

const SignalSearch = struct {
    map: []const u8,
    map_width: u32,
    map_visited: []bool,
    starting_index: u32,
    signal_index: u32,

    starting_index_distance: u32,
    shortest_start_distance: u32,
};

fn parse(input: []const u8) !SignalSearch {
    var map = std.ArrayList(u8).init(gpa.allocator());
    var search: SignalSearch = undefined;
    search.shortest_start_distance = std.math.maxInt(u32);

    var i = std.mem.tokenize(u8, input, "\n ");
    while (i.next()) |map_line| {
        search.map_width = @intCast(u32, map_line.len);
        try map.appendSlice(map_line);
    }

    for (map.items) |*cell, index| {
        if (cell.* == 'S') {
            search.starting_index = @intCast(u32, index);
            cell.* = 'a';
        }
        if (cell.* == 'E') {
            search.signal_index = @intCast(u32, index);
            cell.* = 'z';
        }
    }

    search.map = try map.toOwnedSlice();
    search.map_visited = try gpa.allocator().alloc(bool, search.map.len);
    for (search.map_visited) |*v| v.* = false;
    return search;
}

const Cell = struct { index: u32, distance: u32 };
const CellQueue = std.PriorityQueue(Cell, void, distancePriority);
fn distancePriority(context: void, a: Cell, b: Cell) std.math.Order {
    _ = context;
    return std.math.order(a.distance, b.distance);
}

fn searchSignal(search: *SignalSearch) !void {
    var queue = CellQueue.init(gpa.allocator(), {});
    try queue.add(Cell{ .index = search.signal_index, .distance = 0 });

    while (queue.count() > 0) {
        const cell = queue.remove();

        if (cell.index == search.starting_index)
            search.starting_index_distance = cell.distance;

        if (search.map[cell.index] == 'a') {
            if (cell.distance < search.shortest_start_distance)
                search.shortest_start_distance = cell.distance;
        }

        if (cell.index + 1 < search.map.len)
            try addAdjacent(search, &queue, cell, cell.index + 1);
        if (cell.index >= 1)
            try addAdjacent(search, &queue, cell, cell.index - 1);

        if (cell.index + search.map_width < search.map.len)
            try addAdjacent(search, &queue, cell, cell.index + search.map_width);
        if (cell.index >= search.map_width)
            try addAdjacent(search, &queue, cell, cell.index - search.map_width);
    }
}

fn addAdjacent(search: *SignalSearch, queue: *CellQueue, old: Cell, new_index: u32) !void {
    if (search.map[new_index] + 1 >= search.map[old.index]) {
        if (!search.map_visited[new_index]) {
            search.map_visited[new_index] = true;
            try queue.add(Cell{ .index = new_index, .distance = old.distance + 1 });
        }
    }
}

var gpa = std.heap.GeneralPurposeAllocator(.{}){};

test "solve" {
    try solve(@embedFile("input.txt"));
}
