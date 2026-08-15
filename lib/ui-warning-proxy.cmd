@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR-MODULE: ui-warning-proxy 2026.08.15-V1
rem RescueMeAI compatibility proxy: delegates normal rendering to ui-core.cmd and appends
rem session/channel diagnostics to persistent-agent screens. No credential values are displayed.

set "CORE=C:\WinRERepair\runtime\ui-core.cmd"
set "WORK=C:\WinRERepair"
set "SESSIONFILE=%WORK%\session-version.txt"
set "AUTHRESULT=%WORK%\GITHUB_RESULT.txt"
if not exist "%CORE%" exit /b 91

call "%CORE%" %*
set "UIRC=!errorlevel!"

if /i "%~1"=="screen" (
  set "SV=UNKNOWN"
  if exist "%SESSIONFILE%" set /p "SV="<"%SESSIONFILE%"
  echo.
  echo SESSION / RUNTIME
  echo ----------------------------------------------------------------------------------------------------
  echo Launcher/session : !SV!
  echo Agent runtime    : %~2

  if /i "%~4"=="WARNING / RETRYING" (
    set "GR_STATUS=UNKNOWN"
    set "GR_PHASE=UNKNOWN"
    set "GR_REASON=No structured authorization diagnostic is available yet."
    set "GR_RC=N/A"
    set "GR_HTTP=N/A"
    set "GR_CURL=N/A"
    set "GR_IDHTTP=N/A"
    set "GR_REPOHTTP=N/A"
    set "GR_REFRESHHTTP=N/A"
    set "GR_COMPONENT=UNKNOWN"
    set "GR_LAST=Not recorded"
    if exist "%AUTHRESULT%" (
      for /f "usebackq tokens=1,* delims==" %%A in ("%AUTHRESULT%") do (
        if /i "%%A"=="status" set "GR_STATUS=%%B"
        if /i "%%A"=="phase" set "GR_PHASE=%%B"
        if /i "%%A"=="reason" set "GR_REASON=%%B"
        if /i "%%A"=="return_code" set "GR_RC=%%B"
        if /i "%%A"=="http" set "GR_HTTP=%%B"
        if /i "%%A"=="curl_return_code" set "GR_CURL=%%B"
        if /i "%%A"=="identity_http" set "GR_IDHTTP=%%B"
        if /i "%%A"=="repository_http" set "GR_REPOHTTP=%%B"
        if /i "%%A"=="refresh_http" set "GR_REFRESHHTTP=%%B"
        if /i "%%A"=="component" set "GR_COMPONENT=%%B"
        if /i "%%A"=="last_success" set "GR_LAST=%%B"
      )
    )
    echo.
    echo PRIVATE CHANNEL - RETRY DETAIL
    echo ----------------------------------------------------------------------------------------------------
    echo State            : !GR_STATUS!
    echo Phase            : !GR_PHASE!
    echo Component        : !GR_COMPONENT!
    echo Reason           : !GR_REASON!
    echo Return code      : !GR_RC!
    echo HTTP             : !GR_HTTP!
    echo curl return code : !GR_CURL!
    echo Identity HTTP    : !GR_IDHTTP!
    echo Repository HTTP  : !GR_REPOHTTP!
    echo Refresh HTTP     : !GR_REFRESHHTTP!
    echo Last success     : !GR_LAST!
    echo.
    echo WHAT HAPPENS NEXT
    echo ----------------------------------------------------------------------------------------------------
    echo RescueMeAI will retry automatically. No recovery command is running while authorization is unavailable.
    echo You do not need to send pass, fail, or warning.
    echo If this state does not recover, the details above are safe to photograph and send to ChatGPT.
  )
)
exit /b !UIRC!
