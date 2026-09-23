# Builder image

This image contains Emscripten 3.1.14 and matching host and thread-enabled
WebAssembly builds of Qt 6.4.2. Build it from the repository root with:

```bash
./build_container.sh
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