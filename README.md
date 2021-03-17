> This project is a fork of the [SynologyCloudflareDDNS](https://github.com/joshuaavalon/SynologyCloudflareDDNS)-Project which is made by [Joshua Avalon](https://joshuaavalon.io/)

# Synology Hetzner DDNS Script 📜

The is a script to be used to add [Hetzner](https://www.hetzner.com/) as a DDNS to [Synology](https://www.synology.com/) NAS. The script uses the [Hetzner DNS API](https://dns.hetzner.com/api-docs/) v1.1.1.

## ToDo
- [ ] Configure zone id instead of record id and outomatically use the right record

## How to use

### Access Synology via SSH

1. Login to your DSM
2. Go to Control Panel > Terminal & SNMP > Enable SSH service
3. Use your client to access Synology via SSH.
4. Use your Synology admin account to connect.

### Run commands in Synology

1. Download `hetznerddns.sh` from this repository to `/sbin/hetznerddns.sh`

```
wget https://gitlab.com/onsive.net/SynologyHetznerDDNS/-/raw/master/hetznerddns.sh -O /sbin/hetznerddns.sh
```

It is not a must, you can put I whatever you want. If you put the script in other name or path, make sure you use the right path.

2. Give others execute permission

```
chmod +x /sbin/hetznerddns.sh
```

3. Add `hetznerddns.sh` to Synology

```
cat >> /etc.defaults/ddns_provider.conf << 'EOF'
[Hetzner]
        modulepath=/sbin/hetznerddns.sh
        queryurl=https://dns.hetzner.com/api/v1
        website=https://dns.hetzner.com
E*.
```

`queryurl` does not matter because we are going to use our script but it is needed.

### Get Hetzner parameters

**AccessToken:**
1. Go to [`https://dns.hetzner.com/`](https://dns.hetzner.com/)
2. Click on `Manage API tokens`
3. Insert you `Synology DDNS` (or whatever you like) as token name
4. Click on `Create access token`
5. Save the newly generated access token locally

**Record ID:**
1. Go to [`https://dns.hetzner.com/`](https://dns.hetzner.com/)
2. Click on your zone
3. Save the zone ID from the url locally `https://dns.hetzner.com/zone/<ZoneID>` (ex: `https://dns.hetzner.com/zone/ >> 7D4UzSirxxxxxxxxxxxxxx <<`)
4. Run following command with your zone id and access token
```
curl "https://dns.hetzner.com/api/v1/records?zone_id=<ZoneID>" \
     -H 'Auth-API-Token: <AccessToken>'
```
5. Find the record you would like to use and save the record id locally

### Setup DDNS

1. Login to your DSM
2. Go to Control Panel > External Access > DDNS > Add
3. Enter the following:
   - Service provider: `Hetzner`
   - Hostname: `www.example.com`
   - Username/Email: `<RecordID>`
   - Password Key: `<AccessToken>`
