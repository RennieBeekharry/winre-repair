@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR-MODULE: resolve 2026.08.14-1126-ET
if /i "%~1"=="resolve" goto :RESOLVE
exit /b 64

:RESOLVE
set "HOST=%~2"
set "RET=%~3"
set "CURL=C:\Windows\System32\curl.exe"
set "NSLOOKUP=C:\Windows\System32\nslookup.exe"
set "FINDSTR=C:\Windows\System32\findstr.exe"
set "WORK=C:\WinRERepair"
set "CAND="
set "CACHE="
if /i "%HOST%"=="api.github.com" set "CACHE=%WORK%\github-api-ip.txt"
if /i "%HOST%"=="github.com" set "CACHE=%WORK%\github-web-ip.txt"
if not exist "%CURL%" exit /b 91
if not exist "%NSLOOKUP%" exit /b 91
if not exist "%FINDSTR%" exit /b 91

rem 1. Reuse inherited launcher address when resolving api.github.com.
if /i "%HOST%"=="api.github.com" if defined APIIP (
  set "CAND=%APIIP%"
  call :VALIDATE
  if not errorlevel 1 goto :SUCCESS
)

rem 2. Reuse a previously validated local cache.
if defined CACHE if exist "%CACHE%" (
  set "CAND="
  set /p "CAND="<"%CACHE%"
  if defined CAND (
    call :VALIDATE
    if not errorlevel 1 goto :SUCCESS
  )
)

rem 3. Try multiple independent DNS resolvers. A candidate is accepted only
rem    after an HTTPS/TLS request succeeds with curl --resolve.
for %%D in (64.71.255.204 1.1.1.1 8.8.8.8 9.9.9.9) do (
  call :LOOKUP "%%D"
  if defined CAND (
    call :VALIDATE
    if not errorlevel 1 goto :SUCCESS
  )
)

endlocal & set "%RET%=" & exit /b 92

:LOOKUP
set "DNS=%~1"
set "CAND="
set "TOK="
for /f "delims=" %%L in ('"%NSLOOKUP%" %HOST% %DNS% 2^>nul ^| "%FINDSTR%" /R "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*"') do (
  set "TOK="
  for %%T in (%%L) do set "TOK=%%T"
  if defined TOK if /i not "!TOK!"=="%DNS%" set "CAND=!TOK!"
)
exit /b 0

:VALIDATE
if not defined CAND exit /b 1
"%CURL%" --ssl-no-revoke --fail --silent --show-error --connect-timeout 8 --max-time 20 --resolve "%HOST%:443:%CAND%" "https://%HOST%/" -o NUL >nul 2>&1
exit /b %errorlevel%

:SUCCESS
if defined CACHE >"%CACHE%" echo(%CAND%
endlocal & set "%RET%=%CAND%" & exit /b 0
