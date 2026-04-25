#!/bin/bash
# Version: 2.1.1
set -euo pipefail

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
	curl -sf -"$ip_type" https://ip.hetzner.com/
}

# Function to update a DNS RRset
update_rrset() {
	local zone_id="$1"
	local name="$2"
	local type="$3"
	local ip_addr="$4"

	response=$(curl -s -X "POST" "https://api.hetzner.cloud/v1/zones/$zone_id/rrsets/$name/$type/actions/set_records" \
		-H "Content-Type: application/json" \
		-H "Authorization: Bearer $accessToken" \
		-d "{\"records\": [{\"value\": \"$ip_addr\", \"comment\": \"\"}]}")

	if [[ $(echo "$response" | jq -r ".action.error") == null ]]; then
		changes_made=true
	else
		auth_failed=true
	fi
}

# Get current IP addresses
ipv4=$(get_ip 4)
ipv6=$(get_ip 6)

# Get zone information
zone_info=$(curl -s "https://api.hetzner.cloud/v1/zones" -H "Authorization: Bearer $accessToken")
zone_id=$(echo "$zone_info" | jq -r ".zones[] | select(.name == \"$domain\") | .id")

if [[ -z "$zone_id" ]]; then
	echo "badauth"
	exit 0
fi

# Update records for each host
IFS=',' read -ra host_array <<<"$hosts"
for host in "${host_array[@]}"; do
	# Check and update A record
	if [[ -n "$ipv4" ]]; then
		rrset_response=$(curl -s "https://api.hetzner.cloud/v1/zones/$zone_id/rrsets/$host/A" \
			-H "Authorization: Bearer $accessToken")
		current_ip=$(echo "$rrset_response" | jq -r ".rrset.records[0].value // \"\"")
		if [[ -n "$current_ip" && "$current_ip" != "$ipv4" ]]; then
			update_rrset "$zone_id" "$host" "A" "$ipv4"
		fi
	fi

	# Check and update AAAA record
	if [[ -n "$ipv6" ]]; then
		rrset_response=$(curl -s "https://api.hetzner.cloud/v1/zones/$zone_id/rrsets/$host/AAAA" \
			-H "Authorization: Bearer $accessToken")
		current_ip=$(echo "$rrset_response" | jq -r ".rrset.records[0].value // \"\"")
		if [[ -n "$current_ip" && "$current_ip" != "$ipv6" ]]; then
			update_rrset "$zone_id" "$host" "AAAA" "$ipv6"
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
