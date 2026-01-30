#!/bin/bash
set -e

# TAKNET-PS ADS-B Feeder Modification Installer
# https://github.com/cfd2474/adsb.im-feeder-image

VERSION="v2.9.7-taknet.1"
REPO_URL="https://github.com/cfd2474/adsb.im-feeder-image"
PACKAGE_URL="${REPO_URL}/releases/download/${VERSION}/taknet-adsb-im-mod.tar.gz"
INSTALL_DIR="/opt/adsb/adsb-setup"
BACKUP_DIR="/opt/adsb/adsb-setup.backup.$(date +%Y%m%d_%H%M%S)"

echo "================================================"
echo "TAKNET-PS ADS-B Feeder Modification Installer"
echo "================================================"
echo ""
echo "This will install TAKNET-PS modifications to your"
echo "existing adsb.im feeder installation."
echo ""
echo "Features:"
echo "  - Automatic host selection (Tailscale/non-Tailscale)"
echo "  - Enhanced Tailscale auth key support"
echo "  - Simple port-only configuration"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "ERROR: This script must be run as root"
  echo "Please run: curl -fsSL https://raw.githubusercontent.com/cfd2474/adsb.im-feeder-image/main/install.sh | sudo bash"
  exit 1
fi

# Check if adsb.im is installed
if [ ! -d "$INSTALL_DIR" ]; then
  echo "ERROR: adsb.im installation not found at $INSTALL_DIR"
  echo "Please install adsb.im first: https://adsb.im"
  exit 1
fi

echo "✓ Found adsb.im installation"
echo ""

# Confirm installation
read -p "Continue with installation? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Installation cancelled."
  exit 0
fi

# Create backup
echo ""
echo "Creating backup..."
cp -r "$INSTALL_DIR" "$BACKUP_DIR"
echo "✓ Backup created at: $BACKUP_DIR"

# Download package
echo ""
echo "Downloading TAKNET-PS modifications..."
cd /tmp
rm -f taknet-mod.tar.gz taknet-adsb-im-mod 2>/dev/null || true
curl -L -o taknet-mod.tar.gz "$PACKAGE_URL"
echo "✓ Downloaded package"

# Extract
echo ""
echo "Extracting..."
tar xzf taknet-mod.tar.gz
echo "✓ Extracted"

# Install
echo ""
echo "Installing modifications..."
cp -r taknet-adsb-im-mod/src/modules/adsb-feeder/filesystem/root/opt/adsb/adsb-setup/* "$INSTALL_DIR/"
echo "✓ Files copied"

# Restart services
echo ""
echo "Restarting services..."
systemctl restart adsb-docker
echo "✓ Services restarted"

# Cleanup
cd /tmp
rm -rf taknet-mod.tar.gz taknet-adsb-im-mod

# Get IP address
IP_ADDR=$(hostname -I | awk '{print $1}')

echo ""
echo "================================================"
echo "Installation Complete! ✓"
echo "================================================"
echo ""
echo "Next steps:"
echo "  1. Open web interface: http://${IP_ADDR}"
echo "  2. Go to 'Data Sharing Setup'"
echo "  3. Enable 'TAKNET-PS' and enter port: 30005"
echo "  4. Click 'Apply'"
echo ""
echo "Optional - Configure Tailscale:"
echo "  1. Get auth key from: https://login.tailscale.com/admin/settings/keys"
echo "  2. Go to 'System Management'"
echo "  3. Paste auth key in Tailscale section"
echo "  4. Click 'Apply'"
echo ""
echo "Backup location: $BACKUP_DIR"
echo "To rollback: sudo rm -rf $INSTALL_DIR && sudo mv $BACKUP_DIR $INSTALL_DIR && sudo systemctl restart adsb-docker"
echo ""
echo "Documentation: ${REPO_URL}"
echo ""
