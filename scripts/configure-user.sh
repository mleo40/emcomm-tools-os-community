#!/bin/bash
#
# Author  : Gaston Gonzalez
# Date    : 16 March 2024
# Updated : 11 November 2026
# Purpose : Configure users and groups
set -e

ET_GID=1981

et-log "Adding '${ET_GROUP}' group..."
getent group ${ET_GROUP} >/dev/null || groupadd -g ${ET_GID} ${ET_GROUP}

et-log "Configuring users..."

cp -r ../overlay/etc/skel /etc/
[ ! -e /etc/skel/Desktop ] && mkdir /etc/skel/Desktop

et-log "Add all users to dialout group..."
cp -v -r ../overlay/etc/adduser.conf /etc/

