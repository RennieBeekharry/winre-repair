@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "COMMAND_VERSION=WR-2026.08.14-0353-ET"
set "BUILD_TIME=2026-08-14 03:53 ET"
set "WORK=C:\WinRERepair"
set "DISKPART=X:\Windows\System32\diskpart.exe"
set "FINDSTR=C:\Windows\System32\findstr.exe"
set "SCAN=%WORK%\usb-final-preflight-0353.txt"
set "D1=%WORK%\usb-disk1-preflight-0353.txt"
set "D0=%WORK%\windows-disk0-preflight-0353.txt"
set "P1=%WORK%\usb-partitions-preflight-0353.txt"
set "DPSCRIPT=%WORK%\usb-final-format-0353.txt"
set "DPOUT=%WORK%\usb-final-format-out-0353.txt"
set "SAFE=NO"

cls
echo ================================================================
echo WINRE-REPAIR - FINAL USB MEDIA FORMAT
echo Version: %COMMAND_VERSION%
echo Built:   %BUILD_TIME%
echo Fetched: %date% %time%
echo ================================================================
echo.
echo Approved destructive action: finish formatting the verified USB only.
echo Expected current topology:
echo   Disk 0 = internal Windows C:
echo   Disk 1 = USB, currently one RAW removable ~29 GB partition

echo The script will stop unless all checks still match.
echo.

if not exist "%WORK%" md "%WORK%" >nul 2>&1
if not exist "%DISKPART%" goto :FAIL
if not exist "C:\Windows\System32\Config\SYSTEM" goto :FAIL
if exist U:\ goto :LETTERFAIL
if exist V:\ goto :LETTERFAIL

rem Re-prove Disk 1 is the USB and Disk 0 contains Windows C:.
>"%SCAN%" echo select disk 1
>>"%SCAN%" echo detail disk
"%DISKPART%" /s "%SCAN%" >"%D1%" 2>&1

>"%SCAN%" echo select disk 0
>>"%SCAN%" echo detail disk
"%DISKPART%" /s "%SCAN%" >"%D0%" 2>&1

>"%SCAN%" echo select disk 1
>>"%SCAN%" echo list partition
"%DISKPART%" /s "%SCAN%" >"%P1%" 2>&1

rem Disk 1 must explicitly report USB.
"%FINDSTR%" /i /c:"Type" "%D1%" 2>nul | "%FINDSTR%" /i /c:"USB" >nul 2>&1
if errorlevel 1 goto :FAIL

rem Disk 1 must match the partial-format state we just observed: RAW, removable, ~29 GB.
"%FINDSTR%" /i /c:"RAW" "%D1%" >nul 2>&1
if errorlevel 1 goto :FAIL
"%FINDSTR%" /i /c:"Removable" "%D1%" >nul 2>&1
if errorlevel 1 goto :FAIL
"%FINDSTR%" /i /c:"29 GB" "%D1%" >nul 2>&1
if errorlevel 1 goto :FAIL
"%FINDSTR%" /i /c:"Partition 1" "%P1%" >nul 2>&1
if errorlevel 1 goto :FAIL
"%FINDSTR%" /i /c:"29 GB" "%P1%" >nul 2>&1
if errorlevel 1 goto :FAIL

rem Windows C: must still be on Disk 0 and must not appear on Disk 1.
"%FINDSTR%" /i /c:"Volume" "%D0%" 2>nul | "%FINDSTR%" /R /C:"[ ]C[ ]" >nul 2>&1
if errorlevel 1 goto :FAIL
"%FINDSTR%" /i /c:"Volume" "%D1%" 2>nul | "%FINDSTR%" /R /C:"[ ]C[ ]" >nul 2>&1
if not errorlevel 1 goto :FAIL

set "SAFE=YES"
echo ================================================================
echo PREFLIGHT PASSED
echo Disk 1 = verified USB
echo Disk 0 = Windows C: [NOT TOUCHED]
echo ================================================================
echo Finishing USB format now...

rem One DiskPart pass, as recommended for scripted DiskPart operations.
rem Use a conservative 16 GB FAT32 boot partition, then NTFS for the remainder.
>"%DPSCRIPT%" echo select disk 1
>>"%DPSCRIPT%" echo clean
>>"%DPSCRIPT%" echo convert gpt
>>"%DPSCRIPT%" echo create partition primary size=16000
>>"%DPSCRIPT%" echo format fs=fat32 quick label=WIN11MEDIA
>>"%DPSCRIPT%" echo assign letter=U
>>"%DPSCRIPT%" echo create partition primary
>>"%DPSCRIPT%" echo format fs=ntfs quick label=REPAIRDATA
>>"%DPSCRIPT%" echo assign letter=V
>>"%DPSCRIPT%" echo list volume
>>"%DPSCRIPT%" echo detail disk

"%DISKPART%" /s "%DPSCRIPT%" >"%DPOUT%" 2>&1
if errorlevel 1 goto :FORMATFAIL

rem Verify both resulting filesystems and labels from DiskPart output and mounted letters.
if not exist U:\ goto :FORMATFAIL
if not exist V:\ goto :FORMATFAIL
vol U: | "%FINDSTR%" /i /c:"WIN11MEDIA" >nul 2>&1
if errorlevel 1 goto :FORMATFAIL
vol V: | "%FINDSTR%" /i /c:"REPAIRDATA" >nul 2>&1
if errorlevel 1 goto :FORMATFAIL
"%FINDSTR%" /i /c:"WIN11MEDIA" "%DPOUT%" 2>nul | "%FINDSTR%" /i /c:"FAT32" >nul 2>&1
if errorlevel 1 goto :FORMATFAIL
"%FINDSTR%" /i /c:"REPAIRDATA" "%DPOUT%" 2>nul | "%FINDSTR%" /i /c:"NTFS" >nul 2>&1
if errorlevel 1 goto :FORMATFAIL

cls
echo ================================================================
echo USB MEDIA FORMAT COMPLETE
echo Version: %COMMAND_VERSION%
echo ================================================================
echo USB disk             : Disk 1 [USB]
echo Windows disk         : Disk 0 [NOT TOUCHED]
echo Boot partition       : U: WIN11MEDIA FAT32 ~16 GB
echo Repair-data partition: V: REPAIRDATA NTFS remaining space
echo ---------------------------------------------------------------
echo STATUS: READY_FOR_WINDOWS_MEDIA_DOWNLOAD
echo ================================================================
echo You can stop here for the night.
echo Next pass: download/build Windows 11 24H2 repair media files.
exit /b 0

:LETTERFAIL
set "MSG=U: or V: is already in use. Nothing was changed."
goto :FAILMSG

:FORMATFAIL
set "MSG=USB identity was verified, but formatting did not complete."
cls
echo ================================================================
echo USB FORMAT STOPPED
echo %MSG%
echo ================================================================
echo Disk 1 was the verified USB. Disk 0 Windows was not targeted.
echo Relevant DiskPart output:
"%FINDSTR%" /i /c:"error" /c:"failed" /c:"not supported" /c:"too big" /c:"cannot" /c:"could not" /c:"successfully" "%DPOUT%" 2>nul
echo ================================================================
exit /b 91

:FAIL
set "MSG=USB preflight no longer matches the verified topology. Nothing was changed."
:FAILMSG
cls
echo ================================================================
echo USB FORMAT NOT STARTED
echo %MSG%
echo ================================================================
echo Disk 0 remains protected.
echo ================================================================
exit /b 90
