const std = @import("std");

fn solve(input: []const u8) !void {
    var map = try parse(input);

    const starting_index: u32 = for (map.cells) |*cell, index| {
        if (cell.height == 'S') {
            cell.height = 'a';
            break @intCast(u32, index);
        }
    } else unreachable;

    const signal_index: u32 = for (map.cells) |*cell, index| {
        if (cell.height == 'E') {
            cell.height = 'z';
            break @intCast(u32, index);
        }
    } else unreachable;

    const result = try searchSignal(&map, starting_index, signal_index);

    std.debug.print(
        "Normal Distance: {d}, Shortest Distance: {d}\n",
        .{ result.starting_index_distance, result.shortest_start_distance },
    );
}

const Cell = packed struct { height: u7, visited: bool };
const SignalMap = struct { cells: []Cell, width: u32 };

fn parse(input: []const u8) !SignalMap {
    var cells = std.ArrayList(Cell).init(gpa.allocator());

    var i = std.mem.tokenize(u8, input, "\n ");
    while (i.next()) |map_line|
        try cells.appendSlice(@ptrCast([]const Cell, map_line));

    return SignalMap{
        .cells = try cells.toOwnedSlice(),
        .width = @intCast(u32, std.mem.indexOfScalar(u8, input, '\n').?),
    };
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

fn searchSignal(map: *SignalMap, starting_index: u32, signal_index: u32) !SearchSignalResult {
    var result = SearchSignalResult{};

    var queue = NodeQueue.init(gpa.allocator(), {});
    try queue.add(Node{ .index = signal_index, .distance = 0 });

    while (queue.count() > 0) {
        const node = queue.remove();

        if (node.index == starting_index)
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
