@echo off
setlocal EnableExtensions EnableDelayedExpansion
title RescueMeAI - Quick Reconnect v4

set "RECONNECT_VERSION=2026.09.10-v4"
set "FIX_VERSION=RMAI-FIX-2026.09.10.3"
set "WORK=C:\WinRERepair"
set "RUNTIME=%WORK%\runtime\device-agent-v2.cmd"
set "CONFIG=%WORK%\agent.cfg"
set "TOKEN=%WORK%\.auth\github-logs.token"
set "CURL=C:\Windows\System32\curl.exe"
set "WPE=X:\Windows\System32\wpeutil.exe"
if not exist "%WPE%" set "WPE=wpeutil.exe"
set "PING=X:\Windows\System32\ping.exe"
if not exist "%PING%" set "PING=C:\Windows\System32\ping.exe"
set "NETSH=X:\Windows\System32\netsh.exe"
if not exist "%NETSH%" set "NETSH=C:\Windows\System32\netsh.exe"
set "SSID=404 Network Unavailable"
set "REPO_ID=1333818657"
set "HTTP=%WORK%\reconnect-http.txt"
set "BOOTSTRAP=%WORK%\connect-device-v3.cmd"
set "BOOTSTRAP_URL=https://raw.githubusercontent.com/RennieBeekharry/winre-repair/5902c7e130ca4712e3355f8bf489e37fca9d625f/connect-device-v3.cmd"

cls
echo ================================================================================
echo RescueMeAI - QUICK RECONNECT v4
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo RECONNECT VERSION   : %RECONNECT_VERSION%
echo STATUS              : STARTING
echo CURRENT TASK        : Restoring WinRE network and validating GitHub authorization.
echo SAFETY              : CONNECTION ONLY - no Windows repair is running.
echo WINDOWS CHANGES     : NONE
echo PERSONAL FILES      : NOT TOUCHED
echo REBOOT              : NO
echo WHAT YOU SHOULD DO  : WAIT. Follow this screen only if it asks for authorization.
echo SCREENSHOT REQUIRED : NO
echo ================================================================================

if not exist "%CURL%" goto :DEPENDENCY_FAIL
if not exist "%WORK%" md "%WORK%" >nul 2>&1

echo [1/5] Initializing WinRE networking...
"%WPE%" InitializeNetwork >nul 2>&1

echo [2/5] Checking Internet connectivity...
"%PING%" -n 1 -w 3000 github.com >nul 2>&1
if not errorlevel 1 goto :NETWORK_OK

echo       Internet is not ready. Looking for the saved Wi-Fi profile on removable media...
set "PROFILE="
for %%D in (D E F G H I J K L M N O P Q R S T U V W Y Z) do if not defined PROFILE if exist "%%D:\Wi-Fi-404 Network Unavailable.xml" set "PROFILE=%%D:\Wi-Fi-404 Network Unavailable.xml"
if not defined PROFILE goto :NETWORK_FAIL
echo       Found Wi-Fi profile at !PROFILE!.
echo       Importing profile and connecting...
"%NETSH%" wlan add profile filename="!PROFILE!" interface="Wi-Fi" >nul 2>&1
"%NETSH%" wlan connect name="%SSID%" >nul 2>&1
"%PING%" -n 4 127.0.0.1 >nul 2>&1
"%PING%" -n 1 -w 5000 github.com >nul 2>&1
if errorlevel 1 goto :NETWORK_FAIL

:NETWORK_OK
echo [3/5] Internet connection verified.
echo [4/5] Validating saved GitHub authorization...
if not exist "%TOKEN%" goto :REAUTHORIZE
set "ACCESS="
set /p "ACCESS="<"%TOKEN%"
if not defined ACCESS goto :REAUTHORIZE
if exist "%HTTP%" del /f /q "%HTTP%" >nul 2>&1
"%CURL%" --ssl-no-revoke --silent --show-error --connect-timeout 15 --max-time 60 -H "Accept: application/vnd.github+json" -H "Authorization: Bearer !ACCESS!" -H "X-GitHub-Api-Version: 2022-11-28" -H "User-Agent: RescueMeAI/%RECONNECT_VERSION%" "https://api.github.com/repositories/%REPO_ID%" -o "%WORK%\reconnect-repo.json" -w "%%{http_code}" >"%HTTP%" 2>"%WORK%\reconnect-curl.txt"
set "CURLRC=!errorlevel!"
set "ACCESS="
if not "!CURLRC!"=="0" goto :REAUTHORIZE
set "CODE="
if exist "%HTTP%" set /p "CODE="<"%HTTP%"
if "!CODE!"=="200" goto :AUTHORIZED
goto :REAUTHORIZE

:AUTHORIZED
echo [5/5] Authorization valid. Starting the secure recovery agent...
if not exist "%RUNTIME%" goto :RUNTIME_FAIL
if not exist "%CONFIG%" goto :RUNTIME_FAIL
cls
echo ================================================================================
echo RescueMeAI - CONNECTION VERIFIED
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo RECONNECT VERSION   : %RECONNECT_VERSION%
echo STATUS              : CONNECTED
echo NETWORK             : VERIFIED
echo AUTHORIZATION       : VALID
echo CURRENT TASK        : Starting the validated GitHub recovery agent.
echo WHAT YOU SHOULD DO  : WAIT. Leave this window open.
echo SCREENSHOT REQUIRED : NO
echo ================================================================================
call "%RUNTIME%"
exit /b !errorlevel!

:REAUTHORIZE
cls
echo ================================================================================
echo RescueMeAI - GITHUB AUTHORIZATION REQUIRED
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo RECONNECT VERSION   : %RECONNECT_VERSION%
echo STATUS              : REAUTHORIZATION REQUIRED
echo CURRENT TASK        : Starting GitHub device authorization automatically.
echo SAFETY              : CONNECTION ONLY
echo WHAT YOU SHOULD DO  : Use your phone when the short GitHub code appears.
echo SCREENSHOT REQUIRED : NO unless authorization fails.
echo ================================================================================
if exist "%BOOTSTRAP%" del /f /q "%BOOTSTRAP%" >nul 2>&1
"%CURL%" --ssl-no-revoke -fL "%BOOTSTRAP_URL%" -o "%BOOTSTRAP%"
if errorlevel 1 goto :AUTH_BOOTSTRAP_FAIL
call "%BOOTSTRAP%"
exit /b !errorlevel!

:NETWORK_FAIL
echo.
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STATUS              : NETWORK NOT READY
echo CURRENT TASK        : RescueMeAI could not restore Internet access automatically.
echo WINDOWS CHANGES     : NONE
echo REBOOT              : NO
echo SCREENSHOT REQUIRED : YES
echo WHAT YOU SHOULD DO  : Keep the Wi-Fi-profile USB inserted and send ChatGPT a photo.
echo ================================================================================
exit /b 92

:DEPENDENCY_FAIL
echo STATUS              : RECONNECT DEPENDENCY MISSING
echo SCREENSHOT REQUIRED : YES
exit /b 91

:RUNTIME_FAIL
echo STATUS              : LOCAL RECOVERY RUNTIME MISSING
echo SCREENSHOT REQUIRED : YES
exit /b 91

:AUTH_BOOTSTRAP_FAIL
echo STATUS              : REAUTHORIZATION BOOTSTRAP FAILED
echo SCREENSHOT REQUIRED : YES
echo WHAT YOU SHOULD DO  : Send ChatGPT a photo. Do not reboot.
exit /b 90
