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
fi

echo "Configuring registration..."

if grep -q '^enable_registration:' "$CONFIG_PATH"; then
    sed -i 's/^enable_registration:.*/enable_registration: true/' "$CONFIG_PATH"
else
    echo 'enable_registration: true' >> "$CONFIG_PATH"
fi

if grep -q '^enable_registration_without_verification:' "$CONFIG_PATH"; then
    sed -i 's/^enable_registration_without_verification:.*/enable_registration_without_verification: true/' "$CONFIG_PATH"
else
    echo 'enable_registration_without_verification: true' >> "$CONFIG_PATH"
fi

echo "Registration settings:"
grep '^enable_registration' "$CONFIG_PATH" || true

echo "Configuring port and listener..."

python3 - "$CONFIG_PATH" "$PORT_TO_USE" <<'PY'
import re
import sys
from pathlib import Path

config_path = Path(sys.argv[1])
port = sys.argv[2]

text = config_path.read_text()

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

text, count = re.subn(pattern, replacement, text, count=1)

if count == 0:
    print("Listener already configured or pattern not found")
else:
    config_path.write_text(text)
    print("Listener configured successfully")
PY

echo "======================================"
echo "Final listener:"
grep -A15 "listeners:" "$CONFIG_PATH" || true
echo "======================================"

echo "Starting Synapse..."

exec python3 -m synapse.app.homeserver \
    --config-path="$CONFIG_PATH"
