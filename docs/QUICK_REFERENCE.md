# TAKNET-PS Quick Reference

One-page reference for common tasks and troubleshooting.

## 🎯 Quick Setup

```bash
# 1. Enable TAKNET-PS
Web UI → Data Sharing Setup → Check "TAKNET-PS" → Port: 30005 → Apply

# 2. (Optional) Setup Tailscale  
Web UI → System Management → Enter auth key → Apply
```

## 📍 Aggregator Addresses

| Tailscale Status | Aggregator Host | Auto-Selected |
|-----------------|-----------------|---------------|
| ✅ Active | `tailscale.leckliter.net` | Yes |
| ❌ Inactive | `adsb.leckliter.net` | Yes |

**Port**: 30005 (Beast format, recommended)

## 🔧 Common Commands

### Check Configuration
```bash
# View TAKNET-PS settings
grep TAKNET /opt/adsb/.env

# Check Tailscale status
tailscale status

# View ultrafeeder logs
docker logs ultrafeeder --tail 50
```

### Verify Connection
```bash
# Check TAKNET-PS connection
docker logs ultrafeeder 2>&1 | grep -i leckliter

# Should see: "beast output to tailscale.leckliter.net:30005 connected"

# Test aggregator connectivity
ping tailscale.leckliter.net
telnet tailscale.leckliter.net 30005
```

### Restart Services
```bash
# Restart all ADS-B services
sudo systemctl restart adsb-docker

# Restart just ultrafeeder
docker restart ultrafeeder

# Restart Tailscale
sudo systemctl restart tailscaled
```

## 🚨 Quick Troubleshooting

| Problem | Quick Fix |
|---------|-----------|
| Wrong host selected | Toggle TAKNET-PS off/on in web UI |
| No connection to aggregator | `docker restart ultrafeeder` |
| Tailscale not working | `sudo tailscale up --authkey=<key>` |
| Can't access web UI | Check router for Pi's IP address |
| No planes showing | Check antenna connection |

## 📊 Monitoring

### On Feeder
```bash
# Quick health check
docker ps | grep ultrafeeder && echo "✓ Running" || echo "✗ Down"
grep TAKNET /opt/adsb/.env && echo "✓ Configured" || echo "✗ Not configured"
tailscale status | head -1
```

### On Aggregator
```bash
# Active connections
netstat -tn | grep :30005 | grep ESTABLISHED | wc -l

# Aircraft count
curl -s http://localhost:8080/data/aircraft.json | jq '.aircraft | length'

# Tailscale peers
tailscale status | wc -l
```

## 🔑 Tailscale Auth Key Settings

When generating at https://login.tailscale.com/admin/settings/keys:

- ✅ **Pre-authorized** (check this)
- ❌ **Ephemeral** (do NOT check this)
- ✅ **Reusable** (for multiple feeders)
- **Expiry**: 90 days recommended

## 🌐 File Locations

```
/opt/adsb/.env                          # Configuration
/opt/adsb/adsb-setup/utils/other_aggregators.py  # TaknetPS class
/opt/adsb/adsb-setup/templates/aggregators.html  # UI
/var/log/adsb-feeder.log               # Logs
```

## 📝 Environment Variables

```bash
TAKNET_IS_ENABLED=true
TAKNET_HOST=tailscale.leckliter.net    # Auto-set
TAKNET_PORT=30005                      # User-set
TAILSCALE_AUTHKEY=tskey-auth-xxxxx    # Temporary
```

## 🔗 Useful Links

- **Web UI**: `http://<pi-ip>`
- **Tailscale Admin**: https://login.tailscale.com/admin
- **User Guide**: docs/USER_GUIDE.md
- **Troubleshooting**: docs/DEPLOYMENT.md

## 💡 Pro Tips

1. **Bookmark your Pi's IP** for easy access
2. **Use Tailscale auth keys** for automatic setup
3. **Port 30005 is best** (Beast format)
4. **Check logs first** when troubleshooting
5. **Tailscale survives reboots** once configured

## ⚡ Emergency Commands

```bash
# Complete restart
sudo reboot

# Reset TAKNET-PS config
sudo sed -i '/TAKNET/d' /opt/adsb/.env
sudo systemctl restart adsb-docker

# Disconnect Tailscale
sudo tailscale down

# Re-flash SD card
# (Last resort - backs up nothing)
```

## 📞 Quick Support Checklist

Before asking for help, gather this info:

```bash
# 1. Pi info
hostname
cat /etc/os-release | grep VERSION

# 2. TAKNET-PS config
grep TAKNET /opt/adsb/.env

# 3. Tailscale status
tailscale status

# 4. Docker status
docker ps

# 5. Recent logs
docker logs ultrafeeder --tail 50
journalctl -u tailscaled -n 20
```

## 🎓 Port Reference

| Port | Format | Use Case |
|------|--------|----------|
| 30001 | Raw input | Receiving from dump1090 |
| 30002 | Raw output | Feeding raw data |
| 30003 | SBS | Virtual Radar, BaseStation |
| 30004 | Beast input | Receiving Beast |
| **30005** | **Beast output** | **TAKNET-PS ✓** |
| 30006 | Beast reduce | Bandwidth-optimized |

## ⚙️ Typical Values

```bash
# Location (Corona, CA example)
FEEDER_LAT=33.8343
FEEDER_LON=-117.5723
FEEDER_ALT=400

# Naming
SITE_NAME=adsb-pi-92882

# SDR
READSB_GAIN=autogain     # or 20-30 with filter
READSB_DEVICE_TYPE=rtlsdr
```

---

**Print this page** and keep near your workstation for quick reference!

**Version**: 1.0 | **Updated**: Jan 2025
