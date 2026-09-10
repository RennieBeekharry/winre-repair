@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=REPAIR_WRITE
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Run the prepared separate Safe Mode diagnostic entry for exactly one boot with a persistent one-shot reboot guard.
rem WR_ACTION=ONE_TIME_SAFE_MODE_DIAGNOSTIC_RESTART_GUARDED
rem WR_TARGET=EFI BCD bootsequence for the already-prepared RescueMeAI Safe Mode loader, RescueMeAI state markers, and one restart.
rem WR_CONSEQUENCE=Arms the separate Safe Mode loader for one boot and restarts once. The normal default loader is not modified. A persistent marker suppresses any second reboot if this command is seen again after reconnect.
rem WR_ROLLBACK=Step 76 saved the EFI BCD at C:\RescueMeAI\backups\pre-safemode-step76\BCD. The bootsequence is one-time; the prepared diagnostic loader remains separate.

set "FIX_VERSION=RMAI-FIX-2026.09.10.3"
set "STEP=77"
set "WORK=C:\WinRERepair"
set "STATE=C:\RescueMeAI\state"
set "RESULT=%WORK%\COMMAND_RESULT.env"
set "DETAILS=%WORK%\RUN_DETAILS.txt"
set "GUIDFILE=%STATE%\safemode-step76-guid.txt"
set "REBOOTMARK=%STATE%\reboot-command-77.issued"
set "TESTMARK=%STATE%\safemode-test-77.started"
set "MOUNTVOL=X:\Windows\System32\mountvol.exe"
if not exist "%MOUNTVOL%" set "MOUNTVOL=C:\Windows\System32\mountvol.exe"
set "BCDEDIT=X:\Windows\System32\bcdedit.exe"
if not exist "%BCDEDIT%" set "BCDEDIT=C:\Windows\System32\bcdedit.exe"
set "WPE=X:\Windows\System32\wpeutil.exe"
if not exist "%WPE%" set "WPE=wpeutil.exe"
set "PING=X:\Windows\System32\ping.exe"
if not exist "%PING%" set "PING=C:\Windows\System32\ping.exe"

cls
echo ================================================================================
echo RescueMeAI - ONE-TIME SAFE MODE DIAGNOSTIC
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : PRE-FLIGHT CHECK
echo CURRENT TASK        : Boot the prepared Safe Mode Minimal loader exactly once.
echo SAFETY              : REPAIR-WRITE - ONE-TIME BOOTSEQUENCE + ONE RESTART.
echo ONE-SHOT GUARD      : REQUIRED AND PERSISTENT ACROSS RECONNECTS.
echo NORMAL DEFAULT BOOT : NOT CHANGED
echo PERSONAL FILES      : NOT TOUCHED
echo REBOOT              : ONE ONLY
echo WHAT YOU SHOULD DO  : WATCH THE SCREEN.
echo SCREENSHOT REQUIRED : ONLY for Recovery, blue screen, or unexpected error.
echo ================================================================================

if not exist "%STATE%" md "%STATE%" >nul 2>&1
if exist "%REBOOTMARK%" goto :ALREADY
if not exist "%GUIDFILE%" goto :BLOCK
if not exist "C:\RescueMeAI\backups\pre-safemode-step76\BCD" goto :BLOCK
if not exist "C:\Windows\System32\config\SYSTEM" goto :BLOCK
if not exist "C:\r.cmd" goto :BLOCK

set "SAFEGUID="
set /p "SAFEGUID="<"%GUIDFILE%"
if not defined SAFEGUID goto :BLOCK
if not "!SAFEGUID:~0,1!"=="{" goto :BLOCK
if not "!SAFEGUID:~-1!"=="}" goto :BLOCK

>"%DETAILS%" echo RESCUEMEAI GUARDED ONE-TIME SAFE MODE DIAGNOSTIC
>>"%DETAILS%" echo fix_version=%FIX_VERSION%
>>"%DETAILS%" echo step=%STEP%
>>"%DETAILS%" echo safe_mode_entry=!SAFEGUID!

echo [1/4] Verifying prepared Safe Mode entry and return path...
set "PROFILE="
for %%D in (D E F G H I J K L M N O P Q R S T U V W Y Z) do if not defined PROFILE if exist "%%D:\Wi-Fi-404 Network Unavailable.xml" set "PROFILE=%%D:\Wi-Fi-404 Network Unavailable.xml"
if not defined PROFILE goto :BLOCK
>>"%DETAILS%" echo wifi_profile=!PROFILE!

echo [2/4] Mounting EFI and arming this diagnostic entry for one boot...
set "SYS=S:"
if exist S:\nul set "SYS=T:"
if exist T:\nul if "!SYS!"=="T:" set "SYS=U:"
"%MOUNTVOL%" !SYS! /S >"%WORK%\step77-mount.txt" 2>&1
if errorlevel 1 goto :BLOCK
set "MOUNTED=YES"
set "BCD=!SYS!\EFI\Microsoft\Boot\BCD"
if not exist "!BCD!" goto :BLOCK_MOUNTED
"%BCDEDIT%" /store "!BCD!" /enum !SAFEGUID! >"%WORK%\step77-safe-entry.txt" 2>&1
if errorlevel 1 goto :BLOCK_MOUNTED
"%BCDEDIT%" /store "!BCD!" /bootsequence !SAFEGUID! >"%WORK%\step77-bootsequence.txt" 2>&1
if errorlevel 1 goto :BLOCK_MOUNTED
"%MOUNTVOL%" !SYS! /D >nul 2>&1
set "MOUNTED=NO"

echo [3/4] Writing persistent one-shot reboot guard BEFORE restart...
>"%REBOOTMARK%" echo status=ISSUED
>>"%REBOOTMARK%" echo command_id=77
>>"%REBOOTMARK%" echo guard=ONE_SHOT_PERSISTENT
>>"%REBOOTMARK%" echo safe_mode_entry=!SAFEGUID!
>"%TESTMARK%" echo status=STARTING
>>"%TESTMARK%" echo fix_version=%FIX_VERSION%
>>"%TESTMARK%" echo safe_mode_entry=!SAFEGUID!
>>"%DETAILS%" echo reboot_guard=ACTIVE
>>"%DETAILS%" echo normal_default_loader_changed=NO
>>"%DETAILS%" echo personal_files_targeted=NO

echo [4/4] Starting the single approved Safe Mode restart...
>"%RESULT%" echo STATUS=PASS
>>"%RESULT%" echo MESSAGE=One-time guarded Safe Mode diagnostic restart is starting.
>>"%RESULT%" echo EVIDENCE=Separate Safe Mode loader verified; one-time bootsequence armed; persistent reboot guard written before restart.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=CONDITIONAL

echo.
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : RESTARTING ONCE INTO SAFE MODE
echo ONE-SHOT GUARD      : ACTIVE - A SECOND STEP 77 REBOOT IS BLOCKED
echo NORMAL DEFAULT BOOT : UNCHANGED
echo IF BITLOCKER APPEARS: Enter the recovery key locally.
echo IF SAFE MODE BOOTS  : Reply SUCCESS and send a photo if convenient.
echo IF HP SPINNER HANGS : Wait 5 minutes, then reply STUCK.
echo IF RECOVERY/ERROR   : Reply FAILED and send a photo.
echo IMPORTANT           : After a failed boot, WAIT for ChatGPT before C:\r.cmd.
echo ================================================================================
"%PING%" -n 11 127.0.0.1 >nul 2>&1
"%WPE%" reboot
set "RRC=!errorlevel!"

>"%RESULT%" echo STATUS=FAIL
>>"%RESULT%" echo MESSAGE=The guarded Safe Mode restart command returned instead of restarting.
>>"%RESULT%" echo EVIDENCE=wpeutil reboot exit code !RRC!; persistent guard remains active.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=YES
echo STATUS              : RESTART DID NOT START
echo ONE-SHOT GUARD      : ACTIVE
echo SCREENSHOT REQUIRED : YES
echo WHAT YOU SHOULD DO  : Reply FAILED and send a photo. Do not reboot manually.
exit /b 90

:ALREADY
>"%RESULT%" echo STATUS=WARNING
>>"%RESULT%" echo MESSAGE=Persistent one-shot guard suppressed a repeated Step 77 reboot.
>>"%RESULT%" echo EVIDENCE=The reboot marker already exists; no BCD bootsequence was re-armed and no reboot was issued.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=NO
echo.
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : REPEATED REBOOT SUPPRESSED
echo REBOOT              : NO
echo WHAT YOU SHOULD DO  : WAIT for ChatGPT review.
echo SCREENSHOT REQUIRED : NO
echo ================================================================================
exit /b 40

:BLOCK_MOUNTED
if /i "!MOUNTED!"=="YES" "%MOUNTVOL%" !SYS! /D >nul 2>&1
set "MOUNTED=NO"
:BLOCK
>"%RESULT%" echo STATUS=WARNING
>>"%RESULT%" echo MESSAGE=Safe Mode diagnostic restart was blocked by a pre-flight prerequisite.
>>"%RESULT%" echo EVIDENCE=No reboot was issued; normal default loader and personal files were not changed.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=YES
echo.
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : SAFE MODE TEST BLOCKED
echo REBOOT              : NO
echo SCREENSHOT REQUIRED : YES
echo WHAT YOU SHOULD DO  : Reply FAILED and send a photo. Do not reboot manually.
echo ================================================================================
exit /b 40
