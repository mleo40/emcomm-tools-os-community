# Installing EmComm Tools

EmComm Tools (ETC) comes as one ISO file: Debian 12 with EmComm Tools
installed. You can run it from a USB stick without installing anything (a
"live" system, which starts fresh each time), and install it to a computer's
disk when you're ready. No internet is needed to boot, install or run it.

You need:

- The ETC ISO file and its `.sha256` file.
- A USB stick of 16 GB or more.
- A 64-bit computer with 4 GB of RAM or more. For installing: 64 GB of disk
  or more. The installer erases the disk you choose.

## 1. Check the download

On Linux, in the folder with both files:

```bash
sha256sum -c emcomm-tools-os-community-<date>-amd64.hybrid.iso.sha256
```

It must print `OK`. On Windows: `certutil -hashfile <iso file> SHA256`, and
compare the result with the `.sha256` file.

## 2. Make a Ventoy USB stick

[Ventoy](https://www.ventoy.net) turns a USB stick into a boot menu for ISO
files: you copy the ISO onto the stick as a normal file, and the rest of the
stick is ordinary storage for your own files. ETC includes Ventoy 1.1.10 in
`/opt/ventoy`.

### Install Ventoy on the stick

This erases the USB stick.

- **Windows:** download Ventoy from ventoy.net, run `Ventoy2Disk.exe`, choose
  the stick and click **Install**.
- **Linux:** download Ventoy from ventoy.net (or use `/opt/ventoy` on an ETC
  system), find the stick's device name with `lsblk` (for example `/dev/sdb`),
  then:

  ```bash
  sudo /opt/ventoy/Ventoy2Disk.sh -i /dev/sdX
  ```

The stick now has a large partition named **Ventoy** (exFAT), which Windows,
macOS and Linux can all open.

### Copy ETC onto the stick

Copy the ISO file onto the **Ventoy** partition. You can rename it, for example
to `emcomm-tools.iso`.

### Secure Boot

Computers with Secure Boot on need Ventoy's one-time Secure Boot setup the
first time they boot the stick: see Ventoy's Secure Boot page on ventoy.net.
The ETC ISO itself supports Secure Boot.

## 3. Boot the stick

Plug in the stick, start the computer and open its boot menu (often **F12**,
**F11**, **F10** or **Esc** while it starts; it varies by maker). Choose the USB
stick.

Ventoy lists the ISO files on the stick. Choose the ETC ISO:

![Ventoy menu](install-guide/images/01-ventoy-menu.png)

Choose **Boot in normal mode**:

![Ventoy boot mode](install-guide/images/02-ventoy-boot-mode.png)

The ETC boot menu appears. Press **Enter** for **Live system**:

![ETC boot menu](install-guide/images/03-boot-menu.png)

![Boot splash](install-guide/images/04-splash.png)

## 4. The live system

ETC starts and opens **EmComm Tools User Configuration**. Enter your callsign,
grid square and (optionally) Winlink password and click **Save**, or **Cancel**
to do it later. If you save them here and then install, the installed system
keeps them:

![Live system, first start](install-guide/images/05-live-first-login.png)

You can use EmComm Tools from here without installing. To install it, double-
click **Install EmComm Tools** on the desktop:

![Live desktop](install-guide/images/06-live-desktop.png)

## 5. Install

The installer erases the disk you choose. Back up anything on it first.

**Welcome:** choose your language and click **Next**.

![Installer welcome](install-guide/images/07-welcome.png)

**Location:** choose your region and time zone.

![Location](install-guide/images/08-location.png)

**Keyboard:** choose your keyboard layout.

![Keyboard](install-guide/images/09-keyboard.png)

**Partitions:** choose the disk and **Erase disk**. To encrypt the whole disk,
tick **Encrypt system** and set a passphrase; it's asked for at every start.

![Partitions](install-guide/images/10-partitions.png)

**Users:** enter your name, login name, computer name and password.

![Users](install-guide/images/11-users.png)

**Optional software:** the encryption tools (GNU Privacy Assistant, Paranoia
File & Text Encryption, steghide and guides) are installed only
if you click **Install encryption tools** (it turns dark when selected).
Encryption laws differ by country: don't select them where possessing or using
them is illegal. To skip them, click **Skip encryption tools** or just
**Next**.

![Optional software](install-guide/images/12-optional-software.png)

**Summary:** check the plan and click **Install**.

![Summary](install-guide/images/13-summary.png)

The installation takes about 10 minutes.

![Installing](install-guide/images/14-installing.png)

When it's done, click **Done** to restart, and remove the USB stick when the
computer restarts.

![Finished](install-guide/images/15-finish.png)

## 6. First start

![Boot menu](install-guide/images/16-installed-boot-menu.png)

Log in. If you didn't save your callsign and grid square in the live system,
**EmComm Tools User Configuration** opens; enter them there:

![First login](install-guide/images/17-first-login.png)

## 7. After installing

Maps beyond the included world map, offline Wikipedia (`.zim`) files and the
xara modem aren't in the ISO. How to add them after install is still to be
decided; this guide will cover it once it is.
