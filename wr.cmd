@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "LAUNCHER_VERSION=RMAI-LAUNCHER-2026.08.14-1348-ET"
set "PRODUCT=RescueMeAI"
set "DESCRIPTION=AI-ASSISTED WINDOWS RECOVERY"
set "LEGAL_BASE=https://github.com/RennieBeekharry/winre-repair"
set "LEGAL_FILE=LEGAL.md"
set "CURL=C:\Windows\System32\curl.exe"
set "WPEUTIL=X:\Windows\System32\wpeutil.exe"
set "PING=X:\Windows\System32\ping.exe"
set "NSLOOKUP=C:\Windows\System32\nslookup.exe"
set "FINDSTR=C:\Windows\System32\findstr.exe"
set "MODE=C:\Windows\System32\mode.com"
if not exist "%MODE%" set "MODE=mode"
set "DNS=64.71.255.204"
set "APIHOST=api.github.com"
set "URL=https://api.github.com/repos/RennieBeekharry/winre-repair/contents/next.cmd?ref=main"
set "OUT=X:\next.cmd"
set "TMP=X:\next.cmd.tmp"
set "WORK=C:\WinRERepair"
set "REPORT=%WORK%\LAST_RUN_REPORT.txt"
set "INTERNET_STATUS=CHECKING"
set "APIIP="
set "UI_WIDTH=96"
set "UI_TEXT_WIDTH=92"
set "UI_BORDER================================================================================================="
set "UI_RULE=------------------------------------------------------------------------------------------------"
set "UI_SPACES=                                                                                                    "

title RescueMeAI - Windows Recovery
if not exist "%WORK%" md "%WORK%" >nul 2>&1
call :UI_SETUP
call :UI_HEADER INFO "STARTING RESCUEMEAI" "READ ONLY"
call :UI_SECTION "STARTUP"
call :UI_WRAP "Checking the recovery environment and Internet connection."

if not exist "%CURL%" (
  set "FAIL_RC=91"
  set "FAIL_REASON=Required curl.exe was not found in the recovery environment."
  goto :LAUNCHER_FAIL
)
if not exist "%FINDSTR%" (
  set "FAIL_RC=91"
  set "FAIL_REASON=Required findstr.exe was not found in the recovery environment."
  goto :LAUNCHER_FAIL
)

if exist "%PING%" (
  "%PING%" -n 1 -w 1500 1.1.1.1 >nul 2>&1
  if errorlevel 1 if exist "%WPEUTIL%" "%WPEUTIL%" InitializeNetwork >nul 2>&1
)

if exist "%TMP%" del /f /q "%TMP%" >nul 2>&1
if exist "%OUT%" del /f /q "%OUT%" >nul 2>&1
if exist "%NSLOOKUP%" call :RESOLVE %APIHOST% APIIP
call :FETCHPUBLIC "%URL%" "%TMP%"
if errorlevel 1 (
  set "INTERNET_STATUS=NOT CONNECTED"
  set "FAIL_RC=90"
  set "FAIL_REASON=RescueMeAI could not download the current recovery workflow from GitHub."
  goto :LAUNCHER_FAIL
)

"%FINDSTR%" /b /l /c:"@echo off" "%TMP%" >nul 2>&1
if errorlevel 1 (
  del /f /q "%TMP%" >nul 2>&1
  set "INTERNET_STATUS=CONNECTED"
  set "FAIL_RC=96"
  set "FAIL_REASON=The downloaded RescueMeAI workflow failed basic content validation."
  goto :LAUNCHER_FAIL
)
move /y "%TMP%" "%OUT%" >nul 2>&1
if errorlevel 1 (
  set "INTERNET_STATUS=CONNECTED"
  set "FAIL_RC=97"
  set "FAIL_REASON=The validated RescueMeAI workflow could not be staged locally."
  goto :LAUNCHER_FAIL
)

set "INTERNET_STATUS=CONNECTED"
call :UI_HEADER INFO "LOADING CURRENT RECOVERY WORKFLOW" "READ ONLY"
call :UI_SECTION "[CONNECTED] CURRENT WORKFLOW READY"
call :UI_WRAP "The latest RescueMeAI recovery workflow was downloaded and validated."
call :UI_WRAP "Starting the recovery workflow now."

rem The child workflow owns all normal PASS / FAIL / WARNING result UI.
call "%OUT%"
set "RC=!errorlevel!"
if "!RC!"=="40" (
  color 07 >nul 2>&1
  title Command Prompt
)
exit /b !RC!

:LAUNCHER_FAIL
>"%REPORT%" echo product=%PRODUCT%
>>"%REPORT%" echo status=FAIL
>>"%REPORT%" echo return_code=!FAIL_RC!
>>"%REPORT%" echo launcher_version=%LAUNCHER_VERSION%
>>"%REPORT%" echo date=%date%
>>"%REPORT%" echo time=%time%
>>"%REPORT%" echo message=!FAIL_REASON!
call :UI_HEADER ERROR "LAUNCHER / UPDATE FAILURE" "NO RECOVERY ACTION"
call :UI_SECTION "[FAIL] RESCUEMEAI COULD NOT START"
call :UI_WRAP "!FAIL_REASON!"
call :UI_SECTION "WHAT YOU SHOULD DO"
call :UI_WRAP "Reply to ChatGPT with exactly: fail"
call :UI_SECTION "ADDITIONAL INFORMATION REQUIRED"
call :UI_WRAP "Screenshot this screen only if private reporting is not yet online."
call :UI_WRAP "Nothing destructive was attempted."
call :UI_LINE "%UI_BORDER%"
pause >nul
exit /b !FAIL_RC!

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

:UI_SETUP
"%MODE%" con: cols=100 lines=50 >nul 2>&1
exit /b 0

:UI_THEME
set "UI_THEME=%~1"
set "UI_COLOR=07"
if /i "!UI_THEME!"=="INFO" set "UI_COLOR=0B"
if /i "!UI_THEME!"=="PASS" set "UI_COLOR=0A"
if /i "!UI_THEME!"=="WARNING" set "UI_COLOR=0E"
if /i "!UI_THEME!"=="ERROR" set "UI_COLOR=0C"
color !UI_COLOR! >nul 2>&1
exit /b 0

:UI_HEADER
set "UI_THEME_REQUEST=%~1"
set "UI_STEP=%~2"
set "UI_SAFETY=%~3"
call :UI_THEME "!UI_THEME_REQUEST!"
cls
call :UI_LINE "%UI_BORDER%"
call :UI_CENTER "RESCUEMEAI"
call :UI_CENTER "%DESCRIPTION%"
call :UI_LINE "%UI_BORDER%"
call :UI_LINE "Version      : %LAUNCHER_VERSION%"
call :UI_LINE "Internet     : [%INTERNET_STATUS%]"
call :UI_LINE "Current Step : !UI_STEP!"
call :UI_LINE "Safety       : !UI_SAFETY!"
call :UI_LINE "Legal        : %LEGAL_BASE%"
call :UI_LINE "Legal file   : %LEGAL_FILE%"
call :UI_LINE "%UI_BORDER%"
exit /b 0

:UI_SECTION
echo.
call :UI_LINE "%~1"
call :UI_LINE "%UI_RULE%"
exit /b 0

:UI_WRAP
set "UI_WRAP_TEXT=%~1"
set "UI_WRAP_LINE="
for %%W in (!UI_WRAP_TEXT!) do (
  if not defined UI_WRAP_LINE (
    set "UI_WRAP_LINE=%%W"
  ) else (
    set "UI_WRAP_CAND=!UI_WRAP_LINE! %%W"
    call :STRLEN "!UI_WRAP_CAND!" UI_WRAP_LEN
    if !UI_WRAP_LEN! GTR %UI_TEXT_WIDTH% (
      call :UI_LINE "!UI_WRAP_LINE!"
      set "UI_WRAP_LINE=%%W"
    ) else (
      set "UI_WRAP_LINE=!UI_WRAP_CAND!"
    )
  )
)
if defined UI_WRAP_LINE call :UI_LINE "!UI_WRAP_LINE!"
exit /b 0

:UI_CENTER
set "UI_CENTER_TEXT=%~1"
call :STRLEN "!UI_CENTER_TEXT!" UI_CENTER_LEN
set /a UI_CENTER_PAD=(UI_WIDTH-UI_CENTER_LEN)/2
if !UI_CENTER_PAD! LSS 0 set "UI_CENTER_PAD=0"
set "UI_CENTER_LINE=!UI_SPACES:~0,%UI_CENTER_PAD%!!UI_CENTER_TEXT!"
call :UI_LINE "!UI_CENTER_LINE!"
exit /b 0

:UI_LINE
set "UI_TEXT=%~1"
call :STRLEN "!UI_TEXT!" UI_PRINT_LEN
if !UI_PRINT_LEN! GTR %UI_WIDTH% set "UI_TEXT=!UI_TEXT:~0,%UI_WIDTH%!"
echo(!UI_TEXT!
exit /b 0

:STRLEN
set "SL_TEXT=%~1"
set /a SL_LEN=0
:STRLEN_LOOP
if not "!SL_TEXT:~%SL_LEN%,1!"=="" (
  set /a SL_LEN+=1
  if !SL_LEN! LSS 512 goto :STRLEN_LOOP
)
set "%~2=%SL_LEN%"
exit /b 0
