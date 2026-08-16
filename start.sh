#!/bin/bash
set -e

CONFIG_PATH="/data/homeserver.yaml"
PORT_TO_USE="${PORT:-10000}"
SERVER_NAME="${RENDER_EXTERNAL_HOSTNAME}"

echo "======================================"
echo "MATRIX SYNAPSE"
echo "SERVER_NAME=$SERVER_NAME"
echo "PORT=$PORT_TO_USE"
echo "======================================"

mkdir -p /data

if [ ! -f "$CONFIG_PATH" ]; then

    echo "Generating Synapse configuration..."

    python3 -m synapse.app.homeserver \
        --generate-config \
        --server-name="$SERVER_NAME" \
        --config-path="$CONFIG_PATH" \
        --report-stats=no
fi

echo "Configuring registration..."

python3 - "$CONFIG_PATH" <<'PY'
from pathlib import Path
import re
import sys

p = Path(sys.argv[1])
text = p.read_text()

settings = {
    "enable_registration": "true",
    "enable_registration_without_verification": "true",
}

for key, value in settings.items():
    pattern = rf"(?m)^{re.escape(key)}:.*$"

    if re.search(pattern, text):
        text = re.sub(
            pattern,
            f"{key}: {value}",
            text
        )
    else:
        text += f"\n{key}: {value}\n"

p.write_text(text)
PY

echo "REGISTRATION:"
grep -E \
    '^(enable_registration|enable_registration_without_verification):' \
    "$CONFIG_PATH" || true

echo "Configuring listener..."

python3 - "$CONFIG_PATH" "$PORT_TO_USE" <<'PY'
from pathlib import Path
import sys
import re

p = Path(sys.argv[1])
port = sys.argv[2]

text = p.read_text()

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

text, count = re.subn(
    pattern,
    replacement,
    text,
    count=1
)

if count:
    p.write_text(text)
    print("Listener configured.")
else:
    print("WARNING: listener not changed.")
PY

echo "Starting Synapse..."

exec python3 -m synapse.app.homeserver \
    --config-path="$CONFIG_PATH"
