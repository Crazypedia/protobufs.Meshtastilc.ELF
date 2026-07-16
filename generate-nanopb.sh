#!/usr/bin/env bash
# Generate nanopb C sources for the embedded (Tactility) build.
#
# Scope: the RX path (MeshPacket, Data, User, Position, Telemetry) plus the
# client/config API surface (AdminMessage, ChannelSet, LocalConfig, ChannelFile,
# DeviceState, canned messages) and their transitive imports.
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
    meshtastic/admin.proto
    meshtastic/apponly.proto
    meshtastic/cannedmessages.proto
    meshtastic/clientonly.proto
    meshtastic/connection_status.proto
    meshtastic/deviceonly.proto
    meshtastic/localonly.proto
    meshtastic/mqtt.proto
)

"$PYTHON" nanopb/generator/nanopb_generator.py \
    --protoc-insertion-points \
    -I . \
    -D "$OUT" \
    "${PROTOS[@]}"

# deviceonly.proto declares std::vector callback datatypes upstream, making its
# generated code C++-only. Rename to .pb.cpp so build systems compile it as C++.
# Its header must likewise only be included from C++ translation units.
mv "$OUT/meshtastic/deviceonly.pb.c" "$OUT/meshtastic/deviceonly.pb.cpp"

echo "Generated $(ls "$OUT"/meshtastic/*.pb.c* | wc -l) .pb.c/.pb.cpp files into $OUT/meshtastic/"
