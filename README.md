# transcripteur

**transcripteur** is a CLI that allows you to easily use whisper to transcribe an audio file provided as input.

## Quick start

### Requirements

- [Zig 0.15.x](https://ziglang.org/)
- [Cmake](https://cmake.org/)

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

```sh
cd whisper
mkdir build && cd build
cmake .. && make -j
cd ../..
```

Build `transcripteur` :

```sh
zig build                           # Default (dev)
zig build -Doptimize=ReleaseFast    # Maximum speed
zig build -Doptimize=ReleaseSafe    # Optimized with safety checks
```

### Run

```sh
./zig-out/bin/transcripteur --model <path> --audio <path>
```

Options :

| Options | Descriptions |
| :-- | :-- |
| `--help` or `-h` | Show all options |
| `--model` | Whisper model file |
| `--audio` | Audio file |

## License

This project is licensed under the [GPLv3 License](./LICENSE) see the [LICENSE](./LICENSE) file for details.

