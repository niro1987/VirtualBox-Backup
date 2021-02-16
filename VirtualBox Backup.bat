:: 
:: Creates a backup of all VMs in Oracle VirtualBox
:: 

@ECHO OFF
CLS

:Initialize

	CALL :DebugLog "Starting VirtualBox Backup..."
	FOR %%L IN ("%~dp0.") DO SET "_LOGFILE=%%~fL\log.txt"

	SET "_VBOXMANAGE=C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"
	SET "_7z=C:\Program Files\7-Zip\7z.exe"
	SET "_DATE=%_DATETIME:~0,4%.%_DATETIME:~4,2%.%_DATETIME:~6,2%"
	SET "_TIME=%_DATETIME:~8,2%.%_DATETIME:~10,2%"
	SET "_ERROR=0"
	SET "_README="
	SET "_BACKUPDIR="
	SET "_BACKUPMODE="
	SET "_PREFIX="
	SET "_SUFFIX="
	SET "_INCLUDE="
	SET "_EXCLUDE="
	SET "_COMPRESS="
	SET "_COMPRESSENABLED="
	SET "_KEEP="
	SET "_STACK="
	
	:ParseParameters
	CALL :getParamFlag "/?" "_README" "%~1" && SHIFT /1 && GOTO :ParseParameters
	IF DEFINED _README GOTO :ReadMe
	CALL :getParameter "--backupdir" "_BACKUPDIR" "%~1" "%~2" && SHIFT /1 && SHIFT /1 && GOTO :ParseParameters
	CALL :getParameter "--backupmode" "_BACKUPMODE" "%~1" "%~2" && SHIFT /1 && SHIFT /1 && GOTO :ParseParameters
	CALL :getParameter "--prefix" "_PREFIX" "%~1" "%~2" && SHIFT /1 && SHIFT /1 && GOTO :ParseParameters
	CALL :getParameter "--suffix" "_SUFFIX" "%~1" "%~2" && SHIFT /1 && SHIFT /1 && GOTO :ParseParameters
	CALL :getParameter "--include" "_INCLUDE" "%~1" "%~2" && SHIFT /1 && SHIFT /1 && GOTO :ParseParameters
	CALL :getParameter "--exclude" "_EXCLUDE" "%~1" "%~2" && SHIFT /1 && SHIFT /1 && GOTO :ParseParameters
	CALL :getParameter "--compress" "_COMPRESS" "%~1" "%~2" && SHIFT /1 && SHIFT /1 && GOTO :ParseParameters
	CALL :getParameter "--keep" "_KEEP" "%~1" "%~2" && SHIFT /1 && SHIFT /1 && GOTO :ParseParameters
	CALL :getParamFlag "--stack" "_STACK" "%~1" && SHIFT /1 && GOTO :ParseParameters

	IF NOT DEFINED _BACKUPDIR (
		SET "_BACKUPDIR=false"
		SET "_BACKUPMODE=snapshot"
		SET _COMPRESS=-1
		SET _KEEP=0
		SET "_STACK=TRUE"
	)
	IF NOT DEFINED _BACKUPMODE (
		SET "_BACKUPMODE=snapshot"
	)
	IF NOT DEFINED _COMPRESS (
		SET _COMPRESS=-1
	)
	IF NOT DEFINED _KEEP (
		SET _KEEP=0
	)

	IF %_COMPRESS% GEQ 0 (
		IF %_COMPRESS% LEQ 9 (
			IF EXIST "%_7z%" (
				SET "_COMPRESSENABLED=TRUE"
			)
		)
	)

	"%_VBOXMANAGE%" list vms
	ECHO: 
	CALL :DebugLog "Parameters..."
	IF /I NOT "%_BACKUPDIR%"=="false" (
		CALL :DebugLog "Backup Folder: %_BACKUPDIR%"
	) ELSE (
		CALL :DebugLog "Backup Folder: Snapshot Only"
	)
	CALL :DebugLog "Backup Mode: %_BACKUPMODE%"
	IF DEFINED _PREFIX (
		CALL :DebugLog "Prefix: %_PREFIX%"
	)
	IF DEFINED _SUFFIX (
		CALL :DebugLog "Suffix: %_SUFFIX%"
	)
	IF DEFINED _INCLUDE (
		CALL :DebugLog "Include: %_INCLUDE%"
	)
	IF DEFINED _EXCLUDE (
		CALL :DebugLog "Exclude: %_EXCLUDE%"
	)
	IF DEFINED _COMPRESSENABLED (
		CALL :DebugLog "Compress: %_COMPRESS%"
	) ELSE (
		CALL :DebugLog "Compress: Disabled"
	)
	IF %_KEEP% GTR 0 (
		CALL :DebugLog "Keep: %_KEEP%"
	) ELSE (
		CALL :DebugLog "Keep: All"
	)
	IF DEFINED _STACK (
		CALL :DebugLog "Stack: True"
	) ELSE (
		CALL :DebugLog "Stack: False"
	)
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

		SET _REQUESTOFF=0
		SET _LOOPCOUNT=12
		SET _WAITTIME=5
		SET "_VMINITSTATE="

		CALL :GetInfo

		ECHO:
		CALL :DebugLog "%_VM_NAME%"

		SET "_VMBACKUPNAME=%_PREFIX%%_DATE%-%_TIME%%_SUFFIX%"

	:VM_Include
	:: Check if the VM is explicitly included and skip everything else
		IF DEFINED _INCLUDE (
			IF NOT "%_VM_NAME%"=="%_INCLUDE%" (
				CALL :DebugLog "VM is excluded, skipping..."
				EXIT /B 0
			)
		)

	:VM_Exclude
	:: Check if the VM in excluded from Backup and skip
		IF DEFINED _EXCLUDE (
			IF "%_VM_NAME%"=="%_EXCLUDE%" (
				CALL :DebugLog "VM is excluded, skipping..."
				EXIT /B 0
			)
		)

	:VM_Shutdown
	:: Shutdown VM
		CALL :DebugLog "VM state: %_VM_VMSTATE%"
		SET "_VMINITSTATE=%_VM_VMSTATE%"
		IF /I "%_BACKUPMODE%"=="acpipowerbutton" (
			IF /I "%_VM_VMSTATE%"=="running" (
				Call :DebugLog "ACPI Shutdown..."
				CALL :Shutdown
			)
		)
		IF /I "%_BACKUPMODE%"=="savestate" (
			IF /I "%_VM_VMSTATE%"=="running" (
				Call :DebugLog "Savestate..."
				CALL :Shutdown
			)
		)

	:VM_Create_Snapshot
	:: Create a snapshot
		CALL :DebugLog "Creating Snapshot..."
		"%_VBOXMANAGE%" ^
			snapshot %_VM_UUID% ^
			take "%_VMBACKUPNAME%" ^
			--live

	:VM_Start
	:: Start the VM (if it was running)
		CALL :GetInfo
		IF /I NOT "%_VM_VMSTATE%"=="running" (
			IF /I "%_VMINITSTATE%"=="running" (
				CALL :DebugLog "Starting VM..."
				"%_VBOXMANAGE%" ^
					startvm %_VM_UUID% ^
					--type headless
			)
		)

	:VM_Copy
	:: Copy the VM to TEMP
		CALL :GetVMPath
		IF /I NOT "%_BACKUPDIR%"=="false" (
			CALL :DebugLog "Copy..."
			ROBOCOPY "%_VMPATH%." "%TEMP%\%_VM_UUID%" /E
		)

	:VM_Delete_Snapshot
	:: Delete snapshot 
		IF NOT DEFINED _STACK (
			CALL :DebugLog "Deleting Snapshot..."
			"%_VBOXMANAGE%" ^
				snapshot %_VM_UUID% ^
				delete "%_VMBACKUPNAME%"
		)

	:VM_Compress
	:: Compress
		IF DEFINED _COMPRESSENABLED (
			CALL :DebugLog "Compressing..."
			"%_7z%" a -mx%_COMPRESS% -sdel "%_BACKUPDIR%\%_VM_Name%\%_VMBACKUPNAME%.7z" "%TEMP%\%_VM_UUID%\*"
		) ELSE (
			IF /I NOT "%_BACKUPDIR%"=="false" (
				CALL :DebugLog "Moving..."
				ROBOCOPY "%TEMP%\%_VM_UUID%" "%_BACKUPDIR%\%_VM_Name%\%_VMBACKUPNAME%" /E /MOVE
			)
		)
		REM RD /S /Q "%TEMP%\%_VM_UUID%" > nul

	:VM_Cleanup
	:: Delete old backups
		IF %_KEEP% GTR 0 (
			CALL :DebugLog "Cleanup..."
			FOR /F "skip=%_KEEP% eol=: delims=" %%F IN ('DIR /T:C /B /O:-D "%_BACKUPDIR%\%_VM_Name%\%_PREFIX%*%_SUFFIX%*"') DO (
				CALL :DebugLog "Delete %%~F..."
				FOR %%Z IN ("%_BACKUPDIR%\%_VM_Name%\%%~F") DO (
					IF "%%~aZ" GEQ "d" (
						RD /S /Q "%_BACKUPDIR%\%_VM_Name%\%%~F"
					) ELSE (
						IF "%%~aZ" GEQ "-" (
							DEL "%_BACKUPDIR%\%_VM_Name%\%%~F"
						)
					)
				)
			)
		)

	:VM_Terminate
	:: That's all folks!
		ECHO:
		CALL :DebugLog "%_VM_NAME% done!"
		EXIT /B 0
		GOTO :EOF

:Terminate
:: Check for errors and exit..
	IF %_ERROR% EQU 100 (
		SET _ERRORMSG="Timeout"
	)
	IF %_ERROR% GTR 0 (
		CALL :DebugLog  "ERROR: %_ERRORMSG%"
	)
	EXIT /B
	GOTO :EOF

:DebugLog
	CALL :getDateTime
	FOR /F "tokens=* delims=" %%A IN ("%~1") DO (
		ECHO %%~A
        :: Uncomment (remove 'REM') the following line to enable debugging
		REM ECHO [%_DATETIME%] %%~A >> "%_LOGFILE%" 2>&1
    )
    EXIT /B 0

:getDateTime
:: https://ss64.com/nt/syntax-getdate.html
:: Returns the current date in YYYYMMDDHHMM format in _DATETIME
	ECHO Dim dt > "%TEMP%\getdatetime.vbs"
	ECHO dt=now >> "%TEMP%\getdatetime.vbs"
	ECHO wscript.echo ((year(dt)*100 + month(dt))*100 + day(dt))*10000 + hour(dt)*100 + minute(dt) >> "%TEMP%\getdatetime.vbs"
	FOR /F %%D IN ('cscript /nologo "%TEMP%\getdatetime.vbs"') DO SET _DATETIME=%%D
	DEL /Q "%TEMP%\getdatetime.vbs"
	EXIT /B 0

:GetInfo
:: Takes the VM UUID from %_VMUUID% and return the VM properties in separate variables
	SET "_VARPREFIX=_VM_"
	IF DEFINED _VM_UUID (
		FOR /F "tokens=* delims==" %%A IN ('SET %_VARPREFIX%') DO CALL :ResetVar %%A
	)
	"%_VBOXMANAGE%" showvminfo %_VMUUID% --machinereadable > "%TEMP%\%_VMUUID%.txt"
	FOR /F "tokens=* delims==" %%A IN (%TEMP%\%_VMUUID%.txt) DO CALL :ParseVar %%A
	REM DEL "%TEMP%\%_VMUUID%.txt"
	EXIT /B 0

:GetVMPath
:: Extract the VM base path and save it in _VMPATH
	FOR /F "tokens=* delims=" %%A IN ("%_VM_CfgFile%") DO (
		SET "_VMPATH=%%~dpA"
	)
	EXIT /B 0

:ParseVar
	SET "%_VARPREFIX%%~1=%~2"
	EXIT /B 0

:ResetVar
	SET "%1="
	EXIT /B 0

:Shutdown
	IF /I NOT "%_VM_VMSTATE%"=="running" EXIT /B 0
	IF %_REQUESTOFF% EQU 0 (
		SET _REQUESTOFF=1
		"%_VBOXMANAGE%" controlvm %_VM_UUID% %_BACKUPMODE%
	)
	IF %_LOOPCOUNT% GTR 0 (
		CALL :DebugLog "Waiting for shut down..."
		TIMEOUT /T %_WAITTIME% /nobreak > nul
		SET /A _LOOPCOUNT-=1
		CALL :GetInfo
		CALL :Shutdown
	) ELSE (
		SET _ERROR=100
		GOTO :Terminate
	)
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

:ReadMe
	ECHO:
	ECHO:
	CALL :DebugLog "VirtualBox Backup - Help"
	ECHO:
	CALL :DebugLog "[ --backupdir ]  { PATH }            - Sets the Backup Folder. Leave out for Snapshot Only"
	CALL :DebugLog "[ --backupmode ] [ acpipowerbutton ] - Sets the Backup Mode. Default: snapshot"
	CALL :DebugLog "                 [ savestate ]         "
	CALL :DebugLog ".                [ snapshot ]          "
	CALL :DebugLog "[ --prefix ]     { STRING }          - Prefix your backup with a string. Default: No prefix"
	CALL :DebugLog "[ --suffix ]     { STRING }          - Append your backup with a string. Default: No suffix"
	CALL :DebugLog "[ --include ]    { VM-Name }         - Backup only a single VM. Default: Backup all VMs"
	CALL :DebugLog "[ --exclude ]    { VM-Name }         - Exclude a single VM from backup. Default: Does not exclude any"
	CALL :DebugLog "[ --compress ]   [ 0 - 9 ]           - Sets the Compression Mode. Default: -1 (Disabled)"
	CALL :DebugLog "[ --keep ]       [ 0 - ~ ]           - Keep this many backups, present included. Default: 0 (Keep all)"
	CALL :DebugLog "[ --stack ]                          - Do not delete snapshots. Uses a lot of drive space.
	
	ECHO:
	CALL :DebugLog "Please read the full documentation on https://github.com/niro1987/VirtualBox-Backup#usage"
	ECHO:
	ECHO:

	GOTO :Terminate
