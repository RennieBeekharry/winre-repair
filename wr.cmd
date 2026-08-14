@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "LAUNCHER_VERSION=WR-LAUNCHER-2026.08.14-0932-ET"
set "BUILD_TIME=2026-08-14 09:32 ET"
set "CURL=C:\Windows\System32\curl.exe"
set "CERTUTIL=C:\Windows\System32\certutil.exe"
set "WPEUTIL=X:\Windows\System32\wpeutil.exe"
set "PING=X:\Windows\System32\ping.exe"
set "NSLOOKUP=C:\Windows\System32\nslookup.exe"
set "FINDSTR=C:\Windows\System32\findstr.exe"
set "DNS=64.71.255.204"
set "APIHOST=api.github.com"
set "URL=https://api.github.com/repos/RennieBeekharry/winre-repair/contents/next.cmd?ref=main"
set "LOGREPO=RennieBeekharry/winre-repair-logs"
set "OUT=X:\next.cmd"
set "TMP=X:\next.cmd.tmp"
set "WORK=C:\WinRERepair"
set "REPORT=%WORK%\LAST_RUN_REPORT.txt"
set "DETAILS=%WORK%\RUN_DETAILS.txt"
set "TOKENFILE=%WORK%\.auth\github-logs.token"
set "UPLOADSRC=%WORK%\PRIVATE_UPLOAD_REPORT.txt"
set "B64FILE=%WORK%\PRIVATE_UPLOAD_REPORT.b64"
set "B64CLEAN=%WORK%\PRIVATE_UPLOAD_REPORT.base64.txt"
set "JSONFILE=%WORK%\PRIVATE_UPLOAD_REQUEST.json"
set "RESPFILE=%WORK%\PRIVATE_UPLOAD_RESPONSE.json"

if not exist "%WORK%" md "%WORK%" >nul 2>&1
if exist "%DETAILS%" del /f /q "%DETAILS%" >nul 2>&1

echo ================================================================
echo WINRE-REPAIR LAUNCHER
echo Version: %LAUNCHER_VERSION%
echo Built:   %BUILD_TIME%
echo ================================================================

if not exist "%CURL%" (
  set "RC=91"
  goto :RESULT
)
"%PING%" -n 1 -w 2000 1.1.1.1 >nul 2>&1
if errorlevel 1 "%WPEUTIL%" InitializeNetwork >nul 2>&1

if exist "%TMP%" del /f /q "%TMP%" >nul 2>&1
if exist "%OUT%" del /f /q "%OUT%" >nul 2>&1

call :RESOLVE %APIHOST% APIIP
call :FETCHPUBLIC "%URL%" "%TMP%"
if errorlevel 1 (
  set "RC=90"
  goto :RESULT
)
"%FINDSTR%" /b /l /c:"@echo off" "%TMP%" >nul 2>&1
if errorlevel 1 (
  del /f /q "%TMP%" >nul 2>&1
  set "RC=90"
  goto :RESULT
)
move /y "%TMP%" "%OUT%" >nul
call "%OUT%"
set "RC=!errorlevel!"

:RESULT
set "RUNVERSION=UNKNOWN"
if exist "%OUT%" (
  for /f "tokens=2 delims==" %%V in ('"%FINDSTR%" /b /i /c:"set \"COMMAND_VERSION=" "%OUT%" 2^>nul') do set "RUNVERSION=%%~V"
  set "RUNVERSION=!RUNVERSION:\"=!"
  set "RUNVERSION=!RUNVERSION:"=!"
)

set "WRSTATUS=WARNING"
set "STATUSCOLOR=0E"
set "STATUSMESSAGE=Run completed with a condition that needs review."
set "REPLYWORD=warning"
if "!RC!"=="0" (
  set "WRSTATUS=PASS"
  set "STATUSCOLOR=0A"
  set "STATUSMESSAGE=Run completed successfully."
  set "REPLYWORD=pass"
) else (
  if !RC! GEQ 80 (
    set "WRSTATUS=FAIL"
    set "STATUSCOLOR=0C"
    set "STATUSMESSAGE=Run stopped because a required step failed."
    set "REPLYWORD=fail"
  )
)

>"%REPORT%" echo status=!WRSTATUS!
>>"%REPORT%" echo return_code=!RC!
>>"%REPORT%" echo launcher_version=%LAUNCHER_VERSION%
>>"%REPORT%" echo command_version=!RUNVERSION!
>>"%REPORT%" echo date=%date%
>>"%REPORT%" echo time=%time%
>>"%REPORT%" echo message=!STATUSMESSAGE!

rem Keep a local/USB copy regardless of private upload availability.
set "REPORTVOL="
for %%D in (D E F G H I J K L M N O P Q R S T U V W Y Z) do (
  if exist %%D:\ (
    vol %%D: >"%WORK%\vol-report-%%D.txt" 2>&1
    "%FINDSTR%" /i /c:"REPAIRDATA" "%WORK%\vol-report-%%D.txt" >nul 2>&1
    if not errorlevel 1 set "REPORTVOL=%%D:"
  )
)
if defined REPORTVOL (
  if not exist "!REPORTVOL!\RecoverySource" md "!REPORTVOL!\RecoverySource" >nul 2>&1
  copy /y "%REPORT%" "!REPORTVOL!\RecoverySource\LAST_RUN_REPORT.txt" >nul 2>&1
  if exist "%DETAILS%" copy /y "%DETAILS%" "!REPORTVOL!\RecoverySource\RUN_DETAILS.txt" >nul 2>&1
)

set "UPLOADSTATUS=NOT_AUTHORIZED"
set "UPLOADPATH="
if exist "%TOKENFILE%" call :UPLOADPRIVATE

rem A successful repair with a reporting failure becomes WARNING so evidence is not silently lost.
if /i "!WRSTATUS!"=="PASS" if /i not "!UPLOADSTATUS!"=="PASS" (
  set "WRSTATUS=WARNING"
  set "STATUSCOLOR=0E"
  set "STATUSMESSAGE=Repair action passed, but the private recovery report was not uploaded."
  set "REPLYWORD=warning"
)

color !STATUSCOLOR! >nul 2>&1
echo.
echo ================================================================
echo [!WRSTATUS!]  WINRE-REPAIR RESULT
echo ================================================================
echo !STATUSMESSAGE!
echo Return code          : !RC!
echo Launcher             : %LAUNCHER_VERSION%
echo Command              : !RUNVERSION!
echo Private report upload: !UPLOADSTATUS!
if defined UPLOADPATH echo Private report path  : !UPLOADPATH!
echo Local report         : %REPORT%
if defined REPORTVOL echo USB report           : !REPORTVOL!\RecoverySource\LAST_RUN_REPORT.txt
echo ---------------------------------------------------------------
echo Reply to ChatGPT with one word only: !REPLYWORD!
echo ================================================================
exit /b !RC!

:UPLOADPRIVATE
if not exist "%CERTUTIL%" (
  set "UPLOADSTATUS=FAIL_NO_CERTUTIL"
  exit /b 1
)
set "LOGTOKEN="
set /p "LOGTOKEN="<"%TOKENFILE%"
if not defined LOGTOKEN (
  set "UPLOADSTATUS=FAIL_EMPTY_TOKEN"
  exit /b 1
)

>"%UPLOADSRC%" echo PRIVATE WINRE RECOVERY RUN REPORT
>>"%UPLOADSRC%" echo ==================================
type "%REPORT%" >>"%UPLOADSRC%"
if exist "%DETAILS%" (
  >>"%UPLOADSRC%" echo.
  >>"%UPLOADSRC%" echo --- RUN_DETAILS ---
  type "%DETAILS%" >>"%UPLOADSRC%"
)

"%CERTUTIL%" -f -encode "%UPLOADSRC%" "%B64FILE%" >nul 2>&1
if errorlevel 1 (
  set "UPLOADSTATUS=FAIL_ENCODE"
  set "LOGTOKEN="
  exit /b 1
)
"%FINDSTR%" /v /c:"-----" /c:"CertUtil" "%B64FILE%" >"%B64CLEAN%" 2>nul
set "B64="
for /f "usebackq delims=" %%L in ("%B64CLEAN%") do set "B64=!B64!%%L"
if not defined B64 (
  set "UPLOADSTATUS=FAIL_ENCODE"
  set "LOGTOKEN="
  exit /b 1
)

set "SAFEVER=!RUNVERSION::=_!"
set "SAFEVER=!SAFEVER:/=_!"
set "UPLOADPATH=reports/inbox/run-!SAFEVER!-%RANDOM%%RANDOM%.txt"
>"%JSONFILE%" echo {"message":"WinRE recovery report !SAFEVER!","content":"!B64!"}
set "PUTURL=https://api.github.com/repos/%LOGREPO%/contents/!UPLOADPATH!"
set "HTTP="
if defined APIIP (
  for /f %%H in ('"%CURL%" --ssl-no-revoke --silent --show-error --connect-timeout 15 --max-time 120 --resolve "%APIHOST%:443:!APIIP!" -X PUT -H "Accept: application/vnd.github+json" -H "Authorization: Bearer !LOGTOKEN!" -H "X-GitHub-Api-Version: 2022-11-28" -H "Content-Type: application/json" --data-binary "@%JSONFILE%" -o "%RESPFILE%" -w "%%{http_code}" "%PUTURL%"') do set "HTTP=%%H"
) else (
  for /f %%H in ('"%CURL%" --ssl-no-revoke --silent --show-error --connect-timeout 15 --max-time 120 -X PUT -H "Accept: application/vnd.github+json" -H "Authorization: Bearer !LOGTOKEN!" -H "X-GitHub-Api-Version: 2022-11-28" -H "Content-Type: application/json" --data-binary "@%JSONFILE%" -o "%RESPFILE%" -w "%%{http_code}" "%PUTURL%"') do set "HTTP=%%H"
)
set "LOGTOKEN="
if "!HTTP!"=="201" (
  set "UPLOADSTATUS=PASS"
  exit /b 0
)
set "UPLOADSTATUS=FAIL_HTTP_!HTTP!"
exit /b 1

:FETCHPUBLIC
set "FETCHURL=%~1"
set "FETCHOUT=%~2"
if defined APIIP (
  "%CURL%" --ssl-no-revoke --fail --silent --show-error --connect-timeout 10 --max-time 120 --resolve "%APIHOST%:443:!APIIP!" -H "Accept: application/vnd.github.raw+json" -H "Cache-Control: no-cache, no-store, max-age=0" "%FETCHURL%" -o "%FETCHOUT%"
) else (
  "%CURL%" --ssl-no-revoke --fail --silent --show-error --connect-timeout 10 --max-time 120 -H "Accept: application/vnd.github.raw+json" -H "Cache-Control: no-cache, no-store, max-age=0" "%FETCHURL%" -o "%FETCHOUT%"
)
if errorlevel 1 exit /b 1
if not exist "%FETCHOUT%" exit /b 1
for %%Z in ("%FETCHOUT%") do if %%~zZ LSS 32 exit /b 1
exit /b 0

:RESOLVE
set "%~2="
set "CAND="
for /f "delims=" %%L in ('"%NSLOOKUP%" %~1 %DNS% 2^>nul ^| "%FINDSTR%" /R "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*"') do (
  for %%T in (%%L) do set "CAND=%%T"
  if not "!CAND!"=="%DNS%" set "%~2=!CAND!"
)
exit /b 0
