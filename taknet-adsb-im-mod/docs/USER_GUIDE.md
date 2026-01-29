# TAKNET-PS User Guide

Simple guide for setting up your ADS-B feeder with TAKNET-PS aggregator.

## 🚀 Quick Setup (5 minutes)

### Step 1: Configure TAKNET-PS

1. **Open web interface**: Navigate to `http://your-pi-ip` in your browser
2. **Go to Data Sharing Setup**: Click "Data Sharing" in the menu
3. **Find TAKNET-PS**: Scroll down past sdrmap
4. **Enable it**: Check the box next to "TAKNET-PS (Custom Aggregator)"
5. **Enter port**: Type `30005` in the port field
6. **Apply**: Click the big "Apply" button at the top

**That's it!** The system automatically chooses:
- `tailscale.leckliter.net` if you have Tailscale running
- `adsb.leckliter.net` if you don't have Tailscale

### Step 2 (Optional): Setup Tailscale

Want to use the secure Tailscale network? Follow these steps:

1. **Get an auth key**:
   - Go to [Tailscale Admin Console](https://login.tailscale.com/admin/settings/keys)
   - Click "Generate auth key"
   - **IMPORTANT**: Check "Pre-authorized" ✓
   - **IMPORTANT**: Do NOT check "Ephemeral"
   - Copy the key (starts with `tskey-auth-`)

2. **Configure Tailscale**:
   - Go to "System Management" in the menu
   - Find "Add Tailscale" section
   - Paste your auth key in the first field
   - Click "Apply"
   - Wait ~10 seconds for connection

3. **Verify it worked**:
   - Page will reload
   - You should see: "This device should now be on your tailnet"
   - Go back to "Data Sharing Setup"
   - Look at TAKNET-PS section
   - It should now show: "Currently configured: **tailscale.leckliter.net:30005**"

## 🎯 Configuration Summary

### TAKNET-PS Settings
| Setting | Value | Notes |
|---------|-------|-------|
| Enabled | ✓ Checked | Turn on TAKNET-PS |
| Port | `30005` | Beast format (recommended) |
| Host | Auto-selected | Based on Tailscale status |

### Alternative Ports
- `30005` - Beast format ← **Use this one**
- `30003` - SBS/BaseStation format
- `30002` - Raw format

## ✅ How to Verify It's Working

### Check 1: Configuration Display
On the "Data Sharing Setup" page, TAKNET-PS section should show:
```
Currently configured: tailscale.leckliter.net:30005
```
or
```
Currently configured: adsb.leckliter.net:30005
```

### Check 2: Docker Logs
```bash
# SSH into your Pi, then run:
docker logs ultrafeeder --tail 50 | grep -i beast

# You should see lines like:
# beast output to tailscale.leckliter.net:30005 connected
```

### Check 3: Network Test
```bash
# Test connectivity to aggregator
ping tailscale.leckliter.net

# Test port is reachable
telnet tailscale.leckliter.net 30005
```

## 🆘 Troubleshooting

### Problem: Can't access web interface
**Solution**: 
```bash
# Find your Pi's IP address
# Look at your router's connected devices list
# Or try: http://adsb-feeder.local
```

### Problem: TAKNET-PS shows wrong host
**What you see**: Shows `adsb.leckliter.net` but you have Tailscale running  
**Solution**:
1. Check Tailscale is actually connected:
   ```bash
   ssh pi@your-pi-ip
   tailscale status
   ```
2. Toggle TAKNET-PS off and on again
3. Click "Apply"

### Problem: Port field shows an error
**What you see**: "Port must be between 1 and 65535"  
**Solution**: Make sure you typed just the number: `30005` (no extra spaces or letters)

### Problem: Tailscale auth key doesn't work
**What you see**: "Failed to connect with auth key"  
**Solutions**:
1. **Check the key**: Make sure you copied the whole thing (starts with `tskey-auth-`)
2. **Check settings**: When generating the key:
   - ✓ "Pre-authorized" must be checked
   - ✗ "Ephemeral" must be UNCHECKED
3. **Try again**: Generate a new key and try again
4. **Manual method**: Leave auth key blank and use the login link instead

### Problem: No planes showing on map
**This isn't a TAKNET-PS problem!** Check:
1. Is your antenna connected?
2. Is the SDR plugged in?
3. Are you near an airport or flight path?
4. Check the "Advanced" page → SDR status should be green

## 📊 Understanding the System

### What happens when you enable TAKNET-PS?

1. **You check the box and enter port 30005**
2. **System checks**: Is Tailscale running?
3. **Decision made**:
   - ✅ Tailscale active → Use `tailscale.leckliter.net`
   - ❌ Tailscale not active → Use `adsb.leckliter.net`
4. **Data flows**: Your Pi sends aircraft data to the selected host

### How does automatic host selection work?

```
Your Pi
   │
   ├─→ Check: Is Tailscale running?
   │
   ├─→ YES → Use tailscale.leckliter.net (secure, private network)
   │
   └─→ NO  → Use adsb.leckliter.net (public internet)
```

### Why use Tailscale?

**Without Tailscale** (adsb.leckliter.net):
- ✓ Works immediately, no setup
- ✓ Accessible from anywhere
- ✗ Uses public internet
- ✗ Goes through your router's firewall

**With Tailscale** (tailscale.leckliter.net):
- ✓ Encrypted connection
- ✓ Direct peer-to-peer when possible
- ✓ Works behind NATs/firewalls
- ✓ Part of your private network
- ⚠ Requires 5 minutes of setup

## 🔄 Switching Between Networks

### From Public to Tailscale
1. Set up Tailscale (see Step 2 above)
2. Go back to "Data Sharing Setup"
3. Look at TAKNET-PS section
4. It automatically switched to `tailscale.leckliter.net`!
5. No need to change port or anything else

### From Tailscale to Public
1. Go to "System Management"
2. In Tailscale section, type "disable"
3. Click "Apply"
4. Go back to "Data Sharing Setup"
5. TAKNET-PS automatically switches to `adsb.leckliter.net`

## 📱 Mobile Device Setup

Using a phone or tablet to configure? No problem!

1. **Connect to Pi's WiFi**: Look for "adsb-feeder" network
2. **Open browser**: Any browser works
3. **Auto-redirect**: Should automatically open the setup page
4. **Follow steps above**: Same process on mobile

## 💡 Pro Tips

### Tip 1: Bookmark the web interface
Save `http://your-pi-ip` as a bookmark for easy access

### Tip 2: Keep Tailscale auth key safe
Don't share your auth key in chat, email, or screenshots!

### Tip 3: One port to rule them all
Stick with port 30005 (Beast format) - it's the most compatible

### Tip 4: Check status regularly
Visit "Data Sharing Setup" occasionally to see which host you're using

### Tip 5: Tailscale survives reboots
Once configured, Tailscale stays connected even after restarting your Pi

## 📞 Getting Help

### Check These First
1. Is your Pi powered on? (Obviously, but worth checking!)
2. Is it connected to your network? (WiFi or Ethernet)
3. Can you ping it? `ping your-pi-ip`
4. Is Docker running? SSH in and run: `docker ps`

### Common Questions

**Q: Does this affect my other feeds (FlightAware, etc.)?**  
A: No! TAKNET-PS is just another destination. Your existing feeds keep working.

**Q: Can I use a different port?**  
A: Yes, but check with your aggregator admin which ports they support.

**Q: Do I need to open ports on my router?**  
A: No! Outbound connections (Pi → Aggregator) work automatically.

**Q: Will this use more bandwidth?**  
A: Minimal - ADS-B data is very small (~1KB per aircraft per second).

**Q: Can I feed multiple aggregators?**  
A: Yes! Enable as many as you want on the "Data Sharing Setup" page.

## 🎓 Learning More

### About ADS-B
- **What it is**: Aircraft broadcast their position automatically
- **What you do**: Receive these broadcasts with a simple antenna
- **What TAKNET does**: Collects data from multiple feeders
- **Privacy**: All this data is already public (required by FAA)

### About Ports
- Think of ports like TV channels
- Different ports carry different data formats
- Port 30005 speaks "Beast" format (most common)
- Your Pi can talk multiple formats simultaneously

### About Tailscale
- Creates a private network (like a VPN)
- Your devices get 100.x.x.x addresses
- Works through any firewall
- Free for personal use (up to 100 devices)

---

**Still stuck?** Check the troubleshooting section above or contact your TAKNET administrator.

**Everything working?** Awesome! Your Pi is now feeding aircraft data to TAKNET-PS! ✈️

---

**Version**: 1.0  
**Last Updated**: January 2025  
**Difficulty**: Beginner-friendly
