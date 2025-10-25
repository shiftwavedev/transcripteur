const std = @import("std");
const whisper = @import("whisper.zig");
const audio = @import("audio.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const model_path = "./whisper.cpp/models/ggml-base.en.bin";
    const audio_path = "./whisper.cpp/samples/jfk.wav";

    var whisper_ctx = whisper.WhisperContext.init(allocator, model_path) catch |err| {
        std.debug.print("Failed to initialize Whisper: {}\n", .{err});
        return err;
    };
    defer whisper_ctx.deinit();

    const audio_data = audio.readWavFile(allocator, audio_path) catch |err| {
        std.debug.print("Failed to read audio file: {}\n", .{err});
        return err;
    };
    defer allocator.free(audio_data.samples);

    std.debug.print("Running transcription...\n", .{});

    const result = whisper_ctx.transcribe(audio_data.samples, null, false) catch |err| {
        std.debug.print("Failed to transcribe: {}\n", .{err});
        return err;
    };
    defer allocator.free(result);

    std.debug.print("\n===== Transcription Result =====\n", .{});
    std.debug.print("{s}\n", .{result});
    std.debug.print("================================\n", .{});
}
