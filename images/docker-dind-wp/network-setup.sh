#!/bin/bash
set -e

echo "Setting up Docker networks for WordPress instances..."

# Create custom bridge networks for WordPress instances
# Each instance will get its own network with a unique subnet

# Base network configuration
BASE_SUBNET="172.20.0.0/16"
NETWORK_PREFIX="wp-network"

# Create a main bridge network for inter-instance communication if needed
if ! docker network inspect wp-shared >/dev/null 2>&1; then
    echo "Creating shared network for inter-instance communication..."
    docker network create \
        --driver bridge \
        --subnet 172.21.0.0/16 \
        --opt com.docker.network.bridge.name=wp-shared \
        wp-shared
    echo "Shared network 'wp-shared' created"
fi

# Function to create isolated network for a WordPress instance
create_instance_network() {
    local instance_id=$1
    local subnet=$2
    local network_name="${NETWORK_PREFIX}-${instance_id}"
    
    if ! docker network inspect "$network_name" >/dev/null 2>&1; then
        echo "Creating network for instance ${instance_id}..."
        docker network create \
            --driver bridge \
            --subnet "$subnet" \
            --opt com.docker.network.bridge.name="wp-br-${instance_id}" \
            "$network_name"
        echo "Network '${network_name}' created with subnet ${subnet}"
    else
        echo "Network '${network_name}' already exists"
    fi
}

# Pre-create networks for first 10 instances
for i in {1..10}; do
    subnet="172.20.${i}.0/24"
    create_instance_network "$i" "$subnet"
done

echo "Network setup completed!"
echo ""
echo "Available networks:"
docker network ls | grep -E "wp-network|wp-shared"

