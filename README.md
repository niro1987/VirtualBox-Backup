# VirtualBox Backup
An automated backup for Oracle VirtualBox VMs in Windows

- [VirtualBox Backup](#virtualbox-backup)
- [Installation](#installation)
- [Usage](#usage)
  - [Backup Dir](#backup-dir)
    - [Snapshot Only](#snapshot-only)
  - [Backup Mode](#backup-mode)
  - [Prefix/Suffix](#prefixsuffix)
  - [Include/Exclude](#includeexclude)
  - [Compress](#compress)
  - [Keep](#keep)
  - [Stack](#stack)
- [Advanced Usage](#advanced-usage)
  - [Grandfather-Father-Son Rotation](#grandfather-father-son-rotation)

# Installation
1. Clone or copy this repository to the desired location.
2. Edit and rename *(optional)* **Example Start.bat** according to your needs. See below [Usage](#Usage)
3. Create a basic task to periodically start **Example Start.bat** *(or whatever you named it)* with [Task Scheduler](https://www.google.com/search?q=Windows+Task+Scheduler&oq=Windows+Task+Scheduler).

I've tried passing the arguments directly to *VirtualBox Backup.bat* in Task Scheduler but the task didn't start correctly. Using *Example Start.bat* as the placeholder makes editing the parameters a bit more *'user friendly'* and easier to duplicate.

# Usage
If you do not pass a parameter it will revert to it's default behavior as documented below.

## Backup Dir
```
[ --backupdir ] { PATH }
```
Pass this parameter along with a valid path  to set the target folder. A subfolder is automatically created for each VM. Your can use Windows default variables like `%USERPROFILE%` and `%ONEDRIVE%`. The custom variable `%_CURRENTDIR%` will set the target folder to where you save the `.bat` files.

### Snapshot Only
Leaving the `backupdir` parameter out will create a snapshot of the VM without copying any files. This setting automatically sets [Backup Mode](#backup-mode) to `snapshot` and enables [Stack](#stack). [Keep](#keep) is currently not supported in combination with this setting. [Compress](#compress) does not apply and is ignored.

| Parameter | Description |
| --------- | ----------- |
| `--backupdir "%_CURRENTDIR%"` | Parent folder, see above description. |
| `--backupdir "%USERPROFILE%"` | C:\Users\YourUsername |
| `--backupdir "C:\Backup"` | C:\Backup |

## Backup Mode
```
[ --backupmode ]  [ acpipowerbutton | savestate | snapshot ]
```
In order to succesfully create a backup, the VM needs to be in a stable (not changing) state. To reduce downtime, a snapshot is created and the VM is restarted (if it was running in the first place). 

To restore a backup you simply copy/extract the files to your desired location, add (add, not new) VM to OracleBox and restore the latest snapshot. Be aware that you will not be able to restore a backup while the original VM still exists in the same instance of VirtualBox because the drives will have identical UUID's.

| Parameter | Description |
| --------- | ----------- |
| `--backupmode acpipowerbutton` | The VM is completely shut down and boots normally after the snapshot is created. Not ideal if login is required after boot. Booting a restored backup is like normal booting the VM. |
| `--backupmode savestate` | The VM's state is frozen and saved, VM resumes normally after the snapshot is created. Not all operating systems can handle this *gap* in time. Booting a restored backup is like unfreezing time, the same *gap* applies. You might need to restart your VM to fix any time gap issues. |
| `--backupmode snapshot` | The VM is saved in a live snapshot without any downtime. Booting a restored backup is as if the VM experienced a power failure. It the best suboptimal solution to prevent downtime. |

## Prefix/Suffix
```
[ --prefix ] { PREFIX }
[ --suffix ] { SUFFIX }
```
Each backup is saved to a subfolder inside the [target folder](#backup-dir) named after the VM. The backup is named `[prefix ]YYYY.MM.DD-HH24.MM[ suffix]`. Pass one or both parameters to append an additional string to the backup name.

| Parameter | Description |
| --------- | ----------- |
| `--prefix "Automated Backup"` | Prefix the backup name with `"Automated Backup"` |
| `--suffix="Daily"` | Suffix (append) the backup name with `"Daily"` |

## Include/Exclude
```
[ --include ] { VM-Name }
[ --exclude ] { VM-Name }
```
Set one of the above parameters to exclude or explicitly include a single VM from backup. Does not accept wildcards and is case sensitive.

Explicitly *excluding* a single VM will still run backups for all other VMs. Explicitly *including* a single VM will exclude all other VMs.

| Parameter | Description |
| --------- | ----------- |
| `--include "Remi"` | Will include only the VM named `Remi` from the backup rotation and ignores the rest. |
| `--exclude "Not Me"` | Will exclude only the VM named `Not Me` from the backup rotation but does backup the rest. |

## Compress
```
[ --compress ]  [ -1 - 9 ]
```
***!!!*** In order to enable data compression you need to install [7-Zip](https://www.7-zip.org/) to the default path `C:\Program Files\7-Zip\7z.exe`. To disable compression, leave this parameter out or explicitly set it to `-1`.

The VM Backup Files can be compressed to a single 7-Zip file to save some diskspace and to make them easier to move around.

| Parameter | Description |
| --------- | ----------- |
| `--compress -1` | *(default)* Disable compression. |
| `--compress 0` | No compression rate. While this does not actually reduce filesize, it does reduce the backup to a single file. |
| `--compress [1 - 9]` | Set compression level: 1 (fastest) ... 9 (ultra). |

## Keep
```
[ --keep ] [ 0 - ~ ]
```
Delete old backups with the same prefix and/or suffix and retaines the last `[x]`. If no [Prefix and/or Suffix](#prefixsuffix) is set, all files and folders in the VM's backup subfolder are validated and possibly removed.

| Parameter | Description |
| --------- | ----------- |
| `--keep 0` | *(default)* No cleanup. Keep all backups. |
| `--keep [x]` | Retain the `[x]` latest created backups. |

## Stack
```
[ --stack ]
```
A snapshot is always created before the files are copied. This uses some disk space because VirtualBox saves the new state on top of the latest snapshot. To save disk space, the snapshot is deleted after the backup is created (unless you're using [Snapshot Only](#snapshot-only)). Add this flag to retaun the snapshots, stacking each snapshot on top of the previous one (uses a lot of disk space).

| Parameter | Description |
| --------- | ----------- |
| `--stack` | Retain all snapshots. |

# Advanced Usage

## Grandfather-Father-Son Rotation

[Wikipedia](https://en.wikipedia.org/wiki/Backup_rotation_scheme)

You will need to create and schedule multiple **Example Start.bat** files, one for each generation. Make sure you use a different prefix, suffix or even target folder for each generation to prevent unintended deletion of backups.

| Rotation | Parameters | Description |
| -------- | ---------- | ----------- |
| `Daily Son.bat` | `--keep=2` | Scheduled to run at `02:00` daily. |
| `Weekly Father.bat` | `--keep=4` | Scheduled to run at `02:15` on every Monday of every week. |
| `Monthly Grandfather.bat` | `--keep=3` | Scheduled to run at `02:30` on the first Monday of every month. |

By the end of June 2020 it would look like this.

| *Day*       | 1-4 | 1-5 | 1-6 | 8-6 | 15-6 | 22-6 | 28-6 | 29-6 | 30-6 |
| ----------- | -   | -   | -   | -   | -    | -    | -    | -    | -    |
| Son         | -   | -   | -   | -   | -    | -    | X    | -    | X    |
| Father      | -   | -   | -   | X   | X    | X    | -    | X    | -    |
| Grandfather | X   | X   | X   | -   | -    | -    | -    | -    | -    |
