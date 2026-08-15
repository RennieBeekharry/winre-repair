@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=REPAIR_WRITE
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Resume RescueMeAI without any secondary bootstrap download; reuse staged auth/runtime and repair only the local JSON helper when needed.
rem WR_ACTION=START_RESCUEMEAI_LOCAL_ONLY_AUTH_V18
rem WR_TARGET=RescueMeAI runtime/authentication only.
rem WR_CONSEQUENCE=Repairs only the local authorization helper and reconnects the private command channel. It does not modify Windows recovery state.
rem WR_ROLLBACK=Runtime-only startup update; no Windows recovery rollback is required.

set "COMMAND_VERSION=RMAI-2026.08.15-AGENT-START-18"
set "WORK=C:\WinRERepair"
set "RUNTIME=%WORK%\runtime"
set "CONFIG=%WORK%\agent.cfg"
set "AGENT=C:\wr-agent-v2.cmd"
set "FINDSTR=C:\Windows\System32\findstr.exe"
set "CERTUTIL=C:\Windows\System32\certutil.exe"
set "PARSER=%RUNTIME%\json-value-v1.js"
set "PARSER_B64=%WORK%\json-value-v1.b64"
set "FAIL_REASON=RescueMeAI could not resume the secure recovery session."
set "LOG_REPO=RennieBeekharry/winre-repair-logs"
set "LOG_REPO_ID=1333818657"
set "APP_ID=4595411"
set "CLIENT_ID=Iv23lif9UoXW4QvUh8tJ"
set "SOURCE_REPO=RennieBeekharry/winre-repair"
set "SOURCE_REF=41b232f3abc3a123fe61627040bf936aa658b516"

title RescueMeAI - Windows Recovery
if not exist "%WORK%" md "%WORK%" >nul 2>&1
if not exist "%RUNTIME%" md "%RUNTIME%" >nul 2>&1
if exist "%WORK%\GITHUB_RESULT.txt" del /f /q "%WORK%\GITHUB_RESULT.txt" >nul 2>&1

if not exist "%FINDSTR%" (
  set "FAIL_REASON=Required findstr.exe is missing."
  goto :FATAL
)
if not exist "%CERTUTIL%" (
  set "FAIL_REASON=Required certutil.exe is missing."
  goto :FATAL
)
if not exist "%AGENT%" (
  set "FAIL_REASON=The persistent RescueMeAI agent is missing."
  goto :FATAL
)

call :SCREEN "LOCAL RUNTIME RECOVERY" "Reusing the staged RescueMeAI runtime. No secondary Internet download is required."

for %%F in (resolve.cmd network.cmd ui.cmd reporting.cmd safety.cmd agent-core.js github-auth.cmd) do (
  if not exist "%RUNTIME%\%%F" (
    set "FAIL_REASON=Required staged runtime module %%F is missing."
    goto :FATAL
  )
)

rem If v4 is already present, it has no JSON dependency and can be used directly.
"%FINDSTR%" /i /c:"WR-MODULE: github-auth-v4 2026.08.15-FORM-OAUTH-TLS" "%RUNTIME%\github-auth.cmd" >nul 2>&1
if not errorlevel 1 goto :AUTH_READY

rem Otherwise the proven v3 auth module is already staged. Repair only its local
rem parser from data embedded in this workflow; no additional host/DNS is needed.
"%FINDSTR%" /i /c:"WR-MODULE: github-auth-v3 2026.08.15-CSCRIPT-JSON-TLS" "%RUNTIME%\github-auth.cmd" >nul 2>&1
if errorlevel 1 (
  set "FAIL_REASON=The staged authorization module is neither supported v3 nor v4."
  goto :FATAL
)

if exist "%PARSER_B64%" del /f /q "%PARSER_B64%" >nul 2>&1
>"%PARSER_B64%" echo Ly8gUmVzY3VlTWVBSSBsb2NhbCBKU09OIGhlbHBlciBmb3IgV2luUkUvY3NjcmlwdC4KLy8gVXNh
>>"%PARSER_B64%" echo Z2U6IGNzY3JpcHQgLy9ub2xvZ28ganNvbi12YWx1ZS12MS5qcyA8anNvbi1maWxlPiA8cHJvcGVy
>>"%PARSER_B64%" echo dHk+Ci8vIEludGVudGlvbmFsbHkgYXZvaWRzIEpTT04ucGFyc2UgZm9yIGNvbXBhdGliaWxpdHkg
>>"%PARSER_B64%" echo d2l0aCBvbGRlciBXaW5SRSBKU2NyaXB0IGVuZ2luZXMuCihmdW5jdGlvbiAoKSB7CiAgICBpZiAo
>>"%PARSER_B64%" echo V1NjcmlwdC5Bcmd1bWVudHMubGVuZ3RoIDwgMikgV1NjcmlwdC5RdWl0KDY0KTsKICAgIHZhciBw
>>"%PARSER_B64%" echo YXRoID0gV1NjcmlwdC5Bcmd1bWVudHMuSXRlbSgwKTsKICAgIHZhciBrZXkgPSBXU2NyaXB0LkFy
>>"%PARSER_B64%" echo Z3VtZW50cy5JdGVtKDEpOwoKICAgIGZ1bmN0aW9uIGVzY2FwZVJlKHMpIHsKICAgICAgICByZXR1
>>"%PARSER_B64%" echo cm4gcy5yZXBsYWNlKC8oW1xcLl4kKis/KClcW1xde318XSkvZywgIlxcJDEiKTsKICAgIH0KCiAg
>>"%PARSER_B64%" echo ICBmdW5jdGlvbiB1bmVzY2FwZUpzb25TdHJpbmcocykgewogICAgICAgIHJldHVybiBzCiAgICAg
>>"%PARSER_B64%" echo ICAgICAgIC5yZXBsYWNlKC9cXCIvZywgJyInKQogICAgICAgICAgICAucmVwbGFjZSgvXFxcXC9n
>>"%PARSER_B64%" echo LCAiXFwiKQogICAgICAgICAgICAucmVwbGFjZSgvXFxcLy9nLCAiLyIpCiAgICAgICAgICAgIC5y
>>"%PARSER_B64%" echo ZXBsYWNlKC9cXGIvZywgIlxiIikKICAgICAgICAgICAgLnJlcGxhY2UoL1xcZi9nLCAiXGYiKQog
>>"%PARSER_B64%" echo ICAgICAgICAgICAucmVwbGFjZSgvXFxuL2csICJcbiIpCiAgICAgICAgICAgIC5yZXBsYWNlKC9c
>>"%PARSER_B64%" echo XHIvZywgIlxyIikKICAgICAgICAgICAgLnJlcGxhY2UoL1xcdC9nLCAiXHQiKQogICAgICAgICAg
>>"%PARSER_B64%" echo ICAucmVwbGFjZSgvXFx1KFswLTlhLWZBLUZdezR9KS9nLCBmdW5jdGlvbiAoXywgaCkgewogICAg
>>"%PARSER_B64%" echo ICAgICAgICAgICAgcmV0dXJuIFN0cmluZy5mcm9tQ2hhckNvZGUocGFyc2VJbnQoaCwgMTYpKTsK
>>"%PARSER_B64%" echo ICAgICAgICAgICAgfSk7CiAgICB9CgogICAgdHJ5IHsKICAgICAgICB2YXIgZnNvID0gbmV3IEFj
>>"%PARSER_B64%" echo dGl2ZVhPYmplY3QoIlNjcmlwdGluZy5GaWxlU3lzdGVtT2JqZWN0Iik7CiAgICAgICAgaWYgKCFm
>>"%PARSER_B64%" echo c28uRmlsZUV4aXN0cyhwYXRoKSkgV1NjcmlwdC5RdWl0KDIpOwogICAgICAgIHZhciB0cyA9IGZz
>>"%PARSER_B64%" echo by5PcGVuVGV4dEZpbGUocGF0aCwgMSwgZmFsc2UsIC0yKTsKICAgICAgICB2YXIgdGV4dCA9IHRz
>>"%PARSER_B64%" echo LlJlYWRBbGwoKTsKICAgICAgICB0cy5DbG9zZSgpOwoKICAgICAgICB2YXIgcmUgPSBuZXcgUmVn
>>"%PARSER_B64%" echo RXhwKCciJyArIGVzY2FwZVJlKGtleSkgKyAnIlxccyo6XFxzKig/OiIoKD86XFxcXC58W14iXFxc
>>"%PARSER_B64%" echo XF0pKikifCgtP1swLTldKyg/OlxcLlswLTldKyk/KXwodHJ1ZXxmYWxzZXxudWxsKSknLCAnaScp
>>"%PARSER_B64%" echo OwogICAgICAgIHZhciBtID0gcmUuZXhlYyh0ZXh0KTsKICAgICAgICBpZiAoIW0pIFdTY3JpcHQu
>>"%PARSER_B64%" echo UXVpdCgzKTsKCiAgICAgICAgdmFyIHZhbHVlOwogICAgICAgIGlmICh0eXBlb2YgbVsxXSAhPT0g
>>"%PARSER_B64%" echo InVuZGVmaW5lZCIgJiYgbVsxXSAhPT0gdW5kZWZpbmVkKSB7CiAgICAgICAgICAgIHZhbHVlID0g
>>"%PARSER_B64%" echo dW5lc2NhcGVKc29uU3RyaW5nKG1bMV0pOwogICAgICAgIH0gZWxzZSBpZiAodHlwZW9mIG1bMl0g
>>"%PARSER_B64%" echo IT09ICJ1bmRlZmluZWQiICYmIG1bMl0gIT09IHVuZGVmaW5lZCkgewogICAgICAgICAgICB2YWx1
>>"%PARSER_B64%" echo ZSA9IG1bMl07CiAgICAgICAgfSBlbHNlIHsKICAgICAgICAgICAgdmFsdWUgPSBtWzNdOwogICAg
>>"%PARSER_B64%" echo ICAgICAgICBpZiAoU3RyaW5nKHZhbHVlKS50b0xvd2VyQ2FzZSgpID09PSAibnVsbCIpIFdTY3Jp
>>"%PARSER_B64%" echo cHQuUXVpdCgzKTsKICAgICAgICB9CiAgICAgICAgV1NjcmlwdC5FY2hvKFN0cmluZyh2YWx1ZSkp
>>"%PARSER_B64%" echo OwogICAgICAgIFdTY3JpcHQuUXVpdCgwKTsKICAgIH0gY2F0Y2ggKGUpIHsKICAgICAgICBXU2Ny
>>"%PARSER_B64%" echo aXB0LlF1aXQoNCk7CiAgICB9Cn0pKCk7Cg==
"%CERTUTIL%" -f -decode "%PARSER_B64%" "%PARSER%" >nul 2>&1
if errorlevel 1 (
  set "FAIL_REASON=Could not restore the local WinRE authorization parser."
  goto :FATAL
)
del /f /q "%PARSER_B64%" >nul 2>&1

"%FINDSTR%" /i /c:"avoids JSON.parse" "%PARSER%" >nul 2>&1
if errorlevel 1 (
  set "FAIL_REASON=The restored local authorization parser failed validation."
  goto :FATAL
)

:AUTH_READY
> "%CONFIG%" echo PRODUCT=RescueMeAI
>>"%CONFIG%" echo LOG_REPO=%LOG_REPO%
>>"%CONFIG%" echo CONTROL_REPO=%LOG_REPO%
>>"%CONFIG%" echo CONTROL_PATH=control/current-command.json
>>"%CONFIG%" echo CONTROL_REF=main
>>"%CONFIG%" echo GITHUB_APP_ID=%APP_ID%
>>"%CONFIG%" echo GITHUB_APP_CLIENT_ID=%CLIENT_ID%
>>"%CONFIG%" echo GITHUB_REPOSITORY_ID=%LOG_REPO_ID%
>>"%CONFIG%" echo SOURCE_REPO=%SOURCE_REPO%
>>"%CONFIG%" echo SOURCE_REF=%SOURCE_REF%

>"%RUNTIME%\runtime-sync.cmd" echo @echo off
>>"%RUNTIME%\runtime-sync.cmd" echo setlocal EnableExtensions
>>"%RUNTIME%\runtime-sync.cmd" echo rem WR-MODULE: runtime-local-ready 2026.08.15-START-18
>>"%RUNTIME%\runtime-sync.cmd" echo set "RUNTIME=C:\WinRERepair\runtime"
>>"%RUNTIME%\runtime-sync.cmd" echo for %%%%F in ^(ui.cmd network.cmd resolve.cmd reporting.cmd github-auth.cmd safety.cmd agent-core.js^) do if not exist "%%RUNTIME%%\%%%%F" exit /b 91
>>"%RUNTIME%\runtime-sync.cmd" echo exit /b 0

call :SCREEN "SECURE AUTHORIZATION" "Validating or renewing the GitHub authorization using the local runtime."
call "%RUNTIME%\github-auth.cmd" authorize
if errorlevel 1 (
  set "FAIL_REASON=Secure GitHub authorization could not be established."
  goto :FATAL
)

call :SCREEN "RECOVERY AGENT ONLINE" "Secure command transport is ready. Starting the persistent recovery agent automatically."
call "%AGENT%"
set "ARC=!errorlevel!"
if "!ARC!"=="0" exit /b 0
set "FAIL_REASON=The persistent RescueMeAI agent stopped unexpectedly with return code !ARC!."
goto :FATAL

:SCREEN
cls
color 0B >nul 2>&1
echo ====================================================================================================
echo                                           RESCUEMEAI
echo                                    AI-ASSISTED WINDOWS RECOVERY
echo ====================================================================================================
echo Version         : %COMMAND_VERSION%
echo Transport       : HTTPS / TLS
echo Status          : %~1
echo Windows changes : NONE
echo ====================================================================================================
echo.
echo %~2
echo.
echo PLEASE WAIT - no action is required unless RescueMeAI displays LOCAL ACTION REQUIRED.
exit /b 0

:FATAL
cls
color 0C >nul 2>&1
echo ====================================================================================================
echo                                           RESCUEMEAI
echo                                      APPLICATION FAILURE
echo ====================================================================================================
echo Version         : %COMMAND_VERSION%
echo Transport       : HTTPS / TLS
echo Windows changes : STOPPED
echo ====================================================================================================
echo.
echo %FAIL_REASON%
echo.
if exist "%WORK%\GITHUB_RESULT.txt" (
  echo LOCAL GITHUB DETAIL
  echo ----------------------------------------------------------------------------------------------------
  type "%WORK%\GITHUB_RESULT.txt"
  echo.
)
echo No Windows repair action was executed by this startup failure.
echo A screenshot is required only because the private channel is unavailable.
echo.
pause
exit /b 90
