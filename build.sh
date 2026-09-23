#!/usr/bin/env bash

set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
DOCKER=${DOCKER:-docker}
BUILDER_IMAGE=${BUILDER_IMAGE:-kernelshark-wasm-builder}
CMAKE_PRESET=${CMAKE_PRESET:-wasm-release}
BUILD_JOBS=${BUILD_JOBS:-$(nproc)}

container_args=(
	--rm
	--user "$(id -u):$(id -g)"
	--volume "$ROOT:/workspace"
	--workdir /workspace
)

"$DOCKER" run "${container_args[@]}" "$BUILDER_IMAGE" \
	cmake --preset "$CMAKE_PRESET"

"$DOCKER" run "${container_args[@]}" "$BUILDER_IMAGE" \
	cmake --build --preset "$CMAKE_PRESET" --parallel "$BUILD_JOBS"
