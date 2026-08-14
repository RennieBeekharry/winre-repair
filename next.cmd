@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "COMMAND_VERSION=WR-2026.08.14-0240-ET"
set "BUILD_TIME=2026-08-14 02:40 ET"
set "OS=C:"
set "WORK=C:\WinRERepair"
set "REG=X:\Windows\System32\reg.exe"
set "DISM=X:\Windows\System32\dism.exe"
set "FINDSTR=C:\Windows\System32\findstr.exe"
set "WPEUTIL=X:\Windows\System32\wpeutil.exe"
set "INF=%WORK%\intel167\iaAHCIC.inf"
set "INFO=%WORK%\binding-candidate-info.txt"
set "INV=%WORK%\binding-driver-inventory.txt"
set "LOG=%WORK%\storage-binding-test.log"
set "HIVEBACKUP=%WORK%\SYSTEM.before-iaStorAC-binding.hiv"
set "DEVBACKUP=%WORK%\DEV_A102.before-iaStorAC-binding.reg"
set "ACBACKUP=%WORK%\iaStorAC.before-binding.reg"
set "ABACKUP=%WORK%\iaStorA.before-binding.reg"
set "MARKER=%WORK%\iaStorAC-binding-applied.txt"
set "DEVICEKEY=HKLM\WR_SYS\ControlSet001\Enum\PCI\VEN_8086&DEV_A102&SUBSYS_2B45103C&REV_31\3&11583659&0&B8"

cls
echo ================================================================
echo WINRE-REPAIR - REVERSIBLE STORAGE BINDING TEST
echo Version: %COMMAND_VERSION%
echo Built:   %BUILD_TIME%
echo Fetched: %date% %time%
echo ================================================================
echo.
echo Target: Intel DEV_A102 SATA AHCI controller only
echo Change: iaStorA -^> iaStorAC service binding
echo Backup: full offline SYSTEM hive + exact registry keys
echo Reboot: automatic after successful verification
echo.

if not exist "%WORK%" md "%WORK%" >nul 2>&1
>"%LOG%" echo [%date% %time%] START %COMMAND_VERSION%

if not exist "%OS%\Windows\System32\Config\SYSTEM" goto :FAIL_OS
if not exist "%OS%\Windows\System32\drivers\iaStorAC.sys" goto :FAIL_SYS
if not exist "%INF%" goto :FAIL_INF

rem Re-validate the exact signed candidate before touching the binding.
%DISM% /Image:%OS%\ /Get-DriverInfo /Driver:"%INF%" /English /Format:List >"%INFO%" 2>&1
if errorlevel 1 goto :FAIL_META
%FINDSTR% /l /i /c:"PCI\VEN_8086&DEV_A102&CC_0106" "%INFO%" >nul 2>&1
if errorlevel 1 goto :FAIL_META
%FINDSTR% /l /i /c:"16.7.1.1012" "%INFO%" >nul 2>&1
if errorlevel 1 goto :FAIL_META
%FINDSTR% /l /i /c:"iaStorAC" "%INFO%" >nul 2>&1
if errorlevel 1 goto :FAIL_META
%FINDSTR% /l /i /c:"amd64" "%INFO%" >nul 2>&1
if errorlevel 1 goto :FAIL_META

%DISM% /Image:%OS%\ /Get-Drivers /All /English /Format:Table >"%INV%" 2>&1
%FINDSTR% /l /i /c:"16.7.1.1012" "%INV%" >nul 2>&1
if errorlevel 1 goto :FAIL_INSTALLED

%REG% unload HKLM\WR_SYS >nul 2>&1
%REG% load HKLM\WR_SYS "%OS%\Windows\System32\Config\SYSTEM" >>"%LOG%" 2>&1
if errorlevel 1 goto :FAIL_HIVE

set "CURSERVICE=UNKNOWN"
set "ACSTART=UNKNOWN"
for /f "tokens=2,*" %%A in ('%REG% query "%DEVICEKEY%" /v Service 2^>nul ^| %FINDSTR% /i "Service"') do set "CURSERVICE=%%B"
for /f "tokens=2,*" %%A in ('%REG% query HKLM\WR_SYS\ControlSet001\Services\iaStorAC /v Start 2^>nul ^| %FINDSTR% /i "Start"') do set "ACSTART=%%B"

echo [%date% %time%] Current Service=!CURSERVICE!>>"%LOG%"
echo [%date% %time%] iaStorAC Start=!ACSTART!>>"%LOG%"

if /i "!CURSERVICE!"=="iaStorAC" goto :ALREADY_APPLIED
if /i not "!CURSERVICE!"=="iaStorA" goto :FAIL_UNEXPECTED_SERVICE
if /i not "!ACSTART!"=="0x0" goto :FAIL_START

%REG% query HKLM\WR_SYS\ControlSet001\Services\iaStorAC /v ImagePath 2>nul | %FINDSTR% /i /c:"iaStorAC.sys" >nul 2>&1
if errorlevel 1 goto :FAIL_IMAGEPATH

rem Create rollback evidence before the single registry change.
%REG% save HKLM\WR_SYS "%HIVEBACKUP%" /y >>"%LOG%" 2>&1
if errorlevel 1 goto :FAIL_BACKUP
%REG% export "%DEVICEKEY%" "%DEVBACKUP%" /y >>"%LOG%" 2>&1
if errorlevel 1 goto :FAIL_BACKUP
%REG% export HKLM\WR_SYS\ControlSet001\Services\iaStorAC "%ACBACKUP%" /y >>"%LOG%" 2>&1
if errorlevel 1 goto :FAIL_BACKUP
%REG% export HKLM\WR_SYS\ControlSet001\Services\iaStorA "%ABACKUP%" /y >>"%LOG%" 2>&1
if errorlevel 1 goto :FAIL_BACKUP

rem Single reversible change: bind this exact PCI controller node to iaStorAC.
%REG% add "%DEVICEKEY%" /v Service /t REG_SZ /d iaStorAC /f >>"%LOG%" 2>&1
if errorlevel 1 goto :FAIL_WRITE

set "NEWSERVICE=UNKNOWN"
for /f "tokens=2,*" %%A in ('%REG% query "%DEVICEKEY%" /v Service 2^>nul ^| %FINDSTR% /i "Service"') do set "NEWSERVICE=%%B"
if /i not "!NEWSERVICE!"=="iaStorAC" goto :FAIL_VERIFY

>"%MARKER%" echo Version=%COMMAND_VERSION%
>>"%MARKER%" echo Applied=%date% %time%
>>"%MARKER%" echo Controller=PCI\VEN_8086^&DEV_A102
>>"%MARKER%" echo PreviousService=iaStorA
>>"%MARKER%" echo NewService=iaStorAC
>>"%MARKER%" echo RollbackHive=%HIVEBACKUP%
>>"%MARKER%" echo RollbackDeviceKey=%DEVBACKUP%

%REG% unload HKLM\WR_SYS >>"%LOG%" 2>&1

echo.
echo ================================================================
echo STORAGE BINDING TEST APPLIED AND VERIFIED
echo Version: %COMMAND_VERSION%
echo Previous binding: iaStorA
echo Test binding:     iaStorAC
echo Full SYSTEM backup: %HIVEBACKUP%
echo ================================================================
echo Rebooting in 10 seconds to test Windows startup...
ping -n 11 127.0.0.1 >nul
%WPEUTIL% reboot
exit /b 0

:ALREADY_APPLIED
%REG% unload HKLM\WR_SYS >nul 2>&1
echo.
echo BINDING TEST IS ALREADY APPLIED.
echo Current controller service is already iaStorAC.
echo No additional change and no automatic reboot were performed.
exit /b 60

:FAIL_OS
set "MSG=Offline Windows SYSTEM hive was not found on C:."
goto :FAIL
:FAIL_SYS
set "MSG=iaStorAC.sys is missing. Binding was not changed."
goto :FAIL
:FAIL_INF
set "MSG=Validated Intel 16.7 candidate INF is missing. Binding was not changed."
goto :FAIL
:FAIL_META
set "MSG=Intel 16.7 metadata validation failed. Binding was not changed."
goto :FAIL
:FAIL_INSTALLED
set "MSG=Intel 16.7.1.1012 is not present in the offline driver inventory."
goto :FAIL
:FAIL_HIVE
set "MSG=Could not load the offline SYSTEM hive."
goto :FAIL
:FAIL_UNEXPECTED_SERVICE
set "MSG=Controller is not currently bound to iaStorA. Unexpected state; stopped."
goto :FAIL_LOADED
:FAIL_START
set "MSG=iaStorAC is not configured as Start=0. Binding was not changed."
goto :FAIL_LOADED
:FAIL_IMAGEPATH
set "MSG=iaStorAC ImagePath does not point to iaStorAC.sys. Binding was not changed."
goto :FAIL_LOADED
:FAIL_BACKUP
set "MSG=Rollback backup creation failed. Binding was not changed."
goto :FAIL_LOADED
:FAIL_WRITE
set "MSG=Registry binding write failed."
goto :FAIL_LOADED
:FAIL_VERIFY
set "MSG=Registry binding verification failed."
goto :FAIL_LOADED

:FAIL_LOADED
%REG% unload HKLM\WR_SYS >nul 2>&1
:FAIL
echo.
echo ================================================================
echo BINDING TEST STOPPED SAFELY
echo %MSG%
echo No reboot was initiated.
echo ================================================================
exit /b 90
