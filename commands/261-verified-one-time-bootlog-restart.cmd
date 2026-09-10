@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=REPAIR_WRITE
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Perform the user-approved one-time Windows boot-log restart using the already verified Step 63 preparation, while reasserting bootlog=Yes idempotently in the same EFI BCD store.
rem WR_ACTION=CONTROLLED_BOOTLOG_RESTART_AFTER_VERIFIED_PREPARATION
rem WR_TARGET=EFI BCD default loader bootlog value (same value already set and verified in Step 63), RescueMeAI markers, and current computer restart.
rem WR_CONSEQUENCE=Reasserts bootlog=Yes, records the BCD text for evidence, and restarts once so Windows can generate ntbtlog.txt. No Windows system binary, registry setting, package, partition, or personal file is changed.
rem WR_ROLLBACK=Step 63 retained C:\RescueMeAI\backups\pre-bootlog-step63\BCD; bootlog can be cleared after evidence capture.

set "FIX_VERSION=RMAI-FIX-2026.09.10.3"
set "STEP=65"
set "WORK=C:\WinRERepair"
set "STATE=C:\RescueMeAI\state"
set "RESULT=%WORK%\COMMAND_RESULT.env"
set "DETAILS=%WORK%\RUN_DETAILS.txt"
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
echo RescueMeAI - VERIFIED ONE-TIME BOOT-LOG RESTART
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : PRE-FLIGHT CHECK
echo CURRENT DIAGNOSIS   : Windows reaches the HP spinner but stalls. Step 63 already
echo                       enabled and verified boot logging in the EFI BCD.
echo CURRENT TASK        : Reasserting the same bootlog=Yes value without brittle text
echo                       parsing, then restarting once to generate ntbtlog.txt.
echo SAFETY              : REPAIR-WRITE - same reversible BCD diagnostic value + reboot.
echo PERSONAL FILES      : NOT TOUCHED
echo BITLOCKER           : A recovery-key prompt may appear; enter the key locally only.
echo WHAT YOU SHOULD DO  : WATCH THE SCREEN. Do not press keys during normal startup.
echo SCREENSHOT REQUIRED : ONLY if Recovery, blue screen, or another error appears.
echo ================================================================================

if not exist "%WORK%" md "%WORK%" >nul 2>&1
if not exist "%STATE%" md "%STATE%" >nul 2>&1
>"%DETAILS%" echo RESCUEMEAI VERIFIED ONE-TIME BOOTLOG RESTART
>>"%DETAILS%" echo fix_version=%FIX_VERSION%
>>"%DETAILS%" echo step=%STEP%

echo [1/5] Verifying Step 63 prepared state, rollback copy, and reconnect readiness...
if not exist "C:\RescueMeAI\state\bootlog-step63.prepared" goto :BLOCK_PREP
if not exist "C:\RescueMeAI\backups\pre-bootlog-step63\BCD" goto :BLOCK_PREP
if not exist "C:\Windows\System32\config\SYSTEM" goto :BLOCK_WINDOWS
if not exist "C:\Windows\System32\winload.efi" goto :BLOCK_WINDOWS
if not exist "C:\r.cmd" goto :BLOCK_RECONNECT
if not exist "C:\RescueMeAI\reconnect.cmd" goto :BLOCK_RECONNECT
>>"%DETAILS%" echo step63_prepared_marker=PASS
>>"%DETAILS%" echo step63_bcd_backup=PASS
>>"%DETAILS%" echo windows_target=PASS
>>"%DETAILS%" echo quick_reconnect=PASS

echo [2/5] Verifying the removable Wi-Fi recovery profile...
set "PROFILE="
for %%D in (D E F G H I J K L M N O P Q R S T U V W Y Z) do if not defined PROFILE if exist "%%D:\Wi-Fi-404 Network Unavailable.xml" set "PROFILE=%%D:\Wi-Fi-404 Network Unavailable.xml"
if not defined PROFILE goto :BLOCK_WIFI
>>"%DETAILS%" echo wifi_recovery_profile=PASS
>>"%DETAILS%" echo wifi_profile_location=!PROFILE!

echo [3/5] Mounting the EFI system partition and locating the BCD...
set "SYS=S:"
if exist S:\nul set "SYS=T:"
if exist T:\nul if "!SYS!"=="T:" set "SYS=U:"
"%MOUNTVOL%" !SYS! /S >"%WORK%\step65-mount.txt" 2>&1
if errorlevel 1 goto :BLOCK_BCD
set "MOUNTED=YES"
set "BCD=!SYS!\EFI\Microsoft\Boot\BCD"
if not exist "!BCD!" goto :BLOCK_BCD_MOUNTED
>>"%DETAILS%" echo efi_bcd_found=YES

echo [4/5] Reasserting bootlog=Yes in the verified EFI BCD store...
"%BCDEDIT%" /store "!BCD!" /set {default} bootlog Yes >"%WORK%\step65-set.txt" 2>&1
set "SETRC=!errorlevel!"
>>"%DETAILS%" echo bcdedit_set_bootlog_exit=!SETRC!
if not "!SETRC!"=="0" goto :BLOCK_BCD_MOUNTED
"%BCDEDIT%" /store "!BCD!" /enum {default} >"%WORK%\step65-bcd-after.txt" 2>&1
set "ENUMRC=!errorlevel!"
>>"%DETAILS%" echo bcdedit_enum_default_exit=!ENUMRC!
if not "!ENUMRC!"=="0" goto :BLOCK_BCD_MOUNTED
>>"%DETAILS%" echo.
>>"%DETAILS%" echo --- EFI BCD DEFAULT ENTRY AFTER REASSERT ---
type "%WORK%\step65-bcd-after.txt" >>"%DETAILS%" 2>nul
"%MOUNTVOL%" !SYS! /D >nul 2>&1
set "MOUNTED=NO"

echo [5/5] Marking the approved test and restarting...
>"%STATE%\bootlog-test-65.started" echo status=STARTING
>>"%STATE%\bootlog-test-65.started" echo fix_version=%FIX_VERSION%
>>"%STATE%\bootlog-test-65.started" echo reason=generate_ntbtlog_after_hp_spinner_hang
>>"%DETAILS%" echo bootlog_test_marker=C:\RescueMeAI\state\bootlog-test-65.started
>>"%DETAILS%" echo personal_files_targeted=NO

>"%RESULT%" echo STATUS=PASS
>>"%RESULT%" echo MESSAGE=User-approved one-time boot-log restart is starting after Step 63 verified preparation.
>>"%RESULT%" echo EVIDENCE=Prepared marker, rollback BCD, Windows target, reconnect helper, Wi-Fi profile, EFI BCD, bootlog set exit 0, and BCD enum exit 0 all passed.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=CONDITIONAL
>>"%RESULT%" echo NEXT_STEP=If Windows boots, reply SUCCESS. If HP spinner remains for 5 minutes, reply STUCK, power off, return to WinRE, run C:\r.cmd, and RescueMeAI will collect ntbtlog.txt.

echo.
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : READY - RESTARTING FOR BOOT LOG
echo QUICK RECONNECT     : C:\r.cmd
echo EXPECTED RESULT     : Windows sign-in, or ntbtlog.txt evidence if startup stalls.
echo IF BITLOCKER APPEARS: Enter the recovery key locally; do not send it.
echo IF WINDOWS BOOTS    : Reply SUCCESS.
echo IF RECOVERY/ERROR   : Reply FAILED and send a photo.
echo IF HP SPINNER HANGS : Wait 5 minutes, then reply STUCK; power off and return to
echo                       WinRE, then run C:\r.cmd.
echo SCREENSHOT REQUIRED : ONLY for Recovery, blue screen, or unexpected error.
echo ================================================================================
echo Rebooting in about 10 seconds...
"%PING%" -n 11 127.0.0.1 >nul 2>&1
"%WPE%" reboot
set "RRC=!errorlevel!"

>"%RESULT%" echo STATUS=FAIL
>>"%RESULT%" echo MESSAGE=The controlled boot-log restart command returned instead of restarting.
>>"%RESULT%" echo EVIDENCE=wpeutil reboot exit code !RRC!.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=YES
echo STATUS              : RESTART DID NOT START
echo SCREENSHOT REQUIRED : YES
echo WHAT YOU SHOULD DO  : Reply FAILED and send a photo. Do not reboot manually.
exit /b 90

:BLOCK_BCD_MOUNTED
if /i "!MOUNTED!"=="YES" "%MOUNTVOL%" !SYS! /D >nul 2>&1
goto :BLOCK_BCD
:BLOCK_PREP
set "BLOCK_REASON=STEP63_PREP_OR_ROLLBACK_NOT_FOUND"
goto :BLOCK
:BLOCK_WINDOWS
set "BLOCK_REASON=WINDOWS_TARGET_NOT_VERIFIED"
goto :BLOCK
:BLOCK_RECONNECT
set "BLOCK_REASON=RECONNECT_NOT_READY"
goto :BLOCK
:BLOCK_WIFI
set "BLOCK_REASON=WIFI_RECOVERY_PROFILE_NOT_FOUND"
goto :BLOCK
:BLOCK_BCD
set "BLOCK_REASON=EFI_BCD_OR_BOOTLOG_SET_NOT_READY"
goto :BLOCK
:BLOCK
>"%RESULT%" echo STATUS=WARNING
>>"%RESULT%" echo MESSAGE=Verified one-time boot-log restart was blocked by a pre-flight prerequisite.
>>"%RESULT%" echo EVIDENCE=block_reason=!BLOCK_REASON!; no restart was started.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=YES
>>"%DETAILS%" echo block_reason=!BLOCK_REASON!
echo.
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : BOOT-LOG TEST BLOCKED
echo REBOOT              : NO
echo BLOCK REASON        : !BLOCK_REASON!
echo SCREENSHOT REQUIRED : YES
echo WHAT YOU SHOULD DO  : Reply FAILED and send a photo. Do not reboot manually.
echo ================================================================================
exit /b 40
