# Installation Guide

How to apply TAKNET-PS modifications to adsb.im feeder image.

## 📦 What's in This Package

```
taknet-adsb-im-mod/
├── README.md              # Start here - project overview
├── SUMMARY.md             # Complete project summary
├── CHANGELOG.md           # Version history
├── LICENSE                # MIT License
├── INSTALL.md             # This file
├── .gitignore             # Git ignore patterns
│
├── docs/                  # Complete documentation
│   ├── USER_GUIDE.md         # For end users
│   ├── DEPLOYMENT.md         # For admins  
│   ├── MODIFICATIONS.md      # For developers
│   ├── INTEGRATION.md        # For integration
│   └── QUICK_REFERENCE.md    # Cheat sheet
│
└── src/                   # Modified source files
    └── modules/adsb-feeder/filesystem/root/opt/adsb/adsb-setup/
        ├── app.py
        ├── utils/other_aggregators.py
        └── templates/
            ├── aggregators.html
            └── systemmgmt.html
```

## 🎯 Installation Methods

Choose one of these methods based on your needs:

### Method 1: GitHub Clone (Recommended for Development)

```bash
# 1. Clone this repository
git clone https://github.com/your-org/taknet-adsb-im-mod.git
cd taknet-adsb-im-mod

# 2. Clone adsb.im base repository
git clone https://github.com/dirkhh/adsb-feeder-image.git

# 3. Apply modifications
cp -r src/* adsb-feeder-image/src/

# 4. Build image
cd adsb-feeder-image
make build
```

### Method 2: Extract Tarball (Recommended for Production)

```bash
# 1. Extract the tarball
tar xzf taknet-adsb-im-mod.tar.gz
cd taknet-adsb-im-mod

# 2. Read the documentation
cat README.md

# 3. Clone adsb.im base repository
git clone https://github.com/dirkhh/adsb-feeder-image.git

# 4. Apply modifications
cp -r src/* adsb-feeder-image/src/

# 5. Build image
cd adsb-feeder-image
make build
```

### Method 3: Direct Copy (For In-Place Upgrades)

```bash
# On a feeder that's already running:

# 1. Extract tarball
cd /tmp
tar xzf taknet-adsb-im-mod.tar.gz
cd taknet-adsb-im-mod

# 2. Backup current installation
sudo cp -r /opt/adsb/adsb-setup /opt/adsb/adsb-setup.backup.$(date +%Y%m%d)

# 3. Apply modifications
sudo cp src/modules/adsb-feeder/filesystem/root/opt/adsb/adsb-setup/app.py \
     /opt/adsb/adsb-setup/
sudo cp src/modules/adsb-feeder/filesystem/root/opt/adsb/adsb-setup/utils/other_aggregators.py \
     /opt/adsb/adsb-setup/utils/
sudo cp src/modules/adsb-feeder/filesystem/root/opt/adsb/adsb-setup/templates/aggregators.html \
     /opt/adsb/adsb-setup/templates/
sudo cp src/modules/adsb-feeder/filesystem/root/opt/adsb/adsb-setup/templates/systemmgmt.html \
     /opt/adsb/adsb-setup/templates/

# 4. Restart services
sudo systemctl restart adsb-docker

# 5. Verify in web UI
# Navigate to Data Sharing Setup
# Look for "TAKNET-PS" section
```

## ✅ Verification

After installation, verify the modifications were applied correctly:

### Check 1: Files Present
```bash
ls -la /opt/adsb/adsb-setup/utils/other_aggregators.py
ls -la /opt/adsb/adsb-setup/templates/aggregators.html
grep -i "TaknetPS" /opt/adsb/adsb-setup/utils/other_aggregators.py
```

Expected output: Files exist and TaknetPS class found.

### Check 2: Web UI
1. Open web browser to `http://your-pi-ip`
2. Navigate to "Data Sharing Setup"
3. Scroll down past sdrmap
4. Look for "TAKNET-PS (Custom Aggregator)" section

Expected: TAKNET-PS checkbox and port field visible.

### Check 3: Tailscale Enhancement
1. Navigate to "System Management"
2. Find "Add Tailscale" section  
3. Look for "Tailscale auth key" input field

Expected: Auth key field present with helper text.

## 🔧 Post-Installation Configuration

### For End Users
Follow **docs/USER_GUIDE.md** for:
- Enabling TAKNET-PS
- Entering port number
- Configuring Tailscale (optional)

### For Administrators
Follow **docs/DEPLOYMENT.md** for:
- Mass deployment strategies
- Testing procedures
- Monitoring setup

## 🚨 Troubleshooting Installation

### Issue: Files not copying
```bash
# Check permissions
ls -la src/modules/adsb-feeder/filesystem/root/opt/adsb/adsb-setup/

# Use sudo if needed
sudo cp -r src/* /opt/adsb/
```

### Issue: TAKNET-PS not appearing in web UI
```bash
# Restart web service
sudo systemctl restart adsb-docker

# Check for Python errors
journalctl -u adsb-feeder -n 50

# Verify import
cd /opt/adsb/adsb-setup
python3 -c "from utils.other_aggregators import TaknetPS; print('OK')"
```

### Issue: Build fails
```bash
# Make sure you're in the adsb-feeder-image directory
cd adsb-feeder-image
pwd

# Check make is installed
which make

# View build logs
make build 2>&1 | tee build.log
```

## 📚 Next Steps

After installation:

1. **Read the docs**: Start with docs/USER_GUIDE.md or docs/DEPLOYMENT.md
2. **Test on one feeder**: Don't deploy to all feeders immediately
3. **Verify data flow**: Check aggregator receives data
4. **Monitor for 24 hours**: Ensure stable operation
5. **Roll out gradually**: Deploy in batches

## 🔄 Updating

To update to a newer version:

```bash
# 1. Backup current installation
sudo cp -r /opt/adsb/adsb-setup /opt/adsb/adsb-setup.backup

# 2. Extract new version
tar xzf taknet-adsb-im-mod-v1.1.0.tar.gz
cd taknet-adsb-im-mod

# 3. Read CHANGELOG.md for breaking changes
cat CHANGELOG.md

# 4. Apply new modifications
sudo cp -r src/* /opt/adsb/

# 5. Restart
sudo systemctl restart adsb-docker
```

## 🗑️ Uninstalling

To remove TAKNET-PS modifications:

```bash
# 1. Restore from backup
sudo cp -r /opt/adsb/adsb-setup.backup/* /opt/adsb/adsb-setup/

# 2. Restart services
sudo systemctl restart adsb-docker

# 3. Or re-flash with original adsb.im image
```

## 📞 Support

### Installation Issues
1. Check this file (INSTALL.md)
2. Review error messages
3. Verify file permissions
4. Check system logs

### Usage Issues
1. Read docs/USER_GUIDE.md
2. Check docs/QUICK_REFERENCE.md
3. Review docs/DEPLOYMENT.md

### Technical Issues
1. Read docs/MODIFICATIONS.md
2. Check CHANGELOG.md
3. Review code comments

## ✨ Installation Complete!

If you've successfully applied the modifications:

✅ TaknetPS class added  
✅ Web UI updated  
✅ Tailscale enhanced  
✅ Documentation available  

**Next**: Configure TAKNET-PS in the web UI (see docs/USER_GUIDE.md)

---

**Questions?** See docs/ directory for comprehensive guides.

**Issues?** Check CHANGELOG.md and docs/DEPLOYMENT.md troubleshooting.

**Version**: 1.0.0  
**Last Updated**: January 2025
