#!/bin/bash
# Author   : Gaston Gonzalez
# Date     : 3 November 2024
# Updated  : 11 November 2026
# Purpose  : Test Java installation (Debian 12: OpenJDK 17)

# We need to redirect stderr to stdout otherwise grep will not match.
JAVA_OUT=$(java -version 2>&1 | grep '"17\.')
exit $?
