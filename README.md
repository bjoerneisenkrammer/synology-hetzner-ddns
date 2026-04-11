> This project is a fork of the [SynologyHetznerDDNS](https://gitlab.com/onsive.net/SynologyHetznerDDNS)-Project which is made by OnSive.net

# Synology Hetzner DDNS Script
The is a script to be used to add [Hetzner](https://www.hetzner.com/) as a DDNS to [Synology](https://www.synology.com/) NAS. It uses the [Hetzner DNS API](https://dns.hetzner.com/api-docs/) v1.1.1, based on the forked project.

In addition the script supports multiple record names for IPv4 and IPv6.
IP addresses are determined via https://ip.hetzner.com/

## Installation

There are two ways to install the script on your Synology NAS:

- **[Option A: Manual installation via SSH](#option-a-manual-installation-via-ssh)** — simple one-time setup
- **[Option B: Boot task script](#option-b-boot-task-script)** — automatically reinstalls after DSM updates

---

## Option A: Manual installation via SSH

### Access Synology via SSH

1. Login to your DSM
2. Go to Control Panel > Terminal & SNMP > Enable SSH service
3. Use your client to access Synology via SSH.
4. Use your Synology admin account to connect.

### Run commands in Synology

1. Download `hetznerddns.sh` from this repository to `/sbin/hetznerddns.sh`

```
curl -fsSL https://raw.githubusercontent.com/bjoerneisenkrammer/synology-hetzner-ddns/main/hetznerddns.sh -o /sbin/hetznerddns.sh
```

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
EOF
```

`queryurl` does not matter because we are going to use our script but it is needed.

> **Note:** DSM major updates may overwrite `/sbin/` and reset `ddns_provider.conf`, requiring you to repeat these steps. Use Option B to avoid this.

---

## Option B: Boot task script

`synology-boot-task.sh` automatically downloads the latest `hetznerddns.sh` and configures `ddns_provider.conf` on every boot. This ensures the setup survives DSM updates without any manual intervention.

### Setup

1. Copy `synology-boot-task.sh` to a location on your data volume that survives DSM updates, e.g. `/volume1/scripts/`

```
mkdir -p /volume1/scripts
curl -fsSL https://raw.githubusercontent.com/bjoerneisenkrammer/synology-hetzner-ddns/main/synology-boot-task.sh -o /volume1/scripts/synology-boot-task.sh
chmod +x /volume1/scripts/synology-boot-task.sh
```

2. In DSM, go to **Control Panel > Task Scheduler > Create > Triggered Task > User-defined script**

3. Configure the task:
   - **Task name:** Hetzner DDNS Setup
   - **User:** `root`
   - **Event:** Boot-up
   - **Script:**
     ```
     bash /volume1/scripts/synology-boot-task.sh
     ```

4. Save and run the task once manually to verify it works.

The script logs all actions to syslog under the tag `hetzner-ddns-setup`, visible in DSM under **Log Center**.

---

## Get Hetzner parameters

**AccessToken:**
1. Go to [`https://dns.hetzner.com/`](https://dns.hetzner.com/)
2. Click on `Manage API tokens`
3. Insert you `Synology DDNS` (or whatever you like) as token name
4. Click on `Create access token`
5. Save the newly generated access token locally

**Record Names:**
1. Go to [`https://dns.hetzner.com/`](https://dns.hetzner.com/)
2. Click on your zone
3. Find the record names from the url you would like to update (e.g. `@` and `*`)

## Setup DDNS

1. Login to your DSM
2. Go to Control Panel > External Access > DDNS > Add
3. Enter the following:
   - Service provider: `Hetzner`
   - Hostname: `www.example.com`
   - Username/Email: `<RecordNames>` (e.g. `@,*`)
   - Password Key: `<AccessToken>`
