const std = @import("std");

pub const commands = struct {
    pub const new = @import("commands/new.zig");
    pub const server = @import("commands/server.zig");
    pub const routes = @import("commands/routes.zig");
    pub const migrate = @import("commands/migrate.zig");
    pub const generate = @import("commands/generate.zig");
    pub const swagger = @import("commands/swagger.zig");
    pub const test_cmd = @import("commands/test_cmd.zig");
    pub const deps = @import("commands/deps.zig");
};

pub const templates = struct {
    pub const project = @import("templates/project.zig");
    pub const controller = @import("templates/controller.zig");
    pub const model = @import("templates/model.zig");
    pub const channel = @import("templates/channel.zig");
};

pub const version = "0.1.0";

test {
    std.testing.refAllDecls(@This());
}
