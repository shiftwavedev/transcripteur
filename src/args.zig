const std = @import("std");

pub const Config = struct {
    model_path: []const u8,
    audio_path: []const u8,
    allocator: std.mem.Allocator,

    pub fn deinit(self: *const Config) void {
        self.allocator.free(self.model_path);
        self.allocator.free(self.audio_path);
    }
};

pub fn printHelp() void {
    std.debug.print(
        \\Transcripteur - Audio transcription using Whisper
        \\
        \\Usage: transcripteur --model <path> --audio <path>
        \\
        \\Options:
        \\  --model <path>    Path to Whisper model file
        \\  --audio <path>    Path to audio file (WAV format)
        \\  -h, --help        Display this help message
        \\
    , .{});
}

pub fn parseArgs(allocator: std.mem.Allocator) !?Config {
    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();

    _ = args.skip();

    var model_path: ?[]const u8 = null;
    var audio_path: ?[]const u8 = null;

    while (args.next()) |arg| {
        if (std.mem.eql(u8, arg, "-h") or std.mem.eql(u8, arg, "--help")) {
            printHelp();
            return null;
        } else if (std.mem.eql(u8, arg, "--model")) {
            const next = args.next() orelse {
                std.debug.print("[Error]: --model requires an argument\n", .{});
                std.debug.print("Use --help for usage information\n", .{});
                return error.MissingArgument;
            };
            model_path = next;
        } else if (std.mem.eql(u8, arg, "--audio")) {
            const next = args.next() orelse {
                std.debug.print("[Error]: --audio requires an argument\n", .{});
                std.debug.print("Use --help for usage information\n", .{});
                return error.MissingArgument;
            };
            audio_path = next;
        } else {
            std.debug.print("[Error]: Unknown argument '{s}'\n", .{arg});
            std.debug.print("Use --help for usage information\n", .{});
            return error.UnknownArgument;
        }
    }

    if (model_path == null) {
        std.debug.print("[Error]: --model is required\n", .{});
        std.debug.print("Use --help for usage information\n", .{});
        return error.MissingArgument;
    }

    if (audio_path == null) {
        std.debug.print("[Error]: --audio is required\n", .{});
        std.debug.print("Use --help for usage information\n", .{});
        return error.MissingArgument;
    }

    const duped_model = try allocator.dupe(u8, model_path.?);
    errdefer allocator.free(duped_model);

    const duped_audio = try allocator.dupe(u8, audio_path.?);
    errdefer allocator.free(duped_audio);

    return Config{
        .model_path = duped_model,
        .audio_path = duped_audio,
        .allocator = allocator,
    };
}
