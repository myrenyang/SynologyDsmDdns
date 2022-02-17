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
#     This file need to be runnable in /sbin, e.g. /sbin/cloudflareDdns.sh


set -e;

proxied="true"

# DSM Config
domainName="$1"
password="$2"
hostname="$3"
ip="$4"


# To update the ip, e.g.
# curl -X GET "https://example.com/api/ip-update?ip=`curl icanhazip.com`" -H "p-pwd: password" -H "p-hostname: www.example.com"
#echo "badparam";
ipUpdateUri="https://${domainName}/api/ip-update?ip=${ip}";
response=$(curl -s -X GET "$ipUpdateUri" -H "p-pwd: $password" -H "p-hostname: $hostname")
status=$(echo "$response" | jq -r ".status")

#echo $response

if [[ $status != "200" ]]; then
	errorMsg=$(echo "$response" | jq -r ".errors[0].message")
	echo badauth $status: $errorMsg
	exit 1;
else
	echo "good";
fi

exit 0;
