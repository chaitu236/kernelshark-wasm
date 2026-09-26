#!/usr/bin/env bash

set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
DOCKER=${DOCKER:-docker}
RUNTIME_IMAGE=${RUNTIME_IMAGE:-kernelshark-wasm}
DIST_DIR="$ROOT/out/wasm-release/dist"

for artifact in \
	kernelshark.html \
	kernelshark.js \
	kernelshark.js.gz \
	kernelshark.wasm \
	kernelshark.wasm.br \
	kernelshark.wasm.gz \
	kernelshark.worker.js \
	kernelshark.worker.js.gz \
	favicon.svg \
	favicon-license.txt \
	qtloader.js; do
	if [[ ! -f "$DIST_DIR/$artifact" ]]; then
		echo "Missing build artifact: $DIST_DIR/$artifact" >&2
		echo "Run ./build.sh before building the runtime image." >&2
		exit 1
	fi
done

exec "$DOCKER" build \
	--file "$ROOT/containers/runtime/Dockerfile" \
	--tag "$RUNTIME_IMAGE" \
	"$@" \
	"$ROOT"