# Installing EmComm Tools on Debian 12

This guide installs Debian 12 (bookworm), then installs EmComm Tools on top of it.
The screenshots come from a test install in a virtual machine (UEFI, 4 CPUs,
6 GB RAM, 100 GB disk).

You need:

- A computer (or VM) with at least 4 GB RAM and 64 GB of disk. The disk will be erased.
- An internet connection for the whole install.
- The Debian 12 netinst ISO:
  `https://cdimage.debian.org/cdimage/archive/12.15.0/amd64/iso-cd/debian-12.15.0-amd64-netinst.iso`
  written to a USB stick (or attached to the VM).

Allow 1–2 hours. Most of that time is `install.sh` downloading and compiling.

---

## Part 1: Install Debian 12

### 1. Boot the installer

Boot from the USB stick and choose **Graphical install**.

![Boot menu](images/00-boot-menu.png)

### 2. Language, location and keyboard

Pick your language, country and keyboard layout.

![Language](images/01-language.png)
![Location](images/02-location.png)
![Keyboard](images/03-keyboard.png)

### 3. Hostname and domain

Enter a hostname, for example `emcomm-tools`. Leave the domain empty.

![Hostname](images/04-hostname.png)
![Domain](images/05-domain.png)

### 4. Root password: leave it empty

> **Important:** leave both root password fields **empty** and click **Continue**.

With no root password, Debian disables the root account and gives your user
`sudo`. `install.sh` is run with `sudo`, so your user needs it.

![Root password left empty](images/06-root-password.png)

### 5. Your user account

Enter your full name, a username and a password.

Some usernames are reserved by Debian, for example `operator`. If the
installer rejects your username, pick another one.

![Full name](images/07-full-name.png)
![Username](images/08-username.png)
![User password](images/09-user-password.png)

### 6. Time zone

![Time zone](images/10-timezone.png)

### 7. Partition the disk

For a standard install, choose **Guided - use entire disk**, select the disk,
then **All files in one partition**.

To encrypt the whole disk, choose **Guided - use entire disk and set up
encrypted LVM** instead. This is optional; you'll set a passphrase that is asked
for at every boot.

![Partitioning method](images/11-partition-method.png)
![Disk](images/12-disk.png)
![Scheme](images/13-scheme.png)
![Overview](images/14-overview.png)

Choose **Yes** to write the changes to disk. This erases the disk.

![Write changes](images/15-write-confirm.png)

### 8. Package manager

Answer **No** to scanning extra media. Choose a mirror country and
`deb.debian.org`. Leave the proxy empty unless your network needs one.

![Scan extra media](images/16-scan-media.png)
![Mirror country](images/17-mirror-country.png)
![Mirror](images/18-mirror.png)
![Proxy](images/19-proxy.png)

### 9. Popularity contest

Choose **No**.

![Popularity contest](images/20-popcon.png)

### 10. Software selection

> **Important:** select exactly these:
>
> - **Debian desktop environment**
> - **... GNOME**
> - **SSH server** (optional, for remote access)
> - **standard system utilities**
>
> Do not select any other desktop.

Use the **Space** bar to tick or untick a box, then click **Continue**.

![Software selection](images/21-software.png)
![Installing software](images/22-installing-software.png)

### 11. Finish

Remove the USB stick when asked and click **Continue** to reboot.

![Installation complete](images/23-complete.png)

---

## Part 2: First login to Debian

### 12. Log in

![Login screen](images/24-first-boot.png)
![Password](images/25-login-password.png)

### 13. Debian's welcome screens

Debian shows a short setup the first time. Click through it.

> **Important:** on the **Privacy** page, leave **Location Services off**.

This is the only time these screens appear: `install.sh` removes them for all
users created later.

![Welcome: language](images/26-welcome-language.png)
![Welcome: typing](images/27-welcome-typing.png)
![Welcome: privacy, Location Services off](images/28-welcome-privacy.png)
![Welcome: online accounts, skip](images/29-welcome-accounts.png)
![Welcome: done](images/30-welcome-done.png)
![Debian desktop](images/31-desktop.png)

---

## Part 3: Install EmComm Tools

### 14. Open a terminal

Click **Activities**, type `terminal` and open **Terminal**.

![Search for Terminal](images/32-search-terminal.png)

### 15. Download EmComm Tools

```bash
sudo apt update && sudo apt install -y git
```

```bash
git clone -b feature/debian-base https://github.com/mleo40/emcomm-tools-os-community.git
```

```bash
cd emcomm-tools-os-community/scripts
```

![Clone the repository](images/34-clone.png)

### 16. Run the installer

```bash
sudo ./install.sh
```

Enter your password when asked, then let it run. Run it exactly like this, in the desktop
terminal. Don't pipe it through `tee` or run it over SSH without a terminal: the map
menus below need an interactive terminal.

The installer stops three times to ask you something. Stay nearby.

**Map of your state (OSM).** Use the arrow keys to pick your state, then
press **Enter**. It's used for offline navigation.

![OSM state map](images/37-osm-map-picker.png)

**EmComm Tools map tiles.** Pick your country, then press **Enter**.

![ETC map country](images/39-et-maps-country.png)

**Optional encryption tools.** At the end, the installer asks whether to install
GNU Privacy Assistant, Paranoia File & Text Encryption, VeraCrypt, steghide, gpg
and the encryption guides. The default is **No**: press **Enter** to skip them,
or type `y` to install them.

![Encryption prompt](images/40-encryption-prompt.png)

You can install them later at any time:

```bash
sudo /opt/emcomm-tools/add-ons/crypto/scripts/install-crypto.sh
```

![Encryption tools declined](images/40b-encryption-declined.png)

### 17. Save the install log and reboot

The install log is in `/tmp`, which Debian clears at reboot. Keep a copy:

```bash
cp /tmp/et/et.log ~/et-install.log
```

```bash
sudo reboot
```

---

## Part 4: First login to EmComm Tools

### 18. EmComm Tools user configuration

After logging in, EmComm Tools asks for your callsign, grid square and
(optionally) your Winlink password. The status panel on the right and the
dock on the left are part of EmComm Tools.

![EmComm Tools user configuration](images/42-etc-first-login.png)

Open a terminal to see the EmComm Tools banner:

![EmComm Tools terminal](images/44-etc-terminal.png)

### 19. Check the install

From the top of the repository:

```bash
cd ~/emcomm-tools-os-community && ./post-install-check.sh
```

It checks packages, groups, PATH, the desktop, branding, services, the
encryption choice and the install log, then runs the ETC test suite. The report
is saved to `~/etc-post-install-report.txt`. Every line should be `PASS`.

Still to test by hand: radio CAT and audio with JS8Call and WSJT-X, VARA under
WINE, GPS and maps.

---

## Optional: Build an ISO

To make a bootable live ISO of the system you just installed:

```bash
cd ~/emcomm-tools-os-community/scripts && sudo ./build-iso.sh
```

- **Clean**: a shareable image with your accounts, home folder, Wi-Fi
  passwords, SSH keys and logs left out.
- **Personal**: a portable copy of your own system, including your data,
  optionally encrypted with a passphrase. Do not share it.

The ISO is written to `/home/eggs/`.
