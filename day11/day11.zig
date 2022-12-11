const std = @import("std");

fn solve(input: []const u8) !void {
    const calm = try solveMode(input, .calm);
    const chaos = try solveMode(input, .chaos);

    std.debug.print("Calm Monkey Business: {d}, Chaos Monkey Business: {d}\n", .{ calm, chaos });
}

fn solveMode(input: []const u8, mode: MonkeyMode) !i64 {
    const monkeys = try parseMonkeys(input);

    var max_test_div: i64 = 1;
    for (monkeys) |monkey|
        max_test_div *= monkey.test_div;

    var round: usize = 0;
    const max_rounds: usize = if (mode == .calm) 20 else 10_000;
    while (round < max_rounds) : (round += 1) {
        for (monkeys) |*monkey| {
            try monkeyTurn(monkey, monkeys, mode, max_test_div);
        }
    }

    var monkey_biggest = [2]i64{ 0, 0 };
    for (monkeys) |monkey| {
        if (monkey.inspects_count > monkey_biggest[0]) {
            monkey_biggest[0] = @min(monkey.inspects_count, monkey_biggest[1]);
            monkey_biggest[1] = @max(monkey.inspects_count, monkey_biggest[1]);
        }
    }

    return monkey_biggest[0] * monkey_biggest[1];
}

const Monkey = struct {
    items: std.ArrayList(i64),
    op_is_mul: bool = false,
    operand: ?i64 = null,
    test_div: i64 = 0,
    if_true: i64 = 0,
    if_false: i64 = 0,
    inspects_count: i64 = 0,
};

fn parseMonkeys(input: []const u8) ![]Monkey {
    var monkeys = std.ArrayList(Monkey).init(gpa.allocator());

    var i = std.mem.tokenize(u8, input, "\n");
    while (i.next()) |monkey_line| {
        _ = monkey_line;

        const monkey = try monkeys.addOne();
        monkey.* = .{ .items = std.ArrayList(i64).init(gpa.allocator()) };

        const items_line = i.next().?;
        var items_i = std.mem.tokenize(u8, items_line, "Starngiems:, ");
        while (items_i.next()) |item| {
            const worry = try std.fmt.parseInt(i64, item, 10);
            try monkey.items.append(worry);
        }

        const op_line = i.next().?;
        switch (op_line["  Operation: new = old ".len]) {
            '+' => monkey.op_is_mul = false,
            '*' => monkey.op_is_mul = true,
            else => unreachable,
        }
        const operand = op_line["  Operation: new = old % ".len..];
        if (!std.mem.eql(u8, operand, "old")) {
            monkey.operand = try std.fmt.parseInt(i64, operand, 10);
        }

        const test_line = i.next().?;
        const test_div = test_line["  Test: divisible by ".len..];
        monkey.test_div = try std.fmt.parseInt(i64, test_div, 10);

        const if_true_line = i.next().?;
        const if_true = if_true_line["    If true: throw to monkey ".len..];
        monkey.if_true = try std.fmt.parseInt(i64, if_true, 10);

        const if_false_line = i.next().?;
        const if_false = if_false_line["    If false: throw to monkey ".len..];
        monkey.if_false = try std.fmt.parseInt(i64, if_false, 10);
    }

    return monkeys.toOwnedSlice();
}

const MonkeyMode = enum { calm, chaos };

fn monkeyTurn(monkey: *Monkey, monkeys: []Monkey, mode: MonkeyMode, max_test_div: i64) !void {
    while (monkey.items.items.len > 0) {
        var worry = monkey.items.orderedRemove(0);

        const operand = monkey.operand orelse worry;
        if (monkey.op_is_mul) worry *= operand else worry += operand;

        monkey.inspects_count += 1;

        if (mode == .calm) {
            worry = @divFloor(worry, 3);
        } else {
            worry = @rem(worry, max_test_div);
        }

        const test_div = @rem(worry, monkey.test_div) == 0;
        const next_monkey = if (test_div) monkey.if_true else monkey.if_false;

        try monkeys[@intCast(usize, next_monkey)].items.append(worry);
    }
}

var gpa = std.heap.GeneralPurposeAllocator(.{}){};

test "solve" {
    try solve(@embedFile("input.txt"));
}

test "exa01" {
    try solve(@embedFile("exa01.txt"));
}
