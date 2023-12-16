const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const ally = gpa.allocator();

    const exa01 = try parse(ally, @embedFile("exa01.txt"));
    defer ally.free(exa01.monkeys);
    const input = try parse(ally, @embedFile("input.txt"));
    defer ally.free(input.monkeys);

    std.debug.print("Example Part 1: {d}\n", .{part1(exa01)});
    std.debug.print("Part 1: {d}\n", .{part1(input)});
    std.debug.print("Example Part 2: {d}\n", .{part2(exa01)});
    std.debug.print("Part 2: {d}\n", .{part2(input)});
}

const Input = struct {
    monkeys: []Monkey,
    root: usize,
    humn: usize,
};
const Monkey = struct {
    op: Op,
    lhs: i64,
    rhs: i64,
    res: i64 = undefined,
    human: bool = undefined,
    calculated: bool = false,
};
const Op = enum { lit, add, sub, mul, div };

fn parse(ally: std.mem.Allocator, input: []const u8) !Input {
    var names = std.StringHashMap(usize).init(ally);
    defer names.deinit();
    var root_index: usize = 0;
    var humn_index: usize = 0;

    var index: usize = 0;
    var lines = std.mem.tokenize(u8, input, "\r\n");
    while (lines.next()) |line| {
        var split = std.mem.split(u8, line, ":");
        const name = split.first();
        try names.put(name, index);
        if (std.mem.eql(u8, "root", name)) root_index = index;
        if (std.mem.eql(u8, "humn", name)) humn_index = index;
        index += 1;
    }

    var monkeys = try std.ArrayList(Monkey).initCapacity(ally, names.count());
    errdefer monkeys.deinit();

    lines = std.mem.tokenize(u8, input, "\r\n");
    while (lines.next()) |line| {
        var split = std.mem.tokenize(u8, line, ": ");
        _ = split.next().?;
        const lhs = split.next().?;
        if (std.ascii.isDigit(lhs[0])) {
            monkeys.appendAssumeCapacity(.{
                .op = .lit,
                .lhs = try std.fmt.parseInt(i64, lhs, 10),
                .rhs = 0,
            });
        } else {
            const op: Op = switch (split.next().?[0]) {
                '+' => .add,
                '-' => .sub,
                '*' => .mul,
                '/' => .div,
                else => @panic("unknown"),
            };
            monkeys.appendAssumeCapacity(.{
                .op = op,
                .lhs = @intCast(names.get(lhs).?),
                .rhs = @intCast(names.get(split.next().?).?),
            });
        }
    }

    return Input{
        .monkeys = try monkeys.toOwnedSlice(),
        .root = root_index,
        .humn = humn_index,
    };
}

fn part1(input: Input) i64 {
    return calculate(input, input.root).res;
}

fn part2(input: Input) i64 {
    const root = input.monkeys[input.root];
    const lhs = calculate(input, @intCast(root.lhs));
    const rhs = calculate(input, @intCast(root.rhs));
    if (lhs.human) {
        return solve(input, @intCast(root.lhs), rhs.res);
    } else {
        return solve(input, @intCast(root.rhs), lhs.res);
    }
}

fn calculate(input: Input, index: usize) *const Monkey {
    const monkey = &input.monkeys[index];
    if (!monkey.calculated) {
        monkey.calculated = true;
        if (monkey.op == .lit) {
            monkey.res = monkey.lhs;
            monkey.human = index == input.humn;
        } else {
            const lhs = calculate(input, @intCast(monkey.lhs));
            const rhs = calculate(input, @intCast(monkey.rhs));
            monkey.human = lhs.human or rhs.human;
            monkey.res = switch (monkey.op) {
                .lit => unreachable,
                .add => lhs.res + rhs.res,
                .sub => lhs.res - rhs.res,
                .mul => lhs.res * rhs.res,
                .div => @divFloor(lhs.res, rhs.res),
            };
        }
    }
    return monkey;
}

fn solve(input: Input, index: usize, equals: i64) i64 {
    if (input.humn == index)
        return equals;

    const monkey = input.monkeys[index];
    const lhs = calculate(input, @intCast(monkey.lhs));
    const rhs = calculate(input, @intCast(monkey.rhs));
    if (lhs.human) {
        return solve(input, @intCast(monkey.lhs), switch (monkey.op) {
            .lit => unreachable,
            .add => equals - rhs.res,
            .sub => equals + rhs.res,
            .mul => @divFloor(equals, rhs.res),
            .div => equals * rhs.res,
        });
    } else {
        return solve(input, @intCast(monkey.rhs), switch (monkey.op) {
            .lit => unreachable,
            .add => equals - lhs.res,
            .sub => lhs.res - equals,
            .mul => @divFloor(equals, lhs.res),
            .div => @divFloor(lhs.res, equals),
        });
    }
}
