@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "COMMAND_VERSION=WR-2026.08.14-0350-ET"
set "BUILD_TIME=2026-08-14 03:50 ET"
set "WORK=C:\WinRERepair"
set "DISKPART=X:\Windows\System32\diskpart.exe"
set "FINDSTR=C:\Windows\System32\findstr.exe"
set "CURL=C:\Windows\System32\curl.exe"
set "NSLOOKUP=C:\Windows\System32\nslookup.exe"
set "DNS=64.71.255.204"
set "APIHOST=api.github.com"
set "WRURL=https://api.github.com/repos/RennieBeekharry/winre-repair/contents/wr.cmd?ref=main"
set "WRNEW=%WORK%\wr.api.new.cmd"
set "HELPER=X:\wr-install-api-launcher.cmd"
set "OLDOUT=%WORK%\usb-media-layout-out-0340.txt"
set "SCAN=%WORK%\usb-postformat-scan-0350.txt"
set "D1=%WORK%\usb-disk1-postformat-0350.txt"
set "D0=%WORK%\windows-disk0-postformat-0350.txt"
set "VOLS=%WORK%\volumes-postformat-0350.txt"
set "PARTS=%WORK%\partitions-postformat-0350.txt"
set "UFOUND=NO"
set "VFOUND=NO"
set "WIN11FOUND=NO"
set "REPAIRFOUND=NO"
set "DISK1USB=UNKNOWN"
set "DISK0C=UNKNOWN"
set "OLDERROR=UNKNOWN"
set "UPGRADE=NO"

cls
echo ================================================================
echo WINRE-REPAIR - CHANNEL MIGRATION + USB DIAGNOSTIC
echo Version: %COMMAND_VERSION%
echo Built:   %BUILD_TIME%
echo Fetched: %date% %time%
echo Mode:    READ-ONLY FOR ALL DISKS
echo ================================================================

if not exist "%WORK%" md "%WORK%" >nul 2>&1

rem Stage the new API-only persistent launcher. Do not replace C:\wr.cmd yet;
rem the currently running old launcher may still be reading that file.
if exist "%WRNEW%" del /f /q "%WRNEW%" >nul 2>&1
set "APIIP="
for /f "delims=" %%L in ('"%NSLOOKUP%" %APIHOST% %DNS% 2^>nul ^| "%FINDSTR%" /R "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*"') do (
  for %%T in (%%L) do set "CAND=%%T"
  if not "!CAND!"=="%DNS%" set "APIIP=!CAND!"
)
if defined APIIP (
  "%CURL%" --ssl-no-revoke --fail --silent --show-error --connect-timeout 10 --max-time 120 --resolve "%APIHOST%:443:!APIIP!" -H "Accept: application/vnd.github.raw+json" -H "Cache-Control: no-cache, no-store, max-age=0" "%WRURL%" -o "%WRNEW%" >nul 2>&1
)
if exist "%WRNEW%" (
  "%FINDSTR%" /l /c:"WR-LAUNCHER-2026.08.14-0348-ET" "%WRNEW%" >nul 2>&1
  if not errorlevel 1 set "UPGRADE=STAGED"
)

rem Read-only inspection of current Disk 1 state after the prior format attempt.
if exist "%DISKPART%" (
  >"%SCAN%" echo select disk 1
  >>"%SCAN%" echo detail disk
  "%DISKPART%" /s "%SCAN%" >"%D1%" 2>&1
  "%FINDSTR%" /i /c:"Type" "%D1%" 2>nul | "%FINDSTR%" /i /c:"USB" >nul 2>&1
  if not errorlevel 1 set "DISK1USB=YES"

  >"%SCAN%" echo select disk 0
  >>"%SCAN%" echo detail disk
  "%DISKPART%" /s "%SCAN%" >"%D0%" 2>&1
  "%FINDSTR%" /i /c:"Volume" "%D0%" 2>nul | "%FINDSTR%" /R /C:"[ ]C[ ]" >nul 2>&1
  if not errorlevel 1 set "DISK0C=YES"

  >"%SCAN%" echo list volume
  "%DISKPART%" /s "%SCAN%" >"%VOLS%" 2>&1
  >"%SCAN%" echo select disk 1
  >>"%SCAN%" echo list partition
  "%DISKPART%" /s "%SCAN%" >"%PARTS%" 2>&1

  "%FINDSTR%" /R /C:"[ ]U[ ]" "%VOLS%" >nul 2>&1
  if not errorlevel 1 set "UFOUND=YES"
  "%FINDSTR%" /R /C:"[ ]V[ ]" "%VOLS%" >nul 2>&1
  if not errorlevel 1 set "VFOUND=YES"
  "%FINDSTR%" /i /c:"WIN11MEDIA" "%VOLS%" >nul 2>&1
  if not errorlevel 1 set "WIN11FOUND=YES"
  "%FINDSTR%" /i /c:"REPAIRDATA" "%VOLS%" >nul 2>&1
  if not errorlevel 1 set "REPAIRFOUND=YES"
)

if exist "%OLDOUT%" (
  "%FINDSTR%" /i /c:"error" /c:"failed" /c:"not supported" /c:"too big" /c:"incorrect" /c:"cannot" /c:"could not" "%OLDOUT%" >nul 2>&1
  if not errorlevel 1 (set "OLDERROR=ERROR_TEXT_FOUND") else (set "OLDERROR=NO_ERROR_TEXT_FOUND")
) else (
  set "OLDERROR=PREVIOUS_OUTPUT_MISSING"
)

rem Schedule launcher replacement only after this command returns and the old
rem parent C:\wr.cmd has had time to exit.
if /i "!UPGRADE!"=="STAGED" (
  >"%HELPER%" echo @echo off
  >>"%HELPER%" echo ping -n 6 127.0.0.1 ^>nul
  >>"%HELPER%" echo copy /y "%WRNEW%" "C:\wr.cmd" ^>nul 2^>^&1
  >>"%HELPER%" echo del /f /q "%WRNEW%" ^>nul 2^>^&1
  start "" /b cmd /c "%HELPER%" >nul 2>&1
)

cls
echo ================================================================
echo USB POST-FORMAT SNAPSHOT
echo Version: %COMMAND_VERSION%
echo ================================================================
echo API launcher upgrade staged : %UPGRADE%
echo Disk 1 still reports USB    : %DISK1USB%
echo Windows C still on Disk 0   : %DISK0C%
echo U: volume present           : %UFOUND%
echo V: volume present           : %VFOUND%
echo WIN11MEDIA label present    : %WIN11FOUND%
echo REPAIRDATA label present    : %REPAIRFOUND%
echo Previous DiskPart output    : %OLDERROR%
echo ---------------------------------------------------------------
echo Current Disk 1 volumes:
"%FINDSTR%" /i /c:"Volume" "%D1%" 2>nul
echo ---------------------------------------------------------------
echo Current Disk 1 partitions:
"%FINDSTR%" /i /c:"Partition" "%PARTS%" 2>nul
echo ---------------------------------------------------------------
if exist "%OLDOUT%" (
  echo Relevant lines from failed DiskPart run:
  "%FINDSTR%" /i /c:"DiskPart successfully" /c:"error" /c:"failed" /c:"not supported" /c:"too big" /c:"incorrect" /c:"cannot" /c:"could not" "%OLDOUT%" 2>nul
)
echo ================================================================
echo NO DISK CHANGES WERE MADE BY THIS DIAGNOSTIC.
if /i "%UPGRADE%"=="STAGED" echo C:\wr.cmd will switch to API-only updates in about 5 seconds.
echo Take ONE photo of this screen and send it to ChatGPT.
exit /b 0
