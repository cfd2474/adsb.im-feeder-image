# TAKNET-PS ADS-B Feeder Image Modifications

Custom modifications to the [adsb.im feeder image](https://github.com/dirkhh/adsb-feeder-image) project adding TAKNET-PS aggregator support with automatic host selection and enhanced Tailscale integration.

## 🎯 Features

### TAKNET-PS Custom Aggregator
- **Automatic Host Selection**: Automatically routes to the correct aggregator based on Tailscale status
  - `tailscale.leckliter.net` when Tailscale is active
  - `adsb.leckliter.net` when Tailscale is not active
- **Simple Configuration**: Only requires port number - host is handled automatically
- **User-Friendly UI**: Clear indication of which host will be used
- **Port Validation**: Ensures valid port numbers (1-65535)

### Enhanced Tailscale Integration
- **Auth Key Support**: Automatic authentication with Tailscale auth keys
- **Manual Fallback**: Traditional login link method still available
- **Secure Handling**: Auth keys are automatically cleared after successful connection
- **User Guidance**: Direct link to Tailscale admin console

## 📦 Quick Start

### For End Users (Pre-built Images)
1. Flash the modified adsb.im image to your SD card
2. Boot and access the web interface
3. Navigate to **Data Sharing Setup**
4. Enable **TAKNET-PS** and enter port: `30005`
5. Optionally configure Tailscale in **System Management**

### For Developers (Building from Source)
```bash
# Clone the original repository
git clone https://github.com/dirkhh/adsb-feeder-image.git
cd adsb-feeder-image

# Apply modifications
# Copy files from this repository:
cp -r path/to/taknet-adsb-im-mod/src/* src/

# Build the image
make build
```

## 📖 Documentation

- **[MODIFICATIONS.md](docs/MODIFICATIONS.md)** - Detailed technical changes
- **[INTEGRATION.md](docs/INTEGRATION.md)** - Docker compose and network configuration
- **[USER_GUIDE.md](docs/USER_GUIDE.md)** - End-user setup instructions
- **[DEPLOYMENT.md](docs/DEPLOYMENT.md)** - Mass deployment guide
- **[CHANGELOG.md](docs/CHANGELOG.md)** - Version history and changes

## 🔧 Modified Files

```
src/modules/adsb-feeder/filesystem/root/opt/adsb/adsb-setup/
├── utils/other_aggregators.py    # Added TaknetPS class
├── app.py                         # Enhanced aggregator + Tailscale handling
└── templates/
    ├── aggregators.html           # TAKNET-PS UI
    └── systemmgmt.html            # Enhanced Tailscale UI
```

## 🌐 Network Configuration

### Host Selection Logic
```
┌─────────────────────────┐
│  Check Tailscale Status │
└───────────┬─────────────┘
            │
    ┌───────▼────────┐
    │  Tailscale     │
    │   Active?      │
    └───┬────────┬───┘
        │        │
      YES       NO
        │        │
        ▼        ▼
  tailscale.   adsb.
  leckliter.   leckliter.
  net          net
```

### Common Port Numbers
- **30005** - Beast format (recommended for TAKNET-PS)
- **30003** - SBS/BaseStation format
- **30002** - Raw format
- **30006** - Beast reduce format

## 🔒 Security Considerations

### Tailscale Auth Keys
- Use **pre-authorized** keys (NOT ephemeral)
- Keys are never stored permanently
- Keys are cleared after successful connection
- GitHub automatically revokes exposed keys

### Network Security
- All connections use standard ADS-B protocols
- Tailscale provides encrypted mesh network
- Non-Tailscale connections go to public aggregator
- No sensitive data exposed in configuration

## 🐛 Troubleshooting

### TAKNET-PS Not Connecting
```bash
# Check Tailscale status
tailscale status

# Test connectivity to aggregator
ping tailscale.leckliter.net  # or adsb.leckliter.net
telnet tailscale.leckliter.net 30005

# Check ultrafeeder logs
docker logs ultrafeeder --tail 100
```

### Tailscale Authentication Issues
```bash
# Check service status
systemctl status tailscaled

# View logs
journalctl -u tailscaled -f

# Manual connection test
tailscale up --authkey=tskey-auth-xxxxx
```

## 🤝 Contributing

This is a custom modification for TAKNET-PS deployments. For general adsb.im issues, please refer to the [main project](https://github.com/dirkhh/adsb-feeder-image).

### Reporting Issues
For TAKNET-PS specific issues:
1. Check the troubleshooting guide
2. Verify Tailscale connectivity
3. Review aggregator server logs
4. Contact TAKNET-PS support

## 📊 Deployment Status

Compatible with:
- ✅ Raspberry Pi 3B+
- ✅ Raspberry Pi 4
- ✅ Raspberry Pi 5
- ✅ Orange Pi
- ✅ Other ARM SBCs supported by adsb.im

Tested configurations:
- ✅ Rocky Linux aggregator with readsb/tar1090
- ✅ Tailscale mesh network
- ✅ Direct internet connection (non-Tailscale)
- ✅ Multiple feeders to single aggregator

## 📜 License

This project inherits the license from the original [adsb.im feeder image](https://github.com/dirkhh/adsb-feeder-image) project. Custom modifications are provided as-is for TAKNET-PS deployments.

## 🙏 Credits

- Original adsb.im project by [dirkhh](https://github.com/dirkhh)
- TAKNET-PS modifications for Leckliter network deployments
- Tailscale for secure mesh networking

## 📞 Support

For TAKNET-PS specific questions:
- **Network Issues**: Check Tailscale status and connectivity
- **Configuration Help**: See USER_GUIDE.md
- **Deployment**: See DEPLOYMENT.md

For general adsb.im questions:
- [adsb.im Documentation](https://github.com/dirkhh/adsb-feeder-image)
- [adsb.im Discussions](https://github.com/dirkhh/adsb-feeder-image/discussions)

---

**Version**: 2.9.7+taknet.1  
**Last Updated**: January 2025  
**Based on**: adsb.im-feeder-image
