@echo off
setlocal EnableExtensions EnableDelayedExpansion

rem Persistent WinRE launcher - device login + private log upload.
rem Backward-compatibility marker for cached WR-2026.08.14-0130-ET bootstrap:
rem LAUNCHER_VERSION=WR-LAUNCHER-2026.08.14-0128-ET
set "LAUNCHER_VERSION=WR-LAUNCHER-2026.08.14-0201-ET"
set "BUILD_TIME=2026-08-14 02:01 ET"
set "WORK=C:/WinRERepair"
set "CURL=C:/Windows/System32/curl.exe"
set "WPEUTIL=X:/Windows/System32/wpeutil.exe"
set "IPCONFIG=X:/Windows/System32/ipconfig.exe"
set "PING=X:/Windows/System32/ping.exe"
set "NSLOOKUP=C:/Windows/System32/nslookup.exe"
set "FINDSTR=C:/Windows/System32/findstr.exe"
set "CERTUTIL=X:/Windows/System32/certutil.exe"
if not exist "%CERTUTIL%" set "CERTUTIL=C:/Windows/System32/certutil.exe"
set "TAR=X:/Windows/System32/tar.exe"
if not exist "%TAR%" set "TAR=C:/Windows/System32/tar.exe"
set "DNS=64.71.255.204"
set "APIHOST=api.github.com"
set "COMMAND_URL=https://api.github.com/repos/RennieBeekharry/winre-repair/contents/next.cmd?ref=main&cb=%RANDOM%%RANDOM%"
set "OUT=X:/next.cmd"
set "TMP=X:/next.cmd.tmp"
set "MANIFEST=%WORK%/upload-manifest.txt"
set "LOG_REPO=RennieBeekharry/winre-repair-logs"
set "GH_VERSION=2.97.0"
set "GH_ZIP_NAME=gh_2.97.0_windows_amd64.zip"
set "GH_SHA256=35d7fe05c4dd1411ffda1e73dfc7c6f44b75c936ca51fa6595c657fdc0350cec"
set "GH_URL=https://github.com/cli/cli/releases/download/v2.97.0/%GH_ZIP_NAME%"
set "GH_ZIP=%WORK%/%GH_ZIP_NAME%"
set "GH_STAGE=%WORK%/gh-stage"
set "GH_ROOT=%WORK%/github-cli"
set "GH=%GH_ROOT%/gh.exe"
set "GH_CONFIG_DIR=%WORK%/gh-config"
set "GH_TELEMETRY=false"
set "GH_NO_UPDATE_NOTIFIER=1"
set "DO_NOT_TRACK=1"
set "UPLOAD_COUNT=0"

if not exist "%WORK%" md "%WORK%" >nul 2>&1
if exist "%WORK%/secrets/github-log-token.txt" del /f /q "%WORK%/secrets/github-log-token.txt" >nul 2>&1

echo ================================================================
echo WINRE-REPAIR LAUNCHER
echo Version: %LAUNCHER_VERSION%
echo Built:   %BUILD_TIME%
echo ================================================================

if not exist "%CURL%" (
  echo WR FAILED: curl.exe was not found.
  exit /b 91
)

call :CHECKNET
if not errorlevel 1 (
  echo Internet: connected
  goto :NETREADY
)
echo Internet: not detected - restoring WinRE networking...
"%WPEUTIL%" InitializeNetwork >nul 2>&1
if exist "%IPCONFIG%" "%IPCONFIG%" /renew >nul 2>&1
"%PING%" -n 4 127.0.0.1 >nul 2>&1
call :CHECKNET
if not errorlevel 1 (
  echo Internet: restored
  goto :NETREADY
)
echo Internet: retrying network initialization once...
"%WPEUTIL%" InitializeNetwork >nul 2>&1
if exist "%IPCONFIG%" "%IPCONFIG%" /renew >nul 2>&1
"%PING%" -n 4 127.0.0.1 >nul 2>&1
call :CHECKNET
if not errorlevel 1 echo Internet: restored on retry

:NETREADY
if /i "%~1"=="/setup-logs" goto :SETUPLOGS

rem Fetch the latest public repair command through GitHub Contents API.
if exist "%TMP%" del /f /q "%TMP%" >nul 2>&1
if exist "%OUT%" del /f /q "%OUT%" >nul 2>&1
set "APIIP="
call :RESOLVE %APIHOST% APIIP
if defined APIIP (
  "%CURL%" --ssl-no-revoke --fail --location --silent --show-error --connect-timeout 10 --max-time 120 --resolve "%APIHOST%:443:!APIIP!" -H "Accept: application/vnd.github.raw+json" -H "X-GitHub-Api-Version: 2026-03-10" -H "Cache-Control: no-cache, no-store, max-age=0" "%COMMAND_URL%" -o "%TMP%"
)
if not exist "%TMP%" (
  "%CURL%" --ssl-no-revoke --fail --location --silent --show-error --connect-timeout 10 --max-time 120 -H "Accept: application/vnd.github.raw+json" -H "X-GitHub-Api-Version: 2026-03-10" -H "Cache-Control: no-cache, no-store, max-age=0" "%COMMAND_URL%" -o "%TMP%"
)
if not exist "%TMP%" (
  echo WR FAILED: could not download next.cmd.
  exit /b 90
)
"%FINDSTR%" /b /l /c:"@echo off" "%TMP%" >nul 2>&1
if errorlevel 1 (
  echo WR FAILED: downloaded command did not validate.
  exit /b 90
)
move /y "%TMP%" "%OUT%" >nul
set "WR_RUN_ID=WR-%RANDOM%-%RANDOM%-%RANDOM%"
set "WR_UPLOAD_MANIFEST=%MANIFEST%"
>"%MANIFEST%" type nul
call :ENSURE_AUTH
call "%OUT%"
set "COMMAND_RC=!errorlevel!"
if "!LOGAUTH!"=="1" call :UPLOAD_MANIFEST
echo.
echo Private logs uploaded: !UPLOAD_COUNT!
if not "!UPLOAD_COUNT!"=="0" echo Run ID: !WR_RUN_ID!
exit /b !COMMAND_RC!

:SETUPLOGS
set "WR_RUN_ID=WR-%RANDOM%-%RANDOM%-%RANDOM%"
>"%MANIFEST%" type nul
if not "%~2"=="" if exist "%~2" >>"%MANIFEST%" echo %~2
if not "%~3"=="" if exist "%~3" >>"%MANIFEST%" echo %~3
if not "%~4"=="" if exist "%~4" >>"%MANIFEST%" echo %~4
if not "%~5"=="" if exist "%~5" >>"%MANIFEST%" echo %~5
if not "%~6"=="" if exist "%~6" >>"%MANIFEST%" echo %~6
call :ENSURE_AUTH
if not "!LOGAUTH!"=="1" (
  echo PRIVATE LOG SETUP FAILED: GitHub device authorization did not complete.
  exit /b 95
)
call :UPLOAD_MANIFEST
if "!UPLOAD_COUNT!"=="0" (
  echo PRIVATE LOG SETUP FAILED: no diagnostic file was uploaded.
  exit /b 96
)
echo.
echo ================================================================
echo PRIVATE LOG CHANNEL READY
echo Uploaded files: !UPLOAD_COUNT!
echo Run ID: !WR_RUN_ID!
echo GitHub authorization is stored only under C:/WinRERepair/gh-config
echo ================================================================
exit /b 0

:ENSURE_AUTH
set "LOGAUTH=0"
call :ENSURE_GH
if errorlevel 1 exit /b 1
"%GH%" auth status --hostname github.com >nul 2>&1
if errorlevel 1 (
  echo.
  echo ================================================================
  echo ONE-TIME GITHUB DEVICE LOGIN
  echo GitHub CLI will display a SHORT one-time code.
  echo On your phone open: https://github.com/login/device
  echo Enter the code shown here and approve GitHub CLI access.
  echo If GitHub asks for 2FA, use your normal authenticator method.
  echo Keep this PC command window open until login finishes.
  echo ================================================================
  echo.
  "%GH%" auth login --hostname github.com --git-protocol https --web --insecure-storage --skip-ssh-key --scopes repo
  if errorlevel 1 exit /b 1
)
"%GH%" api "repos/%LOG_REPO%" --silent >nul 2>&1
if errorlevel 1 (
  echo GitHub login completed but private log repository access failed.
  exit /b 1
)
if exist "%GH_CONFIG_DIR%" attrib +h "%GH_CONFIG_DIR%" >nul 2>&1
set "LOGAUTH=1"
echo Private log authorization: verified
exit /b 0

:ENSURE_GH
if exist "%GH%" (
  "%GH%" --version >nul 2>&1
  if not errorlevel 1 exit /b 0
)
if not exist "%CERTUTIL%" (
  echo GitHub CLI setup failed: certutil.exe unavailable.
  exit /b 1
)
if not exist "%TAR%" (
  echo GitHub CLI setup failed: tar.exe unavailable.
  exit /b 1
)
echo Downloading verified portable GitHub CLI %GH_VERSION%...
if exist "%GH_ZIP%" del /f /q "%GH_ZIP%" >nul 2>&1
"%CURL%" --ssl-no-revoke --fail --location --silent --show-error --connect-timeout 15 --max-time 600 "%GH_URL%" -o "%GH_ZIP%"
if errorlevel 1 (
  echo GitHub CLI download failed.
  exit /b 1
)
"%CERTUTIL%" -hashfile "%GH_ZIP%" SHA256 | "%FINDSTR%" /i /c:"%GH_SHA256%" >nul 2>&1
if errorlevel 1 (
  echo GitHub CLI SHA-256 validation FAILED. File will not be executed.
  del /f /q "%GH_ZIP%" >nul 2>&1
  exit /b 1
)
echo GitHub CLI SHA-256: verified
if exist "%GH_STAGE%" rmdir /s /q "%GH_STAGE%" >nul 2>&1
md "%GH_STAGE%" >nul 2>&1
"%TAR%" -xf "%GH_ZIP%" -C "%GH_STAGE%" >nul 2>&1
if errorlevel 1 (
  echo GitHub CLI extraction failed.
  exit /b 1
)
set "FOUND_GH="
for /r "%GH_STAGE%" %%F in (gh.exe) do if not defined FOUND_GH set "FOUND_GH=%%F"
if not defined FOUND_GH (
  echo GitHub CLI archive did not contain gh.exe.
  exit /b 1
)
if not exist "%GH_ROOT%" md "%GH_ROOT%" >nul 2>&1
copy /y "!FOUND_GH!" "%GH%" >nul 2>&1
rmdir /s /q "%GH_STAGE%" >nul 2>&1
del /f /q "%GH_ZIP%" >nul 2>&1
"%GH%" --version
exit /b %errorlevel%

:UPLOAD_MANIFEST
set "UPLOAD_COUNT=0"
if not exist "%MANIFEST%" exit /b 0
for /f "usebackq delims=" %%F in ("%MANIFEST%") do if exist "%%F" call :UPLOAD_FILE "%%F"
exit /b 0

:UPLOAD_FILE
set "UPLOADFILE=%~1"
set "UPLOADNAME=%~nx1"
set "UPLOADNAME=!UPLOADNAME: =_!"
set "REMOTE_PATH=runs/!WR_RUN_ID!/!UPLOADNAME!"
set "B64=%WORK%/wr-upload.b64"
set "PAYLOAD=%WORK%/wr-upload.json"
for %%T in ("!B64!" "!PAYLOAD!") do if exist %%T del /f /q %%T >nul 2>&1
"%CERTUTIL%" -f -encode "!UPLOADFILE!" "!B64!" >nul 2>&1
if errorlevel 1 exit /b 1
>"!PAYLOAD!" <nul set /p "={^"message^":^"Upload WinRE diagnostic evidence !WR_RUN_ID!^",^"content^":^""
for /f "usebackq skip=1 delims=" %%L in ("!B64!") do if /i not "%%L"=="-----END CERTIFICATE-----" <nul set /p "=%%L">>"!PAYLOAD!"
>>"!PAYLOAD!" echo ^",^"branch^":^"main^"}
"%GH%" api --method PUT "repos/%LOG_REPO%/contents/!REMOTE_PATH!" --input "!PAYLOAD!" --silent >nul 2>&1
if errorlevel 1 (
  echo LOG UPLOAD FAILED: !UPLOADNAME!
) else (
  set /a UPLOAD_COUNT+=1
  echo LOG UPLOADED: !REMOTE_PATH!
)
del /f /q "!B64!" "!PAYLOAD!" >nul 2>&1
exit /b 0

:CHECKNET
"%PING%" -n 1 -w 2000 1.1.1.1 >nul 2>&1
if not errorlevel 1 exit /b 0
"%PING%" -n 1 -w 2000 8.8.8.8 >nul 2>&1
if not errorlevel 1 exit /b 0
exit /b 1

:RESOLVE
set "%~2="
set "CAND="
for /f "delims=" %%L in ('"%NSLOOKUP%" %~1 %DNS% 2^>nul ^| "%FINDSTR%" /R "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*"') do (
  for %%T in (%%L) do set "CAND=%%T"
  if not "!CAND!"=="%DNS%" set "%~2=!CAND!"
)
exit /b 0
