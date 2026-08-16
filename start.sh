#!/bin/bash
# Generate config if missing
if [ ! -f /data/homeserver.yaml ]; then
    python3 -m synapse.app.homeserver \
        --generate-config \
        --server-name="$RENDER_EXTERNAL_HOSTNAME" \
        --config-path=/data/homeserver.yaml
    
    sed -i 's/enable_registration: false/enable_registration: true/g' /data/homeserver.yaml
fi

# Render passes a dynamic port via $PORT. We need to update homeserver.yaml port or let it bind correctly.
# For a quick fix, let's run Synapse:
exec python3 -m synapse.app.homeserver --config-path /data/homeserver.yaml
