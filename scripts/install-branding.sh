#!/bin/bash
#
# Author  : Gaston Gonzalez
# Date    : 16 March 2024
# Updated : 11 November 2026
# Purpose : Install boot/desktop branding

et-log "Installing EmComm Tools branding"

apt install plymouth plymouth-themes -y

PLYMOUTH_DIR=/usr/share/plymouth

et-log "Installing desktop wallpaper..."
cp -v ../logos/emcomm-tools-wallpaper.png /usr/share/backgrounds/

et-log "Installing spinners..."
cp -v ../overlay/usr/share/plymouth/themes/spinner/*.png "${PLYMOUTH_DIR}/themes/spinner/"

# r7 used Ubuntu's default 'bgrt' theme, which draws the images in
# themes/spinner/. Debian defaults to its own desktop-base theme.
et-log "Setting boot splash theme..."
# Debian's plymouth initramfs hook replaces the two-step watermark with
# desktop-base's Debian logo. Divert that logo and put ETC's watermark there.
DEBIAN_LOGO=/usr/share/desktop-base/debian-logos/logo-text-version-64.png
if [[ -e "${DEBIAN_LOGO}" || -e "${DEBIAN_LOGO}.debian" ]]; then
  dpkg-divert --local --rename --add --divert "${DEBIAN_LOGO}.debian" "${DEBIAN_LOGO}"
  cp -v ../overlay/usr/share/plymouth/themes/spinner/watermark.png "${DEBIAN_LOGO}"
fi

plymouth-set-default-theme -R bgrt

# GRUB is installed later, by the installer; its update-grub reads this
# drop-in: 'splash' for plymouth (Debian's default is 'quiet' only), "EmComm
# Tools" instead of "Debian GNU/Linux", and ETC's boot background (the same
# image as the live ISO's boot menu).
et-log "Configuring the GRUB menu and boot splash (drop-in)..."
cp -v ../logos/emcomm-tools-boot-800x600.png /usr/share/backgrounds/emcomm-tools-grub.png
mkdir -p /etc/default/grub.d
cat > /etc/default/grub.d/emcomm-tools.cfg <<'EOF'
GRUB_CMDLINE_LINUX_DEFAULT="${GRUB_CMDLINE_LINUX_DEFAULT} splash"
GRUB_DISTRIBUTOR="EmComm Tools"
GRUB_BACKGROUND="/usr/share/backgrounds/emcomm-tools-grub.png"
EOF

gsettings set org.gnome.desktop.background picture-uri file:////usr/share/backgrounds/emcomm-tools-wallpaper.png
gsettings set org.gnome.desktop.background picture-uri-dark file:////usr/share/backgrounds/emcomm-tools-wallpaper.png
