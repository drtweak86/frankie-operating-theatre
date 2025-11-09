# Frankie Operating Theatre 🛠️

One-shot rebuild script for my Raspberry Pi workstation (XFCE desktop, dev tools, Kodi/GBM, Argon ONE fan, QoL utilities).

## One-liner install

curl -fsSL https://raw.githubusercontent.com/Drtweak86/frankie-operating-theatre/main/pi-workstation.sh | bash

Or clone and run:

git clone https://github.com/Drtweak86/frankie-operating-theatre.git
cd frankie-operating-theatre
chmod +x pi-workstation.sh
./pi-workstation.sh

## Backup

curl -fsSL https://raw.githubusercontent.com/Drtweak86/frankie-operating-theatre/main/pi-backup.sh -o pi-backup.sh
chmod +x pi-backup.sh
./pi-backup.sh /mnt/hddroot/PI_BACKUP

## Restore

curl -fsSL https://raw.githubusercontent.com/Drtweak86/frankie-operating-theatre/main/pi-restore.sh -o pi-restore.sh
chmod +x pi-restore.sh
./pi-restore.sh /mnt/hddroot/PI_BACKUP/pi_home_backup_*.tgz


## Recovery/Dev Enhancements

curl -fsSL https://raw.githubusercontent.com/Drtweak86/frankie-operating-theatre/main/pi-dev-recovery.sh | bash
