@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=REPAIR_WRITE
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Perform a controlled Windows boot test after correcting the reconnect-helper preflight path.
rem WR_ACTION=CONTROLLED_WINDOWS_BOOT_TEST_AFTER_PREFLIGHT_FIX
rem WR_TARGET=Current computer restart only; prerequisites are checked immediately before restart.
rem WR_CONSEQUENCE=The computer restarts and Windows attempts normal startup. No BCD entry, EFI file, registry setting, update package, partition, or personal file is changed by this command.
rem WR_ROLLBACK=The restart itself makes no persistent configuration change; EFI and BCD safety copies remain retained locally.

set "FIX_VERSION=RMAI-FIX-2026.09.10.3"
set "STEP=50"
set "WORK=C:\WinRERepair"
set "STATE=C:\RescueMeAI\state"
set "RESULT=%WORK%\COMMAND_RESULT.env"
set "DETAILS=%WORK%\RUN_DETAILS.txt"
set "BCD=%WORK%\step50-bcd.txt"
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
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : PRE-FLIGHT CHECK
echo CURRENT DIAGNOSIS   : The EFI boot manager was stale and has been replaced
echo                       from the verified C:\Windows copy and re-verified.
echo PREVIOUS BLOCK      : Step 49 checked the wrong reconnect-v3 filename.
echo CURRENT TASK        : Re-running corrected pre-flight checks, then normal startup.
echo SAFETY              : RESTART ONLY - no boot settings or personal files changed.
echo BITLOCKER           : A recovery-key prompt may appear after this EFI repair.
echo WHAT YOU SHOULD DO  : WATCH THE SCREEN. Do not press keys during normal startup.
echo SCREENSHOT REQUIRED : ONLY if Recovery, blue screen, or another error appears.
echo ================================================================================

>"%DETAILS%" echo RESCUEMEAI CONTROLLED BOOT TEST AFTER PREFLIGHT FIX
>>"%DETAILS%" echo fix_version=%FIX_VERSION%
>>"%DETAILS%" echo step=%STEP%
>>"%DETAILS%" echo prior_step49_block_reason=incorrect_reconnect_filename_check

echo [1/4] Verifying Windows and the permanent reconnect helper...
if not exist "C:\Windows\System32\config\SYSTEM" goto :BLOCK_WINDOWS
if not exist "C:\Windows\System32\winload.efi" goto :BLOCK_WINDOWS
if not exist "C:\Windows\Boot\EFI\bootmgfw.efi" goto :BLOCK_WINDOWS
if not exist "C:\r.cmd" goto :BLOCK_RECONNECT
if not exist "C:\RescueMeAI\reconnect.cmd" goto :BLOCK_RECONNECT
>>"%DETAILS%" echo windows_target=PASS
>>"%DETAILS%" echo reconnect_v3=PASS

echo [2/4] Checking Wi-Fi recovery fallback...
set "PROFILE=NO"
for %%D in (E F G H I J K L M) do if exist "%%D:\Wi-Fi-404 Network Unavailable.xml" set "PROFILE=YES"
if /i "!PROFILE!"=="YES" (
  >>"%DETAILS%" echo wifi_recovery_profile=PASS
) else (
  >>"%DETAILS%" echo wifi_recovery_profile=ADVISORY_NOT_PRESENT
)
echo       Wi-Fi fallback profile: !PROFILE!

echo [3/4] Re-checking the active Windows boot entry...
"%BCDEDIT%" /enum {default} >"%BCD%" 2>&1
if errorlevel 1 goto :BLOCK_BCD
findstr /i /c:"\Windows\system32\winload.efi" "%BCD%" >nul 2>&1
if errorlevel 1 goto :BLOCK_BCD
set "PARTC=0"
for /f "delims=" %%N in ('findstr /i /c:"partition=C:" "%BCD%" ^| find /c /v ""') do set "PARTC=%%N"
if !PARTC! LSS 2 goto :BLOCK_BCD
>>"%DETAILS%" echo bcd_default_entry=PASS
>>"%DETAILS%" echo bcd_partition_c_lines=!PARTC!

echo [4/4] Marking the test and starting the controlled restart...
>"%STATE%\boot-test-50.pending" echo status=STARTING
>>"%STATE%\boot-test-50.pending" echo fix_version=%FIX_VERSION%
>>"%STATE%\boot-test-50.pending" echo reason=verified_efi_boot_manager_refresh_after_corrected_preflight
>>"%DETAILS%" echo boot_test_marker=C:\RescueMeAI\state\boot-test-50.pending

>"%RESULT%" echo STATUS=PASS
>>"%RESULT%" echo MESSAGE=Controlled Windows boot test is starting after corrected pre-flight validation.
>>"%RESULT%" echo EVIDENCE=Windows target, permanent reconnect helper, and active BCD entry passed corrected checks; Wi-Fi fallback presence was recorded as advisory.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=CONDITIONAL
>>"%RESULT%" echo NEXT_STEP=If Windows boots, reply SUCCESS. If BitLocker appears, enter the recovery key locally. If Recovery or an error returns, send a photo; once at CMD use C:\r.cmd.

echo.
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : READY - RESTARTING INTO WINDOWS
echo QUICK RECONNECT     : C:\r.cmd
echo EXPECTED RESULT     : Normal Windows sign-in screen or desktop.
echo IF BITLOCKER APPEARS: Enter the 48-digit recovery key locally; do not send it.
echo IF WINDOWS BOOTS    : Reply SUCCESS.
echo IF RECOVERY/ERROR   : Reply FAILED and send a photo.
echo IF HP SPINNER HANGS : Wait 10 minutes, then reply STUCK with a photo.
echo ================================================================================
echo Rebooting in about 10 seconds...
"%PING%" -n 11 127.0.0.1 >nul 2>&1
"%WPE%" reboot
set "RRC=!errorlevel!"
>"%RESULT%" echo STATUS=FAIL
>>"%RESULT%" echo MESSAGE=The controlled restart command returned instead of restarting.
>>"%RESULT%" echo EVIDENCE=wpeutil reboot exit code !RRC!.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=YES
echo STATUS              : RESTART DID NOT START
echo SCREENSHOT REQUIRED : YES
echo WHAT YOU SHOULD DO  : Reply FAILED and send a photo.
exit /b 90

:BLOCK_WINDOWS
set "BLOCK_REASON=WINDOWS_PREREQUISITE_MISSING"
goto :BLOCK
:BLOCK_RECONNECT
set "BLOCK_REASON=RECONNECT_HELPER_MISSING"
goto :BLOCK
:BLOCK_BCD
set "BLOCK_REASON=BCD_PREREQUISITE_FAILED"
goto :BLOCK

:BLOCK
>"%RESULT%" echo STATUS=WARNING
>>"%RESULT%" echo MESSAGE=Controlled boot test was blocked because a corrected pre-flight prerequisite did not validate.
>>"%RESULT%" echo EVIDENCE=block_reason=!BLOCK_REASON!; no restart was started and no boot configuration or personal file was changed.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=YES
>>"%DETAILS%" echo block_reason=!BLOCK_REASON!
echo.
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : BOOT TEST BLOCKED
echo BLOCK REASON        : !BLOCK_REASON!
echo REBOOT              : NO
echo SCREENSHOT REQUIRED : YES
echo WHAT YOU SHOULD DO  : Reply FAILED and send a photo. Do not reboot manually.
echo ================================================================================
exit /b 40
