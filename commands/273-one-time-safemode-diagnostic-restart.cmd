@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=REPAIR_WRITE
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Arm the prepared separate Safe Mode diagnostic entry for exactly one boot and restart once, protected by a persistent one-shot reboot marker.
rem WR_ACTION=ONE_TIME_SAFE_MODE_DIAGNOSTIC_RESTART
rem WR_TARGET=EFI BCD bootsequence for the prepared RescueMeAI diagnostic loader, RescueMeAI one-shot reboot markers, and one computer restart.
rem WR_CONSEQUENCE=Sets a one-time bootsequence to the already-prepared Safe Mode diagnostic loader and restarts once. The normal default Windows loader remains unchanged. A persistent local guard prevents this same command from issuing a second reboot after reconnect.
rem WR_ROLLBACK=The Step 76 EFI BCD backup remains at C:\RescueMeAI\backups\pre-safemode-step76\BCD. The bootsequence is one-time; the diagnostic entry remains separate from the normal default loader.

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
echo CURRENT DIAGNOSIS   : Normal Windows boot reaches late driver/device startup and
echo                       hangs. A separate Safe Mode Minimal loader is prepared.
echo CURRENT TASK        : Arm that separate loader for ONE boot only, then restart.
echo SAFETY              : ONE-TIME DIAGNOSTIC RESTART WITH PERSISTENT REBOOT GUARD.
echo NORMAL DEFAULT BOOT : NOT CHANGED
echo PERSONAL FILES      : NOT TOUCHED
echo BITLOCKER           : A recovery-key prompt may appear; enter it locally only.
echo WHAT YOU SHOULD DO  : WATCH THE SCREEN. Do not press keys during normal startup.
echo SCREENSHOT REQUIRED : ONLY if Recovery, blue screen, or another error appears.
echo ================================================================================

if not exist "%STATE%" md "%STATE%" >nul 2>&1
if exist "%REBOOTMARK%" goto :ALREADY_REBOOTED
if not exist "%GUIDFILE%" goto :BLOCK
if not exist "C:\RescueMeAI\backups\pre-safemode-step76\BCD" goto :BLOCK
if not exist "C:\Windows\System32\config\SYSTEM" goto :BLOCK
if not exist "C:\r.cmd" goto :BLOCK

set "SAFEGUID="
set /p "SAFEGUID="<"%GUIDFILE%"
if not defined SAFEGUID goto :BLOCK
if not "%SAFEGUID:~0,1%"=="{" goto :BLOCK
if not "%SAFEGUID:~-1%"=="}" goto :BLOCK

> "%DETAILS%" echo RESCUEMEAI ONE-TIME SAFE MODE DIAGNOSTIC
>>"%DETAILS%" echo fix_version=%FIX_VERSION%
>>"%DETAILS%" echo step=%STEP%
>>"%DETAILS%" echo safe_mode_entry=!SAFEGUID!

echo [1/5] Verifying Wi-Fi recovery profile for the return path...
set "PROFILE="
for %%D in (D E F G H I J K L M N O P Q R S T U V W Y Z) do if not defined PROFILE if exist "%%D:\Wi-Fi-404 Network Unavailable.xml" set "PROFILE=%%D:\Wi-Fi-404 Network Unavailable.xml"
if not defined PROFILE goto :BLOCK
>>"%DETAILS%" echo wifi_recovery_profile=!PROFILE!

echo [2/5] Mounting EFI and verifying the prepared Safe Mode entry...
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
>>"%DETAILS%" echo prepared_entry_verified=YES

echo [3/5] Arming the prepared Safe Mode loader for one boot only...
"%BCDEDIT%" /store "!BCD!" /bootsequence !SAFEGUID! >"%WORK%\step77-bootsequence.txt" 2>&1
set "BSRC=!errorlevel!"
>>"%DETAILS%" echo bootsequence_set_exit=!BSRC!
if not "!BSRC!"=="0" goto :BLOCK_MOUNTED
"%BCDEDIT%" /store "!BCD!" /enum {bootmgr} >"%WORK%\step77-bootmgr.txt" 2>&1
if errorlevel 1 goto :BLOCK_MOUNTED
"%MOUNTVOL%" !SYS! /D >nul 2>&1
set "MOUNTED=NO"

echo [4/5] Setting the persistent one-shot reboot guard...
> "%REBOOTMARK%" echo status=ISSUED
>>"%REBOOTMARK%" echo command_id=77
>>"%REBOOTMARK%" echo safe_mode_entry=!SAFEGUID!
>>"%REBOOTMARK%" echo guard=ONE_SHOT_PERSISTENT
> "%TESTMARK%" echo status=STARTING
>>"%TESTMARK%" echo fix_version=%FIX_VERSION%
>>"%TESTMARK%" echo safe_mode_entry=!SAFEGUID!
>>"%DETAILS%" echo reboot_guard=%REBOOTMARK%
>>"%DETAILS%" echo normal_default_loader_changed=NO
>>"%DETAILS%" echo personal_files_targeted=NO

echo [5/5] Starting the approved one-time Safe Mode restart...
> "%RESULT%" echo STATUS=PASS
>>"%RESULT%" echo MESSAGE=One-time Safe Mode diagnostic restart is starting now.
>>"%RESULT%" echo EVIDENCE=Prepared separate loader verified; bootsequence armed once; persistent reboot guard written before restart.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=CONDITIONAL
>>"%RESULT%" echo NEXT_STEP=If Safe Mode boots, reply SUCCESS. If HP spinner remains for 5 minutes, reply STUCK and wait for ChatGPT before running C:\r.cmd.

echo.
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : READY - RESTARTING ONCE INTO SAFE MODE
echo ONE-SHOT GUARD      : ACTIVE - THIS COMMAND CANNOT REBOOT TWICE
echo NORMAL DEFAULT BOOT : UNCHANGED
echo IF BITLOCKER APPEARS: Enter the recovery key locally; do not send it.
echo IF SAFE MODE BOOTS  : Reply SUCCESS.
echo IF RECOVERY/ERROR   : Reply FAILED and send a photo.
echo IF HP SPINNER HANGS : Wait 5 minutes, reply STUCK, then power off if necessary.
echo                       DO NOT run C:\r.cmd until ChatGPT says the queue is safe.
echo SCREENSHOT REQUIRED : ONLY for Recovery, blue screen, or unexpected error.
echo ================================================================================
echo Rebooting in about 10 seconds...
"%PING%" -n 11 127.0.0.1 >nul 2>&1
"%WPE%" reboot
set "RRC=!errorlevel!"

> "%RESULT%" echo STATUS=FAIL
>>"%RESULT%" echo MESSAGE=The one-time Safe Mode restart command returned instead of restarting.
>>"%RESULT%" echo EVIDENCE=wpeutil reboot exit code !RRC!; reboot guard remains set to prevent retry.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=YES
echo.
echo STATUS              : RESTART DID NOT START
echo REBOOT GUARD        : ACTIVE - AUTOMATIC RETRY BLOCKED
echo SCREENSHOT REQUIRED : YES
echo WHAT YOU SHOULD DO  : Reply FAILED and send a photo. Do not reboot manually.
exit /b 90

:ALREADY_REBOOTED
> "%RESULT%" echo STATUS=WARNING
>>"%RESULT%" echo MESSAGE=One-shot reboot guard blocked a repeated Step 77 restart.
>>"%RESULT%" echo EVIDENCE=Persistent reboot marker already exists; no BCD value was re-armed and no reboot was issued.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=NO
echo.
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : REPEATED REBOOT SUPPRESSED
echo REBOOT              : NO
echo WHAT YOU SHOULD DO  : WAIT. Do not run another reboot command.
echo SCREENSHOT REQUIRED : NO
echo ================================================================================
exit /b 40

:BLOCK_MOUNTED
if /i "!MOUNTED!"=="YES" "%MOUNTVOL%" !SYS! /D >nul 2>&1
set "MOUNTED=NO"
:BLOCK
> "%RESULT%" echo STATUS=WARNING
>>"%RESULT%" echo MESSAGE=One-time Safe Mode restart was blocked by a pre-flight prerequisite.
>>"%RESULT%" echo EVIDENCE=No reboot was issued; normal default loader and personal files were not changed.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=YES
echo.
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : SAFE MODE TEST BLOCKED
echo REBOOT              : NO
echo SCREENSHOT REQUIRED : YES
echo WHAT YOU SHOULD DO  : Reply FAILED and send ChatGPT a photo. Do not reboot.
echo ================================================================================
exit /b 40
