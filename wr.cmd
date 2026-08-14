@echo off
setlocal EnableExtensions EnableDelayedExpansion

rem Persistent WinRE launcher.
rem - Restores WinRE networking when needed.
rem - Fetches next.cmd through GitHub Contents API first.
rem - Uses GitHub CLI device login for private diagnostic uploads.
rem - Stores GitHub CLI auth only under C:\WinRERepair until revoked.
rem - Uploads only files explicitly listed by next.cmd in the manifest.
set "LAUNCHER_VERSION=WR-LAUNCHER-2026.08.14-0155-ET"
set "BUILD_TIME=2026-08-14 01:55 ET"
set "CURL=C:\Windows\System32\curl.exe"
set "WPEUTIL=X:\Windows\System32\wpeutil.exe"
set "IPCONFIG=X:\Windows\System32\ipconfig.exe"
set "PING=X:\Windows\System32\ping.exe"
set "NSLOOKUP=C:\Windows\System32\nslookup.exe"
set "FINDSTR=C:\Windows\System32\findstr.exe"
set "CERTUTIL=X:\Windows\System32\certutil.exe"
if not exist "%CERTUTIL%" set "CERTUTIL=C:\Windows\System32\certutil.exe"
set "TAR=X:\Windows\System32\tar.exe"
if not exist "%TAR%" set "TAR=C:\Windows\System32\tar.exe"
set "WORK=C:\WinRERepair"
set "MANIFEST=%WORK%\upload-manifest.txt"
set "DNS=64.71.255.204"
set "APIHOST=api.github.com"
set "COMMAND_APIURL=https://api.github.com/repos/RennieBeekharry/winre-repair/contents/next.cmd?ref=main"
set "RAWURL=https://raw.githubusercontent.com/RennieBeekharry/winre-repair/main/next.cmd?cb=%RANDOM%%RANDOM%%RANDOM%"
set "LOG_REPO=RennieBeekharry/winre-repair-logs"
set "OUT=X:\next.cmd"
set "TMP=X:\next.cmd.tmp"
set "APIIP="
set "LOGAUTH=0"
set "UPLOAD_COUNT=0"

rem GitHub CLI v2.97.0 is the current immutable release selected for this
rem recovery session. The SHA-256 below is the digest published by GitHub for
rem gh_2.97.0_windows_amd64.zip.
set "GH_VERSION=2.97.0"
set "GH_ZIP_NAME=gh_2.97.0_windows_amd64.zip"
set "GH_SHA256=35d7fe05c4dd1411ffda1e73dfc7c6f44b75c936ca51fa6595c657fdc0350cec"
set "GH_URL=https://github.com/cli/cli/releases/download/v2.97.0/%GH_ZIP_NAME%"
set "GH_ROOT=%WORK%\github-cli"
set "GH=%GH_ROOT%\gh.exe"
set "GH_STAGE=%WORK%\gh-stage"
set "GH_ZIP=%WORK%\%GH_ZIP_NAME%"
set "GH_CONFIG_DIR=%WORK%\gh-config"
set "GH_TELEMETRY=false"
set "GH_NO_UPDATE_NOTIFIER=1"
set "DO_NOT_TRACK=1"

if not exist "%WORK%" md "%WORK%" >nul 2>&1

rem Remove the abandoned PAT file if an earlier attempt left one behind.
if exist "%WORK%\secrets\github-log-token.txt" del /f /q "%WORK%\secrets\github-log-token.txt" >nul 2>&1

echo ================================================================
echo WINRE-REPAIR LAUNCHER
echo Version: %LAUNCHER_VERSION%
echo Built:   %BUILD_TIME%
echo ================================================================

if not exist "%CURL%" (
  echo WR FAILED: curl.exe was not found at %CURL%.
  exit /b 91
)

rem ---------------------------------------------------------------
rem NETWORK GUARD
rem ---------------------------------------------------------------
call :CHECKNET
if not errorlevel 1 (
  echo Internet: connected
  goto :NETREADY
)

echo Internet: not detected - restoring WinRE networking...
%WPEUTIL% InitializeNetwork >nul 2>&1
if exist "%IPCONFIG%" "%IPCONFIG%" /renew >nul 2>&1
%PING% -n 4 127.0.0.1 >nul 2>&1
call :CHECKNET
if not errorlevel 1 (
  echo Internet: restored
  goto :NETREADY
)

echo Internet: first recovery attempt did not verify - retrying once...
%WPEUTIL% InitializeNetwork >nul 2>&1
if exist "%IPCONFIG%" "%IPCONFIG%" /renew >nul 2>&1
%PING% -n 4 127.0.0.1 >nul 2>&1
call :CHECKNET
if not errorlevel 1 (
  echo Internet: restored on retry
  goto :NETREADY
)

echo Internet: probe still unavailable; trying GitHub transport directly.

:NETREADY
call :RESOLVE %APIHOST% APIIP
if /i "%~1"=="/setup-logs" goto :SETUPLOGS

rem ---------------------------------------------------------------
rem FETCH LATEST REPAIR COMMAND
rem ---------------------------------------------------------------
if exist "%TMP%" del /f /q "%TMP%" >nul 2>&1
if exist "%OUT%" del /f /q "%OUT%" >nul 2>&1

if defined APIIP (
  "%CURL%" --ssl-no-revoke --fail --location --silent --show-error --connect-timeout 10 --max-time 120 --resolve "%APIHOST%:443:!APIIP!" -H "Accept: application/vnd.github.raw+json" -H "X-GitHub-Api-Version: 2026-03-10" -H "Cache-Control: no-cache, no-store, max-age=0" -H "Pragma: no-cache" "%COMMAND_APIURL%" -o "%TMP%"
  if not errorlevel 1 call :VALIDATE API
  if exist "%OUT%" goto :GOT
)

if exist "%TMP%" del /f /q "%TMP%" >nul 2>&1
"%CURL%" --ssl-no-revoke --fail --location --silent --show-error --connect-timeout 10 --max-time 120 -H "Accept: application/vnd.github.raw+json" -H "X-GitHub-Api-Version: 2026-03-10" -H "Cache-Control: no-cache, no-store, max-age=0" -H "Pragma: no-cache" "%COMMAND_APIURL%" -o "%TMP%"
if not errorlevel 1 call :VALIDATE API-DNS
if exist "%OUT%" goto :GOT

if exist "%TMP%" del /f /q "%TMP%" >nul 2>&1
for %%I in (185.199.108.133 185.199.109.133 185.199.110.133 185.199.111.133) do (
  "%CURL%" --ssl-no-revoke --fail --location --silent --show-error --connect-timeout 10 --max-time 120 --resolve "raw.githubusercontent.com:443:%%I" -H "Cache-Control: no-cache, no-store, max-age=0" -H "Pragma: no-cache" "%RAWURL%" -o "%TMP%"
  if not errorlevel 1 call :VALIDATE RAW
  if exist "%OUT%" goto :GOT
)

echo.
echo WR FAILED: Internet/GitHub transport could not be restored.
echo No repair command was executed.
exit /b 90

:GOT
echo Transport: !TRANSPORT!
set "FETCHEDVER=unknown"
for /f "tokens=2 delims==" %%V in ('%FINDSTR% /b /c:"set \"COMMAND_VERSION=" "%OUT%" 2^>nul') do set "FETCHEDVER=%%~V"
echo Command:   !FETCHEDVER!

call :MAKE_RUN_ID
set "WR_RUN_ID=!RUNID!"
set "WR_UPLOAD_MANIFEST=%MANIFEST%"
>"%MANIFEST%" type nul

call :ENSURE_LOG_AUTH
if not "!LOGAUTH!"=="1" echo Private log upload: unavailable for this run

call "%OUT%"
set "COMMAND_RC=!errorlevel!"
if "!LOGAUTH!"=="1" call :UPLOAD_MANIFEST

echo.
if "!UPLOAD_COUNT!"=="0" (
  echo Private logs uploaded: 0
) else (
  echo Private logs uploaded: !UPLOAD_COUNT!
  echo Run ID: !WR_RUN_ID!
)
exit /b !COMMAND_RC!

rem ---------------------------------------------------------------
rem ONE-TIME EXISTING-LOG SETUP MODE
rem ---------------------------------------------------------------
:SETUPLOGS
call :MAKE_RUN_ID
set "WR_RUN_ID=!RUNID!"
set "WR_UPLOAD_MANIFEST=%MANIFEST%"
>"%MANIFEST%" type nul
if not "%~2"=="" if exist "%~2" >>"%MANIFEST%" echo %~2
if not "%~3"=="" if exist "%~3" >>"%MANIFEST%" echo %~3
if not "%~4"=="" if exist "%~4" >>"%MANIFEST%" echo %~4
if not "%~5"=="" if exist "%~5" >>"%MANIFEST%" echo %~5
if not "%~6"=="" if exist "%~6" >>"%MANIFEST%" echo %~6

call :ENSURE_LOG_AUTH
if not "!LOGAUTH!"=="1" (
  echo.
  echo PRIVATE LOG SETUP FAILED: GitHub device authorization did not complete.
  exit /b 95
)
call :UPLOAD_MANIFEST
if "!UPLOAD_COUNT!"=="0" (
  echo.
  echo PRIVATE LOG SETUP COMPLETE, BUT NO LOG FILE WAS UPLOADED.
  exit /b 96
)

echo.
echo ================================================================
echo PRIVATE LOG CHANNEL READY
echo Uploaded files: !UPLOAD_COUNT!
echo Run ID: !WR_RUN_ID!
echo GitHub CLI auth is stored locally under: %GH_CONFIG_DIR%
echo Revoke/logout after recovery is complete.
echo ================================================================
exit /b 0

rem ---------------------------------------------------------------
rem GITHUB CLI + DEVICE AUTHORIZATION
rem ---------------------------------------------------------------
:ENSURE_LOG_AUTH
set "LOGAUTH=0"
call :ENSURE_GH
if errorlevel 1 exit /b 1
call :PREP_GH_HOSTS

"%GH%" auth status --hostname github.com >nul 2>&1
if errorlevel 1 (
  echo.
  echo ================================================================
  echo ONE-TIME GITHUB DEVICE LOGIN
  echo No long token is required.
  echo.
  echo GitHub CLI will display a SHORT one-time code.
  echo On your phone open:
  echo   https://github.com/login/device
  echo Enter the code shown here and approve GitHub CLI access.
  echo Keep this command window open while you approve it.
  echo ================================================================
  echo.
  "%GH%" auth login --hostname github.com --git-protocol https --web --insecure-storage --skip-ssh-key --scopes repo
  if errorlevel 1 (
    echo GitHub device login did not complete.
    exit /b 1
  )
)

"%GH%" api "repos/%LOG_REPO%" --silent >nul 2>&1
if errorlevel 1 (
  echo GitHub login succeeded, but the private log repository is not accessible.
  exit /b 1
)
if exist "%GH_CONFIG_DIR%" attrib +h "%GH_CONFIG_DIR%" >nul 2>&1
set "LOGAUTH=1"
echo Private log authorization: verified through GitHub device login
exit /b 0

:ENSURE_GH
if exist "%GH%" (
  "%GH%" --version >nul 2>&1
  if not errorlevel 1 exit /b 0
)
if not exist "%CERTUTIL%" (
  echo GitHub CLI setup failed: certutil.exe is unavailable.
  exit /b 1
)
if not exist "%TAR%" (
  echo GitHub CLI setup failed: tar.exe is unavailable.
  exit /b 1
)

echo Installing verified portable GitHub CLI %GH_VERSION% for device login...
if exist "%GH_ZIP%" del /f /q "%GH_ZIP%" >nul 2>&1
call :DOWNLOAD_GH_ZIP
if errorlevel 1 (
  echo GitHub CLI download failed.
  exit /b 1
)

"%CERTUTIL%" -hashfile "%GH_ZIP%" SHA256 | %FINDSTR% /i /c:"%GH_SHA256%" >nul 2>&1
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
if not exist "%GH%" (
  echo GitHub CLI installation failed.
  exit /b 1
)
rmdir /s /q "%GH_STAGE%" >nul 2>&1
del /f /q "%GH_ZIP%" >nul 2>&1
"%GH%" --version
if errorlevel 1 exit /b 1
exit /b 0

:DOWNLOAD_GH_ZIP
set "GH_HEADERS=%WORK%\gh-release-headers.txt"
set "GH_REDIRECT="
set "GH_WEBIP="
set "GH_ASSET_HOST="
set "GH_ASSET_IP="
if exist "%GH_HEADERS%" del /f /q "%GH_HEADERS%" >nul 2>&1
call :RESOLVE github.com GH_WEBIP
if defined GH_WEBIP (
  "%CURL%" --ssl-no-revoke --fail --silent --show-error --connect-timeout 10 --max-time 60 --resolve "github.com:443:!GH_WEBIP!" -D "%GH_HEADERS%" -o NUL "%GH_URL%" >nul 2>&1
  for /f "tokens=1,*" %%A in ('%FINDSTR% /b /i /c:"location:" "%GH_HEADERS%" 2^>nul') do if not defined GH_REDIRECT set "GH_REDIRECT=%%B"
)
if defined GH_REDIRECT (
  for /f "tokens=2 delims=/" %%H in ("!GH_REDIRECT!") do set "GH_ASSET_HOST=%%H"
  if defined GH_ASSET_HOST call :RESOLVE !GH_ASSET_HOST! GH_ASSET_IP
  if defined GH_ASSET_IP (
    "%CURL%" --ssl-no-revoke --fail --location --silent --show-error --connect-timeout 15 --max-time 600 --resolve "!GH_ASSET_HOST!:443:!GH_ASSET_IP!" "!GH_REDIRECT!" -o "%GH_ZIP%"
    if not errorlevel 1 goto :GH_DOWNLOAD_OK
  )
)

rem Normal DNS fallback if the explicit redirect path was unavailable.
"%CURL%" --ssl-no-revoke --fail --location --silent --show-error --connect-timeout 15 --max-time 600 "%GH_URL%" -o "%GH_ZIP%"
if errorlevel 1 exit /b 1

:GH_DOWNLOAD_OK
for %%Z in ("%GH_ZIP%") do if %%~zZ LSS 10000000 exit /b 1
exit /b 0

rem Pin github.com and api.github.com only inside the current WinRE RAM disk.
rem This makes GitHub CLI resilient when WinRE DHCP works but DNS does not.
:PREP_GH_HOSTS
set "HOSTS=X:\Windows\System32\drivers\etc\hosts"
set "HOSTSTMP=%WORK%\hosts.wr.tmp"
set "WEBIP="
set "RESTIP="
call :RESOLVE github.com WEBIP
call :RESOLVE api.github.com RESTIP
if not defined WEBIP exit /b 0
if not defined RESTIP exit /b 0
if exist "%HOSTS%" (
  %FINDSTR% /v /c:"# WR-GH" "%HOSTS%" >"%HOSTSTMP%" 2>nul
) else (
  >"%HOSTSTMP%" type nul
)
>>"%HOSTSTMP%" echo !WEBIP! github.com # WR-GH
>>"%HOSTSTMP%" echo !RESTIP! api.github.com # WR-GH
copy /y "%HOSTSTMP%" "%HOSTS%" >nul 2>&1
del /f /q "%HOSTSTMP%" >nul 2>&1
exit /b 0

rem ---------------------------------------------------------------
rem UPLOAD MANIFEST TO PRIVATE REPOSITORY USING gh api
rem ---------------------------------------------------------------
:UPLOAD_MANIFEST
set "UPLOAD_COUNT=0"
if not exist "%MANIFEST%" exit /b 0
if not "!LOGAUTH!"=="1" exit /b 0
if not exist "%CERTUTIL%" exit /b 1
for /f "usebackq delims=" %%F in ("%MANIFEST%") do (
  if exist "%%F" call :UPLOAD_FILE "%%F"
)
exit /b 0

:UPLOAD_FILE
set "UPLOADFILE=%~1"
set "UPLOADNAME=%~nx1"
set "UPLOADNAME=!UPLOADNAME: =_!"
set "REMOTE_PATH=runs/!WR_RUN_ID!/!UPLOADNAME!"
set "B64=%WORK%\wr-upload.b64"
set "PAYLOAD=%WORK%\wr-upload.json"
for %%T in ("!B64!" "!PAYLOAD!") do if exist %%T del /f /q %%T >nul 2>&1

"%CERTUTIL%" -f -encode "!UPLOADFILE!" "!B64!" >nul 2>&1
if errorlevel 1 (
  echo LOG UPLOAD FAILED: could not encode !UPLOADNAME!
  exit /b 1
)

>"!PAYLOAD!" <nul set /p "={^"message^":^"Upload WinRE diagnostic evidence !WR_RUN_ID!^",^"content^":^""
for /f "usebackq skip=1 delims=" %%L in ("!B64!") do (
  if /i not "%%L"=="-----END CERTIFICATE-----" <nul set /p "=%%L">>"!PAYLOAD!"
)
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

:MAKE_RUN_ID
set "RUNID=WR-%RANDOM%-%RANDOM%"
set "TODAY=%date%"
set "NOW=%time: =0%"
set "NOW=!NOW::=!"
set "NOW=!NOW:.=!"
for /f "tokens=1-4 delims=/ " %%A in ("%date%") do (
  if not "%%D"=="" set "RUNID=WR-%%D%%B%%C-!NOW!"
)
exit /b 0

:CHECKNET
%PING% -n 1 -w 2000 1.1.1.1 >nul 2>&1
if not errorlevel 1 exit /b 0
%PING% -n 1 -w 2000 8.8.8.8 >nul 2>&1
if not errorlevel 1 exit /b 0
exit /b 1

:VALIDATE
set "TRANSPORT=%~1"
if not exist "%TMP%" exit /b 1
for %%Z in ("%TMP%") do if %%~zZ LSS 512 exit /b 1
%FINDSTR% /b /l /c:"@echo off" "%TMP%" >nul 2>&1
if errorlevel 1 exit /b 1
%FINDSTR% /l /c:"COMMAND_VERSION=WR-" "%TMP%" >nul 2>&1
if errorlevel 1 exit /b 1
move /y "%TMP%" "%OUT%" >nul
exit /b 0

:RESOLVE
set "%~2="
set "CAND="
for /f "delims=" %%L in ('%NSLOOKUP% %~1 %DNS% 2^>nul ^| %FINDSTR% /R "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*"') do (
  for %%T in (%%L) do set "CAND=%%T"
  if not "!CAND!"=="%DNS%" set "%~2=!CAND!"
)
exit /b 0
