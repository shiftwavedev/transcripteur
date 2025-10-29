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

**Linux/macOS:**

```sh
./zig-out/bin/transcripteur --model <path> --audio <path>
```

**Windows:**

```cmd
zig-out\bin\transcripteur.exe --model <path> --audio <path>
```

> **Note:** On Windows, the required DLLs (whisper.dll, ggml.dll, ggml-base.dll, ggml-cpu.dll) are automatically copied to `zig-out\bin\` during the build.

Options :

| Options | Descriptions |
| :-- | :-- |
| `--help` or `-h` | Show all options |
| `--model` | Whisper model file |
| `--audio` | Audio file |

## License

This project is licensed under the [GPLv3 License](./LICENSE) see the [LICENSE](./LICENSE) file for details.

