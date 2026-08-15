@echo off
setlocal EnableExtensions
rem WR_RISK=REPAIR_WRITE
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Perform the controlled reboot test after BCDBoot successfully refreshed the firmware-selected Windows UEFI boot environment.
rem WR_ACTION=CONTROLLED_BCDBOOT_TEST_REBOOT
rem WR_TARGET=System reboot only; no additional Windows configuration changes.
rem WR_CONSEQUENCE=Stops the WinRE recovery session and reboots the computer so the internal Windows installation attempts to start with the refreshed UEFI boot files.
rem WR_ROLLBACK=BCD backup remains at C:\WinRERepair\BCD.before-bcdboot.bak. No additional repair writes occur in this command.

set "R=C:\WinRERepair"
set "A=%R%\runtime\github-auth.cmd"

>"%R%\LAST_RUN_REPORT.txt" echo status=PASS
>>"%R%\LAST_RUN_REPORT.txt" echo message=Controlled post-BCDBoot boot test is starting now.
>"%R%\RUN_DETAILS.txt" echo transition=CONTROLLED_BCDBOOT_TEST_REBOOT
>>"%R%\RUN_DETAILS.txt" echo windows_changes=NONE_ADDITIONAL
>>"%R%\RUN_DETAILS.txt" echo bcd_backup=C:\WinRERepair\BCD.before-bcdboot.bak
if exist "%A%" call "%A%" upload >nul 2>&1

cls
echo ==============================================================================
echo                              RESCUEMEAI
echo                    CONTROLLED UEFI BOOT TEST
echo ==============================================================================
echo.
echo Windows UEFI boot files were refreshed successfully with BCDBoot.
echo The recovery USB must already be removed before this command runs.
echo.
echo RescueMeAI is rebooting the PC now.
echo No additional repair changes are being made during this step.
echo.
echo NEXT:
echo   - If Windows starts normally, sign in and tell ChatGPT: BOOTED.
echo   - If Windows fails again, photograph the exact error and return to recovery.
echo.
echo PLEASE WAIT - rebooting...
timeout /t 4 /nobreak >nul
wpeutil reboot
shutdown /r /t 0
exit /b 0
