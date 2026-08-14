@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=REPAIR_WRITE
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Verify the existing REPAIRDATA volume and retrieve Windows 11 UUP source metadata before download.
rem WR_ACTION=MEDIA_DOWNLOAD_PREFLIGHT
rem WR_TARGET=REPAIRDATA media workspace and RescueMeAI temporary files only.
rem WR_CONSEQUENCE=Creates a RescueMeAI media workspace and downloads source metadata. It does not modify Windows or partition layout.
rem WR_ROLLBACK=Delete the RescueMeAI media workspace files created by this preflight.

set "WORK=C:\WinRERepair"
set "MEDIAWORK=%WORK%\media"
set "RUNTIME=%WORK%\runtime"
set "RESOLVER=%RUNTIME%\resolve.cmd"
set "CURL=C:\Windows\System32\curl.exe"
set "FINDSTR=C:\Windows\System32\findstr.exe"
set "FSUTIL=C:\Windows\System32\fsutil.exe"
set "RESULT=%WORK%\COMMAND_RESULT.env"
set "DETAIL=%MEDIAWORK%\preflight-details.txt"
set "META=%MEDIAWORK%\uup-26100.8894-core-en-us.json"
set "HTTPFILE=%MEDIAWORK%\uup-http.txt"
set "ERRFILE=%MEDIAWORK%\uup-curl-error.txt"
set "UUPHOST=api.uupdump.net"
set "UUPID=44ac3fa1-0cef-463b-a650-6240d396f894"
set "UUPURL=https://api.uupdump.net/get.php?id=%UUPID%^&lang=en-us^&edition=core"
set "MEDIA_DRIVE="
set "FREE_BYTES=UNKNOWN"
set "UUPIP="

if not exist "%MEDIAWORK%" md "%MEDIAWORK%" >nul 2>&1
if not exist "%RESOLVER%" goto :FAIL_RUNTIME
if not exist "%CURL%" goto :FAIL_RUNTIME
if not exist "%FINDSTR%" goto :FAIL_RUNTIME

for %%D in (D E F G H I J K L M N O P Q R S T U V W Y Z) do (
  vol %%D: 2>nul | "%FINDSTR%" /i /c:"REPAIRDATA" >nul 2>&1
  if not errorlevel 1 if not defined MEDIA_DRIVE set "MEDIA_DRIVE=%%D:"
)

if not defined MEDIA_DRIVE goto :FAIL_VOLUME

if not exist "%MEDIA_DRIVE%\RescueMeAI" md "%MEDIA_DRIVE%\RescueMeAI" >nul 2>&1
if not exist "%MEDIA_DRIVE%\RescueMeAI\Media" md "%MEDIA_DRIVE%\RescueMeAI\Media" >nul 2>&1
>"%MEDIA_DRIVE%\RescueMeAI\Media\.write-test.tmp" echo RescueMeAI media preflight
if errorlevel 1 goto :FAIL_WRITE
del /f /q "%MEDIA_DRIVE%\RescueMeAI\Media\.write-test.tmp" >nul 2>&1

if exist "%FSUTIL%" (
  for /f "tokens=2 delims=:" %%A in ('"%FSUTIL%" volume diskfree %MEDIA_DRIVE% 2^>nul ^| "%FINDSTR%" /i /c:"free bytes"') do if "!FREE_BYTES!"=="UNKNOWN" set "FREE_BYTES=%%A"
  set "FREE_BYTES=!FREE_BYTES: =!"
)

call "%RESOLVER%" resolve "%UUPHOST%" UUPIP
if errorlevel 1 goto :FAIL_UUP_NETWORK
if not defined UUPIP goto :FAIL_UUP_NETWORK

if exist "%META%" del /f /q "%META%" >nul 2>&1
if exist "%HTTPFILE%" del /f /q "%HTTPFILE%" >nul 2>&1
"%CURL%" --ssl-no-revoke --fail --silent --show-error --connect-timeout 15 --max-time 180 --resolve "%UUPHOST%:443:%UUPIP%" "%UUPURL%" -o "%META%" -w "%%{http_code}" >"%HTTPFILE%" 2>"%ERRFILE%"
set "CRC=!errorlevel!"
set "HTTP=000"
if exist "%HTTPFILE%" set /p "HTTP="<"%HTTPFILE%"
if not "!CRC!"=="0" goto :FAIL_UUP_METADATA
if not "!HTTP!"=="200" goto :FAIL_UUP_METADATA
if not exist "%META%" goto :FAIL_UUP_METADATA
for %%Z in ("%META%") do if %%~zZ LSS 1024 goto :FAIL_UUP_METADATA

"%FINDSTR%" /c:"26100.8894" "%META%" >nul 2>&1
if errorlevel 1 goto :FAIL_UUP_CONTENT
"%FINDSTR%" /i /c:"amd64" "%META%" >nul 2>&1
if errorlevel 1 goto :FAIL_UUP_CONTENT
"%FINDSTR%" /i /c:"core" "%META%" >nul 2>&1
if errorlevel 1 goto :FAIL_UUP_CONTENT

>"%DETAIL%" echo status=PASS
>>"%DETAIL%" echo media_drive=%MEDIA_DRIVE%
>>"%DETAIL%" echo media_path=%MEDIA_DRIVE%\RescueMeAI\Media
>>"%DETAIL%" echo free_bytes=%FREE_BYTES%
>>"%DETAIL%" echo uup_id=%UUPID%
>>"%DETAIL%" echo build=26100.8894
>>"%DETAIL%" echo arch=amd64
>>"%DETAIL%" echo language=en-us
>>"%DETAIL%" echo edition=core
>>"%DETAIL%" echo uup_api_ip=%UUPIP%
>>"%DETAIL%" echo uup_http=%HTTP%

>"%RESULT%" echo STATUS=PASS
>>"%RESULT%" echo MESSAGE=Recovery media download preflight passed.
>>"%RESULT%" echo EVIDENCE=REPAIRDATA=%MEDIA_DRIVE%; free_bytes=%FREE_BYTES%; Windows 11 24H2 build 26100.8894 amd64 Core en-us metadata verified.
>>"%RESULT%" echo INSTRUCTION=No user action is required. RescueMeAI remains online while ChatGPT prepares the resumable media download.
exit /b 0

:FAIL_RUNTIME
>"%RESULT%" echo STATUS=FAIL
>>"%RESULT%" echo MESSAGE=Recovery media preflight could not start because a required RescueMeAI runtime component is missing.
>>"%RESULT%" echo EVIDENCE=No Windows recovery state was changed.
>>"%RESULT%" echo INSTRUCTION=Reply fail. RescueMeAI remains online.
exit /b 91

:FAIL_VOLUME
>"%RESULT%" echo STATUS=FAIL
>>"%RESULT%" echo MESSAGE=RescueMeAI could not find a mounted volume labeled REPAIRDATA.
>>"%RESULT%" echo EVIDENCE=No disk or partition changes were attempted.
>>"%RESULT%" echo INSTRUCTION=Reply fail. RescueMeAI remains online.
exit /b 90

:FAIL_WRITE
>"%RESULT%" echo STATUS=FAIL
>>"%RESULT%" echo MESSAGE=REPAIRDATA was found but RescueMeAI could not write to its media workspace.
>>"%RESULT%" echo EVIDENCE=No Windows recovery state was changed.
>>"%RESULT%" echo INSTRUCTION=Reply fail. RescueMeAI remains online.
exit /b 97

:FAIL_UUP_NETWORK
>"%RESULT%" echo STATUS=FAIL
>>"%RESULT%" echo MESSAGE=RescueMeAI could not establish a validated HTTPS route to the UUP metadata service.
>>"%RESULT%" echo EVIDENCE=REPAIRDATA=%MEDIA_DRIVE%; no Windows recovery state was changed.
>>"%RESULT%" echo INSTRUCTION=Reply fail. RescueMeAI remains online.
exit /b 92

:FAIL_UUP_METADATA
>"%RESULT%" echo STATUS=FAIL
>>"%RESULT%" echo MESSAGE=The UUP metadata request failed.
>>"%RESULT%" echo EVIDENCE=REPAIRDATA=%MEDIA_DRIVE%; HTTP=!HTTP!; curl=!CRC!; no Windows recovery state was changed.
>>"%RESULT%" echo INSTRUCTION=Reply fail. RescueMeAI remains online.
exit /b 90

:FAIL_UUP_CONTENT
>"%RESULT%" echo STATUS=FAIL
>>"%RESULT%" echo MESSAGE=The downloaded UUP metadata did not match the selected Windows recovery source.
>>"%RESULT%" echo EVIDENCE=Expected Windows 11 24H2 build 26100.8894 amd64 Core en-us. No media files were downloaded.
>>"%RESULT%" echo INSTRUCTION=Reply fail. RescueMeAI remains online.
exit /b 96
