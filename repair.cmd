@echo off
setlocal EnableExtensions EnableDelayedExpansion

rem ============================================================================
rem winre-repair - one-shot targeted Intel SATA AHCI driver update for WinRE
rem Target controller: PCI\VEN_8086&DEV_A102 (Intel 100 Series/C230 SATA AHCI)
rem Microsoft Update Catalog driver: Intel HDC 16.7.1.1012
rem Update ID: 33243991-754a-46d6-94da-794a9b757ba3
rem ============================================================================

set "UPDATEID=33243991-754a-46d6-94da-794a9b757ba3"
set "HWID=VEN_8086&DEV_A102"
set "HWIDFULL=PCI\VEN_8086&DEV_A102&CC_0106"
set "CATALOGHOST=www.catalog.update.microsoft.com"
set "CATALOGIP=20.165.94.49"
set "CURL=C:\Windows\System32\curl.exe"
set "FINDSTR=C:\Windows\System32\findstr.exe"
set "NSLOOKUP=C:\Windows\System32\nslookup.exe"
set "DISM=X:\Windows\System32\dism.exe"
set "EXPAND=X:\Windows\System32\expand.exe"
set "REG=X:\Windows\System32\reg.exe"
set "WPEUTIL=X:\Windows\System32\wpeutil.exe"

cls
echo ================================================================
echo winre-repair - Intel SATA AHCI one-shot repair
echo ================================================================
echo.

rem ---- Locate the offline Windows installation --------------------------------
set "OSDRIVE="
for %%D in (C D E F G H I J K L M N) do (
  if exist "%%D:\Windows\System32\Config\SYSTEM" if exist "%%D:\Windows\System32\drivers" (
    if /i not "%%D:"=="X:" if not defined OSDRIVE set "OSDRIVE=%%D:"
  )
)
if not defined OSDRIVE (
  echo ERROR: Could not locate the offline Windows installation.
  exit /b 10
)

set "WORK=%OSDRIVE%\WinRERepair"
set "LOGDIR=%WORK%\logs"
set "BACKUP=%WORK%\backup"
set "PKGDIR=%WORK%\intel-16.7.1.1012"
set "LOG=%LOGDIR%\winre-repair-latest.log"
if not exist "%WORK%" md "%WORK%" >nul 2>&1
if not exist "%LOGDIR%" md "%LOGDIR%" >nul 2>&1
if not exist "%BACKUP%" md "%BACKUP%" >nul 2>&1

rem ---- Locate WINREPAIR USB for a second copy of logs --------------------------
set "USBLOG="
for %%D in (D E F G H I J K L M N) do (
  if exist "%%D:\" (
    vol %%D: 2^>nul | %FINDSTR% /i "WINREPAIR" >nul 2>&1 && set "USBLOG=%%D:\RepairLogs"
  )
)
if not defined USBLOG if exist "H:\RepairLogs" set "USBLOG=H:\RepairLogs"
if defined USBLOG if not exist "%USBLOG%" md "%USBLOG%" >nul 2>&1

call :log "START"
call :log "Offline Windows: %OSDRIVE%"
call :log "Target controller: %HWIDFULL%"
call :log "Catalog update: %UPDATEID%"

rem ---- Safety preflight: verify target controller in OFFLINE SYSTEM hive --------
%REG% unload HKLM\WR_SYS >nul 2>&1
%REG% unload HKLM\OFFSYS >nul 2>&1
%REG% load HKLM\WR_SYS "%OSDRIVE%\Windows\System32\Config\SYSTEM" >>"%LOG%" 2>&1
if errorlevel 1 (call :fail "Could not load offline SYSTEM hive." 11 & exit /b 11)

set "CS=ControlSet001"
for /f "tokens=3" %%A in ('%REG% query HKLM\WR_SYS\Select /v Default 2^>nul ^| %FINDSTR% /i "Default"') do set "DEFCS=%%A"
if /i "!DEFCS!"=="0x2" set "CS=ControlSet002"
if /i "!DEFCS!"=="0x3" set "CS=ControlSet003"
call :log "Offline control set: !CS!"

%REG% query HKLM\WR_SYS\!CS!\Enum\PCI /s /f "%HWID%" >"%WORK%\controller.txt" 2>&1
if errorlevel 1 (
  %REG% unload HKLM\WR_SYS >nul 2>&1
  call :fail "Expected Intel DEV_A102 controller was not found. No changes made." 12
  exit /b 12
)
%FINDSTR% /i "iaStorA" "%WORK%\controller.txt" >nul 2>&1
if errorlevel 1 (
  %REG% unload HKLM\WR_SYS >nul 2>&1
  call :fail "DEV_A102 exists but is not bound to iaStorA in offline Windows. No changes made." 13
  exit /b 13
)

%REG% export HKLM\WR_SYS\!CS!\Services\iaStorA "%BACKUP%\iaStorA-service.reg" /y >>"%LOG%" 2>&1
%REG% unload HKLM\WR_SYS >>"%LOG%" 2>&1

rem ---- Back up current iaStorA binary and current driver inventory --------------
if exist "%OSDRIVE%\Windows\System32\drivers\iaStorA.sys" (
  copy /y "%OSDRIVE%\Windows\System32\drivers\iaStorA.sys" "%BACKUP%\iaStorA.sys.before-update" >>"%LOG%" 2>&1
)
%DISM% /Image:%OSDRIVE%\ /Get-Drivers /All /Format:Table /LogPath:"%LOGDIR%\dism-before.log" >"%BACKUP%\drivers-before.txt" 2>&1

rem ---- Initialize networking ----------------------------------------------------
call :log "Initializing WinRE networking..."
%WPEUTIL% InitializeNetwork >>"%LOG%" 2>&1
ping -n 1 1.1.1.1 >>"%LOG%" 2>&1
if errorlevel 1 (call :fail "No internet connectivity after InitializeNetwork." 20 & exit /b 20)
if not exist "%CURL%" (call :fail "curl.exe was not found in offline Windows." 21 & exit /b 21)

rem ---- Fetch Microsoft Catalog download metadata -------------------------------
call :log "Fetching Microsoft Update Catalog metadata..."
set "CATHTML=%WORK%\catalog-response.html"
%CURL% --fail --connect-timeout 20 --max-time 120 --resolve "%CATALOGHOST%:443:%CATALOGIP%" -sS -X POST -H "Content-Type: application/x-www-form-urlencoded" --data-raw "updateIDs=%%5B%%7B%%22size%%22%%3A0%%2C%%22updateID%%22%%3A%%22%UPDATEID%%%22%%2C%%22uidInfo%%22%%3A%%22%UPDATEID%%%22%%7D%%5D" "https://%CATALOGHOST%/DownloadDialog.aspx" -o "%CATHTML%" >>"%LOG%" 2>&1
if errorlevel 1 (
  call :log "Cached Catalog IP failed. Resolving Catalog host..."
  call :resolve "%CATALOGHOST%" CATIP2
  if not defined CATIP2 (call :fail "Could not resolve Microsoft Update Catalog." 22 & exit /b 22)
  call :log "Catalog resolved to !CATIP2!"
  %CURL% --fail --connect-timeout 20 --max-time 120 --resolve "%CATALOGHOST%:443:!CATIP2!" -sS -X POST -H "Content-Type: application/x-www-form-urlencoded" --data-raw "updateIDs=%%5B%%7B%%22size%%22%%3A0%%2C%%22updateID%%22%%3A%%22%UPDATEID%%%22%%2C%%22uidInfo%%22%%3A%%22%UPDATEID%%%22%%7D%%5D" "https://%CATALOGHOST%/DownloadDialog.aspx" -o "%CATHTML%" >>"%LOG%" 2>&1
  if errorlevel 1 (call :fail "Microsoft Update Catalog request failed." 23 & exit /b 23)
)

rem ---- Parse official CAB URL ---------------------------------------------------
set "CABURL="
for /f "tokens=2 delims='" %%U in ('%FINDSTR% /i "download.windowsupdate.com dl.delivery.mp.microsoft.com" "%CATHTML%" 2^>nul') do (
  if not defined CABURL set "CABURL=%%U"
)
if not defined CABURL (call :fail "Catalog response did not contain a Microsoft driver URL." 24 & exit /b 24)
call :log "Catalog returned a Microsoft download URL."

for /f "tokens=3 delims=/" %%H in ("!CABURL!") do set "DLHOST=%%H"
if not defined DLHOST (call :fail "Could not parse Microsoft download host." 25 & exit /b 25)
call :resolve "!DLHOST!" DLIP
if not defined DLIP (call :fail "Could not resolve Microsoft driver download host." 26 & exit /b 26)
call :log "Download host: !DLHOST! -> !DLIP!"

rem ---- Download the official CAB ------------------------------------------------
set "CAB=%WORK%\intel-storage-16.7.1.1012.cab"
echo !CABURL! | %FINDSTR% /b /i "https://" >nul 2>&1
if not errorlevel 1 (
  %CURL% --fail --location --retry 4 --retry-delay 3 --connect-timeout 20 --max-time 900 --resolve "!DLHOST!:443:!DLIP!" "!CABURL!" -o "%CAB%" >>"%LOG%" 2>&1
) else (
  %CURL% --fail --location --retry 4 --retry-delay 3 --connect-timeout 20 --max-time 900 --resolve "!DLHOST!:80:!DLIP!" "!CABURL!" -o "%CAB%" >>"%LOG%" 2>&1
)
if errorlevel 1 (call :fail "Driver CAB download failed." 27 & exit /b 27)
if not exist "%CAB%" (call :fail "Driver CAB was not created." 28 & exit /b 28)
for %%S in ("%CAB%") do call :log "Downloaded CAB size: %%~zS bytes"

rem ---- Extract and verify exact controller support ------------------------------
if exist "%PKGDIR%" rd /s /q "%PKGDIR%" >nul 2>&1
md "%PKGDIR%" >nul 2>&1
%EXPAND% -F:* "%CAB%" "%PKGDIR%" >>"%LOG%" 2>&1
if errorlevel 1 (call :fail "Could not extract the Microsoft driver CAB." 30 & exit /b 30)

set "MATCHINF="
for /r "%PKGDIR%" %%F in (*.inf) do (
  %FINDSTR% /i /c:"PCI\VEN_8086&DEV_A102&CC_0106" "%%F" >nul 2>&1 && set "MATCHINF=%%F"
)
if not defined MATCHINF (call :fail "Downloaded package does not support PCI VEN_8086 DEV_A102 CC_0106." 31 & exit /b 31)
%FINDSTR% /i /c:"16.7.1.1012" "!MATCHINF!" >>"%LOG%" 2>&1
if errorlevel 1 (call :fail "Matching INF was found, but version 16.7.1.1012 was not verified." 32 & exit /b 32)
call :log "Verified matching signed Intel INF: !MATCHINF!"

rem ---- Add only the verified signed INF to the offline Windows image ------------
call :log "Adding Intel 16.7.1.1012 driver package to %OSDRIVE%\Windows..."
%DISM% /Image:%OSDRIVE%\ /Add-Driver /Driver:"!MATCHINF!" /LogPath:"%LOGDIR%\dism-add-driver.log" >>"%LOG%" 2>&1
if errorlevel 1 (call :fail "DISM failed to add the Intel driver package." 40 & exit /b 40)

%DISM% /Image:%OSDRIVE%\ /Get-Drivers /All /Format:Table /LogPath:"%LOGDIR%\dism-after.log" >"%WORK%\drivers-after.txt" 2>&1
%FINDSTR% /i "16.7.1.1012" "%WORK%\drivers-after.txt" >>"%LOG%" 2>&1
if errorlevel 1 (call :fail "DISM returned success, but 16.7.1.1012 was not found in offline driver inventory." 41 & exit /b 41)

call :log "SUCCESS: Intel 16.7.1.1012 is staged in the offline Windows driver store."
call :copylogs

echo.
echo ================================================================
echo SUCCESS
echo Intel storage driver 16.7.1.1012 was added to %OSDRIVE%\Windows.
echo.
echo Primary log:
echo   %LOG%
if defined USBLOG (
  echo.
  echo UPLOAD THIS FILE TO CHATGPT IF WINDOWS STILL FAILS:
  echo   %USBLOG%\winre-repair-latest.log
)
echo.
echo Existing Intel driver package was NOT removed.
echo BIOS storage mode was NOT changed.
echo ================================================================
echo.
echo Rebooting in 15 seconds. Press Ctrl+C to cancel the reboot.
ping -n 16 127.0.0.1 >nul
%WPEUTIL% reboot
exit /b 0

:resolve
set "%~2="
set "_R="
for %%S in (64.71.255.204 8.8.8.8 1.1.1.1) do (
  %NSLOOKUP% -type=A %~1 %%S >"%WORK%\resolve.tmp" 2>&1
  for /f "tokens=2 delims=: " %%I in ('%FINDSTR% /i "Address" "%WORK%\resolve.tmp"') do set "%~2=%%I"
  call set "_R=%%%~2%%"
  if defined _R exit /b 0
)
exit /b 1

:log
echo [%date% %time%] %~1
echo [%date% %time%] %~1>>"%LOG%"
exit /b 0

:copylogs
if defined USBLOG (
  copy /y "%LOG%" "%USBLOG%\winre-repair-latest.log" >nul 2>&1
  if exist "%LOGDIR%\dism-add-driver.log" copy /y "%LOGDIR%\dism-add-driver.log" "%USBLOG%\dism-add-driver.log" >nul 2>&1
  if exist "%WORK%\drivers-after.txt" copy /y "%WORK%\drivers-after.txt" "%USBLOG%\drivers-after.txt" >nul 2>&1
)
exit /b 0

:fail
call :log "FAILURE %~2: %~1"
call :copylogs
echo.
echo ================================================================
echo REPAIR STOPPED - NO REBOOT
echo %~1
echo Error code: %~2
echo Log: %LOG%
if defined USBLOG (
  echo.
  echo UPLOAD THIS FILE TO CHATGPT:
  echo   %USBLOG%\winre-repair-latest.log
)
echo ================================================================
exit /b %~2
