@echo off
setlocal EnableExtensions
rem WR_RISK=REPAIR_WRITE
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Perform the controlled reboot test after the reversible Microsoft storahci boot configuration was staged and the recovery USB was removed.
rem WR_ACTION=CONTROLLED_BOOT_TEST_REBOOT
rem WR_TARGET=System reboot only; no additional Windows configuration changes.
rem WR_CONSEQUENCE=Stops the WinRE recovery session and reboots the computer so the internal Windows installation attempts to start with the already-staged storahci configuration.
rem WR_ROLLBACK=If Windows still fails to boot, return to WinRE and restore the saved iaStorA binding or C:\WinRERepair\SYSTEM.before-storahci-test.hiv.

set "R=C:\WinRERepair"
set "A=%R%\runtime\github-auth.cmd"

>"%R%\LAST_RUN_REPORT.txt" echo status=PASS
>>"%R%\LAST_RUN_REPORT.txt" echo message=Controlled storahci boot test reboot is starting now.
>"%R%\RUN_DETAILS.txt" echo transition=CONTROLLED_BOOT_TEST_REBOOT
>>"%R%\RUN_DETAILS.txt" echo windows_changes=NONE_ADDITIONAL
>>"%R%\RUN_DETAILS.txt" echo staged_driver=storahci
>>"%R%\RUN_DETAILS.txt" echo rollback=C:\WinRERepair\SYSTEM.before-storahci-test.hiv
if exist "%A%" call "%A%" upload >nul 2>&1

cls
echo ==============================================================================
echo                              RESCUEMEAI
echo                        CONTROLLED BOOT TEST
echo ==============================================================================
echo.
echo The reversible Microsoft storahci boot configuration is staged.
echo The recovery USB has been removed.
echo.
echo RescueMeAI is rebooting the PC now.
echo No additional repair changes are being made during this step.
echo.
echo NEXT:
echo   - If Windows starts normally, sign in and tell ChatGPT: BOOTED.
echo   - If Windows fails again, note the exact error and return to recovery.
echo     The previous Intel iaStorA configuration can be restored.
echo.
echo PLEASE WAIT - rebooting...
timeout /t 4 /nobreak >nul
wpeutil reboot
shutdown /r /t 0
exit /b 0
