@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=REPAIR_WRITE
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Upgrade the persistent RescueMeAI quick reconnect helper so future WinRE reconnects can restore Wi-Fi automatically from removable media.
rem WR_ACTION=UPGRADE_RECONNECT_HELPER
rem WR_TARGET=C:\RescueMeAI\reconnect.cmd and C:\r.cmd only.
rem WR_CONSEQUENCE=Updates RescueMeAI helper files only. No Windows system, BCD, registry, package, partition, or personal-file changes.
rem WR_ROLLBACK=Previous helper can be restored from GitHub if required.

set "FIX_VERSION=RMAI-FIX-2026.09.10.2"
set "STEP=40"
set "WORK=C:\WinRERepair"
set "RESULT=%WORK%\COMMAND_RESULT.env"
set "DETAILS=%WORK%\RUN_DETAILS.txt"
set "DEST=C:\RescueMeAI"
set "CURL=C:\Windows\System32\curl.exe"
set "CERT=C:\Windows\System32\certutil.exe"
set "URL=https://raw.githubusercontent.com/RennieBeekharry/winre-repair/853baef6dd76a3eadcce9929713bb0d9d1b894a2/reconnect-v3.cmd"
set "EXPECTED=1886a64981c1965cb52d8cffb1cc2e2b8839ff0540fb9236279544bc16de341d"
set "TMP=%WORK%\reconnect-v3.download.cmd"

cls
echo ================================================================================
echo RescueMeAI - QUICK RECONNECT UPGRADE
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : RUNNING
echo CURRENT TASK        : Upgrading the one-command reconnect helper.
echo SAFETY              : REPAIR-WRITE - RescueMeAI helper files only.
echo WINDOWS SYSTEM      : NOT MODIFIED
echo PERSONAL FILES      : NOT TOUCHED
echo REBOOT              : NO
echo WHAT YOU SHOULD DO  : WAIT. Leave this window open.
echo SCREENSHOT REQUIRED : NO
echo ================================================================================

if not exist "%DEST%" md "%DEST%" >nul 2>&1
echo [1/4] Downloading the pinned reconnect helper...
"%CURL%" --ssl-no-revoke -fL "%URL%" -o "%TMP%"
if errorlevel 1 goto :FAIL

echo [2/4] Verifying SHA-256 before installation...
set "ACTUAL="
for /f "skip=1 delims=" %%H in ('"%CERT%" -hashfile "%TMP%" SHA256 2^>nul') do if not defined ACTUAL set "ACTUAL=%%H"
set "ACTUAL=!ACTUAL: =!"
if /i not "!ACTUAL!"=="%EXPECTED%" goto :HASHFAIL

echo [3/4] Installing C:\RescueMeAI\reconnect.cmd...
copy /y "%TMP%" "%DEST%\reconnect.cmd" >nul
if errorlevel 1 goto :FAIL

echo [4/4] Rebuilding the short C:\r.cmd launcher...
>"C:\r.cmd" echo @echo off
>>"C:\r.cmd" echo call C:\RescueMeAI\reconnect.cmd
>>"C:\r.cmd" echo exit /b %%errorlevel%%
if not exist "C:\r.cmd" goto :FAIL

>"%DETAILS%" echo RESCUEMEAI QUICK RECONNECT UPGRADE
>>"%DETAILS%" echo fix_version=%FIX_VERSION%
>>"%DETAILS%" echo step=%STEP%
>>"%DETAILS%" echo reconnect_version=2026.09.10-v3
>>"%DETAILS%" echo sha256_verified=YES
>>"%DETAILS%" echo quick_command=C:\r.cmd
>>"%DETAILS%" echo wifi_profile_copied_to_system_drive=NO
>>"%DETAILS%" echo windows_changes_performed=NO
>>"%DETAILS%" echo personal_files_targeted=NO
>"%RESULT%" echo STATUS=PASS
>>"%RESULT%" echo MESSAGE=Persistent quick reconnect upgraded successfully.
>>"%RESULT%" echo EVIDENCE=Reconnect v3 installed with verified SHA-256; future WinRE reconnect command is C:\r.cmd.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=NO
>>"%RESULT%" echo NEXT_STEP=RescueMeAI may continue recovery; verify this helper before the next reboot.

echo.
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : COMPLETE - QUICK RECONNECT READY
echo FUTURE COMMAND      : C:\r.cmd
echo NETWORK RECOVERY    : AUTOMATIC when the Wi-Fi-profile USB is inserted
echo WINDOWS CHANGES     : NONE
echo REBOOT              : NO
echo WHAT YOU SHOULD DO  : WAIT. RescueMeAI will continue.
echo SCREENSHOT REQUIRED : NO
echo ================================================================================
exit /b 0

:HASHFAIL
>"%RESULT%" echo STATUS=FAIL
>>"%RESULT%" echo MESSAGE=Reconnect helper SHA-256 verification failed.
>>"%RESULT%" echo EVIDENCE=No helper was installed and no Windows state was changed.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=YES
echo STATUS              : STOPPED - DOWNLOAD INTEGRITY CHECK FAILED
echo SCREENSHOT REQUIRED : YES
exit /b 90

:FAIL
>"%RESULT%" echo STATUS=FAIL
>>"%RESULT%" echo MESSAGE=Reconnect helper upgrade failed.
>>"%RESULT%" echo EVIDENCE=No Windows system or personal files were changed.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=YES
echo STATUS              : STOPPED - RECONNECT UPGRADE FAILED
echo SCREENSHOT REQUIRED : YES
exit /b 90
