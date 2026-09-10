@echo off
setlocal EnableExtensions EnableDelayedExpansion
title RescueMeAI - Reconnect v2

set "RECONNECT_VERSION=2026.09.10-v2"
set "FIX_VERSION=RMAI-FIX-2026.09.10.2"
set "WORK=C:\WinRERepair"
set "RUNTIME=%WORK%\runtime\device-agent-v2.cmd"
set "CONFIG=%WORK%\agent.cfg"
set "TOKEN=%WORK%\.auth\github-logs.token"
set "CURL=C:\Windows\System32\curl.exe"
set "WPE=X:\Windows\System32\wpeutil.exe"
if not exist "%WPE%" set "WPE=wpeutil.exe"
set "PING=X:\Windows\System32\ping.exe"
if not exist "%PING%" set "PING=C:\Windows\System32\ping.exe"
set "REPO_ID=1333818657"
set "HTTP=%WORK%\reconnect-http.txt"
set "BOOTSTRAP=%WORK%\connect-device-v3.cmd"
set "BOOTSTRAP_URL=https://raw.githubusercontent.com/RennieBeekharry/winre-repair/5902c7e130ca4712e3355f8bf489e37fca9d625f/connect-device-v3.cmd"

cls
echo ================================================================================
echo RescueMeAI - QUICK RECONNECT v2
echo ================================================================================
echo RECOVERY FIX      : %FIX_VERSION%
echo RECONNECT VERSION : %RECONNECT_VERSION%
echo CURRENT TASK      : Restoring network and validating the saved GitHub session.
echo SAFETY            : CONNECTION ONLY - no Windows repair is running.
echo WINDOWS CHANGES   : NONE
echo PERSONAL FILES    : NOT TOUCHED
echo REBOOT            : NO
echo WHAT YOU SHOULD DO: WAIT. Follow this screen only if it asks for authorization.
echo ================================================================================

if not exist "%CURL%" goto :DEPENDENCY_FAIL
if not exist "%WORK%" md "%WORK%" >nul 2>&1

echo [1/4] Initializing WinRE networking...
"%WPE%" InitializeNetwork >nul 2>&1

echo [2/4] Checking Internet connectivity...
"%PING%" -n 1 -w 3000 github.com >nul 2>&1
if errorlevel 1 goto :NETWORK_FAIL

echo [3/4] Validating the saved GitHub authorization...
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
if "!CODE!"=="401" goto :REAUTHORIZE
if "!CODE!"=="403" goto :REAUTHORIZE
goto :REAUTHORIZE

:AUTHORIZED
echo [4/4] Authorization is valid. Starting the secure recovery agent...
if not exist "%RUNTIME%" goto :REAUTHORIZE
if not exist "%CONFIG%" goto :REAUTHORIZE
cls
echo ================================================================================
echo RescueMeAI - CONNECTION VERIFIED
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STATUS              : CONNECTED
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
echo RescueMeAI - GITHUB AUTHORIZATION EXPIRED
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STATUS              : REAUTHORIZATION REQUIRED
echo CURRENT TASK        : Starting GitHub device authorization automatically.
echo SAFETY              : CONNECTION ONLY - no Windows repair is running.
echo WHAT YOU SHOULD DO  : Use your phone when the short GitHub code appears.
echo SCREENSHOT REQUIRED : NO unless authorization fails.
echo ================================================================================
if exist "%BOOTSTRAP%" del /f /q "%BOOTSTRAP%" >nul 2>&1
"%CURL%" --ssl-no-revoke -fL "%BOOTSTRAP_URL%" -o "%BOOTSTRAP%"
if errorlevel 1 goto :AUTH_BOOTSTRAP_FAIL
call "%BOOTSTRAP%"
exit /b !errorlevel!

:NETWORK_FAIL
color 0E >nul 2>&1
echo.
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STATUS              : NETWORK NOT READY
echo CURRENT TASK        : Waiting for WinRE network access.
echo WINDOWS CHANGES     : NONE
echo REBOOT              : NO
echo SCREENSHOT REQUIRED : YES
echo WHAT YOU SHOULD DO  : Restore the saved Wi-Fi profile, then run C:\r.cmd again.
echo ================================================================================
exit /b 92

:DEPENDENCY_FAIL
color 0C >nul 2>&1
echo.
echo STATUS              : RECONNECT DEPENDENCY MISSING
echo SCREENSHOT REQUIRED : YES
exit /b 91

:AUTH_BOOTSTRAP_FAIL
color 0C >nul 2>&1
echo.
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STATUS              : REAUTHORIZATION BOOTSTRAP FAILED
echo WINDOWS CHANGES     : NONE
echo SCREENSHOT REQUIRED : YES
echo WHAT YOU SHOULD DO  : Send ChatGPT a photo of THIS screen. Do not reboot.
echo ================================================================================
exit /b 90
