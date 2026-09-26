#!/usr/bin/env bash

set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
DOCKER=${DOCKER:-docker}
RUNTIME_IMAGE=${RUNTIME_IMAGE:-kernelshark-wasm}
DIST_DIR="$ROOT/out/wasm-release/dist"
VERSION_FILE="$DIST_DIR/asset-version.txt"

for artifact in \
	kernelshark.html \
	favicon-license.txt \
	asset-version.txt; do
	if [[ ! -f "$DIST_DIR/$artifact" ]]; then
		echo "Missing build artifact: $DIST_DIR/$artifact" >&2
		echo "Run ./build.sh before building the runtime image." >&2
		exit 1
	fi
done

asset_version=$(<"$VERSION_FILE")
if [[ ! "$asset_version" =~ ^[0-9a-f]{64}$ ]]; then
	echo "Invalid asset version: $asset_version" >&2
	exit 1
fi
if ! grep --fixed-strings --quiet "assets/$asset_version" \
	"$DIST_DIR/kernelshark.html"; then
	echo "HTML does not reference asset version: $asset_version" >&2
	exit 1
fi

ASSET_DIR="$DIST_DIR/assets/$asset_version"
for artifact in \
	kernelshark.js \
	kernelshark.js.gz \
	kernelshark.wasm \
	kernelshark.wasm.br \
	kernelshark.wasm.gz \
	kernelshark.worker.js \
	kernelshark.worker.js.gz \
	favicon.svg \
	qtloader.js; do
	if [[ ! -f "$ASSET_DIR/$artifact" ]]; then
		echo "Missing versioned asset: $ASSET_DIR/$artifact" >&2
		echo "Run ./build.sh before building the runtime image." >&2
		exit 1
	fi
done

exec "$DOCKER" build \
	--file "$ROOT/containers/runtime/Dockerfile" \
	--tag "$RUNTIME_IMAGE" \
	"$@" \
	"$ROOT"