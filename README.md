# VirtualBox Backup
An automated backup for Oracle VirtualBox VMs in Windows

- [VirtualBox Backup](#virtualbox-backup)
- [Installation](#installation)
- [Usage](#usage)
  - [Backup Folder](#backup-folder)
  - [Shutdown Mode](#shutdown-mode)
  - [Compression Mode](#compression-mode)
  - [Cleanup Mode](#cleanup-mode)
  - [Name Prefix/Suffix](#name-prefixsuffix)
  - [Grandfather-Father-Son Rotation](#grandfather-father-son-rotation)
  - [Exclude/Include](#excludeinclude)

# Installation
1. Clone or copy this repository to the desired location.
2. Edit and rename *(optional)* **Example Start.bat** according to your needs. See below [Usage](#Usage)
3. Create a basic task to periodically start **Example Start.bat** *(or whatever you named it)* with [Task Scheduler](https://www.google.com/search?q=Windows+Task+Scheduler&oq=Windows+Task+Scheduler).

I've tried passing the arguments directly to *VirtualBox Backup.bat* in Task Scheduler but the task didn't start correctly. Has to do with the usage of quotes and spaces between them. Using *Example Start.bat* as the placeholder makes editing the parameters a bit more *'user friendly'*.

# Usage
All paramters are optional. If you do not pass a parameter, it will revert to it's default behavior as documented below.

## Backup Folder
```
[ -b | --backupdir ] { PATH }
```
By default the VM Backup's are saved to the folder where you saved the repository (the same folder as **VirtualBox Backup.bat** to be exact). To change the default, pass the above parameter along with a valid path. A subfolder is created if it does not already exist with the same name as the VM.

| Parameter | Description |
| --------- | ----------- |
| `--backupdir=""` | *(default)* Parent folder |
| `--backupdir="%USERPROFILE%"` | C:\Users\UserName |
| `--backupdir="C:\Backup"` | C:\Backup |

## Shutdown Mode
```
[ -s | --shutdown ]  [ acpipowerbutton | savestate ]
```
The VM needs to be shut down to copy the required files. Pass the above parameter to change the shutdown mode. The VM is restarted when the backup has been made (if it was running).

| Parameter | Description |
| --------- | ----------- |
| `--shutdown=acpipowerbutton` | *(default)* Use The VM is shut down using the ACPI mode. This is the same as short pressing the powerbutton on your PC, shuts it down clean. |
| `--shutdown=savestate` | The VM's state is saved and powered down. This does not actually shut down the VM, it's more like stopping time. Not all VM's (OS's) can handle the *gap* in time. | 

## Compression Mode
```
[ -c | --compress ]  [ 0 - 9 ]
```
***!!!*** In order to enable data compression you need to install [7-Zip](https://www.7-zip.org/) and [7-Zip Extra](https://www.7-zip.org/).

The VM Backup Files can be compressed to a single file to save some diskspace and/or to make the backups easier to handle.

| Parameter | Description |
| --------- | ----------- |
| `--compress=-1` | Disables compression. |
| `--compress=0` | *(default)* No compression. While this does not actually compress the files, it does make them easier to handle because the backup is reduced to a single file. |
| `--compress=[1 - 9]` | Set compression level: 1 (fastest) ... 9 (ultra). |

## Cleanup Mode
```
[ -k | --keep ] [ 0 - ~ ]
```
Delete old VM Backup files (or folders) and keeps the last `[x]` files. If no [Prefix](#name-prefix) is set, all files and folders in the VM's backup subfolder are validated and possibly removed.

| Parameter | Description |
| --------- | ----------- |
| `--keep=0` | *(default)* No cleanup. Keep all files. |
| `--keep=[x]` | Keep the `[x]` last created files/folder. |

## Name Prefix/Suffix
```
[ -p | --prefix ] { PREFIX }
[ -s | --suffix ] { SUFFIX }
```
Each backup is saved to a folder named after the VM. The backup file/folder is named after the date the backup was created on (exact string depends on regional settings). Pass the above parameter to prefix and/or suffix (append) an additional string to the backup name, an additional space `" "` is automatically added.

| Parameter | Description |
| --------- | ----------- |
| `--prefix=""` | *(default)* No prefix. |
| `--prefix="Daily"` | Prefix the backup name with `"Daily"` |
| `--suffix=""` | *(default)* No suffix. |
| `--suffix="Weekly"` | Suffix (append) the backup name with `"Weekly"` |

## Grandfather-Father-Son Rotation
```
[ --gfs ]
```
Add this parameter to enabled [Grandfather-Father-Son](https://en.wikipedia.org/wiki/Backup_rotation_scheme) rotation. This mode checks if another backup exists with the same date (can have any prefix) and skips the VM accordingly.

You will need to create and schedule the **Example Start [Grandfather | Father | Son].bat** files, one for each generation. An *older* generation should be scheduled to run before a *younger* generation.

Assuming a single VM does not take more than 15 minutes to backup you could schedule the rotation as follows.

| Rotation | Parameters | Description |
| -------- | ---------- | ----------- |
| `Monthly Grandfather.bat` | `--keep=3` | Scheduled to run at `02:00` on the first Monday of every month. |
| `Weekly Father.bat` | `--keep=4` | Scheduled to run at `02:15` on every Monday of every week. |
| `Daily Son.bat` | `--keep=2` | Scheduled to run at `02:30` daily. |

By the end of June 2020 it would look like this.

| *Day*       | 1-4 | 1-5 | 1-6 | 8-6 | 15-6 | 22-6 | 28-6 | 29-6 | 30-6 |
| ----------- | -   | -   | -   | -   | -    | -    | -    | -    | -    |
| Grandfather | X   | X   | X   | -   | -    | -    | -    | -    | -    |
| Father      | -   | -   | -   | X   | X    | X    | -    | X    | -    |
| Son         | -   | -   | -   | -   | -    | -    | X    | -    | X    |

## Exclude/Include
```
[ -e | --exclude ] { VM-Name }
[ -i | --include ] { VM-Name }
```
Set one of the above parameters to exclude or explicitly include a single VM in the Backup rotation. Does not accept wildcards, is case sensitive.

Explicitly **excluding** a single VM will still run backups for all other VMs. Explicitly **including** a single VM will *exclude* all other VMs.

| Parameter | Description |
| --------- | ----------- |
| `--exclude=""` | *(default)* Backup all VMs. |
| `--exclude="Not Me"` | Will exclude only the VM named `Not Me` from the backup rotation but does backup the rest. |
| `--include=""` | *(default)* Backup all VMs. |
| `--include="Remi"` | Will include only the VM named `Remi` from the backup rotation and ignores the rest. |