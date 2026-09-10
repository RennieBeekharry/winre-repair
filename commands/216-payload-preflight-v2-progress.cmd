@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=READ_ONLY
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Recheck free space and Microsoft repair-payload endpoints with WinRE-compatible commands.
rem WR_ACTION=PREFLIGHT_OFFICIAL_REPAIR_PAYLOAD_V2
rem WR_TARGET=C: free-space metadata and official Microsoft HTTPS endpoints only.
rem WR_CONSEQUENCE=Checks storage and HTTPS headers only; makes no Windows servicing changes.
rem WR_ROLLBACK=Not applicable.

set "WORK=C:\WinRERepair"
set "DETAILS=%WORK%\RUN_DETAILS.txt"
set "RESULT=%WORK%\COMMAND_RESULT.env"
set "CURL=C:\Windows\System32\curl.exe"
set "URL1=https://catalog.sf.dl.delivery.mp.microsoft.com/filestreamingservice/files/d8b7f92b-bd35-4b4c-96e5-46ce984b31e0/public/windows11.0-kb5043080-x64_953449672073f8fb99badb4cc6d5d7849b9c83e8.msu"
set "URL2=https://catalog.sf.dl.delivery.mp.microsoft.com/filestreamingservice/files/dbc14d78-9837-4fb2-afbc-75d6663bf1e5/public/windows11.0-kb5121003-x64_dc58f03fef04b4c611e0db0ab3fadfb301194113.msu"
if not exist "%WORK%" md "%WORK%" >nul 2>&1

cls
echo ================================================================================
echo RescueMeAI - RECOVERY PROGRESS
echo ================================================================================
echo STATUS            : RUNNING
echo CURRENT DIAGNOSIS : RestoreHealth confirmed required repair content is missing.
echo CURRENT TASK      : Rechecking local space and Microsoft package reachability.
echo SAFETY            : READ-ONLY PREFLIGHT - no Windows servicing changes.
echo SCREENSHOT NEEDED : NO - wait for the final status below.
echo ================================================================================
echo.

echo [1/3] Reading free-space information for C:...
fsutil volume diskfree C: >"%WORK%\diskfree.txt" 2>&1
set "FRC=!errorlevel!"

echo [2/3] Testing the Microsoft checkpoint-package HTTPS endpoint...
"%CURL%" --ssl-no-revoke -L -I -sS --connect-timeout 20 --max-time 45 "%URL1%" -o NUL -w "%%{http_code}" >"%WORK%\http1.txt" 2>"%WORK%\curl1-error.txt"
set "C1=!errorlevel!"
set "H1=NONE"
if exist "%WORK%\http1.txt" set /p "H1="<"%WORK%\http1.txt"
set "E1=NONE"
if exist "%WORK%\curl1-error.txt" set /p "E1="<"%WORK%\curl1-error.txt"

echo [3/3] Testing the Microsoft cumulative-update HTTPS endpoint...
"%CURL%" --ssl-no-revoke -L -I -sS --connect-timeout 20 --max-time 45 "%URL2%" -o NUL -w "%%{http_code}" >"%WORK%\http2.txt" 2>"%WORK%\curl2-error.txt"
set "C2=!errorlevel!"
set "H2=NONE"
if exist "%WORK%\http2.txt" set /p "H2="<"%WORK%\http2.txt"
set "E2=NONE"
if exist "%WORK%\curl2-error.txt" set /p "E2="<"%WORK%\curl2-error.txt"

>"%DETAILS%" echo RESCUEMEAI OFFICIAL PAYLOAD PREFLIGHT V2
>>"%DETAILS%" echo fsutil_exit=!FRC!
for /f "usebackq delims=" %%L in ("%WORK%\diskfree.txt") do >>"%DETAILS%" echo diskfree=%%L
>>"%DETAILS%" echo checkpoint_curl_exit=!C1!
>>"%DETAILS%" echo checkpoint_http=!H1!
>>"%DETAILS%" echo checkpoint_error=!E1!
>>"%DETAILS%" echo lcu_curl_exit=!C2!
>>"%DETAILS%" echo lcu_http=!H2!
>>"%DETAILS%" echo lcu_error=!E2!
>>"%DETAILS%" echo required_payload_bytes=6171370529

>"%RESULT%" echo STATUS=PASS
>>"%RESULT%" echo MESSAGE=WinRE-compatible payload preflight completed.
>>"%RESULT%" echo EVIDENCE=Disk-free output plus cURL exit and HTTP results attached.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=NO
>>"%RESULT%" echo NEXT_STEP=RescueMeAI will review space and reachability before any large download.

echo.
echo ================================================================================
echo STATUS            : COMPLETE
echo RESULT            : Space and Microsoft endpoint checks completed.
echo WINDOWS CHANGES   : NONE
echo NEXT STEP         : RescueMeAI is reviewing whether the official repair payload
echo                     can be downloaded safely on this connection.
echo SCREENSHOT NEEDED : NO
echo WHAT TO DO        : Leave this window open and keep the PC connected to power.
echo ================================================================================
exit /b 0
