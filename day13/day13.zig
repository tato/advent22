const std = @import("std");

fn solve(input: []const u8) !void {
    var packets = std.ArrayList([]const Elem).init(gpa.allocator());

    var pair_index: u32 = 1;
    var pair_index_sum: u32 = 0;

    var i = std.mem.tokenize(u8, input, " \n");
    while (i.next()) |top_line| {
        defer pair_index += 1;

        const top = try parse(top_line);
        const bot = try parse(i.next().?);

        switch (orderPackets(top, bot)) {
            .lt => pair_index_sum += pair_index,
            .gt => {},
            .eq => unreachable,
        }

        try packets.append(top);
        try packets.append(bot);
    }

    const divider_top = try parse("[[2]]");
    const divider_bot = try parse("[[6]]");

    try packets.append(divider_top);
    try packets.append(divider_bot);

    std.sort.sort([]const Elem, packets.items, {}, packetsLessThan);

    var decoder_key: usize = 1;
    for (packets.items) |packet, index| {
        if (orderPackets(divider_top, packet) == .eq)
            decoder_key *= (index + 1);
        if (orderPackets(divider_bot, packet) == .eq)
            decoder_key *= (index + 1);
    }

    std.debug.print("Index Sum: {d}, Decoder Key: {d}\n", .{ pair_index_sum, decoder_key });
}

const Elem = union(enum) {
    integer: u32,
    list: []const Elem,
};

fn parse(input: []const u8) ![]const Elem {
    var current: usize = 1;
    return parseList(input, &current);
}

fn parseList(input: []const u8, current: *usize) ![]const Elem {
    var list = std.ArrayList(Elem).init(gpa.allocator());

    while (input[current.*] != ']') {
        if (input[current.*] == '[') {
            current.* += 1;
            try list.append(Elem{ .list = try parseList(input, current) });
        } else if (std.ascii.isDigit(input[current.*])) {
            var start = current.*;
            while (std.ascii.isDigit(input[current.*]))
                current.* += 1;
            const n = try std.fmt.parseInt(u32, input[start..current.*], 10);
            try list.append(Elem{ .integer = n });
        }

        if (input[current.*] == ',')
            current.* += 1;
    }

    current.* += 1;

    return try list.toOwnedSlice();
}

fn orderPackets(top_list: []const Elem, bot_list: []const Elem) std.math.Order {
    const len = @min(top_list.len, bot_list.len);

    for (top_list[0..len]) |*top_elem, index| {
        const bot_elem = &bot_list[index];

        if (top_elem.* == .integer and bot_elem.* == .integer) {
            switch (std.math.order(top_elem.integer, bot_elem.integer)) {
                .lt, .gt => |o| return o,
                .eq => {},
            }
        } else if (top_elem.* == .list and bot_elem.* == .list) {
            switch (orderPackets(top_elem.list, bot_elem.list)) {
                .lt, .gt => |o| return o,
                .eq => {},
            }
        } else {
            const integer_elem = if (top_elem.* == .integer) top_elem else bot_elem;
            const transformed = [1]Elem{.{ .integer = integer_elem.integer }};

            const new_izq_list = if (top_elem.* == .list) top_elem.list else &transformed;
            const new_der_list = if (bot_elem.* == .list) bot_elem.list else &transformed;

            switch (orderPackets(new_izq_list, new_der_list)) {
                .lt, .gt => |o| return o,
                .eq => {},
            }
        }
    }

    return if (top_list.len < bot_list.len) .lt else if (top_list.len > bot_list.len) .gt else .eq;
}

fn packetsLessThan(context: void, top: []const Elem, bot: []const Elem) bool {
    _ = context;
    return orderPackets(top, bot) == .lt;
}

var gpa = std.heap.GeneralPurposeAllocator(.{}){};

test "solve" {
    try solve(@embedFile("input.txt"));
}

test "exa01" {
    try solve(@embedFile("exa01.txt"));
}

test "test" {
    const l = try parse("[[4,4],4,4]");
    const r = try parse("[[4,4],4,4,4]");
    try std.testing.expect(orderPackets(l, r) == .lt);
}
