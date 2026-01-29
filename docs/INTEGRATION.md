# TAKNET-PS Integration & Deployment Guide

Complete guide for deploying TAKNET-PS modifications across multiple feeders.

## 📦 Deployment Options

### Option A: Pre-built Image (Recommended)
```bash
# Flash the modified image to SD card
# Boot the Pi
# Configure via web interface
# Done!
```

### Option B: Build from Source
```bash
# Clone this repository
git clone https://github.com/your-org/taknet-adsb-im-mod.git
cd taknet-adsb-im-mod

# Apply to adsb.im repository
cd /path/to/adsb-feeder-image
cp -r /path/to/taknet-adsb-im-mod/src/* src/

# Build image
make build
```

### Option C: In-place Upgrade (Existing Feeders)
```bash
# On each feeder:
ssh pi@feeder-ip

# Backup current installation
sudo cp -r /opt/adsb/adsb-setup /opt/adsb/adsb-setup.backup

# Download and apply modifications
cd /tmp
wget https://your-server/taknet-mods.tar.gz
tar xzf taknet-mods.tar.gz
sudo cp -r taknet-mods/src/* /opt/adsb/

# Restart services
sudo systemctl restart adsb-docker
```

---

## 🏗️ Aggregator Server Setup

### Rocky Linux Aggregator Configuration

#### 1. Install Dependencies
```bash
# Install readsb
sudo dnf install readsb tar1090

# Install Tailscale
curl -fsSL https://tailscale.com/install.sh | sh
```

#### 2. Configure readsb to Accept Beast Input
Edit `/etc/default/readsb`:
```bash
# Enable Beast input on port 30005
RECEIVER_OPTIONS="--net-ri-port=30005 --net-bo-port=30006"

# Configure location
DECODER_OPTIONS="--lat=33.8343 --lon=-117.5723"

# Enable output to tar1090
NET_OPTIONS="--net --net-heartbeat=60"
```

#### 3. Configure Firewall
```bash
# Allow Beast input
sudo firewall-cmd --permanent --add-port=30005/tcp

# Allow Tailscale
sudo firewall-cmd --permanent --add-rich-rule='
  rule family="ipv4" source address="100.0.0.0/8" accept'

# Reload
sudo firewall-cmd --reload
```

#### 4. Setup Tailscale
```bash
# Start Tailscale
sudo tailscale up --accept-dns=false

# Get Tailscale IP
tailscale ip -4
# Note this IP (e.g., 100.64.0.1)
```

#### 5. Configure DNS (Optional)
If using `tailscale.leckliter.net`:
```bash
# In your DNS provider, add:
# A record: tailscale.leckliter.net → 100.64.0.1 (your Tailscale IP)
```

Or use MagicDNS (Tailscale's built-in DNS):
```bash
# In Tailscale admin: Settings → DNS → Enable MagicDNS
# Your aggregator becomes: aggregator-name.tailnet-name.ts.net
```

#### 6. Start Services
```bash
sudo systemctl enable --now readsb
sudo systemctl enable --now tar1090
sudo systemctl status readsb
```

---

## 🔄 Mass Deployment Workflow

### Scenario: Deploy to 10+ Feeders

#### Step 1: Prepare Image
```bash
# Build modified image once
make build

# Flash to one SD card
# Test thoroughly
# Create master image
```

#### Step 2: Clone SD Cards
```bash
# Use SD card duplicator or:
dd if=/dev/sdX of=taknet-adsb-master.img bs=4M status=progress

# Clone to new cards:
dd if=taknet-adsb-master.img of=/dev/sdY bs=4M status=progress
```

#### Step 3: Deploy Cards
```bash
# Insert SD card in each Pi
# Power on
# Each Pi will:
# 1. Boot with unique hostname (based on CPU serial)
# 2. Create WiFi hotspot
# 3. Wait for configuration
```

#### Step 4: Bulk Configure
Create config script: `bulk-configure.sh`
```bash
#!/bin/bash
# Configuration for feeder at zip code $1

ZIP=$1
FEEDER_IP=$2
LAT=$3
LON=$4
ALT=$5

# Tailscale auth key (generate one reusable key)
TS_KEY="tskey-auth-YOUR-KEY-HERE"

# Configure via API
curl -X POST "http://${FEEDER_IP}/api/configure" \
  -H "Content-Type: application/json" \
  -d "{
    \"site_name\": \"adsb-pi-${ZIP}\",
    \"lat\": \"${LAT}\",
    \"lon\": \"${LON}\",
    \"alt\": \"${ALT}\",
    \"taknet_enabled\": true,
    \"taknet_port\": \"30005\",
    \"tailscale_authkey\": \"${TS_KEY}\"
  }"
```

Use it:
```bash
# Configure multiple feeders
./bulk-configure.sh 92882 192.168.1.100 33.8343 -117.5723 400
./bulk-configure.sh 92883 192.168.1.101 33.8456 -117.5834 420
./bulk-configure.sh 92884 192.168.1.102 33.8567 -117.5945 410
```

---

## 🌐 Network Architecture

### Simple Network (No Tailscale)
```
┌─────────────┐
│  Feeder 1   │──┐
└─────────────┘  │
                  │    Internet
┌─────────────┐  │    ─────────    ┌──────────────┐
│  Feeder 2   │──┼─────────────────│  Aggregator  │
└─────────────┘  │                 │ adsb.leckliter│
                  │                 │     .net      │
┌─────────────┐  │                 └──────────────┘
│  Feeder 3   │──┘
└─────────────┘
```

### Tailscale Mesh Network
```
┌─────────────┐     ┌─────────────────────────────┐
│  Feeder 1   │─────│   Tailscale Mesh Network   │
│ 100.64.0.2  │     │   (Encrypted P2P)          │
└─────────────┘     │                             │
                    │  ┌──────────────┐          │
┌─────────────┐     │  │  Aggregator  │          │
│  Feeder 2   │─────│──│ 100.64.0.1   │          │
│ 100.64.0.3  │     │  │ tailscale.   │          │
└─────────────┘     │  │ leckliter.net│          │
                    │  └──────────────┘          │
┌─────────────┐     │                             │
│  Feeder 3   │─────│                             │
│ 100.64.0.4  │     └─────────────────────────────┘
└─────────────┘
```

### Hybrid Network (Mixed)
```
                    ┌─────────────────────┐
                    │    Tailscale VPN    │
┌─────────────┐     │                     │     ┌──────────────┐
│  Feeder 1   │─────│────────────────────────→  │ Aggregator   │
│ (Tailscale) │     │                     │     │ 100.64.0.1   │
└─────────────┘     └─────────────────────┘     │              │
                                                 │ Also at:     │
┌─────────────┐                                 │ adsb.        │
│  Feeder 2   │─────────Internet───────────────→│ leckliter    │
│ (No TS)     │                                 │ .net         │
└─────────────┘                                 └──────────────┘
```

---

## 🔧 Docker Compose Integration

### Ultrafeeder Configuration

#### Method 1: Environment Variables
```yaml
services:
  ultrafeeder:
    image: ghcr.io/sdr-enthusiasts/docker-adsb-ultrafeeder
    environment:
      # Core settings
      - READSB_DEVICE_TYPE=rtlsdr
      - READSB_LAT=${FEEDER_LAT}
      - READSB_LON=${FEEDER_LONG}
      
      # TAKNET-PS (auto-configured via web UI)
      - ULTRAFEEDER_CONFIG=
          adsblol,in.adsb.lol,12000,beast_reduce_plus_out;
          ${TAKNET_HOST:+beast,${TAKNET_HOST},${TAKNET_PORT},beast_out};
```

#### Method 2: Direct Configuration
```yaml
services:
  ultrafeeder:
    environment:
      - ULTRAFEEDER_CONFIG=
          adsblol,in.adsb.lol,12000,beast_reduce_plus_out;
          beast,tailscale.leckliter.net,30005,beast_out;
```

#### Method 3: Conditional (Advanced)
```yaml
services:
  ultrafeeder:
    environment:
      - ULTRAFEEDER_CONFIG=
          adsblol,in.adsb.lol,12000,beast_reduce_plus_out;
          beast,${TAKNET_HOST:-adsb.leckliter.net},${TAKNET_PORT:-30005},beast_out;
```

### Complete docker-compose.yml Example
```yaml
version: '3.8'

services:
  ultrafeeder:
    image: ghcr.io/sdr-enthusiasts/docker-adsb-ultrafeeder
    container_name: ultrafeeder
    hostname: ultrafeeder
    restart: unless-stopped
    
    devices:
      - /dev/bus/usb:/dev/bus/usb
    
    ports:
      - "8080:80"
      - "30005:30005"
    
    environment:
      # Location
      - READSB_LAT=33.8343
      - READSB_LON=-117.5723
      - READSB_ALT=400m
      
      # SDR
      - READSB_DEVICE_TYPE=rtlsdr
      - READSB_RTLSDR_DEVICE=00001090
      - READSB_GAIN=autogain
      
      # Feeds
      - ULTRAFEEDER_CONFIG=
          adsblol,in.adsb.lol,12000,beast_reduce_plus_out;
          beast,${TAKNET_HOST},${TAKNET_PORT},beast_out;
      
      # MLAT
      - MLAT_USER=adsb-pi-92882
      - UUID=${ULTRAFEEDER_UUID}
      
      # Map
      - TAR1090_SITESHOW=true
      - TAR1090_SITENAME=TAKNET Corona
```

---

## 📊 Monitoring & Verification

### Aggregator Monitoring Script
```bash
#!/bin/bash
# monitor-feeders.sh

echo "=== TAKNET-PS Feeder Status ==="
echo

# Check readsb connections
echo "Active Connections:"
netstat -tn | grep :30005 | awk '{print $5}' | cut -d: -f1 | sort | uniq -c

echo
echo "Aircraft Count:"
curl -s http://localhost:8080/data/aircraft.json | jq '.aircraft | length'

echo
echo "Message Rate:"
curl -s http://localhost:8080/data/stats.json | jq '.last1min.messages'

echo
echo "Tailscale Peers:"
tailscale status | grep -v "^#"
```

### Feeder Health Check Script
```bash
#!/bin/bash
# health-check.sh (run on each feeder)

echo "=== Feeder Health Check ==="

# Check TAKNET-PS config
echo "TAKNET-PS Configuration:"
grep "TAKNET" /opt/adsb/.env 2>/dev/null || echo "Not configured"

# Check Tailscale status
echo
echo "Tailscale Status:"
tailscale status --json | jq -r '.BackendState'

# Check ultrafeeder
echo
echo "Ultrafeeder Status:"
docker ps | grep ultrafeeder

# Check TAKNET-PS connection
echo
echo "TAKNET-PS Connection:"
docker logs ultrafeeder 2>&1 | grep -i "tailscale.leckliter\|adsb.leckliter" | tail -5
```

---

## 🚨 Troubleshooting Deployment

### Issue: Feeder connects to wrong host

**Check 1**: Verify Tailscale status
```bash
ssh pi@feeder
tailscale status
```

**Check 2**: Force reconfiguration
```bash
# Via web UI: Toggle TAKNET-PS off and on
# Or via CLI:
ssh pi@feeder
sudo systemctl restart adsb-docker
```

### Issue: Multiple feeders share hostname

**Cause**: SD card was cloned after first boot  
**Fix**: Each feeder needs unique CPU serial
```bash
# On each feeder, force regenerate hostname:
sudo /opt/adsb/scripts/generate-hostname.sh
sudo reboot
```

### Issue: Aggregator shows no data

**Check 1**: Firewall
```bash
# On aggregator:
sudo firewall-cmd --list-all
# Should show port 30005/tcp
```

**Check 2**: readsb listening
```bash
# On aggregator:
sudo netstat -tlnp | grep 30005
```

**Check 3**: Feeder connectivity
```bash
# On feeder:
telnet tailscale.leckliter.net 30005
```

---

## 📈 Scaling Considerations

### 10-50 Feeders
- ✅ Single aggregator sufficient
- ✅ Standard hardware (4 cores, 8GB RAM)
- ✅ 1 Gbps network adequate

### 50-200 Feeders
- ⚠️ Monitor aggregator CPU and network
- ⚠️ Consider load balancing
- ⚠️ May need database for stats

### 200+ Feeders
- 🔴 Multiple aggregators required
- 🔴 Geographic distribution recommended
- 🔴 Central database and monitoring

### Resource Planning

**Per Feeder**:
- Network: ~5 KB/s outbound
- CPU: Minimal (handled by Pi)
- Storage: None (streaming only)

**Aggregator** (per 100 feeders):
- Network: ~500 KB/s inbound
- CPU: 1-2 cores
- RAM: 2-4 GB
- Storage: 10 GB (for stats/history)

---

## 🔐 Security Best Practices

### Feeder Security
1. ✅ Disable unused services
2. ✅ Keep system updated
3. ✅ Use SSH keys (not passwords)
4. ✅ Firewall only allows outbound
5. ✅ Unique credentials per feeder

### Aggregator Security
1. ✅ Firewall ports 30005 only to Tailscale network
2. ✅ HTTPS for web interface
3. ✅ Regular backups
4. ✅ Monitor for abnormal traffic
5. ✅ DDoS protection if public

### Tailscale Security
1. ✅ Use ACLs to restrict access
2. ✅ Rotate auth keys regularly
3. ✅ Monitor connected devices
4. ✅ Enable MFA for admin account
5. ✅ Audit access logs

---

## 📝 Deployment Checklist

### Pre-Deployment
- [ ] Test modified image on one feeder
- [ ] Document network configuration
- [ ] Prepare Tailscale auth keys
- [ ] Set up aggregator server
- [ ] Configure DNS records
- [ ] Create deployment scripts
- [ ] Prepare troubleshooting guide

### During Deployment
- [ ] Flash SD cards with modified image
- [ ] Label each SD card with site info
- [ ] Install feeders at sites
- [ ] Connect to network
- [ ] Configure via web UI or API
- [ ] Verify Tailscale connection
- [ ] Check data flow to aggregator
- [ ] Document each feeder's IP/location

### Post-Deployment
- [ ] Monitor aggregator for 24 hours
- [ ] Verify all feeders connected
- [ ] Check for error patterns
- [ ] Update documentation
- [ ] Create backup procedures
- [ ] Train support staff
- [ ] Schedule regular maintenance

---

**Document Version**: 1.0  
**Last Updated**: January 2025  
**Audience**: System Administrators
