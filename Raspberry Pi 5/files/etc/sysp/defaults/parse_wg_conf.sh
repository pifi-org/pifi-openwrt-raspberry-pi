#!/bin/bash

# Function to parse the .conf file and set UCI configuration
parse_and_set_uci() {
    file="$1"
    # Get the raw filename without the extension
    raw_filename=$(basename "$file" .conf)
    # Replace any non-alphanumeric characters with underscores
    filename=$(echo "$raw_filename" | sed 's/[^a-zA-Z0-9]/_/g')

    # Print the filename for debugging
    echo "raw filename: $raw_filename"
    echo "sanitized filename: $filename"

    # Read the necessary values from the .conf file
    privateKey=$(grep 'PrivateKey' "$file" | awk -F '=' '{print $2"="$3}' | xargs)
    publicKey=$(grep 'PublicKey' "$file" | awk -F '=' '{print $2"="$3}' | xargs)
    presharedKey=$(grep 'PresharedKey' "$file" | awk -F '=' '{print $2"="$3}' | xargs)
    address=$(grep 'Address' "$file" | awk -F '=' '{print $2}' | xargs)
    dns=$(grep 'DNS' "$file" | awk -F '=' '{print $2}' | xargs | cut -d ',' -f 1 | awk '{print $1}')
    endpoint=$(grep 'Endpoint' "$file" | awk -F '=' '{print $2}' | xargs)

    # Filter and process the address
    address=$(echo "$address" | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}(/\d{1,2})?' | sed 's#^\([0-9\.]*\)$#\1/32#')

    # Process the endpoint
    endpoint_host=$(echo "$endpoint" | cut -d':' -f1)
    endpoint_port=$(echo "$endpoint" | cut -d':' -f2)
    if [ -z "$endpoint_port" ]; then
        endpoint_port="51820"
    fi

    # Debug output
    echo "privateKey: $privateKey"
    echo "publicKey: $publicKey"
    echo "presharedKey: $presharedKey"
    echo "address: $address"
    echo "dns: $dns"
    echo "endpoint_host: $endpoint_host"
    echo "endpoint_port: $endpoint_port"

    # Check if the values were correctly extracted
    if [ -z "$privateKey" ] || [ -z "$publicKey" ] || [ -z "$address" ] || [ -z "$dns" ] || [ -z "$endpoint_host" ]; then
        echo "Error: Missing necessary values in $file"
        return 1
    fi

    # Remove existing interface if it exists
    if uci get wireguard.${filename} &> /dev/null; then
        echo "Removing existing interface $filename"
        uci delete wireguard.${filename}
    fi

    # Remove existing peers if they exist
    peer_sections=$(uci show wireguard | grep "wireguard_${filename}" | cut -d'.' -f2)
    for peer in $peer_sections; do
        echo "Removing existing peer $peer"
        uci delete wireguard.${peer}
    done

    # Set UCI configuration in the /etc/config/wireguard file
    echo "Running UCI commands..."
    echo "uci set wireguard.${filename}='interface'"
    uci set wireguard.${filename}='interface'
    if [ $? -ne 0 ]; then echo "Error: Failed to set interface for $filename"; return 1; fi
    echo "Set wireguard.${filename}='interface'"

    echo "uci set wireguard.${filename}.proto='wireguard'"
    uci set wireguard.${filename}.proto='wireguard'
    if [ $? -ne 0 ]; then echo "Error: Failed to set proto for $filename"; return 1; fi
    echo "Set wireguard.${filename}.proto='wireguard'"

    echo "uci set wireguard.${filename}.private_key='${privateKey}'"
    uci set wireguard.${filename}.private_key="${privateKey}"
    if [ $? -ne 0 ]; then echo "Error: Failed to set private_key for $filename"; return 1; fi
    echo "Set wireguard.${filename}.private_key='${privateKey}'"

    echo "uci set wireguard.${filename}.disabled='0'"
    uci set wireguard.${filename}.disabled='0'
    if [ $? -ne 0 ]; then echo "Error: Failed to set disabled for $filename"; return 1; fi
    echo "Set wireguard.${filename}.disabled='0'"

    echo "uci set wireguard.${filename}.addresses='${address}'"
    uci set wireguard.${filename}.addresses="${address}"
    if [ $? -ne 0 ]; then echo "Error: Failed to set addresses for $filename"; return 1; fi
    echo "Set wireguard.${filename}.addresses='${address}'"

    echo "uci set wireguard.${filename}.dns='${dns}'"
    uci set wireguard.${filename}.dns="${dns}"
    if [ $? -ne 0 ]; then echo "Error: Failed to set dns for $filename"; return 1; fi
    echo "Set wireguard.${filename}.dns='${dns}'"

    # Add WireGuard peer configuration
    peer=$(uci add wireguard wireguard_${filename})
    if [ $? -ne 0 ]; then echo "Error: Failed to add peer for $filename"; return 1; fi
    echo "Added peer wireguard.${peer}"

    echo "uci set wireguard.${peer}.public_key='${publicKey}'"
    uci set wireguard.${peer}.public_key="${publicKey}"
    if [ $? -ne 0 ]; then echo "Error: Failed to set public_key for $peer"; return 1; fi
    echo "Set wireguard.${peer}.public_key='${publicKey}'"

    echo "uci set wireguard.${peer}.private_key='${privateKey}'"
    uci set wireguard.${peer}.private_key="${privateKey}"
    if [ $? -ne 0 ]; then echo "Error: Failed to set private_key for $peer"; return 1; fi
    echo "Set wireguard.${peer}.private_key='${privateKey}'"

    echo "uci set wireguard.${peer}.persistent_keepalive='25'"
    uci set wireguard.${peer}.persistent_keepalive='25'
    if [ $? -ne 0 ]; then echo "Error: Failed to set persistent_keepalive for $peer"; return 1; fi
    echo "Set wireguard.${peer}.persistent_keepalive='25'"

    echo "uci set wireguard.${peer}.disabled='0'"
    uci set wireguard.${peer}.disabled='0'
    if [ $? -ne 0 ]; then echo "Error: Failed to set disabled for $peer"; return 1; fi
    echo "Set wireguard.${peer}.disabled='0'"

    echo "uci add_list wireguard.${peer}.allowed_ips='0.0.0.0/1'"
    uci add_list wireguard.${peer}.allowed_ips='0.0.0.0/1'
    if [ $? -ne 0 ]; then echo "Error: Failed to add allowed_ips (0.0.0.0/1) for $peer"; return 1; fi
    echo "Added allowed_ips (0.0.0.0/1) for wireguard.${peer}"

    echo "uci add_list wireguard.${peer}.allowed_ips='128.0.0.0/1'"
    uci add_list wireguard.${peer}.allowed_ips='128.0.0.0/1'
    if [ $? -ne 0 ]; then echo "Error: Failed to add allowed_ips (128.0.0.0/1) for $peer"; return 1; fi
    echo "Added allowed_ips (128.0.0.0/1) for wireguard.${peer}"

    echo "uci set wireguard.${peer}.route_allowed_ips='1'"
    uci set wireguard.${peer}.route_allowed_ips='1'
    if [ $? -ne 0 ]; then echo "Error: Failed to set route_allowed_ips for $peer"; return 1; fi
    echo "Set wireguard.${peer}.route_allowed_ips='1'"

    echo "uci set wireguard.${peer}.endpoint_host='${endpoint_host}'"
    uci set wireguard.${peer}.endpoint_host="${endpoint_host}"
    if [ $? -ne 0 ]; then echo "Error: Failed to set endpoint_host for $peer"; return 1; fi
    echo "Set wireguard.${peer}.endpoint_host='${endpoint_host}'"

    echo "uci set wireguard.${peer}.endpoint_port='${endpoint_port}'"
    uci set wireguard.${peer}.endpoint_port="${endpoint_port}"
    if [ $? -ne 0 ]; then echo "Error: Failed to set endpoint_port for $peer"; return 1; fi
    echo "Set wireguard.${peer}.endpoint_port='${endpoint_port}'"

    if [ -n "$presharedKey" ]; then
        echo "uci set wireguard.@wireguard_${filename}[-1].preshared_key='${presharedKey}'"
        uci set wireguard.@wireguard_${filename}[-1].preshared_key="${presharedKey}"
        if [ $? -ne 0 ]; then echo "Error: Failed to set preshared_key for $peer"; return 1; fi
        echo "Set wireguard.@wireguard_${filename}[-1].preshared_key='${presharedKey}'"
    fi

    echo "uci commit wireguard"
    uci commit wireguard
    if [ $? -ne 0 ]; then echo "Error: Failed to commit wireguard settings for $filename"; return 1; fi
    echo "Successfully configured WireGuard for $filename"
}

# Check if a filename is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <path_to_conf_file>"
    exit 1
fi

# Process the provided .conf file
if [ -e "$1" ]; then
    parse_and_set_uci "$1"
else
    echo "File not found: $1"
    exit 1
fi