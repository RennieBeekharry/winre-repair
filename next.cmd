@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "COMMAND_VERSION=WR-2026.08.14-0940-ET"
set "BUILD_TIME=2026-08-14 09:40 ET"
set "WORK=C:\WinRERepair"
set "AUTHDIR=%WORK%\.auth"
set "TOKENFILE=%AUTHDIR%\github-logs.token"
set "REPORT=%WORK%\LAST_RUN_REPORT.txt"
set "DETAILS=%WORK%\RUN_DETAILS.txt"
set "CURL=C:\Windows\System32\curl.exe"
set "CERTUTIL=C:\Windows\System32\certutil.exe"
set "NSLOOKUP=C:\Windows\System32\nslookup.exe"
set "FINDSTR=C:\Windows\System32\findstr.exe"
set "DNS=64.71.255.204"
set "APIHOST=api.github.com"
set "LOGREPO=RennieBeekharry/winre-repair-logs"
set "LAUNCHERURL=https://api.github.com/repos/RennieBeekharry/winre-repair/contents/wr.cmd?ref=main"
set "NEWLAUNCHER=C:\wr.new.cmd"
set "UPGRADE=X:\wr-private-upgrade.cmd"
set "UPLOADSRC=%WORK%\PRIVATE_BOOTSTRAP_REPORT.txt"
set "B64FILE=%WORK%\PRIVATE_BOOTSTRAP_REPORT.b64"
set "B64CLEAN=%WORK%\PRIVATE_BOOTSTRAP_REPORT.base64.txt"
set "JSONFILE=%WORK%\PRIVATE_BOOTSTRAP_REQUEST.json"
set "RESPFILE=%WORK%\PRIVATE_BOOTSTRAP_RESPONSE.json"
set "MAXATTEMPTS=5"

cls
echo ================================================================
echo WINRE-REPAIR - PRIVATE REPORTING BOOTSTRAP
echo Version: %COMMAND_VERSION%
echo Built:   %BUILD_TIME%
echo ================================================================
echo Purpose: authorize automatic diagnostic uploads to the private
echo          winre-repair-logs repository.
echo Token retries: up to %MAXATTEMPTS% attempts; bad tokens are never saved.
echo Disk/filesystem management operations in this build: NONE
echo Windows repair operations in this build: NONE
echo ================================================================

if not exist "%WORK%" md "%WORK%" >nul 2>&1
if not exist "%AUTHDIR%" md "%AUTHDIR%" >nul 2>&1
if not exist "%CURL%" goto :TOOLSFAIL
if not exist "%CERTUTIL%" goto :TOOLSFAIL
if not exist "%NSLOOKUP%" goto :TOOLSFAIL
if not exist "%FINDSTR%" goto :TOOLSFAIL

call :RESOLVE %APIHOST% APIIP

rem If a credential was previously saved, validate it first. If rejected,
rem explain why, remove it, and fall through to the retry-safe prompt.
set "LOGTOKEN="
if exist "%TOKENFILE%" set /p "LOGTOKEN="<"%TOKENFILE%"
if defined LOGTOKEN (
  call :TESTUPLOAD
  if not errorlevel 1 goto :AUTHORIZED
  call :SETREASON
  cls
  color 0E >nul 2>&1
  echo ================================================================
  echo [WARNING] SAVED TOKEN WAS REJECTED
  echo ================================================================
  echo GitHub HTTP : !HTTP!
  echo Reason      : !AUTHREASON!
  echo Action      : Saved token removed; you can enter a new one.
  echo ================================================================
  set "LOGTOKEN="
  attrib -h -s "%TOKENFILE%" >nul 2>&1
  del /f /q "%TOKENFILE%" >nul 2>&1
  ping -n 3 127.0.0.1 >nul
)

set /a ATTEMPT=1

:TOKENPROMPT
if !ATTEMPT! GTR %MAXATTEMPTS% goto :ATTEMPTSUSED
set "LOGTOKEN="
set "HTTP="
set "AUTHREASON="
cls
color 07 >nul 2>&1
echo ================================================================
echo ONE-TIME PRIVATE LOG AUTHORIZATION
echo Attempt !ATTEMPT! of %MAXATTEMPTS%
echo ================================================================
echo Paste the ACTUAL fine-grained GitHub token for ONLY:
echo   %LOGREPO%
echo Required permission: Contents = Read and write
echo.
echo The token will NOT be uploaded in a report or committed to Git.
echo A token is saved only AFTER GitHub accepts a test upload.
echo.
echo Paste the token and press ENTER.
echo ================================================================

rem Hide the token while it is being typed/pasted.
color 00 >nul 2>&1
set /p "LOGTOKEN="
color 07 >nul 2>&1
cls

if not defined LOGTOKEN (
  set "HTTP=LOCAL"
  set "AUTHREASON=Blank input - no token was entered."
  goto :REJECTED
)

call :TESTUPLOAD
if not errorlevel 1 goto :SAVETOKEN
call :SETREASON

:REJECTED
set "LOGTOKEN="
color 0C >nul 2>&1
echo ================================================================
echo [FAIL] TOKEN AUTHORIZATION ATTEMPT !ATTEMPT! FAILED
echo ================================================================
echo GitHub HTTP : !HTTP!
echo Reason      : !AUTHREASON!
echo Saved       : NO
echo ---------------------------------------------------------------
echo You may try again. The program will not crash or keep the bad token.
echo ================================================================
set /a ATTEMPT+=1
if !ATTEMPT! LEQ %MAXATTEMPTS% (
  ping -n 3 127.0.0.1 >nul
  goto :TOKENPROMPT
)
goto :ATTEMPTSUSED

:SAVETOKEN
>"%TOKENFILE%" echo(!LOGTOKEN!
attrib +h +s "%TOKENFILE%" >nul 2>&1
attrib +h "%AUTHDIR%" >nul 2>&1
set "LOGTOKEN="
goto :AUTHORIZED

:AUTHORIZED
set "LOGTOKEN="

rem Stage the permanent launcher with automatic private uploads.
if exist "%NEWLAUNCHER%" del /f /q "%NEWLAUNCHER%" >nul 2>&1
call :FETCHPUBLIC "%LAUNCHERURL%" "%NEWLAUNCHER%"
if errorlevel 1 (
  color 0E >nul 2>&1
  echo ================================================================
  echo [WARNING] TOKEN ACCEPTED, BUT LAUNCHER UPDATE FAILED
  echo ================================================================
  echo The valid token was saved locally.
  echo Rerun C:\wr.cmd; authorization will be reused automatically.
  echo ================================================================
  exit /b 40
)
"%FINDSTR%" /i /c:"WR-LAUNCHER-2026.08.14-0932-ET" "%NEWLAUNCHER%" >nul 2>&1
if errorlevel 1 (
  del /f /q "%NEWLAUNCHER%" >nul 2>&1
  color 0E >nul 2>&1
  echo ================================================================
  echo [WARNING] TOKEN ACCEPTED, BUT LAUNCHER VALIDATION FAILED
  echo ================================================================
  echo The valid token was saved locally.
  echo Rerun C:\wr.cmd after the launcher is corrected.
  echo ================================================================
  exit /b 40
)

>"%UPGRADE%" echo @echo off
>>"%UPGRADE%" echo ping -n 5 127.0.0.1 ^>nul
>>"%UPGRADE%" echo copy /y "C:\wr.new.cmd" "C:\wr.cmd" ^>nul 2^>^&1
>>"%UPGRADE%" echo del /f /q "C:\wr.new.cmd" ^>nul 2^>^&1
start "" /b cmd.exe /c call "%UPGRADE%" >nul 2>&1

color 0A >nul 2>&1
echo ================================================================
echo [PASS] PRIVATE RECOVERY REPORTING ENABLED
echo ================================================================
echo Private repo        : %LOGREPO%
echo GitHub test upload  : ACCEPTED
echo Previous run report : UPLOADED
echo Permanent launcher  : WR-LAUNCHER-2026.08.14-0932-ET staged
echo.
echo Future runs will automatically upload compact diagnostic evidence.
echo Reply to ChatGPT with one word only: pass
echo ================================================================
exit /b 0

:ATTEMPTSUSED
set "LOGTOKEN="
color 0C >nul 2>&1
echo ================================================================
echo [FAIL] PRIVATE LOG AUTHORIZATION NOT COMPLETED
echo ================================================================
echo All %MAXATTEMPTS% attempts were used.
echo No rejected token was saved.
echo You can safely rerun C:\wr.cmd later to get another %MAXATTEMPTS% attempts.
echo ================================================================
exit /b 90

:TOOLSFAIL
color 0C >nul 2>&1
echo ================================================================
echo [FAIL] REQUIRED WINRE TOOL IS MISSING
echo ================================================================
echo Token authorization was not attempted and no token was saved.
echo ================================================================
exit /b 91

:SETREASON
set "AUTHREASON=GitHub rejected the authorization request."
if not defined HTTP set "HTTP=000"
if "!HTTP!"=="000" set "AUTHREASON=No GitHub API response - network, DNS, TLS, or connection failure."
if "!HTTP!"=="401" set "AUTHREASON=Bad credentials - token is mistyped, invalid, expired, or revoked."
if "!HTTP!"=="403" (
  set "AUTHREASON=Token was recognized but GitHub forbids this write - check repository access and Contents: Read and write permission."
  if exist "%RESPFILE%" (
    "%FINDSTR%" /i /c:"rate limit" "%RESPFILE%" >nul 2>&1
    if not errorlevel 1 set "AUTHREASON=GitHub rate limit or abuse protection blocked the request; token may still be valid."
  )
)
if "!HTTP!"=="404" set "AUTHREASON=Token cannot access the private winre-repair-logs repository, or that repository was not selected for the token."
if "!HTTP!"=="409" set "AUTHREASON=GitHub repository state conflict; token may be valid but the upload could not be committed."
if "!HTTP!"=="422" set "AUTHREASON=GitHub accepted authentication but rejected the upload request as invalid; this is not necessarily a bad token."
if "!HTTP!"=="429" set "AUTHREASON=GitHub rate limit reached; wait and retry later."
if "!HTTP:~0,1!"=="5" set "AUTHREASON=Temporary GitHub server error; token may be valid."
exit /b 0

:TESTUPLOAD
set "HTTP=000"
if exist "%RESPFILE%" del /f /q "%RESPFILE%" >nul 2>&1
>"%UPLOADSRC%" echo PRIVATE WINRE REPORTING BOOTSTRAP
>>"%UPLOADSRC%" echo bootstrap_version=%COMMAND_VERSION%
>>"%UPLOADSRC%" echo date=%date%
>>"%UPLOADSRC%" echo time=%time%
if exist "%REPORT%" (
  >>"%UPLOADSRC%" echo.
  >>"%UPLOADSRC%" echo --- PREVIOUS_LAST_RUN_REPORT ---
  type "%REPORT%" >>"%UPLOADSRC%"
) else (
  >>"%UPLOADSRC%" echo previous_report=NOT_FOUND
)
if exist "%DETAILS%" (
  >>"%UPLOADSRC%" echo.
  >>"%UPLOADSRC%" echo --- PREVIOUS_RUN_DETAILS ---
  type "%DETAILS%" >>"%UPLOADSRC%"
)

"%CERTUTIL%" -f -encode "%UPLOADSRC%" "%B64FILE%" >nul 2>&1
if errorlevel 1 (
  set "HTTP=LOCAL"
  set "AUTHREASON=Local report encoding failed before GitHub was contacted."
  exit /b 1
)
"%FINDSTR%" /v /c:"-----" /c:"CertUtil" "%B64FILE%" >"%B64CLEAN%" 2>nul
set "B64="
for /f "usebackq delims=" %%L in ("%B64CLEAN%") do set "B64=!B64!%%L"
if not defined B64 (
  set "HTTP=LOCAL"
  set "AUTHREASON=Local report encoding produced no upload data."
  exit /b 1
)

set "UPLOADPATH=reports/inbox/bootstrap-%COMMAND_VERSION%-%RANDOM%%RANDOM%.txt"
>"%JSONFILE%" echo {"message":"WinRE private reporting bootstrap","content":"!B64!"}
set "PUTURL=https://api.github.com/repos/%LOGREPO%/contents/!UPLOADPATH!"
if defined APIIP (
  for /f %%H in ('"%CURL%" --ssl-no-revoke --silent --show-error --connect-timeout 15 --max-time 120 --resolve "%APIHOST%:443:!APIIP!" -X PUT -H "Accept: application/vnd.github+json" -H "Authorization: Bearer !LOGTOKEN!" -H "X-GitHub-Api-Version: 2022-11-28" -H "Content-Type: application/json" --data-binary "@%JSONFILE%" -o "%RESPFILE%" -w "%%{http_code}" "%PUTURL%"') do set "HTTP=%%H"
) else (
  for /f %%H in ('"%CURL%" --ssl-no-revoke --silent --show-error --connect-timeout 15 --max-time 120 -X PUT -H "Accept: application/vnd.github+json" -H "Authorization: Bearer !LOGTOKEN!" -H "X-GitHub-Api-Version: 2022-11-28" -H "Content-Type: application/json" --data-binary "@%JSONFILE%" -o "%RESPFILE%" -w "%%{http_code}" "%PUTURL%"') do set "HTTP=%%H"
)
if "!HTTP!"=="201" exit /b 0
if "!HTTP!"=="200" exit /b 0
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
