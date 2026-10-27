#!/usr/bin/env bash

set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
DOCKER=${DOCKER:-docker}
BUILDER_IMAGE=${BUILDER_IMAGE:-kernelshark-wasm-builder}

if [[ "${1:-}" == "--print-image-tag" ]]; then
	if (( $# != 1 )); then
		printf '%s\n' '--print-image-tag does not accept build options' >&2
		exit 1
	fi
	cd "$ROOT"
	input_hash=$(sha256sum \
		build_container.sh \
		containers/builder/Dockerfile \
		containers/builder/Dockerfile.dockerignore \
		containers/builder/entrypoint.sh \
		cmake/CollectQtLicenses.cmake | sha256sum)
	printf 'linux-amd64-%s\n' "${input_hash%% *}"
	exit 0
fi

exec "$DOCKER" build \
	--file "$ROOT/containers/builder/Dockerfile" \
	--tag "$BUILDER_IMAGE" \
	"$@" \
	"$ROOT"
