#!/bin/bash
#
# Author  : Gaston Gonzalez
# Date    : 16 March 2024
# Updated : 11 November 2026
# Purpose : Main installer for EmComm Tools Community (ETC)

. ./env.sh
. ./functions.sh

exitIfNotRoot

./bootstrap.sh
./update-apt.sh
./install-release.sh

./install-base.sh
./install-dev-tools.sh
./install-pup.sh
./install-browser.sh
./remove-packages.sh
./install-branding.sh

./configure-gnome.sh
./configure-user.sh

./install-emcomm-tools.sh
./fix-panasonic-brightness.sh

./install-hamlib.sh
./install-js8call.sh

./install-udev.sh
./install-gps.sh 
./install-navit.sh
./install-cat.sh

./install-conky.sh

# Install packet tool chain
./install-direwolf.sh
./install-yaac.sh
./install-bbs-client.sh
./install-bbs-server.sh
./install-chattervox.sh
./install-qttermtcp.sh
./install-packet.sh

# Install modems
./install-ardop.sh

./install-winlink.sh

./install-audio-tools.sh

# Offline KBs (Cyberdeck)
./install-wikipedia.sh

# Add user-specific data
./download-osm-maps.sh
[ ! -z "${ET_EXPERT}" ] && ./download-wikipedia.sh

./install-wine.sh

# Install GIS applications and dependencies
./install-mbtileserver.sh
./install-python.sh
./install-mbutil.sh
./install-gis-tools.sh

# Install RF analysis and prediction tools
./install-rf-analysis-tools.sh

# Install SDR tools
./install-sdr-tools.sh
./install-dump1090.sh
./install-sdrpp.sh

# Install ETC custom maps
./download-et-maps.sh

# Install ETC applications
./install-et-api.sh
./install-et-aircraft.sh
./install-et-predict.sh

# Install documentation tools
./install-dictionary.sh
#./install-doc-tools.sh

# Install prediction tools
./install-voacap.sh

# Install fldigi suite
./install-fldigi.sh
./install-flmsg.sh
./install-flamp.sh
./install-et-portaudio.sh

# Instal SIGINT tools
./install-minimodem.sh

# Install ISO tools
./install-ventoy.sh

# Install offline resources
./install-offline-lib.sh

# Install WSJT-X (FT8)
./install-wsjtx.sh

# Install simple WWV util
./install-et-wwv.sh

# Security Patches
./patch-copy-fail.sh

# Install Reticulum and related applications
./install-python3.sh
./install-reticulum.sh
./install-nomadnet.sh
./install-meshchat.sh
./install-partyline.sh
./install-modem73.sh
./install-mercury.sh
./install-mercury-stats.sh
./install-offline-rnode-firmware.sh

# Debrand
./debrand.sh

# Email
./install-thunderbird.sh

# EmComm Tools PnP GUI apps
./install-et-user-app.sh

# Offline Multimedia (DVD)
./install-media-player.sh

# Install Rust (root-only) and the xara modem
./install-rust.sh
./install-xara.sh

# Optional encryption tools (opt-in, default No). Always stage the add-on so it
# can be installed later, including on systems installed from an ISO.
./install-crypto.sh --stage
case "${ET_CRYPTO}" in
  yes) ./install-crypto.sh --yes ;;
  no)  et-log "ET_CRYPTO=no: encryption tools not installed." ;;
  *)   if [ -t 0 ]; then
         ./install-crypto.sh
       else
         et-log "No terminal for the encryption prompt: encryption tools not installed."
       fi ;;
esac

# 'et-build-iso' runs build-iso.sh from this clone. /usr/local/bin is on both the
# user's PATH and sudo's secure_path. The link breaks if this clone is moved or
# deleted.
ln -sfv "$(pwd)/build-iso.sh" /usr/local/bin/et-build-iso

# Apply the user setup to the account running this script (run last, after
# everything has been added to /etc/skel).
./configure-existing-user.sh
