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

# DSM Config
apiKey="$1"
secret="$2"
hostname="$3" # format need to be www.example.com.us, for the root domain, put like this: @.example.com.us
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
	echo "badauth";
	exit 1;
fi
if [[ $response == [] ]]; then
	echo "nohost";
	exit 1;
fi

# Get TTL value
ttl=$(echo "$response" | jq -r ".[0].ttl // null")
if [[ $ttl == "null" ]]; then
	echo "nohost";
	exit 1;
fi

dnsIp=$(echo "$response" | jq -r ".[0].data // null")

# No need to update ip if already same
if [[ $dnsIp == $ip ]]; then
	echo "nochg";
	exit 0;
fi

# To upate the ip details
ipUpdateUri="https://api.godaddy.com/v1/domains/${domainName}/records/${recordType}/${hostName}"
response=$(curl -s -X PUT "$ipUpdateUri" -H "Authorization: sso-key $apiKey:$secret" -H "Content-Type: application/json" -d '[{"data":"'$ip'","ttl":'$ttl'}]')

if [ -z "$response" ]; then
	echo "good";
	exit 0;
fi
if [[ $response == {* ]]; then
	message=$(echo $response | jq -r ".message")
	echo "badresolv - $message";
	exit 1;
fi

echo "$response"
exit 1;