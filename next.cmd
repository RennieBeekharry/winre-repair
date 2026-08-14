@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "COMMAND_VERSION=WR-2026.08.14-0345-ET"
set "BUILD_TIME=2026-08-14 03:45 ET"
set "WORK=C:\WinRERepair"
set "DISKPART=X:\Windows\System32\diskpart.exe"
set "FINDSTR=C:\Windows\System32\findstr.exe"
set "OLDOUT=%WORK%\usb-media-layout-out-0340.txt"
set "SCAN=%WORK%\usb-postformat-scan-0345.txt"
set "D1=%WORK%\usb-disk1-postformat-0345.txt"
set "D0=%WORK%\windows-disk0-postformat-0345.txt"
set "VOLS=%WORK%\volumes-postformat-0345.txt"
set "PARTS=%WORK%\partitions-postformat-0345.txt"
set "UFOUND=NO"
set "VFOUND=NO"
set "WIN11FOUND=NO"
set "REPAIRFOUND=NO"
set "DISK1USB=UNKNOWN"
set "DISK0C=UNKNOWN"
set "OLDERROR=UNKNOWN"

cls
echo ================================================================
echo WINRE-REPAIR - USB POST-FORMAT DIAGNOSTIC
echo Version: %COMMAND_VERSION%
echo Built:   %BUILD_TIME%
echo Fetched: %date% %time%
echo Mode:    READ-ONLY - NO CLEAN / FORMAT / PARTITION CHANGES
echo ================================================================

if not exist "%WORK%" md "%WORK%" >nul 2>&1
if not exist "%DISKPART%" goto :SUMMARY

rem Inspect current Disk 1 state.
>"%SCAN%" echo select disk 1
>>"%SCAN%" echo detail disk
"%DISKPART%" /s "%SCAN%" >"%D1%" 2>&1
"%FINDSTR%" /i /c:"Type" "%D1%" 2>nul | "%FINDSTR%" /i /c:"USB" >nul 2>&1
if not errorlevel 1 set "DISK1USB=YES"

rem Independently verify Windows still belongs to Disk 0.
>"%SCAN%" echo select disk 0
>>"%SCAN%" echo detail disk
"%DISKPART%" /s "%SCAN%" >"%D0%" 2>&1
"%FINDSTR%" /i /c:"Volume" "%D0%" 2>nul | "%FINDSTR%" /R /C:"[ ]C[ ]" >nul 2>&1
if not errorlevel 1 set "DISK0C=YES"

rem List current volumes and Disk 1 partitions.
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

rem Classify the saved DiskPart output from the failed destructive run.
if exist "%OLDOUT%" (
  "%FINDSTR%" /i /c:"error" /c:"failed" /c:"not supported" /c:"too big" /c:"incorrect" /c:"cannot" /c:"could not" "%OLDOUT%" >nul 2>&1
  if not errorlevel 1 (set "OLDERROR=ERROR_TEXT_FOUND") else (set "OLDERROR=NO_ERROR_TEXT_FOUND")
) else (
  set "OLDERROR=PREVIOUS_OUTPUT_MISSING"
)

:SUMMARY
cls
echo ================================================================
echo USB POST-FORMAT SNAPSHOT
echo Version: %COMMAND_VERSION%
echo ================================================================
echo Disk 1 still reports USB : %DISK1USB%
echo Windows C still on Disk 0: %DISK0C%
echo U: volume present        : %UFOUND%
echo V: volume present        : %VFOUND%
echo WIN11MEDIA label present : %WIN11FOUND%
echo REPAIRDATA label present : %REPAIRFOUND%
echo Previous DiskPart output : %OLDERROR%
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
echo Take ONE photo of this screen and send it to ChatGPT.
exit /b 0
