#!/usr/bin/env bash

set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
DOCKER=${DOCKER:-docker}
BUILDER_IMAGE=${BUILDER_IMAGE:-kernelshark-wasm-builder}

exec "$DOCKER" build \
	--file "$ROOT/containers/Builder.Dockerfile" \
	--tag "$BUILDER_IMAGE" \
	"$@" \
	"$ROOT"
