#!/bin/bash
#
# Author  : Gaston Gonzalez
# Date    : 16 March 2024
# Updated : 11 November 2026
# Purpose : Install base tools and configuration
set -e

et-log "Installing environment variables..."
cp -v ../overlay/etc/environment /etc/

et-log "Installing message of the day..."
cp -v ../overlay/etc/motd /etc/

# Debian's /etc/profile resets PATH for login shells, dropping the entries set
# in /etc/environment. Re-add them from /etc/profile.d.
et-log "Installing PATH profile..."
cp -v ../overlay/etc/profile.d/emcomm-tools.sh /etc/profile.d/
chmod 644 /etc/profile.d/emcomm-tools.sh

et-log "Installing base packages..."

apt install \
  build-essential \
  cmake \
  curl \
  imagemagick \
  jq \
  net-tools \
  openjdk-17-jdk \
  openssh-server \
  screen \
  socat \
  stow \
  xsel \
  tree \
  tty-clock \
  -y
