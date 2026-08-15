@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=REPAIR_WRITE
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Confirm command 40 BCD verification evidence, report the planned boot test, then schedule a delayed WinRE reboot so the persistent agent can close command 41 cleanly first.
rem WR_ACTION=CONTROLLED_BOOT_TEST
rem WR_TARGET=Current PC reboot only; no disk, partition, registry, driver, BCD, or personal-file content is changed by this command.
rem WR_CONSEQUENCE=The PC will reboot automatically about 30 seconds after this command completes so Windows can be tested with the freshly rebuilt UEFI BCD store.
rem WR_ROLLBACK=No persistent Windows state is changed by the reboot command. The pre-rebuild BCD backup from command 39 remains available.

set "R=C:\WinRERepair"
set "O=%R%\COMMAND_RESULT.env"
set "A=%R%\runtime\github-auth.cmd"
set "V=%R%\repair40-verify-bcd.txt"
set "F=C:\Windows\System32\findstr.exe"
set "P=X:\Windows\System32\ping.exe"
set "W=X:\Windows\System32\wpeutil.exe"
if not exist "%P%" set "P=ping.exe"
if not exist "%W%" set "W=wpeutil.exe"

if not exist "%V%" goto :BLOCK
for %%S in ("bootmgr_return_code=0" "default_return_code=0" "bootmgr_path=YES" "bootmgr_device_present=YES" "bootmgr_default_present=YES" "default_device_c=YES" "default_osdevice_c=YES" "default_winload_path=YES" "default_systemroot=YES" "winload_file_present=YES") do (
  "%F%" /i /l /x /c:%%S "%V%" >nul 2>&1
  if errorlevel 1 goto :BLOCK
)

>"%R%\LAST_RUN_REPORT.txt" echo status=PASS
>>"%R%\LAST_RUN_REPORT.txt" echo message=Verified fresh UEFI BCD is ready for a controlled Windows boot test.
>"%R%\RUN_DETAILS.txt" echo repair=CONTROLLED_BOOT_TEST_SCHEDULED
>>"%R%\RUN_DETAILS.txt" echo prior_command=40
>>"%R%\RUN_DETAILS.txt" echo bcd_verification=PASS
>>"%R%\RUN_DETAILS.txt" echo reboot_delay_seconds=30
>>"%R%\RUN_DETAILS.txt" echo reboot_method=wpeutil_reboot
if exist "%A%" call "%A%" upload >nul 2>&1

start "" /b "%ComSpec%" /d /c "\"%P%\" 127.0.0.1 -n 31 -w 1000 ^>nul 2^>^&1 ^& \"%W%\" reboot"
if errorlevel 1 goto :BLOCK

>"%O%" echo STATUS=PASS
>>"%O%" echo MESSAGE=Fresh UEFI BCD is verified and a controlled Windows boot test is scheduled in about 30 seconds.
>>"%O%" echo EVIDENCE=Command 40 semantic BCD verification passed; command 39 backup remains available.
>>"%O%" echo INSTRUCTION=Do not press anything. The PC will reboot automatically. If Windows reaches the sign-in screen, tell ChatGPT Windows booted. If Recovery returns, show ChatGPT that screen.
exit /b 0

:BLOCK
>"%R%\LAST_RUN_REPORT.txt" echo status=WARNING
>>"%R%\LAST_RUN_REPORT.txt" echo message=Controlled boot test was blocked because the command 40 verification evidence was missing or inconsistent.
>"%R%\RUN_DETAILS.txt" echo repair=CONTROLLED_BOOT_TEST_BLOCKED
>>"%R%\RUN_DETAILS.txt" echo prior_command=40
>>"%R%\RUN_DETAILS.txt" echo reboot_scheduled=NO
if exist "%A%" call "%A%" upload >nul 2>&1
>"%O%" echo STATUS=WARNING
>>"%O%" echo MESSAGE=Controlled boot test was not scheduled because verification evidence could not be re-confirmed.
>>"%O%" echo EVIDENCE=No reboot was started and no Windows recovery state was changed.
>>"%O%" echo INSTRUCTION=No user action is required. Leave RescueMeAI online for automatic review.
exit /b 0
