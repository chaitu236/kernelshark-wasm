# kernelshark-wasm

[KernelShark](https://kernelshark.org/) is a Linux kernel trace viewer. This
project cross-compiles KernelShark and its dependencies to WebAssembly so it can
run in a web browser.

## Build and Run

Requires Docker or a compatible container engine such as Podman.

```bash
./build_container.sh
./build.sh
./build_runtime.sh
docker run --rm --publish 8080:8080 kernelshark-wasm
```

Open [http://127.0.0.1:8080/](http://127.0.0.1:8080/).

Build output is written to `out/wasm-release/dist/`.

### Configuration

Set these environment variables when running the scripts as needed:

| Variable | Purpose | Default |
| --- | --- | --- |
| `DOCKER` | Container command, such as `podman` | `docker` |
| `BUILDER_IMAGE` | Toolchain image name | `kernelshark-wasm-builder` |
| `RUNTIME_IMAGE` | Application image name | `kernelshark-wasm` |
| `BUILD_JOBS` | Parallel build jobs | Number of CPUs |
| `CMAKE_PRESET` | CMake preset used by `build.sh` | `wasm-release` |

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) and the
[browser test instructions](tests/README.md).

## Licensing

Independently authored project code is **MIT**-licensed unless otherwise noted.
Upstream code, derived patches, and third-party assets retain their own licenses.

The open-source Qt WebAssembly port requires the combined application to be
distributed under **GPL-3.0-only**, preserving applicable component terms.
See [LICENSE](LICENSE) for details. Build output includes license texts,
third-party notices, and source information.
