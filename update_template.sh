#!/bin/bash

auth_key="%TOKEN%"           # Your API Token or Global API Key
zone_identifier="%ZONE%"     # Can be found in the "Overview" tab of your domain
record_name="%SUBDOMAIN%"    # Which record you want to be synced
interface="%INTERFACE%"      # Interface to get local IP from

###########################################
## Get local interface IP
###########################################
if [ "${interface}" == "" ]; then
  logger -s "Interface does not exist"
  exit 1
fi

ip=$(ip -4 addr show ${interface} | grep -oP "(?<=inet ).*(?=/)")

if [ "${ip}" == "" ]; then
  logger -s "DDNS Updater: No IP found"
  exit 1
fi

###########################################
## Seek for the A record
###########################################
logger "DDNS Updater: Check Initiated"
record=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$zone_identifier/dns_records?name=$record_name" -H "Authorization: Bearer $auth_key" -H "Content-Type: application/json")

###########################################
## Check if the domain has an A record
###########################################
if [[ $record == *"\"count\":0"* ]]; then
  logger -s "DDNS Updater: Record does not exist, perhaps create one first? (${ip} for ${record_name})"
  exit 1
fi

###########################################
## Get existing IP
###########################################
old_ip=$(echo "$record" | grep -Po '(?<="content":")[^"]*' | head -1)
# Compare if they're the same
if [[ $ip == $old_ip ]]; then
  logger "DDNS Updater: IP ($ip) for ${record_name} has not changed."
  exit 0
fi

###########################################
## Set the record identifier from result
###########################################
record_identifier=$(echo "$record" | grep -Po '(?<="id":")[^"]*' | head -1)

###########################################
## Change the IP@Cloudflare using the API
###########################################
update=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$zone_identifier/dns_records/$record_identifier" \
                     -H "Authorization: Bearer $auth_key" \
                     -H "Content-Type: application/json" \
              --data "{\"id\":\"$zone_identifier\",\"type\":\"A\",\"proxied\":false,\"name\":\"$record_name\",\"content\":\"$ip\"}")

###########################################
## Report the status
###########################################
case "$update" in
*"\"success\":false"*)
  logger -s "DDNS Updater: $ip $record_name DDNS failed for $record_identifier ($ip). DUMPING RESULTS:\n$update"
  exit 1;;
*)
  logger "DDNS Updater: $ip $record_name DDNS updated."
  exit 0;;
esac
