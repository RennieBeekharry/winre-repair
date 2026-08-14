@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR-MODULE: resolve 2026.08.14-1552-ET
if /i "%~1"=="resolve" goto :RESOLVE
exit /b 64

:RESOLVE
set "HOST=%~2"
set "RET=%~3"
set "CURL=C:\Windows\System32\curl.exe"
set "NSLOOKUP=C:\Windows\System32\nslookup.exe"
set "FINDSTR=C:\Windows\System32\findstr.exe"
set "WORK=C:\WinRERepair"
set "DOHHOST=cloudflare-dns.com"
set "CAND="
set "CACHE="
if /i "%HOST%"=="api.github.com" set "CACHE=%WORK%\github-api-ip.txt"
if /i "%HOST%"=="github.com" set "CACHE=%WORK%\github-web-ip.txt"
if not exist "%CURL%" exit /b 91
if not exist "%FINDSTR%" exit /b 91

if /i "%HOST%"=="api.github.com" if defined APIIP (
  set "CAND=%APIIP%"
  call :VALIDATE
  if not errorlevel 1 goto :SUCCESS
)

if defined CACHE if exist "%CACHE%" (
  set "CAND="
  set /p "CAND="<"%CACHE%"
  if defined CAND (
    call :VALIDATE
    if not errorlevel 1 goto :SUCCESS
  )
)

rem Proven WinRE fallback: resolve through DNS-over-HTTPS without depending on local DNS.
for %%I in (1.1.1.1 1.0.0.1) do (
  call :DOH "%%I"
  if defined CAND (
    call :VALIDATE
    if not errorlevel 1 goto :SUCCESS
  )
)

if exist "%NSLOOKUP%" (
  for %%D in (64.71.255.204 1.1.1.1 8.8.8.8 9.9.9.9) do (
    call :LOOKUP "%%D"
    if defined CAND (
      call :VALIDATE
      if not errorlevel 1 goto :SUCCESS
    )
  )
)

endlocal & set "%RET%=" & exit /b 92

:DOH
set "DOHIP=%~1"
set "DOHJSON=%WORK%\resolve-doh.json"
set "DOHHTTP=%WORK%\resolve-doh-http.txt"
set "CAND="
if exist "%DOHJSON%" del /f /q "%DOHJSON%" >nul 2>&1
if exist "%DOHHTTP%" del /f /q "%DOHHTTP%" >nul 2>&1
"%CURL%" --ssl-no-revoke --silent --show-error --connect-timeout 10 --max-time 45 --resolve "%DOHHOST%:443:%DOHIP%" -H "Accept: application/dns-json" "https://%DOHHOST%/dns-query?name=%HOST%&type=A" -o "%DOHJSON%" -w "%%{http_code}" >"%DOHHTTP%" 2>nul
if errorlevel 1 exit /b 0
set "HC="
if exist "%DOHHTTP%" set /p "HC="<"%DOHHTTP%"
if not "%HC%"=="200" exit /b 0
set "JOIN="
for /f "usebackq delims=" %%L in ("%DOHJSON%") do set "JOIN=!JOIN!%%L"
if not defined JOIN exit /b 0
set "TAIL=!JOIN:*data=!"
if "!TAIL!"=="!JOIN!" exit /b 0
set "RAW="
for /f "tokens=2 delims=:" %%A in ("!TAIL!") do set "RAW=%%A"
if not defined RAW exit /b 0
for /f "tokens=1 delims=,}]" %%A in ("!RAW!") do set "CAND=%%A"
set "CAND=!CAND:"=!"
set "CAND=!CAND: =!"
echo(!CAND!|"%FINDSTR%" /r /x "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*" >nul 2>&1
if errorlevel 1 set "CAND="
exit /b 0

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
rem Any HTTP response proves DNS/TLS reachability; do not reject a host merely because its root URL returns 4xx.
"%CURL%" --ssl-no-revoke --silent --show-error --connect-timeout 8 --max-time 20 --resolve "%HOST%:443:%CAND%" "https://%HOST%/" -o NUL >nul 2>&1
exit /b %errorlevel%

:SUCCESS
if defined CACHE >"%CACHE%" echo(%CAND%
endlocal & set "%RET%=%CAND%" & exit /b 0
