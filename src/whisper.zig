const std = @import("std");

const libWhisper = @cImport({
    @cInclude("whisper.h");
});

fn emptyLogCallback(_: libWhisper.enum_ggml_log_level, _: [*c]const u8, _: ?*anyopaque) callconv(.c) void {}

pub const WhisperContext = struct {
    allocator: std.mem.Allocator,
    ctx: *libWhisper.whisper_context,

    pub fn init(allocator: std.mem.Allocator, model_path: []const u8) !WhisperContext {
        libWhisper.whisper_log_set(emptyLogCallback, null);

        const cpy_path: [:0]u8 = try allocator.dupeZ(u8, model_path);
        defer allocator.free(cpy_path);

        const ctx_params = libWhisper.whisper_context_default_params();
        const ctx = libWhisper.whisper_init_from_file_with_params(cpy_path, ctx_params);

        if (ctx == null) {
            std.debug.print("[Error] Failed to load model : {s}\n", .{cpy_path});
            return error.WhisperInitFailed;
        }

        return WhisperContext{
            .allocator = allocator,
            .ctx = ctx.?,
        };
    }

    pub fn deinit(self: *WhisperContext) void {
        libWhisper.whisper_free(self.ctx);
    }

    pub fn transcribe(
        self: *WhisperContext,
        samples: []const f32,
        language: ?[]const u8,
        translate: bool,
    ) ![]const u8 {
        var params = libWhisper.whisper_full_default_params(libWhisper.WHISPER_SAMPLING_GREEDY);

        var lang_buffer: [3:0]u8 = undefined;
        if (language) |lang| {
            if (lang.len == 0 or lang.len > 2) {
                return error.InvalidLanguageCode;
            }
            @memcpy(lang_buffer[0..lang.len], lang);
            lang_buffer[lang.len] = 0;
            params.language = &lang_buffer;
        } else {
            params.language = null;
        }

        params.print_progress = false;
        params.print_special = false;
        params.print_realtime = false;
        params.print_timestamps = false;
        params.translate = translate;
        params.single_segment = true;
        params.no_context = true;
        params.no_timestamps = true;

        const ret_code = libWhisper.whisper_full(
            self.ctx,
            params,
            samples.ptr,
            @intCast(samples.len),
        );

        if (ret_code != 0) {
            std.debug.print("[Error] Whisper transcription failed with code: {}\n", .{ret_code});
            return error.TranscriptionFailed;
        }

        const num_segments = libWhisper.whisper_full_n_segments(self.ctx);
        if (num_segments == 0) {
            return try self.allocator.dupe(u8, "");
        }

        var total_len: usize = 0;
        var index: c_int = 0;
        while (index < num_segments) : (index += 1) {
            const segment_text = libWhisper.whisper_full_get_segment_text(self.ctx, index);
            if (segment_text != null) {
                total_len += std.mem.len(segment_text);
                if (index < num_segments - 1) total_len += 1;
            }
        }

        const result =  try self.allocator.alloc(u8, total_len);
        errdefer self.allocator.free(result);

        var pos: usize = 0;
        index = 0;
        while (index < num_segments) : (index += 1) {
            const segment_text = libWhisper.whisper_full_get_segment_text(self.ctx, index);
            if (segment_text != null) {
                const segment_slice = std.mem.span(segment_text);
                @memcpy(result[pos .. pos + segment_slice.len], segment_slice);
                pos += segment_slice.len;
                if (index < num_segments - 1) {
                    result[pos] = ' ';
                    pos += 1;
                }
            }
        }

        const trimmed = std.mem.trim(u8, result, " \t\n\r");
        if (!std.unicode.utf8ValidateSlice(trimmed)) {
            self.allocator.free(result);
            return try self.allocator.dupe(u8, "");
        }

        const trimmed_result = try self.allocator.dupe(u8, trimmed);
        self.allocator.free(result);

        return trimmed_result;
    }
};
