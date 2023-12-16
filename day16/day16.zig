const std = @import("std");

var log: bool = false;
pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const ally = gpa.allocator();

    const exa01 = try parse(ally, @embedFile("exa01.txt"));
    defer ally.free(exa01.valves);
    const input = try parse(ally, @embedFile("input.txt"));
    defer ally.free(input.valves);

    std.debug.print("Example Part 1: {d}\n", .{try part1(ally, exa01)});
    std.debug.print("Part 1: {d}\n", .{try part1(ally, input)});
    std.debug.print("Example Part 2: {d}\n", .{try part2(ally, exa01)});
    log = true;
    std.debug.print("Part 2: {d}\n", .{try part2(ally, input)});
}

fn parse(ally: std.mem.Allocator, input: []const u8) !Input {
    var names = std.StringHashMap(usize).init(ally);
    defer names.deinit();
    var aa_index: u16 = 0;

    var index: usize = 0;
    var lines = std.mem.tokenize(u8, input, "\r\n");
    while (lines.next()) |line| {
        const end = std.mem.indexOfScalarPos(u8, line, 6, ' ').?;
        const name = line[6..end];
        try names.put(name, index);
        if (std.mem.eql(u8, name, "AA"))
            aa_index = @intCast(index);
        index += 1;
    }

    var valves = try std.ArrayList(Valve).initCapacity(ally, names.count());
    errdefer valves.deinit();

    lines = std.mem.tokenize(u8, input, "\r\n");
    while (lines.next()) |line| {
        var i = std.mem.tokenize(u8, line[1..], "abcdefghijklmnopqrstuvwxyz =;,");

        _ = i.next().?;
        const flow = try std.fmt.parseInt(u16, i.next().?, 10);

        const valve: *Valve = valves.addOneAssumeCapacity();
        valve.* = .{ .flow = flow };

        while (i.next()) |tunnel|
            try valve.tunnels.append(@intCast(names.get(tunnel).?));
    }

    return Input{ .valves = try valves.toOwnedSlice(), .start = aa_index };
}

const Valve = struct {
    flow: u16,
    tunnels: std.BoundedArray(u16, 6) = .{},
};
const Position = struct {
    position: u16,
    elephant: u16 = 0,
    open: OpenSet,
    const OpenSet = std.StaticBitSet(64);
};
const BestPositionsMap = std.AutoHashMap(Position, u64);
const Input = struct {
    valves: []const Valve,
    start: u16,
};

fn part1(ally: std.mem.Allocator, input: Input) !u64 {
    var positions = BestPositionsMap.init(ally);
    defer positions.deinit();

    try positions.put(.{ .position = input.start, .open = Position.OpenSet.initEmpty() }, 0);

    for (0..30) |minute| {
        _ = minute;

        var next_positions = BestPositionsMap.init(ally);
        try next_positions.ensureTotalCapacity(positions.count());

        var i = positions.iterator();
        while (i.next()) |entry| {
            const position = entry.key_ptr.*;
            const total_flow = entry.value_ptr.*;

            const valve = input.valves[position.position];
            const new_total_flow = total_flow + calculateFlow(position, input.valves);

            if (!position.open.isSet(position.position) and valve.flow > 0) {
                var new_position = position;
                new_position.open.set(position.position);
                try putBestPosition(&next_positions, new_position, new_total_flow);
            }

            for (valve.tunnels.slice()) |tunnel| {
                var new_position = position;
                new_position.position = tunnel;
                try putBestPosition(&next_positions, new_position, new_total_flow);
            }
        }

        positions.deinit();
        positions = next_positions;
    }

    var best_flow: u64 = 0;
    var i = positions.valueIterator();
    while (i.next()) |flow| {
        if (flow.* > best_flow)
            best_flow = flow.*;
    }
    return best_flow;
}

fn part2(ally: std.mem.Allocator, input: Input) !u64 {
    var positions = BestPositionsMap.init(ally);
    defer positions.deinit();

    var partial_positions = std.ArrayList(struct { Position, u64 }).init(ally);
    defer partial_positions.deinit();

    var next_positions = BestPositionsMap.init(ally);
    defer next_positions.deinit();

    try positions.put(.{
        .position = input.start,
        .elephant = input.start,
        .open = Position.OpenSet.initEmpty(),
    }, 0);

    for (0..26) |minute| {
        if (log) std.debug.print(" == Minute {d}\n", .{minute + 1});

        partial_positions.clearRetainingCapacity();

        var entries = positions.iterator();
        while (entries.next()) |entry| {
            const position = entry.key_ptr.*;
            const total_flow = entry.value_ptr.*;

            const valve = input.valves[position.position];
            const new_total_flow = total_flow + calculateFlow(position, input.valves);

            if (!position.open.isSet(position.position) and valve.flow > 0) {
                var new_position = position;
                new_position.open.set(position.position);
                try partial_positions.append(.{ new_position, new_total_flow });
            }

            for (valve.tunnels.slice()) |tunnel| {
                var new_position = position;
                new_position.position = tunnel;
                try partial_positions.append(.{ new_position, new_total_flow });
            }
        }

        if (log) std.debug.print("    {d} partial_positions\n", .{partial_positions.items.len});

        next_positions.clearRetainingCapacity();

        for (partial_positions.items) |tuple| {
            const position = tuple[0];
            const total_flow = tuple[1];
            const valve = input.valves[position.elephant];

            if (!position.open.isSet(position.elephant) and valve.flow > 0) {
                var new_position = position;
                new_position.open.set(position.elephant);
                try putBestPosition(&next_positions, new_position, total_flow);
            }

            for (valve.tunnels.slice()) |tunnel| {
                var new_position = position;
                new_position.elephant = tunnel;
                try putBestPosition(&next_positions, new_position, total_flow);
            }
        }

        if (log) std.debug.print("    {d} next_positions\n", .{next_positions.count()});

        if (next_positions.count() > 10_000) {
            var highest: u64 = 0;
            var lowest: u64 = std.math.maxInt(u64);
            var values = next_positions.valueIterator();
            while (values.next()) |value| {
                highest = @max(highest, value.*);
                lowest = @min(lowest, value.*);
            }
            if (log) std.debug.print("    highest: {d}, lowest: {d}\n", .{ highest, lowest });

            positions.clearRetainingCapacity();
            var _entries = next_positions.iterator();
            while (_entries.next()) |entry| {
                if (highest * 3 / 4 <= entry.value_ptr.*) {
                    try positions.put(entry.key_ptr.*, entry.value_ptr.*);
                }
            }
        } else {
            std.mem.swap(BestPositionsMap, &positions, &next_positions);
        }
    }

    var best_flow: u64 = 0;
    var i = positions.valueIterator();
    while (i.next()) |flow| best_flow = @max(best_flow, flow.*);
    return best_flow;
}

fn calculateFlow(position: Position, valves: []const Valve) u64 {
    var flow: u64 = 0;
    var i = position.open.iterator(.{});
    while (i.next()) |index| {
        flow += valves[index].flow;
    }
    return flow;
}

fn putBestPosition(map: *BestPositionsMap, position: Position, total_flow: u64) !void {
    const entry = try map.getOrPut(position);
    if (!entry.found_existing or total_flow > entry.value_ptr.*) {
        entry.value_ptr.* = total_flow;
    }
}
