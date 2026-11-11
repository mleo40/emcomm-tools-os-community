# EmComm Tools OS Community

See https://community.emcommtools.com

## Building the ISO

EmComm Tools is built as a Debian 12 (bookworm) live ISO with Debian's
live-build. Users boot it, try it live, and install it with Calamares.

On a Debian 12 machine (a VM is fine) with about 60 GB free and internet:

```bash
git clone https://github.com/thetechprepper/emcomm-tools-os-community.git
cd emcomm-tools-os-community/live-build
sudo ./build.sh
```

The ISO and `build.log` are written to `/var/tmp/etc-live-build/`. See
[ISO-BUILD-PLAN.md](ISO-BUILD-PLAN.md) for how the build works.
