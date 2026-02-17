/// Embedded template strings for scaffolding a new zzz project.
pub const build_zig =
    \\const std = @import("std");
    \\
    \\pub fn build(b: *std.Build) void {
    \\    const target = b.standardTargetOptions(.{});
    \\    const optimize = b.standardOptimizeOption(.{});
    \\    const env_name = b.option([]const u8, "env", "Environment: dev (default), prod, staging") orelse "dev";
    \\
    \\    const zzz_dep = b.dependency("zzz", .{ .target = target, .optimize = optimize });
    \\    const zzz_mod = zzz_dep.module("zzz");
    \\
    \\    // Build config path from -Denv option
    \\    var config_path_buf: [64]u8 = undefined;
    \\    const config_path = std.fmt.bufPrint(&config_path_buf, "config/{s}.zig", .{env_name}) catch "config/dev.zig";
    \\
    \\    const config_mod = b.createModule(.{
    \\        .root_source_file = b.path("config/config.zig"),
    \\        .target = target,
    \\    });
    \\
    \\    const app_config_mod = b.createModule(.{
    \\        .root_source_file = b.path(config_path),
    \\        .target = target,
    \\    });
    \\    app_config_mod.addImport("config", config_mod);
    \\
    \\    const exe = b.addExecutable(.{
    \\        .name = "$NAME$",
    \\        .root_module = b.createModule(.{
    \\            .root_source_file = b.path("src/main.zig"),
    \\            .target = target,
    \\            .optimize = optimize,
    \\            .imports = &.{
    \\                .{ .name = "zzz", .module = zzz_mod },
    \\                .{ .name = "app_config", .module = app_config_mod },
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
        \\        "config",
        \\    }},
        \\}}
        \\
    , .{name}) catch null;
}

pub const main_zig =
    \\const std = @import("std");
    \\const zzz = @import("zzz");
    \\const app_config = @import("app_config");
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
    \\pub fn main(init: std.process.Init) !void {
    \\    const allocator = init.gpa;
    \\    const io = init.io;
    \\
    \\    var env = try zzz.Env.init(allocator, .{});
    \\    defer env.deinit();
    \\
    \\    const config = zzz.mergeWithEnv(@TypeOf(app_config.config), app_config.config, &env);
    \\
    \\    var server = zzz.Server.init(allocator, .{
    \\        .host = config.host,
    \\        .port = config.port,
    \\    }, App.handler);
    \\
    \\    try server.listen(io);
    \\}
    \\
;

pub const config_zig =
    \\/// Shared application config struct.
    \\/// Comptime defaults come from dev.zig / prod.zig (selected by `-Denv`).
    \\/// Runtime overrides come from `.env` + system env via `zzz.mergeWithEnv`.
    \\pub const AppConfig = struct {
    \\    host: []const u8 = "127.0.0.1",
    \\    port: u16 = 4000,
    \\    secret_key_base: []const u8 = "change-me-in-production",
    \\};
    \\
;

pub const config_dev_zig =
    \\const AppConfig = @import("config").AppConfig;
    \\
    \\/// Development defaults.
    \\pub const config: AppConfig = .{
    \\    .host = "127.0.0.1",
    \\    .port = 4000,
    \\    .secret_key_base = "dev-secret-not-for-production",
    \\};
    \\
;

pub const config_prod_zig =
    \\const AppConfig = @import("config").AppConfig;
    \\
    \\/// Production defaults.
    \\pub const config: AppConfig = .{
    \\    .host = "0.0.0.0",
    \\    .port = 8080,
    \\    .secret_key_base = "MUST-BE-SET-VIA-ENV",
    \\};
    \\
;

pub const dot_env =
    \\# Development environment variables
    \\# These override comptime defaults from config/dev.zig
    \\HOST=127.0.0.1
    \\PORT=4000
    \\SECRET_KEY_BASE=dev-secret-not-for-production
    \\
;

pub const env_example =
    \\# Environment Configuration
    \\#
    \\# These variables override the comptime defaults from config/dev.zig or config/prod.zig.
    \\# Build with: zig build run              (uses config/dev.zig)
    \\#             zig build run -Denv=prod   (uses config/prod.zig)
    \\#
    \\# HOST              Server bind address (dev: 127.0.0.1, prod: 0.0.0.0)
    \\# PORT              Server listen port (dev: 4000, prod: 8080)
    \\# SECRET_KEY_BASE   Secret for sessions/CSRF — MUST be set in production
    \\
    \\HOST=127.0.0.1
    \\PORT=4000
    \\SECRET_KEY_BASE=dev-secret-not-for-production
    \\
;

pub const gitignore =
    \\zig-cache/
    \\zig-out/
    \\zig-pkg/
    \\.zig-cache/
    \\.zig-out/
    \\.env
    \\!.env.example
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
