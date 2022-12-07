const std = @import("std");

fn solve(input: []const u8) !void {
    const root = try Directory.create();
    var current = root;

    var i = std.mem.tokenize(u8, input, "\n");
    _ = i.next(); // skip $ cd /

    while (i.next()) |line| {
        var split = std.mem.split(u8, line[2..], " ");
        const cmd = split.first();
        const arg = split.rest();
        if (std.mem.eql(u8, "cd", cmd)) {
            if (std.mem.eql(u8, "..", arg)) {
                current = current.parent.?;
            } else {
                const parent = current;
                current = current.children.get(arg).?;
                current.parent = parent;
            }
        } else if (std.mem.eql(u8, "ls", cmd)) {
            while (i.rest().len > 0 and i.rest()[0] != '$') {
                var entry = std.mem.split(u8, i.next().?, " ");
                const kind = entry.first();
                const name = entry.rest();
                if (std.mem.eql(u8, "dir", kind)) {
                    try current.children.put(gpa.allocator(), name, try Directory.create());
                } else {
                    try current.files.append(gpa.allocator(), try std.fmt.parseInt(u64, kind, 10));
                }
            }
        } else @panic("Unknown command");
    }

    _ = walkSizes(root);
    const sum_sizes_result = sumSizes(root);

    const minimum_delete_size = minimum_unused_space - (total_disk_space - root.size);
    const delete_result = delete(root, minimum_delete_size);

    std.debug.print("Sum: {d}, Delete: {d}\n", .{ sum_sizes_result, delete_result });
}

const maximum_directory_size = 100000;
const total_disk_space = 70000000;
const minimum_unused_space = 30000000;

const Directory = struct {
    files: std.ArrayListUnmanaged(u64) = .{},
    children: std.StringHashMapUnmanaged(*Directory) = .{},
    parent: ?*Directory = null,
    size: u64 = 0,

    fn create() !*Directory {
        const d = try gpa.allocator().create(Directory);
        d.* = .{};
        return d;
    }
};

fn walkSizes(d: *Directory) u64 {
    for (d.files.items) |file_size| {
        d.size += file_size;
    }
    var i = d.children.valueIterator();
    while (i.next()) |child| {
        d.size += walkSizes(child.*);
    }
    return d.size;
}

fn sumSizes(d: *Directory) u64 {
    var result: u64 = 0;
    if (d.size <= maximum_directory_size) {
        result += d.size;
    }
    var i = d.children.valueIterator();
    while (i.next()) |child| {
        result += sumSizes(child.*);
    }
    return result;
}

fn delete(d: *Directory, minimum_delete_size: u64) u64 {
    var result: u64 = total_disk_space;

    if (d.size > minimum_delete_size and d.size < result) {
        result = d.size;
    }

    var i = d.children.valueIterator();
    while (i.next()) |child| {
        const child_delete = delete(child.*, minimum_delete_size);
        if (child_delete > minimum_delete_size and child_delete < result) {
            result = child_delete;
        }
    }

    return result;
}

var gpa = std.heap.GeneralPurposeAllocator(.{}){};

test "input" {
    try solve(@embedFile("input.txt"));
}
