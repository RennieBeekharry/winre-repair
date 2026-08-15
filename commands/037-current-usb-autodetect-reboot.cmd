@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=REPAIR_WRITE
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Wait for the known REPAIRDATA recovery USB partition to disappear, then reboot automatically for the post-BCDBoot boot test.
rem WR_ACTION=AUTO_DETECT_CURRENT_RECOVERY_USB_AND_REBOOT
rem WR_TARGET=Current recovery USB presence check and system reboot only; no additional Windows configuration changes.
rem WR_CONSEQUENCE=Waits while F:\RescueMeAI\Media is present. After removal is verified, reboots to test the internal Windows installation.
rem WR_ROLLBACK=BCD backup remains at C:\WinRERepair\BCD.before-bcdboot.bak. No additional repair writes occur in this command.

set "R=C:\WinRERepair"
set "O=%R%\COMMAND_RESULT.env"
set "A=%R%\runtime\github-auth.cmd"

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
echo   Do NOT type pass, fail, or warning.
echo   Do NOT reboot the computer yourself.
echo.
echo WHAT HAPPENS NEXT
echo ----------------------------------------------------------------------------------------------------
echo   RescueMeAI will detect removal automatically.
echo   After removal is verified, the PC will reboot automatically.
echo.

:WAIT_USB
if not exist "F:\RescueMeAI\Media\." goto :USB_REMOVED
echo PLEASE REMOVE THE RECOVERY USB. RescueMeAI is waiting...
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
echo RescueMeAI will reboot automatically in 4 seconds.
echo PLEASE WAIT - no action is required.
echo.

>"%R%\LAST_RUN_REPORT.txt" echo status=PASS
>>"%R%\LAST_RUN_REPORT.txt" echo message=Recovery USB removal verified; controlled post-BCDBoot boot test is starting.
>"%R%\RUN_DETAILS.txt" echo transition=AUTO_DETECT_CURRENT_RECOVERY_USB_AND_REBOOT
>>"%R%\RUN_DETAILS.txt" echo recovery_usb=REMOVED_VERIFIED
>>"%R%\RUN_DETAILS.txt" echo windows_changes=NONE_ADDITIONAL
>>"%R%\RUN_DETAILS.txt" echo bcd_backup=C:\WinRERepair\BCD.before-bcdboot.bak
if exist "%A%" call "%A%" upload >nul 2>&1

timeout /t 4 /nobreak >nul
wpeutil reboot
shutdown /r /t 0
exit /b 0
