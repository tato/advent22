const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const ally = gpa.allocator();

    const exa01_blueprints = try parseBlueprints(ally, @embedFile("exa01.txt"));
    const input_blueprints = try parseBlueprints(ally, @embedFile("input.txt"));

    std.debug.print("Example Part 1: {d}\n", .{try part1(ally, exa01_blueprints)});
    std.debug.print("Part 1: {d}\n", .{try part1(ally, input_blueprints)});
    std.debug.print("Part 2: {d}\n", .{try part2(ally, input_blueprints)});
}

fn part1(ally: std.mem.Allocator, blueprints: []const Blueprint) !u64 {
    var total_quality_level: u64 = 0;
    for (blueprints) |*blueprint| {
        const max_geodes = try maxGeodes(ally, blueprint, 24);
        total_quality_level += blueprint.id * max_geodes;
    }
    return total_quality_level;
}

fn part2(ally: std.mem.Allocator, blueprints: []const Blueprint) !u64 {
    var total_value: u64 = 1;
    for (blueprints[0..3]) |*blueprint| {
        const max_geodes = try maxGeodes(ally, blueprint, 32);
        total_value *= max_geodes;
    }
    return total_value;
}

const Blueprint = struct {
    id: u32,
    ore_robot_cost: u32,
    clay_robot_cost: u32,
    obsidian_robot_ore_cost: u32,
    obsidian_robot_clay_cost: u32,
    geode_robot_ore_cost: u32,
    geode_robot_obsidian_cost: u32,
    max_ore_cost: u32,
};

fn parseBlueprints(ally: std.mem.Allocator, input: []const u8) ![]const Blueprint {
    var blueprints = std.ArrayList(Blueprint).init(ally);

    var i = std.mem.tokenize(u8, input, "\n");
    while (i.next()) |blueprint_line| {
        const blueprint = try blueprints.addOne();

        var ni = std.mem.tokenize(u8, blueprint_line, "BE:. abcdefghijklmnopqrstuvwxyz");
        blueprint.id = try std.fmt.parseInt(u32, ni.next().?, 10);
        blueprint.ore_robot_cost = try std.fmt.parseInt(u32, ni.next().?, 10);
        blueprint.clay_robot_cost = try std.fmt.parseInt(u32, ni.next().?, 10);
        blueprint.obsidian_robot_ore_cost = try std.fmt.parseInt(u32, ni.next().?, 10);
        blueprint.obsidian_robot_clay_cost = try std.fmt.parseInt(u32, ni.next().?, 10);
        blueprint.geode_robot_ore_cost = try std.fmt.parseInt(u32, ni.next().?, 10);
        blueprint.geode_robot_obsidian_cost = try std.fmt.parseInt(u32, ni.next().?, 10);
        blueprint.max_ore_cost = @max(
            blueprint.ore_robot_cost,
            blueprint.clay_robot_cost,
            blueprint.obsidian_robot_ore_cost,
            blueprint.geode_robot_ore_cost,
        );
    }

    return try blueprints.toOwnedSlice();
}

const Operation = struct {
    ore: u32 = 0,
    ore_robots: u32 = 1,
    clay: u32 = 0,
    clay_robots: u32 = 0,
    obsidian: u32 = 0,
    obsidian_robots: u32 = 0,
    geodes: u32 = 0,
    geode_robots: u32 = 0,
};

const OperationSet = std.AutoHashMap(Operation, void);

fn maxGeodes(
    ally: std.mem.Allocator,
    blueprint: *const Blueprint,
    minute_limit: u32,
) !u64 {
    var operations = OperationSet.init(ally);
    try operations.put(Operation{}, {});

    var minutes: u64 = 1;
    while (minutes <= minute_limit) : (minutes += 1) {
        var geodes: u32 = 0;
        var keys = operations.keyIterator();
        while (keys.next()) |operation|
            geodes = @max(operation.geodes, geodes);

        var next_minute_operations = OperationSet.init(ally);
        keys = operations.keyIterator();
        while (keys.next()) |operation| {
            try minute(blueprint, operation, &next_minute_operations, geodes);
        }

        operations.deinit();
        operations = next_minute_operations;
    }

    var geodes: u64 = 0;
    var keys = operations.keyIterator();
    while (keys.next()) |operation|
        geodes = @max(operation.geodes, geodes);
    return geodes;
}

fn minute(
    blueprint: *const Blueprint,
    operation: *const Operation,
    operations: *OperationSet,
    beat_geodes: u32,
) !void {
    var mined_operation = operation.*;
    mined_operation.ore += mined_operation.ore_robots;
    mined_operation.clay += mined_operation.clay_robots;
    mined_operation.obsidian += mined_operation.obsidian_robots;
    mined_operation.geodes += mined_operation.geode_robots;

    if (mined_operation.geodes < beat_geodes) {
        return;
    }

    try operations.put(mined_operation, {});

    if (operation.ore_robots < blueprint.max_ore_cost and
        operation.ore >= blueprint.ore_robot_cost)
    {
        var op = mined_operation;
        op.ore_robots += 1;
        op.ore -= blueprint.ore_robot_cost;
        try operations.put(op, {});
    }
    if (operation.clay_robots < blueprint.obsidian_robot_clay_cost and
        operation.ore >= blueprint.clay_robot_cost)
    {
        var op = mined_operation;
        op.clay_robots += 1;
        op.ore -= blueprint.clay_robot_cost;
        try operations.put(op, {});
    }
    if (operation.obsidian_robots < blueprint.geode_robot_obsidian_cost and
        operation.ore >= blueprint.obsidian_robot_ore_cost and
        operation.clay >= blueprint.obsidian_robot_clay_cost)
    {
        var op = mined_operation;
        op.obsidian_robots += 1;
        op.ore -= blueprint.obsidian_robot_ore_cost;
        op.clay -= blueprint.obsidian_robot_clay_cost;
        try operations.put(op, {});
    }
    if (operation.ore >= blueprint.geode_robot_ore_cost and
        operation.obsidian >= blueprint.geode_robot_obsidian_cost)
    {
        var op = mined_operation;
        op.geode_robots += 1;
        op.ore -= blueprint.geode_robot_ore_cost;
        op.obsidian -= blueprint.geode_robot_obsidian_cost;
        try operations.put(op, {});
    }
}
