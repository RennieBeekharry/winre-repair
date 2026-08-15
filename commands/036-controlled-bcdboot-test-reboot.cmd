@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=REPAIR_WRITE
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Wait for the recovery USB to be removed, detect removal automatically, then perform the controlled reboot test after BCDBoot repair.
rem WR_ACTION=AUTO_DETECT_USB_REMOVAL_AND_REBOOT
rem WR_TARGET=Recovery USB presence detection and system reboot only; no additional Windows configuration changes.
rem WR_CONSEQUENCE=Waits safely while recovery media is attached, then reboots the computer so the internal Windows installation attempts to start with the refreshed UEFI boot files.
rem WR_ROLLBACK=BCD backup remains at C:\WinRERepair\BCD.before-bcdboot.bak. No additional repair writes occur in this command.

set "R=C:\WinRERepair"
set "O=%R%\COMMAND_RESULT.env"
set "A=%R%\runtime\github-auth.cmd"
set "WAITCOUNT=0"
set "MAXWAIT=450"

cls
color 0E >nul 2>&1
echo ====================================================================================================
echo                                           RESCUEMEAI
echo                                  LOCAL ACTION REQUIRED
echo ====================================================================================================
echo.
echo Windows UEFI boot files were refreshed successfully.
echo.
echo WHAT YOU NEED TO DO
echo ----------------------------------------------------------------------------------------------------
echo   Physically remove the RescueMeAI / Windows recovery USB from this PC.
echo.
echo   DO NOT type pass, fail, or warning.
echo   DO NOT reboot the computer yourself.
echo.
echo WHAT HAPPENS NEXT
echo ----------------------------------------------------------------------------------------------------
echo   RescueMeAI is watching for the recovery USB to disappear.
echo   As soon as removal is verified, RescueMeAI will continue automatically and reboot the PC.
echo.
echo PLEASE REMOVE THE RECOVERY USB NOW.
echo.

:WAIT_USB
call :USB_PRESENT
if errorlevel 1 goto :USB_STILL_PRESENT
goto :USB_REMOVED

:USB_STILL_PRESENT
set /a WAITCOUNT+=1
if !WAITCOUNT! GEQ %MAXWAIT% goto :WAIT_TIMEOUT
<nul set /p "=Waiting for USB removal...                                              `r"
timeout /t 2 /nobreak >nul
goto :WAIT_USB

:USB_REMOVED
cls
color 0B >nul 2>&1
echo ====================================================================================================
echo                                           RESCUEMEAI
echo                                    CONTROLLED BOOT TEST
echo ====================================================================================================
echo.
echo Recovery USB removal: VERIFIED
echo BCDBoot repair       : VERIFIED PASS
echo Windows changes      : NONE ADDITIONAL
echo.
echo RescueMeAI will reboot automatically in a few seconds.
echo The internal Windows installation will be tested with the refreshed UEFI boot files.
echo.
echo PLEASE WAIT - no action is required.
echo.

>"%R%\LAST_RUN_REPORT.txt" echo status=PASS
>>"%R%\LAST_RUN_REPORT.txt" echo message=Recovery USB removal was detected automatically; controlled post-BCDBoot boot test is starting.
>"%R%\RUN_DETAILS.txt" echo transition=AUTO_DETECT_USB_REMOVAL_AND_REBOOT
>>"%R%\RUN_DETAILS.txt" echo recovery_usb=REMOVED_VERIFIED
>>"%R%\RUN_DETAILS.txt" echo windows_changes=NONE_ADDITIONAL
>>"%R%\RUN_DETAILS.txt" echo bcd_backup=C:\WinRERepair\BCD.before-bcdboot.bak
if exist "%A%" call "%A%" upload >nul 2>&1

timeout /t 4 /nobreak >nul
wpeutil reboot
shutdown /r /t 0
exit /b 0

:WAIT_TIMEOUT
>"%O%" echo STATUS=WARNING
>>"%O%" echo MESSAGE=RescueMeAI did not detect removal of the recovery USB within the automatic waiting period.
>>"%O%" echo EVIDENCE=No reboot occurred and no additional Windows changes were made.
>>"%O%" echo INSTRUCTION=Leave RescueMeAI running. A screenshot is only needed if the recovery USB has definitely been removed but this message remains.
exit /b 0

:USB_PRESENT
for %%D in (D E F G H I J K L M N O P Q R S T U V W Y Z) do (
  if exist "%%D:\RescueMeAI\Media\." exit /b 1
  vol %%D: 2>nul | findstr /i /c:"REPAIRDATA" /c:"WIN11MEDIA" >nul 2>&1
  if not errorlevel 1 exit /b 1
)
exit /b 0
