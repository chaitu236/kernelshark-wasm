#!/bin/sh

set -eu

emsdk_dir=${EMSDK:-/emsdk}
working_dir=$PWD
cd "$emsdk_dir"
. ./emsdk_env.sh >/dev/null
cd "$working_dir"

exec "$@"
