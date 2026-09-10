@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=REPAIR_WRITE
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Install the verified RescueMeAI reconnect v3 helper and rebuild the one-command launcher.
rem WR_ACTION=INSTALL_VERIFIED_RECONNECT_V3
rem WR_TARGET=C:\RescueMeAI\reconnect.cmd and C:\r.cmd only.
rem WR_CONSEQUENCE=Updates RescueMeAI helper files only. No Windows system, BCD, registry, package, partition, reboot, or personal-file changes.
rem WR_ROLLBACK=The previous helper can be restored from GitHub.

set "FIX_VERSION=RMAI-FIX-2026.09.10.2"
set "STEP=42"
set "WORK=C:\WinRERepair"
set "RESULT=%WORK%\COMMAND_RESULT.env"
set "DETAILS=%WORK%\RUN_DETAILS.txt"
set "DEST=C:\RescueMeAI"
set "CURL=C:\Windows\System32\curl.exe"
set "CERT=C:\Windows\System32\certutil.exe"
set "FIND=C:\Windows\System32\findstr.exe"
set "URL=https://raw.githubusercontent.com/RennieBeekharry/winre-repair/853baef6dd76a3eadcce9929713bb0d9d1b894a2/reconnect-v3.cmd"
set "EXPECTED=1886a64981c1965cb52d8cffb1cc2e2b8839ff0540fb9236279544bc16de341d"
set "TMP=%WORK%\reconnect-v3.download.cmd"
set "HASHOUT=%WORK%\reconnect-v3-hash.txt"

cls
echo ================================================================================
echo RescueMeAI - VERIFIED QUICK RECONNECT INSTALL
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : RUNNING
echo CURRENT TASK        : Installing reconnect v3 and rebuilding C:\r.cmd.
echo SAFETY              : REPAIR-WRITE - RescueMeAI helper files only.
echo WINDOWS SYSTEM      : NOT MODIFIED
echo PERSONAL FILES      : NOT TOUCHED
echo REBOOT              : NO
echo WHAT YOU SHOULD DO  : WAIT.
echo SCREENSHOT REQUIRED : NO
echo ================================================================================

if not exist "%DEST%" md "%DEST%" >nul 2>&1
echo [1/4] Downloading pinned reconnect v3...
"%CURL%" --ssl-no-revoke -fL "%URL%" -o "%TMP%"
if errorlevel 1 goto :FAIL

echo [2/4] Verifying SHA-256...
"%CERT%" -hashfile "%TMP%" SHA256 >"%HASHOUT%" 2>&1
"%FIND%" /i /c:"%EXPECTED%" "%HASHOUT%" >nul 2>&1
if errorlevel 1 goto :HASHFAIL

echo [3/4] Installing local reconnect helper...
copy /y "%TMP%" "%DEST%\reconnect.cmd" >nul
if errorlevel 1 goto :FAIL

echo [4/4] Rebuilding C:\r.cmd...
>"C:\r.cmd" echo @echo off
>>"C:\r.cmd" echo call C:\RescueMeAI\reconnect.cmd
>>"C:\r.cmd" echo exit /b %%errorlevel%%
if not exist "C:\r.cmd" goto :FAIL

>"%DETAILS%" echo RESCUEMEAI VERIFIED RECONNECT INSTALL
>>"%DETAILS%" echo fix_version=%FIX_VERSION%
>>"%DETAILS%" echo step=%STEP%
>>"%DETAILS%" echo reconnect_version=2026.09.10-v3
>>"%DETAILS%" echo sha256_verified=YES
>>"%DETAILS%" echo quick_command=C:\r.cmd
>>"%DETAILS%" echo wifi_profile_stays_on_removable_media=YES
>>"%DETAILS%" echo windows_changes_performed=NO
>>"%DETAILS%" echo personal_files_targeted=NO
>"%RESULT%" echo STATUS=PASS
>>"%RESULT%" echo MESSAGE=Reconnect v3 installed and C:\r.cmd rebuilt successfully.
>>"%RESULT%" echo EVIDENCE=Verified reconnect v3 is local; Wi-Fi restoration can use the removable-media profile without copying its secret to C:.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=NO
>>"%RESULT%" echo NEXT_STEP=RescueMeAI can continue recovery and future WinRE reconnects use C:\r.cmd.

echo.
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : COMPLETE - QUICK RECONNECT V3 READY
echo FUTURE COMMAND      : C:\r.cmd
echo WI-FI RECOVERY      : AUTOMATIC IF PROFILE USB IS INSERTED
echo WINDOWS CHANGES     : NONE
echo REBOOT              : NO
echo WHAT YOU SHOULD DO  : WAIT. RescueMeAI will continue.
echo SCREENSHOT REQUIRED : NO
echo ================================================================================
exit /b 0

:HASHFAIL
>"%RESULT%" echo STATUS=FAIL
>>"%RESULT%" echo MESSAGE=Reconnect v3 SHA-256 verification failed.
>>"%RESULT%" echo EVIDENCE=No helper was installed and no Windows state was changed.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=YES
echo STATUS              : STOPPED - DOWNLOAD INTEGRITY CHECK FAILED
echo SCREENSHOT REQUIRED : YES
exit /b 90

:FAIL
>"%RESULT%" echo STATUS=FAIL
>>"%RESULT%" echo MESSAGE=Reconnect v3 installation failed.
>>"%RESULT%" echo EVIDENCE=No Windows system or personal files were changed.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=YES
echo STATUS              : STOPPED - RECONNECT INSTALL FAILED
echo SCREENSHOT REQUIRED : YES
exit /b 90
