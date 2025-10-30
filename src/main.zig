const std = @import("std");
const whisper = @import("whisper.zig");
const audio = @import("audio.zig");
const args = @import("args.zig");

pub fn main() void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const config = (args.parseArgs(allocator) catch {
        std.process.exit(1);
    }) orelse return;
    defer config.deinit();

    std.debug.print("Loading model from: {s}\n", .{config.model_path});
    var whisper_ctx = whisper.WhisperContext.init(allocator, config.model_path) catch |err| {
        std.debug.print("[Error]: Failed to initialize Whisper: {}\n", .{err});
        std.process.exit(1);
    };
    defer whisper_ctx.deinit();
    std.debug.print("Model loaded successfully\n", .{});

    if (config.translate) {
        std.debug.print("Mode: Transcription and translation to English\n", .{});
    } else {
        std.debug.print("Mode: Transcription\n", .{});
    }
    if (config.language) |lang| {
        std.debug.print("Language: {s}\n", .{lang});
    }
    std.debug.print("Processing {} file(s)\n\n", .{config.audio_paths.len});

    for (config.audio_paths, 0..) |audio_path, i| {
        std.debug.print("[{}/{}] Processing: {s}\n", .{ i + 1, config.audio_paths.len, audio_path });

        const audio_data = audio.readWavFile(allocator, audio_path) catch |err| {
            std.debug.print("[Error]: Failed to read audio file: {}\n", .{err});
            std.process.exit(1);
        };
        defer allocator.free(audio_data.samples);

        std.debug.print("Audio loaded: {} samples, {} Hz, {} channels\n", .{
            audio_data.samples.len,
            audio_data.sample_rate,
            audio_data.channels,
        });

        const result = whisper_ctx.transcribe(audio_data.samples, config.language, config.translate) catch |err| {
            std.debug.print("[Error]: Failed to transcribe: {}\n", .{err});
            std.process.exit(1);
        };
        defer allocator.free(result);

        std.debug.print("\n===== Result: {s} =====\n", .{audio_path});
        std.debug.print("{s}\n", .{result});
        std.debug.print("==========================================\n\n", .{});
    }
}
