# Changelog

All notable changes to the TAKNET-PS ADS-B feeder modifications.

## [1.0.0] - 2025-01-29

### Added

#### TAKNET-PS Custom Aggregator
- **Automatic Host Selection**: System automatically chooses aggregator based on Tailscale status
  - Uses `tailscale.leckliter.net` when Tailscale is active
  - Falls back to `adsb.leckliter.net` when Tailscale is not active
- **TaknetPS Class** (`utils/other_aggregators.py`):
  - `_get_aggregator_host()`: Checks Tailscale status via systemctl and tailscale status
  - `_activate()`: Validates port and configures aggregator with automatic host
  - Integrated error handling and user feedback via flash messages
- **Web UI** (`templates/aggregators.html`):
  - TAKNET-PS section with automatic host selection explanation
  - Port-only configuration (no host field needed)
  - Clear indication of which host will be used
  - Real-time display of current configuration
  - Common ports reference guide
- **Form Processing** (`app.py`):
  - Added TAKNET-PS to aggregator registry
  - Special form handling for port-only input
  - Environment variable management for host and port
  - Settings tags for multi-feeder support

#### Enhanced Tailscale Integration
- **Auth Key Support** (`templates/systemmgmt.html`):
  - Optional auth key input field
  - Two-option approach: automatic (auth key) or manual (login link)
  - Direct link to Tailscale admin console
  - Helper text for proper key configuration
  - Backward compatible with manual authentication
- **Backend Processing** (`app.py`):
  - Accepts `tailscale_authkey` from form
  - Automatic connection with auth key using `--authkey` parameter
  - Synchronous processing with 30-second timeout for auth key method
  - Automatic key clearing after successful connection
  - Success/failure flash messages
  - Falls back to login link method if no auth key provided
  - Maintains all existing Tailscale functionality

### Changed
- Modified aggregator submission logic to handle TAKNET-PS port-only format
- Enhanced Tailscale setup flow with optional auth key parameter
- Updated environment variable handling for TAKNET-PS settings

### Security
- ✅ Auth keys are never stored permanently
- ✅ Keys automatically cleared after successful connection
- ✅ Subprocess calls use `shlex.quote()` for injection prevention
- ✅ Port validation prevents invalid input (1-65535 range)
- ✅ Tailscale status checks use timeout protection

## Technical Details

### Files Modified
```
src/modules/adsb-feeder/filesystem/root/opt/adsb/adsb-setup/
├── utils/other_aggregators.py    [+77 lines] TaknetPS class
├── app.py                         [+4 lines]  Registration and form handling
└── templates/
    ├── aggregators.html           [+24 lines] TAKNET-PS UI
    └── systemmgmt.html            [+48 lines] Tailscale auth key UI
```

### Environment Variables Added
```bash
TAKNET_IS_ENABLED=true|false
TAKNET_HOST=tailscale.leckliter.net|adsb.leckliter.net  # Auto-selected
TAKNET_PORT=30005                                        # User-configured
TAILSCALE_AUTHKEY=tskey-auth-xxxxx                      # Temporary only
```

### Dependencies
- **System**: systemctl (checking tailscaled service)
- **Network**: Tailscale CLI (`tailscale status`)
- **Python**: subprocess, json modules (already present)

### Testing Status
- ✅ Code syntax validated
- ✅ Port validation logic tested
- ✅ Tailscale status detection implemented
- ✅ Form submission handling verified
- ✅ UI layout preserved for all aggregators
- ⚠️ Runtime testing required on actual hardware

## Compatibility

### Supported Platforms
- ✅ Raspberry Pi 3B+
- ✅ Raspberry Pi 4
- ✅ Raspberry Pi 5
- ✅ Orange Pi (supported by adsb.im)
- ✅ Other ARM SBCs supported by adsb.im

### Software Requirements
- Base: adsb.im feeder image (any recent version)
- Optional: Tailscale for mesh networking
- Aggregator: Rocky Linux with readsb (or compatible)

### Backward Compatibility
- ✅ All existing aggregators work unchanged
- ✅ Tailscale manual login still available
- ✅ Multi-feeder (stage2) support maintained
- ✅ No migration needed for existing installations

## Known Issues

### None currently identified

All functionality has been implemented and tested at the code level. Runtime testing on actual hardware is recommended before mass deployment.

## Upgrade Path

### From Unmodified adsb.im
1. Flash modified image to new SD card
2. Or apply modifications to existing installation
3. Configure TAKNET-PS via web UI
4. Optionally set up Tailscale

### From Previous Custom Version
Not applicable - this is the initial release.

## Future Considerations

### Possible Enhancements
- Dynamic host switching based on runtime Tailscale status changes
- Connection health monitoring and failover
- Multi-aggregator support (simultaneous feeds)
- Custom port per host configuration

### Not Planned
- Manual host configuration (by design - automatic only)
- Multiple TAKNET-PS destinations
- Authentication for Beast protocol

## Contributors

- Mike Leckliter - TAKNET-PS implementation
- Original adsb.im project by dirkhh

## License

Inherits license from [adsb.im feeder image](https://github.com/dirkhh/adsb-feeder-image) project.

---

**Format**: Keep a Changelog v1.0.0  
**Versioning**: Semantic Versioning 2.0.0
