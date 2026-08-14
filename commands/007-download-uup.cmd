@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=REPAIR_WRITE
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Download and verify the selected Windows 11 recovery source into the existing REPAIRDATA volume.
rem WR_ACTION=DOWNLOAD_WINDOWS_RECOVERY_SOURCE
rem WR_TARGET=REPAIRDATA RescueMeAI Media workspace only.
rem WR_CONSEQUENCE=Downloads Windows recovery source files and a local manifest. Windows system state and partition layout are not changed.
rem WR_ROLLBACK=Delete the RescueMeAI Media source folder if the downloaded recovery source is no longer needed.

set "WORK=C:\WinRERepair"
set "RUNTIME=%WORK%\runtime"
set "MEDIAWORK=%WORK%\media"
set "NETWORK=%RUNTIME%\network.cmd"
set "RESOLVER=%RUNTIME%\resolve.cmd"
set "CURL=C:\Windows\System32\curl.exe"
set "CERTUTIL=C:\Windows\System32\certutil.exe"
set "FINDSTR=C:\Windows\System32\findstr.exe"
set "CSCRIPT=X:\Windows\System32\cscript.exe"
if not exist "%CSCRIPT%" set "CSCRIPT=C:\Windows\System32\cscript.exe"
set "RESULT=%WORK%\COMMAND_RESULT.env"
set "STATE=%MEDIAWORK%\uup-download-state.txt"
set "META=%MEDIAWORK%\uup-26100.8894-core-en-us.json"
set "HELPER=%MEDIAWORK%\uup-download.js"
set "DNS_SHIM=%MEDIAWORK%\rescuemeai-nslookup.cmd"
set "SOURCE_REF=7fa4eac814f5a4b017187fdbec05f697df955815"
set "HELPER_URL=https://api.github.com/repos/RennieBeekharry/winre-repair/contents/tools/uup-download.js?ref=%SOURCE_REF%"
set "DNS_URL=https://api.github.com/repos/RennieBeekharry/winre-repair/contents/tools/rescuemeai-nslookup.cmd?ref=%SOURCE_REF%"
set "UUPHOST=api.uupdump.net"
set "UUPID=44ac3fa1-0cef-463b-a650-6240d396f894"
set "UUPIP="
set "MEDIA_DRIVE="
set "DEST="
set "HTTP=000"
set "CRC=90"

if not exist "%MEDIAWORK%" md "%MEDIAWORK%" >nul 2>&1
for %%F in ("%NETWORK%" "%RESOLVER%" "%CURL%" "%CERTUTIL%" "%FINDSTR%" "%CSCRIPT%") do if not exist %%F goto :FAIL_RUNTIME

for %%D in (D E F G H I J K L M N O P Q R S T U V W Y Z) do (
  vol %%D: 2>nul | "%FINDSTR%" /i /c:"REPAIRDATA" >nul 2>&1
  if not errorlevel 1 if not defined MEDIA_DRIVE set "MEDIA_DRIVE=%%D:"
)
if not defined MEDIA_DRIVE goto :FAIL_VOLUME

set "DEST=%MEDIA_DRIVE%\RescueMeAI\Media\UUP\26100.8894-amd64-core-en-us"
for %%P in ("%MEDIA_DRIVE%\RescueMeAI" "%MEDIA_DRIVE%\RescueMeAI\Media" "%MEDIA_DRIVE%\RescueMeAI\Media\UUP" "%DEST%") do if not exist %%P md %%P >nul 2>&1
>"%DEST%\.write-test.tmp" echo RescueMeAI recovery media download
if errorlevel 1 goto :FAIL_WRITE
del /f /q "%DEST%\.write-test.tmp" >nul 2>&1

call "%NETWORK%" fetch "%HELPER_URL%" "%HELPER%"
if errorlevel 1 goto :FAIL_HELPER
"%FINDSTR%" /i /c:"WR-MODULE: uup-download-js 2026.08.14-1535-ET" "%HELPER%" >nul 2>&1
if errorlevel 1 goto :FAIL_HELPER
call "%NETWORK%" fetch "%DNS_URL%" "%DNS_SHIM%"
if errorlevel 1 goto :FAIL_HELPER
"%FINDSTR%" /i /c:"WR-MODULE: rescuemeai-nslookup 2026.08.14-1600-ET" "%DNS_SHIM%" >nul 2>&1
if errorlevel 1 goto :FAIL_HELPER

call "%RESOLVER%" resolve "%UUPHOST%" UUPIP
if errorlevel 1 goto :FAIL_UUP_NETWORK
if not defined UUPIP goto :FAIL_UUP_NETWORK

set "UUPURL=https://%UUPHOST%/get.php?id=%UUPID%^&lang=en-us^&edition=core"
if exist "%META%" del /f /q "%META%" >nul 2>&1
"%CURL%" --ssl-no-revoke --fail --silent --show-error --connect-timeout 15 --max-time 240 --resolve "%UUPHOST%:443:%UUPIP%" "%UUPURL%" -o "%META%" -w "%%{http_code}" >"%MEDIAWORK%\uup-http.txt" 2>"%MEDIAWORK%\uup-curl-error.txt"
set "CRC=!errorlevel!"
if exist "%MEDIAWORK%\uup-http.txt" set /p "HTTP="<"%MEDIAWORK%\uup-http.txt"
if not "!CRC!"=="0" goto :FAIL_UUP_METADATA
if not "!HTTP!"=="200" goto :FAIL_UUP_METADATA
if not exist "%META%" goto :FAIL_UUP_METADATA
for %%Z in ("%META%") do if %%~zZ LSS 1024 goto :FAIL_UUP_METADATA
"%FINDSTR%" /c:"26100.8894" "%META%" >nul 2>&1
if errorlevel 1 goto :FAIL_UUP_CONTENT
"%FINDSTR%" /i /c:"amd64" "%META%" >nul 2>&1
if errorlevel 1 goto :FAIL_UUP_CONTENT

cls
color 0B >nul 2>&1
echo ================================================================================================
echo                                    RESCUEMEAI
echo                           WINDOWS RECOVERY MEDIA DOWNLOAD
echo ================================================================================================
echo Source         : Windows 11 24H2 build 26100.8894 x64 Home/Core en-US
echo Destination    : %DEST%
echo Windows changes: NONE
echo ================================================================================================
echo.
echo STATUS: DOWNLOADING RECOVERY SOURCE
echo.
echo PLEASE WAIT. Leave this window open while the download is running.
echo Existing partial files will be resumed when possible and every completed
echo source file will be checked against the SHA-1 supplied by the UUP metadata.
echo No Windows system file, boot setting, disk layout, or partition is being changed.
echo.

"%CSCRIPT%" //nologo "%HELPER%" "%CURL%" "%CERTUTIL%" "%DNS_SHIM%" "%META%" "%DEST%" "%STATE%"
set "DRC=!errorlevel!"
if "!DRC!"=="0" goto :PASS
if "!DRC!"=="92" goto :FAIL_DOWNLOAD_NETWORK
if "!DRC!"=="96" goto :FAIL_INTEGRITY
if "!DRC!"=="97" goto :FAIL_SPACE
goto :FAIL_DOWNLOAD

:PASS
>"%RESULT%" echo STATUS=PASS
>>"%RESULT%" echo MESSAGE=Windows recovery source download completed and all downloaded UUP files passed SHA-1 verification.
>>"%RESULT%" echo EVIDENCE=Source Windows 11 24H2 build 26100.8894 amd64 Core en-us; destination=%DEST%; local manifest created.
>>"%RESULT%" echo INSTRUCTION=Reply pass. RescueMeAI remains online.
exit /b 0

:FAIL_RUNTIME
>"%RESULT%" echo STATUS=FAIL
>>"%RESULT%" echo MESSAGE=Recovery source download could not start because a required RescueMeAI component is missing.
>>"%RESULT%" echo EVIDENCE=No Windows recovery state was changed.
>>"%RESULT%" echo INSTRUCTION=Reply fail. RescueMeAI remains online.
exit /b 91

:FAIL_VOLUME
>"%RESULT%" echo STATUS=FAIL
>>"%RESULT%" echo MESSAGE=RescueMeAI could not find the existing REPAIRDATA volume.
>>"%RESULT%" echo EVIDENCE=No disk or partition changes were attempted.
>>"%RESULT%" echo INSTRUCTION=Reply fail. RescueMeAI remains online.
exit /b 90

:FAIL_WRITE
>"%RESULT%" echo STATUS=FAIL
>>"%RESULT%" echo MESSAGE=REPAIRDATA was found but the RescueMeAI Media workspace is not writable.
>>"%RESULT%" echo EVIDENCE=No Windows recovery state was changed.
>>"%RESULT%" echo INSTRUCTION=Reply fail. RescueMeAI remains online.
exit /b 97

:FAIL_HELPER
>"%RESULT%" echo STATUS=FAIL
>>"%RESULT%" echo MESSAGE=RescueMeAI could not stage the pinned recovery-media downloader.
>>"%RESULT%" echo EVIDENCE=No Windows recovery state was changed and no media download began.
>>"%RESULT%" echo INSTRUCTION=Reply fail. RescueMeAI remains online.
exit /b 96

:FAIL_UUP_NETWORK
>"%RESULT%" echo STATUS=FAIL
>>"%RESULT%" echo MESSAGE=RescueMeAI could not establish a validated HTTPS route to the UUP metadata service.
>>"%RESULT%" echo EVIDENCE=Destination=%DEST%; no Windows recovery state was changed.
>>"%RESULT%" echo INSTRUCTION=Reply fail. RescueMeAI remains online.
exit /b 92

:FAIL_UUP_METADATA
>"%RESULT%" echo STATUS=FAIL
>>"%RESULT%" echo MESSAGE=The Windows recovery-source metadata request failed.
>>"%RESULT%" echo EVIDENCE=HTTP=!HTTP!; curl=!CRC!; no Windows recovery state was changed.
>>"%RESULT%" echo INSTRUCTION=Reply fail. RescueMeAI remains online.
exit /b 90

:FAIL_UUP_CONTENT
>"%RESULT%" echo STATUS=FAIL
>>"%RESULT%" echo MESSAGE=The UUP metadata did not match the selected Windows recovery source.
>>"%RESULT%" echo EVIDENCE=Expected Windows 11 24H2 build 26100.8894 amd64. No source download began.
>>"%RESULT%" echo INSTRUCTION=Reply fail. RescueMeAI remains online.
exit /b 96

:FAIL_DOWNLOAD_NETWORK
>"%RESULT%" echo STATUS=FAIL
>>"%RESULT%" echo MESSAGE=The recovery-source download stopped because a Microsoft download host could not be reached.
>>"%RESULT%" echo EVIDENCE=Completed and partial files remain on REPAIRDATA for the next resumable attempt.
>>"%RESULT%" echo INSTRUCTION=Reply fail. RescueMeAI remains online.
exit /b 92

:FAIL_INTEGRITY
>"%RESULT%" echo STATUS=FAIL
>>"%RESULT%" echo MESSAGE=A recovery-source file failed metadata or SHA-1 verification.
>>"%RESULT%" echo EVIDENCE=The unverified file was not accepted as complete; verified files remain for resume.
>>"%RESULT%" echo INSTRUCTION=Reply fail. RescueMeAI remains online.
exit /b 96

:FAIL_SPACE
>"%RESULT%" echo STATUS=FAIL
>>"%RESULT%" echo MESSAGE=REPAIRDATA does not have enough free space for the remaining source plus the reserved conversion margin.
>>"%RESULT%" echo EVIDENCE=Existing downloaded files remain intact. No Windows recovery state was changed.
>>"%RESULT%" echo INSTRUCTION=Reply fail. RescueMeAI remains online.
exit /b 97

:FAIL_DOWNLOAD
>"%RESULT%" echo STATUS=FAIL
>>"%RESULT%" echo MESSAGE=The Windows recovery-source download stopped unexpectedly.
>>"%RESULT%" echo EVIDENCE=Existing completed/partial files remain on REPAIRDATA and the next attempt can resume them.
>>"%RESULT%" echo INSTRUCTION=Reply fail. RescueMeAI remains online.
exit /b 90
