# kernelshark-wasm

`kernelshark-wasm` is a reproducible integration build for KernelShark on
WebAssembly. It uses canonical upstream repositories at immutable revisions,
applies the WebAssembly port as reviewable patches, and builds each component
with its existing native build system.

This repository currently provides:

- a pinned OCI builder image with Emscripten 3.1.14 and thread-enabled Qt 6.4.2
- a CMake `ExternalProject` superbuild
- a Ninja-based release preset
- a final `dist/` directory containing KernelShark browser artifacts

Testing, publication, runtime images, and deployment are intentionally outside
the current scope.

## Build with the container

Build the reusable toolchain image:

```bash
docker build \
    --file containers/Builder.Dockerfile \
    --tag kernelshark-wasm-builder .
```

Configure and build the superbuild:

```bash
docker run --rm \
    --user "$(id -u):$(id -g)" \
    --volume "$PWD:/workspace" \
    --workdir /workspace \
    kernelshark-wasm-builder \
    cmake --preset wasm-release

docker run --rm \
    --user "$(id -u):$(id -g)" \
    --volume "$PWD:/workspace" \
    --workdir /workspace \
    kernelshark-wasm-builder \
    cmake --build --preset wasm-release
```

Artifacts are written to:

```text
out/wasm-release/dist/
```

## Build graph

The superbuild uses CMake only as the orchestrator:

- json-c: CMake through `emcmake`
- libtraceevent: GNU Make through `emmake`
- libtracefs: GNU Make through `emmake`
- zstd: GNU Make through `emmake`
- trace-cmd: GNU Make through `emmake`
- KernelShark: CMake through Qt's `qt-cmake`

Source pins and the toolchain versions are centralized in
[`cmake/Versions.cmake`](cmake/Versions.cmake). Component-specific patches are
stored under [`patches/`](patches/).

## Local configuration

The same CMake project can use an existing compatible local toolchain:

```bash
cmake --preset wasm-release \
    -DKS_EMSDK_ROOT=/path/to/emsdk \
    -DKS_QT_WASM_ROOT=/path/to/threaded/qt-wasm

cmake --build --preset wasm-release
```

The source and build trees fetched by `ExternalProject` are contained entirely
under the selected CMake binary directory.
