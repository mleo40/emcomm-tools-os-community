#!/bin/bash
#
# Author  : Gaston Gonzalez
# Date    : 25 April 2025
# Updated : 11 November 2026
# Purpose : Installs Python setuptools and makes 'python' point to python3
#           (Python 2 is not available on Debian 12; mbutil runs on python3)
set -e
trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
trap 'et-log "\"${last_command}\" command failed with exit code $?."' ERR

et-log "Installing Python 3 setuptools and python-is-python3..."

apt install \
  python3-setuptools \
  python-is-python3 \
  -y
