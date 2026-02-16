const std = @import("std");
const Allocator = std.mem.Allocator;
const project_tmpl = @import("../templates/project.zig");

/// `zzz new <name>` -- scaffold a new zzz project.
pub fn run(args: []const []const u8, _: Allocator, io: std.Io) void {
    const stdout_file = std.Io.File.stdout();
    const stderr_file = std.Io.File.stderr();

    if (args.len < 1) {
        stderr_file.writeStreamingAll(io, "Usage: zzz new <project_name>\n") catch {};
        return;
    }

    const name = args[0];

    // Validate name
    for (name) |c| {
        if (!std.ascii.isAlphanumeric(c) and c != '_' and c != '-') {
            var err_buf: [256]u8 = undefined;
            const msg = std.fmt.bufPrint(&err_buf, "Invalid project name: '{s}'. Use only letters, numbers, underscores, and hyphens.\n", .{name}) catch "Invalid project name.\n";
            stderr_file.writeStreamingAll(io, msg) catch {};
            return;
        }
    }

    // Create directory structure
    makeDir(name, io) catch |err| {
        var err_buf: [256]u8 = undefined;
        const msg = std.fmt.bufPrint(&err_buf, "Failed to create directory '{s}': {}\n", .{ name, err }) catch "Failed to create directory.\n";
        stderr_file.writeStreamingAll(io, msg) catch {};
        return;
    };
    makeDirPath(name, "src", io) catch return;
    makeDirPath(name, "src/controllers", io) catch return;
    makeDirPath(name, "templates", io) catch return;
    makeDirPath(name, "public", io) catch return;
    makeDirPath(name, "public/css", io) catch return;
    makeDirPath(name, "public/js", io) catch return;

    // Write build.zig (replace $NAME$ with actual name)
    const build_str = project_tmpl.build_zig;
    if (std.mem.indexOf(u8, build_str, "$NAME$")) |idx| {
        var build_buf: [4096]u8 = undefined;
        const before = build_str[0..idx];
        const after = build_str[idx + 6 ..];
        var pos: usize = 0;
        @memcpy(build_buf[pos..][0..before.len], before);
        pos += before.len;
        @memcpy(build_buf[pos..][0..name.len], name);
        pos += name.len;
        @memcpy(build_buf[pos..][0..after.len], after);
        pos += after.len;
        writeFilePath(name, "build.zig", build_buf[0..pos], io) catch return;
    } else {
        writeFilePath(name, "build.zig", build_str, io) catch return;
    }

    // Write build.zig.zon
    var zon_buf: [2048]u8 = undefined;
    if (project_tmpl.buildZigZon(name, &zon_buf)) |content| {
        writeFilePath(name, "build.zig.zon", content, io) catch return;
    }

    // Write src/main.zig
    writeFilePath(name, "src/main.zig", project_tmpl.main_zig, io) catch return;

    // Write .gitignore
    writeFilePath(name, ".gitignore", project_tmpl.gitignore, io) catch return;

    // Write public/css/style.css
    writeFilePath(name, "public/css/style.css", project_tmpl.style_css, io) catch return;

    // Write public/js/app.js
    writeFilePath(name, "public/js/app.js", "// Add your JavaScript here\n", io) catch return;

    var msg_buf: [512]u8 = undefined;
    const msg = std.fmt.bufPrint(&msg_buf,
        \\
        \\  Created new zzz project: {s}
        \\
        \\  To get started:
        \\    cd {s}
        \\    zig build run
        \\
        \\  Then visit http://127.0.0.1:4000
        \\
    , .{ name, name }) catch "  Project created.\n";
    stdout_file.writeStreamingAll(io, msg) catch {};
}

fn makeDir(name: []const u8, io: std.Io) !void {
    var path_buf: [512]u8 = undefined;
    const path = std.fmt.bufPrint(&path_buf, "{s}", .{name}) catch return error.NameTooLong;
    std.Io.Dir.cwd().createDir(io, path, .default_dir) catch |err| {
        return err;
    };
}

fn makeDirPath(base: []const u8, sub: []const u8, io: std.Io) !void {
    var path_buf: [512]u8 = undefined;
    const path = std.fmt.bufPrint(&path_buf, "{s}/{s}", .{ base, sub }) catch return error.NameTooLong;
    std.Io.Dir.cwd().createDirPath(io, path) catch |err| {
        return err;
    };
}

fn writeFilePath(base: []const u8, sub_path: []const u8, content: []const u8, io: std.Io) !void {
    var path_buf: [512]u8 = undefined;
    const path = std.fmt.bufPrint(&path_buf, "{s}/{s}", .{ base, sub_path }) catch return error.NameTooLong;
    const file = std.Io.Dir.cwd().createFile(io, path, .{}) catch |err| {
        return err;
    };
    defer file.close(io);
    file.writeStreamingAll(io, content) catch |err| {
        return err;
    };
}
