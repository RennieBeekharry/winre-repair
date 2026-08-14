@echo off
setlocal EnableExtensions EnableDelayedExpansion

rem Active repair command. wr.cmd always downloads a fresh copy of this file.
set "COMMAND_VERSION=WR-2026.08.14-0055-ET"
set "BUILD_TIME=2026-08-14 00:55 ET"
set "OS=C:"
set "WORK=C:\WinRERepair"
set "PKG=%WORK%\intel167"
set "LOG=%WORK%\winre-repair.log"
set "USBLOG=H:\RepairLogs"
set "UPDATEID=33243991-754a-46d6-94da-794a9b757ba3"
set "DNS=64.71.255.204"
set "CURL=C:\Windows\System32\curl.exe"
set "FINDSTR=C:\Windows\System32\findstr.exe"
set "NSLOOKUP=C:\Windows\System32\nslookup.exe"
set "REG=X:\Windows\System32\reg.exe"
set "DISM=X:\Windows\System32\dism.exe"
set "EXPAND=X:\Windows\System32\expand.exe"
set "WPEUTIL=X:\Windows\System32\wpeutil.exe"
set "CAB=%WORK%\intel-16.7.1.1012.cab"
set "DRIVERINFO=%WORK%\candidate-driver-info.txt"

cls
echo ================================================================
echo WINRE-REPAIR - ACTIVE COMMAND
echo Version: %COMMAND_VERSION%
echo Built:   %BUILD_TIME%
echo Fetched: %date% %time%
echo ================================================================

if not exist "%OS%\Windows\System32\Config\SYSTEM" (
  set "FAILCODE=10"
  set "FAILMSG=Windows was not found on C:. No changes were made."
  goto :FAIL
)
if not exist "%CURL%" (
  set "FAILCODE=11"
  set "FAILMSG=curl.exe was not found."
  goto :FAIL
)

if not exist "%WORK%" md "%WORK%" >nul 2>&1
if not exist "%PKG%" md "%PKG%" >nul 2>&1
if exist "H:\" if not exist "%USBLOG%" md "%USBLOG%" >nul 2>&1
>"%LOG%" echo [%date% %time%] START %COMMAND_VERSION%
call :LOG "Build: %BUILD_TIME%"
call :LOG "Target: %OS%\Windows"
call :LOG "GitHub command channel active"

rem Verify and back up the exact storage controller state.
%REG% unload HKLM\WR_SYS >nul 2>&1
%REG% load HKLM\WR_SYS "%OS%\Windows\System32\Config\SYSTEM" >>"%LOG%" 2>&1
if errorlevel 1 (
  set "FAILCODE=20"
  set "FAILMSG=Could not load the offline SYSTEM registry hive."
  goto :FAIL
)
%REG% query HKLM\WR_SYS\ControlSet001\Enum\PCI /s /f "VEN_8086&DEV_A102" >>"%LOG%" 2>&1
if errorlevel 1 (
  %REG% unload HKLM\WR_SYS >nul 2>&1
  set "FAILCODE=21"
  set "FAILMSG=Intel DEV_A102 SATA AHCI controller was not found. No driver was installed."
  goto :FAIL
)
%REG% export HKLM\WR_SYS\ControlSet001\Services\iaStorA "%WORK%\iaStorA-service-before.reg" /y >>"%LOG%" 2>&1
%REG% unload HKLM\WR_SYS >>"%LOG%" 2>&1
if exist "%OS%\Windows\System32\drivers\iaStorA.sys" copy /y "%OS%\Windows\System32\drivers\iaStorA.sys" "%WORK%\iaStorA.sys.before" >>"%LOG%" 2>&1

call :LOG "Initializing networking"
%WPEUTIL% InitializeNetwork >>"%LOG%" 2>&1
ping -n 1 1.1.1.1 >>"%LOG%" 2>&1
if errorlevel 1 (
  set "FAILCODE=30"
  set "FAILMSG=Internet connectivity failed. No driver was installed."
  goto :FAIL
)

rem Obtain the Microsoft Catalog CAB URL for the exact approved update ID.
call :RESOLVE www.catalog.update.microsoft.com CATIP
if not defined CATIP set "CATIP=20.165.94.49"
call :LOG "Catalog IP: !CATIP!"
>"%WORK%\updateids.txt" echo [{"size":0,"updateID":"%UPDATEID%","uidInfo":"%UPDATEID%"}]
%CURL% --ssl-no-revoke --fail --silent --show-error --connect-timeout 20 --max-time 120 --resolve "www.catalog.update.microsoft.com:443:!CATIP!" -X POST -H "Content-Type: application/x-www-form-urlencoded" --data-urlencode "updateIDs@%WORK%\updateids.txt" "https://www.catalog.update.microsoft.com/DownloadDialog.aspx" -o "%WORK%\catalog.html" >>"%LOG%" 2>&1
if errorlevel 1 (
  set "FAILCODE=32"
  set "FAILMSG=Microsoft Update Catalog request failed."
  goto :FAIL
)

set "CABURL="
for /f "tokens=2 delims='" %%U in ('%FINDSTR% /i "download.windowsupdate.com dl.delivery.mp.microsoft.com" "%WORK%\catalog.html" 2^>nul') do if not defined CABURL set "CABURL=%%U"
if not defined CABURL (
  set "FAILCODE=33"
  set "FAILMSG=Catalog did not return the driver CAB URL."
  goto :FAIL
)
call :LOG "Catalog driver URL: !CABURL!"

rem FOR /F collapses repeated '/' delimiters, so token 2 is the host.
for /f "tokens=2 delims=/" %%H in ("!CABURL!") do set "DLHOST=%%H"
if not defined DLHOST (
  set "FAILCODE=34"
  set "FAILMSG=Could not determine the Microsoft download host."
  goto :FAIL
)
call :LOG "Download host: !DLHOST!"

if exist "%CAB%" del /f /q "%CAB%" >nul 2>&1
if exist "%CAB%.tmp" del /f /q "%CAB%.tmp" >nul 2>&1
call :RESOLVE !DLHOST! DLIP
if defined DLIP (
  call :LOG "Resolved download IP: !DLIP!"
  call :TRYDOWNLOAD !DLIP!
)

if not exist "%CAB%" (
  for %%I in (152.195.19.97 23.32.75.16 152.199.39.108 152.199.21.175 2.16.168.54 2.20.245.170) do (
    if not exist "%CAB%" (
      call :LOG "Trying CDN fallback IP %%I"
      call :TRYDOWNLOAD %%I
    )
  )
)

if not exist "%CAB%" (
  set "FAILCODE=35"
  set "FAILMSG=Driver CAB download failed after resolved and CDN fallback attempts."
  goto :FAIL
)
for %%Z in ("%CAB%") do call :LOG "Driver CAB downloaded: %%~zZ bytes"

if exist "%PKG%\*" del /q "%PKG%\*" >nul 2>&1
%EXPAND% -F:* "%CAB%" "%PKG%" >>"%LOG%" 2>&1
if errorlevel 1 (
  set "FAILCODE=40"
  set "FAILMSG=Driver CAB extraction failed."
  goto :FAIL
)

rem Do not parse the INF text directly. Ask DISM to interpret the candidate
rem package and report its normalized metadata, including Hardware ID and
rem DriverVer. This avoids FINDSTR/INF encoding problems.
set "MATCHINF="
for /r "%PKG%" %%F in (iaAHCIC.inf) do if not defined MATCHINF set "MATCHINF=%%F"
if not defined MATCHINF (
  set "FAILCODE=41"
  set "FAILMSG=Expected iaAHCIC.inf was not present in the Microsoft package. Installation refused."
  goto :FAIL
)
call :LOG "Candidate INF: !MATCHINF!"
if exist "%DRIVERINFO%" del /f /q "%DRIVERINFO%" >nul 2>&1
%DISM% /Image:%OS%\ /Get-DriverInfo /Driver:"!MATCHINF!" /English /Format:List /LogPath:"%WORK%\dism-candidate-driver.log" >"%DRIVERINFO%" 2>&1
if errorlevel 1 (
  type "%DRIVERINFO%" >>"%LOG%" 2>&1
  set "FAILCODE=42"
  set "FAILMSG=DISM could not inspect the candidate Intel driver. Installation refused."
  goto :FAIL
)
type "%DRIVERINFO%" >>"%LOG%"

%FINDSTR% /l /i /c:"PCI\VEN_8086&DEV_A102&CC_0106" "%DRIVERINFO%" >nul 2>&1
if errorlevel 1 (
  set "FAILCODE=43"
  set "FAILMSG=DISM metadata does not list the exact DEV_A102 AHCI hardware ID. Installation refused."
  goto :FAIL
)
%FINDSTR% /l /i /c:"16.7.1.1012" "%DRIVERINFO%" >nul 2>&1
if errorlevel 1 (
  set "FAILCODE=44"
  set "FAILMSG=DISM metadata does not report expected driver version 16.7.1.1012. Installation refused."
  goto :FAIL
)
%FINDSTR% /l /i /c:"amd64" "%DRIVERINFO%" >nul 2>&1
if errorlevel 1 (
  set "FAILCODE=45"
  set "FAILMSG=DISM metadata does not report AMD64 support. Installation refused."
  goto :FAIL
)
call :LOG "DISM validation passed: DEV_A102, version 16.7.1.1012, AMD64"

rem Add only this verified INF. Do not use /ForceUnsigned; x64 signature
rem enforcement remains active.
call :LOG "Adding verified signed Intel driver INF to offline Windows"
%DISM% /Image:%OS%\ /Add-Driver /Driver:"!MATCHINF!" /English /LogPath:"%WORK%\dism-add-driver.log" >>"%LOG%" 2>&1
if errorlevel 1 (
  set "FAILCODE=50"
  set "FAILMSG=DISM could not add the verified Intel storage driver."
  goto :FAIL
)
%DISM% /Image:%OS%\ /Get-Drivers /All /English /Format:Table /LogPath:"%WORK%\dism-driver-inventory.log" >>"%LOG%" 2>&1

call :LOG "SUCCESS - verified signed Intel storage driver package added"
call :COPYLOGS
echo.
echo ================================================================
echo SUCCESS - DRIVER PACKAGE INSTALLED
echo Version: %COMMAND_VERSION%
echo Log: %LOG%
if exist "H:\" echo USB copy: %USBLOG%\winre-repair.log
echo Rebooting in 10 seconds.
echo ================================================================
ping -n 11 127.0.0.1 >nul
%WPEUTIL% reboot
exit /b 0

:TRYDOWNLOAD
set "TRYIP=%~1"
if exist "%CAB%" exit /b 0
echo(!CABURL!|%FINDSTR% /b /i "https://" >nul
if not errorlevel 1 (
  %CURL% --ssl-no-revoke --fail --location --silent --show-error --connect-timeout 12 --max-time 600 --resolve "!DLHOST!:443:%TRYIP%" "!CABURL!" -o "%CAB%.tmp" >>"%LOG%" 2>&1
) else (
  %CURL% --fail --location --silent --show-error --connect-timeout 12 --max-time 600 --resolve "!DLHOST!:80:%TRYIP%" "!CABURL!" -o "%CAB%.tmp" >>"%LOG%" 2>&1
)
if errorlevel 1 (
  if exist "%CAB%.tmp" del /f /q "%CAB%.tmp" >nul 2>&1
  exit /b 1
)
for %%Z in ("%CAB%.tmp") do if %%~zZ LSS 1024 (
  del /f /q "%CAB%.tmp" >nul 2>&1
  exit /b 1
)
move /y "%CAB%.tmp" "%CAB%" >nul
exit /b 0

:RESOLVE
set "%~2="
set "CAND="
for /f "delims=" %%L in ('%NSLOOKUP% %~1 %DNS% 2^>nul ^| %FINDSTR% /R "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*"') do (
  for %%T in (%%L) do set "CAND=%%T"
  if not "!CAND!"=="%DNS%" set "%~2=!CAND!"
)
exit /b 0

:LOG
echo [%date% %time%] %~1
echo [%date% %time%] %~1>>"%LOG%"
exit /b 0

:COPYLOGS
if exist "H:\" (
  if not exist "%USBLOG%" md "%USBLOG%" >nul 2>&1
  copy /y "%LOG%" "%USBLOG%\winre-repair.log" >nul 2>&1
  if exist "%DRIVERINFO%" copy /y "%DRIVERINFO%" "%USBLOG%\candidate-driver-info.txt" >nul 2>&1
  if exist "%WORK%\dism-candidate-driver.log" copy /y "%WORK%\dism-candidate-driver.log" "%USBLOG%\dism-candidate-driver.log" >nul 2>&1
  if exist "%WORK%\dism-add-driver.log" copy /y "%WORK%\dism-add-driver.log" "%USBLOG%\dism-add-driver.log" >nul 2>&1
  if exist "%WORK%\dism-driver-inventory.log" copy /y "%WORK%\dism-driver-inventory.log" "%USBLOG%\dism-driver-inventory.log" >nul 2>&1
)
exit /b 0

:FAIL
call :LOG "FAILURE !FAILCODE! - !FAILMSG!"
%REG% unload HKLM\WR_SYS >nul 2>&1
call :COPYLOGS
echo.
echo ================================================================
echo REPAIR STOPPED - NO REBOOT
echo Version: %COMMAND_VERSION%
echo !FAILMSG!
echo Error: !FAILCODE!
echo Log: %LOG%
if exist "H:\" echo USB copy: %USBLOG%\winre-repair.log
echo ================================================================
exit /b !FAILCODE!
