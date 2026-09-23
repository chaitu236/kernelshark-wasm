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
./build_container.sh
```

Configure and build the superbuild:

```bash
./build.sh
```

Both scripts can use a different Docker-compatible command or image name:

```bash
DOCKER=podman BUILDER_IMAGE=example/kernelshark-wasm-builder ./build_container.sh
DOCKER=podman BUILDER_IMAGE=example/kernelshark-wasm-builder ./build.sh
```

`build.sh` also accepts `CMAKE_PRESET` and `BUILD_JOBS` environment overrides.

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

## Developing KernelShark changes

The reproducible build always fetches the pinned upstream KernelShark revision
and applies the patches in `patches/kernel-shark/`. Develop new KernelShark
changes in a separate checkout rather than editing the disposable checkout
under `out/`.

Start a development branch from the revision recorded in
`cmake/Versions.cmake`, then apply the current WASM patch series:

```bash
git clone https://git.kernel.org/pub/scm/utils/trace-cmd/kernel-shark.git
cd kernel-shark
git switch --create my-change 60ac62e57bd4bbdb7d206d30ea0280d041287792
git apply ../kernelshark-wasm/patches/kernel-shark/*.patch
```

Develop and commit the change in that checkout. Export the finished commit into
this repository:

```bash
git format-patch -1 HEAD \
    --output-directory ../kernelshark-wasm/patches/kernel-shark
```

Patch files are applied in lexical filename order. Check that a new patch has a
unique numeric prefix and applies after the existing series.

Remove only the KernelShark external-project state before rebuilding, so the
dependency sysroot is reused:

```bash
rm -rf \
    out/wasm-release/sources/kernelshark \
    out/wasm-release/builds/kernelshark \
    out/wasm-release/stamps/kernelshark

./build.sh
```

For a completely clean application and dependency build, remove the entire
`out/wasm-release` directory before running `./build.sh`.

A local-source override is not currently implemented. If development becomes
frequent, a future `KS_KERNELSHARK_SOURCE_DIR` option can bypass download and
patch steps while retaining pinned dependencies. The upstream pin plus patch
series remains the release and reproducibility path.

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
