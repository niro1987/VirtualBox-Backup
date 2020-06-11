@ECHO OFF
FOR %%C IN ("%~dp0.") DO SET "_VBBACKUP=%%~fC\VirtualBox Backup.bat"
:: Please read the full documentation on https://github.com/niro1987/VirtualBox-Backup#usage
:: 
:: [ -b | --backupdir ] { PATH }                        - Set to change Backup Folder. Default: .\ (Same folder as this file)
:: [ -s | --shutdown ]  [ acpipowerbutton | savestate ] - Set to change Shutdown Mode. Default: acpipowerbutton (Clean shutdown)
:: [ -c | --compress ]  [ 0 - 9 ]                       - Set to change Compression Mode. Default: 0 (No compression)
:: [ -k | --keep ]      [ 0 - ~ ]                       - Set to change Cleanup Mode. Default: 0 (All)
:: [ -p | --prefix ]    { PREFIX }                      - Set to change Name Prefix. Default: "" (No prefix)
:: [ -s | --suffix ]    { SUFFIX }                      - Set to change Name Suffix. Default: "" (No suffix)
:: [ --gfs ]                                            - Set to enable Grandfather-Father-Son rotation. Default: Disabled
:: [ -e | --exclude ]   { VM-Name }                     - Set to exclude a single VM from Backup. Default: "" (Backup all VMs)
:: [ -i | --include ]   { VM-Name }                     - Set to include only a single VM Backup. Default: "" (Backup all VMs)

:: Example - Modify according to your needs
"%_VBBACKUP%" --backupdir="" --shutdown=acpipowerbutton --compress=5 --keep=2 --prefix="GFS Rotation" --suffix="Monthly" --gfs