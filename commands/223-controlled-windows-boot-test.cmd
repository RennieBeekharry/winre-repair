@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=REPAIR_WRITE
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Perform a controlled reboot after the clean post-SFC verification so Windows startup can be tested.
rem WR_ACTION=CONTROLLED_WINDOWS_BOOT_TEST
rem WR_TARGET=Current computer restart only; Windows boot configuration is checked but not changed.
rem WR_CONSEQUENCE=The computer will restart, the RescueMeAI WinRE connection will close, and Windows will attempt a normal startup.
rem WR_ROLLBACK=The reboot itself makes no persistent Windows configuration change; pre-SFC boot-file safety copies remain on C:.

set "WORK=C:\WinRERepair"
set "STATE=C:\RescueMeAI\state"
set "RESULT=%WORK%\COMMAND_RESULT.env"
set "DETAILS=%WORK%\RUN_DETAILS.txt"
set "BCD=%WORK%\boot-test-bcd.txt"
set "BCDEDIT=X:\Windows\System32\bcdedit.exe"
if not exist "%BCDEDIT%" set "BCDEDIT=C:\Windows\System32\bcdedit.exe"
set "WPE=X:\Windows\System32\wpeutil.exe"
if not exist "%WPE%" set "WPE=wpeutil.exe"
set "PING=X:\Windows\System32\ping.exe"
if not exist "%PING%" set "PING=C:\Windows\System32\ping.exe"
if not exist "%STATE%" md "%STATE%" >nul 2>&1

cls
echo ================================================================================
echo RescueMeAI - CONTROLLED WINDOWS BOOT TEST
echo ================================================================================
echo STATUS            : PREPARING REBOOT
echo CURRENT DIAGNOSIS : Offline SFC completed successfully and the follow-up
echo                     verification found no remaining protected-file errors.
echo CURRENT TASK      : Re-checking boot prerequisites, then restarting into Windows.
echo SAFETY            : REPAIR-WRITE - REBOOT ONLY; no boot settings are being changed.
echo PERSONAL FILES    : NOT TOUCHED
echo SCREENSHOT NEEDED : AFTER REBOOT ONLY IF Windows Recovery or an error returns.
echo ================================================================================
echo.

>"%DETAILS%" echo RESCUEMEAI CONTROLLED WINDOWS BOOT TEST

echo [1/4] Re-checking the Windows target and boot binaries...
if not exist "C:\Windows\System32\config\SYSTEM" goto :BLOCK
if not exist "C:\Windows\System32\winload.efi" goto :BLOCK
if not exist "C:\Windows\System32\winresume.efi" goto :BLOCK
>>"%DETAILS%" echo windows_target=PASS
>>"%DETAILS%" echo key_boot_files=PASS

echo [2/4] Re-checking the active Windows boot entry...
"%BCDEDIT%" /enum {default} >"%BCD%" 2>&1
if errorlevel 1 goto :BLOCK
findstr /i /c:"\Windows\system32\winload.efi" "%BCD%" >nul 2>&1
if errorlevel 1 goto :BLOCK
set "PARTC=0"
for /f "delims=" %%N in ('findstr /i /c:"partition=C:" "%BCD%" ^| find /c /v ""') do set "PARTC=%%N"
if !PARTC! LSS 2 goto :BLOCK
>>"%DETAILS%" echo bcd_default_entry=PASS
>>"%DETAILS%" echo bcd_partition_c_lines=!PARTC!

echo [3/4] Writing a local boot-test marker...
>"%STATE%\boot-test-27.pending" echo status=STARTING
>>"%STATE%\boot-test-27.pending" echo reason=post_sfc_verification_clean
>>"%STATE%\boot-test-27.pending" echo prior_command=26
>>"%DETAILS%" echo boot_test_marker=C:\RescueMeAI\state\boot-test-27.pending

echo [4/4] Starting the controlled reboot...
echo.
echo ================================================================================
echo STATUS            : READY - REBOOTING INTO WINDOWS
echo EXPECTED RESULT   : Windows should continue to the normal sign-in screen.
echo WHAT TO DO NEXT   : Do not press any keys during startup.
echo.
echo IF WINDOWS BOOTS  : Tell ChatGPT: Windows booted.
echo IF RECOVERY/ERROR : Send ChatGPT a photo of THAT screen.
echo SCREENSHOT NEEDED : ONLY IF Recovery or another boot error appears.
echo ================================================================================
echo.
echo Rebooting in about 8 seconds...
"%PING%" -n 9 127.0.0.1 >nul 2>&1

>"%RESULT%" echo STATUS=PASS
>>"%RESULT%" echo MESSAGE=Controlled Windows boot test is starting now after clean post-SFC verification.
>>"%RESULT%" echo EVIDENCE=Windows target, key boot files, and default BCD entry were re-checked immediately before reboot.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=CONDITIONAL
>>"%RESULT%" echo NEXT_STEP=If Windows boots, tell ChatGPT. If Recovery or an error returns, send a photo of that screen.

"%WPE%" reboot
set "RRC=!errorlevel!"

>"%RESULT%" echo STATUS=FAIL
>>"%RESULT%" echo MESSAGE=The controlled reboot command returned instead of restarting the computer.
>>"%RESULT%" echo EVIDENCE=wpeutil reboot exit code !RRC!.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=YES
echo.
echo ================================================================================
echo STATUS            : REBOOT DID NOT START
echo EXIT CODE         : !RRC!
echo SCREENSHOT NEEDED : YES
echo WHAT TO DO        : Send ChatGPT a photo of THIS screen.
echo ================================================================================
exit /b 90

:BLOCK
>"%RESULT%" echo STATUS=WARNING
>>"%RESULT%" echo MESSAGE=Controlled reboot was blocked because a boot prerequisite did not re-validate.
>>"%RESULT%" echo EVIDENCE=No reboot was started and no boot configuration was changed.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=YES
echo.
echo ================================================================================
echo STATUS            : REBOOT BLOCKED
echo WINDOWS CHANGES   : NONE
echo SCREENSHOT NEEDED : YES
echo WHAT TO DO        : Send ChatGPT a photo of THIS screen. Do not reboot manually.
echo ================================================================================
exit /b 40
