# EmComm Tools OS Community

See https://community.emcommtools.com

## Build on Debian 12

An internet connection is required.

1. Install Debian 12 (bookworm), amd64, with the GNOME desktop. Leave the root
   password empty so your user gets `sudo`.
2. Download EmComm Tools:
   ```bash
   sudo apt update && sudo apt install -y git
   git clone https://github.com/thetechprepper/emcomm-tools-os-community.git
   cd emcomm-tools-os-community/scripts
   ```
3. Install it (from `scripts/`, with `sudo` from your own account):
   ```bash
   sudo ./install.sh
   ```
   The last step asks whether to install the optional encryption tools
   (default No). You can add them later with `sudo ./install-crypto.sh`.
4. Reboot.
5. Optional: build a live ISO of the system:
   ```bash
   sudo ./build-iso.sh
   ```
   Choose a clean ISO to share with others, or a personal ISO that carries
   your own account and data (optionally passphrase-protected). The ISO is
   written to `/home/eggs/`.

See [DEBIAN-MIGRATION.md](DEBIAN-MIGRATION.md) for details.
