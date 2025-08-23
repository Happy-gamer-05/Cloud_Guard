#!/bin/bash
# regenerate_kibana_token.sh
# Script to regenerate Kibana service token and update kibana.yml

set -e

# -------------------------------
# CONFIGURATION
# -------------------------------
ELASTIC_CONTAINER="elasticsearch"
KIBANA_CONTAINER="kibana"
KIBANA_CONFIG="../kibana.yml"

# -------------------------------
# GENERATE NEW TOKEN
# -------------------------------
echo "[*] Generating new Kibana service token..."
NEW_TOKEN=$(docker exec -it $ELASTIC_CONTAINER bin/elasticsearch-service-tokens create elastic/kibana kibana-service-token \
    | grep -oE 'AAE[A-Za-z0-9]+' | tr -d '\r')

if [[ -z "$NEW_TOKEN" ]]; then
    echo "[!] Failed to generate new token."
    exit 1
fi

echo "[+] New token generated: $NEW_TOKEN"

# -------------------------------
# UPDATE kibana.yml
# -------------------------------
if [[ ! -f "$KIBANA_CONFIG" ]]; then
    echo "[!] kibana.yml not found at $KIBANA_CONFIG"
    exit 1
fi

echo "[*] Updating kibana.yml with new token..."
sed -i "s|elasticsearch.serviceAccountToken: .*|elasticsearch.serviceAccountToken: $NEW_TOKEN|" "$KIBANA_CONFIG"

echo "[+] kibana.yml updated successfully."

# -------------------------------
# RESTART KIBANA CONTAINER
# -------------------------------
echo "[*] Restarting Kibana container..."
docker restart $KIBANA_CONTAINER

echo "[+] Done! Kibana is now using the new service token."
