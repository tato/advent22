const std = @import("std");

fn findPacketMarker(signal: []const u8) !u32 {
    return findAnyMarker(4, signal);
}

fn findMessageMarker(signal: []const u8) !u32 {
    return findAnyMarker(14, signal);
}

fn findAnyMarker(comptime marker_len: u32, signal: []const u8) !u32 {
    if (signal.len < marker_len) return error.stream_too_short;

    for (signal[marker_len - 1 ..]) |_, index| {
        if (checkMarker(marker_len, signal[index .. index + marker_len][0..marker_len]))
            return @truncate(u32, index + marker_len);
    }

    return error.no_signal_marker;
}

fn checkMarker(comptime magic_len: u32, signal: *const [magic_len]u8) bool {
    for (signal[0 .. signal.len - 1]) |current_signal, index| {
        for (signal[index + 1 ..]) |other_signal| {
            if (current_signal == other_signal)
                return false;
        }
    } else return true;
}

test {
    const packet_index = try findPacketMarker(@embedFile("input.txt"));
    const message_index = try findMessageMarker(@embedFile("input.txt"));
    std.debug.print("Packet: {d}, Message: {d}\n", .{ packet_index, message_index });
}
