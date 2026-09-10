@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=REPAIR_WRITE
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Download and integrity-check the official Microsoft checkpoint and cumulative-update repair packages.
rem WR_ACTION=DOWNLOAD_OFFICIAL_KB5121003_PAYLOAD
rem WR_TARGET=C:\RescueMeAI\packages\KB5121003 only; no Windows servicing operation is performed.
rem WR_CONSEQUENCE=Downloads about 6.2 GB of official Microsoft update files to local recovery storage; Windows system components are not changed by this command.
rem WR_ROLLBACK=Downloaded files can be deleted later if not needed; this command does not alter the offline Windows image.

set "PKGDIR=C:\RescueMeAI\packages\KB5121003"
set "WORK=C:\WinRERepair"
set "DETAILS=%WORK%\RUN_DETAILS.txt"
set "RESULT=%WORK%\COMMAND_RESULT.env"
set "CURL=C:\Windows\System32\curl.exe"
set "P1=%PKGDIR%\windows11.0-kb5043080-x64_953449672073f8fb99badb4cc6d5d7849b9c83e8.msu"
set "P2=%PKGDIR%\windows11.0-kb5121003-x64_dc58f03fef04b4c611e0db0ab3fadfb301194113.msu"
set "URL1=https://catalog.sf.dl.delivery.mp.microsoft.com/filestreamingservice/files/d8b7f92b-bd35-4b4c-96e5-46ce984b31e0/public/windows11.0-kb5043080-x64_953449672073f8fb99badb4cc6d5d7849b9c83e8.msu"
set "URL2=https://catalog.sf.dl.delivery.mp.microsoft.com/filestreamingservice/files/dbc14d78-9837-4fb2-afbc-75d6663bf1e5/public/windows11.0-kb5121003-x64_dc58f03fef04b4c611e0db0ab3fadfb301194113.msu"
if not exist "%PKGDIR%" md "%PKGDIR%" >nul 2>&1
if not exist "%WORK%" md "%WORK%" >nul 2>&1

cls
echo ================================================================================
echo RescueMeAI - OFFICIAL REPAIR PAYLOAD DOWNLOAD
echo ================================================================================
echo STATUS            : RUNNING
echo CURRENT DIAGNOSIS : Windows says required repair content cannot be found locally.
echo CURRENT TASK      : Downloading the exact Microsoft packages for build 26200.9168.
echo SAFETY            : REPAIR-WRITE - DOWNLOAD ONLY; Windows is not being serviced yet.
echo DOWNLOAD SIZE     : Approximately 6.2 GB total.
echo FREE SPACE        : Preflight found approximately 277 GB available.
echo SCREENSHOT NEEDED : NO - wait for the final status below.
echo ================================================================================
echo.

set "S1=0"
if exist "%P1%" for %%F in ("%P1%") do set "S1=%%~zF"
if "!S1!"=="533761740" goto :P1DONE
echo [1/4] Downloading Microsoft checkpoint package KB5043080 - about 509 MB...
echo       The progress bar below is the live download status.
"%CURL%" --ssl-no-revoke -L --fail --retry 5 --retry-delay 5 --retry-all-errors -C - --progress-bar "%URL1%" -o "%P1%"
if errorlevel 1 goto :DOWNLOADFAIL
:P1DONE
for %%F in ("%P1%") do set "S1=%%~zF"
if not "!S1!"=="533761740" goto :SIZEFAIL

echo.
echo [2/4] Verifying KB5043080 integrity...
certutil -hashfile "%P1%" SHA1 >"%WORK%\kb5043080-sha1.txt" 2>&1
findstr /i /c:"953449672073f8fb99badb4cc6d5d7849b9c83e8" "%WORK%\kb5043080-sha1.txt" >nul 2>&1
if errorlevel 1 goto :HASHFAIL
echo       KB5043080 size and SHA-1 match the Microsoft package filename.

set "S2=0"
if exist "%P2%" for %%F in ("%P2%") do set "S2=%%~zF"
if "!S2!"=="5637608789" goto :P2DONE
echo.
echo [3/4] Downloading Microsoft cumulative update KB5121003 - about 5.4 GB...
echo       This is the long step. The progress bar below is the live download status.
"%CURL%" --ssl-no-revoke -L --fail --retry 5 --retry-delay 5 --retry-all-errors -C - --progress-bar "%URL2%" -o "%P2%"
if errorlevel 1 goto :DOWNLOADFAIL
:P2DONE
for %%F in ("%P2%") do set "S2=%%~zF"
if not "!S2!"=="5637608789" goto :SIZEFAIL

echo.
echo [4/4] Verifying KB5121003 integrity...
certutil -hashfile "%P2%" SHA1 >"%WORK%\kb5121003-sha1.txt" 2>&1
findstr /i /c:"dc58f03fef04b4c611e0db0ab3fadfb301194113" "%WORK%\kb5121003-sha1.txt" >nul 2>&1
if errorlevel 1 goto :HASHFAIL
echo       KB5121003 size and SHA-1 match the Microsoft package filename.

>"%DETAILS%" echo RESCUEMEAI OFFICIAL REPAIR PAYLOAD DOWNLOAD
>>"%DETAILS%" echo kb5043080_bytes=!S1!
>>"%DETAILS%" echo kb5043080_sha1=953449672073f8fb99badb4cc6d5d7849b9c83e8
>>"%DETAILS%" echo kb5121003_bytes=!S2!
>>"%DETAILS%" echo kb5121003_sha1=dc58f03fef04b4c611e0db0ab3fadfb301194113
>>"%DETAILS%" echo source=Microsoft Update Catalog delivery endpoints
>>"%DETAILS%" echo windows_servicing_performed=NO

>"%RESULT%" echo STATUS=PASS
>>"%RESULT%" echo MESSAGE=Official Microsoft repair packages downloaded and integrity checked successfully.
>>"%RESULT%" echo EVIDENCE=Expected sizes and SHA-1 values confirmed for both packages.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=NO
>>"%RESULT%" echo NEXT_STEP=RescueMeAI will review the verified payload before applying any servicing change.

echo.
echo ================================================================================
echo STATUS            : COMPLETE
echo RESULT            : Official Microsoft repair payload downloaded and verified.
echo WINDOWS SERVICING : NOT STARTED
echo NEXT STEP         : RescueMeAI is reviewing the verified packages before use.
echo SCREENSHOT NEEDED : NO
echo WHAT TO DO        : Leave this window open and keep the PC connected to power.
echo ================================================================================
exit /b 0

:DOWNLOADFAIL
>"%RESULT%" echo STATUS=WARNING
>>"%RESULT%" echo MESSAGE=Official Microsoft package download was interrupted; partial files were retained for resume.
>>"%RESULT%" echo EVIDENCE=No Windows servicing operation was performed.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=YES
echo.
echo ================================================================================
echo STATUS            : DOWNLOAD INTERRUPTED
echo WINDOWS SERVICING : NOT STARTED
echo SCREENSHOT NEEDED : YES
echo WHAT TO DO        : Send ChatGPT a photo of THIS screen. Do not remove partial files.
echo ================================================================================
exit /b 40

:SIZEFAIL
>"%RESULT%" echo STATUS=FAIL
>>"%RESULT%" echo MESSAGE=Downloaded package size did not match the Microsoft catalog size.
>>"%RESULT%" echo EVIDENCE=Windows servicing was not started.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=YES
echo.
echo ================================================================================
echo STATUS            : INTEGRITY CHECK FAILED
echo WINDOWS SERVICING : NOT STARTED
echo SCREENSHOT NEEDED : YES
echo WHAT TO DO        : Send ChatGPT a photo of THIS screen.
echo ================================================================================
exit /b 90

:HASHFAIL
>"%RESULT%" echo STATUS=FAIL
>>"%RESULT%" echo MESSAGE=Downloaded package hash did not match the Microsoft package filename.
>>"%RESULT%" echo EVIDENCE=Windows servicing was not started.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=YES
echo.
echo ================================================================================
echo STATUS            : INTEGRITY CHECK FAILED
echo WINDOWS SERVICING : NOT STARTED
echo SCREENSHOT NEEDED : YES
echo WHAT TO DO        : Send ChatGPT a photo of THIS screen.
echo ================================================================================
exit /b 90
