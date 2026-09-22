# Builder image

`Builder.Dockerfile` creates the build environment used by the CMake
superbuild. It pins Emscripten 3.1.14, verifies the Qt 6.4.2 source archive,
and installs matching host and thread-enabled WebAssembly Qt builds.

Build it from the repository root:

```bash
docker build \
    --file containers/Builder.Dockerfile \
    --tag kernelshark-wasm-builder .
```

The Qt layers are intentionally expensive. Rebuilding application dependencies
does not rebuild the image unless the Dockerfile or its inputs change.

The final image exports:

```text
EMSDK=/emsdk
QT_HOST_PATH=/opt/qt/6.4.2/host
QT_WASM=/opt/qt/6.4.2/wasm-threaded
```

Its entrypoint activates Emscripten and then executes the supplied command.
