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
#     This file need to be runnable in /sbin, e.g. /sbin/ovhcaddns.sh


set -e;

# DSM Config
zoneName="$1"
password="$2"
hostname="$3"
ip="$4"


# To refresh the change
# curl -s -X POST "https://ca.api.ovh.com/1.0/domain/zone/example.com/refresh" -H "X-Ovh-Application: iE3vL3mgAtLZg00l" -H "X-Ovh-Consumer: Juf2pt9W67XLBhNOEp0EZC888D3LY1Tg" -H "X-Ovh-Signature: $1$54ad5c303944d8f65d82f0a9902f6c690afa6f72" -H "X-Ovh-Timestamp: 1645107753"
#-b "tCdebugLib=1; TCPID=122161955377405701643; TC_PRIVACY=0@002%7C176%7C3810@2%2C3%2C4@1@1641632145600%2C1641632145600%2C1675328145600@; TC_PRIVACY_CENTER=2%2C3%2C4; tc_cj_v2=%7E%24.+%27%7B4ZZZ./%7B%7D%26*1%20-%21%27*2ZZZKPNKPLSLRPJJJZZZpc_q777.%20%28%7C-%7B%29%7EZZZ%22**%22%27%20ZZZKPNKPMKRQKJJJZZZ%5Dfc%5De777_rn_lh%5BfyfcheZZZ222H*1%23%7D%27*0%7EH%7D*%28ZZZKPNKPMLKNRJJJZZZ%5D777_rn_lh%5BfyfcheZZZ%7D%7BH*1%23H%7D*%28ZZZKPNKPMLQONJJJZZZ%5D777%7E%24.+%27%7B4ZZZ./%7B%7D%26*1%20-%21%27*2ZZZKPNKPONLMJJJJZZZpc_q777m…%22%3A1%7D%2C%22options%22%3A%7B%22path%22%3A%22%2F%22%2C%22session%22%3A15724800%2C%22end%22%3A15724800%7D%7D; _gcl_au=1.1.1933630143.1641632148; tc_cj_v2_cmp=; tc_cj_v2_med=; atauthority=%7B%22name%22%3A%22atauthority%22%2C%22val%22%3A%7B%22authority_name%22%3A%22default%22%2C%22visitor_mode%22%3A%22optin%22%7D%2C%22options%22%3A%7B%22end%22%3A%222023-03-02T00%3A44%3A06.659Z%22%2C%22path%22%3A%22%2F%22%7D%7D; kameleoonVisitorCode=_js_4adjwbqwyb2fo0jg; clientSideUserId=17eea82a-2ff9-46a3-9381-ff10fd3f68bb"
