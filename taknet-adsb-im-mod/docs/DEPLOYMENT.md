# TAKNET-PS Deployment Guide

Step-by-step guide for deploying TAKNET-PS modifications to production feeders.

## 📋 Prerequisites

### Aggregator Server
- [ ] Rocky Linux server (or compatible)
- [ ] readsb installed and configured
- [ ] tar1090 installed (optional but recommended)
- [ ] Port 30005 open on firewall
- [ ] Static IP or DNS name configured
- [ ] Optionally: Tailscale installed and configured

### Feeder Requirements
- [ ] Raspberry Pi 3B+ or newer (or compatible SBC)
- [ ] 8GB+ SD card
- [ ] RTL-SDR dongle
- [ ] ADS-B antenna (1090 MHz)
- [ ] Network connectivity (WiFi or Ethernet)
- [ ] Optionally: Tailscale access

### Tools Needed
- [ ] SD card reader/writer
- [ ] Balena Etcher or dd for flashing
- [ ] SSH client (Terminal, PuTTY, etc.)
- [ ] Web browser
- [ ] Network access to feeders

---

## 🚀 Quick Deployment (Recommended)

### Method 1: Flash Pre-built Image

```bash
# 1. Download modified image
wget https://your-server/taknet-adsb-im-feeder-v1.0.0.img.gz

# 2. Flash to SD card
balenaEtcher  # Or use command line:
gunzip -c taknet-adsb-im-feeder-v1.0.0.img.gz | sudo dd of=/dev/sdX bs=4M status=progress

# 3. Insert SD card into Pi and power on
# 4. Connect to Pi's web interface at http://192.168.1.x
# 5. Configure TAKNET-PS:
#    - Go to "Data Sharing Setup"
#    - Enable TAKNET-PS
#    - Enter port: 30005
#    - Click Apply

# 6. Optionally configure Tailscale:
#    - Go to "System Management"
#    - Enter Tailscale auth key
#    - Click Apply
```

**Done!** Feeder will automatically select the correct aggregator host.

---

## 🔧 Manual Deployment (Build from Source)

### Step 1: Prepare Build Environment

```bash
# Clone the original adsb.im repository
git clone https://github.com/dirkhh/adsb-feeder-image.git
cd adsb-feeder-image

# Download TAKNET-PS modifications
wget https://github.com/your-org/taknet-adsb-im-mod/archive/refs/heads/main.tar.gz
tar xzf main.tar.gz
```

### Step 2: Apply Modifications

```bash
# Copy modified files over originals
cp -r taknet-adsb-im-mod-main/src/* src/

# Verify files were copied
ls -la src/modules/adsb-feeder/filesystem/root/opt/adsb/adsb-setup/utils/other_aggregators.py
ls -la src/modules/adsb-feeder/filesystem/root/opt/adsb/adsb-setup/templates/aggregators.html
```

### Step 3: Build Image

```bash
# Follow adsb.im build instructions
make build

# This will create an .img file in the build directory
```

### Step 4: Flash and Deploy

```bash
# Flash to SD card
balenaEtcher  # Or dd command

# Boot Pi and configure via web UI
```

---

## 📦 Mass Deployment (10+ Feeders)

### Preparation Phase

#### 1. Build Master Image
```bash
# Build once, deploy many
make build
sudo dd if=taknet-adsb-feeder.img of=master.img bs=4M
```

#### 2. Generate Tailscale Auth Key
```bash
# Go to: https://login.tailscale.com/admin/settings/keys
# Settings:
# ✓ Reusable
# ✓ Pre-authorized
# ✗ NOT Ephemeral
# 
# Save key securely: tskey-auth-XXXXXXXXXXXXXXXXXX
```

#### 3. Prepare Deployment Spreadsheet
```csv
Site,Zip,IP,Latitude,Longitude,Altitude,Notes
Corona-1,92882,192.168.1.100,33.8343,-117.5723,400,Primary site
Corona-2,92883,192.168.1.101,33.8456,-117.5834,420,Secondary site
Corona-3,92884,192.168.1.102,33.8567,-117.5945,410,Backup site
```

### Deployment Phase

#### Method A: Serial Deployment (Safest)

```bash
#!/bin/bash
# deploy-one.sh - Deploy one feeder at a time

SITE_NAME=$1
IP=$2
LAT=$3
LON=$4
ALT=$5

echo "=== Deploying $SITE_NAME ==="

# Wait for Pi to boot
echo "Waiting for $IP to be online..."
until ping -c1 $IP &>/dev/null; do sleep 5; done

# Configure via curl (if API available)
curl -X POST "http://${IP}/api/setup" -H "Content-Type: application/json" \
  -d "{
    \"site_name\": \"$SITE_NAME\",
    \"lat\": \"$LAT\",
    \"lon\": \"$LON\",
    \"alt\": \"$ALT\",
    \"taknet_enabled\": true,
    \"taknet_port\": \"30005\"
  }"

echo "✓ $SITE_NAME deployed successfully"
```

Use it:
```bash
# Deploy each feeder
./deploy-one.sh "adsb-pi-92882" "192.168.1.100" "33.8343" "-117.5723" "400"
./deploy-one.sh "adsb-pi-92883" "192.168.1.101" "33.8456" "-117.5834" "420"
# ... etc
```

#### Method B: Parallel Deployment (Faster)

```bash
#!/bin/bash
# deploy-parallel.sh - Deploy multiple feeders simultaneously

TS_KEY="tskey-auth-YOUR-KEY-HERE"

# Function to deploy one feeder
deploy_feeder() {
    local SITE=$1
    local IP=$2
    local LAT=$3
    local LON=$4
    local ALT=$5
    
    echo "[$SITE] Waiting for Pi..."
    until ping -c1 $IP &>/dev/null; do sleep 5; done
    
    echo "[$SITE] Configuring..."
    ssh pi@$IP << 'EOF'
# Configure TAKNET-PS
echo "TAKNET_IS_ENABLED=true" >> /opt/adsb/.env
echo "TAKNET_PORT=30005" >> /opt/adsb/.env

# Configure Tailscale
tailscale up --authkey=$TS_KEY --accept-dns=false

# Restart services
systemctl restart adsb-docker
EOF
    
    echo "[$SITE] ✓ Complete"
}

# Deploy all feeders in parallel
deploy_feeder "adsb-pi-92882" "192.168.1.100" "33.8343" "-117.5723" "400" &
deploy_feeder "adsb-pi-92883" "192.168.1.101" "33.8456" "-117.5834" "420" &
deploy_feeder "adsb-pi-92884" "192.168.1.102" "33.8567" "-117.5945" "410" &

# Wait for all to complete
wait
echo "✓ All feeders deployed!"
```

### Verification Phase

```bash
#!/bin/bash
# verify-deployment.sh - Check all feeders are working

FEEDERS=(
    "192.168.1.100"
    "192.168.1.101"
    "192.168.1.102"
)

echo "=== Verifying TAKNET-PS Deployment ==="
echo

for IP in "${FEEDERS[@]}"; do
    echo "Checking $IP..."
    
    # Check if online
    if ! ping -c1 $IP &>/dev/null; then
        echo "  ✗ OFFLINE"
        continue
    fi
    
    # Check TAKNET-PS config
    CONFIG=$(ssh pi@$IP "grep TAKNET /opt/adsb/.env")
    echo "  Config: $CONFIG"
    
    # Check Tailscale status
    TS_STATUS=$(ssh pi@$IP "tailscale status --json | jq -r '.BackendState'")
    echo "  Tailscale: $TS_STATUS"
    
    # Check ultrafeeder
    ULTRA_STATUS=$(ssh pi@$IP "docker ps | grep ultrafeeder")
    if [ -n "$ULTRA_STATUS" ]; then
        echo "  ✓ Ultrafeeder running"
    else
        echo "  ✗ Ultrafeeder not running"
    fi
    
    echo
done
```

---

## 🔍 Testing & Validation

### Test Plan

#### Stage 1: Lab Testing
```bash
# Test one feeder in controlled environment
# 1. Flash SD card
# 2. Boot Pi
# 3. Configure TAKNET-PS
# 4. Verify data flow
# 5. Test Tailscale connection
# 6. Verify automatic host switching
# 7. Test without Tailscale
# 8. Verify fallback to adsb.leckliter.net
```

#### Stage 2: Pilot Deployment
```bash
# Deploy to 2-3 feeders in production
# 1. Monitor for 24 hours
# 2. Check aggregator logs
# 3. Verify all feeders connected
# 4. Test failover scenarios
# 5. Document any issues
```

#### Stage 3: Full Deployment
```bash
# Roll out to all feeders
# 1. Deploy in batches of 10
# 2. Verify each batch before continuing
# 3. Monitor aggregator load
# 4. Document deployment progress
```

### Validation Checklist

On **each feeder**:
- [ ] TAKNET-PS enabled in web UI
- [ ] Port set to 30005
- [ ] Correct host displayed (tailscale.leckliter.net or adsb.leckliter.net)
- [ ] Ultrafeeder container running
- [ ] No errors in docker logs
- [ ] Tailscale connected (if applicable)
- [ ] Other aggregators still working

On **aggregator**:
- [ ] Port 30005 shows LISTEN
- [ ] Feeder connections visible in netstat
- [ ] Aircraft data flowing
- [ ] No errors in readsb logs
- [ ] tar1090 map shows aircraft
- [ ] CPU/memory usage normal

---

## 🚨 Troubleshooting Deployment Issues

### Issue: Can't find Pi on network

**Symptom**: Can't access web interface  
**Solutions**:
```bash
# Method 1: Check router DHCP leases

# Method 2: Scan network
nmap -sn 192.168.1.0/24 | grep -B2 "Raspberry"

# Method 3: Use mDNS
ping adsb-feeder.local

# Method 4: Connect via WiFi hotspot
# Pi creates "adsb-feeder" WiFi on first boot
```

### Issue: SD card won't boot

**Symptom**: No activity LEDs, no network  
**Solutions**:
```bash
# 1. Verify image integrity
sha256sum taknet-adsb-feeder.img

# 2. Re-flash SD card

# 3. Try different SD card

# 4. Check power supply (need 2.5A+ for Pi 3/4)
```

### Issue: TAKNET-PS not appearing in UI

**Symptom**: Don't see TAKNET-PS checkbox  
**Solutions**:
```bash
# 1. Verify files were copied correctly
ssh pi@feeder-ip
ls -la /opt/adsb/adsb-setup/utils/other_aggregators.py
grep -i "TaknetPS" /opt/adsb/adsb-setup/utils/other_aggregators.py

# 2. Restart web service
systemctl restart adsb-docker

# 3. Check for Python errors
journalctl -u adsb-feeder -n 50
```

### Issue: Wrong aggregator host selected

**Symptom**: Shows adsb.leckliter.net but Tailscale is running  
**Solutions**:
```bash
# 1. Verify Tailscale is actually connected
ssh pi@feeder-ip
tailscale status

# 2. Check service status
systemctl status tailscaled

# 3. Force reconfiguration
# Go to web UI → Toggle TAKNET-PS off and on

# 4. Restart docker
systemctl restart adsb-docker
```

### Issue: Tailscale auth key rejected

**Symptom**: "Failed to connect with auth key"  
**Solutions**:
```bash
# 1. Verify key settings:
# ✓ Pre-authorized
# ✗ NOT Ephemeral
# ✓ Reusable (for mass deployment)

# 2. Generate new key

# 3. Try manual login method instead:
# Leave auth key blank, use login link
```

### Issue: No data reaching aggregator

**Symptom**: Feeder configured but no data on aggregator  
**Solutions**:
```bash
# On feeder:
docker logs ultrafeeder 2>&1 | grep -i "taknet\|leckliter"

# Should see: "beast output to tailscale.leckliter.net:30005 connected"

# On aggregator:
netstat -tn | grep :30005
# Should see connections from feeders

# Test connectivity:
telnet tailscale.leckliter.net 30005
```

---

## 📊 Monitoring Post-Deployment

### Aggregator Monitoring Script

Create `/usr/local/bin/taknet-monitor.sh`:
```bash
#!/bin/bash
# Monitor TAKNET-PS aggregator health

LOG="/var/log/taknet-monitor.log"

timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

echo "[$(timestamp)] === TAKNET-PS Status ===" | tee -a $LOG

# Active connections
CONN_COUNT=$(netstat -tn | grep :30005 | grep ESTABLISHED | wc -l)
echo "[$(timestamp)] Active feeders: $CONN_COUNT" | tee -a $LOG

# Aircraft count
AIRCRAFT=$(curl -s http://localhost:8080/data/aircraft.json | jq '.aircraft | length')
echo "[$(timestamp)] Aircraft visible: $AIRCRAFT" | tee -a $LOG

# Message rate
MSG_RATE=$(curl -s http://localhost:8080/data/stats.json | jq '.last1min.messages')
echo "[$(timestamp)] Messages/min: $MSG_RATE" | tee -a $LOG

# Tailscale peers
TS_PEERS=$(tailscale status | grep -v "^#" | wc -l)
echo "[$(timestamp)] Tailscale peers: $TS_PEERS" | tee -a $LOG

# Alert if too few feeders
if [ $CONN_COUNT -lt 5 ]; then
    echo "[$(timestamp)] WARNING: Only $CONN_COUNT feeders connected!" | tee -a $LOG
fi
```

Run via cron:
```bash
# /etc/crontab
*/5 * * * * root /usr/local/bin/taknet-monitor.sh
```

### Feeder Health Check Script

Create on each feeder: `/usr/local/bin/health-check.sh`:
```bash
#!/bin/bash
# Check feeder health

# Check TAKNET-PS enabled
if grep -q "TAKNET_IS_ENABLED=true" /opt/adsb/.env; then
    echo "✓ TAKNET-PS enabled"
else
    echo "✗ TAKNET-PS not enabled"
    exit 1
fi

# Check ultrafeeder running
if docker ps | grep -q ultrafeeder; then
    echo "✓ Ultrafeeder running"
else
    echo "✗ Ultrafeeder not running"
    exit 1
fi

# Check TAKNET-PS connection
if docker logs ultrafeeder 2>&1 | tail -100 | grep -q "leckliter.net.*connected"; then
    echo "✓ Connected to aggregator"
else
    echo "✗ Not connected to aggregator"
    exit 1
fi

echo "✓ All checks passed"
```

---

## 📝 Deployment Checklist

### Pre-Deployment
- [ ] Aggregator server configured and tested
- [ ] DNS/IP addresses configured
- [ ] Firewall rules configured
- [ ] Tailscale network set up (if using)
- [ ] Master image built and tested
- [ ] Deployment plan documented
- [ ] Rollback procedure defined
- [ ] Team trained on troubleshooting
- [ ] Support contacts identified

### During Deployment
- [ ] Label SD cards with site info
- [ ] Flash all SD cards
- [ ] Physical installation at sites
- [ ] Network connectivity verified
- [ ] Web UI accessible
- [ ] TAKNET-PS configured
- [ ] Tailscale configured (if using)
- [ ] Data flow verified
- [ ] Document each deployment
- [ ] Update inventory

### Post-Deployment
- [ ] All feeders reporting to aggregator
- [ ] Monitoring scripts running
- [ ] Alert thresholds configured
- [ ] Documentation updated
- [ ] Backup procedures tested
- [ ] Performance baseline established
- [ ] Support handoff complete
- [ ] User training complete

---

## 📞 Support & Escalation

### Support Tiers

**Tier 1: User Support**
- Web UI navigation
- Basic configuration
- Password resets
- Network connectivity

**Tier 2: Technical Support**
- Tailscale issues
- Docker problems
- SDR configuration
- Log analysis

**Tier 3: Developer Support**
- Code issues
- Integration problems
- Custom modifications
- Performance optimization

### Escalation Path

1. **Check documentation** (this guide + USER_GUIDE.md)
2. **Run diagnostic scripts** (health-check.sh)
3. **Check aggregator status** (monitor script)
4. **Review logs** (docker logs, journalctl)
5. **Contact support** (with diagnostic output)

---

**Document Version**: 1.0  
**Last Updated**: January 2025  
**Next Review**: After first 50 deployments
