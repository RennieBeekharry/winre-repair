@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "COMMAND_VERSION=WR-2026.08.14-0340-ET"
set "BUILD_TIME=2026-08-14 03:40 ET"
set "WORK=C:\WinRERepair"
set "DISKPART=X:\Windows\System32\diskpart.exe"
set "FINDSTR=C:\Windows\System32\findstr.exe"
set "TARGET_LABEL=WINREPAIR"
set "EXPECTED_DISK_ID=E0BF3720"
set "EXPECTED_USB_DISK=1"
set "EXPECTED_OS_DISK=0"
set "EXPECTED_USB_SIZE=114 GB"
set "SCAN=%WORK%\usb-erase-preflight-0340.txt"
set "USBDETAIL=%WORK%\usb-erase-candidate-0340.txt"
set "OSDETAIL=%WORK%\usb-erase-windows-disk-0340.txt"
set "DPSCRIPT=%WORK%\usb-media-layout-0340.txt"
set "DPOUT=%WORK%\usb-media-layout-out-0340.txt"
set "USBDISK="
set "OSDISK="
set "USBMATCH=0"
set "OSMATCH=0"
set "SAFE=NO"

cls
echo ================================================================
echo WINRE-REPAIR - VERIFIED USB MEDIA PARTITIONING
echo Version: %COMMAND_VERSION%
echo Built:   %BUILD_TIME%
echo Fetched: %date% %time%
echo ================================================================
echo.
echo DESTRUCTIVE ACTION: only the previously verified WINREPAIR USB may be erased.
echo Required fingerprint:
echo   Physical disk : %EXPECTED_USB_DISK%
echo   Type          : USB
echo   Disk ID       : %EXPECTED_DISK_ID%
echo   Volume        : WINREPAIR / Removable / %EXPECTED_USB_SIZE%
echo   Windows disk  : %EXPECTED_OS_DISK%
echo.

if not exist "%WORK%" md "%WORK%" >nul 2>&1
if not exist "%DISKPART%" goto :FAIL
if not exist "C:\Windows\System32\Config\SYSTEM" goto :FAIL
if exist U:\ goto :FAIL_LETTER
if exist V:\ goto :FAIL_LETTER
if exist "%USBDETAIL%" del /f /q "%USBDETAIL%" >nul 2>&1
if exist "%OSDETAIL%" del /f /q "%OSDETAIL%" >nul 2>&1

rem Re-identify both disks from scratch. Disk number alone is never sufficient.
for /L %%D in (0,1,15) do (
  >"%SCAN%" echo select disk %%D
  >>"%SCAN%" echo detail disk
  "%DISKPART%" /s "%SCAN%" >"%WORK%\erase-disk-%%D-detail-0340.txt" 2>&1

  "%FINDSTR%" /i /c:"%TARGET_LABEL%" "%WORK%\erase-disk-%%D-detail-0340.txt" >nul 2>&1
  if not errorlevel 1 (
    set /a USBMATCH+=1
    set "USBDISK=%%D"
    copy /y "%WORK%\erase-disk-%%D-detail-0340.txt" "%USBDETAIL%" >nul 2>&1
  )

  "%FINDSTR%" /i /c:"Volume" "%WORK%\erase-disk-%%D-detail-0340.txt" 2>nul | "%FINDSTR%" /R /C:"[ ]C[ ]" >nul 2>&1
  if not errorlevel 1 (
    set /a OSMATCH+=1
    set "OSDISK=%%D"
    copy /y "%WORK%\erase-disk-%%D-detail-0340.txt" "%OSDETAIL%" >nul 2>&1
  )
)

rem Fail closed unless the exact previously observed topology is present.
if not "!USBMATCH!"=="1" goto :FAIL
if not "!OSMATCH!"=="1" goto :FAIL
if not "!USBDISK!"=="%EXPECTED_USB_DISK%" goto :FAIL
if not "!OSDISK!"=="%EXPECTED_OS_DISK%" goto :FAIL
if "!USBDISK!"=="!OSDISK!" goto :FAIL
if "!USBDISK!"=="0" goto :FAIL
if not exist "%USBDETAIL%" goto :FAIL

rem Literal fingerprint checks. No Disk ID parsing is used.
"%FINDSTR%" /i /c:"%EXPECTED_DISK_ID%" "%USBDETAIL%" >nul 2>&1
if errorlevel 1 goto :FAIL
"%FINDSTR%" /i /c:"Type" "%USBDETAIL%" 2>nul | "%FINDSTR%" /i /c:"USB" >nul 2>&1
if errorlevel 1 goto :FAIL
"%FINDSTR%" /i /c:"%TARGET_LABEL%" "%USBDETAIL%" 2>nul | "%FINDSTR%" /i /c:"Removable" >nul 2>&1
if errorlevel 1 goto :FAIL
"%FINDSTR%" /i /c:"%TARGET_LABEL%" "%USBDETAIL%" 2>nul | "%FINDSTR%" /i /c:"114 GB" >nul 2>&1
if errorlevel 1 goto :FAIL

rem Re-prove Windows C: is on Disk 0 and not on the USB candidate.
if not exist "%OSDETAIL%" goto :FAIL
"%FINDSTR%" /i /c:"Volume" "%OSDETAIL%" 2>nul | "%FINDSTR%" /R /C:"[ ]C[ ]" >nul 2>&1
if errorlevel 1 goto :FAIL

set "SAFE=YES"
echo ================================================================
echo PREFLIGHT PASSED
echo USB physical disk : !USBDISK!
echo USB disk ID       : %EXPECTED_DISK_ID%
echo Windows disk      : !OSDISK!
echo ================================================================
echo Erasing ONLY the verified USB and creating media partitions...

rem Destructive commands begin here, after all identity checks above pass.
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
echo Verified erased disk : !USBDISK!  [USB]
echo Verified old disk ID : %EXPECTED_DISK_ID%
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
set "MSG=The verified USB was selected, but partitioning or format verification failed."
goto :FAIL_MSG

:FAIL
set "MSG=USB identity preflight did not exactly match the verified fingerprint. Nothing was erased."

:FAIL_MSG
cls
echo ================================================================
echo USB MEDIA STAGE STOPPED
echo %MSG%
echo ================================================================
echo Candidate disk : !USBDISK!
echo Expected USB   : Disk %EXPECTED_USB_DISK% / ID %EXPECTED_DISK_ID% / %EXPECTED_USB_SIZE%
echo Windows disk  : !OSDISK!  [expected %EXPECTED_OS_DISK%]
echo USB matches   : !USBMATCH!
echo OS matches    : !OSMATCH!
echo ================================================================
exit /b 90
