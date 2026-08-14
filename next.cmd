@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "COMMAND_VERSION=WR-2026.08.14-0358-ET"
set "BUILD_TIME=2026-08-14 03:58 ET"
set "WORK=C:\WinRERepair"
set "DISKPART=X:\Windows\System32\diskpart.exe"
set "FORMAT=X:\Windows\System32\format.com"
if not exist "%FORMAT%" set "FORMAT=C:\Windows\System32\format.com"
set "FINDSTR=C:\Windows\System32\findstr.exe"
set "SCAN=%WORK%\usb-format-preflight-0358.txt"
set "D1=%WORK%\usb-disk1-preflight-0358.txt"
set "D0=%WORK%\windows-disk0-preflight-0358.txt"
set "LISTCMD=%WORK%\usb-listdisk-0358.txt"
set "LISTOUT=%WORK%\usb-listdisk-out-0358.txt"
set "LAYOUT=%WORK%\usb-layout-0358.txt"
set "LAYOUTOUT=%WORK%\usb-layout-out-0358.txt"
set "POSTCMD=%WORK%\usb-postformat-0358.txt"
set "POSTOUT=%WORK%\usb-postformat-out-0358.txt"
set "FATOUT=%WORK%\usb-fat32-format-0358.txt"
set "NTFSOUT=%WORK%\usb-ntfs-format-0358.txt"

cls
echo ================================================================
echo WINRE-REPAIR - VERIFIED USB FORMAT COMPLETION
echo Version: %COMMAND_VERSION%
echo Built:   %BUILD_TIME%
echo Fetched: %date% %time%
echo ================================================================
echo.
echo Approved destructive action: erase and format the verified USB only.
echo Safety requirements before CLEAN:
echo   Disk 1 must report Type: USB and physical size 114 GB.
echo   Disk 0 must contain Windows C:.
echo   Disk 1 must NOT contain Windows C:.
echo.

if not exist "%WORK%" md "%WORK%" >nul 2>&1
if not exist "%DISKPART%" goto :PREFLIGHTFAIL
if not exist "%FORMAT%" goto :PREFLIGHTFAIL
if not exist "C:\Windows\System32\Config\SYSTEM" goto :PREFLIGHTFAIL
if exist U:\ goto :LETTERFAIL
if exist V:\ goto :LETTERFAIL

rem Re-identify the physical disks from scratch.
>"%SCAN%" echo select disk 1
>>"%SCAN%" echo detail disk
"%DISKPART%" /s "%SCAN%" >"%D1%" 2>&1

>"%SCAN%" echo select disk 0
>>"%SCAN%" echo detail disk
"%DISKPART%" /s "%SCAN%" >"%D0%" 2>&1

>"%LISTCMD%" echo list disk
"%DISKPART%" /s "%LISTCMD%" >"%LISTOUT%" 2>&1

rem Disk 1 must explicitly be USB.
"%FINDSTR%" /i /c:"Type" "%D1%" 2>nul | "%FINDSTR%" /i /c:"USB" >nul 2>&1
if errorlevel 1 goto :PREFLIGHTFAIL

rem Disk 1 physical size must still be the verified 114 GB device.
"%FINDSTR%" /i /c:"Disk 1" "%LISTOUT%" 2>nul | "%FINDSTR%" /i /c:"114 GB" >nul 2>&1
if errorlevel 1 goto :PREFLIGHTFAIL

rem Windows C: must still be on Disk 0 and absent from Disk 1.
"%FINDSTR%" /i /c:"Volume" "%D0%" 2>nul | "%FINDSTR%" /R /C:"[ ]C[ ]" >nul 2>&1
if errorlevel 1 goto :PREFLIGHTFAIL
"%FINDSTR%" /i /c:"Volume" "%D1%" 2>nul | "%FINDSTR%" /R /C:"[ ]C[ ]" >nul 2>&1
if not errorlevel 1 goto :PREFLIGHTFAIL

cls
echo ================================================================
echo PREFLIGHT PASSED
echo Disk 1 = verified 114 GB USB
echo Disk 0 = Windows C: [NOT TOUCHED]
echo ================================================================
echo Creating USB partitions...

rem Use the Microsoft-documented multi-partition USB pattern: MBR, a small
rem FAT32 boot partition, then NTFS for large repair/image files. Formatting
rem itself is done with FORMAT.COM rather than DiskPart.
>"%LAYOUT%" echo select disk 1
>>"%LAYOUT%" echo clean
>>"%LAYOUT%" echo convert mbr
>>"%LAYOUT%" echo create partition primary size=8192
>>"%LAYOUT%" echo active
>>"%LAYOUT%" echo assign letter=U
>>"%LAYOUT%" echo create partition primary
>>"%LAYOUT%" echo assign letter=V
>>"%LAYOUT%" echo exit

"%DISKPART%" /s "%LAYOUT%" >"%LAYOUTOUT%" 2>&1
if errorlevel 1 goto :LAYOUTFAIL
if not exist U:\ goto :LAYOUTFAIL
if not exist V:\ goto :LAYOUTFAIL

echo Formatting U: as FAT32...
"%FORMAT%" U: /FS:FAT32 /Q /V:WIN11MEDIA /Y >"%FATOUT%" 2>&1
if errorlevel 1 goto :FORMATFAIL

echo Formatting V: as NTFS...
"%FORMAT%" V: /FS:NTFS /Q /V:REPAIRDATA /Y >"%NTFSOUT%" 2>&1
if errorlevel 1 goto :FORMATFAIL

rem Verify the resulting labels and filesystems through DiskPart.
>"%POSTCMD%" echo list volume
"%DISKPART%" /s "%POSTCMD%" >"%POSTOUT%" 2>&1
"%FINDSTR%" /i /c:"WIN11MEDIA" "%POSTOUT%" 2>nul | "%FINDSTR%" /i /c:"FAT32" >nul 2>&1
if errorlevel 1 goto :VERIFYFAIL
"%FINDSTR%" /i /c:"REPAIRDATA" "%POSTOUT%" 2>nul | "%FINDSTR%" /i /c:"NTFS" >nul 2>&1
if errorlevel 1 goto :VERIFYFAIL
vol U: | "%FINDSTR%" /i /c:"WIN11MEDIA" >nul 2>&1
if errorlevel 1 goto :VERIFYFAIL
vol V: | "%FINDSTR%" /i /c:"REPAIRDATA" >nul 2>&1
if errorlevel 1 goto :VERIFYFAIL

cls
echo ================================================================
echo USB MEDIA FORMAT COMPLETE
echo Version: %COMMAND_VERSION%
echo ================================================================
echo USB disk             : Disk 1 [USB, 114 GB]
echo Windows disk         : Disk 0 [NOT TOUCHED]
echo Boot partition       : U: WIN11MEDIA FAT32 ~8 GB
echo Repair-data partition: V: REPAIRDATA NTFS remaining space
echo ---------------------------------------------------------------
echo STATUS: READY_FOR_WINDOWS_MEDIA_DOWNLOAD
echo ================================================================
echo DONE FOR TONIGHT.
echo Next pass: download/build Windows 11 24H2 repair media files.
exit /b 0

:LETTERFAIL
set "MSG=U: or V: is already in use. Format was not started."
goto :STOPSAFE

:PREFLIGHTFAIL
set "MSG=USB identity safety checks did not all pass. Format was not started."
goto :STOPSAFE

:LAYOUTFAIL
cls
echo ================================================================
echo USB FORMAT STOPPED - PARTITION LAYOUT FAILED
echo Disk 1 was the verified USB. Disk 0 Windows was not targeted.
echo ---------------------------------------------------------------
type "%LAYOUTOUT%" 2>nul
echo ================================================================
exit /b 91

:FORMATFAIL
cls
echo ================================================================
echo USB FORMAT STOPPED - FILESYSTEM FORMAT FAILED
echo Disk 1 was the verified USB. Disk 0 Windows was not targeted.
echo ---------------------------------------------------------------
echo FAT32 result:
type "%FATOUT%" 2>nul
echo ---------------------------------------------------------------
echo NTFS result:
type "%NTFSOUT%" 2>nul
echo ================================================================
exit /b 92

:VERIFYFAIL
cls
echo ================================================================
echo USB FORMAT STOPPED - FINAL VERIFICATION FAILED
echo Disk 1 was the verified USB. Disk 0 Windows was not targeted.
echo ---------------------------------------------------------------
type "%POSTOUT%" 2>nul
echo ================================================================
exit /b 93

:STOPSAFE
cls
echo ================================================================
echo USB FORMAT NOT STARTED
echo %MSG%
echo Disk 0 remains protected.
echo ================================================================
exit /b 90
