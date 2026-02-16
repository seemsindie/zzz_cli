const std = @import("std");
const Allocator = std.mem.Allocator;
const controller_tmpl = @import("../templates/controller.zig");
const model_tmpl = @import("../templates/model.zig");
const channel_tmpl = @import("../templates/channel.zig");

/// `zzz gen <type> <Name> [fields...]` -- generate code from templates.
pub fn run(args: []const []const u8, _: Allocator, io: std.Io) void {
    const stderr_file = std.Io.File.stderr();

    if (args.len < 2) {
        stderr_file.writeStreamingAll(io,
            \\Usage:
            \\  zzz gen controller <Name>
            \\  zzz gen model <Name> [field:type ...]
            \\  zzz gen channel <Name>
            \\
            \\Field types: string, text, integer, int, float, real, boolean, bool
            \\
            \\Examples:
            \\  zzz gen controller Users
            \\  zzz gen model Post title:string body:text user_id:integer
            \\  zzz gen channel Chat
            \\
        ) catch {};
        return;
    }

    const gen_type = args[0];
    const name_upper = args[1];

    // Convert to lowercase
    var name_lower_buf: [128]u8 = undefined;
    const name_lower = toLower(name_upper, &name_lower_buf);

    if (std.mem.eql(u8, gen_type, "controller")) {
        generateController(name_lower, name_upper, io);
    } else if (std.mem.eql(u8, gen_type, "model")) {
        generateModel(name_lower, name_upper, args[2..], io);
    } else if (std.mem.eql(u8, gen_type, "channel")) {
        generateChannel(name_lower, name_upper, io);
    } else {
        var buf: [256]u8 = undefined;
        const msg = std.fmt.bufPrint(&buf, "Unknown generator type: {s}\n", .{gen_type}) catch "Unknown generator type.\n";
        stderr_file.writeStreamingAll(io, msg) catch {};
        stderr_file.writeStreamingAll(io, "Available: controller, model, channel\n") catch {};
    }
}

fn generateController(name_lower: []const u8, name_upper: []const u8, io: std.Io) void {
    const stdout_file = std.Io.File.stdout();
    const stderr_file = std.Io.File.stderr();

    var buf: [4096]u8 = undefined;
    const content = controller_tmpl.generate(name_lower, name_upper, &buf) orelse {
        stderr_file.writeStreamingAll(io, "Failed to generate controller template\n") catch {};
        return;
    };

    var path_buf: [256]u8 = undefined;
    const path = std.fmt.bufPrint(&path_buf, "src/controllers/{s}.zig", .{name_lower}) catch return;

    writeFile(path, content, io) catch return;

    var msg_buf: [256]u8 = undefined;
    const msg = std.fmt.bufPrint(&msg_buf, "  Generated: {s}\n", .{path}) catch "  Generated controller.\n";
    stdout_file.writeStreamingAll(io, msg) catch {};
}

fn generateModel(name_lower: []const u8, name_upper: []const u8, fields: []const []const u8, io: std.Io) void {
    const stdout_file = std.Io.File.stdout();

    // Build Zig struct fields
    var fields_zig_buf: [2048]u8 = undefined;
    var fields_pos: usize = 0;

    // Build SQL column definitions
    var columns_sql_buf: [2048]u8 = undefined;
    var cols_pos: usize = 0;

    for (fields) |field_spec| {
        // Parse "name:type"
        const colon = std.mem.indexOfScalar(u8, field_spec, ':') orelse continue;
        const field_name = field_spec[0..colon];
        const field_type = field_spec[colon + 1 ..];

        const zig_type = model_tmpl.zigType(field_type);
        const sql_type = model_tmpl.sqlColumnType(field_type);

        // Zig field: "    name: type,\n"
        const zig_line = std.fmt.bufPrint(fields_zig_buf[fields_pos..], "    {s}: {s},\n", .{ field_name, zig_type }) catch break;
        fields_pos += zig_line.len;

        // SQL column: "        .{ .name = \"name\", .col_type = .type, .nullable = false },\n"
        const sql_line = std.fmt.bufPrint(columns_sql_buf[cols_pos..], "        .{{ .name = \"{s}\", .col_type = {s}, .nullable = false }},\n", .{ field_name, sql_type }) catch break;
        cols_pos += sql_line.len;
    }

    // Generate schema file
    var schema_buf: [8192]u8 = undefined;
    if (model_tmpl.generateSchema(name_lower, name_upper, fields_zig_buf[0..fields_pos], &schema_buf)) |content| {
        var path_buf: [256]u8 = undefined;
        const path = std.fmt.bufPrint(&path_buf, "src/{s}.zig", .{name_lower}) catch return;
        if (writeFile(path, content, io)) |_| {
            var msg_buf: [256]u8 = undefined;
            const msg = std.fmt.bufPrint(&msg_buf, "  Generated: {s}\n", .{path}) catch "  Generated schema.\n";
            stdout_file.writeStreamingAll(io, msg) catch {};
        } else |_| {}
    }

    // Generate migration file with timestamp prefix
    var migration_buf: [8192]u8 = undefined;
    if (model_tmpl.generateMigration(name_lower, columns_sql_buf[0..cols_pos], &migration_buf)) |content| {
        // Use a simple incrementing counter for the migration prefix
        var path_buf: [256]u8 = undefined;
        const path = std.fmt.bufPrint(&path_buf, "priv/migrations/001_create_{s}.zig", .{name_lower}) catch return;

        // Ensure directory exists
        std.Io.Dir.cwd().createDirPath(io, "priv/migrations") catch {};

        if (writeFile(path, content, io)) |_| {
            var msg_buf: [256]u8 = undefined;
            const msg = std.fmt.bufPrint(&msg_buf, "  Generated: {s}\n", .{path}) catch "  Generated migration.\n";
            stdout_file.writeStreamingAll(io, msg) catch {};
        } else |_| {}
    }
}

fn generateChannel(name_lower: []const u8, name_upper: []const u8, io: std.Io) void {
    const stdout_file = std.Io.File.stdout();
    const stderr_file = std.Io.File.stderr();

    var buf: [4096]u8 = undefined;
    const content = channel_tmpl.generate(name_lower, name_upper, &buf) orelse {
        stderr_file.writeStreamingAll(io, "Failed to generate channel template\n") catch {};
        return;
    };

    var path_buf: [256]u8 = undefined;
    const path = std.fmt.bufPrint(&path_buf, "src/channels/{s}.zig", .{name_lower}) catch return;

    // Ensure directory exists
    std.Io.Dir.cwd().createDirPath(io, "src/channels") catch {};

    writeFile(path, content, io) catch return;

    var msg_buf: [256]u8 = undefined;
    const msg = std.fmt.bufPrint(&msg_buf, "  Generated: {s}\n", .{path}) catch "  Generated channel.\n";
    stdout_file.writeStreamingAll(io, msg) catch {};
}

fn writeFile(path: []const u8, content: []const u8, io: std.Io) !void {
    const stderr_file = std.Io.File.stderr();
    const file = std.Io.Dir.cwd().createFile(io, path, .{ .exclusive = true }) catch |err| {
        if (err == error.PathAlreadyExists) {
            var buf: [256]u8 = undefined;
            const msg = std.fmt.bufPrint(&buf, "  File already exists: {s} (skipped)\n", .{path}) catch "  File already exists (skipped).\n";
            stderr_file.writeStreamingAll(io, msg) catch {};
        } else {
            var buf: [256]u8 = undefined;
            const msg = std.fmt.bufPrint(&buf, "  Failed to create {s}: {}\n", .{ path, err }) catch "  Failed to create file.\n";
            stderr_file.writeStreamingAll(io, msg) catch {};
        }
        return err;
    };
    defer file.close(io);
    file.writeStreamingAll(io, content) catch |err| {
        var buf: [256]u8 = undefined;
        const msg = std.fmt.bufPrint(&buf, "  Failed to write {s}: {}\n", .{ path, err }) catch "  Failed to write file.\n";
        stderr_file.writeStreamingAll(io, msg) catch {};
        return err;
    };
}

fn toLower(s: []const u8, buf: []u8) []const u8 {
    const len = @min(s.len, buf.len);
    for (s[0..len], 0..) |c, i| {
        buf[i] = std.ascii.toLower(c);
    }
    return buf[0..len];
}
