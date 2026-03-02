# AGENTS.md - nvbandwidth Development Guide

nvbandwidth is a CUDA-based GPU bandwidth measurement tool for measuring memory transfer bandwidth across PCIe and NVLink links.

- **Language**: C++17, CUDA
- **Build**: CMake 3.20+, CUDA 11.X+ (multinode requires 12.3+)
- **Dependencies**: Boost::program_options, NVML, CUDA Runtime

## Build Commands

### Single-node
```bash
cmake .
make
```

### Multinode (requires MPI)
```bash
cmake -DMULTINODE=1 .
make
```

### Build Options
- CUDA architectures: `cmake -DCMAKE_CUDA_ARCHITECTURES="80;86" .`
- Boost root (Windows): `cmake -DBOOST_ROOT=/path/to/boost .`
- Release build (default): `cmake -DCMAKE_BUILD_TYPE=Release .`

## Running Tests

Testcases are benchmarks, not unit tests. Run specific testcases:
```bash
./nvbandwidth -t <testcase_name>    # Run specific test
./nvbandwidth -l                     # List all testcases
./nvbandwidth -p <prefix>           # Run by prefix
```

Common options:
- `-b, --bufferSize` - Buffer size in MiB (default: 512)
- `-i, --testSamples` - Iterations (default: 3)
- `-m, --useMean` - Use mean instead of median
- `-j, --json` - JSON output
- `-v, --verbose` - Verbose output
- `-s, --skipVerification` - Skip data verification

## Code Style

### License Header
All source files must include the Apache 2.0 license header with SPDX tags (see existing files for exact format).

### File Organization
- Headers: `.h`, Implementation: `.cpp`, CUDA device code: `.cu`
- Include guards: `#ifndef FILENAME_H_` / `#define FILENAME_H_` / `#endif`

### Naming Conventions
- **Classes**: PascalCase (e.g., `Testcase`, `HostToDeviceCE`)
- **Functions**: PascalCase (e.g., `filterHasAccessiblePeerPairs`)
- **Variables**: camelCase (e.g., `deviceCount`, `bufferSize`)
- **Member variables**: `m_` prefix or camelCase (match surrounding code)
- **Constants**: PascalCase (e.g., `defaultLoopCount`, `_MiB`)
- **Enums**: PascalCase (e.g., `ContextPreference`)
- **Macros**: UPPER_SNAKE_CASE (e.g., `CUDA_ASSERT`, `ROUND_UP`)

### Formatting
- Indentation: 4 spaces (no tabs)
- Opening brace on same line for functions/classes
- Use braces for single-line statements in macros
- Line length: ~100 characters (soft limit)
- Comments: `//` (not `/* */` except license headers)

### Imports and Includes
Order: Boost, CUDA, NVML, MPI (if MULTINODE), then local headers
- Local headers: `#include "common.h"`
- External headers: `#include <cuda.h>`

### Error Handling
Use assertion macros from `error_handling.h`:
```cpp
CUDA_ASSERT(cuDeviceGetCount(&deviceCount));  // CUDA API errors
NVML_ASSERT(nvmlInit_v2());                   // NVML API errors
ASSERT(condition);                             // Generic assertions
```
- Log detailed errors with function, file, line
- Abort with `MPI_ABORT` in multinode builds
- Call `std::exit(1)` on failure

### Types and Memory
- `unsigned long long`: sizes and counts
- `size_t`: memory addresses and system API sizes
- `int`: device indices and loop counters
- `std::vector`: dynamic arrays
- `std::string`: strings
- Raw pointers with explicit `new`/`delete` (no smart pointers in legacy code)
- Prefer `const` correctness

### Class Design
- Inheritance for testcases: base class `Testcase` with virtual `run()`
- Composition for operations: `MemcpyInitiator`, `NodeHelper`
- RAII for resource management
- Virtual destructors for polymorphic classes

### CUDA Patterns
- Use `CUdevice`, `CUcontext`, `CUstream`, `CUdeviceptr`
- Use `cudaError_t` for error checking
- CUDA events for timing: `cuEventCreate`, `cuEventRecord`, `cuEventElapsedTime`
- Streams for async: `cuStreamCreate`, `cuMemcpyAsync`

### Multinode
- Use `#ifdef MULTINODE` for conditional compilation
- Include `<mpi.h>` only when `MULTINODE` is defined
- Use `HOST_INFO` macro for error messages with rank info
- Only MPI rank 0 should output to stdout

## Common Tasks

**Add new testcase:**
1. Declare class in `testcase.h` (inherit from `Testcase`)
2. Implement `run()` in `testcases_ce.cpp` or `testcases_sm.cpp`
3. Register in `createTestcases()` in `nvbandwidth.cpp`

**Add new memcpy operation:**
1. Add class in `memcpy.h` (inherit from `MemcpyInitiator`)
2. Implement in `memcpy.cpp`
3. Use in testcase `run()` methods
