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
        config.deinit();
        std.process.exit(1);
    };
    defer whisper_ctx.deinit();
    std.debug.print("Model loaded successfully\n", .{});

    std.debug.print("Reading audio file from: {s}\n", .{config.audio_path});
    const audio_data = audio.readWavFile(allocator, config.audio_path) catch |err| {
        std.debug.print("[Error]: Failed to read audio file: {}\n", .{err});
        whisper_ctx.deinit();
        config.deinit();
        std.process.exit(1);
    };
    defer allocator.free(audio_data.samples);
    std.debug.print("Audio loaded: {} samples, {} Hz, {} channels\n", .{
        audio_data.samples.len,
        audio_data.sample_rate,
        audio_data.channels,
    });

    std.debug.print("Running transcription...\n", .{});
    const result = whisper_ctx.transcribe(audio_data.samples, null, false) catch |err| {
        std.debug.print("[Error]: Failed to transcribe: {}\n", .{err});
        allocator.free(audio_data.samples);
        whisper_ctx.deinit();
        config.deinit();
        std.process.exit(1);
    };
    defer allocator.free(result);

    std.debug.print("\n===== Transcription Result =====\n", .{});
    std.debug.print("{s}\n", .{result});
    std.debug.print("================================\n", .{});
}
