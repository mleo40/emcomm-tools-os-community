#!/bin/bash
#
# Date    : 12 November 2026
# Purpose : Validate an EmComm Tools system installed from the ISO (or the
#           live session). Checks the system setup, then runs ETC's app tests.
#
# Usage   : Run as the normal user (not root), offline or online:
#             /opt/emcomm-tools-os-community/tests/validate-install.sh
#           Options:
#             --no-apps   skip ETC's app tests (test-*.sh)
#
# Exit code: the number of failed checks (0 means everything passed).
# WARN lines need a look but aren't failures; SKIP lines don't apply here.

RUN_APPS=1
[[ "${1:-}" == "--no-apps" ]] && RUN_APPS=0

TESTS_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
# Run from elsewhere (a USB stick): use the app tests in the repository copy.
ls "${TESTS_DIR}"/test-*.sh >/dev/null 2>&1 || TESTS_DIR=/opt/emcomm-tools-os-community/tests
export PATH="/opt/emcomm-tools/bin:${PATH}"
# Desktop settings and user services, also when run over SSH.
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/${EUID}}"
[[ -z "${DBUS_SESSION_BUS_ADDRESS:-}" && -S "${XDG_RUNTIME_DIR}/bus" ]] \
  && export DBUS_SESSION_BUS_ADDRESS="unix:path=${XDG_RUNTIME_DIR}/bus"

if [[ -t 1 ]]; then
  G="\033[0;32m"; R="\033[0;31m"; Y="\033[1;33m"; B="\033[1;34m"; N="\033[0m"
else
  G=""; R=""; Y=""; B=""; N=""
fi
PASS=0; FAIL=0; WARN=0; SKIP=0

pass()    { PASS=$((PASS+1)); printf "  ${G}PASS${N}  %s\n" "$1"; }
fail()    { FAIL=$((FAIL+1)); printf "  ${R}FAIL${N}  %s\n" "$1"; }
warn()    { WARN=$((WARN+1)); printf "  ${Y}WARN${N}  %s\n" "$1"; }
skip()    { SKIP=$((SKIP+1)); printf "  SKIP  %s\n" "$1"; }
info()    { printf "  INFO  %s\n" "$1"; }
section() { printf "\n${B}== %s ==${N}\n" "$1"; }
check()   { if eval "$2" >/dev/null 2>&1; then pass "$1"; else fail "$1"; fi; }

if [[ ${EUID} -eq 0 ]]; then
  echo "Run this as your normal user, not as root (it checks your account)."
  exit 1
fi

LIVE=0
[[ -d /run/live/medium ]] || grep -qw 'boot=live' /proc/cmdline && LIVE=1
install_only() { if [[ ${LIVE} -eq 1 ]]; then skip "$1 (live session)"; return 1; fi; return 0; }

echo "EmComm Tools install validation: $(date '+%Y-%m-%d %H:%M')"

# --------------------------------------------------------------------------
section "System"
. /etc/os-release
[[ "${ID}" == "debian" && "${VERSION_ID}" == "12" ]] \
  && pass "Debian 12 (${PRETTY_NAME})" || fail "Not Debian 12: ${PRETTY_NAME}"
REL=$(et-system-info release 2>/dev/null)
[[ "${REL}" == ETC_* ]] && pass "Release: ${REL}" || fail "Release name missing from /etc/lsb-release (got '${REL}')"
info "Kernel $(uname -r); $( [[ ${LIVE} -eq 1 ]] && echo 'live session' || echo 'installed system')"
if [[ -d /sys/firmware/efi ]]; then
  SB=$(od -An -t u1 /sys/firmware/efi/efivars/SecureBoot-8be4df61-93ca-11d2-aa0d-00e098032b8c 2>/dev/null | awk '{print $NF}')
  info "Boot mode: UEFI, Secure Boot $( [[ "${SB}" == "1" ]] && echo on || echo off)"
else
  info "Boot mode: BIOS"
fi
check "PATH includes /opt/emcomm-tools/bin (login shell)" \
  "bash -lc 'echo \$PATH' | tr ':' '\n' | grep -qx /opt/emcomm-tools/bin"
if install_only "Free space on /"; then
  FREE=$(df --output=avail -BG / | tail -1 | tr -dc 0-9)
  [[ ${FREE} -ge 10 ]] && pass "Free space on /: ${FREE} GB" || warn "Free space on /: only ${FREE} GB"
fi

# --------------------------------------------------------------------------
section "User account"
[[ "$(id -gn)" == "et-data" ]] && pass "Primary group is et-data" || fail "Primary group is $(id -gn), not et-data"
for g in dialout audio plugdev sudo; do
  id -nG | tr ' ' '\n' | grep -qx "${g}" && pass "Member of ${g}" || fail "Not a member of ${g}"
done
UJ="${HOME}/.config/emcomm-tools/user.json"
if jq -e '.callsign and .grid' "${UJ}" >/dev/null 2>&1; then
  CALL=$(jq -r .callsign "${UJ}"); GRID=$(jq -r .grid "${UJ}")
  pass "user.json: callsign ${CALL}, grid ${GRID}"
  [[ "${CALL}" == "N0CALL" ]] && warn "Callsign is still the default N0CALL (run et-user)"
else
  fail "${UJ} missing or not valid"
fi
[[ -e "${HOME}/.config/emcomm-tools/first-login-complete" ]] \
  && pass "First-login setup completed" || warn "First-login setup not completed yet"
if install_only "Live user removed"; then
  getent passwd user >/dev/null && warn "Live-session user 'user' exists on the installed system" || pass "No live-session user"
fi

# --------------------------------------------------------------------------
section "Desktop"
check "Dock favorites are ETC's" "gsettings get org.gnome.shell favorite-apps | grep -q et-user.desktop"
check "ETC wallpaper" "gsettings get org.gnome.desktop.background picture-uri | grep -q emcomm-tools"
check "GNOME Software update service off at login" \
  "grep -qx 'Hidden=true' ${HOME}/.config/autostart/org.gnome.Software.desktop"
check "Conky starts at login" "test -e ${HOME}/.config/autostart/conky.desktop"
if install_only "Installer not left installed"; then
  dpkg -s calamares >/dev/null 2>&1 && fail "Installer still installed (\"Install System\" in the app menu)" || pass "Installer removed"
  check "Installer settings removed (/etc/calamares)" "! test -e /etc/calamares"
fi

# --------------------------------------------------------------------------
section "Boot"
check "Boot splash enabled (splash on the kernel command line)" "grep -qw splash /proc/cmdline"
check "Plymouth theme is bgrt" "grep -q 'Theme=bgrt' /etc/plymouth/plymouthd.conf"
if install_only "GRUB branding"; then
  check "GRUB branding drop-in" "grep -q 'EmComm Tools' /etc/default/grub.d/emcomm-tools-branding.cfg"
  if [[ -r /boot/grub/grub.cfg ]]; then
    check "GRUB menu shows EmComm Tools" "grep -q \"EmComm Tools\" /boot/grub/grub.cfg"
  else
    skip "GRUB menu text (grub.cfg is readable only by root; check the boot menu)"
  fi
  check "GRUB background present" "test -s /usr/share/backgrounds/emcomm-tools-grub.png"
fi

# --------------------------------------------------------------------------
section "Services"
if install_only "SSH"; then
  check "SSH server running" "systemctl is-active --quiet ssh"
  check "SSH host keys present" "ls /etc/ssh/ssh_host_*_key.pub"
  check "machine-id set" "test -s /etc/machine-id"
fi
check "chrony running" "systemctl is-active --quiet chrony"
if [[ -e /dev/et-gps ]]; then
  check "GPS plugged in: gpsd running" "systemctl is-active --quiet gpsd"
else
  skip "gpsd (no GPS plugged in)"
fi

check "et-api forecast zone data present" "test -s /opt/emcomm-tools-api/data/weather-forecast-zone.csv"
API=http://localhost:1981
AIRCRAFT="${API}/api/aircraft?icao24=A004B3"
info "Waiting up to 3 minutes for et-api (it builds its indexes on first start)..."
for i in $(seq 1 36); do curl -s -m 3 "${AIRCRAFT}" | jq -e '.[0].make' >/dev/null 2>&1 && break; sleep 5; done
check "et-api service running" "systemctl --user is-active --quiet et-service-et-api"
check "et-api answers: position" "curl -s -m 5 ${API}/api/geo/position | jq -e '.position.lat'"
check "et-api answers: callsign lookup" "curl -s -m 5 '${API}/api/license?callsign=KT7RUN' | jq -e .callsign"
check "et-api answers: aircraft lookup" "curl -s -m 5 '${AIRCRAFT}' | jq -e '.[0].make'"
check "Tile server running" "systemctl --user is-active --quiet et-service-mbtileserver"
check "Tile server answers" "curl -s -m 5 -o /dev/null -w '%{http_code}' http://localhost:1982/services | grep -q 200"
check "World map tiles present" "ls ${HOME}/.local/share/emcomm-tools/mbtileserver/tilesets/*.mbtiles"

# --------------------------------------------------------------------------
section "Packages"
if install_only "apt sources"; then
  check "apt sources include contrib and non-free" \
    "grep -E '^deb .* main contrib non-free' /etc/apt/sources.list"
fi
for p in js8call wsjtx; do
  apt-mark showhold 2>/dev/null | grep -qx "${p}" && pass "${p} held" || fail "${p} not held (apt could replace ETC's build)"
done
JV=$(java -version 2>&1 | awk -F'"' '/version/{print $2}')
[[ "${JV%%.*}" == "17" ]] && pass "Java ${JV}" || fail "Java ${JV:-missing} (expected 17)"
check "WINE installed" "command -v wine"
check "VARA add-on scripts in ~/add-ons/wine" "test -x ${HOME}/add-ons/wine/02-install-vara-hf.sh"
command -v xara >/dev/null && pass "xara installed" || info "xara not installed (not in the ISO)"

# --------------------------------------------------------------------------
section "Encryption tools"
check "Encryption tools can be added later (offline)" "test -x /opt/emcomm-tools-os-community/scripts/install-crypto.sh && test -d /opt/emcomm-tools/add-ons/crypto/payload/debs"
CRYPTO_BIN=(gpa:/usr/local/bin/gpa pfte:/opt/pfte/bin steghide:/usr/bin/steghide)
if [[ -e /etc/emcomm-tools/crypto-enabled ]]; then
  info "Encryption tools were selected"
  for c in "${CRYPTO_BIN[@]}"; do check "${c%%:*} installed" "test -e ${c#*:}"; done
else
  info "Encryption tools were not selected"
  for c in "${CRYPTO_BIN[@]}"; do
    [[ -e ${c#*:} ]] && fail "${c%%:*} installed but not selected" || pass "${c%%:*} not installed"
  done
fi

# --------------------------------------------------------------------------
section "Files"
if [[ -r /opt/emcomm-tools-os-community/scripts/install.sh ]]; then
  pass "Repository copy in /opt/emcomm-tools-os-community"
  check "Repository copy is read-only for users" "! test -w /opt/emcomm-tools-os-community/scripts"
  check "install.sh not executable (no accidental reinstall)" "! test -x /opt/emcomm-tools-os-community/scripts/install.sh"
else
  fail "Repository copy missing: /opt/emcomm-tools-os-community"
fi
for d in /opt/dist /opt/src; do
  [[ -e ${d} ]] && warn "Build folder ${d} present" || pass "No build folder ${d}"
done

# --------------------------------------------------------------------------
section "Radio audio"
if [[ -e /dev/et-audio ]]; then
  info "Interface: $(udevadm info /dev/et-audio 2>/dev/null | sed -n 's/^E: ET_DEVICE=//p')"
  check "Input: ET_AUDIO listed for recording" "arecord -L | grep -q '^sysdefault:CARD=ET_AUDIO'"
  check "Output: ET_AUDIO listed for playback" "aplay -L | grep -q '^sysdefault:CARD=ET_AUDIO'"
else
  skip "No radio audio interface plugged in"
fi

# --------------------------------------------------------------------------
if [[ ${RUN_APPS} -eq 1 ]]; then
  section "ETC app tests (${TESTS_DIR}/test-*.sh)"
  if ! cd "${TESTS_DIR}" 2>/dev/null; then
    fail "App tests not found (${TESTS_DIR})"
  else
  for t in test-*.sh; do
    if [[ "${t}" == "test-xara.sh" ]] && ! command -v xara >/dev/null; then
      skip "${t} (xara not installed)"; continue
    fi
    if PATH=".:${PATH}" bash "./${t}" >/dev/null 2>&1; then pass "${t}"; else fail "${t}"; fi
  done
  fi
fi

# --------------------------------------------------------------------------
printf "\n${B}== Summary ==${N}\n"
printf "  ${G}%d passed${N}, ${R}%d failed${N}, ${Y}%d warnings${N}, %d skipped\n" \
  "${PASS}" "${FAIL}" "${WARN}" "${SKIP}"
exit "${FAIL}"
