# transcripteur

**transcripteur** is a CLI that allows you to easily use whisper to transcribe an audio file provided as input.

## Quick start

### Requirements

**All platforms:**
- [Zig 0.15.x](https://ziglang.org/)
- [CMake](https://cmake.org/)

**Windows only:**
- [Visual Studio 2022 Build Tools](https://visualstudio.microsoft.com/fr/downloads/) or Visual Studio 2022
  - Required components: "Desktop development with C++"

### Build && setup

Clone project and setup :

```sh
git clone https://github.com/shiftwavedev/transcripteur.git
## or via Codeberg
git clone https://codeberg.org/shiftwave/transcripteur.git
cd transcripteur
git submodule update --init --recursive
```

Build whisper.cpp :

**Linux/macOS:**

```sh
cd whisper.cpp
mkdir build && cd build
cmake .. && make -j
cd ../..
```

**Windows:**

```cmd
cd whisper.cpp
mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
cmake --build . --config Release
cd ..\..
```

Build `transcripteur` :

```sh
zig build                           # Default (dev)
zig build -Doptimize=ReleaseFast    # Maximum speed
zig build -Doptimize=ReleaseSafe    # Optimized with safety checks
```

### Run

**Basic usage:**

**Linux/macOS:**

```sh
./zig-out/bin/transcripteur --model <path> --audio <path>
```

**Windows:**

```cmd
zig-out\bin\transcripteur.exe --model <path> --audio <path>
```

**Multiple files:**

```sh
# Process multiple audio files at once (comma-separated)
./zig-out/bin/transcripteur --model model.bin --audio "file1.wav,file2.wav,file3.wav"
```

**With language and translation:**

```sh
# Transcribe in French
./zig-out/bin/transcripteur --model model.bin --audio audio.wav --language fr

# Translate from French to English
./zig-out/bin/transcripteur --model model.bin --audio audio.wav --language fr --translate
```

> **Note:** On Windows, the required DLLs (whisper.dll, ggml.dll, ggml-base.dll, ggml-cpu.dll) are automatically copied to `zig-out\bin\` during the build.

### Options

| Option | Description |
| :-- | :-- |
| `--help` or `-h` | Show all options |
| `--model <path>` | Path to Whisper model file (required) |
| `--audio <paths>` | Audio file(s) in WAV format. Use comma to separate multiple files (required) |
| `-l, --language <code>` | Language code (e.g., en, fr, es, de) or "auto" for automatic detection |
| `--translate` | Translate transcription to English (only English translation supported) |

### Examples

```sh
# Simple transcription
./zig-out/bin/transcripteur --model ggml-base.bin --audio recording.wav

# Multiple files with French language
./zig-out/bin/transcripteur --model ggml-base.bin --audio "audio1.wav,audio2.wav" -l fr

# Transcribe Spanish audio and translate to English
./zig-out/bin/transcripteur --model ggml-base.bin --audio spanish.wav -l es --translate

# Auto-detect language for multiple files
./zig-out/bin/transcripteur --model ggml-base.bin --audio "file1.wav,file2.wav,file3.wav" -l auto
```

## License

This project is licensed under the [GPLv3 License](./LICENSE) see the [LICENSE](./LICENSE) file for details.

