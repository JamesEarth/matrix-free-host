#!/bin/bash
set -euxo pipefail

CONFIG_PATH="/data/homeserver.yaml"
PORT_TO_USE="${PORT:-10000}"

echo "========================================"
echo "Starting Matrix Synapse"
echo "PORT=${PORT_TO_USE}"
echo "HOST=${RENDER_EXTERNAL_HOSTNAME:-unknown}"
echo "========================================"

mkdir -p /data

if [ ! -f "$CONFIG_PATH" ]; then
    echo "Generating Synapse configuration..."

    python3 -m synapse.app.homeserver \
        --generate-config \
        --server-name="${RENDER_EXTERNAL_HOSTNAME}" \
        --config-path="$CONFIG_PATH" \
        --report-stats=no

    echo "Enabling registration..."
    sed -i 's/enable_registration: false/enable_registration: true/' "$CONFIG_PATH"
fi

echo "Config generated/found:"
ls -lh "$CONFIG_PATH"

echo "Changing Synapse listener to Render port ${PORT_TO_USE}..."

python3 - "$CONFIG_PATH" "$PORT_TO_USE" <<'PY'
import sys
from pathlib import Path

config = Path(sys.argv[1])
port = sys.argv[2]

text = config.read_text()

# Synapse generated config normally contains:
#   port: 8008
#   bind_addresses:
#     - ::1
#     - 127.0.0.1

text = text.replace("port: 8008", f"port: {port}")

text = text.replace(
    "bind_addresses:\n      - ::1\n      - 127.0.0.1",
    "bind_addresses:\n      - 0.0.0.0"
)

text = text.replace(
    "bind_addresses:\n      - 127.0.0.1",
    "bind_addresses:\n      - 0.0.0.0"
)

config.write_text(text)
PY

echo "Checking listener configuration..."
grep -A8 -B2 "listeners:" "$CONFIG_PATH" || true

echo "Starting Synapse..."

exec python3 -m synapse.app.homeserver \
    --config-path="$CONFIG_PATH"
