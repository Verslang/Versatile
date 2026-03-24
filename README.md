# Versatile Project

A comprehensive, self-hosting project spanning three interconnected programming languages:
**Verslang**, **Versscript**, and **Versatile**.

This project demonstrates:
- **Self-hosting**: Verslang compiles new parts of itself using its own language
- **Cross-language integration**: Performance-critical parts of Versscript are written in Verslang
- **Cross-platform installers**: Written entirely in Verslang, producing native executables for Windows, Linux, and macOS
- **Unified build system**: A single build orchestrator compiles the entire project

---

## Project Structure

```
versatile-project/
├── tests/                          # Language test suites
│   ├── test_verslang.vlang         # Verslang feature tests
│   ├── test_versscript.vs          # Versscript feature tests
│   └── test_versatile.vtile        # Versatile combined-language tests
│
├── installer/                      # Cross-platform installers (in Verslang)
│   ├── verslang-installer/
│   │   ├── installer-common.vlang  # Shared installer infrastructure
│   │   ├── installer-windows.vlang # Windows PE64 installer
│   │   ├── installer-linux.vlang   # Linux ELF64 installer
│   │   └── installer-macos.vlang   # macOS installer
│   └── versatile-installer/
│       └── installer.vlang         # Combined suite installer
│
├── versscript-native/              # Versscript runtime modules in Verslang
│   ├── string_ops.vlang            # SIMD string operations
│   ├── math_engine.vlang           # SSE/x87 math engine
│   ├── memory_pool.vlang           # Pool & arena allocators
│   ├── json_parser.vlang           # Fast recursive-descent JSON parser
│   └── hash_table.vlang            # Robin Hood hash table
│
├── verslang-bootstrap/             # Self-hosting bootstrap compiler
│   ├── lexer.vlang                 # Tokenizer (75+ token types)
│   ├── parser.vlang                # Recursive descent parser (40+ AST nodes)
│   ├── codegen.vlang               # x86-64 code generator
│   └── main.vlang                  # Compiler entry point & CLI
│
├── build/
│   └── build-all.vlang             # Master build orchestrator (in Verslang)
│
├── build-windows.bat               # Windows build script
├── build-linux.sh                  # Linux build script
├── build-macos.sh                  # macOS build script
└── README.md
```

---

## Languages

### Verslang (.vlang)

A statically-typed, low-level systems programming language that compiles directly to x86-64 machine code. No linker, no runtime — just raw binary output.

- **Output formats**: ELF64, PE32+, flat binary, boot sector, Mach-O
- **Features**: `declare`/`constant`/`mutable` variables, `structure`/`enumeration`/`union`/`bitfield` types, inline `assembly{}` blocks, `syscall()`, `when platform` conditional compilation
- **Types**: `u8`–`u64`, `i8`–`i64`, `f32`, `f64`, `bool`, `char`, `void`, `ptr<T>`, `array<T,N>`

### Versscript (.vs / .verss)

A dynamically-typed scripting language with a C++ runtime, 500+ built-in functions, and 60+ modules.

- **Features**: `var`/`let`/`const` variables, classes with inheritance, `foreach`/`forever` loops, `try`/`catch`/`finally`, `§` comments, `<settings:>` blocks, `Permissions{}`
- **Runtime**: 232 passing tests, full standard library

### Versatile (.vtile)

A combined meta-language that embeds both Verslang and Versscript blocks in a single file using `verslang { }` and `versscript { }` delimiters, enabling mixed high-level/low-level programming.

---

## Building

### Prerequisites

- **Verslang compiler** (`verslang`) on your PATH
- **Versscript interpreter** (`verss`) on your PATH (optional, for Versscript tests)

### Windows

```bat
build-windows.bat
```

### Linux

```bash
chmod +x build-linux.sh
./build-linux.sh
```

### macOS

```bash
chmod +x build-macos.sh
./build-macos.sh
```

### Build Output

All artifacts are placed in `build/output/`:

| Artifact | Description |
|---|---|
| `verslang-bootstrap` | Self-hosting Verslang compiler written in Verslang |
| `versnative.dll` / `libversnative.so` / `libversnative.dylib` | Native module library for Versscript |
| `verslang-installer` | Platform-specific Verslang installer |
| `versatile-installer` | Combined installer for the full suite |
| `test_verslang` | Compiled test runner |

---

## Components

### Self-Hosting Bootstrap Compiler

The `verslang-bootstrap/` directory contains a Verslang compiler **written entirely in Verslang**. This demonstrates the language's capability to compile itself:

1. **Lexer** — Tokenizes Verslang source into 75+ token types, handles `§` comments, nested `/* */` blocks, hex/binary/float literals
2. **Parser** — Recursive descent parser producing 40+ AST node types, with Pratt expression parsing for operator precedence
3. **Code Generator** — Emits x86-64 machine code directly, with full instruction encoding, ELF64/PE64 header generation, symbol management, and relocations
4. **Main** — CLI entry point with argument parsing, 6-step compilation pipeline, and platform-specific I/O via syscalls (Linux) or Win32 API (Windows)

### Native Modules for Versscript

The `versscript-native/` directory contains performance-critical components of the Versscript runtime, rewritten in Verslang for maximum speed:

- **string_ops** — SIMD-accelerated `strlen` (SSE2), Boyer-Moore-Horsfall substring search, bulk `toUpper`/`toLower`, FNV-1a hashing, UTF-8 decoding
- **math_engine** — SSE `abs`/`min`/`max`/`clamp`/`sqrt`, x87 FPU trigonometry (`sin`/`cos`/`tan`/`atan2`), SIMD `Vec4d` operations, PCG random number generator
- **memory_pool** — Pool allocator with free lists, arena (bump) allocator, corruption/double-free detection, platform-specific OS memory allocation
- **json_parser** — Fast tokenizer + recursive descent parser, handles all JSON types including nested objects/arrays, escape sequences, exponent notation
- **hash_table** — Robin Hood open-addressing hash table with FNV-1a hashing, automatic resizing, tombstone compaction, iterator support

### Cross-Platform Installers

All installers are written in Verslang and compile to native executables with zero dependencies:

- **Windows** — Creates directories, copies files, modifies PATH via registry, creates uninstall entries, MessageBox UI
- **Linux** — Direct syscall I/O, `/usr/local/bin` installation, `~/.bashrc` PATH export, troff man page generation
- **macOS** — Homebrew-style Cellar directories, `~/.zshrc` profile update, man page installation
- **Versatile** — Combined installer that installs both Verslang and Versscript with component selection

---

## Architecture

```
┌─────────────────────────────────────────────────┐
│                 Versatile (.vtile)               │
│         Mixed verslang{} + versscript{} blocks   │
├────────────────────┬────────────────────────────┤
│  Versscript (.vs)  │      Verslang (.vlang)     │
│  Dynamic, 500+     │      Static, compiles to   │
│  builtins, classes │      x86-64 machine code   │
├────────────────────┼────────────────────────────┤
│  C++ Runtime       │  ← versscript-native/ →    │
│  (verss)           │  SIMD strings, math, JSON, │
│                    │  memory pools, hash tables  │
├────────────────────┴────────────────────────────┤
│            verslang-bootstrap/                   │
│      Self-hosting compiler (lexer → parser →     │
│      codegen → x86-64 binary)                    │
├─────────────────────────────────────────────────┤
│           installer/ (all platforms)             │
│      Native installers compiled by Verslang      │
└─────────────────────────────────────────────────┘
```

---

## Testing

Each language has a dedicated test file:

- **`tests/test_verslang.vlang`** — Structures, enumerations, unions, bitfields, assembly integration, math functions, platform-specific blocks, 6 test suites
- **`tests/test_versscript.vs`** — Variables, types, arithmetic, strings, arrays, HashMaps, functions, classes/OOP, control flow, error handling, builtins, JSON, functional patterns, File I/O, advanced patterns
- **`tests/test_versatile.vtile`** — Cross-language data exchange, mixed pipelines, config & build patterns, plugin architecture

Run all tests via the build scripts, or individually:

```bash
# Verslang tests (compile and run)
verslang tests/test_verslang.vlang -o test_verslang -f elf64
./test_verslang

# Versscript tests (interpret)
verss tests/test_versscript.vs

# Versatile tests (requires both compilers)
# Processed by the Versatile toolchain
```

---

## File Count Summary

| Category | Files | Language |
|---|---|---|
| Tests | 3 | .vlang, .vs, .vtile |
| Installers | 5 | .vlang |
| Native Modules | 5 | .vlang |
| Bootstrap Compiler | 4 | .vlang |
| Build System | 4 | .vlang, .bat, .sh |
| Documentation | 1 | .md |
| **Total** | **22** | |

---

## License

Part of the Versatile Language Suite. All rights reserved.
