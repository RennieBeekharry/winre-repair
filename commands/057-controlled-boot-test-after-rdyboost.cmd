@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=REPAIR_WRITE
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Re-confirm the Command 55 ReadyBoost boot-start repair, upload a pre-reboot checkpoint, then reboot WinRE for a controlled Windows boot test.
rem WR_ACTION=CONTROLLED_BOOT_TEST_AFTER_RDYBOOST
rem WR_TARGET=Current PC reboot only after confirming rdyboost Start=0, the lower-filter entry, driver file, and rollback backup.
rem WR_CONSEQUENCE=Reboots the PC so Windows can be tested with the restored ReadyBoost boot-start configuration. No additional Windows registry, driver, BCD, partition, package, or personal-file content is changed.
rem WR_ROLLBACK=Command 55 backup remains at C:\WinRERepair\backup\rdyboost-before-command55.reg and can be restored if this boot test still returns 0x7B.

set "R=C:\WinRERepair"
set "O=%R%\COMMAND_RESULT.env"
set "A=%R%\runtime\github-auth.cmd"
set "UI=%R%\runtime\ui.cmd"
set "REG=C:\Windows\System32\reg.exe"
set "FS=C:\Windows\System32\findstr.exe"
set "SYS=C:\Windows\System32\config\SYSTEM"
set "BK=%R%\backup\rdyboost-before-command55.reg"
set "W=X:\Windows\System32\wpeutil.exe"
if not exist "%REG%" set "REG=reg.exe"
if not exist "%FS%" set "FS=findstr.exe"
if not exist "%W%" set "W=wpeutil.exe"
if not exist "%SYS%" goto :BLOCK

call :STAGE "1 of 4" "Re-confirming the ReadyBoost Start value before reboot."
"%REG%" unload HKLM\RMAISYS57 >nul 2>&1
"%REG%" load HKLM\RMAISYS57 "%SYS%" >nul 2>&1
if errorlevel 1 goto :BLOCK
set "SVC=HKLM\RMAISYS57\ControlSet001\Services\rdyboost"
set "CLS=HKLM\RMAISYS57\ControlSet001\Control\Class\{71A27CDD-812A-11D0-BEC7-08002BE2092F}"
"%REG%" query "%SVC%" /v Start >"%R%\repair57-start.txt" 2>&1
"%FS%" /i /c:"0x0" "%R%\repair57-start.txt" >nul 2>&1
if errorlevel 1 goto :BLOCK_LOADED

call :STAGE "2 of 4" "Checking the ReadyBoost filter entry, driver file, and rollback backup."
"%REG%" query "%CLS%" /v LowerFilters >"%R%\repair57-filters.txt" 2>&1
"%FS%" /i /c:"rdyboost" "%R%\repair57-filters.txt" >nul 2>&1
if errorlevel 1 goto :BLOCK_LOADED
if not exist C:\Windows\System32\drivers\rdyboost.sys goto :BLOCK_LOADED
if not exist "%BK%" goto :BLOCK_LOADED
"%REG%" unload HKLM\RMAISYS57 >nul 2>&1

call :STAGE "3 of 4" "Uploading the pre-reboot checkpoint so the boot test is fully traceable."
>"%R%\LAST_RUN_REPORT.txt" echo status=PASS
>>"%R%\LAST_RUN_REPORT.txt" echo message=Command 57 verified the ReadyBoost repair and is starting a controlled Windows boot test.
>"%R%\RUN_DETAILS.txt" echo repair=CONTROLLED_BOOT_TEST_AFTER_RDYBOOST
>>"%R%\RUN_DETAILS.txt" echo prior_command=55
>>"%R%\RUN_DETAILS.txt" echo rdyboost_start=0x0
>>"%R%\RUN_DETAILS.txt" echo lowerfilters_rdyboost=YES
>>"%R%\RUN_DETAILS.txt" echo driver_file_present=YES
>>"%R%\RUN_DETAILS.txt" echo rollback_backup=%BK%
>>"%R%\RUN_DETAILS.txt" echo reboot_method=wpeutil_reboot
if exist "%A%" call "%A%" upload >nul 2>&1

call :STAGE "4 of 4" "Starting the controlled Windows boot test now."
>"%O%" echo STATUS=PASS
>>"%O%" echo MESSAGE=Command 57 verified the ReadyBoost repair and is rebooting now for the Windows boot test.
>>"%O%" echo EVIDENCE=rdyboost Start=0, lower-filter entry present, driver present, rollback backup present.
>>"%O%" echo INSTRUCTION=Do not press anything during reboot. If Windows reaches sign-in, tell ChatGPT Windows booted. If 0x7B or Recovery returns, show ChatGPT that screen.
"%W%" reboot
exit /b %errorlevel%

:STAGE
if exist "%UI%" call "%UI%" screen "RMAI-AGENT-V2-2026.08.14-1508-ET" "CONNECTED" "RUNNING COMMAND 57" "CONTROLLED REBOOT" "AI-ASSISTED WINDOWS RECOVERY" "INFO"
echo.
echo COMMAND DETAILS
echo ------------------------------------------------------------------------------------------------
echo Command ID : 57
echo Name       : Controlled Windows boot test after ReadyBoost repair
echo Goal       : Test whether restoring rdyboost Start from 2 to 0 resolves INACCESSIBLE_BOOT_DEVICE.
echo Reboot     : YES - only after all safety checks pass.
echo.
echo RECOVERY ACTIVITY
echo Step %~1
echo %~2
echo.
echo No action is required.
exit /b 0

:BLOCK_LOADED
"%REG%" unload HKLM\RMAISYS57 >nul 2>&1
:BLOCK
>"%R%\LAST_RUN_REPORT.txt" echo status=FAIL
>>"%R%\LAST_RUN_REPORT.txt" echo message=Command 57 blocked the boot test because the ReadyBoost repair could not be re-confirmed safely.
>"%R%\RUN_DETAILS.txt" echo repair=CONTROLLED_BOOT_TEST_AFTER_RDYBOOST_BLOCKED
>>"%R%\RUN_DETAILS.txt" echo reboot_started=NO
if exist "%A%" call "%A%" upload >nul 2>&1
>"%O%" echo STATUS=FAIL
>>"%O%" echo MESSAGE=Command 57 blocked the controlled boot test because a required ReadyBoost verification check failed.
>>"%O%" echo EVIDENCE=No reboot was started and no additional Windows state was changed.
>>"%O%" echo INSTRUCTION=Leave RescueMeAI online for automatic review.
exit /b 90
