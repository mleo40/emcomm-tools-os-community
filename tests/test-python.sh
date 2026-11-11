#!/bin/bash
# Author   : Gaston Gonzalez
# Updated  : 11 November 2026
# Purpose  : Test that 'python' runs Python 3 (Python 2 is not on Debian 12)

OUT=$(python --version 2>&1 | grep "^Python 3")
exit $?
