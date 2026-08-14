@echo off
setlocal EnableExtensions EnableDelayedExpansion

rem winre-repair v2 - targeted repair for Intel DEV_A102 SATA AHCI in offline Windows
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

cls
echo ================================================================
echo WINRE-REPAIR v2 - Intel SATA AHCI repair
echo ================================================================

if not exist "%OS%\Windows\System32\Config\SYSTEM" (
  set "FAILCODE=10"
  set "FAILMSG=Windows was not found on C:. No changes were made."
  goto :FAIL
)
if not exist "%CURL%" (
  set "FAILCODE=11"
  set "FAILMSG=curl.exe was not found in the offline Windows installation."
  goto :FAIL
)

if not exist "%WORK%" md "%WORK%" >nul 2>&1
if not exist "%PKG%" md "%PKG%" >nul 2>&1
if exist "H:\" if not exist "%USBLOG%" md "%USBLOG%" >nul 2>&1
>"%LOG%" echo [%date% %time%] START winre-repair v2
call :LOG "Target: %OS%\Windows"

rem Verify the expected controller in the offline SYSTEM hive.
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

call :RESOLVE www.catalog.update.microsoft.com CATIP
if not defined CATIP (
  set "FAILCODE=31"
  set "FAILMSG=Could not resolve Microsoft Update Catalog through the known DNS server."
  goto :FAIL
)
call :LOG "Catalog IP: !CATIP!"

>"%WORK%\updateids.txt" echo [{"size":0,"updateID":"%UPDATEID%","uidInfo":"%UPDATEID%"}]
%CURL% --fail --silent --show-error --connect-timeout 20 --max-time 120 --resolve "www.catalog.update.microsoft.com:443:!CATIP!" -X POST -H "Content-Type: application/x-www-form-urlencoded" --data-urlencode "updateIDs@%WORK%\updateids.txt" "https://www.catalog.update.microsoft.com/DownloadDialog.aspx" -o "%WORK%\catalog.html" >>"%LOG%" 2>&1
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

for /f "tokens=3 delims=/" %%H in ("!CABURL!") do set "DLHOST=%%H"
call :RESOLVE !DLHOST! DLIP
if not defined DLIP (
  set "FAILCODE=34"
  set "FAILMSG=Could not resolve the Microsoft driver download host."
  goto :FAIL
)
call :LOG "Download host: !DLHOST! - !DLIP!"

set "CAB=%WORK%\intel-16.7.1.1012.cab"
echo(!CABURL!|%FINDSTR% /b /i "https://" >nul
if not errorlevel 1 (
  %CURL% --fail --location --retry 3 --connect-timeout 20 --max-time 900 --resolve "!DLHOST!:443:!DLIP!" "!CABURL!" -o "!CAB!" >>"%LOG%" 2>&1
) else (
  %CURL% --fail --location --retry 3 --connect-timeout 20 --max-time 900 --resolve "!DLHOST!:80:!DLIP!" "!CABURL!" -o "!CAB!" >>"%LOG%" 2>&1
)
if errorlevel 1 (
  set "FAILCODE=35"
  set "FAILMSG=Driver CAB download failed."
  goto :FAIL
)

if exist "%PKG%\*" del /q "%PKG%\*" >nul 2>&1
%EXPAND% -F:* "!CAB!" "%PKG%" >>"%LOG%" 2>&1
if errorlevel 1 (
  set "FAILCODE=40"
  set "FAILMSG=Driver CAB extraction failed."
  goto :FAIL
)

set "MATCHINF="
for /r "%PKG%" %%F in (*.inf) do %FINDSTR% /i /c:"PCI\VEN_8086&DEV_A102&CC_0106" "%%F" >nul 2>&1 && set "MATCHINF=%%F"
if not defined MATCHINF (
  set "FAILCODE=41"
  set "FAILMSG=Downloaded package does not support the required DEV_A102 controller. Installation refused."
  goto :FAIL
)
call :LOG "Verified INF: !MATCHINF!"

call :LOG "Adding signed Intel driver package to offline Windows"
%DISM% /Image:%OS%\ /Add-Driver /Driver:"%PKG%" /Recurse /LogPath:"%WORK%\dism-add-driver.log" >>"%LOG%" 2>&1
if errorlevel 1 (
  set "FAILCODE=50"
  set "FAILMSG=DISM could not add the Intel storage driver."
  goto :FAIL
)
%DISM% /Image:%OS%\ /Get-Drivers /All /Format:Table /LogPath:"%WORK%\dism-driver-inventory.log" >>"%LOG%" 2>&1

call :LOG "SUCCESS - signed Intel storage driver package added"
call :COPYLOGS
echo.
echo ================================================================
echo SUCCESS - DRIVER PACKAGE INSTALLED
echo Log: %LOG%
if exist "H:\" echo USB copy: %USBLOG%\winre-repair.log
echo The computer will reboot in 10 seconds.
echo ================================================================
ping -n 11 127.0.0.1 >nul
%WPEUTIL% reboot
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
echo !FAILMSG!
echo Error: !FAILCODE!
echo Log: %LOG%
if exist "H:\" echo USB copy: %USBLOG%\winre-repair.log
echo ================================================================
exit /b !FAILCODE!
