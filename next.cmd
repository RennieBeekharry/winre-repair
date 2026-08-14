@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "COMMAND_VERSION=WR-2026.08.14-0335-ET"
set "BUILD_TIME=2026-08-14 03:35 ET"
set "WORK=C:\WinRERepair"
set "DISKPART=X:\Windows\System32\diskpart.exe"
set "FINDSTR=C:\Windows\System32\findstr.exe"
set "TARGET_LABEL=WINREPAIR"
set "EXPECTED_DISK_ID=E0BF3720"
set "EXPECTED_USB_SIZE=114 GB"
set "SCAN=%WORK%\usb-erase-preflight.txt"
set "USBDETAIL=%WORK%\usb-erase-candidate.txt"
set "OSDETAIL=%WORK%\usb-erase-windows-disk.txt"
set "DPSCRIPT=%WORK%\usb-media-layout.txt"
set "DPOUT=%WORK%\usb-media-layout-out.txt"
set "USBDISK="
set "OSDISK="
set "USBMATCH=0"
set "OSMATCH=0"
set "USBID=UNKNOWN"
set "SAFE=NO"

cls
echo ================================================================
echo WINRE-REPAIR - VERIFIED USB MEDIA PARTITIONING
echo Version: %COMMAND_VERSION%
echo Built:   %BUILD_TIME%
echo Fetched: %date% %time%
echo ================================================================
echo.
echo DESTRUCTIVE ACTION: the verified WINREPAIR USB will be erased.
echo Internal Windows disk must independently resolve to a different disk.
echo Expected USB fingerprint: USB / ID %EXPECTED_DISK_ID% / %EXPECTED_USB_SIZE%.
echo.

if not exist "%WORK%" md "%WORK%" >nul 2>&1
if not exist "%DISKPART%" goto :FAIL
if not exist "C:\Windows\System32\Config\SYSTEM" goto :FAIL
if exist U:\ goto :FAIL_LETTER
if exist V:\ goto :FAIL_LETTER
if exist "%USBDETAIL%" del /f /q "%USBDETAIL%" >nul 2>&1
if exist "%OSDETAIL%" del /f /q "%OSDETAIL%" >nul 2>&1

rem Re-identify both disks from scratch. Disk numbers are not trusted alone.
for /L %%D in (0,1,15) do (
  >"%SCAN%" echo select disk %%D
  >>"%SCAN%" echo detail disk
  "%DISKPART%" /s "%SCAN%" >"%WORK%\erase-disk-%%D-detail.txt" 2>&1

  "%FINDSTR%" /i /c:"%TARGET_LABEL%" "%WORK%\erase-disk-%%D-detail.txt" >nul 2>&1
  if not errorlevel 1 (
    set /a USBMATCH+=1
    set "USBDISK=%%D"
    copy /y "%WORK%\erase-disk-%%D-detail.txt" "%USBDETAIL%" >nul 2>&1
  )

  "%FINDSTR%" /i /c:"Volume" "%WORK%\erase-disk-%%D-detail.txt" 2>nul | "%FINDSTR%" /R /C:"[ ]C[ ]" >nul 2>&1
  if not errorlevel 1 (
    set /a OSMATCH+=1
    set "OSDISK=%%D"
    copy /y "%WORK%\erase-disk-%%D-detail.txt" "%OSDETAIL%" >nul 2>&1
  )
)

if not "!USBMATCH!"=="1" goto :FAIL
if not "!OSMATCH!"=="1" goto :FAIL
if "!USBDISK!"=="!OSDISK!" goto :FAIL
if not exist "%USBDETAIL%" goto :FAIL

rem Candidate must explicitly be USB and contain the exact known removable volume.
"%FINDSTR%" /i /c:"Type" "%USBDETAIL%" 2>nul | "%FINDSTR%" /i /c:"USB" >nul 2>&1
if errorlevel 1 goto :FAIL
"%FINDSTR%" /i /c:"%TARGET_LABEL%" "%USBDETAIL%" 2>nul | "%FINDSTR%" /i /c:"Removable" >nul 2>&1
if errorlevel 1 goto :FAIL
"%FINDSTR%" /i /c:"%TARGET_LABEL%" "%USBDETAIL%" 2>nul | "%FINDSTR%" /i /c:"114 GB" >nul 2>&1
if errorlevel 1 goto :FAIL

rem Disk ID must match the previously observed physical USB fingerprint exactly.
for /f "tokens=1,* delims=:" %%A in ('"%FINDSTR%" /i /c:"Disk ID:" "%USBDETAIL%" 2^>nul') do if /i "!USBID!"=="UNKNOWN" set "USBID=%%B"
for /f "tokens=*" %%I in ("!USBID!") do set "USBID=%%I"
if /i not "!USBID!"=="%EXPECTED_DISK_ID%" goto :FAIL

rem Extra hard stop: the candidate may never be Disk 0 on this machine.
if "!USBDISK!"=="0" goto :FAIL
set "SAFE=YES"

echo ================================================================
echo PREFLIGHT PASSED
echo USB physical disk : !USBDISK!
echo USB disk ID       : !USBID!
echo Windows disk      : !OSDISK!
echo ================================================================
echo Erasing only the verified USB and creating media partitions...

rem Create a UEFI-friendly FAT32 boot partition and an NTFS repair-data partition.
>"%DPSCRIPT%" echo select disk !USBDISK!
>>"%DPSCRIPT%" echo clean
>>"%DPSCRIPT%" echo convert gpt
>>"%DPSCRIPT%" echo create partition primary size=30000
>>"%DPSCRIPT%" echo format fs=fat32 quick label=WIN11MEDIA
>>"%DPSCRIPT%" echo assign letter=U
>>"%DPSCRIPT%" echo create partition primary
>>"%DPSCRIPT%" echo format fs=ntfs quick label=REPAIRDATA
>>"%DPSCRIPT%" echo assign letter=V
>>"%DPSCRIPT%" echo list volume
>>"%DPSCRIPT%" echo detail disk

"%DISKPART%" /s "%DPSCRIPT%" >"%DPOUT%" 2>&1
if errorlevel 1 goto :FORMAT_FAIL

if not exist U:\ goto :FORMAT_FAIL
if not exist V:\ goto :FORMAT_FAIL
vol U: | "%FINDSTR%" /i /c:"WIN11MEDIA" >nul 2>&1
if errorlevel 1 goto :FORMAT_FAIL
vol V: | "%FINDSTR%" /i /c:"REPAIRDATA" >nul 2>&1
if errorlevel 1 goto :FORMAT_FAIL

cls
echo ================================================================
echo USB MEDIA LAYOUT READY
echo Version: %COMMAND_VERSION%
echo ================================================================
echo Verified erased disk : !USBDISK!
echo Previous disk ID     : !USBID!
echo Windows disk         : !OSDISK!  [NOT TOUCHED]
echo Boot partition       : U:  WIN11MEDIA  FAT32  ~30 GB
echo Repair-data partition: V:  REPAIRDATA   NTFS   remaining space
echo ---------------------------------------------------------------
echo NEXT: download/build Windows 11 24H2 repair media files.
echo ================================================================
echo Take ONE photo of this screen and send it to ChatGPT.
exit /b 0

:FAIL_LETTER
set "MSG=Drive letter U: or V: is already in use. USB was not erased."
goto :FAIL_MSG
:FORMAT_FAIL
set "MSG=USB was selected correctly, but partitioning/format verification failed."
goto :FAIL_MSG
:FAIL
set "MSG=USB identity preflight did not exactly match the verified fingerprint. Nothing was erased."
:FAIL_MSG
cls
echo ================================================================
echo USB MEDIA STAGE STOPPED
echo %MSG%
echo ================================================================
echo Candidate disk: !USBDISK!
echo Candidate ID  : !USBID!
echo Windows disk  : !OSDISK!
echo USB matches   : !USBMATCH!
echo OS matches    : !OSMATCH!
echo ================================================================
exit /b 90
