@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "COMMAND_VERSION=WR-2026.08.14-0325-ET"
set "BUILD_TIME=2026-08-14 03:25 ET"
set "WORK=C:\WinRERepair"
set "DISKPART=X:\Windows\System32\diskpart.exe"
set "FINDSTR=C:\Windows\System32\findstr.exe"
set "TARGET_LABEL=WINREPAIR"
set "VOLCMD=%WORK%\usb-target-volume.txt"
set "VOLOUT=%WORK%\usb-target-volume-out.txt"
set "OSCMD=%WORK%\os-volume.txt"
set "OSOUT=%WORK%\os-volume-out.txt"
set "DISKCMD=%WORK%\usb-target-disk.txt"
set "DISKOUT=%WORK%\usb-target-disk-out.txt"
set "LISTCMD=%WORK%\disk-list.txt"
set "LISTOUT=%WORK%\disk-list-out.txt"
set "FINGERPRINT=%WORK%\usb-media-target-fingerprint.txt"
set "USBLETTER="
set "USBDISK="
set "OSDISK="
set "USBID=UNKNOWN"
set "USBTYPE=UNKNOWN"
set "MATCHCOUNT=0"
set "SAFE=NO"

cls
echo ================================================================
echo WINRE-REPAIR - USB MEDIA TARGET IDENTIFICATION
echo Version: %COMMAND_VERSION%
echo Built:   %BUILD_TIME%
echo Fetched: %date% %time%
echo Mode:    READ-ONLY - NOTHING WILL BE ERASED
echo ================================================================
echo.
echo Looking for exactly one existing USB volume labelled %TARGET_LABEL%.
echo The internal Windows disk will be identified independently and excluded.
echo.

if not exist "%WORK%" md "%WORK%" >nul 2>&1
if not exist "%DISKPART%" goto :SUMMARY

rem Find exactly one mounted volume with the known existing WINREPAIR label.
for %%L in (D E F G H I J K L M N O P Q R S T U V W Y Z) do (
  vol %%L: 2>nul | "%FINDSTR%" /i /c:"%TARGET_LABEL%" >nul 2>&1
  if not errorlevel 1 (
    set /a MATCHCOUNT+=1
    set "USBLETTER=%%L"
  )
)
if not "%MATCHCOUNT%"=="1" goto :SUMMARY

rem Map the labelled USB volume to its physical disk number.
>"%VOLCMD%" echo select volume %USBLETTER%
>>"%VOLCMD%" echo detail volume
"%DISKPART%" /s "%VOLCMD%" >"%VOLOUT%" 2>&1
for /f "tokens=1,2,3" %%A in ('"%FINDSTR%" /R /C:"Disk [0-9]" "%VOLOUT%"') do (
  if /i "%%A"=="Disk" set "USBDISK=%%B"
  if /i "%%B"=="Disk" set "USBDISK=%%C"
)
if not defined USBDISK goto :SUMMARY

rem Independently map the offline Windows C: volume to its physical disk.
>"%OSCMD%" echo select volume C
>>"%OSCMD%" echo detail volume
"%DISKPART%" /s "%OSCMD%" >"%OSOUT%" 2>&1
for /f "tokens=1,2,3" %%A in ('"%FINDSTR%" /R /C:"Disk [0-9]" "%OSOUT%"') do (
  if /i "%%A"=="Disk" set "OSDISK=%%B"
  if /i "%%B"=="Disk" set "OSDISK=%%C"
)
if not defined OSDISK goto :SUMMARY
if "%USBDISK%"=="%OSDISK%" goto :SUMMARY

rem Inspect the candidate physical disk. It must explicitly report USB.
>"%DISKCMD%" echo select disk %USBDISK%
>>"%DISKCMD%" echo detail disk
"%DISKPART%" /s "%DISKCMD%" >"%DISKOUT%" 2>&1
"%FINDSTR%" /i /R /C:"Type.*USB" "%DISKOUT%" >nul 2>&1
if errorlevel 1 goto :SUMMARY
set "USBTYPE=USB"
for /f "tokens=3" %%I in ('"%FINDSTR%" /i /c:"Disk ID:" "%DISKOUT%"') do if /i "!USBID!"=="UNKNOWN" set "USBID=%%I"

rem Capture disk list lines so the user can visually verify the capacity.
>"%LISTCMD%" echo list disk
"%DISKPART%" /s "%LISTCMD%" >"%LISTOUT%" 2>&1
set "SAFE=YES"

rem Save the non-secret fingerprint for the destructive stage to re-check.
>"%FINGERPRINT%" echo Version=%COMMAND_VERSION%
>>"%FINGERPRINT%" echo ExistingLabel=%TARGET_LABEL%
>>"%FINGERPRINT%" echo ExistingDriveLetter=%USBLETTER%:
>>"%FINGERPRINT%" echo CandidateDisk=%USBDISK%
>>"%FINGERPRINT%" echo CandidateDiskID=%USBID%
>>"%FINGERPRINT%" echo CandidateType=%USBTYPE%
>>"%FINGERPRINT%" echo WindowsDisk=%OSDISK%

:SUMMARY
cls
echo ================================================================
echo USB MEDIA TARGET SNAPSHOT
echo Version: %COMMAND_VERSION%
echo ================================================================
echo Matching WINREPAIR volumes : %MATCHCOUNT%
echo Candidate drive letter     : %USBLETTER%:
echo Candidate physical disk    : %USBDISK%
echo Candidate disk type        : %USBTYPE%
echo Candidate disk ID          : %USBID%
echo Windows C: physical disk   : %OSDISK%
echo ---------------------------------------------------------------
if defined USBDISK (
  echo Candidate disk listing:
  "%FINDSTR%" /i /c:"Disk %USBDISK%" "%LISTOUT%" 2>nul
)
if defined OSDISK (
  echo Windows disk listing:
  "%FINDSTR%" /i /c:"Disk %OSDISK%" "%LISTOUT%" 2>nul
)
echo ---------------------------------------------------------------
if /i "%SAFE%"=="YES" (
  echo TARGET STATUS: SAFE_CANDIDATE_IDENTIFIED
  echo NEXT STAGE IS NOT ARMED YET.
) else (
  echo TARGET STATUS: NOT_SAFE_TO_ERASE
)
echo ================================================================
echo NO FORMAT, CLEAN, PARTITION, OR FILE DELETE COMMAND WAS RUN.
echo Take ONE photo of this screen and send it to ChatGPT.
exit /b 0
