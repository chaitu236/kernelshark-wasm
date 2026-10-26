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
- an unprivileged nginx runtime image for the generated application

Testing, publication, and Kubernetes deployment are intentionally outside the
current scope.

## Licensing

Independently authored project code is licensed under **MIT**, except
where another license applies. Upstream code, upstream-derived patches, and
third-party assets retain their applicable licenses; this is not a blanket
relicensing of the repository or its history.

The combined application built with the pinned open-source Qt WebAssembly port
must be distributed under **GPL-3.0-only**, while preserving applicable component
terms. See [LICENSE](LICENSE) for the grant and its scope. The full license texts
are provided in
[LICENSES/MIT.txt](LICENSES/MIT.txt),
[LICENSES/LGPL-2.1-only.txt](LICENSES/LGPL-2.1-only.txt), and
[LICENSES/GPL-3.0-only.txt](LICENSES/GPL-3.0-only.txt).

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
├── LICENSE                              # project licensing scope
├── LICENSES/                            # project, upstream, Qt and runtime texts
├── THIRD-PARTY-NOTICES.txt               # attribution and notice-file index
├── kernelshark.html                     # not hashed; contains the resulting hash
├── asset-version.txt                    # resulting bundle hash
├── favicon-license.txt                  # distribution metadata; not hashed
└── assets/<sha256>/
    ├── favicon.svg                      # hash input
    ├── kernelshark.js                   # hash input
    ├── kernelshark.js.gz                # generated representation; not hashed
    ├── kernelshark.wasm                 # hash input
    ├── kernelshark.wasm.br              # generated representation; not hashed
    ├── kernelshark.wasm.gz              # generated representation; not hashed
    ├── kernelshark.worker.js            # hash input
    ├── kernelshark.worker.js.gz         # generated representation; not hashed
    └── qtloader.js                      # hash input
```

The SHA-256 directory is calculated from the five files marked `hash input`.
The root HTML is then regenerated with references to that directory.

## Build and run the application image

Build the nginx runtime image after `./build.sh`:

```bash
./build_runtime.sh
```

Run it locally:

```bash
docker run --rm --publish 8080:8080 kernelshark-wasm
```

Open `http://127.0.0.1:8080/`. The health endpoint is available at
`http://127.0.0.1:8080/healthz`.

The runtime image uses unprivileged nginx on port 8080. It prefers the
Brotli-11 WebAssembly artifact when supported, uses the `.gz` files generated
by the superbuild as a compatibility fallback, and adds the
`Cross-Origin-Opener-Policy` and `Cross-Origin-Embedder-Policy` headers required
by WebAssembly pthreads. Raw artifacts remain available for clients that do not
advertise Brotli or gzip support. Nginx serves the root HTML with `no-cache`
and versioned assets with a one-year `immutable` cache policy.

Deploy the runtime image atomically so clients see either the complete old
bundle or the complete new bundle. A non-atomic rolling deployment must instead
retain older asset directories until no served HTML can reference them.

Override the runtime image name or Docker-compatible command with:

```bash
DOCKER=podman RUNTIME_IMAGE=example/kernelshark-wasm ./build_runtime.sh
```

Container definitions are separated by responsibility:

```text
containers/
├── builder/    # Emscripten and threaded Qt build environment
└── runtime/    # nginx application image
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
    -DKS_QT_WASM_ROOT=/path/to/threaded/qt-wasm \
    -DKS_QT_LICENSE_DIR=/path/to/qt-license-bundle

cmake --build --preset wasm-release
```

The source and build trees fetched by `ExternalProject` are contained entirely
under the selected CMake binary directory.

The builder image supplies its Qt notice bundle under `${QT_WASM}/licenses`.
For a local Qt build, generate the matching bundle once from its source tree:

```bash
cmake \
    -DKS_QT_SOURCE_ROOT=/path/to/qt-everywhere-src-6.4.2 \
    -DKS_QT_LICENSE_DIR=/path/to/qt-license-bundle \
    -DKS_QT_VERSION=6.4.2 \
    -P cmake/CollectQtLicenses.cmake
```
