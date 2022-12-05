const std = @import("std");

const Stack = std.ArrayList(u8);

fn solve(
    input: []const u8,
    comptime moveFn: fn (*Stack, *Stack, u32) anyerror!void,
) !void {
    var stacks = std.ArrayList(Stack).init(gpa.allocator());

    var i = std.mem.split(u8, input, "\n");
    while (i.next()) |stack_level| {
        if (stack_level.len == 0) break;

        var index: usize = 1;
        while (index < stack_level.len) : (index += 4) {
            const stack_index = (index - 1) / 4;
            if (stacks.items.len <= stack_index) {
                try stacks.appendNTimes(
                    Stack.init(gpa.allocator()),
                    stack_index - stacks.items.len + 1,
                );
            }

            if (std.ascii.isUpper(stack_level[index])) {
                try stacks.items[stack_index].insert(0, stack_level[index]);
            }
        }
    }

    while (i.next()) |cmd| {
        var cmd_tokens = std.mem.tokenize(u8, cmd, " ");
        if (cmd.len == 0) continue;

        _ = cmd_tokens.next();
        const amount = try std.fmt.parseInt(u32, cmd_tokens.next().?, 10);
        _ = cmd_tokens.next();
        const src_stack = try std.fmt.parseInt(u32, cmd_tokens.next().?, 10) - 1;
        _ = cmd_tokens.next();
        const dst_stack = try std.fmt.parseInt(u32, cmd_tokens.next().?, 10) - 1;

        try moveFn(&stacks.items[src_stack], &stacks.items[dst_stack], amount);
    }

    for (stacks.items) |stack| {
        std.debug.print("{c}", .{stack.items[stack.items.len - 1]});
    }
    std.debug.print("\n", .{});
}

fn moveOneByOne(src_stack: *Stack, dst_stack: *Stack, _amount: u32) !void {
    var amount = _amount;
    while (amount > 0) : (amount -= 1) {
        const crate = src_stack.pop();
        try dst_stack.append(crate);
    }
}

fn moveMany(src_stack: *Stack, dst_stack: *Stack, amount: u32) !void {
    dst_stack.appendSlice(src_stack.items[src_stack.items.len - amount ..]);
    src_stack.shrinkRetainingCapacity(src_stack.items.len - amount);
}

var gpa = std.heap.GeneralPurposeAllocator(.{}){};

test "input a" {
    try solve(@embedFile("input.txt"), moveOneByOne);
}

test "input b" {
    try solve(@embedFile("input.txt"), moveMany);
}
