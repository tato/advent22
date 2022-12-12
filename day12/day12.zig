const std = @import("std");

fn solve(input: []const u8) !void {
    var map = try parse(input);
    const result = try searchSignal(&map);
    std.debug.print(
        "Normal Distance: {d}, Shortest Distance: {d}\n",
        .{ result.starting_index_distance, result.shortest_start_distance },
    );
}

const Cell = packed struct { height: u7, visited: bool };
const SignalMap = struct {
    cells: []Cell,
    width: u32,
    starting_index: u32,
    signal_index: u32,
};

fn parse(input: []const u8) !SignalMap {
    var cells = std.ArrayList(Cell).init(gpa.allocator());
    var map: SignalMap = undefined;

    var i = std.mem.tokenize(u8, input, "\n ");
    while (i.next()) |map_line| {
        map.width = @intCast(u32, map_line.len);
        try cells.appendSlice(@ptrCast([]const Cell, map_line));
    }

    for (cells.items) |*cell, index| {
        std.debug.assert(!cell.visited);
        if (cell.height == 'S') {
            map.starting_index = @intCast(u32, index);
            cell.height = 'a';
        }
        if (cell.height == 'E') {
            map.signal_index = @intCast(u32, index);
            cell.height = 'z';
        }
    }

    map.cells = try cells.toOwnedSlice();
    return map;
}

const Node = struct { index: u32, distance: u32 };
const NodeQueue = std.PriorityQueue(Node, void, distancePriority);
fn distancePriority(context: void, a: Node, b: Node) std.math.Order {
    _ = context;
    return std.math.order(a.distance, b.distance);
}

const SearchSignalResult = struct {
    starting_index_distance: u32 = std.math.maxInt(u32),
    shortest_start_distance: u32 = std.math.maxInt(u32),
};

fn searchSignal(map: *SignalMap) !SearchSignalResult {
    var result = SearchSignalResult{};

    var queue = NodeQueue.init(gpa.allocator(), {});
    try queue.add(Node{ .index = map.signal_index, .distance = 0 });

    while (queue.count() > 0) {
        const node = queue.remove();

        if (node.index == map.starting_index)
            result.starting_index_distance = node.distance;

        if (map.cells[node.index].height == 'a') {
            if (node.distance < result.shortest_start_distance)
                result.shortest_start_distance = node.distance;
        }

        if (node.index + 1 < map.cells.len)
            try addAdjacent(map, &queue, node, node.index + 1);
        if (node.index >= 1)
            try addAdjacent(map, &queue, node, node.index - 1);

        if (node.index + map.width < map.cells.len)
            try addAdjacent(map, &queue, node, node.index + map.width);
        if (node.index >= map.width)
            try addAdjacent(map, &queue, node, node.index - map.width);
    }

    return result;
}

fn addAdjacent(map: *SignalMap, queue: *NodeQueue, old: Node, new_index: u32) !void {
    if (map.cells[new_index].height + 1 >= map.cells[old.index].height and !map.cells[new_index].visited) {
        map.cells[new_index].visited = true;
        try queue.add(Node{ .index = new_index, .distance = old.distance + 1 });
    }
}

var gpa = std.heap.GeneralPurposeAllocator(.{}){};

test "solve" {
    try solve(@embedFile("input.txt"));
}
