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
import re
import sys
from pathlib import Path

config_path = Path(sys.argv[1])
port = sys.argv[2]

text = config_path.read_text()

# Replace the generated HTTP listener block.
pattern = (
    r"(?ms)^  - bind_addresses:\n"
    r"(?:    - .*\n)+"
    r"    port: \d+"
)

replacement = (
    "  - bind_addresses:\n"
    "    - 0.0.0.0\n"
    f"    port: {port}"
)

new_text, count = re.subn(pattern, replacement, text, count=1)

if count == 0:
    print("ERROR: Could not find Synapse listener block")
    sys.exit(1)

config_path.write_text(new_text)

print("Listener successfully configured.")
PY

echo "======================================"
echo "FINAL SYNAPSE LISTENER:"
grep -A15 "listeners:" "${CONFIG_PATH}"
echo "======================================"

echo "Starting Synapse..."

exec python3 -m synapse.app.homeserver \
    --config-path="${CONFIG_PATH}"
