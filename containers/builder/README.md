# Builder image

This image contains Emscripten 3.1.14, the Brotli artifact encoder, and matching
host and thread-enabled WebAssembly builds of Qt 6.4.2. Build it from the
repository root with:

```bash
./build_container.sh
```

The Qt layers are intentionally expensive. Rebuilding application dependencies
does not rebuild the image unless the Dockerfile or its inputs change.

After Qt installation, the image collects Qt and bundled codec/font license
texts, copyright notices, and acknowledgments into `${QT_WASM}/licenses`.
The collector uses the already-downloaded Qt source tree, with no additional
download. A checksum manifest accompanies the notices. Normal application builds
only copy these local files into the distribution.

Builder images created before notice collection was added need rebuilding.
Alternatively, configure a matching pre-generated bundle with
`-DKS_QT_LICENSE_DIR=/path/to/bundle`; collection never downloads missing notices.

The final image exports:

```text
EMSDK=/emsdk
QT_HOST_PATH=/opt/qt/6.4.2/host
QT_WASM=/opt/qt/6.4.2/wasm-threaded
```

Its entrypoint activates Emscripten and then executes the supplied command.
