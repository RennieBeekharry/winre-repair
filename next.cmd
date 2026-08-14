@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "COMMAND_VERSION=WR-2026.08.14-0220-ET"
set "BUILD_TIME=2026-08-14 02:20 ET"
set "WORK=C:\WinRERepair"
set "DNS=64.71.255.204"
set "CURL=C:\Windows\System32\curl.exe"
set "NSLOOKUP=C:\Windows\System32\nslookup.exe"
set "FINDSTR=C:\Windows\System32\findstr.exe"
set "CERTUTIL=X:\Windows\System32\certutil.exe"
if not exist "%CERTUTIL%" set "CERTUTIL=C:\Windows\System32\certutil.exe"
set "TAR=X:\Windows\System32\tar.exe"
if not exist "%TAR%" set "TAR=C:\Windows\System32\tar.exe"
set "HOSTS=X:\Windows\System32\drivers\etc\hosts"
set "GHZIP=%WORK%\gh_2.97.0_windows_amd64.zip"
set "GHROOT=%WORK%\github-cli"
set "GHEXE=%GHROOT%\gh.exe"
set "GHSTAGE=%WORK%\gh-stage"
set "GHURL=https://github.com/cli/cli/releases/download/v2.97.0/gh_2.97.0_windows_amd64.zip"
set "GHSHA=35d7fe05c4dd1411ffda1e73dfc7c6f44b75c936ca51fa6595c657fdc0350cec"
set "LAUNCHER=%WORK%\wr-device-login.cmd"
set "LAUNCHER_API=https://api.github.com/repos/RennieBeekharry/winre-repair/contents/wr.cmd?ref=main&cb=%RANDOM%%RANDOM%"

cls
echo ================================================================
echo WINRE-REPAIR - AUTOMATIC GITHUB NETWORK BOOTSTRAP
echo Version: %COMMAND_VERSION%
echo Built:   %BUILD_TIME%
echo Fetched: %date% %time%
echo ================================================================
echo.
echo No manual DNS commands are required.
echo This bootstrap repairs GitHub name resolution inside WinRE only.
echo.

if not exist "%WORK%" md "%WORK%" >nul 2>&1

call :PINHOST github.com
call :PINHOST api.github.com
call :PINHOST release-assets.githubusercontent.com
call :PINHOST objects.githubusercontent.com
call :PINHOST raw.githubusercontent.com

if not exist "%GHEXE%" (
  echo Preparing verified GitHub CLI...
  call :DOWNLOAD_GH
  if errorlevel 1 goto :FAIL_GH
  "%CERTUTIL%" -hashfile "%GHZIP%" SHA256 | "%FINDSTR%" /i /c:"%GHSHA%" >nul 2>&1
  if errorlevel 1 (
    echo GitHub CLI SHA-256 validation FAILED.
    del /f /q "%GHZIP%" >nul 2>&1
    goto :FAIL_GH
  )
  echo GitHub CLI SHA-256: verified
  if exist "%GHSTAGE%" rmdir /s /q "%GHSTAGE%" >nul 2>&1
  md "%GHSTAGE%" >nul 2>&1
  "%TAR%" -xf "%GHZIP%" -C "%GHSTAGE%" >nul 2>&1
  if errorlevel 1 goto :FAIL_GH
  set "FOUNDGH="
  for /r "%GHSTAGE%" %%F in (gh.exe) do if not defined FOUNDGH set "FOUNDGH=%%F"
  if not defined FOUNDGH goto :FAIL_GH
  if not exist "%GHROOT%" md "%GHROOT%" >nul 2>&1
  copy /y "!FOUNDGH!" "%GHEXE%" >nul 2>&1
  rmdir /s /q "%GHSTAGE%" >nul 2>&1
  del /f /q "%GHZIP%" >nul 2>&1
)

if not exist "%GHEXE%" goto :FAIL_GH
"%GHEXE%" --version
if errorlevel 1 goto :FAIL_GH

if exist "%LAUNCHER%" del /f /q "%LAUNCHER%" >nul 2>&1
set "APIIP="
call :RESOLVE api.github.com APIIP
if defined APIIP (
  "%CURL%" --ssl-no-revoke --fail --location --silent --show-error --connect-timeout 10 --max-time 120 --resolve "api.github.com:443:!APIIP!" -H "Accept: application/vnd.github.raw+json" -H "X-GitHub-Api-Version: 2026-03-10" -H "Cache-Control: no-cache, no-store, max-age=0" "%LAUNCHER_API%" -o "%LAUNCHER%"
)
if not exist "%LAUNCHER%" (
  echo Could not fetch the device-login launcher.
  exit /b 11
)

"%FINDSTR%" /l /c:"LAUNCHER_VERSION=WR-LAUNCHER-2026.08.14-0201-ET" "%LAUNCHER%" >nul 2>&1
if errorlevel 1 (
  echo Downloaded launcher failed validation.
  exit /b 12
)

echo.
echo GitHub network bootstrap complete.
echo The launcher will now show a short device-login code.
echo.

call "%LAUNCHER%" /setup-logs ^
  "%WORK%\post-driver-0x7b-diagnostic.log" ^
  "%WORK%\setupapi-storage.txt" ^
  "%WORK%\driver-inventory.txt" ^
  "%WORK%\package-state.txt"
set "RC=!errorlevel!"
if not "!RC!"=="0" exit /b !RC!

echo.
echo ================================================================
echo PRIVATE LOG CHANNEL READY
echo Tell ChatGPT only: DONE
echo ================================================================
exit /b 0

:DOWNLOAD_GH
if exist "%GHZIP%" del /f /q "%GHZIP%" >nul 2>&1
set "WEBIP="
call :RESOLVE github.com WEBIP
if not defined WEBIP exit /b 1
set "HDR=%WORK%\gh-release-headers.txt"
if exist "%HDR%" del /f /q "%HDR%" >nul 2>&1
"%CURL%" --ssl-no-revoke --fail --silent --show-error --connect-timeout 10 --max-time 60 --resolve "github.com:443:!WEBIP!" -D "%HDR%" -o NUL "%GHURL%" >nul 2>&1
if errorlevel 1 exit /b 1
set "REDIRECT="
for /f "tokens=1,*" %%A in ('"%FINDSTR%" /b /i /c:"location:" "%HDR%" 2^>nul') do if not defined REDIRECT set "REDIRECT=%%B"
if not defined REDIRECT exit /b 1
set "ASSETHOST="
for /f "tokens=2 delims=/" %%H in ("!REDIRECT!") do set "ASSETHOST=%%H"
if not defined ASSETHOST exit /b 1
set "ASSETIP="
call :RESOLVE !ASSETHOST! ASSETIP
if not defined ASSETIP exit /b 1
"%CURL%" --ssl-no-revoke --fail --location --silent --show-error --connect-timeout 15 --max-time 600 --resolve "!ASSETHOST!:443:!ASSETIP!" "!REDIRECT!" -o "%GHZIP%"
if errorlevel 1 exit /b 1
for %%Z in ("%GHZIP%") do if %%~zZ LSS 10000000 exit /b 1
exit /b 0

:PINHOST
set "PINHOSTNAME=%~1"
set "PINIP="
call :RESOLVE %PINHOSTNAME% PINIP
if not defined PINIP exit /b 0
if exist "%HOSTS%" "%FINDSTR%" /v /i /c:" %PINHOSTNAME% # WR-GH" "%HOSTS%" >"%WORK%\hosts.tmp" 2>nul
if not exist "%WORK%\hosts.tmp" >"%WORK%\hosts.tmp" type nul
>>"%WORK%\hosts.tmp" echo !PINIP! %PINHOSTNAME% # WR-GH
copy /y "%WORK%\hosts.tmp" "%HOSTS%" >nul 2>&1
del /f /q "%WORK%\hosts.tmp" >nul 2>&1
exit /b 0

:RESOLVE
set "%~2="
set "CAND="
for /f "delims=" %%L in ('"%NSLOOKUP%" %~1 %DNS% 2^>nul ^| "%FINDSTR%" /R "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*"') do (
  for %%T in (%%L) do set "CAND=%%T"
  if not "!CAND!"=="%DNS%" set "%~2=!CAND!"
)
exit /b 0

:FAIL_GH
echo.
echo GitHub CLI bootstrap failed safely. No Windows repair change was made.
exit /b 95
