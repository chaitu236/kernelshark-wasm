# Runtime image

The runtime image uses unprivileged nginx on port 8080 to serve the generated
KernelShark bundle. It enables static gzip negotiation and the cross-origin
isolation headers required by WebAssembly pthreads.

Build and run it after `./build.sh`:

```bash
./build_runtime.sh
docker run --rm --publish 8080:8080 kernelshark-wasm
```

Open `http://127.0.0.1:8080/`. The health endpoint is available at
`http://127.0.0.1:8080/healthz`.