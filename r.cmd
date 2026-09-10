@echo off
setlocal EnableExtensions EnableDelayedExpansion
title RescueMeAI - Safe Reconnect Bootstrap

set "FIX_VERSION=RMAI-FIX-2026.09.10.3"
set "BOOTSTRAP_VERSION=2026.09.10-r2"
set "WORK=C:\WinRERepair"
set "DESTDIR=C:\RescueMeAI"
set "DEST=%DESTDIR%\reconnect.cmd"
set "TMP=%WORK%\reconnect-v4.bootstrap.tmp"
set "HASHOUT=%WORK%\reconnect-v4.bootstrap.sha256.txt"
set "CURL=C:\Windows\System32\curl.exe"
set "CERT=C:\Windows\System32\certutil.exe"
set "URL=https://raw.githubusercontent.com/RennieBeekharry/winre-repair/41de5e93cc3938e7133fa002236eed697cf7b9b7/reconnect-v4.cmd"
set "EXPECTED=7c692b7738f6c7556cdb2653f4088d567055c50f809ff5ce1067a2fd555a6f3f"

cls
echo ================================================================================
echo RescueMeAI - SAFE RECONNECT BOOTSTRAP
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo BOOTSTRAP VERSION   : %BOOTSTRAP_VERSION%
echo STATUS              : UPDATING RECONNECT HELPER SAFELY
echo SAFETY              : CONNECTION ONLY - THIS SCRIPT CANNOT REBOOT WINDOWS
echo WINDOWS CHANGES     : NONE
echo PERSONAL FILES      : NOT TOUCHED
echo REBOOT              : NO
echo WHAT YOU SHOULD DO  : WAIT
echo SCREENSHOT REQUIRED : NO unless this script stops with an error
echo ================================================================================

if not exist "%CURL%" goto :FAIL
if not exist "%CERT%" goto :FAIL
if not exist "%WORK%" md "%WORK%" >nul 2>&1
if not exist "%DESTDIR%" md "%DESTDIR%" >nul 2>&1
if exist "%TMP%" del /f /q "%TMP%" >nul 2>&1
if exist "%HASHOUT%" del /f /q "%HASHOUT%" >nul 2>&1

echo [1/4] Downloading pinned Reconnect v4...
"%CURL%" --ssl-no-revoke --fail --location --silent --show-error --connect-timeout 15 --max-time 120 "%URL%" -o "%TMP%"
if errorlevel 1 goto :FAIL
if not exist "%TMP%" goto :FAIL

echo [2/4] Verifying SHA-256 integrity...
"%CERT%" -hashfile "%TMP%" SHA256 >"%HASHOUT%" 2>&1
if errorlevel 1 goto :FAIL
set "ACTUAL="
for /f "skip=1 delims=" %%H in ('type "%HASHOUT%"') do if not defined ACTUAL set "ACTUAL=%%H"
set "ACTUAL=!ACTUAL: =!"
if /i not "!ACTUAL!"=="%EXPECTED%" goto :HASHFAIL

echo [3/4] Installing verified reconnect helper...
copy /y "%TMP%" "%DEST%" >nul
if errorlevel 1 goto :FAIL

echo [4/4] Starting connection-only RescueMeAI reconnect...
call "%DEST%"
exit /b !errorlevel!

:HASHFAIL
echo.
echo STATUS              : STOPPED - RECONNECT DOWNLOAD HASH MISMATCH
echo REBOOT              : NO
echo SCREENSHOT REQUIRED : YES
echo WHAT YOU SHOULD DO  : Send ChatGPT a photo. Do not reboot.
exit /b 93

:FAIL
echo.
echo STATUS              : STOPPED - SAFE RECONNECT UPDATE FAILED
echo REBOOT              : NO
echo SCREENSHOT REQUIRED : YES
echo WHAT YOU SHOULD DO  : Send ChatGPT a photo. Do not reboot.
exit /b 90
