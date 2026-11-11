#!/bin/bash
#
# Author  : Gaston Gonzalez
# Date    : 29 December 2023
# Updated : 11 November 2026
# Purpose : Install development tools
set -e

et-log "Installing dev tools for fldigi..."
apt install \
  autoconf \
  dialog \
  gettext \
  libfltk1.3-dev \
  libportaudio2 \
  libsamplerate0-dev \
  libsndfile1-dev \
  libudev-dev \
  pkg-config \
  portaudio19-dev \
  -y

et-log "Installing dev tools for building EmComm Tools packages and general development..."
apt install \
  git \
  libfuse2 \
  meld \
  rpm \
  vim \
  -y

# libyaml-dev - needed for Ruby via rbenv
et-log "Installing tools needed for ETC R5"
apt install \
  libyaml-dev \
  -y
