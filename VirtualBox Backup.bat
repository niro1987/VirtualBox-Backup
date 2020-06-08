:: 
:: Creates a backup of all VMs in Oracle VirtualBox
:: 

@ECHO OFF
CLS

:Initialize

	SET "_README="
	SET "_BACKUPDIR="
	SET "_SHUTDOWN="
	SET "_COMPRESS="
	SET "_KEEP="
	SET "_PREFIX="

	:ParseParameters
	CALL :getParamFlag "/?" "_README" "%~1" && SHIFT /1 && GOTO :ParseParameters
	IF DEFINED _README (
		ECHO:
		ECHO:
		ECHO VirtualBox Backup - Help
		ECHO:
		ECHO ^[ -b ^| --backupdir ^] ^{ PATH ^}                        - Set to change Backup Folder. Default: .\ ^(Same folder as this file^)
		ECHO ^[ -s ^| --shutdown ^]  ^[ acpipowerbutton ^| savestate ^] - Set to change Shutdown Mode. Default: acpipowerbutton ^(Clean shutdown^)
		ECHO ^[ -c ^| --compress ^]  ^[ 0 - 9 ^]                       - Set to change Compression Mode. Default: 0 ^(No compression^)
		ECHO ^[ -k ^| --keep ^] ^[ 0 - ~ ^]                            - Set to change Cleanup Mode. Default: 0 ^(All^)
		ECHO ^[ -p ^| --prefix ^] ^{ PREFIX ^}                         - Set to change Name Prefix. Default: "" ^(No prefix^)
		ECHO: 
		ECHO Please read the full documentation on https://github.com/niro1987/VirtualBox-Backup#usage
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

	SET "_VBOXMANAGE=C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"
	SET "_7za=C:\Program Files\7-Zip\7za.exe"
	SET "_DATE=%DATE%"
	SET _ERROR=0
	SET _WAITTIME=5

	ECHO Starting VirtualBox Backup...
	"%_VBOXMANAGE%" list vms
	ECHO: 
	ECHO Parameters...
	ECHO Backup Folder: "%_BACKUPDIR%"
	ECHO Shutdown Mode: "%_SHUTDOWN%"
	IF EXIST "%_7za%" (
		ECHO Compression Mode: %_COMPRESS%
	) ELSE (
		ECHO Compression Mode: Could not find "%_7za%"
	)
	ECHO Cleanup Mode: %_KEEP%
	ECHO Name Prefix: "%_PREFIX%"
	ECHO:
	ECHO:

	IF DEFINED _PREFIX (
		SET "_PREFIX=%_PREFIX% "
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

		ECHO "%_VMNAME%"

		:VM_PowerOff
		:: Shut down the VM (if it's running)
			CALL :GetState
			IF /I "%_VMSTATE%"=="running" (
				IF %_REQUESTOFF% EQU 0 (
					ECHO VM is "%_VMSTATE%"..
				)
				GOTO :PowerOff
			) ELSE (
				ECHO VM is "%_VMSTATE%"..
			)

		:VM_CopyFiles
		:: Copy the VM files
			CALL :GetPath
			ECHO Copy Files...
			IF EXIST "%_7za%" (
				ROBOCOPY "%_VMPATH%." "%TEMP%\%_VMUUID%" /E
			) ELSE (
				ROBOCOPY "%_VMPATH%." "%_BACKUPDIR%\%_VMNAME%\%_PREFIX%%_DATE%" /E
			)

		:VM_Start
		:: Start the VM (if it was running)
			IF /I "%_VMINITSTATE%"=="running" (
				ECHO Starting VM...
				CALL :PowerOn
			)

		:VM_Compress
		:: Compress the VM Backup Files to a single compressed file
			IF EXIST "%_7za%" (
				ECHO Compress Files...
				"%_7za%" a -mx%_COMPRESS% -sdel "%_BACKUPDIR%\%_VMNAME%\%_PREFIX%%_DATE%.7z" "%TEMP%\%_VMUUID%\*"
				RD /S /Q "%TEMP%\%_VMUUID%"
			)

		:VM_Cleanup
		:: Delete old backups
		IF %_KEEP% GTR 0 (
			ECHO Cleanup of old backups...
			FOR /F "skip=%_KEEP% eol=: delims=" %%F IN ('DIR /T:C /B /O:-D "%_BACKUPDIR%\%_VMNAME%\%_PREFIX%*"') DO (
				ECHO Delete "%_VMNAME%\%%~F"...
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

:Terminate
:: Check for errors and exit..
	IF %_ERROR% EQU 100 (
		SET _ERRORMSG="Timeout during PowerOff"
	)
	IF %_ERROR% GTR 0 (
		NOW %_ERROR%: %_ERRORMSG%
		NOW %_ERROR%: %_ERRORMSG% >> %_BACKUPDIR%\errorlog.txt
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
	IF %_LOOPCOUNT% GTR 0 (
		IF %_REQUESTOFF% EQU 0 (
			SET _REQUESTOFF=1
			ECHO VM Shutdown...
			"%_VBOXMANAGE%" controlvm %_VMUUID% %_SHUTDOWN%
		)
		ECHO Waiting for VM to shut down...
		TIMEOUT /t %_WAITTIME% /nobreak > nul
		SET /A _LOOPCOUNT-=1
		GOTO :VM_PowerOff
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