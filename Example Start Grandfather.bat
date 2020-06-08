@ECHO OFF
FOR %%C IN ("%~dp0.") DO SET "_VBBACKUP=%%~fC\VirtualBox Backup.bat"
:: Please read the full documentation on https://github.com/niro1987/VirtualBox-Backup#usage
:: 
:: [ -b | --backupdir ] { PATH }                        - Set to change Backup Folder. Default: .\ (Same folder as this file)
:: [ -s | --shutdown ]  [ acpipowerbutton | savestate ] - Set to change Shutdown Mode. Default: acpipowerbutton (Clean shutdown)
:: [ -c | --compress ]  [ 0 - 9 ]                       - Set to change Compression Mode. Default: 0 (No compression)
:: [ -k | --keep ]      [ 0 - ~ ]                       - Set to change Cleanup Mode. Default: 0 (All)
:: [ -p | --prefix ]    { PREFIX }                      - Set to change Name Prefix. Default: "" (No prefix)
:: [ --gfs ]                                            - Set to enable Grandfather-Father-Son rotation. Default: Disabled

:: Example - Modify according to your needs
"%_VBBACKUP%" --backupdir="" --shutdown=acpipowerbutton --compress=5 --keep=2 --prefix="Grandfather" --gfs