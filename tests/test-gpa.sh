#!/bin/bash
# Author   : Gaston Gonzalez
# Date     : 6 March 2026
# Updated  : 11 November 2026
# Purpose  : Test GNU Privacy Assistant installation (optional encryption tools)

# Only expected when the optional encryption tools were installed.
[[ -e /etc/emcomm-tools/crypto-enabled ]] || exit 0

OUT=$(which gpa)
exit $?
