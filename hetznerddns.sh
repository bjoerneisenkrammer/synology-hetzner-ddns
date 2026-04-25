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
server_error=false

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
	local response http_code

	response=$(curl -s -w "%{http_code}" -X "POST" "https://api.hetzner.cloud/v1/zones/$zone_id/rrsets/$name/$type/actions/set_records" \
		-H "Content-Type: application/json" \
		-H "Authorization: Bearer $accessToken" \
		-d "{\"records\": [{\"value\": \"$ip_addr\", \"comment\": \"\"}]}")
	http_code="${response: -3}"

	if [[ "$http_code" =~ ^2 ]]; then
		changes_made=true
	elif [[ "$http_code" == "401" || "$http_code" == "403" ]]; then
		auth_failed=true
	else
		server_error=true
	fi
}

# Function to check current IP and update RRset if changed
check_and_update() {
	local zone_id="$1"
	local host="$2"
	local type="$3"
	local new_ip="$4"
	local response http_code body current_ip

	response=$(curl -s -w "%{http_code}" "https://api.hetzner.cloud/v1/zones/$zone_id/rrsets/$host/$type" \
		-H "Authorization: Bearer $accessToken")
	http_code="${response: -3}"
	body="${response%???}"

	if [[ "$http_code" == "401" || "$http_code" == "403" ]]; then
		auth_failed=true
	elif [[ ! "$http_code" =~ ^2 ]]; then
		server_error=true
	else
		current_ip=$(echo "$body" | jq -r ".rrset.records[0].value // \"\"")
		if [[ -n "$current_ip" && "$current_ip" != "$new_ip" ]]; then
			update_rrset "$zone_id" "$host" "$type" "$new_ip"
		fi
	fi
}

# Get current IP addresses
ipv4=$(get_ip 4)
ipv6=$(get_ip 6)

# Get zone information
zone_response=$(curl -s -w "%{http_code}" "https://api.hetzner.cloud/v1/zones" -H "Authorization: Bearer $accessToken")
zone_http_code="${zone_response: -3}"
zone_info="${zone_response%???}"

if [[ "$zone_http_code" == "401" || "$zone_http_code" == "403" ]]; then
	echo "badauth"
	exit 0
elif [[ ! "$zone_http_code" =~ ^2 ]]; then
	echo "911"
	exit 0
fi

zone_id=$(echo "$zone_info" | jq -r --arg domain "$domain" '.zones[] | select(.name == $domain) | .id')

if [[ -z "$zone_id" ]]; then
	echo "badauth"
	exit 0
fi

# Update records for each host
IFS=',' read -ra host_array <<<"$hosts"
for host in "${host_array[@]}"; do
	[[ -n "$ipv4" ]] && check_and_update "$zone_id" "$host" "A" "$ipv4"
	[[ -n "$ipv6" ]] && check_and_update "$zone_id" "$host" "AAAA" "$ipv6"
done

# Final output based on overall results
if $auth_failed; then
	echo "badauth"
	exit 0
elif $server_error; then
	echo "911"
	exit 0
elif $changes_made; then
	echo "good"
else
	echo "nochg"
fi
