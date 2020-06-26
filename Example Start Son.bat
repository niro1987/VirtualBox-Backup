@ECHO OFF
CLS
FOR %%C IN ("%~dp0.") DO (
    SET "_CURRENTDIR=%%~fC"
    SET "_VBBACKUP=%_CURRENTDIR%\VirtualBox Backup.bat"
)
:: Please read the full documentation on https://github.com/niro1987/VirtualBox-Backup#usage
:: 
:: [ --backupdir ]  { PATH }            - Sets the Backup Folder. Leave out for Snapshot Only
:: [ --backupmode ] [ acpipowerbutton ] - Sets the Backup Mode. Default: snapshot
::                  [ savestate ]         
:: .                [ snapshot ]          
:: [ --prefix ]     { STRING }          - Prefix your backup with a string. Default: No prefix
:: [ --suffix ]     { STRING }          - Append your backup with a string. Default: No suffix
:: [ --include ]    { VM-Name }         - Backup only a single VM. Default: Backup all VMs
:: [ --exclude ]    { VM-Name }         - Exclude a single VM from backup. Default: Does not exclude any
:: [ --compress ]   [ 0 - 9 ]           - Sets the Compression Mode. Default: -1 (Disabled)
:: [ --keep ]       [ 0 - ~ ]           - Keep this many backups, present included. Default: 0 (Keep all)
:: [ --stack ]                          - Do not delete snapshots. Uses a lot of drive space.

:: Example - Modify according to your needs
"%_VBBACKUP%" --backupdir "%_CURRENTDIR%" --backupmode snapshot --suffix "Daily Backup" --compress 1 --keep 3
