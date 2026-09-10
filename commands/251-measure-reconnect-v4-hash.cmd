@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=READ_ONLY
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Download the pinned RescueMeAI reconnect v4 helper and measure its SHA-256 before installation.
rem WR_ACTION=MEASURE_RECONNECT_V4_HASH
rem WR_TARGET=RescueMeAI temporary download and diagnostic files only.
rem WR_CONSEQUENCE=Downloads a pinned helper to C:\WinRERepair and calculates its SHA-256. No Windows, EFI, BCD, registry, package, partition, reboot, or personal-file change.
rem WR_ROLLBACK=Not applicable; this is a read-only verification step.

set "FIX_VERSION=RMAI-FIX-2026.09.10.3"
set "STEP=54"
set "WORK=C:\WinRERepair"
set "RESULT=%WORK%\COMMAND_RESULT.env"
set "DETAILS=%WORK%\RUN_DETAILS.txt"
set "TMP=%WORK%\reconnect-v4.download.cmd"
set "HASHOUT=%WORK%\reconnect-v4-hash.txt"
set "CURL=C:\Windows\System32\curl.exe"
set "CERT=C:\Windows\System32\certutil.exe"
set "URL=https://raw.githubusercontent.com/RennieBeekharry/winre-repair/41de5e93cc3938e7133fa002236eed697cf7b9b7/reconnect-v4.cmd"

cls
echo ================================================================================
echo RescueMeAI - RECONNECT V4 INTEGRITY MEASUREMENT
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : RUNNING
echo CURRENT TASK        : Measuring the exact pinned reconnect v4 download before install.
echo SAFETY              : READ-ONLY verification.
echo PERSONAL FILES      : NOT TOUCHED
echo REBOOT              : NO
echo WHAT YOU SHOULD DO  : WAIT. Leave this window open.
echo SCREENSHOT REQUIRED : NO
echo ================================================================================

if not exist "%WORK%" md "%WORK%" >nul 2>&1
if not exist "%CURL%" goto :FAIL
if not exist "%CERT%" goto :FAIL
if exist "%TMP%" del /f /q "%TMP%" >nul 2>&1
if exist "%HASHOUT%" del /f /q "%HASHOUT%" >nul 2>&1

echo [1/3] Downloading pinned reconnect v4...
"%CURL%" --ssl-no-revoke --fail --location --silent --show-error --connect-timeout 15 --max-time 120 "%URL%" -o "%TMP%"
if errorlevel 1 goto :FAIL
if not exist "%TMP%" goto :FAIL

echo [2/3] Calculating SHA-256...
"%CERT%" -hashfile "%TMP%" SHA256 >"%HASHOUT%" 2>&1
if errorlevel 1 goto :FAIL
set "HASH="
for /f "skip=1 delims=" %%H in ('type "%HASHOUT%"') do if not defined HASH set "HASH=%%H"
set "HASH=!HASH: =!"
if not defined HASH goto :FAIL

echo [3/3] Recording integrity result...
>"%DETAILS%" echo RESCUEMEAI RECONNECT V4 HASH MEASUREMENT
>>"%DETAILS%" echo fix_version=%FIX_VERSION%
>>"%DETAILS%" echo step=%STEP%
>>"%DETAILS%" echo reconnect_v4_sha256=!HASH!
>>"%DETAILS%" echo windows_changes_performed=NO
>>"%DETAILS%" echo personal_files_targeted=NO

>"%RESULT%" echo STATUS=PASS
>>"%RESULT%" echo MESSAGE=Reconnect v4 downloaded-file SHA-256 measured successfully.
>>"%RESULT%" echo EVIDENCE=Reconnect v4 SHA-256=!HASH!.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=NO
>>"%RESULT%" echo NEXT_STEP=RescueMeAI will install reconnect v4 only after the measured hash is reviewed.

echo.
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : COMPLETE - HASH SENT FOR REVIEW
echo WINDOWS CHANGES     : NONE
echo REBOOT              : NO
echo WHAT YOU SHOULD DO  : WAIT.
echo SCREENSHOT REQUIRED : NO
echo ================================================================================
exit /b 0

:FAIL
>"%RESULT%" echo STATUS=FAIL
>>"%RESULT%" echo MESSAGE=Reconnect v4 integrity measurement failed.
>>"%RESULT%" echo EVIDENCE=No Windows or personal-file changes were made.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=YES
echo STATUS              : STOPPED - RECONNECT V4 HASH CHECK FAILED
echo SCREENSHOT REQUIRED : YES
exit /b 90
