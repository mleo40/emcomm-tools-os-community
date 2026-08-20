#!/bin/bash
#
# Author  : mleo
# Date    : 20 August 2026
# Purpose : User customizations - additional desktop environment
set -e

et-log "Installing XFCE desktop environment..."

apt install \
  xfce4 \
  xfce4-goodies \
  --install-recommends \
  -y
