@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR-MODULE: media-download-core 2026.08.14-1611-ET
set "W=C:\WinRERepair"
set "R=%W%\runtime"
set "M=%W%\media"
set "N=%R%\network.cmd"
set "C=C:\Windows\System32\curl.exe"
set "H=C:\Windows\System32\certutil.exe"
set "F=C:\Windows\System32\findstr.exe"
set "J=X:\Windows\System32\cscript.exe"
if not exist "%J%" set "J=C:\Windows\System32\cscript.exe"
set "O=%W%\COMMAND_RESULT.env"
set "SRC=37de4739ade208b4c771262964eda977095c5244"
set "HELP=%M%\uup-download.js"
set "DNS=%M%\rescuemeai-nslookup.cmd"
set "DOH=%M%\doh-resolve.js"
set "IPOUT=%M%\uup-api-addresses.txt"
set "META=%M%\uup-26100.8894-core-en-us.json"
set "UID=44ac3fa1-0cef-463b-a650-6240d396f894"
set "D="
set "UUPIP="
if not exist "%M%" md "%M%" >nul 2>&1
for %%X in (D E F G H I J K L M N O P Q R S T U V W Y Z) do (
  vol %%X: 2>nul | "%F%" /i /c:"REPAIRDATA" >nul 2>&1
  if not errorlevel 1 if not defined D set "D=%%X:"
)
if not defined D goto :NOVOL
set "DEST=%D%\RescueMeAI\Media\UUP\26100.8894-amd64-core-en-us"
for %%P in ("%D%\RescueMeAI" "%D%\RescueMeAI\Media" "%D%\RescueMeAI\Media\UUP" "%DEST%") do if not exist %%P md %%P >nul 2>&1

cls
echo ================================================================================================
echo                                    RESCUEMEAI
echo                           WINDOWS RECOVERY MEDIA DOWNLOAD
echo ================================================================================================
echo Status         : PREPARING DOWNLOAD
echo Destination    : %DEST%
echo Windows changes: NONE
echo ================================================================================================
echo.
echo CURRENT ACTIVITY: Loading the verified media downloader and DNS helper.
echo PLEASE WAIT. No action is required.

call "%N%" fetch "https://api.github.com/repos/RennieBeekharry/winre-repair/contents/tools/uup-download.js?ref=%SRC%" "%HELP%"
if errorlevel 1 goto :FETCHFAIL
call "%N%" fetch "https://api.github.com/repos/RennieBeekharry/winre-repair/contents/tools/rescuemeai-nslookup.cmd?ref=%SRC%" "%DNS%"
if errorlevel 1 goto :FETCHFAIL
call "%N%" fetch "https://api.github.com/repos/RennieBeekharry/winre-repair/contents/tools/doh-resolve.js?ref=%SRC%" "%DOH%"
if errorlevel 1 goto :FETCHFAIL
"%F%" /i /c:"WR-MODULE: uup-download-js 2026.08.14-1535-ET" "%HELP%" >nul 2>&1
if errorlevel 1 goto :FETCHFAIL
"%F%" /i /c:"WR-MODULE: rescuemeai-nslookup 2026.08.14-1609-ET" "%DNS%" >nul 2>&1
if errorlevel 1 goto :FETCHFAIL
"%F%" /i /c:"WR-MODULE: doh-resolve-js 2026.08.14-1608-ET" "%DOH%" >nul 2>&1
if errorlevel 1 goto :FETCHFAIL

cls
echo ================================================================================================
echo                                    RESCUEMEAI
echo                           WINDOWS RECOVERY MEDIA DOWNLOAD
echo ================================================================================================
echo Status         : CONNECTING TO SOURCE
echo Destination    : %DEST%
echo Windows changes: NONE
echo ================================================================================================
echo.
echo CURRENT ACTIVITY: Resolving the official UUP dump JSON API through DNS-over-HTTPS.
echo PLEASE WAIT. No action is required.

if exist "%IPOUT%" del /f /q "%IPOUT%" >nul 2>&1
"%J%" //nologo "%DOH%" "%C%" "api.uupdump.net" >"%IPOUT%" 2>"%M%\uup-doh-error.txt"
if errorlevel 1 goto :NETFAIL
for /f "usebackq tokens=1,2 delims=: " %%A in ("%IPOUT%") do if /i "%%A"=="Address" if not defined UUPIP set "UUPIP=%%B"
if not defined UUPIP goto :NETFAIL

set "UUPURL=https://api.uupdump.net/get.php?id=%UID%&lang=en-us&edition=core"
if exist "%META%" del /f /q "%META%" >nul 2>&1
"%C%" --ssl-no-revoke --fail --silent --show-error --connect-timeout 20 --max-time 300 --resolve "api.uupdump.net:443:%UUPIP%" "%UUPURL%" -o "%META%" 2>"%M%\uup-api-curl-error.txt"
if errorlevel 1 goto :NETFAIL
if not exist "%META%" goto :NETFAIL
for %%Z in ("%META%") do if %%~zZ LSS 1024 goto :METFAIL
"%F%" /c:"26100.8894" "%META%" >nul 2>&1
if errorlevel 1 goto :METFAIL
"%F%" /i /c:"amd64" "%META%" >nul 2>&1
if errorlevel 1 goto :METFAIL

cls
echo ================================================================================================
echo                                    RESCUEMEAI
echo                           WINDOWS RECOVERY MEDIA DOWNLOAD
echo ================================================================================================
echo Source         : Windows 11 24H2 build 26100.8894 x64 Home/Core en-US
echo Destination    : %DEST%
echo Windows changes: NONE
echo ================================================================================================
echo.
echo STATUS: DOWNLOADING AND VERIFYING RECOVERY SOURCE
echo.
echo PLEASE WAIT. Leave this window open.
echo RescueMeAI will show each file as it downloads and verifies it.
echo Partial downloads are resumable. Windows itself is not being changed.
echo.
"%J%" //nologo "%HELP%" "%C%" "%H%" "%DNS%" "%META%" "%DEST%" "%M%\uup-download-state.txt"
set "RC=!errorlevel!"
if not "!RC!"=="0" goto :DLFAIL
>"%O%" echo STATUS=PASS
>>"%O%" echo MESSAGE=Windows recovery source download completed and all downloaded files passed SHA-1 verification.
>>"%O%" echo EVIDENCE=Destination=%DEST%; source build 26100.8894 amd64 Core en-us.
>>"%O%" echo INSTRUCTION=Reply pass. RescueMeAI remains online.
exit /b 0

:NOVOL
set "MSG=The existing REPAIRDATA volume could not be found."
set "RC=90"
goto :FAIL
:FETCHFAIL
set "MSG=The verified recovery-media downloader could not be staged."
set "RC=90"
goto :FAIL
:NETFAIL
set "MSG=The official UUP dump metadata service could not be reached through the DNS-over-HTTPS route."
set "RC=92"
goto :FAIL
:METFAIL
set "MSG=The UUP metadata response did not match the selected Windows 11 recovery source."
set "RC=96"
goto :FAIL
:DLFAIL
set "MSG=The recovery-source download stopped before all files verified. Completed and partial files remain resumable."
if not defined RC set "RC=90"
:FAIL
>"%O%" echo STATUS=FAIL
>>"%O%" echo MESSAGE=%MSG%
>>"%O%" echo EVIDENCE=No Windows system, boot, disk, or partition state was changed.
>>"%O%" echo INSTRUCTION=Reply fail. RescueMeAI remains online.
exit /b %RC%
