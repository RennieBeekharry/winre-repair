@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "COMMAND_VERSION=WR-2026.08.14-0404-ET"
set "BUILD_TIME=2026-08-14 04:04 ET"
set "WORK=C:\WinRERepair"
set "DISKPART=X:\Windows\System32\diskpart.exe"
set "FORMAT=X:\Windows\System32\format.com"
if not exist "%FORMAT%" set "FORMAT=C:\Windows\System32\format.com"
set "FINDSTR=C:\Windows\System32\findstr.exe"
set "SCAN=%WORK%\usb-formatonly-scan-0404.txt"
set "D1=%WORK%\usb-disk1-formatonly-0404.txt"
set "D0=%WORK%\windows-disk0-formatonly-0404.txt"
set "LISTCMD=%WORK%\usb-listdisk-formatonly-0404.txt"
set "LISTOUT=%WORK%\usb-listdisk-out-formatonly-0404.txt"
set "VOLCMD=%WORK%\usb-listvol-formatonly-0404.txt"
set "VOLOUT=%WORK%\usb-listvol-out-formatonly-0404.txt"
set "PARTCMD=%WORK%\usb-listpart-formatonly-0404.txt"
set "PARTOUT=%WORK%\usb-listpart-out-formatonly-0404.txt"
set "POSTCMD=%WORK%\usb-postformat-0404.txt"
set "POSTOUT=%WORK%\usb-postformat-out-0404.txt"
set "FATOUT=%WORK%\usb-fat32-format-0404.txt"
set "NTFSOUT=%WORK%\usb-ntfs-format-0404.txt"

cls
echo ================================================================
echo WINRE-REPAIR - USB FORMAT ONLY
echo Version: %COMMAND_VERSION%
echo Built:   %BUILD_TIME%
echo Fetched: %date% %time%
echo ================================================================
echo.
echo The partition layout already succeeded in the previous run.
echo This pass DOES NOT CLEAN OR REPARTITION THE USB.
echo It only formats the already-created U: and V: USB volumes.
echo.

if not exist "%WORK%" md "%WORK%" >nul 2>&1
if not exist "%DISKPART%" goto :PREFLIGHTFAIL
if not exist "%FORMAT%" goto :PREFLIGHTFAIL
if not exist "C:\Windows\System32\Config\SYSTEM" goto :PREFLIGHTFAIL

rem Re-identify both physical disks and current USB volumes from scratch.
>"%SCAN%" echo select disk 1
>>"%SCAN%" echo detail disk
"%DISKPART%" /s "%SCAN%" >"%D1%" 2>&1

>"%SCAN%" echo select disk 0
>>"%SCAN%" echo detail disk
"%DISKPART%" /s "%SCAN%" >"%D0%" 2>&1

>"%LISTCMD%" echo list disk
"%DISKPART%" /s "%LISTCMD%" >"%LISTOUT%" 2>&1

>"%VOLCMD%" echo list volume
"%DISKPART%" /s "%VOLCMD%" >"%VOLOUT%" 2>&1

>"%PARTCMD%" echo select disk 1
>>"%PARTCMD%" echo list partition
"%DISKPART%" /s "%PARTCMD%" >"%PARTOUT%" 2>&1

rem Disk 1 must still be the known USB and Disk 0 must still own Windows C:.
"%FINDSTR%" /i /c:"Type" "%D1%" 2>nul | "%FINDSTR%" /i /c:"USB" >nul 2>&1
if errorlevel 1 goto :PREFLIGHTFAIL
"%FINDSTR%" /i /c:"Disk 1" "%LISTOUT%" 2>nul | "%FINDSTR%" /i /c:"114 GB" >nul 2>&1
if errorlevel 1 goto :PREFLIGHTFAIL
"%FINDSTR%" /i /c:"Volume" "%D0%" 2>nul | "%FINDSTR%" /R /C:"[ ]C[ ]" >nul 2>&1
if errorlevel 1 goto :PREFLIGHTFAIL
"%FINDSTR%" /i /c:"Volume" "%D1%" 2>nul | "%FINDSTR%" /R /C:"[ ]C[ ]" >nul 2>&1
if not errorlevel 1 goto :PREFLIGHTFAIL

rem The already-created USB layout must still expose U: and V: as RAW volumes.
"%FINDSTR%" /R /C:"[ ]U[ ]" "%D1%" 2>nul | "%FINDSTR%" /i /c:"RAW" >nul 2>&1
if errorlevel 1 goto :PREFLIGHTFAIL
"%FINDSTR%" /R /C:"[ ]V[ ]" "%D1%" 2>nul | "%FINDSTR%" /i /c:"RAW" >nul 2>&1
if errorlevel 1 goto :PREFLIGHTFAIL
"%FINDSTR%" /i /c:"Partition 1" "%PARTOUT%" >nul 2>&1
if errorlevel 1 goto :PREFLIGHTFAIL
"%FINDSTR%" /i /c:"Partition 2" "%PARTOUT%" >nul 2>&1
if errorlevel 1 goto :PREFLIGHTFAIL

cls
echo ================================================================
echo PREFLIGHT PASSED
echo Disk 1 = verified 114 GB USB
echo Disk 0 = Windows C: [NOT TOUCHED]
echo Existing U: and V: RAW partitions verified
echo ================================================================
echo Formatting U: as FAT32...

"%FORMAT%" U: /FS:FAT32 /Q /V:WIN11MEDIA /Y /X >"%FATOUT%" 2>&1
if errorlevel 1 goto :FORMATFAIL

echo Formatting V: as NTFS...
"%FORMAT%" V: /FS:NTFS /Q /V:REPAIRDATA /Y /X >"%NTFSOUT%" 2>&1
if errorlevel 1 goto :FORMATFAIL

rem Verify labels and filesystems.
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

:FORMATFAIL
cls
echo ================================================================
echo USB FORMAT STOPPED - FILESYSTEM FORMAT FAILED
echo Disk 0 Windows was not targeted.
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
echo Disk 0 Windows was not targeted.
echo ---------------------------------------------------------------
type "%POSTOUT%" 2>nul
echo ================================================================
exit /b 93

:PREFLIGHTFAIL
cls
echo ================================================================
echo USB FORMAT NOT STARTED
echo Existing USB layout or disk identity did not match expected state.
echo No CLEAN or partition command was run by this pass.
echo Disk 0 remains protected.
echo ================================================================
exit /b 90
