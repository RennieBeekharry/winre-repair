@echo off
setlocal EnableExtensions EnableDelayedExpansion
title RescueMeAI - Safe Reconnect Bootstrap

set "FIX_VERSION=RMAI-FIX-2026.09.10.3"
set "BOOTSTRAP_VERSION=2026.09.10-r3"
set "WORK=C:\WinRERepair"
set "DESTDIR=C:\RescueMeAI"
set "DEST=%DESTDIR%\reconnect.cmd"
set "TMP=%WORK%\reconnect-v4.bootstrap.tmp"
set "HASHOUT=%WORK%\reconnect-v4.bootstrap.sha256.txt"
set "CURL=C:\Windows\System32\curl.exe"
set "CERT=C:\Windows\System32\certutil.exe"
set "WPE=X:\Windows\System32\wpeutil.exe"
if not exist "%WPE%" set "WPE=wpeutil.exe"
set "NETSH=X:\Windows\System32\netsh.exe"
if not exist "%NETSH%" set "NETSH=C:\Windows\System32\netsh.exe"
set "PING=X:\Windows\System32\ping.exe"
if not exist "%PING%" set "PING=C:\Windows\System32\ping.exe"
set "SSID=404 Network Unavailable"
set "URL=https://raw.githubusercontent.com/RennieBeekharry/winre-repair/41de5e93cc3938e7133fa002236eed697cf7b9b7/reconnect-v4.cmd"
set "EXPECTED=7c692b7738f6c7556cdb2653f4088d567055c50f809ff5ce1067a2fd555a6f3f"

cls
echo ================================================================================
echo RescueMeAI - SAFE RECONNECT BOOTSTRAP
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo BOOTSTRAP VERSION   : %BOOTSTRAP_VERSION%
echo STATUS              : RESTORING CONNECTION AND UPDATING RECONNECT HELPER
echo SAFETY              : CONNECTION ONLY - THIS SCRIPT CANNOT REBOOT WINDOWS
echo WINDOWS CHANGES     : NONE
echo PERSONAL FILES      : NOT TOUCHED
echo REBOOT              : NO
echo WHAT YOU SHOULD DO  : WAIT
echo SCREENSHOT REQUIRED : NO unless this script stops with an error
echo ================================================================================

if not exist "%CURL%" goto :FAIL
if not exist "%CERT%" goto :FAIL
if not exist "%NETSH%" goto :FAIL
if not exist "%PING%" goto :FAIL
if not exist "%WORK%" md "%WORK%" >nul 2>&1
if not exist "%DESTDIR%" md "%DESTDIR%" >nul 2>&1
if exist "%TMP%" del /f /q "%TMP%" >nul 2>&1
if exist "%HASHOUT%" del /f /q "%HASHOUT%" >nul 2>&1

echo [1/6] Initializing WinRE networking...
"%WPE%" InitializeNetwork >"%WORK%\r3-network-init.txt" 2>&1

echo [2/6] Checking Internet connectivity...
"%PING%" -n 1 github.com >nul 2>&1
if not errorlevel 1 goto :ONLINE

rem First try an already-imported profile, then fall back to the removable XML.
"%NETSH%" wlan connect name="%SSID%" interface="Wi-Fi" >"%WORK%\r3-existing-profile.txt" 2>&1
"%PING%" -n 4 127.0.0.1 >nul 2>&1
"%PING%" -n 1 github.com >nul 2>&1
if not errorlevel 1 goto :ONLINE

set "PROFILE="
for %%D in (D E F G H I J K L M N O P Q R S T U V W Y Z) do if not defined PROFILE if exist "%%D:\Wi-Fi-404 Network Unavailable.xml" set "PROFILE=%%D:\Wi-Fi-404 Network Unavailable.xml"
if not defined PROFILE goto :NETWORKFAIL

echo       Importing saved Wi-Fi profile from !PROFILE!...
"%NETSH%" wlan add profile filename="!PROFILE!" interface="Wi-Fi" >"%WORK%\r3-profile-import.txt" 2>&1
if errorlevel 1 goto :NETWORKFAIL
"%NETSH%" wlan connect name="%SSID%" interface="Wi-Fi" >"%WORK%\r3-wifi-connect.txt" 2>&1
"%PING%" -n 6 127.0.0.1 >nul 2>&1
"%PING%" -n 1 github.com >nul 2>&1
if errorlevel 1 goto :NETWORKFAIL

:ONLINE
echo [3/6] Internet connection confirmed.

echo [4/6] Downloading pinned Reconnect v4...
"%CURL%" --ssl-no-revoke --fail --location --silent --show-error --connect-timeout 15 --max-time 120 "%URL%" -o "%TMP%"
if errorlevel 1 goto :FAIL
if not exist "%TMP%" goto :FAIL

echo [5/6] Verifying SHA-256 and installing helper...
"%CERT%" -hashfile "%TMP%" SHA256 >"%HASHOUT%" 2>&1
if errorlevel 1 goto :FAIL
set "ACTUAL="
for /f "skip=1 delims=" %%H in ('type "%HASHOUT%"') do if not defined ACTUAL set "ACTUAL=%%H"
set "ACTUAL=!ACTUAL: =!"
if /i not "!ACTUAL!"=="%EXPECTED%" goto :HASHFAIL
copy /y "%TMP%" "%DEST%" >nul
if errorlevel 1 goto :FAIL

echo [6/6] Starting connection-only RescueMeAI reconnect...
call "%DEST%"
exit /b !errorlevel!

:NETWORKFAIL
echo.
echo ================================================================================
echo STATUS              : STOPPED - NETWORK NOT READY
echo REBOOT              : NO
echo WINDOWS CHANGES     : NONE
echo SCREENSHOT REQUIRED : YES
echo WHAT YOU SHOULD DO  : Keep the Wi-Fi-profile USB inserted and send ChatGPT a photo.
echo ================================================================================
exit /b 40

:HASHFAIL
echo.
echo ================================================================================
echo STATUS              : STOPPED - RECONNECT DOWNLOAD HASH MISMATCH
echo REBOOT              : NO
echo SCREENSHOT REQUIRED : YES
echo WHAT YOU SHOULD DO  : Send ChatGPT a photo. Do not reboot.
echo ================================================================================
exit /b 93

:FAIL
echo.
echo ================================================================================
echo STATUS              : STOPPED - SAFE RECONNECT UPDATE FAILED
echo REBOOT              : NO
echo SCREENSHOT REQUIRED : YES
echo WHAT YOU SHOULD DO  : Send ChatGPT a photo. Do not reboot.
echo ================================================================================
exit /b 90
