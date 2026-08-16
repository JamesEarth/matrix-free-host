#!/bin/bash
set -e

CONFIG_PATH="/data/homeserver.yaml"
PORT_TO_USE="${PORT:-10000}"

# Generate config if it doesn't exist
if [ ! -f "$CONFIG_PATH" ]; then
    python3 -m synapse.app.homeserver \
        --generate-config \
        --server-name="${RENDER_EXTERNAL_HOSTNAME}" \
        --config-path="$CONFIG_PATH" \
        --report-stats=no

    sed -i 's/enable_registration: false/enable_registration: true/g' "$CONFIG_PATH"
fi

# Make Synapse listen on Render's port and all interfaces
python3 - "$CONFIG_PATH" "$PORT_TO_USE" <<'PY'
import sys
import yaml

config_path = sys.argv[1]
port = int(sys.argv[2])

with open(config_path) as f:
    config = yaml.safe_load(f)

for listener in config["listeners"]:
    if listener.get("type") == "http":
        listener["port"] = port
        listener["bind_addresses"] = ["0.0.0.0"]

with open(config_path, "w") as f:
    yaml.safe_dump(config, f, sort_keys=False)
PY

echo "Starting Synapse on 0.0.0.0:${PORT_TO_USE}"

exec python3 -m synapse.app.homeserver \
    --config-path="$CONFIG_PATH"
