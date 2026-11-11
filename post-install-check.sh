#!/bin/bash
#
# Purpose : Check a Debian 12 EmComm Tools system after install.sh + reboot.
#           Test helper for the Debian migration.
#
# Usage   : Log in to the desktop as the user who ran install.sh, open a
#           terminal and run (NOT with sudo):
#             ./post-install-check.sh
#
# Output  : PASS / WARN / FAIL per check, a summary, and a report saved to
#           ~/etc-post-install-report.txt. Exit code 1 if anything failed.
#
# Tip     : /tmp is cleared at boot on Debian 12, so save the install log
#           BEFORE rebooting:  cp /tmp/et/et.log ~/et-install.log
#           This script scans ~/et-install.log or /tmp/et/et.log if present.

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPORT="${HOME}/etc-post-install-report.txt"
ADDON=/opt/emcomm-tools/add-ons/crypto/scripts/install-crypto.sh
CRYPTO_MARKER=/etc/emcomm-tools/crypto-enabled

GREEN="\033[0;32m"; RED="\033[0;31m"; YELLOW="\033[1;33m"; BLUE="\033[1;34m"; NC="\033[0m"
PASS=0; FAIL=0; WARN=0

exec > >(tee >(sed 's/\x1b\[[0-9;]*m//g' > "${REPORT}")) 2>&1

section() { echo -e "\n${BLUE}== $1 ==${NC}"; }
pass()    { PASS=$((PASS+1)); echo -e "  ${GREEN}PASS${NC}  $1"; }
fail()    { FAIL=$((FAIL+1)); echo -e "  ${RED}FAIL${NC}  $1${2:+  -> $2}"; }
warn()    { WARN=$((WARN+1)); echo -e "  ${YELLOW}WARN${NC}  $1${2:+  -> $2}"; }

# check "description" command...   (PASS if the command succeeds)
check()   { local d="$1"; shift; if "$@" >/dev/null 2>&1; then pass "$d"; else fail "$d"; fi; }
# check_not "description" command... (PASS if the command fails)
check_not() { local d="$1"; shift; if "$@" >/dev/null 2>&1; then fail "$d"; else pass "$d"; fi; }

installed() { dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q "install ok installed"; }
gs()        { gsettings get "$@" 2>/dev/null; }

if [[ $EUID -eq 0 ]]; then
  echo "Run this as your normal desktop user, not as root or with sudo."
  exit 2
fi

echo "EmComm Tools post-install check - $(date)"
echo "User: $(id -un)   Host: $(hostname)   Kernel: $(uname -r)"

# ---------------------------------------------------------------------------
section "Base OS and apt"
. /etc/os-release
[[ "${ID}" == "debian" && "${VERSION_ID}" == "12" ]] && pass "Debian 12 (${PRETTY_NAME})" || fail "Debian 12" "found ${PRETTY_NAME}"
check     "apt sources point at bookworm"              grep -rqs 'bookworm' /etc/apt/sources.list
check_not "no Ubuntu apt sources left"                 grep -rqs 'ubuntu.com' /etc/apt/sources.list /etc/apt/sources.list.d
check_not "no Cubic @reboot line in /etc/crontab"      grep -q 'emcomm-tools-os-community/overlay' /etc/crontab
check     "dpkg has no half-installed packages"        bash -c '[[ -z "$(dpkg --audit)" ]]'
check     "apt dependency check is clean"              apt-get check

# ---------------------------------------------------------------------------
section "Package swaps"
check     "java is OpenJDK 17"                         bash -c 'java -version 2>&1 | grep -q "\"17\."'
check     "python runs Python 3"                       bash -c 'python --version 2>&1 | grep -q "^Python 3"'
check_not "python2 not installed"                      installed python2
check_not "firefox-esr removed"                        installed firefox-esr
check_not "LibreOffice removed"                        bash -c 'dpkg -l "libreoffice-*" 2>/dev/null | grep -q "^ii"'
for p in gnome-terminal nautilus gnome-control-center seahorse; do
  check   "GNOME app kept after purge: ${p}"            installed "${p}"
done
check_not "Debian first-login wizard removed"         installed gnome-initial-setup
[[ "$(gsettings get org.gnome.system.location enabled 2>/dev/null)" == "false" ]] && pass "location services off" || fail "location services off" "turned on in your account? gsettings reset org.gnome.system.location enabled"
check     "thunderbird installed"                      installed thunderbird
check     "wine installed"                             installed wine
installed "wine32:i386" && pass "wine32:i386 installed (32-bit WINE for VARA)" || warn "wine32:i386 not installed" "VARA needs 32-bit WINE"

# ---------------------------------------------------------------------------
section "Prebuilt packages"
for p in wsjtx js8call sdrpp pat min et-predict-app et-aircraft-app; do
  check   "${p} installed"                              installed "${p}"
done
check     "SDR++ is the Debian bookworm build"         bash -c 'ls /opt/dist/sdrpp_debian_bookworm_amd64.deb'

# ---------------------------------------------------------------------------
section "User setup ($(id -un))"
[[ "$(id -gn)" == "et-data" ]] && pass "primary group is et-data" || fail "primary group is et-data" "is $(id -gn) (log out/in after install?)"
for g in $(sed -n 's/^EXTRA_GROUPS="\(.*\)"/\1/p' /etc/adduser.conf); do
  if getent group "${g}" >/dev/null; then
    id -nG | tr ' ' '\n' | grep -qx "${g}" && pass "in group ${g}" || fail "in group ${g}"
  fi
done
check     "~/.bash_profile from /etc/skel"             test -f "${HOME}/.bash_profile"
check     "~/Desktop/offline present"                  test -d "${HOME}/Desktop/offline"
check     "Reticulum (rnsd) in ~/.local/bin"           test -x "${HOME}/.local/bin/rnsd"
check     "NomadNet in ~/.local/bin"                   test -x "${HOME}/.local/bin/nomadnet"
[[ "$(umask)" == "0002" ]] && pass "umask is 0002" || warn "umask is $(umask)" "expected 0002 from ~/.bash_profile (check in a new terminal)"
check     "et-api user service file present"           test -f "${HOME}/.config/systemd/user/et-service-et-api.service"

# ---------------------------------------------------------------------------
section "PATH"
check     "/etc/profile.d/emcomm-tools.sh installed"   test -f /etc/profile.d/emcomm-tools.sh
LOGIN_PATH=$(bash -lc 'echo $PATH' 2>/dev/null)
[[ ":${LOGIN_PATH}:" == *":/opt/emcomm-tools/bin:"* ]] && pass "login shell PATH has /opt/emcomm-tools/bin" || fail "login shell PATH has /opt/emcomm-tools/bin" "${LOGIN_PATH}"
[[ ":${PATH}:" == *":/opt/emcomm-tools/bin:"* ]] && pass "this session's PATH has /opt/emcomm-tools/bin" || fail "this session's PATH has /opt/emcomm-tools/bin" "log out and back in"
for c in et-radio et-mode et-log et-user-first-login; do
  check   "${c} found on login PATH"                   bash -lc "command -v ${c}"
done
check     "~/.local/bin on login PATH"                 bash -lc '[[ ":$PATH:" == *":$HOME/.local/bin:"* ]]'

# ---------------------------------------------------------------------------
section "Desktop (GNOME)"
check     "settings override installed"                test -f /usr/share/glib-2.0/schemas/90_emcomm-tools.gschema.override
check_not "old Ubuntu override gone"                   test -f /usr/share/glib-2.0/schemas/90_ubuntu-settings.gschema.override
EXT=$(gs org.gnome.shell enabled-extensions)
for e in dash-to-dock@micxgx.gmail.com ding@rastersoft.com ubuntu-appindicators@ubuntu.com; do
  [[ "${EXT}" == *"${e}"* ]] && pass "extension enabled: ${e}" || fail "extension enabled: ${e}" "${EXT}"
done
if command -v gnome-extensions >/dev/null && [[ -n "${DBUS_SESSION_BUS_ADDRESS}" ]]; then
  ACTIVE=$(gnome-extensions list --enabled 2>/dev/null)
  for e in dash-to-dock@micxgx.gmail.com ding@rastersoft.com ubuntu-appindicators@ubuntu.com; do
    grep -qx "${e}" <<<"${ACTIVE}" && pass "extension running: ${e}" || fail "extension running: ${e}"
  done
else
  warn "not in a desktop session" "extension runtime state not checked"
fi
[[ "$(gs org.gnome.shell.extensions.dash-to-dock dock-fixed)" == "true" ]] && pass "dock always visible" || fail "dock always visible"
[[ "$(gs org.gnome.shell.extensions.dash-to-dock dock-position)" == "'LEFT'" ]] && pass "dock on the left" || fail "dock on the left"
[[ "$(gs org.gnome.shell favorite-apps)" == *"et-user.desktop"* ]] && pass "ETC launchers in favorites" || fail "ETC launchers in favorites" "$(gs org.gnome.shell favorite-apps)"
[[ "$(gs org.gnome.desktop.interface gtk-theme)" == "'Yaru-dark'" ]] && pass "Yaru-dark theme" || fail "Yaru-dark theme" "$(gs org.gnome.desktop.interface gtk-theme)"
check     "Yaru-dark theme files present"              test -d /usr/share/themes/Yaru-dark
[[ "$(gs org.gnome.desktop.wm.preferences button-layout)" == *"minimize,maximize,close"* ]] && pass "minimize/maximize/close buttons" || fail "minimize/maximize/close buttons"
[[ "$(gs org.gnome.desktop.background picture-uri)" == *"emcomm-tools-wallpaper"* ]] && pass "ETC wallpaper set" || fail "ETC wallpaper set"
check     "wallpaper file present"                     test -f /usr/share/backgrounds/emcomm-tools-wallpaper.png

# ---------------------------------------------------------------------------
section "Boot splash and installer branding"
THEME=$(plymouth-set-default-theme 2>/dev/null || readlink -f /usr/share/plymouth/themes/default.plymouth)
[[ "${THEME}" == *bgrt* ]] && pass "Plymouth theme is bgrt" || fail "Plymouth theme is bgrt" "${THEME}"
check     "splash in /etc/default/grub"                grep -q '^GRUB_CMDLINE_LINUX_DEFAULT=.*splash' /etc/default/grub
check     "splash on this boot's kernel command line"  grep -qw splash /proc/cmdline
if [[ -f "${REPO_DIR}/overlay/usr/share/plymouth/themes/spinner/watermark.png" ]]; then
  check   "ETC watermark installed"                    cmp -s "${REPO_DIR}/overlay/usr/share/plymouth/themes/spinner/watermark.png" /usr/share/plymouth/themes/spinner/watermark.png
fi
for f in branding.desc show.qml logo.png background.png screenshots/et-radio.png; do
  check   "Calamares branding: ${f}"                   test -f "/etc/calamares/branding/emcomm-tools/${f}"
done

# ---------------------------------------------------------------------------
section "EmComm Tools services"
if systemctl --user is-active --quiet et-service-et-api 2>/dev/null; then
  pass "et-api user service running"
  CODE=$(curl -s -o /dev/null -w '%{http_code}' --max-time 10 http://localhost:1981/api/geo/position)
  [[ "${CODE}" =~ ^[2-4][0-9][0-9]$ ]] && pass "et-api answers on :1981 (HTTP ${CODE})" || fail "et-api answers on :1981" "HTTP ${CODE:-none}"
else
  warn "et-api user service not running" "it may only start via et-* tools; try: systemctl --user start et-service-et-api"
fi

# ---------------------------------------------------------------------------
section "Encryption opt-in"
check     "crypto add-on staged"                       test -x "${ADDON}"
if [[ -e "${CRYPTO_MARKER}" ]]; then
  echo "  (encryption tools were chosen)"
  check   "gpa installed"                              command -v gpa
  check   "pfte installed"                             test -d /opt/pfte/bin
  check   "veracrypt installed"                        installed veracrypt
  check   "steghide installed"                         installed steghide
  check   "crypto guides in ~/Desktop/offline/crypto"  test -f "${HOME}/Desktop/offline/crypto/gpg-cheatsheet.md"
  check   "AmRRON public key present"                  test -f "${HOME}/Desktop/offline/nets/amrron/AmRRON_Actual_ECC_PUBLIC.asc"
else
  echo "  (encryption tools were NOT chosen)"
  check_not "gpa not installed"                        command -v gpa
  check_not "pfte not installed"                       test -d /opt/pfte/bin
  check_not "veracrypt not installed"                  installed veracrypt
  check_not "steghide not installed"                   installed steghide
  check_not "no crypto guides in /etc/skel"            test -d /etc/skel/Desktop/offline/crypto
  check_not "no AmRRON public key in /etc/skel"        test -f /etc/skel/Desktop/offline/nets/amrron/AmRRON_Actual_ECC_PUBLIC.asc
fi

# ---------------------------------------------------------------------------
section "Install log"
LOG=""
for l in "${HOME}/et-install.log" /tmp/et/et.log; do [[ -f "$l" ]] && { LOG="$l"; break; }; done
if [[ -n "${LOG}" ]]; then
  ERRS=$(grep -c 'failed with exit code' "${LOG}")
  if [[ "${ERRS}" -eq 0 ]]; then
    pass "no failed commands in ${LOG}"
  else
    fail "${ERRS} failed command(s) in ${LOG}"
    grep 'failed with exit code' "${LOG}" | sed 's/^/        /' | head -30
  fi
else
  warn "no install log found" "/tmp is cleared at boot; next time: cp /tmp/et/et.log ~/et-install.log before rebooting"
fi

# ---------------------------------------------------------------------------
section "Existing ETC test suite (tests/run-test-suite.sh)"
if [[ -d "${REPO_DIR}/tests" ]]; then
  SUITE=$(cd "${REPO_DIR}/tests" && ./run-test-suite.sh 2>&1 | sed 's/\x1b\[[0-9;]*m//g')
  SUITE_FAILS=$(grep -c 'FAILED' <<<"${SUITE}")
  SUITE_PASSES=$(grep -c 'PASSED' <<<"${SUITE}")
  if [[ "${SUITE_FAILS}" -eq 0 ]]; then
    pass "all ${SUITE_PASSES} suite tests passed"
  else
    fail "${SUITE_FAILS} of $((SUITE_FAILS+SUITE_PASSES)) suite tests failed"
    grep 'FAILED' <<<"${SUITE}" | sed 's/^/        /'
  fi
else
  warn "tests/ not found next to this script" "suite not run"
fi

# ---------------------------------------------------------------------------
echo
echo -e "${BLUE}== Summary ==${NC}"
echo -e "  ${GREEN}${PASS} passed${NC}, ${RED}${FAIL} failed${NC}, ${YELLOW}${WARN} warnings${NC}"
echo "  Report saved to ${REPORT}"
echo
echo "Still manual (see REGRESSION.md): radio CAT/audio with JS8Call and WSJT-X,"
echo "VARA under WINE, GPS, maps, and the ISO build (scripts/build-iso.sh)."

[[ "${FAIL}" -eq 0 ]]
