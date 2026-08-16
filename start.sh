#!/bin/bash
set -euo pipefail

CONFIG_PATH="/data/homeserver.yaml"
PORT_TO_USE="${PORT:-10000}"
SERVER_NAME="${RENDER_EXTERNAL_HOSTNAME}"

echo "======================================"
echo "Starting Matrix Synapse"
echo "SERVER_NAME=${SERVER_NAME}"
echo "PORT=${PORT_TO_USE}"
echo "======================================"

mkdir -p /data

if [ ! -f "$CONFIG_PATH" ]; then
    echo "Generating Synapse configuration..."

    python3 -m synapse.app.homeserver \
        --generate-config \
        --server-name="${SERVER_NAME}" \
        --config-path="${CONFIG_PATH}" \
        --report-stats=no

    echo "Enabling registration..."

    sed -i \
        's/enable_registration: false/enable_registration: true/' \
        "${CONFIG_PATH}"
fi

echo "Configuring Synapse listener..."

python3 - "${CONFIG_PATH}" "${PORT_TO_USE}" <<'PY'
import sys
from pathlib import Path

config_path = Path(sys.argv[1])
port = sys.argv[2]

text = config_path.read_text()

# Change default Synapse port 8008 -> Render's PORT.
text = text.replace(
    "port: 8008",
    f"port: {port}",
    1
)

# Listen on all interfaces so Render can reach Synapse.
text = text.replace(
    "bind_addresses:\n      - ::1\n      - 127.0.0.1",
    "bind_addresses:\n      - 0.0.0.0",
    1
)

text = text.replace(
    "bind_addresses:\n      - 127.0.0.1",
    "bind_addresses:\n      - 0.0.0.0",
    1
)

config_path.write_text(text)
PY

echo "======================================"
echo "Synapse listener configuration:"
grep -A15 "listeners:" "${CONFIG_PATH}" || true
echo "======================================"

echo "Starting Synapse..."

exec python3 -m synapse.app.homeserver \
    --config-path="${CONFIG_PATH}"
