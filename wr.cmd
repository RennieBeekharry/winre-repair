@echo off
setlocal EnableExtensions EnableDelayedExpansion

rem Persistent WinRE launcher.
rem - Restores WinRE networking when needed.
rem - Fetches next.cmd through GitHub Contents API first.
rem - Keeps the private log token only on the local repair volume.
rem - Uploads only files explicitly listed by next.cmd in the upload manifest.
set "LAUNCHER_VERSION=WR-LAUNCHER-2026.08.14-0128-ET"
set "BUILD_TIME=2026-08-14 01:28 ET"
set "CURL=C:\Windows\System32\curl.exe"
set "WPEUTIL=X:\Windows\System32\wpeutil.exe"
set "IPCONFIG=X:\Windows\System32\ipconfig.exe"
set "PING=X:\Windows\System32\ping.exe"
set "NSLOOKUP=C:\Windows\System32\nslookup.exe"
set "FINDSTR=C:\Windows\System32\findstr.exe"
set "WORK=C:\WinRERepair"
set "SECRETDIR=%WORK%\secrets"
set "TOKENFILE=%SECRETDIR%\github-log-token.txt"
set "MANIFEST=%WORK%\upload-manifest.txt"
set "DNS=64.71.255.204"
set "APIHOST=api.github.com"
set "COMMAND_APIURL=https://api.github.com/repos/RennieBeekharry/winre-repair/contents/next.cmd?ref=main"
set "RAWURL=https://raw.githubusercontent.com/RennieBeekharry/winre-repair/main/next.cmd?cb=%RANDOM%%RANDOM%%RANDOM%"
set "LOG_REPO=RennieBeekharry/winre-repair-logs"
set "LOG_REPO_API=https://api.github.com/repos/%LOG_REPO%"
set "OUT=X:\next.cmd"
set "TMP=X:\next.cmd.tmp"
set "APIIP="
set "LOGAUTH=0"
set "UPLOAD_COUNT=0"

if not exist "%WORK%" md "%WORK%" >nul 2>&1

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

rem One-time setup mode used by the bootstrap command after this launcher is
rem first installed. It uploads already-collected diagnostic evidence only.
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

rem Log authorization is independent of the repair itself. A missing/expired
rem token disables upload but never blocks the repair command.
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
  echo PRIVATE LOG SETUP FAILED: token could not be validated.
  echo No token was uploaded or written to GitHub.
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
echo Token location: %TOKENFILE%
echo The token itself was NOT uploaded or logged.
echo ================================================================
exit /b 0

rem ---------------------------------------------------------------
rem TOKEN SETUP / VALIDATION
rem ---------------------------------------------------------------
:ENSURE_LOG_AUTH
set "LOGAUTH=0"
set "GHTOKEN="
set "TOKEN_NEW=0"
if not exist "%SECRETDIR%" md "%SECRETDIR%" >nul 2>&1

if exist "%TOKENFILE%" (
  set /p "GHTOKEN="<"%TOKENFILE%"
) else (
  echo.
  echo ================================================================
  echo ONE-TIME PRIVATE LOG AUTHORIZATION
  echo Paste the fine-grained GitHub token you created, then press ENTER.
  echo It is saved ONLY to this PC at:
  echo %TOKENFILE%
  echo.
  echo IMPORTANT: the characters will be visible briefly while pasted.
  echo They are not written to the diagnostic log or GitHub repository.
  echo ================================================================
  set /p "GHTOKEN=Token: "
  set "TOKEN_NEW=1"
  if not defined GHTOKEN (
    cls
    echo No token was entered. Private log upload disabled.
    exit /b 1
  )
  >"%TOKENFILE%" echo(!GHTOKEN!
  attrib +h "%TOKENFILE%" >nul 2>&1
  cls
  echo WINRE-REPAIR: validating private log authorization...
)

if not defined GHTOKEN exit /b 1
if not defined APIIP call :RESOLVE %APIHOST% APIIP
set "AUTHRESP=%WORK%\github-log-auth-response.json"
set "AUTHHTTP=%WORK%\github-log-auth-http.txt"
if exist "%AUTHRESP%" del /f /q "%AUTHRESP%" >nul 2>&1
if exist "%AUTHHTTP%" del /f /q "%AUTHHTTP%" >nul 2>&1

if defined APIIP (
  "%CURL%" --ssl-no-revoke --silent --location --connect-timeout 10 --max-time 60 --resolve "%APIHOST%:443:!APIIP!" -H "Accept: application/vnd.github+json" -H "Authorization: Bearer !GHTOKEN!" -H "X-GitHub-Api-Version: 2026-03-10" -o "%AUTHRESP%" -w "%%{http_code}" "%LOG_REPO_API%" >"%AUTHHTTP%" 2>nul
) else (
  "%CURL%" --ssl-no-revoke --silent --location --connect-timeout 10 --max-time 60 -H "Accept: application/vnd.github+json" -H "Authorization: Bearer !GHTOKEN!" -H "X-GitHub-Api-Version: 2026-03-10" -o "%AUTHRESP%" -w "%%{http_code}" "%LOG_REPO_API%" >"%AUTHHTTP%" 2>nul
)
set "AUTHCODE="
if exist "%AUTHHTTP%" set /p "AUTHCODE="<"%AUTHHTTP%"
if "%AUTHCODE%"=="200" (
  set "LOGAUTH=1"
  echo Private log authorization: verified
  del /f /q "%AUTHRESP%" "%AUTHHTTP%" >nul 2>&1
  exit /b 0
)

echo Private log authorization failed. GitHub HTTP: %AUTHCODE%
if "%TOKEN_NEW%"=="1" (
  del /f /q "%TOKENFILE%" >nul 2>&1
  echo The unverified token file was removed.
)
set "GHTOKEN="
del /f /q "%AUTHRESP%" "%AUTHHTTP%" >nul 2>&1
exit /b 1

rem ---------------------------------------------------------------
rem UPLOAD MANIFEST TO PRIVATE REPOSITORY
rem GitHub Contents API requires base64. certutil creates the base64 locally;
rem the token never becomes part of the payload or committed content.
rem ---------------------------------------------------------------
:UPLOAD_MANIFEST
set "UPLOAD_COUNT=0"
if not exist "%MANIFEST%" exit /b 0
if not "!LOGAUTH!"=="1" exit /b 0
set "CERTUTIL=X:\Windows\System32\certutil.exe"
if not exist "!CERTUTIL!" set "CERTUTIL=C:\Windows\System32\certutil.exe"
if not exist "!CERTUTIL!" (
  echo Private log upload skipped: certutil.exe is unavailable.
  exit /b 1
)
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
set "UPRESP=%WORK%\wr-upload-response.json"
set "UPHTTP=%WORK%\wr-upload-http.txt"
for %%T in ("!B64!" "!PAYLOAD!" "!UPRESP!" "!UPHTTP!") do if exist %%T del /f /q %%T >nul 2>&1

"!CERTUTIL!" -f -encode "!UPLOADFILE!" "!B64!" >nul 2>&1
if errorlevel 1 (
  echo LOG UPLOAD FAILED: could not encode !UPLOADNAME!
  exit /b 1
)

>"!PAYLOAD!" <nul set /p "={^"message^":^"Upload WinRE diagnostic evidence !WR_RUN_ID!^",^"content^":^""
for /f "usebackq skip=1 delims=" %%L in ("!B64!") do (
  if /i not "%%L"=="-----END CERTIFICATE-----" <nul set /p "=%%L">>"!PAYLOAD!"
)
>>"!PAYLOAD!" echo ^",^"branch^":^"main^"}

set "UPLOAD_URL=https://api.github.com/repos/%LOG_REPO%/contents/!REMOTE_PATH!"
if defined APIIP (
  "%CURL%" --ssl-no-revoke --silent --location --connect-timeout 10 --max-time 180 --resolve "%APIHOST%:443:!APIIP!" -X PUT -H "Accept: application/vnd.github+json" -H "Authorization: Bearer !GHTOKEN!" -H "X-GitHub-Api-Version: 2026-03-10" -H "Content-Type: application/json" --data-binary "@!PAYLOAD!" -o "!UPRESP!" -w "%%{http_code}" "!UPLOAD_URL!" >"!UPHTTP!" 2>nul
) else (
  "%CURL%" --ssl-no-revoke --silent --location --connect-timeout 10 --max-time 180 -X PUT -H "Accept: application/vnd.github+json" -H "Authorization: Bearer !GHTOKEN!" -H "X-GitHub-Api-Version: 2026-03-10" -H "Content-Type: application/json" --data-binary "@!PAYLOAD!" -o "!UPRESP!" -w "%%{http_code}" "!UPLOAD_URL!" >"!UPHTTP!" 2>nul
)
set "UPCODE="
if exist "!UPHTTP!" set /p "UPCODE="<"!UPHTTP!"
if "!UPCODE!"=="201" (
  set /a UPLOAD_COUNT+=1
  echo LOG UPLOADED: !REMOTE_PATH!
) else if "!UPCODE!"=="200" (
  set /a UPLOAD_COUNT+=1
  echo LOG UPDATED: !REMOTE_PATH!
) else (
  echo LOG UPLOAD FAILED: !UPLOADNAME! - GitHub HTTP !UPCODE!
)
for %%T in ("!B64!" "!PAYLOAD!" "!UPRESP!" "!UPHTTP!") do if exist %%T del /f /q %%T >nul 2>&1
exit /b 0

:MAKE_RUN_ID
set "RID_DATE=%date:/=-%"
set "RID_DATE=!RID_DATE: =_!"
set "RID_TIME=%time::=-%"
set "RID_TIME=!RID_TIME: =0!"
set "RID_TIME=!RID_TIME:.=-!"
set "RUNID=!RID_DATE!_!RID_TIME!_%RANDOM%"
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
for %%Z in ("%TMP%") do if %%~zZ LSS 1024 exit /b 1
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
