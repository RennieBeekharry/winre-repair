@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=REPAIR_WRITE
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Load the immutable RescueMeAI Pairing-13 core and continue repository-scoped GitHub App device pairing.
rem WR_ACTION=LOAD_RESCUEMEAI_PAIRING_CORE
rem WR_TARGET=RescueMeAI recovery tooling only. No Windows repair target.
rem WR_CONSEQUENCE=Downloads one pinned RescueMeAI pairing module and executes it.
rem WR_ROLLBACK=Downloaded recovery tooling can be removed later. No Windows recovery state is modified.

set "COMMAND_VERSION=RMAI-2026.08.14-SECURE-PAIRING-13"
set "PRODUCT=RescueMeAI"
set "DESCRIPTION=AI-ASSISTED WINDOWS RECOVERY"
set "WORK=C:\WinRERepair"
set "RUNTIME=%WORK%\runtime"
set "CURL=C:\Windows\System32\curl.exe"
set "FINDSTR=C:\Windows\System32\findstr.exe"
set "MODE=C:\Windows\System32\mode.com"
if not exist "%MODE%" set "MODE=mode"
set "APIHOST=api.github.com"
set "DOHHOST=cloudflare-dns.com"
set "SOURCE_REPO=RennieBeekharry/winre-repair"
set "SOURCE_REF=7ad401e5e7425d90358f57660540bcca08a49919"
set "CORE=%RUNTIME%\pairing-core-v13.cmd"
set "CORE_TMP=%RUNTIME%\pairing-core-v13.cmd.tmp"
set "CORE_URL=https://api.github.com/repos/%SOURCE_REPO%/contents/lib/pairing-core-v13.cmd?ref=%SOURCE_REF%"
set "APIIP="
set "DOH_STATUS=NOT_RUN"
set "DOH_HTTP=NOT_RUN"
set "DOH_CURL_RC=NOT_RUN"
set "FAIL_RC=90"
set "FAIL_REASON=RescueMeAI could not load the secure Pairing-13 core."
set "UI_WIDTH=96"
set "UI_TEXT_WIDTH=92"
set "UI_BORDER================================================================================================="
set "UI_RULE=------------------------------------------------------------------------------------------------"
set "UI_SPACES=                                                                                                    "

title RescueMeAI - Windows Recovery
if not exist "%WORK%" md "%WORK%" >nul 2>&1
if not exist "%RUNTIME%" md "%RUNTIME%" >nul 2>&1
"%MODE%" con: cols=100 lines=50 >nul 2>&1

if not exist "%CURL%" (
  set "FAIL_RC=91"
  set "FAIL_REASON=Required curl.exe is missing from the recovery environment."
  goto :FAIL
)
if not exist "%FINDSTR%" (
  set "FAIL_RC=91"
  set "FAIL_REASON=Required findstr.exe is missing from the recovery environment."
  goto :FAIL
)

call :HEADER INFO "LOADING SECURE PAIRING CORE"
call :SECTION "PAIRING BOOTSTRAP"
call :WRAP "RescueMeAI is loading the immutable Pairing-13 authentication core. Terms version 2026-08-14 was already accepted on this recovery computer."

call :DOH_RESOLVE_A "%APIHOST%" APIIP
set "DOH_STATUS=!DOH_LAST_STATUS!"
set "DOH_HTTP=!DOH_LAST_HTTP!"
set "DOH_CURL_RC=!DOH_LAST_CURL_RC!"
if not defined APIIP (
  set "FAIL_RC=92"
  set "FAIL_REASON=DNS-over-HTTPS could not provide an api.github.com address for the pinned Pairing-13 core."
  goto :FAIL
)

call :TEST_API_IP "!APIIP!"
if errorlevel 1 (
  set "FAIL_RC=92"
  set "FAIL_REASON=DNS-over-HTTPS returned an api.github.com address, but HTTPS validation failed."
  goto :FAIL
)

if exist "%CORE_TMP%" del /f /q "%CORE_TMP%" >nul 2>&1
"%CURL%" --ssl-no-revoke --fail --silent --show-error --connect-timeout 15 --max-time 120 --resolve "%APIHOST%:443:%APIIP%" -H "Accept: application/vnd.github.raw+json" -H "Cache-Control: no-cache, no-store, max-age=0" "%CORE_URL%" -o "%CORE_TMP%" 2>"%WORK%\PAIRING_CORE_CURL_ERROR.txt"
set "FETCH_RC=!errorlevel!"
if not "!FETCH_RC!"=="0" (
  set "FAIL_RC=90"
  set "FAIL_REASON=The pinned RescueMeAI Pairing-13 core could not be downloaded."
  goto :FAIL
)
if not exist "%CORE_TMP%" (
  set "FAIL_RC=90"
  set "FAIL_REASON=curl returned success but the Pairing-13 core file was not created."
  goto :FAIL
)
for %%Z in ("%CORE_TMP%") do if %%~zZ LSS 256 (
  set "FAIL_RC=96"
  set "FAIL_REASON=The downloaded Pairing-13 core was unexpectedly small."
  goto :FAIL
)
"%FINDSTR%" /i /c:"WR-MODULE: pairing-core 2026.08.14-PAIRING-13" "%CORE_TMP%" >nul 2>&1
if errorlevel 1 (
  set "FAIL_RC=96"
  set "FAIL_REASON=The downloaded Pairing-13 core failed marker validation."
  goto :FAIL
)
move /y "%CORE_TMP%" "%CORE%" >nul 2>&1
if errorlevel 1 (
  set "FAIL_RC=97"
  set "FAIL_REASON=The validated Pairing-13 core could not be staged locally."
  goto :FAIL
)
>"%WORK%\github-api-ip.txt" echo(!APIIP!

call "%CORE%"
set "CORE_RC=!errorlevel!"
exit /b !CORE_RC!

:FAIL
call :HEADER ERROR "PAIRING BOOTSTRAP FAILED"
call :SECTION "[FAIL] RESCUEMEAI COULD NOT LOAD PAIRING-13"
call :LINE "Return code : !FAIL_RC!"
call :LINE "API DoH     : !DOH_STATUS!"
call :LINE "DoH HTTP    : !DOH_HTTP!"
call :LINE "DoH curl RC : !DOH_CURL_RC!"
call :LINE "API IP      : !APIIP!"
call :SECTION "REASON"
call :WRAP "!FAIL_REASON!"
call :SECTION "SAFETY"
call :WRAP "No Windows repair, disk, boot, registry, partition, or filesystem action was performed."
call :SECTION "NEXT"
call :WRAP "RescueMeAI is returning automatically to the Windows Recovery command prompt."
call :LINE "%UI_BORDER%"
echo.
echo Returning to command prompt...
color 07 >nul 2>&1
title Command Prompt
exit /b !FAIL_RC!

:DOH_RESOLVE_A
set "DOH_QUERY_HOST=%~1"
set "DOH_RETURN_VAR=%~2"
set "%DOH_RETURN_VAR%="
set "DOH_LAST_STATUS=FAIL"
set "DOH_LAST_HTTP=NOT_RUN"
set "DOH_LAST_CURL_RC=NOT_RUN"
for %%I in (1.1.1.1 1.0.0.1) do (
  if /i not "!DOH_LAST_STATUS!"=="PASS" call :TRY_DOH_A "%%I"
)
if /i "!DOH_LAST_STATUS!"=="PASS" exit /b 0
exit /b 1

:TRY_DOH_A
set "DOH_RESOLVER_IP=%~1"
set "DOH_JSON=%WORK%\bootstrap-doh.json"
set "DOH_HTTP_FILE=%WORK%\bootstrap-doh-http.txt"
if exist "%DOH_JSON%" del /f /q "%DOH_JSON%" >nul 2>&1
if exist "%DOH_HTTP_FILE%" del /f /q "%DOH_HTTP_FILE%" >nul 2>&1
"%CURL%" --ssl-no-revoke --silent --show-error --connect-timeout 10 --max-time 45 --resolve "%DOHHOST%:443:%DOH_RESOLVER_IP%" -H "Accept: application/dns-json" "https://cloudflare-dns.com/dns-query?name=%DOH_QUERY_HOST%&type=A" -o "%DOH_JSON%" -w "%%{http_code}" >"%DOH_HTTP_FILE%" 2>"%WORK%\bootstrap-doh-error.txt"
set "DOH_LAST_CURL_RC=!errorlevel!"
set "DOH_LAST_HTTP="
if exist "%DOH_HTTP_FILE%" set /p "DOH_LAST_HTTP="<"%DOH_HTTP_FILE%"
if not "!DOH_LAST_CURL_RC!"=="0" exit /b 1
if not "!DOH_LAST_HTTP!"=="200" exit /b 1
set "DOH_JOIN="
for /f "usebackq delims=" %%L in ("%DOH_JSON%") do set "DOH_JOIN=!DOH_JOIN!%%L"
if not defined DOH_JOIN exit /b 1
set "DOH_TAIL=!DOH_JOIN:*data=!"
if "!DOH_TAIL!"=="!DOH_JOIN!" exit /b 1
set "DOH_RAW="
for /f "tokens=2 delims=:" %%A in ("!DOH_TAIL!") do set "DOH_RAW=%%A"
if not defined DOH_RAW exit /b 1
set "DOH_IP="
for /f "tokens=1 delims=,}]" %%A in ("!DOH_RAW!") do set "DOH_IP=%%A"
set "DOH_IP=!DOH_IP:"=!"
set "DOH_IP=!DOH_IP: =!"
if not defined DOH_IP exit /b 1
echo(!DOH_IP!|"%FINDSTR%" /r /x "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*" >nul 2>&1
if errorlevel 1 exit /b 1
set "%DOH_RETURN_VAR%=!DOH_IP!"
set "DOH_LAST_STATUS=PASS"
exit /b 0

:TEST_API_IP
set "TEST_IP=%~1"
"%CURL%" --ssl-no-revoke --silent --show-error --connect-timeout 10 --max-time 30 --resolve "%APIHOST%:443:%TEST_IP%" -I "https://api.github.com/" -o NUL >nul 2>&1
exit /b !errorlevel!

:HEADER
set "THEME=%~1"
set "STEP=%~2"
set "C=07"
if /i "!THEME!"=="INFO" set "C=0B"
if /i "!THEME!"=="PASS" set "C=0A"
if /i "!THEME!"=="WARNING" set "C=0E"
if /i "!THEME!"=="ERROR" set "C=0C"
color !C! >nul 2>&1
cls
call :LINE "%UI_BORDER%"
call :CENTER "RESCUEMEAI"
call :CENTER "%DESCRIPTION%"
call :LINE "%UI_BORDER%"
call :LINE "Version      : %COMMAND_VERSION%"
call :LINE "Internet     : [CONNECTED]"
call :LINE "Current Step : !STEP!"
call :LINE "Safety       : NO WINDOWS RECOVERY ACTION"
call :LINE "Legal        : https://github.com/RennieBeekharry/winre-repair"
call :LINE "Legal file   : LEGAL.md"
call :LINE "%UI_BORDER%"
exit /b 0

:SECTION
echo.
call :LINE "%~1"
call :LINE "%UI_RULE%"
exit /b 0

:WRAP
set "T=%~1"
set "L="
for %%W in (!T!) do (
  if not defined L (
    set "L=%%W"
  ) else (
    set "CAND=!L! %%W"
    call :STRLEN "!CAND!" N
    if !N! GTR %UI_TEXT_WIDTH% (
      call :LINE "!L!"
      set "L=%%W"
    ) else (
      set "L=!CAND!"
    )
  )
)
if defined L call :LINE "!L!"
exit /b 0

:CENTER
set "T=%~1"
call :STRLEN "!T!" N
set /a P=(UI_WIDTH-N)/2
if !P! LSS 0 set "P=0"
set "OUT=!UI_SPACES:~0,%P%!!T!"
call :LINE "!OUT!"
exit /b 0

:LINE
set "T=%~1"
call :STRLEN "!T!" N
if !N! GTR %UI_WIDTH% set "T=!T:~0,%UI_WIDTH%!"
echo(!T!
exit /b 0

:STRLEN
set "S=%~1"
set /a N=0
:STRLEN_LOOP
if not "!S:~%N%,1!"=="" (
  set /a N+=1
  if !N! LSS 512 goto :STRLEN_LOOP
)
set "%~2=%N%"
exit /b 0
