@echo off
setlocal EnableExtensions EnableDelayedExpansion

rem One-time bootstrap for the private diagnostic log channel.
set "COMMAND_VERSION=WR-2026.08.14-0130-ET"
set "BUILD_TIME=2026-08-14 01:30 ET"
set "WORK=C:\WinRERepair"
set "CURL=C:\Windows\System32\curl.exe"
set "NSLOOKUP=C:\Windows\System32\nslookup.exe"
set "FINDSTR=C:\Windows\System32\findstr.exe"
set "DNS=64.71.255.204"
set "APIHOST=api.github.com"
set "LAUNCHER_URL=https://api.github.com/repos/RennieBeekharry/winre-repair/contents/wr.cmd?ref=main"
set "NEWLAUNCHER=%WORK%\wr-new.cmd"
set "UPDATER=%WORK%\finish-launcher-update.cmd"
set "EXPECTED=WR-LAUNCHER-2026.08.14-0128-ET"

cls
echo ================================================================
echo WINRE-REPAIR - PRIVATE LOG CHANNEL BOOTSTRAP
echo Version: %COMMAND_VERSION%
echo Built:   %BUILD_TIME%
echo Fetched: %date% %time%
echo ================================================================

if not exist "%WORK%" md "%WORK%" >nul 2>&1
if not exist "%CURL%" (
  echo BOOTSTRAP FAILED: curl.exe was not found.
  exit /b 10
)

if exist "%NEWLAUNCHER%" del /f /q "%NEWLAUNCHER%" >nul 2>&1

set "APIIP="
call :RESOLVE %APIHOST% APIIP
if defined APIIP (
  "%CURL%" --ssl-no-revoke --fail --location --silent --show-error --connect-timeout 10 --max-time 120 --resolve "%APIHOST%:443:!APIIP!" -H "Accept: application/vnd.github.raw+json" -H "X-GitHub-Api-Version: 2026-03-10" -H "Cache-Control: no-cache, no-store, max-age=0" -H "Pragma: no-cache" "%LAUNCHER_URL%" -o "%NEWLAUNCHER%"
)
if not exist "%NEWLAUNCHER%" (
  "%CURL%" --ssl-no-revoke --fail --location --silent --show-error --connect-timeout 10 --max-time 120 -H "Accept: application/vnd.github.raw+json" -H "X-GitHub-Api-Version: 2026-03-10" -H "Cache-Control: no-cache, no-store, max-age=0" -H "Pragma: no-cache" "%LAUNCHER_URL%" -o "%NEWLAUNCHER%"
)

if not exist "%NEWLAUNCHER%" (
  echo BOOTSTRAP FAILED: could not download the new launcher.
  exit /b 11
)
%FINDSTR% /l /c:"LAUNCHER_VERSION=%EXPECTED%" "%NEWLAUNCHER%" >nul 2>&1
if errorlevel 1 (
  echo BOOTSTRAP FAILED: downloaded launcher version did not validate.
  del /f /q "%NEWLAUNCHER%" >nul 2>&1
  exit /b 12
)

echo New launcher validated: %EXPECTED%
echo.
echo Starting one-time private log authorization and upload setup...
echo.

call "%NEWLAUNCHER%" /setup-logs ^
  "%WORK%\post-driver-0x7b-diagnostic.log" ^
  "%WORK%\setupapi-storage.txt" ^
  "%WORK%\driver-inventory.txt" ^
  "%WORK%\package-state.txt"
set "SETUPRC=!errorlevel!"
if not "!SETUPRC!"=="0" (
  echo.
  echo BOOTSTRAP STOPPED: private log setup returned error !SETUPRC!.
  echo The existing C:\wr.cmd was not replaced.
  exit /b !SETUPRC!
)

rem C:\wr.cmd is the parent batch file currently executing, so replacing it
rem synchronously can corrupt the caller's remaining instruction stream.
rem Schedule a tiny delayed updater that runs after this bootstrap and its
rem parent launcher have exited.
>"%UPDATER%" echo @echo off
>>"%UPDATER%" echo ping -n 5 127.0.0.1 ^>nul 2^>^&1
>>"%UPDATER%" echo if exist "C:\wr.cmd" copy /y "C:\wr.cmd" "%WORK%\wr-launcher-before-private-logs.cmd" ^>nul 2^>^&1
>>"%UPDATER%" echo copy /y "%NEWLAUNCHER%" "C:\wr.cmd" ^>nul 2^>^&1
>>"%UPDATER%" echo del /f /q "%NEWLAUNCHER%" ^>nul 2^>^&1
>>"%UPDATER%" echo del /f /q "%%~f0" ^>nul 2^>^&1

start "" /b X:\Windows\System32\cmd.exe /d /c ""%UPDATER%"" >nul 2>&1

echo.
echo ================================================================
echo PRIVATE LOG CHANNEL BOOTSTRAP COMPLETE
echo Existing diagnostics were submitted to the private repository.
echo C:\wr.cmd will be upgraded automatically in about 5 seconds.
echo.
echo You do NOT need to upload screenshots of these logs again.
echo When this screen returns to the prompt, tell ChatGPT: DONE
echo ================================================================
exit /b 0

:RESOLVE
set "%~2="
set "CAND="
for /f "delims=" %%L in ('%NSLOOKUP% %~1 %DNS% 2^>nul ^| %FINDSTR% /R "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*"') do (
  for %%T in (%%L) do set "CAND=%%T"
  if not "!CAND!"=="%DNS%" set "%~2=!CAND!"
)
exit /b 0
