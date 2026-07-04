#!/usr/bin/env bash
# Generate nanopb C sources for the embedded (Tactility) build.
#
# Scope: the transitive import closure of mesh.proto — the RX-path minimum
# (MeshPacket, Data, User, Position, Telemetry) plus the files they import.
# Per-message sizing/callback options come from the meshtastic/*.options
# files maintained upstream.
#
# Requires: python3 with the `protobuf` and `grpcio-tools` packages, and the
# nanopb submodule checked out (git submodule update --init).
set -euo pipefail

cd "$(dirname "$0")"

PYTHON="${PYTHON:-python3}"
if ! "$PYTHON" -c 'import grpc_tools.protoc' 2>/dev/null; then
    for candidate in /usr/bin/python3 python3; do
        if "$candidate" -c 'import grpc_tools.protoc' 2>/dev/null; then
            PYTHON="$candidate"
            break
        fi
    done
fi
"$PYTHON" -c 'import grpc_tools.protoc' || {
    echo "error: no python3 with grpcio-tools found (pip install protobuf grpcio-tools)" >&2
    exit 1
}

OUT=generated
mkdir -p "$OUT"

PROTOS=(
    meshtastic/mesh.proto
    meshtastic/channel.proto
    meshtastic/config.proto
    meshtastic/device_ui.proto
    meshtastic/module_config.proto
    meshtastic/atak.proto
    meshtastic/portnums.proto
    meshtastic/telemetry.proto
    meshtastic/xmodem.proto
)

"$PYTHON" nanopb/generator/nanopb_generator.py \
    --protoc-insertion-points \
    -I . \
    -D "$OUT" \
    "${PROTOS[@]}"

echo "Generated $(ls "$OUT"/meshtastic/*.pb.c | wc -l) .pb.c files into $OUT/meshtastic/"
