@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "COMMAND_VERSION=WR-2026.08.14-0328-ET"
set "BUILD_TIME=2026-08-14 03:28 ET"
set "WORK=C:\WinRERepair"
set "DISKPART=X:\Windows\System32\diskpart.exe"
set "FINDSTR=C:\Windows\System32\findstr.exe"
set "TARGET_LABEL=WINREPAIR"
set "LISTCMD=%WORK%\disk-list-0328.txt"
set "LISTOUT=%WORK%\disk-list-out-0328.txt"
set "SCANCMD=%WORK%\disk-scan-0328.txt"
set "USBDETAIL=%WORK%\usb-candidate-detail-0328.txt"
set "OSDETAIL=%WORK%\windows-disk-detail-0328.txt"
set "FINGERPRINT=%WORK%\usb-media-target-fingerprint.txt"
set "USBLETTER="
set "USBDISK="
set "OSDISK="
set "USBID=UNKNOWN"
set "USBTYPE=UNKNOWN"
set "USBSIZE=UNKNOWN"
set "USBUNIT=UNKNOWN"
set "USBLINE=UNAVAILABLE"
set "OSLINE=UNAVAILABLE"
set "LABELMATCH=0"
set "USBMATCH=0"
set "OSMATCH=0"
set "SIZEOK=NO"
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
echo Fail-closed identification of the existing %TARGET_LABEL% USB.
echo This stage contains no clean, format, partition, or delete command.
echo.

if not exist "%WORK%" md "%WORK%" >nul 2>&1
if not exist "%DISKPART%" goto :SUMMARY
if exist "%USBDETAIL%" del /f /q "%USBDETAIL%" >nul 2>&1
if exist "%OSDETAIL%" del /f /q "%OSDETAIL%" >nul 2>&1

rem First identify exactly one mounted volume by its existing known label.
for %%L in (D E F G H I J K L M N O P Q R S T U V W Y Z) do (
  vol %%L: 2>nul | "%FINDSTR%" /i /c:"%TARGET_LABEL%" >nul 2>&1
  if not errorlevel 1 (
    set /a LABELMATCH+=1
    set "USBLETTER=%%L"
  )
)
if not "!LABELMATCH!"=="1" goto :SUMMARY

rem Capture the physical disk table once.
>"%LISTCMD%" echo list disk
"%DISKPART%" /s "%LISTCMD%" >"%LISTOUT%" 2>&1

rem Disk-centric scan: DETAIL DISK officially lists the volumes on that disk.
rem Find the physical disk that actually contains WINREPAIR, and independently
rem find the disk containing the C: Windows volume.
for /L %%D in (0,1,15) do (
  >"%SCANCMD%" echo select disk %%D
  >>"%SCANCMD%" echo detail disk
  "%DISKPART%" /s "%SCANCMD%" >"%WORK%\disk-%%D-detail-0328.txt" 2>&1

  "%FINDSTR%" /i /c:"%TARGET_LABEL%" "%WORK%\disk-%%D-detail-0328.txt" >nul 2>&1
  if not errorlevel 1 (
    set /a USBMATCH+=1
    set "USBDISK=%%D"
    copy /y "%WORK%\disk-%%D-detail-0328.txt" "%USBDETAIL%" >nul 2>&1
  )

  "%FINDSTR%" /i /c:"Volume" "%WORK%\disk-%%D-detail-0328.txt" 2>nul | "%FINDSTR%" /R /C:"[ ]C[ ]" >nul 2>&1
  if not errorlevel 1 (
    set /a OSMATCH+=1
    set "OSDISK=%%D"
    copy /y "%WORK%\disk-%%D-detail-0328.txt" "%OSDETAIL%" >nul 2>&1
  )
)

if not "!USBMATCH!"=="1" goto :SUMMARY
if not "!OSMATCH!"=="1" goto :SUMMARY
if "!USBDISK!"=="!OSDISK!" goto :SUMMARY
if not exist "%USBDETAIL%" goto :SUMMARY

rem Candidate must explicitly identify as USB in its physical-disk properties.
"%FINDSTR%" /i /c:"Type" "%USBDETAIL%" 2>nul | "%FINDSTR%" /i /c:"USB" >nul 2>&1
if errorlevel 1 goto :SUMMARY
set "USBTYPE=USB"

rem Capture disk ID if DiskPart exposes one. UNKNOWN is displayed but is not
rem trusted as an identifier by itself.
for /f "tokens=1,* delims=:" %%A in ('"%FINDSTR%" /i /c:"Disk ID:" "%USBDETAIL%" 2^>nul') do if /i "!USBID!"=="UNKNOWN" set "USBID=%%B"
for /f "tokens=*" %%I in ("!USBID!") do set "USBID=%%I"
if not defined USBID set "USBID=UNKNOWN"

rem Parse the candidate and Windows rows from LIST DISK. Support both normal
rem rows and the optional leading '*' focus marker.
for /f "tokens=1,2,3,4,5,6,7" %%A in ('"%FINDSTR%" /i /c:"Disk" "%LISTOUT%"') do (
  if /i "%%A"=="Disk" if "%%B"=="!USBDISK!" (
    set "USBLINE=%%A %%B %%C %%D %%E %%F %%G"
    set "USBSIZE=%%D"
    set "USBUNIT=%%E"
  )
  if "%%A"=="*" if /i "%%B"=="Disk" if "%%C"=="!USBDISK!" (
    set "USBLINE=%%A %%B %%C %%D %%E %%F %%G"
    set "USBSIZE=%%E"
    set "USBUNIT=%%F"
  )
  if /i "%%A"=="Disk" if "%%B"=="!OSDISK!" set "OSLINE=%%A %%B %%C %%D %%E %%F %%G"
  if "%%A"=="*" if /i "%%B"=="Disk" if "%%C"=="!OSDISK!" set "OSLINE=%%A %%B %%C %%D %%E %%F %%G"
)

rem The user's USB is nominally 128 GB; Windows normally reports roughly
rem 119 GB. Accept only a deliberately broad 100-140 GB physical-disk window.
if /i "!USBUNIT!"=="GB" (
  set /a USBNUM=!USBSIZE! 2>nul
  if !USBNUM! GEQ 100 if !USBNUM! LEQ 140 set "SIZEOK=YES"
)
if /i not "!SIZEOK!"=="YES" goto :SUMMARY

set "SAFE=YES"
>"%FINGERPRINT%" echo Version=%COMMAND_VERSION%
>>"%FINGERPRINT%" echo ExistingLabel=%TARGET_LABEL%
>>"%FINGERPRINT%" echo ExistingDriveLetter=%USBLETTER%:
>>"%FINGERPRINT%" echo CandidateDisk=%USBDISK%
>>"%FINGERPRINT%" echo CandidateDiskID=%USBID%
>>"%FINGERPRINT%" echo CandidateType=%USBTYPE%
>>"%FINGERPRINT%" echo CandidateReportedSize=%USBSIZE% %USBUNIT%
>>"%FINGERPRINT%" echo WindowsDisk=%OSDISK%

:SUMMARY
cls
echo ================================================================
echo USB MEDIA TARGET SNAPSHOT
echo Version: %COMMAND_VERSION%
echo ================================================================
echo Matching WINREPAIR volumes : %LABELMATCH%
echo Existing drive letter      : %USBLETTER%:
echo Disks containing WINREPAIR : %USBMATCH%
echo Candidate physical disk    : %USBDISK%
echo Candidate disk type        : %USBTYPE%
echo Candidate disk ID          : %USBID%
echo Candidate reported size    : %USBSIZE% %USBUNIT%
echo 128-GB size check          : %SIZEOK%
echo Disks containing Windows C : %OSMATCH%
echo Windows C: physical disk   : %OSDISK%
echo ---------------------------------------------------------------
echo Candidate LIST DISK row:
echo %USBLINE%
echo Windows LIST DISK row:
echo %OSLINE%
echo ---------------------------------------------------------------
if exist "%USBDETAIL%" (
  echo Candidate proof from DETAIL DISK:
  "%FINDSTR%" /i /c:"Disk ID:" /c:"Type" /c:"%TARGET_LABEL%" "%USBDETAIL%" 2>nul
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
