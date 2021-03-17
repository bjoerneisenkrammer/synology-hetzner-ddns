#!/bin/bash
set -e;

ipv4Regex="((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])"

# DSM Config
username="$1"
password="$2"
#hostname="$3"
ipAddr="$4"

if [[ $ipAddr =~ $ipv4Regex ]]; then
    recordType="A";
else
    recordType="AAAA";
fi

res=$(curl "https://dns.hetzner.com/api/v1/records/$username" \
     -H "Auth-API-Token: $password")
recordIp=$(echo "$res" | jq -r ".record.value")

if [[ $recordIp = "$ipAddr" ]]; then
    echo "nochg";
    exit 0;
fi

name=$(echo "$res" | jq -r ".record.name")
zone_id=$(echo "$res" | jq -r ".record.zone_id")

res=$(curl -X "PUT" "https://dns.hetzner.com/api/v1/records/$username" \
     -H "Content-Type: application/json" \
     -H "Auth-API-Token: $password" \
     -d "{
  \"value\": \"$ipAddr\",
  \"ttl\": 300,
  \"type\": \"$recordType\",
  \"name\": \"$name\",
  \"zone_id\": \"$zone_id\"
}")
resResult=$(echo "$res" | jq -r ".record")

if [[ $resResult = null ]]; then
    echo "badauth";
else
    echo "good";
fi