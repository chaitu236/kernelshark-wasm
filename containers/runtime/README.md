# Runtime image

The runtime image uses unprivileged nginx on port 8080 to serve the generated
KernelShark bundle. It prefers the precompressed Brotli WebAssembly module,
falls back to static gzip or the raw module according to client support, and
adds the cross-origin isolation headers required by WebAssembly pthreads.

Build and run it after `./build.sh`:

```bash
./build_runtime.sh
docker run --rm --publish 8080:8080 kernelshark-wasm
```

Open `http://127.0.0.1:8080/`. The health endpoint is available at
`http://127.0.0.1:8080/healthz`.