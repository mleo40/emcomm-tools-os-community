# Installing Windows Applications

The following instructions only need to be run once. They should be run
in this directory as your normal user (do not use 'sudo').

1. Install the WINE dependencies.

    ./01-install-wine-deps.sh

2. Install VARA HF. Accept the default settings and uncheck Launch My Program
   when prompted during the installation.

    ./02-install-vara-hf.sh

3. Install VARA FM. Accept the default settings and uncheck Launch My Program
   when prompted during the installation.

    ./03-install-vara-fm.sh

4. Run the registry editor. Follow the instructions in the terminal. In 
   this step we will need to map COM port 10 (COM10) to the EmComm Tools
   CAT control device (/dev/et-cat).

    ./04-run-regedit.sh

5. If you want to restore your WINE installation on another ETC system (or
   after reinstalling), run the following to make a backup of your WINE
   installation now.

    ./05-backup-wine-install.sh

It is important that you do not run any of the VARA programs until after
the backup is run in step 5.

## Restoring VARA on another ETC system

ETC ISOs don't include a WINE installation. To restore the backup made in
step 5 on another ETC system (or after reinstalling):

1. Copy the backup file (`etc-wine-backup-HOST-YYYYMMDD.tar.gz`) to the system,
   for example from a USB stick.

2. Unpack it in your home folder. This creates `~/.wine32`.

```
cd ~ && tar -xzf /path/to/etc-wine-backup-*.tar.gz
```

The backup can include your VARA registration, so don't add it to an ISO you
share with others.
