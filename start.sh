#!/bin/bash
CONFIG_PATH="/data/homeserver.yaml"

# Generate config if missing
if [ ! -f "$CONFIG_PATH" ]; then
    python3 -m synapse.app.homeserver \
        --generate-config \
        --server-name="$RENDER_EXTERNAL_HOSTNAME" \
        --config-path="$CONFIG_PATH"
    
    sed -i 's/enable_registration: false/enable_registration: true/g' "$CONFIG_PATH"
fi

# Start a tiny background web server on Render's $PORT to pass health checks immediately
PORT_TO_USE=${PORT:-10000}
python3 -m http.server $PORT_TO_USE --directory /tmp &

# Start Synapse in the background or foreground
exec python3 -m synapse.app.homeserver --config-path "$CONFIG_PATH"
