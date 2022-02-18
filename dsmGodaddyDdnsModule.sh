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
ipv4Regex="^([0-9]{1,3}\.){3}[0-9]{1,3}$"
ddnsName="GoDaddy"
logFile="/var/services/web/logs/ddns.log"

# DSM Config
apiKey="$1"   # username
secret="$2"   # password
hostname="$3" # format to be like 'www.example.com.us', for the root domain, like this: '@.example.com.us'
ip="$4"

domainName=${hostname#*.}
hostName=${hostname%%.*}

if [[ $ip =~ $ipv4Regex ]]; then
    recordType="A";
else
    recordType="AAAA";
fi

# To get the record details, e.g.
# curl -s -X GET "https://api.godaddy.com/v1/domains/example.com/records/A/www" -H "Authorization: sso-key <apiKey>:<secret>"

ipGetUri="https://api.godaddy.com/v1/domains/${domainName}/records/${recordType}/${hostName}"
response=`curl -s -X GET "$ipGetUri" -H "Authorization: sso-key $apiKey:$secret"`

if [[ $response == {* ]]; then
    code=$(echo "$response" | jq -r ".code")
    message=$(echo "$response" | jq -r ".message")
	echo "badauth - $message";
    echo "`date +"%Y-%m-%d %T"` - $ddnsName: $message" >> $logFile
	exit 1;
fi
if [[ $response == [] ]]; then
	echo "nohost - The hostname specified does not exist in this user account.";
    echo "`date +"%Y-%m-%d %T"` - $ddnsName: The hostname specified does not exist in this user account." >> $logFile
	exit 1;
fi

# Get TTL value
ttl=$(echo "$response" | jq -r ".[0].ttl // null")
if [[ $ttl == "null" ]]; then
	echo "nohost - The hostname specified does not exist in this user account.";
    echo "`date +"%Y-%m-%d %T"` - $ddnsName: Failed to get TTL value" >> $logFile
	exit 1;
fi

dnsIp=$(echo "$response" | jq -r ".[0].data // null")

# No need to update ip if already same
if [[ $dnsIp == $ip ]]; then
	echo "nochg - IP same, skip update";
    echo "`date +"%Y-%m-%d %T"` - $ddnsName: IP same, skip update" >> $logFile
	exit 0;
fi

# To upate the ip details
ipUpdateUri="https://api.godaddy.com/v1/domains/${domainName}/records/${recordType}/${hostName}"
response=$(curl -s -X PUT "$ipUpdateUri" -H "Authorization: sso-key $apiKey:$secret" -H "Content-Type: application/json" -d '[{"data":"'$ip'","ttl":"'$ttl'"}]')

if [ -z "$response" ]; then
	echo "good";
    echo "`date +"%Y-%m-%d %T"` - $ddnsName: IP update successfully" >> $logFile
	exit 0;
fi
if [[ $response == {* ]]; then
    code=$(echo "$response" | jq -r ".code")
    message=$(echo "$response" | jq -r ".message")
    echo "notfqdn - $message";
    echo "`date +"%Y-%m-%d %T"` - $ddnsName: $message" >> $logFile
	exit 1;
fi

echo "$response"
echo "`date +"%Y-%m-%d %T"` - $ddnsName: $response" >> $logFile
exit 1;