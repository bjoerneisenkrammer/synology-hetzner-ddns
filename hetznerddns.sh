#!/bin/bash
set -e

# DSM configuration parameters
hosts="$1"
accessToken="$2"
domain="$3"

# Initialize status variables
changes_made=false
auth_failed=false

# Function to get IP address
get_ip() {
    local ip_type="$1"
    curl -s -"$ip_type" https://ip.hetzner.com/
}

# Function to update DNS record
update_record() {
    local record_id="$1"
    local record_type="$2"
    local record_name="$3"
    local ip_addr="$4"
    local zone_id="$5"

    response=$(curl -s -X "PUT" "https://dns.hetzner.com/api/v1/records/$record_id" \
         -H "Content-Type: application/json" \
         -H "Auth-API-Token: $accessToken" \
         -d "{
      \"value\": \"$ip_addr\",
      \"ttl\": 600,
      \"type\": \"$record_type\",
      \"name\": \"$record_name\",
      \"zone_id\": \"$zone_id\"
    }")
    
    if [[ $(echo "$response" | jq -r ".record") != null ]]; then
        changes_made=true
    else
        auth_failed=true
    fi
}

# Get current IP addresses
ipv4=$(get_ip 4)
ipv6=$(get_ip 6)

# Get zone information
zone_info=$(curl -s "https://dns.hetzner.com/api/v1/zones" -H "Auth-API-Token: $accessToken")
zone_id=$(echo "$zone_info" | jq -r ".zones[] | select(.name == \"$domain\") | .id")

if [[ -z "$zone_id" ]]; then
    echo "badauth"
    exit 0
fi

# Get records for the zone
records_info=$(curl -s "https://dns.hetzner.com/api/v1/records?zone_id=$zone_id" -H "Auth-API-Token: $accessToken")

# Update records for each host
IFS=',' read -ra host_array <<< "$hosts"
for host in "${host_array[@]}"; do
    # Check and update A record
    a_record=$(echo "$records_info" | jq -r ".records[] | select(.type == \"A\" and .name == \"$host\")")
    if [[ -n "$a_record" ]]; then
        record_id=$(echo "$a_record" | jq -r ".id")
        current_ip=$(echo "$a_record" | jq -r ".value")
        if [[ "$current_ip" != "$ipv4" ]]; then
            update_record "$record_id" "A" "$host" "$ipv4" "$zone_id"
        fi
    fi

    # Check and update AAAA record
    aaaa_record=$(echo "$records_info" | jq -r ".records[] | select(.type == \"AAAA\" and .name == \"$host\")")
    if [[ -n "$aaaa_record" ]]; then
        record_id=$(echo "$aaaa_record" | jq -r ".id")
        current_ip=$(echo "$aaaa_record" | jq -r ".value")
        if [[ "$current_ip" != "$ipv6" ]]; then
            update_record "$record_id" "AAAA" "$host" "$ipv6" "$zone_id"
        fi
    fi
done

# Final output based on overall results
if $auth_failed; then
    echo "badauth"
    exit 0
elif $changes_made; then
    echo "good"
else
    echo "nochg"
fi