#!/bin/bash
CONFIG_PATH="/data/homeserver.yaml"

# Generate config if it doesn't exist
if [ ! -f "$CONFIG_PATH" ]; then
    python3 -m synapse.app.homeserver \
        --generate-config \
        --server-name="$RENDER_EXTERNAL_HOSTNAME" \
        --config-path="$CONFIG_PATH"
    
    # Enable registration so you can sign up your admin/user account
    sed -i 's/enable_registration: false/enable_registration: true/g' "$CONFIG_PATH"
fi

# Bind to all interfaces and use Render's dynamic $PORT (defaulting to 10000)
PORT_TO_USE=${PORT:-10000}
sed -i "s/port: 8008/port: ${PORT_TO_USE}/g" "$CONFIG_PATH"
sed -i "s/bind_addresses: \['::1', '127\.0\.0\.1'\]/bind_addresses: \['0\.0\.0\.0'\]/g" "$CONFIG_PATH"

# Start Synapse
exec python3 -m synapse.app.homeserver --config-path "$CONFIG_PATH"
