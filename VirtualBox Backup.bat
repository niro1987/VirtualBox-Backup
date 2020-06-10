:: 
:: Creates a backup of all VMs in Oracle VirtualBox
:: 

@ECHO OFF
CLS

:Initialize

	CALL :getDateTime
	FOR %%L IN ("%~dp0.") DO SET "_LOGFILE=%%~fL\log.txt"

	SET "_README="
	SET "_BACKUPDIR="
	SET "_SHUTDOWN="
	SET "_COMPRESS="
	SET "_KEEP="
	SET "_PREFIX="
	SET "_GFS="

	:ParseParameters
	CALL :getParamFlag "/?" "_README" "%~1" && SHIFT /1 && GOTO :ParseParameters
	IF DEFINED _README (
		ECHO:
		ECHO:
		CALL :DebugLog "VirtualBox Backup - Help"
		ECHO:
		CALL :DebugLog "[ -b | --backupdir ] { PATH }                        - Set to change Backup Folder. Default: .\ (Same folder as this file)"
		CALL :DebugLog "[ -s | --shutdown ]  [ acpipowerbutton | savestate ] - Set to change Shutdown Mode. Default: acpipowerbutton (Clean shutdown)"
		CALL :DebugLog "[ -c | --compress ]  [ 0 - 9 ]                       - Set to change Compression Mode. Default: 0 (No compression)"
		CALL :DebugLog "[ -k | --keep ]      [ 0 - ~ ]                       - Set to change Cleanup Mode. Default: 0 (All)"
		CALL :DebugLog "[ -p | --prefix ]    { PREFIX }                      - Set to change Name Prefix. Default: "" (No prefix)"
		CALL :DebugLog "[ -s | --suffix ]    { SUFFIX }                      - Set to change Name Suffix. Default: "" (No suffix)"
		CALL :DebugLog "[ --gfs ]                                            - Set to enable Grandfather-Father-Son rotation. Default: Disabled"
		ECHO: 
		CALL :DebugLog "Please read the full documentation on https://github.com/niro1987/VirtualBox-Backup#usage"
		ECHO:
		EXIT /B 0 
	)

	CALL :getParameter "-b" "_BACKUPDIR" "%~1" "%~2" && SHIFT /1 && SHIFT /1 && GOTO :ParseParameters
	CALL :getParameter "--backupdir" "_BACKUPDIR" "%~1" "%~2" && SHIFT /1 && SHIFT /1 && GOTO :ParseParameters

	CALL :getParameter "-s" "_SHUTDOWN" "%~1" "%~2" && SHIFT /1 && SHIFT /1 && GOTO :ParseParameters
	CALL :getParameter "--shutdown" "_SHUTDOWN" "%~1" "%~2" && SHIFT /1 && SHIFT /1 && GOTO :ParseParameters

	CALL :getParameter "-c" "_COMPRESS" "%~1" "%~2" && SHIFT /1 && SHIFT /1 && GOTO :ParseParameters
	CALL :getParameter "--compress" "_COMPRESS" "%~1" "%~2" && SHIFT /1 && SHIFT /1 && GOTO :ParseParameters

	CALL :getParameter "-k" "_KEEP" "%~1" "%~2" && SHIFT /1 && SHIFT /1 && GOTO :ParseParameters
	CALL :getParameter "--keep" "_KEEP" "%~1" "%~2" && SHIFT /1 && SHIFT /1 && GOTO :ParseParameters

	CALL :getParameter "-p" "_PREFIX" "%~1" "%~2" && SHIFT /1 && SHIFT /1 && GOTO :ParseParameters
	CALL :getParameter "--prefix" "_PREFIX" "%~1" "%~2" && SHIFT /1 && SHIFT /1 && GOTO :ParseParameters

	CALL :getParameter "-s" "_SUFFIX" "%~1" "%~2" && SHIFT /1 && SHIFT /1 && GOTO :ParseParameters
	CALL :getParameter "--suffix" "_SUFFIX" "%~1" "%~2" && SHIFT /1 && SHIFT /1 && GOTO :ParseParameters

	CALL :getParamFlag "--gfs" "_GFS" "%~1" && SHIFT /1 && GOTO :ParseParameters

	IF NOT DEFINED _BACKUPDIR (
		FOR %%i IN ("%~dp0.") DO SET "_BACKUPDIR=%%~fi"
	)
	IF NOT DEFINED _SHUTDOWN (
		SET _SHUTDOWN=acpipowerbutton
	)
	IF NOT DEFINED _COMPRESS (
		SET _COMPRESS=0
	)
	IF NOT DEFINED _KEEP (
		SET _KEEP=0
	)
	IF NOT DEFINED _PREFIX (
		SET "_PREFIX="
	)
	IF NOT DEFINED _GFS (
		SET "_GFS=FALSE"
	)

	SET "_VBOXMANAGE=C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"
	SET "_7za=C:\Program Files\7-Zip\7za.exe"
	SET "_DATE=%_DATETIME:~0,8%"
	SET _ERROR=0
	SET _WAITTIME=5

	CALL :DebugLog "Starting VirtualBox Backup..."
	"%_VBOXMANAGE%" list vms
	ECHO: 
	CALL :DebugLog "Parameters..."
	CALL :DebugLog "Backup Folder: %_BACKUPDIR%"
	CALL :DebugLog "Shutdown Mode: %_SHUTDOWN%"
	IF EXIST "%_7za%" (
		CALL :DebugLog "Compression Mode: %_COMPRESS%"
	) ELSE (
		CALL :DebugLog "Compression Mode: Disabled"
	)
	CALL :DebugLog "Cleanup Mode: %_KEEP%"
	CALL :DebugLog "Name Prefix: %_PREFIX%"
	CALL :DebugLog "Name Suffix: %_SUFFIX%"
	CALL :DebugLog "GrandFather-Father-Son: %_GFS%"
	ECHO:
	ECHO:

	IF DEFINED _PREFIX (
		SET "_PREFIX=%_PREFIX% "
	)
	IF DEFINED _SUFFIX (
		SET "_SUFFIX= %_SUFFIX%"
	)

	FOR /F "tokens=* delims=" %%V IN ('"%_VBOXMANAGE%" list vms') DO CALL :VM_Initialize %%V
	GOTO :Terminate

	:VM_Initialize
	:: Set Variables
		SET "_VMNAME=%~1"
		SET "_VMUUID=%~2"
		SET "_VMINITSTATE="
		SET _REQUESTOFF=0
		SET _LOOPCOUNT=12

		CALL :DebugLog "%_VMNAME%"
		:: Uncomment and modify the following line to skip a specific VM
		:: IF "%_VMNAME%"=="Home Assistant" EXIT /B 0

		:VM_GFS
		:: Check for an existing backup on the same date and skip the VM if exists
			IF "%_GFS%"=="TRUE" (
				CALL :DebugLog "Checking for existing backups..."
				FOR /F "eol=: delims=" %%F IN ('DIR /B "%_BACKUPDIR%\%_VMNAME%\*%_DATE%*"') DO (
					CALL :DebugLog "Found: %_VMNAME%\%%~F..."
					Exit /B 0
				)
			)

		:VM_PowerOff
		:: Shut down the VM (if it's running)
			CALL :GetState
			IF /I "%_VMSTATE%"=="running" (
				CALL :DebugLog "VM is %_VMSTATE%.."
				CALL :PowerOff
			)
			CALL :DebugLog "VM is %_VMSTATE%.."

		:VM_CopyFiles
		:: Copy the VM files
			CALL :GetPath
			CALL :DebugLog "Copy Files..."
			IF EXIST "%_7za%" (
				ROBOCOPY "%_VMPATH%." "%TEMP%\%_VMUUID%" /E
			) ELSE (
				ROBOCOPY "%_VMPATH%." "%_BACKUPDIR%\%_VMNAME%\%_PREFIX%%_DATE%%_SUFFIX%" /E
			)

		:VM_Start
		:: Start the VM (if it was running)
			IF /I "%_VMINITSTATE%"=="running" (
				CALL :DebugLog "Starting VM..."
				CALL :PowerOn
			)

		:VM_Compress
		:: Compress the VM Backup Files to a single compressed file
			IF EXIST "%_7za%" (
				CALL :DebugLog "Compress Files..."
				"%_7za%" a -mx%_COMPRESS% -sdel "%_BACKUPDIR%\%_VMNAME%\%_PREFIX%%_DATE%%_SUFFIX%.7z" "%TEMP%\%_VMUUID%\*"
				RD /S /Q "%TEMP%\%_VMUUID%"
			)

		:VM_Cleanup
		:: Delete old backups
		IF %_KEEP% GTR 0 (
			CALL :DebugLog "Cleanup of old backups..."
			FOR /F "skip=%_KEEP% eol=: delims=" %%F IN ('DIR /T:C /B /O:-D "%_BACKUPDIR%\%_VMNAME%\%_PREFIX%*%_SUFFIX%*"') DO (
				CALL :DebugLog "Delete %_VMNAME%\%%~F..."
				FOR %%Z IN ("%_BACKUPDIR%\%_VMNAME%\%%~F") DO (
					IF "%%~aZ" GEQ "d" (
						RD /S /Q "%_BACKUPDIR%\%_VMNAME%\%%~F"
					) ELSE (
						IF "%%~aZ" GEQ "-" (
							DEL "%_BACKUPDIR%\%_VMNAME%\%%~F"
						)
					)
				)
			)
		)

	:VM_Terminate
	:: That's all folks!
		ECHO:
		EXIT /B 0
		GOTO :EOF

:DebugLog
	FOR /F "tokens=* delims=" %%A IN ("%~1") DO (
		ECHO %%~A
        :: Uncomment (remove 'REM') the following line to enable debugging
		REM ECHO [%_DATETIME%] %%~A >> "%_LOGFILE%" 2>&1
    )
    EXIT /B 0

:Terminate
:: Check for errors and exit..
	IF %_ERROR% EQU 100 (
		SET _ERRORMSG="Timeout during Shutdown"
	)
	IF %_ERROR% GTR 0 (
		CALL :DebugLog  "ERROR: %_ERRORMSG%"
	)
	EXIT /B
	GOTO :EOF

:PowerOn
:: Takes the VM UUID from %_VMUUID% and start the VM in headless mode
	"%_VBOXMANAGE%" startvm %_VMUUID% --type headless
	EXIT /B 0
	GOTO :EOF

:PowerOff
:: Takes the VM UUID from %_VMUUID% and tries to shut it down
	CALL :GetState
	IF /I NOT "%_VMSTATE%"=="running" EXIT /B 0
	IF %_REQUESTOFF% EQU 0 (
		SET _REQUESTOFF=1
		CALL :DebugLog "VM Shutdown..."
		"%_VBOXMANAGE%" controlvm %_VMUUID% %_SHUTDOWN%
	)
	IF %_LOOPCOUNT% GTR 0 (
		CALL :DebugLog "Waiting for VM to shut down..."
		TIMEOUT /T %_WAITTIME% /nobreak > nul
		SET /A _LOOPCOUNT-=1
		CALL :PowerOff
	) ELSE (
		SET _ERROR=100
		GOTO :Terminate
	)
	GOTO :EOF

:GetState
:: Takes the VM UUID from %_VMUUID% and returns the state in %_VMSTATE%
:: The %_VMSTATE% variable changes during shutdown, %_VMINITSTATE% does not
	"%_VBOXMANAGE%" showvminfo %_VMUUID% --machinereadable > %TEMP%\%_VMUUID%.txt
	FOR /F "tokens=2 delims==" %%A IN ('FINDSTR /I /B "VMState=" "%TEMP%\%_VMUUID%.txt"') DO (
		SET "_VMSTATE=%%~A"
	)
	IF "%_VMINITSTATE%"=="" (
		SET "_VMINITSTATE=%_VMSTATE%"
	)
	IF EXIST "%TEMP%\%_VMUUID%.txt" (
		DEL "%TEMP%\%_VMUUID%.txt"
	)
	EXIT /B 0
	GOTO :EOF

:GetPath
:: Takes the VM UUID from %_VMUUID% and returns the folder path in %_VMPATH%
	"%_VBOXMANAGE%" showvminfo %_VMUUID% --machinereadable > %TEMP%\%_VMUUID%.txt
	FOR /F "tokens=* delims=" %%A IN ('FINDSTR /I /B "CfgFile=" "%TEMP%\%_VMUUID%.txt"') DO (
		FOR %%B IN (%%~A) DO (
			SET "_VMPATH=%%~dpB"
		)
	)
	IF EXIST "%TEMP%\%_VMUUID%.txt" (
		DEL "%TEMP%\%_VMUUID%.txt"
	)
	EXIT /B 0
	GOTO :EOF

:getParameter
:: Thanks to https://stackoverflow.com/a/47169024
:: 1 CLI Parameter Name
:: 2 Parameter Name
:: 3 Active Parameter Name
:: 4 Active Parameter Value
	IF "%~3"=="%~1" (
		IF "%~4"=="" (
			SET "%~2="
			EXIT /B 1
		)
		SET "%~2=%~4"
		EXIT /B 0
	)
	EXIT /B 1
	GOTO :EOF

:getParamFlag
:: Thanks to https://stackoverflow.com/a/47169024
:: 1 CLI Parameter Name
:: 2 Parameter Name
:: 3 Active Parameter Name
	IF "%~3"=="%~1" (
		SET "%~2=TRUE"
	EXIT /B 0
	)
	EXIT /B 1
	GOTO :EOF

:getDateTime
:: https://ss64.com/nt/syntax-getdate.html
:: Returns the current date in YYYYMMDDHHMM format in _DATETIME
	ECHO Dim dt > "%TEMP%\getdatetime.vbs"
	ECHO dt=now >> "%TEMP%\getdatetime.vbs"
	ECHO wscript.echo ((year(dt)*100 + month(dt))*100 + day(dt))*10000 + hour(dt)*100 + minute(dt) >> "%TEMP%\getdatetime.vbs"
	FOR /F %%D IN ('cscript /nologo "%TEMP%\getdatetime.vbs"') DO SET _DATETIME=%%D
	DEL /Q "%TEMP%\getdatetime.vbs"