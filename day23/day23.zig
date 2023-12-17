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
};
const ElfPosition = [2]i64;
const SparseElves = std.AutoHashMap(ElfPosition, void);
const Box = struct { x0: i64, x1: i64, y0: i64, y1: i64 };
const all_directions: []const ElfPosition = &.{
    .{ 0, -1 },
    .{ 0, 1 },
    .{ 1, -1 },
    .{ 1, 0 },
    .{ 1, 1 },
    .{ -1, -1 },
    .{ -1, 0 },
    .{ -1, 1 },
};
const north_directions: []const ElfPosition = &.{ .{ 0, -1 }, .{ 1, -1 }, .{ -1, -1 } };
const south_directions: []const ElfPosition = &.{ .{ 0, 1 }, .{ 1, 1 }, .{ -1, 1 } };
const west_directions: []const ElfPosition = &.{ .{ -1, 0 }, .{ -1, -1 }, .{ -1, 1 } };
const east_directions: []const ElfPosition = &.{ .{ 1, 0 }, .{ 1, -1 }, .{ 1, 1 } };

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

    return Input{ .cells = try cells.toOwnedSlice(), .w = @intCast(w), .h = @intCast(h) };
}

fn part1(ally: std.mem.Allocator, input: Input) !u64 {
    return (try process(ally, input, 10)).floor_tiles;
}

fn part2(ally: std.mem.Allocator, input: Input) !u64 {
    return (try process(ally, input, null)).rounds;
}

const ProcessResult = struct { rounds: u64, floor_tiles: u64 };
fn process(ally: std.mem.Allocator, input: Input, stop_at_round: ?u64) !ProcessResult {
    var elves = try sparseElves(ally, input);
    defer elves.deinit();

    var next_elves = SparseElves.init(ally);
    defer next_elves.deinit();
    try next_elves.ensureTotalCapacity(elves.count());

    var proposals = std.AutoHashMap(ElfPosition, u16).init(ally);
    defer proposals.deinit();

    var cardinal_directions = std.BoundedArray([]const ElfPosition, 4){};
    cardinal_directions.appendAssumeCapacity(north_directions);
    cardinal_directions.appendAssumeCapacity(south_directions);
    cardinal_directions.appendAssumeCapacity(west_directions);
    cardinal_directions.appendAssumeCapacity(east_directions);

    if (debug) {
        const stdout = std.io.getStdOut().writer();
        try stdout.print("== Initial State ==\n", .{});
        try printElves(elves, stdout);
    }

    var round: u64 = 1;
    while (true) : (round += 1) {
        proposals.clearRetainingCapacity();

        var keys = elves.keyIterator();
        while (keys.next()) |elf| {
            if (elfNextPosition(elf.*, elves, cardinal_directions.slice())) |elf_next| {
                const entry = try proposals.getOrPut(elf_next);
                if (!entry.found_existing)
                    entry.value_ptr.* = 0;
                entry.value_ptr.* += 1;
            }
        }

        var elves_that_moved_this_round: u64 = 0;
        next_elves.clearRetainingCapacity();

        keys = elves.keyIterator();
        while (keys.next()) |elf| {
            var elf_next = elf.*;
            if (elfNextPosition(elf.*, elves, cardinal_directions.slice())) |possible_elf_next| {
                if (proposals.get(possible_elf_next).? == 1) {
                    elf_next = possible_elf_next;
                    elves_that_moved_this_round += 1;
                }
            }
            try next_elves.put(elf_next, {});
        }

        std.debug.assert(next_elves.count() == elves.count());
        std.mem.swap(SparseElves, &elves, &next_elves);

        if (debug) {
            const stdout = std.io.getStdOut().writer();
            try stdout.print("== End of Round {d} ==\n", .{round});
            try printElves(elves, stdout);
        }

        cardinal_directions.appendAssumeCapacity(cardinal_directions.orderedRemove(0));

        if (stop_at_round) |sar| {
            if (round == sar)
                break;
        }
        if (elves_that_moved_this_round == 0)
            break;
    }

    const box = elvesBoundingBox(elves);
    const floor_tiles = (box.x1 - box.x0 + 1) * (box.y1 - box.y0 + 1) - elves.count();
    return .{ .rounds = round, .floor_tiles = @intCast(floor_tiles) };
}

fn sparseElves(ally: std.mem.Allocator, input: Input) !SparseElves {
    var elves = SparseElves.init(ally);
    errdefer elves.deinit();
    for (0..input.h) |y| {
        for (0..input.w) |x| {
            if (input.cells[y * input.w + x] == '#') {
                try elves.put(ElfPosition{ @intCast(x), @intCast(y) }, {});
            }
        }
    }
    return elves;
}

fn elfNextPosition(
    elf: ElfPosition,
    elves: SparseElves,
    cardinal_directions: []const []const ElfPosition,
) ?ElfPosition {
    for (all_directions) |d| {
        if (elves.contains(.{ elf[0] + d[0], elf[1] + d[1] }))
            break;
    } else return null;

    cardinal_checks: for (cardinal_directions) |directions| {
        for (directions) |d| {
            if (elves.contains(.{ elf[0] + d[0], elf[1] + d[1] }))
                continue :cardinal_checks;
        }

        const d = directions[0];
        return .{ elf[0] + d[0], elf[1] + d[1] };
    }

    return null;
}

fn printElves(elves: SparseElves, out: anytype) !void {
    var stdout = std.io.bufferedWriter(out);
    const box = elvesBoundingBox(elves);
    const w: usize = @intCast(box.x1 - box.x0 + 1);
    const h: usize = @intCast(box.y1 - box.y0 + 1);
    for (0..h) |y| {
        for (0..w) |x| {
            const elfx = @as(i64, @intCast(x)) + box.x0;
            const elfy = @as(i64, @intCast(y)) + box.y0;
            try stdout.writer().writeByte(if (elves.contains(.{ elfx, elfy })) '#' else '.');
        }
        try stdout.writer().writeByte('\n');
    }
    try stdout.flush();
}

fn elvesBoundingBox(elves: SparseElves) Box {
    var x0: i64 = std.math.maxInt(i64);
    var x1: i64 = std.math.minInt(i64);
    var y0: i64 = std.math.maxInt(i64);
    var y1: i64 = std.math.minInt(i64);
    var keys = elves.keyIterator();
    while (keys.next()) |elf| {
        x0 = @min(x0, elf[0]);
        x1 = @max(x1, elf[0]);
        y0 = @min(y0, elf[1]);
        y1 = @max(y1, elf[1]);
    }
    std.debug.assert(x1 > x0 and y1 > y0);
    return .{ .x0 = x0, .x1 = x1, .y0 = y0, .y1 = y1 };
}
