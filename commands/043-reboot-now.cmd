@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=REPAIR_WRITE
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Re-confirm the successful command 40 BCD verification evidence, upload a pre-reboot record, and reboot WinRE immediately for the controlled Windows boot test.
rem WR_ACTION=CONTROLLED_REBOOT_NOW
rem WR_TARGET=Current PC reboot only; no disk, partition, registry, driver, BCD, or personal-file content is changed by this command.
rem WR_CONSEQUENCE=The PC will reboot immediately so Windows can be tested with the freshly rebuilt and verified UEFI BCD store.
rem WR_ROLLBACK=No persistent Windows state is changed by this reboot command. The pre-rebuild BCD backup from command 39 remains available.

set "R=C:\WinRERepair"
set "O=%R%\COMMAND_RESULT.env"
set "A=%R%\runtime\github-auth.cmd"
set "V=%R%\repair40-verify-bcd.txt"
set "F=C:\Windows\System32\findstr.exe"
set "W=X:\Windows\System32\wpeutil.exe"
if not exist "%W%" set "W=wpeutil.exe"

if not exist "%V%" goto :BLOCK
for %%S in ("bootmgr_return_code=0" "default_return_code=0" "bootmgr_path=YES" "bootmgr_device_present=YES" "bootmgr_default_present=YES" "default_device_c=YES" "default_osdevice_c=YES" "default_winload_path=YES" "default_systemroot=YES" "winload_file_present=YES") do (
  "%F%" /i /l /x /c:%%S "%V%" >nul 2>&1
  if errorlevel 1 goto :BLOCK
)

>"%R%\LAST_RUN_REPORT.txt" echo status=PASS
>>"%R%\LAST_RUN_REPORT.txt" echo message=Controlled reboot is starting now to test Windows with the verified fresh UEFI BCD store.
>"%R%\RUN_DETAILS.txt" echo repair=CONTROLLED_REBOOT_NOW
>>"%R%\RUN_DETAILS.txt" echo prior_command=40
>>"%R%\RUN_DETAILS.txt" echo bcd_verification=PASS
>>"%R%\RUN_DETAILS.txt" echo reboot_method=wpeutil_reboot
if exist "%A%" call "%A%" upload >nul 2>&1

>"%O%" echo STATUS=PASS
>>"%O%" echo MESSAGE=Controlled Windows boot test is starting now.
>>"%O%" echo EVIDENCE=Fresh UEFI BCD semantic verification passed and the pre-rebuild BCD backup remains available.
>>"%O%" echo INSTRUCTION=Do not press anything while the PC reboots. If Windows reaches sign-in, tell ChatGPT Windows booted. If Recovery returns, show ChatGPT that screen.

"%W%" reboot
exit /b %errorlevel%

:BLOCK
>"%R%\LAST_RUN_REPORT.txt" echo status=WARNING
>>"%R%\LAST_RUN_REPORT.txt" echo message=Immediate reboot was blocked because command 40 verification evidence could not be re-confirmed.
>"%R%\RUN_DETAILS.txt" echo repair=CONTROLLED_REBOOT_BLOCKED
>>"%R%\RUN_DETAILS.txt" echo reboot_started=NO
if exist "%A%" call "%A%" upload >nul 2>&1
>"%O%" echo STATUS=WARNING
>>"%O%" echo MESSAGE=Controlled reboot was not started because BCD verification evidence is missing or inconsistent.
>>"%O%" echo EVIDENCE=No reboot was started and no Windows recovery state was changed.
>>"%O%" echo INSTRUCTION=No user action is required. Leave RescueMeAI online for automatic review.
exit /b 0
