@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "COMMAND_VERSION=WR-2026.08.14-0248-ET"
set "BUILD_TIME=2026-08-14 02:48 ET"
set "OS=C:"
set "WORK=C:\WinRERepair"
set "REG=X:\Windows\System32\reg.exe"
set "FINDSTR=C:\Windows\System32\findstr.exe"
set "CHKDSK=X:\Windows\System32\chkdsk.exe"
set "FSUTIL=X:\Windows\System32\fsutil.exe"
set "DISKPART=X:\Windows\System32\diskpart.exe"
set "CERTUTIL=X:\Windows\System32\certutil.exe"
set "WMIC=X:\Windows\System32\wbem\wmic.exe"
if not exist "%WMIC%" set "WMIC=C:\Windows\System32\wbem\wmic.exe"
set "POWERSHELL=X:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
if not exist "%POWERSHELL%" set "POWERSHELL=C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
set "DEVICEKEY=HKLM\WR_SYS\ControlSet001\Enum\PCI\VEN_8086&DEV_A102&SUBSYS_2B45103C&REV_31\3&11583659&0&B8"
set "LOG=%WORK%\drive-health-triage.log"
set "CHK=%WORK%\chkdsk-readonly.txt"
set "SMART=%WORK%\smart-status.txt"
set "PHYS=%WORK%\physicaldisk-status.txt"
set "DPIN=%WORK%\diskpart-health.txt"
set "DPOUT=%WORK%\diskpart-health-out.txt"
set "DIRTYOUT=%WORK%\dirty-bit.txt"
set "ROLLBACK=UNKNOWN"
set "READABLE=NO"
set "DISKONLINE=UNKNOWN"
set "SMARTSTATE=UNAVAILABLE"
set "PHYSSTATE=UNAVAILABLE"
set "DIRTYSTATE=UNKNOWN"
set "CHKSTATE=INCONCLUSIVE"
set "READTEST=FAIL"
set "ASSESS=NO_OBVIOUS_DRIVE_FAILURE"

cls
echo ================================================================
echo WINRE-REPAIR - DRIVE HEALTH SNAPSHOT
echo Version: %COMMAND_VERSION%
echo Built:   %BUILD_TIME%
echo Fetched: %date% %time%
echo ================================================================
echo.
echo Restoring the failed iaStorAC test binding, then checking the drive.
echo Drive checks are READ-ONLY. CHKDSK is run without /F or /R.
echo.

if not exist "%WORK%" md "%WORK%" >nul 2>&1
>"%LOG%" echo [%date% %time%] START %COMMAND_VERSION%

rem Roll back only the exact controller service value changed by build 0240.
if not exist "%OS%\Windows\System32\Config\SYSTEM" goto :NO_OS
%REG% unload HKLM\WR_SYS >nul 2>&1
%REG% load HKLM\WR_SYS "%OS%\Windows\System32\Config\SYSTEM" >>"%LOG%" 2>&1
if errorlevel 1 goto :ROLLBACK_FAIL
set "CURSERVICE=UNKNOWN"
for /f "tokens=2,*" %%A in ('%REG% query "%DEVICEKEY%" /v Service 2^>nul ^| %FINDSTR% /i "Service"') do set "CURSERVICE=%%B"
if /i "!CURSERVICE!"=="iaStorAC" (
  %REG% add "%DEVICEKEY%" /v Service /t REG_SZ /d iaStorA /f >>"%LOG%" 2>&1
  if errorlevel 1 goto :ROLLBACK_FAIL_LOADED
)
set "NEWSERVICE=UNKNOWN"
for /f "tokens=2,*" %%A in ('%REG% query "%DEVICEKEY%" /v Service 2^>nul ^| %FINDSTR% /i "Service"') do set "NEWSERVICE=%%B"
if /i "!NEWSERVICE!"=="iaStorA" set "ROLLBACK=OK"
%REG% unload HKLM\WR_SYS >nul 2>&1
if /i not "%ROLLBACK%"=="OK" goto :ROLLBACK_FAIL

goto :DRIVE_TESTS

:ROLLBACK_FAIL_LOADED
%REG% unload HKLM\WR_SYS >nul 2>&1
:ROLLBACK_FAIL
set "ROLLBACK=FAILED"
goto :SUMMARY

:NO_OS
set "ROLLBACK=NOT_RUN"
goto :SUMMARY

:DRIVE_TESTS
if exist "%OS%\Windows\System32\ntoskrnl.exe" set "READABLE=YES"

rem Verify that actual bytes can be read from two boot-critical files.
if exist "%CERTUTIL%" (
  "%CERTUTIL%" -hashfile "%OS%\Windows\System32\ntoskrnl.exe" SHA256 >nul 2>&1
  if not errorlevel 1 (
    "%CERTUTIL%" -hashfile "%OS%\Windows\System32\drivers\disk.sys" SHA256 >nul 2>&1
    if not errorlevel 1 set "READTEST=PASS"
  )
)

rem DiskPart visibility/online state.
>"%DPIN%" echo list disk
>>"%DPIN%" echo list volume
"%DISKPART%" /s "%DPIN%" >"%DPOUT%" 2>&1
%FINDSTR% /i /c:"Online" "%DPOUT%" >nul 2>&1
if not errorlevel 1 set "DISKONLINE=YES"

rem Query NTFS dirty bit; no repair action.
"%FSUTIL%" dirty query %OS% >"%DIRTYOUT%" 2>&1
%FINDSTR% /i /c:"is NOT Dirty" "%DIRTYOUT%" >nul 2>&1
if not errorlevel 1 set "DIRTYSTATE=CLEAN"
if /i "%DIRTYSTATE%"=="UNKNOWN" (
  %FINDSTR% /i /c:"is Dirty" "%DIRTYOUT%" >nul 2>&1
  if not errorlevel 1 set "DIRTYSTATE=DIRTY"
)

rem Try SMART predictive status if WMIC/WMI is available in this WinRE image.
if exist "%WMIC%" (
  "%WMIC%" /namespace:\\root\wmi path MSStorageDriver_FailurePredictStatus get PredictFailure /value >"%SMART%" 2>&1
  %FINDSTR% /i /c:"PredictFailure=TRUE" "%SMART%" >nul 2>&1
  if not errorlevel 1 set "SMARTSTATE=FAIL"
  if /i "!SMARTSTATE!"=="UNAVAILABLE" (
    %FINDSTR% /i /c:"PredictFailure=FALSE" "%SMART%" >nul 2>&1
    if not errorlevel 1 set "SMARTSTATE=PASS"
  )
)

rem Try Storage Management health if PowerShell Storage cmdlets are available.
if exist "%POWERSHELL%" (
  "%POWERSHELL%" -NoLogo -NoProfile -NonInteractive -Command "Get-PhysicalDisk ^| Format-List FriendlyName,OperationalStatus,HealthStatus,Size" >"%PHYS%" 2>&1
  %FINDSTR% /i /c:"HealthStatus" "%PHYS%" >nul 2>&1
  if not errorlevel 1 (
    %FINDSTR% /i /c:"Unhealthy" /c:"Warning" /c:"Lost Communication" "%PHYS%" >nul 2>&1
    if errorlevel 1 (set "PHYSSTATE=HEALTHY") else (set "PHYSSTATE=WARNING")
  )
)

rem Microsoft documents CHKDSK without repair switches as status/read-only.
echo Running read-only CHKDSK. This may take several minutes...
"%CHKDSK%" %OS% >"%CHK%" 2>&1
%FINDSTR% /i /c:"found no problems" "%CHK%" >nul 2>&1
if not errorlevel 1 set "CHKSTATE=CLEAN"
%FINDSTR% /i /c:"found problems" /c:"errors found" "%CHK%" >nul 2>&1
if not errorlevel 1 set "CHKSTATE=ERRORS_FOUND"
%FINDSTR% /i /c:"0 KB in bad sectors" "%CHK%" >nul 2>&1
if not errorlevel 1 (
  if /i "%CHKSTATE%"=="INCONCLUSIVE" set "CHKSTATE=NO_BAD_SECTORS_REPORTED"
) else (
  %FINDSTR% /i /c:"KB in bad sectors" "%CHK%" >nul 2>&1
  if not errorlevel 1 set "CHKSTATE=BAD_SECTORS_REPORTED"
)

if /i "%SMARTSTATE%"=="FAIL" set "ASSESS=DRIVE_FAILURE_SUSPECTED"
if /i "%PHYSSTATE%"=="WARNING" set "ASSESS=DRIVE_FAILURE_SUSPECTED"
if /i "%CHKSTATE%"=="BAD_SECTORS_REPORTED" set "ASSESS=DRIVE_FAILURE_SUSPECTED"
if /i "%READABLE%"=="NO" set "ASSESS=DRIVE_FAILURE_SUSPECTED"
if /i "%READTEST%"=="FAIL" set "ASSESS=DRIVE_FAILURE_SUSPECTED"
if /i "%SMARTSTATE%"=="UNAVAILABLE" if /i "%PHYSSTATE%"=="UNAVAILABLE" if /i "%CHKSTATE%"=="INCONCLUSIVE" set "ASSESS=DRIVE_HEALTH_INCONCLUSIVE"

:SUMMARY
cls
echo ================================================================
echo RECOVERY SNAPSHOT
echo Version: %COMMAND_VERSION%
echo ================================================================
echo Failed binding rollback : %ROLLBACK%
echo Windows volume readable : %READABLE%
echo Boot-file read test     : %READTEST%
echo Physical disk online    : %DISKONLINE%
echo SMART predictive status : %SMARTSTATE%
echo PhysicalDisk health     : %PHYSSTATE%
echo NTFS dirty bit          : %DIRTYSTATE%
echo CHKDSK read-only        : %CHKSTATE%
echo ---------------------------------------------------------------
echo ASSESSMENT: %ASSESS%
echo ================================================================
echo Take ONE photo of this screen and send it to ChatGPT.
echo No disk repair was performed.
exit /b 0
