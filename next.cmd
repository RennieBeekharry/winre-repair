@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "COMMAND_VERSION=WR-2026.08.14-0258-ET"
set "BUILD_TIME=2026-08-14 02:58 ET"
set "OS=C:"
set "WORK=C:\WinRERepair"
set "REG=X:\Windows\System32\reg.exe"
set "FINDSTR=C:\Windows\System32\findstr.exe"
set "CHKDSK=X:\Windows\System32\chkdsk.exe"
set "FSUTIL=X:\Windows\System32\fsutil.exe"
set "DISKPART=X:\Windows\System32\diskpart.exe"
set "WMIC=X:\Windows\System32\wbem\wmic.exe"
if not exist "%WMIC%" set "WMIC=C:\Windows\System32\wbem\wmic.exe"
set "POWERSHELL=X:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
if not exist "%POWERSHELL%" set "POWERSHELL=C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
set "DEVICEKEY=HKLM\WR_SYS\ControlSet001\Enum\PCI\VEN_8086&DEV_A102&SUBSYS_2B45103C&REV_31\3&11583659&0&B8"
set "CHK=%WORK%\chkdsk-readonly-0258.txt"
set "SMART=%WORK%\smart-status-0258.txt"
set "PHYS=%WORK%\physicaldisk-status-0258.txt"
set "DPIN=%WORK%\diskpart-health-0258.txt"
set "DPOUT=%WORK%\diskpart-health-out-0258.txt"
set "DIRTYOUT=%WORK%\dirty-bit-0258.txt"
set "BINDING=UNKNOWN"
set "DISKONLINE=UNKNOWN"
set "DIRTYSTATE=UNKNOWN"
set "CHKSTATE=INCONCLUSIVE"
set "SMARTSTATE=UNAVAILABLE"
set "PHYSSTATE=UNAVAILABLE"
set "KERNELREAD=FAIL"
set "DISKSYSREAD=FAIL"
set "HIVEREAD=FAIL"
set "ASSESS=INCONCLUSIVE"

cls
echo ================================================================
echo WINRE-REPAIR - CORRECTED DRIVE HEALTH SNAPSHOT
echo Version: %COMMAND_VERSION%
echo Built:   %BUILD_TIME%
echo Fetched: %date% %time%
echo Mode:    READ-ONLY - NO DISK REPAIR
echo ================================================================
echo.
echo Previous snapshot could falsely mark a drive failure when certutil
 echo was unavailable. This build performs direct binary file reads.
echo.

if not exist "%WORK%" md "%WORK%" >nul 2>&1

rem Confirm the failed iaStorAC test was rolled back.
%REG% unload HKLM\WR_SYS >nul 2>&1
%REG% load HKLM\WR_SYS "%OS%\Windows\System32\Config\SYSTEM" >nul 2>&1
if not errorlevel 1 (
  for /f "tokens=2,*" %%A in ('%REG% query "%DEVICEKEY%" /v Service 2^>nul ^| %FINDSTR% /i "Service"') do set "BINDING=%%B"
  %REG% unload HKLM\WR_SYS >nul 2>&1
)

rem Force real binary reads. COPY /B must read the complete source file.
if exist "%OS%\Windows\System32\ntoskrnl.exe" (
  copy /b "%OS%\Windows\System32\ntoskrnl.exe" NUL >nul 2>&1
  if not errorlevel 1 set "KERNELREAD=PASS"
)
if exist "%OS%\Windows\System32\drivers\disk.sys" (
  copy /b "%OS%\Windows\System32\drivers\disk.sys" NUL >nul 2>&1
  if not errorlevel 1 set "DISKSYSREAD=PASS"
)
if exist "%OS%\Windows\System32\Config\SYSTEM" (
  copy /b "%OS%\Windows\System32\Config\SYSTEM" NUL >nul 2>&1
  if not errorlevel 1 set "HIVEREAD=PASS"
)

rem Disk visibility.
>"%DPIN%" echo list disk
>>"%DPIN%" echo list volume
"%DISKPART%" /s "%DPIN%" >"%DPOUT%" 2>&1
%FINDSTR% /i /c:"Online" "%DPOUT%" >nul 2>&1
if not errorlevel 1 set "DISKONLINE=YES"

rem NTFS dirty bit.
"%FSUTIL%" dirty query %OS% >"%DIRTYOUT%" 2>&1
%FINDSTR% /i /c:"is NOT Dirty" "%DIRTYOUT%" >nul 2>&1
if not errorlevel 1 set "DIRTYSTATE=CLEAN"
if /i "%DIRTYSTATE%"=="UNKNOWN" (
  %FINDSTR% /i /c:"is Dirty" "%DIRTYOUT%" >nul 2>&1
  if not errorlevel 1 set "DIRTYSTATE=DIRTY"
)

rem SMART predictive status if WinRE exposes WMI. Unavailable is neutral.
if exist "%WMIC%" (
  "%WMIC%" /namespace:\\root\wmi path MSStorageDriver_FailurePredictStatus get PredictFailure /value >"%SMART%" 2>&1
  %FINDSTR% /i /c:"PredictFailure=TRUE" "%SMART%" >nul 2>&1
  if not errorlevel 1 set "SMARTSTATE=FAIL"
  if /i "!SMARTSTATE!"=="UNAVAILABLE" (
    %FINDSTR% /i /c:"PredictFailure=FALSE" "%SMART%" >nul 2>&1
    if not errorlevel 1 set "SMARTSTATE=PASS"
  )
)

rem Storage Management health if available. Unavailable is neutral.
if exist "%POWERSHELL%" (
  "%POWERSHELL%" -NoLogo -NoProfile -NonInteractive -Command "Get-PhysicalDisk ^| Format-List FriendlyName,OperationalStatus,HealthStatus,Size" >"%PHYS%" 2>&1
  %FINDSTR% /i /c:"HealthStatus" "%PHYS%" >nul 2>&1
  if not errorlevel 1 (
    %FINDSTR% /i /c:"Unhealthy" /c:"Warning" /c:"Lost Communication" "%PHYS%" >nul 2>&1
    if errorlevel 1 (set "PHYSSTATE=HEALTHY") else (set "PHYSSTATE=WARNING")
  )
)

rem Read-only filesystem check. No /F or /R.
echo Running read-only CHKDSK. Please wait...
"%CHKDSK%" %OS% >"%CHK%" 2>&1
%FINDSTR% /i /c:"found no problems" "%CHK%" >nul 2>&1
if not errorlevel 1 set "CHKSTATE=CLEAN"
%FINDSTR% /i /c:"found problems" /c:"errors found" "%CHK%" >nul 2>&1
if not errorlevel 1 set "CHKSTATE=ERRORS_FOUND"
%FINDSTR% /i /c:"0 KB in bad sectors" "%CHK%" >nul 2>&1
if not errorlevel 1 if /i "%CHKSTATE%"=="INCONCLUSIVE" set "CHKSTATE=NO_BAD_SECTORS_REPORTED"
if /i not "%CHKSTATE%"=="CLEAN" if /i not "%CHKSTATE%"=="ERRORS_FOUND" (
  %FINDSTR% /i /c:"KB in bad sectors" "%CHK%" >nul 2>&1
  if not errorlevel 1 (
    %FINDSTR% /i /c:"0 KB in bad sectors" "%CHK%" >nul 2>&1
    if errorlevel 1 set "CHKSTATE=BAD_SECTORS_REPORTED"
  )
)

rem Conservative assessment: only positive failure evidence flags the drive.
set "ASSESS=NO_OBVIOUS_DRIVE_FAILURE"
if /i "%DISKONLINE%"=="UNKNOWN" set "ASSESS=INCONCLUSIVE"
if /i "%KERNELREAD%"=="FAIL" set "ASSESS=BOOT_FILE_OR_READ_PROBLEM"
if /i "%DISKSYSREAD%"=="FAIL" set "ASSESS=BOOT_FILE_OR_READ_PROBLEM"
if /i "%HIVEREAD%"=="FAIL" set "ASSESS=READ_PROBLEM_SUSPECTED"
if /i "%CHKSTATE%"=="ERRORS_FOUND" set "ASSESS=FILESYSTEM_PROBLEM_FOUND"
if /i "%CHKSTATE%"=="BAD_SECTORS_REPORTED" set "ASSESS=DRIVE_FAILURE_SUSPECTED"
if /i "%SMARTSTATE%"=="FAIL" set "ASSESS=DRIVE_FAILURE_SUSPECTED"
if /i "%PHYSSTATE%"=="WARNING" set "ASSESS=DRIVE_FAILURE_SUSPECTED"

cls
echo ================================================================
echo RECOVERY SNAPSHOT
echo Version: %COMMAND_VERSION%
echo ================================================================
echo Controller binding       : %BINDING%
echo Physical disk online     : %DISKONLINE%
echo ntoskrnl.exe binary read : %KERNELREAD%
echo disk.sys binary read     : %DISKSYSREAD%
echo SYSTEM hive binary read  : %HIVEREAD%
echo SMART predictive status  : %SMARTSTATE%
echo PhysicalDisk health      : %PHYSSTATE%
echo NTFS dirty bit           : %DIRTYSTATE%
echo CHKDSK read-only         : %CHKSTATE%
echo ---------------------------------------------------------------
echo ASSESSMENT: %ASSESS%
echo ================================================================
echo Take ONE photo of this screen and send it to ChatGPT.
echo No disk repair was performed.
exit /b 0
