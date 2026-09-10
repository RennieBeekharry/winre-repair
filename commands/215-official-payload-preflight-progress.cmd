@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=READ_ONLY
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Verify free disk space and Microsoft payload availability before downloading repair packages.
rem WR_ACTION=PREFLIGHT_OFFICIAL_REPAIR_PAYLOAD
rem WR_TARGET=C: free-space metadata and official Microsoft download endpoints only.
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
echo CURRENT DIAGNOSIS : The Windows component store needs repair content that is not
echo                     available locally. Direct update rollback also failed.
echo CURRENT TASK      : Verifying space and official Microsoft repair payloads.
echo SAFETY            : READ-ONLY PREFLIGHT - no Windows servicing changes.
echo SCREENSHOT NEEDED : NO - wait for the final status below.
echo ================================================================================
echo.

echo [1/4] Checking free space on C:...
set "FREE=UNKNOWN"
for /f "tokens=3" %%A in ('fsutil volume diskfree C: ^| findstr /i /c:"Total free bytes"') do if not defined FREE set "FREE=%%A"

echo [2/4] Verifying Microsoft checkpoint package endpoint...
set "H1=000"
for /f %%H in ('"%CURL%" --ssl-no-revoke -L -s -o NUL -w "%%{http_code}" --max-time 45 -r 0-0 "%URL1%"') do set "H1=%%H"

echo [3/4] Verifying Microsoft cumulative-update package endpoint...
set "H2=000"
for /f %%H in ('"%CURL%" --ssl-no-revoke -L -s -o NUL -w "%%{http_code}" --max-time 45 -r 0-0 "%URL2%"') do set "H2=%%H"

echo [4/4] Building download-readiness summary...
>"%DETAILS%" echo RESCUEMEAI OFFICIAL PAYLOAD PREFLIGHT
>>"%DETAILS%" echo c_free_bytes=!FREE!
>>"%DETAILS%" echo kb5043080_http=!H1!
>>"%DETAILS%" echo kb5043080_expected_bytes=533761740
>>"%DETAILS%" echo kb5121003_http=!H2!
>>"%DETAILS%" echo kb5121003_expected_bytes=5637608789
>>"%DETAILS%" echo combined_expected_bytes=6171370529
>>"%DETAILS%" echo source=Microsoft Update Catalog delivery endpoints

if not "!H1!"=="206" if not "!H1!"=="200" goto :FAIL
if not "!H2!"=="206" if not "!H2!"=="200" goto :FAIL

>"%RESULT%" echo STATUS=PASS
>>"%RESULT%" echo MESSAGE=Official Microsoft repair-payload endpoints are reachable.
>>"%RESULT%" echo EVIDENCE=Free-space metadata and both official endpoint HTTP results attached.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=NO
>>"%RESULT%" echo NEXT_STEP=RescueMeAI will verify space is sufficient before downloading the repair payload.

echo.
echo ================================================================================
echo STATUS            : COMPLETE
echo RESULT            : Official Microsoft payload endpoints are reachable.
echo WINDOWS CHANGES   : NONE
echo NEXT STEP         : RescueMeAI is checking whether there is enough local space
echo                     for approximately 6.2 GB of official repair packages.
echo SCREENSHOT NEEDED : NO
echo WHAT TO DO        : Leave this window open and keep the PC connected to power.
echo ================================================================================
exit /b 0

:FAIL
>"%RESULT%" echo STATUS=WARNING
>>"%RESULT%" echo MESSAGE=One or more official Microsoft payload endpoints could not be verified.
>>"%RESULT%" echo EVIDENCE=HTTP results attached; no repair package was downloaded.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=NO
>>"%RESULT%" echo NEXT_STEP=RescueMeAI will review the connectivity result before continuing.
echo.
echo ================================================================================
echo STATUS            : WAITING FOR REVIEW
echo RESULT            : Microsoft payload verification was incomplete.
echo WINDOWS CHANGES   : NONE
echo SCREENSHOT NEEDED : NO
echo WHAT TO DO        : Leave this window open and keep the PC connected to power.
echo ================================================================================
exit /b 40
