#!/bin/bash

# Reference from DSM /etc.default/ddns_provider.conf
# Input:
#    1. DynDNS style request:
#       modulepath = DynDNS
#       queryurl = [Update URL]?[Query Parameters]
#
#    2. Self-defined module:
#       modulepath = /sbin/xxxddns
#       queryurl = DDNS_Provider_Name
#
#       Our service will assign parameters in the following order when calling module:
#           ($1=username, $2=password, $3=hostname, $4=ip)
#
# Output:
#    When you write your own module, you can use the following words to tell user what happen by print it.
#    You can use your own message, but there is no multiple-language support.
#
#       good -  Update successfully.
#       nochg - Update successfully but the IP address have not changed.
#       nohost - The hostname specified does not exist in this user account.
#       abuse - The hostname specified is blocked for update abuse.
#       notfqdn - The hostname specified is not a fully-qualified domain name.
#       badauth - Authenticate failed.
#       911 - There is a problem or scheduled maintenance on provider side
#       badagent - The user agent sent bad request(like HTTP method/parameters is not permitted)
#       badresolv - Failed to connect to  because failed to resolve provider address.
#       badconn - Failed to connect to provider because connection timeout.
#
# About this script
#     This file need to be runnable in /sbin, e.g. /sbin/cloudflareddns.sh


set -e;

# DSM Config
zoneId="$1"    # username
apiToken="$2"  # password
hostname="$3"  # hostname
ip="$4"

ipv4Regex="^([0-9]{1,3}\.){3}[0-9]{1,3}$"
logFile="/var/services/web/logs/ddnsLog.txt"
ddnsName="Cloudflare"
logMsgPrefix="$ddnsName $hostname -> $ip: "

if [[ $ip =~ $ipv4Regex ]]; then
    recordType="A";
else
    recordType="AAAA";
fi

# Get the recordId
listDnsUri="https://api.cloudflare.com/client/v4/zones/$zoneId/dns_records?name=${hostname}"
response=$(curl -s -X GET "$listDnsUri" -H "Authorization: Bearer $apiToken" -H "Content-Type: application/json")
success=$(echo "$response" | jq -r ".success")

if [[ $success != "true" ]]; then
    errorCode=$(echo "$response" | jq -r ".errors[0].code")
    errorMsg=$(echo "$response" | jq -r ".errors[0].message")
    if [[ $errorCode == "10000" ]]; then
        echo "badauth - $errorMsg"
        echo "`date +"%Y-%m-%d %T"` - $logMsgPrefix: $errorMsg" >> $logFile
        exit 1;
    fi
    echo "notfqdn - $errorMsg";
    echo "`date +"%Y-%m-%d %T"` - $logMsgPrefix: $errorMsg" >> $logFile
    exit 1;
fi

recordId=$(echo "$response" | jq -r ".result[0].id // null")
if [[ $recordId == "null" ]]; then
    echo "nohost";
    echo "`date +"%Y-%m-%d %T"` - $logMsgPrefix: The hostname does not exist in this user account." >> $logFile
    exit 1;
fi

dnsIp=$(echo "$response" | jq -r ".result[0].content // null")
# No need to update ip if already same
if [[ $dnsIp == $ip ]]; then
	echo "nochg - IP same, skip update";
    echo "`date +"%Y-%m-%d %T"` - $logMsgPrefix: IP same, skip update" >> $logFile
	exit 0;
fi

# Update the type and ip, and left every else not changed, like name, ttl and proxied.
ipUpdateUri="https://api.cloudflare.com/client/v4/zones/$zoneId/dns_records/$recordId";
response=$(curl -s -X PATCH "$ipUpdateUri" -H "Authorization: Bearer $apiToken" -H "Content-Type: application/json" --data '{"content":"'$ip'","type":"'$recordType'"}')
success=$(echo "$response" | jq -r ".success")

if [[ $success != "true" ]]; then
    errorCode=$(echo "$response" | jq -r ".errors[0].code")
    errorMsg=$(echo "$response" | jq -r ".errors[0].message")
    if [[ $errorCode == "10000" ]]; then
        echo "badauth - $errorMsg"
        echo "`date +"%Y-%m-%d %T"` - $logMsgPrefix: $errorMsg" >> $logFile
        exit 1;
    fi
    echo "notfqdn - $errorMsg";
    echo "`date +"%Y-%m-%d %T"` - $logMsgPrefix: $errorMsg" >> $logFile
    exit 1;
fi

echo "good";
echo "`date +"%Y-%m-%d %T"` - $logMsgPrefix: IP update successfully" >> $logFile

exit 0;
