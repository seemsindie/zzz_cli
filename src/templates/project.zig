/// Embedded template strings for scaffolding a new zzz project.

pub const build_zig =
    \\const std = @import("std");
    \\
    \\pub fn build(b: *std.Build) void {
    \\    const target = b.standardTargetOptions(.{});
    \\    const optimize = b.standardOptimizeOption(.{});
    \\
    \\    const zzz_dep = b.dependency("zzz", .{ .target = target, .optimize = optimize });
    \\    const zzz_mod = zzz_dep.module("zzz");
    \\
    \\    const exe = b.addExecutable(.{
    \\        .name = "$NAME$",
    \\        .root_module = b.createModule(.{
    \\            .root_source_file = b.path("src/main.zig"),
    \\            .target = target,
    \\            .optimize = optimize,
    \\            .imports = &.{
    \\                .{ .name = "zzz", .module = zzz_mod },
    \\            },
    \\        }),
    \\    });
    \\
    \\    b.installArtifact(exe);
    \\
    \\    const run_step = b.step("run", "Run the app");
    \\    const run_cmd = b.addRunArtifact(exe);
    \\    run_step.dependOn(&run_cmd.step);
    \\    run_cmd.step.dependOn(b.getInstallStep());
    \\
    \\    if (b.args) |args| {
    \\        run_cmd.addArgs(args);
    \\    }
    \\
    \\    const test_step = b.step("test", "Run tests");
    \\    const tests = b.addTest(.{ .root_module = exe.root_module });
    \\    test_step.dependOn(&b.addRunArtifact(tests).step);
    \\}
    \\
;

pub fn buildZigZon(name: []const u8, buf: []u8) ?[]const u8 {
    return std.fmt.bufPrint(buf,
        \\.{{
        \\    .name = .{s},
        \\    .version = "0.1.0",
        \\    .minimum_zig_version = "0.16.0-dev.2535+b5bd49460",
        \\    .dependencies = .{{
        \\        .zzz = .{{
        \\            .path = "../zzz",
        \\        }},
        \\    }},
        \\    .paths = .{{
        \\        "build.zig",
        \\        "build.zig.zon",
        \\        "src",
        \\    }},
        \\}}
        \\
    , .{name}) catch null;
}

pub const main_zig =
    \\const std = @import("std");
    \\const zzz = @import("zzz");
    \\
    \\const Router = zzz.Router;
    \\const Context = zzz.Context;
    \\
    \\fn index(ctx: *Context) !void {
    \\    ctx.html(.ok,
    \\        \\<!DOCTYPE html>
    \\        \\<html>
    \\        \\<head><title>Welcome to Zzz</title></head>
    \\        \\<body>
    \\        \\  <h1>Welcome to Zzz!</h1>
    \\        \\  <p>Your new project is ready.</p>
    \\        \\</body>
    \\        \\</html>
    \\    );
    \\}
    \\
    \\const App = Router.define(.{
    \\    .middleware = &.{zzz.logger},
    \\    .routes = &.{
    \\        Router.get("/", index),
    \\    },
    \\});
    \\
    \\pub fn main() !void {
    \\    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    \\    defer _ = gpa.deinit();
    \\
    \\    var server = zzz.Server.init(gpa.allocator(), .{
    \\        .port = 4000,
    \\    }, &App.handler);
    \\
    \\    std.log.info("Zzz server listening on http://127.0.0.1:4000", .{});
    \\    try server.listen(std.io.defaultIo());
    \\}
    \\
;

pub const gitignore =
    \\zig-cache/
    \\zig-out/
    \\.zig-cache/
    \\.zig-out/
    \\
;

pub const style_css =
    \\/* Add your styles here */
    \\body {
    \\    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
    \\    max-width: 800px;
    \\    margin: 40px auto;
    \\    padding: 0 20px;
    \\    color: #333;
    \\}
    \\
;

const std = @import("std");
