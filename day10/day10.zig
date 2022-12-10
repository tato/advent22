const std = @import("std");

fn solve(input: []const u8) !void {
    var signal: i64 = 0;
    var register: i64 = 1;
    var cycle: i64 = 1;
    var screen = std.mem.zeroes(ScreenArray);

    var i = std.mem.tokenize(u8, input, "\n");
    while (i.next()) |instr| {
        addSignal(&signal, cycle, register);
        drawRegisterToScreen(&screen, cycle, register);

        if (std.mem.eql(u8, instr, "noop")) {
            cycle += 1;
        }
        if (std.mem.startsWith(u8, instr, "addx")) {
            drawRegisterToScreen(&screen, cycle + 1, register);
            addSignal(&signal, cycle + 1, register);
            register += try std.fmt.parseInt(i64, instr[5..], 10);
            cycle += 2;
        }
    }

    std.debug.print("Signal: {d}\n", .{signal});
    drawScreen(&screen);
}

const screen_width = 40;
const screen_height = 6;
const ScreenArray = [screen_width * screen_height]bool;

fn addSignal(signal: *i64, cycle: i64, register: i64) void {
    if (@mod(cycle - 20, 40) == 0) {
        signal.* += cycle * register;
    }
}

fn drawRegisterToScreen(screen: *ScreenArray, cycle: i64, register: i64) void {
    const x = @mod(cycle - 1, screen_width);
    if (x == register or x == register - 1 or x == register + 1) {
        screen[@intCast(usize, cycle - 1)] = true;
    }
}

fn drawScreen(screen: *const ScreenArray) void {
    var y: usize = 0;
    while (y < screen_height) : (y += 1) {
        var x: usize = 0;
        while (x < screen_width) : (x += 1) {
            if (screen[y * screen_width + x]) {
                std.debug.print("#", .{});
            } else {
                std.debug.print(" ", .{});
            }
        }
        std.debug.print("\n", .{});
    }
}

test "solve" {
    try solve(@embedFile("input.txt"));
}

test "exa01" {
    try solve(@embedFile("exa01.txt"));
}
