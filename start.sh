#!/bin/bash
# Generate config if missing
if [ ! -f /data/homeserver.yaml ]; then
    python3 -m synapse.app.homeserver \
        --generate-config \
        --server-name="$RENDER_EXTERNAL_HOSTNAME" \
        --config-path=/data/homeserver.yaml
    
    # Enable registration
    sed -i 's/enable_registration: false/enable_registration: true/g' /data/homeserver.yaml
fi

# Update port in homeserver.yaml to match Render's expected $PORT
sed -i "s/port: 8008/port: ${PORT:-10000}/g" /data/homeserver.yaml
sed -i "s/bind_addresses: \['::1', '127\.0\.0\.1'\]/bind_addresses: \['0\.0\.0\.0'\]/g" /data/homeserver.yaml

# Start Synapse
exec python3 -m synapse.app.homeserver --config-path /data/homeserver.yaml
