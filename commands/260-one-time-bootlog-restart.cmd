@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=REPAIR_WRITE
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Perform the user-approved one-time Windows boot-log restart after boot logging was prepared and verified.
rem WR_ACTION=CONTROLLED_ONE_TIME_BOOTLOG_RESTART
rem WR_TARGET=Current computer restart only; existing verified bootlog setting is re-checked before restart.
rem WR_CONSEQUENCE=The computer restarts and Windows attempts normal startup with boot logging already enabled. No Windows system file, EFI file, BCD setting, registry setting, package, partition, or personal file is changed by this command.
rem WR_ROLLBACK=The restart itself makes no persistent configuration change. Step 63 retained a BCD backup and the bootlog setting can be removed later after evidence is captured.

set "FIX_VERSION=RMAI-FIX-2026.09.10.3"
set "STEP=64"
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
if not exist "%STATE%" md "%STATE%" >nul 2>&1

cls
echo ================================================================================
echo RescueMeAI - ONE-TIME BOOT-LOG TEST
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : PRE-FLIGHT CHECK
echo CURRENT DIAGNOSIS   : Windows reaches the HP spinner but stalls. EFI, BCD,
echo                       native storage drivers, and storage filters have been checked.
echo CURRENT TASK        : Re-check boot logging and recovery reconnect readiness,
echo                       then restart once to generate C:\Windows\ntbtlog.txt.
echo SAFETY              : RESTART ONLY - no repair setting is changed by this step.
echo PERSONAL FILES      : NOT TOUCHED
echo BITLOCKER           : A recovery-key prompt may appear; enter the key locally only.
echo WHAT YOU SHOULD DO  : WATCH THE SCREEN. Do not press keys during normal startup.
echo SCREENSHOT REQUIRED : ONLY if Recovery, blue screen, or another error appears.
echo ================================================================================

>"%DETAILS%" echo RESCUEMEAI ONE-TIME BOOTLOG RESTART
>>"%DETAILS%" echo fix_version=%FIX_VERSION%
>>"%DETAILS%" echo step=%STEP%

echo [1/4] Verifying Windows and the permanent recovery reconnect helper...
if not exist "C:\Windows\System32\config\SYSTEM" goto :BLOCK_WINDOWS
if not exist "C:\Windows\System32\winload.efi" goto :BLOCK_WINDOWS
if not exist "C:\Windows\Boot\EFI\bootmgfw.efi" goto :BLOCK_WINDOWS
if not exist "C:\r.cmd" goto :BLOCK_RECONNECT
if not exist "C:\RescueMeAI\reconnect.cmd" goto :BLOCK_RECONNECT
>>"%DETAILS%" echo windows_target=PASS
>>"%DETAILS%" echo quick_reconnect=PASS

echo [2/4] Verifying the removable Wi-Fi recovery profile is available...
set "PROFILE="
for %%D in (D E F G H I J K L M N O P Q R S T U V W Y Z) do if not defined PROFILE if exist "%%D:\Wi-Fi-404 Network Unavailable.xml" set "PROFILE=%%D:\Wi-Fi-404 Network Unavailable.xml"
if not defined PROFILE goto :BLOCK_WIFI
>>"%DETAILS%" echo wifi_recovery_profile=PASS
>>"%DETAILS%" echo wifi_profile_location=!PROFILE!

echo [3/4] Re-checking bootlog=Yes in the EFI BCD store...
set "SYS=S:"
if exist S:\nul set "SYS=T:"
"%MOUNTVOL%" !SYS! /S >"%WORK%\step64-mount.txt" 2>&1
if errorlevel 1 goto :BLOCK_BCD
set "BCD=!SYS!\EFI\Microsoft\Boot\BCD"
if not exist "!BCD!" goto :BLOCK_BCD_MOUNTED
"%BCDEDIT%" /store "!BCD!" /enum {default} >"%WORK%\step64-bcd.txt" 2>&1
if errorlevel 1 goto :BLOCK_BCD_MOUNTED
findstr /i /c:"bootlog" "%WORK%\step64-bcd.txt" >"%WORK%\step64-bootlog-line.txt" 2>nul
if errorlevel 1 goto :BLOCK_BCD_MOUNTED
findstr /i /c:"Yes" "%WORK%\step64-bootlog-line.txt" >nul 2>&1
if errorlevel 1 goto :BLOCK_BCD_MOUNTED
"%MOUNTVOL%" !SYS! /D >nul 2>&1
>>"%DETAILS%" echo bootlog_default=YES

echo [4/4] Marking the test and starting the approved restart...
>"%STATE%\bootlog-test-64.started" echo status=STARTING
>>"%STATE%\bootlog-test-64.started" echo fix_version=%FIX_VERSION%
>>"%STATE%\bootlog-test-64.started" echo reason=generate_ntbtlog_after_hp_spinner_hang
>>"%DETAILS%" echo bootlog_test_marker=C:\RescueMeAI\state\bootlog-test-64.started

>"%RESULT%" echo STATUS=PASS
>>"%RESULT%" echo MESSAGE=User-approved one-time boot-log restart is starting now.
>>"%RESULT%" echo EVIDENCE=Windows target, reconnect helper, Wi-Fi recovery profile, and EFI bootlog=Yes passed pre-flight checks.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=CONDITIONAL
>>"%RESULT%" echo NEXT_STEP=If Windows boots, reply SUCCESS. If HP spinner remains for 5 minutes, power off, return to WinRE, run C:\r.cmd, and RescueMeAI will collect ntbtlog.txt.

echo.
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : READY - RESTARTING FOR ONE-TIME BOOT LOG
echo QUICK RECONNECT     : C:\r.cmd
echo EXPECTED RESULT     : Windows sign-in screen, or a new C:\Windows\ntbtlog.txt
echo                       if startup stalls again.
echo IF BITLOCKER APPEARS: Enter the recovery key locally; do not send it.
echo IF WINDOWS BOOTS    : Reply SUCCESS.
echo IF RECOVERY/ERROR   : Reply FAILED and send a photo.
echo IF HP SPINNER HANGS : Wait 5 minutes, then reply STUCK. Power off only after
echo                       that 5-minute mark, return to WinRE, and run C:\r.cmd.
echo SCREENSHOT REQUIRED : ONLY for Recovery, blue screen, or unexpected error.
echo ================================================================================
echo Rebooting in about 10 seconds...
"%PING%" -n 11 127.0.0.1 >nul 2>&1
"%WPE%" reboot
set "RRC=!errorlevel!"

>"%RESULT%" echo STATUS=FAIL
>>"%RESULT%" echo MESSAGE=The one-time boot-log restart command returned instead of restarting.
>>"%RESULT%" echo EVIDENCE=wpeutil reboot exit code !RRC!.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=YES
echo.
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : RESTART DID NOT START
echo REBOOT              : NO
echo SCREENSHOT REQUIRED : YES
echo WHAT YOU SHOULD DO  : Reply FAILED and send a photo. Do not reboot manually.
echo ================================================================================
exit /b 90

:BLOCK_BCD_MOUNTED
"%MOUNTVOL%" !SYS! /D >nul 2>&1
goto :BLOCK_BCD

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
set "BLOCK_REASON=BOOTLOG_NOT_VERIFIED_IN_EFI_BCD"
goto :BLOCK

:BLOCK
>"%RESULT%" echo STATUS=WARNING
>>"%RESULT%" echo MESSAGE=One-time boot-log restart was blocked by a pre-flight prerequisite.
>>"%RESULT%" echo EVIDENCE=block_reason=!BLOCK_REASON!; no restart was started and no Windows system or personal file was changed.
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
