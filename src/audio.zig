const std = @import("std");

pub const WavHeader = struct {
    channels: u16,
    sample_rate: u32,
    byte_rate: u32,
    block_align: u16,
    bits_per_sample: u16,
    data_size: u32,
};

fn readU32LE(buf: []const u8, offset: usize) u32 {
    return @as(u32, buf[offset]) |
           @as(u32, buf[offset + 1]) << 8 |
           @as(u32, buf[offset + 2]) << 16 |
           @as(u32, buf[offset + 3]) << 24;
}

fn readU16LE(buf: []const u8, offset: usize) u16 {
    return @as(u16, buf[offset]) | (@as(u16, buf[offset + 1]) << 8);
}

fn readI16LE(buf: []const u8, offset: usize) i16 {
    return @as(i16, @bitCast(readU16LE(buf, offset)));
}

pub fn readWavFile(allocator: std.mem.Allocator, file_path: []const u8) !struct {
    samples: []f32,
    sample_rate: u32,
    channels: u16,
} {
    const file = try std.fs.cwd().openFile(file_path, .{});
    defer file.close();

    const file_size = try file.getEndPos();
    const file_buffer = try allocator.alloc(u8, file_size);
    defer allocator.free(file_buffer);
    _ = try file.readAll(file_buffer);

    var header: WavHeader = undefined;
    var pos: usize = 0;

    // Read RIFF header
    if (pos + 12 > file_size) return error.InvalidWavFile;
    if (!std.mem.eql(u8, file_buffer[0..4], "RIFF")) return error.InvalidWavFile;
    pos += 8;
    if (!std.mem.eql(u8, file_buffer[pos..pos+4], "WAVE")) return error.InvalidWavFile;
    pos += 4;

    // Find fmt chunk
    while (pos + 8 <= file_size) {
        const chunk_id = file_buffer[pos..pos+4];
        const chunk_size = readU32LE(file_buffer, pos + 4);
        pos += 8;

        if (std.mem.eql(u8, chunk_id, "fmt ")) {
            if (pos + 16 > file_size) return error.InvalidWavFile;
            
            const audio_format = readU16LE(file_buffer, pos);
            if (audio_format != 1) return error.UnsupportedAudioFormat;
            
            header.channels = readU16LE(file_buffer, pos + 2);
            header.sample_rate = readU32LE(file_buffer, pos + 4);
            header.byte_rate = readU32LE(file_buffer, pos + 8);
            header.block_align = readU16LE(file_buffer, pos + 12);
            header.bits_per_sample = readU16LE(file_buffer, pos + 14);
            
            pos += chunk_size;
            break;
        } else {
            pos += chunk_size;
        }
    }

    // Find data chunk
    var data_start: usize = 0;
    var data_size: u32 = 0;
    while (pos + 8 <= file_size) {
        const chunk_id = file_buffer[pos..pos+4];
        data_size = readU32LE(file_buffer, pos + 4);
        pos += 8;

        if (std.mem.eql(u8, chunk_id, "data")) {
            data_start = pos;
            break;
        } else {
            pos += data_size;
        }
    }

    if (data_start == 0) return error.NoDataChunk;

    // Convert audio data to f32 samples
    const num_frames = data_size / header.block_align;
    const samples_per_channel = num_frames;
    
    // Allocate for mono output (Whisper requires mono)
    const mono_samples = try allocator.alloc(f32, samples_per_channel);
    errdefer allocator.free(mono_samples);

    if (header.bits_per_sample == 16) {
        if (header.channels == 1) {
            // Mono: direct conversion
            for (0..samples_per_channel) |i| {
                const sample_i16 = readI16LE(file_buffer, data_start + i*2);
                mono_samples[i] = @as(f32, @floatFromInt(sample_i16)) / 32768.0;
            }
        } else if (header.channels == 2) {
            // Stereo: average both channels to mono
            for (0..samples_per_channel) |i| {
                const left = readI16LE(file_buffer, data_start + i*4);
                const right = readI16LE(file_buffer, data_start + i*4 + 2);
                const avg = @divTrunc((@as(i32, left) + @as(i32, right)), 2);
                mono_samples[i] = @as(f32, @floatFromInt(avg)) / 32768.0;
            }
        } else {
            allocator.free(mono_samples);
            return error.UnsupportedChannelCount;
        }
    } else if (header.bits_per_sample == 32) {
        if (header.channels == 1) {
            for (0..samples_per_channel) |i| {
                const sample_i32 = @as(i32, @bitCast(readU32LE(file_buffer, data_start + i*4)));
                mono_samples[i] = @as(f32, @floatFromInt(sample_i32)) / 2147483648.0;
            }
        } else if (header.channels == 2) {
            for (0..samples_per_channel) |i| {
                const left_u32 = readU32LE(file_buffer, data_start + i*8);
                const right_u32 = readU32LE(file_buffer, data_start + i*8 + 4);
                const left = @as(i32, @bitCast(left_u32));
                const right = @as(i32, @bitCast(right_u32));
                const avg = @divTrunc((@as(i64, left) + @as(i64, right)), 2);
                mono_samples[i] = @as(f32, @floatFromInt(avg)) / 2147483648.0;
            }
        } else {
            allocator.free(mono_samples);
            return error.UnsupportedChannelCount;
        }
    } else {
        allocator.free(mono_samples);
        return error.UnsupportedBitDepth;
    }

    return .{
        .samples = mono_samples,
        .sample_rate = header.sample_rate,
        .channels = 1, // Always return mono (requirement of Whisper)
    };
}
