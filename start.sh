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

# Generate config only on first startup
if [ ! -f "$CONFIG_PATH" ]; then
    echo "Generating Synapse configuration..."

    python3 -m synapse.app.homeserver \
        --generate-config \
        --server-name="${SERVER_NAME}" \
        --config-path="${CONFIG_PATH}" \
        --report-stats=no
fi

# --------------------------------------------------
# FORCE REGISTRATION SETTINGS
# --------------------------------------------------

echo "======================================"
echo "Configuring registration..."
echo "======================================"

python3 - "$CONFIG_PATH" <<'PY'
from pathlib import Path
import re
import sys

path = Path(sys.argv[1])
text = path.read_text()

settings = {
    "enable_registration": "true",
    "enable_registration_without_verification": "true",
}

for key, value in settings.items():
    pattern = rf"(?m)^{re.escape(key)}:.*$"
    replacement = f"{key}: {value}"

    if re.search(pattern, text):
        text = re.sub(pattern, replacement, text)
    else:
        text += f"\n{replacement}\n"

path.write_text(text)
PY

echo "CURRENT REGISTRATION CONFIG:"
grep -E '^(enable_registration|enable_registration_without_verification):' \
    "$CONFIG_PATH" || true

# --------------------------------------------------
# CONFIGURE PORT + LISTENER
# --------------------------------------------------

echo "======================================"
echo "Configuring listener..."
echo "======================================"

python3 - "$CONFIG_PATH" "$PORT_TO_USE" <<'PY'
import re
import sys
from pathlib import Path

path = Path(sys.argv[1])
port = sys.argv[2]

text = path.read_text()

# Replace the generated listener bind addresses and port.
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
    print("WARNING: listener pattern not found")
else:
    path.write_text(text)
    print("Listener configured successfully")
PY

echo "======================================"
echo "FINAL REGISTRATION SETTINGS"
echo "======================================"

grep -E '^(enable_registration|enable_registration_without_verification):' \
    "$CONFIG_PATH" || true

echo "======================================"
echo "FINAL LISTENER"
echo "======================================"

grep -A15 "listeners:" "$CONFIG_PATH" || true

echo "======================================"
echo "Starting Synapse..."
echo "======================================"

exec python3 -m synapse.app.homeserver \
    --config-path="$CONFIG_PATH"
