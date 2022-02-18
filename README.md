- [Synology Cloudflare DDNS Script 📜](#synology-cloudflare-ddns-script---)
  * [How to use `dsmCloudflareDdnsModule.sh`](#how-to-use--dsmcloudflareddnsmodulesh-)
    + [Access Synology via SSH](#access-synology-via-ssh)
    + [Run commands in Synology](#run-commands-in-synology)
  * [Get Cloudflare parameters](#get-cloudflare-parameters)
  * [Setup DDNS](#setup-ddns)
- [Synology GoDaddy DDNS Script 📜](#synology-godaddy-ddns-script---)
  * [How to use `dsmGodaddyDdnsModule.sh`](#how-to-use--dsmgodaddyddnsmodulesh-)
    + [Access Synology via SSH](#access-synology-via-ssh-1)
    + [Run commands in Synology](#run-commands-in-synology-1)
  * [Register API key and secret](#register-api-key-and-secret)
  * [Setup DDNS](#setup-ddns-1)

# Synology Cloudflare DDNS Script 📜

The is a script to be used to add [Cloudflare](https://www.cloudflare.com/) as a DDNS to [Synology](https://www.synology.com/) NAS. The script used an updated API, Cloudflare API v4.

## How to use `dsmCloudflareDdnsModule.sh`

### Access Synology via SSH

1. Login to your DSM
2. Go to Control Panel > Terminal & SNMP > Enable SSH service
3. Use your client to access Synology via SSH.
4. Use your Synology admin account to connect.

### Run commands in Synology

1. Download `dsmCloudflareDdnsModule.sh` from this repository to `/sbin/cloudflareddns.sh` or any folder as you like

```
wget https://raw.githubusercontent.com/myrenyang/SynologyDsmDdns/main/dsmCloudflareDdnsModule.sh -O /sbin/cloudflareddns.sh
```

2. (Optional) Update the script to change the log file location, by default it is `/var/services/web/logs/ddnsLog.txt`, that means you can see the log on website if you have enabled Web Station.

3. Make it executable in `/sbin/cloudflareddns.sh`

```
chmod +x /sbin/cloudflareddns.sh
```
If you put the it in another folder, just make a link
```
ln -s /whatever-path-of-the-folder/cloudflareddns.sh /sbin/cloudflareddns.sh
```

4. Add `cloudflareddns.sh` to Synology Config Panel

Append following config to `/etc.defaults/ddns_provider.conf`.
```
[Cloudflare]
        modulepath=/sbin/cloudflareddns.sh
        queryurl=https://www.cloudflare.com
        website=https://dash.cloudflare.com
```

You can use VI editor or following commands
```
echo "[Cloudflare]" >> /etc.defaults/ddns_provider.conf
echo "        modulepath=/sbin/cloudflareddns.sh" >> /etc.defaults/ddns_provider.conf
echo "        queryurl=https://www.cloudflare.com" >> /etc.defaults/ddns_provider.conf
echo "        website=https://dash.cloudflare.com" >> /etc.defaults/ddns_provider.conf
echo "" >> /etc.defaults/ddns_provider.conf
```

Note, `queryurl` does not matter because we are going to use our script but it is needed.

## Get Cloudflare parameters

1. Go to your domain overview page and copy your zone ID.
2. Go to your [profile](https://dash.cloudflare.com/profile/api-tokens) > **API Tokens** > **Create Token**. It should have the permissions of `Zone > DNS > Edit`. Copy the api token.

## Setup DDNS

1. Login to your DSM
2. Go to Control Panel > External Access > DDNS > Add
3. Enter the following:
   - Service provider: `Cloudflare`
   - Hostname: Full domain name that need to update ip, like `www.example.com`
   - Username: Put domain Zone ID here, like `o4ngn949nsod0ngo09e9df90hs0hs8kj`
   - Password: Put API Token here, like `pGWuZ245NDluc29kMG5nbzA5ZTlkZjkwaHMwaHM4`

---

# Synology GoDaddy DDNS Script 📜

The is a script to be used to add [Godaddy](https://www.godaddy.com/) as a DDNS to [Synology](https://www.synology.com/) NAS. The script used an API v1.

## How to use `dsmGodaddyDdnsModule.sh`

### Access Synology via SSH

1. Login to your DSM
2. Go to Control Panel > Terminal & SNMP > Enable SSH service
3. Use your client to access Synology via SSH.
4. Use your Synology admin account to connect.

### Run commands in Synology

1. Download `dsmGodaddyDdnsModule.sh` from this repository to `/sbin/godaddyddns.sh` or any folder as you like

```
wget https://raw.githubusercontent.com/myrenyang/SynologyDsmDdns/main/dsmGodaddyDdnsModule.sh -O /sbin/godaddyddns.sh
```

2. (Optional) Update the script to change the log file location, by default it is `/var/services/web/logs/ddnsLog.txt`, that means you can see the log on website if you have enabled Web Station.

4. Make it executable in `/sbin/godaddyddns.sh`

```
chmod +x /sbin/godaddyddns.sh
```
If you put the script file in another folder, just make a link
```
ln -s /whatever-path-of-the-folder/godaddyddns.sh /sbin/godaddyddns.sh
```

3. Add `godaddyddns.sh` to Synology

Append following config to `/etc.defaults/ddns_provider.conf`.
```
[GoDaddy]
        modulepath=/sbin/godaddyddns.sh
        queryurl=https://developer.godaddy.com
        website=https://dcc.godaddy.com
```

You can use VI editor or following commands
```
echo "[GoDaddy]" >> /etc.defaults/ddns_provider.conf
echo "        modulepath=/sbin/godaddyddns.sh" >> /etc.defaults/ddns_provider.conf
echo "        queryurl=https://developer.godaddy.com" >> /etc.defaults/ddns_provider.conf
echo "        website=https://dcc.godaddy.com" >> /etc.defaults/ddns_provider.conf
echo "" >> /etc.defaults/ddns_provider.conf
```

Note, `queryurl` does not matter because we are going to use our script but it is needed.

## Register API key and secret

1. Log into your GoDaddy account. Go to https://developer.godaddy.com/keys and click Create New API Key.
2. When a new window opens, Choose a Name for your new API key then select Production as Environment. Click Next.
3. Copy your Key and your Secret Key to a text file and be careful not to lose it. Click Got it!

## Setup DDNS

1. Login to your DSM
2. Go to Control Panel > External Access > DDNS > Add
3. Enter the following:
   - Service provider: `GoDaddy`
   - Hostname: `www.example.com` or `@.example.com` for the root domain
   - Username: `<api token>`
   - Password: `<secret>`


