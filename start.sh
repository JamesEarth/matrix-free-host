#!/bin/bash
# Generate config if missing
if [ ! -f /data/homeserver.yaml ]; then
    python3 -m synapse.app.homeserver \
        --generate-config \
        --server-name="$RENDER_EXTERNAL_HOSTNAME" \
        --config-path=/data/homeserver.yaml
    
    # Enable registration by default so you can sign up your admin account
    sed -i 's/enable_registration: false/enable_registration: true/g' /data/homeserver.yaml
fi

# Start Synapse
exec python3 -m synapse.app.homeserver --config-path /data/homeserver.yaml
