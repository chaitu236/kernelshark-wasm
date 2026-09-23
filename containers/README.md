# Container images

- [`builder/`](builder/) contains the pinned Emscripten and threaded Qt build
  environment used by `build.sh`.
- [`runtime/`](runtime/) contains the unprivileged nginx image that serves the
  generated files from `out/wasm-release/dist/`.

Use `./build_container.sh` for the builder image and `./build_runtime.sh` for
the runtime image.