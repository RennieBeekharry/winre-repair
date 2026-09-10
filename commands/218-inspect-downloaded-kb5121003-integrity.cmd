@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=READ_ONLY
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Inspect the downloaded Microsoft repair packages after the size mismatch without changing Windows or deleting files.
rem WR_ACTION=INSPECT_DOWNLOADED_KB5121003_INTEGRITY
rem WR_TARGET=C:\RescueMeAI\packages\KB5121003 downloaded package files only.
rem WR_CONSEQUENCE=Reads file sizes and SHA-1 hashes only; no Windows servicing, deletion, reset, reboot, or package installation is performed.
rem WR_ROLLBACK=Not applicable; this command is read-only.

set "PKGDIR=C:\RescueMeAI\packages\KB5121003"
set "WORK=C:\WinRERepair"
set "DETAILS=%WORK%\RUN_DETAILS.txt"
set "RESULT=%WORK%\COMMAND_RESULT.env"
set "P1=%PKGDIR%\windows11.0-kb5043080-x64_953449672073f8fb99badb4cc6d5d7849b9c83e8.msu"
set "P2=%PKGDIR%\windows11.0-kb5121003-x64_dc58f03fef04b4c611e0db0ab3fadfb301194113.msu"
set "E1=533761740"
set "E2=5637608789"
if not exist "%WORK%" md "%WORK%" >nul 2>&1

cls
echo ================================================================================
echo RescueMeAI - PACKAGE INTEGRITY DIAGNOSIS
echo ================================================================================
echo STATUS            : RUNNING
echo CURRENT DIAGNOSIS : Both Microsoft downloads reached 100%%, but KB5121003
echo                     failed the local size check before any Windows servicing.
echo CURRENT TASK      : Measuring the downloaded files and computing SHA-1 hashes.
echo SAFETY            : READ-ONLY - no Windows changes are being made.
echo WINDOWS SERVICING : NOT STARTED
echo PERSONAL FILES    : NOT TOUCHED
echo SCREENSHOT NEEDED : NO - wait for the final status below.
echo ================================================================================
echo.

>"%DETAILS%" echo RESCUEMEAI DOWNLOADED PACKAGE INTEGRITY INSPECTION

echo [1/4] Measuring checkpoint package KB5043080...
set "S1=MISSING"
if exist "%P1%" for %%F in ("%P1%") do set "S1=%%~zF"
>>"%DETAILS%" echo kb5043080_expected_bytes=%E1%
>>"%DETAILS%" echo kb5043080_actual_bytes=!S1!

echo [2/4] Computing KB5043080 SHA-1...
if exist "%P1%" (
  certutil -hashfile "%P1%" SHA1 >"%WORK%\inspect-kb5043080-sha1.txt" 2>&1
  findstr /i /v /c:"SHA1 hash" /c:"CertUtil" "%WORK%\inspect-kb5043080-sha1.txt" >>"%DETAILS%" 2>nul
  findstr /i /c:"953449672073f8fb99badb4cc6d5d7849b9c83e8" "%WORK%\inspect-kb5043080-sha1.txt" >nul 2>&1 && (set "H1=MATCH") || (set "H1=MISMATCH")
) else (
  set "H1=MISSING"
)
>>"%DETAILS%" echo kb5043080_hash_status=!H1!

echo [3/4] Measuring cumulative update KB5121003...
set "S2=MISSING"
if exist "%P2%" for %%F in ("%P2%") do set "S2=%%~zF"
>>"%DETAILS%" echo kb5121003_expected_bytes=%E2%
>>"%DETAILS%" echo kb5121003_actual_bytes=!S2!

echo [4/4] Computing KB5121003 SHA-1...
if exist "%P2%" (
  certutil -hashfile "%P2%" SHA1 >"%WORK%\inspect-kb5121003-sha1.txt" 2>&1
  findstr /i /v /c:"SHA1 hash" /c:"CertUtil" "%WORK%\inspect-kb5121003-sha1.txt" >>"%DETAILS%" 2>nul
  findstr /i /c:"dc58f03fef04b4c611e0db0ab3fadfb301194113" "%WORK%\inspect-kb5121003-sha1.txt" >nul 2>&1 && (set "H2=MATCH") || (set "H2=MISMATCH")
) else (
  set "H2=MISSING"
)
>>"%DETAILS%" echo kb5121003_hash_status=!H2!

set "S1OK=NO"
set "S2OK=NO"
if "!S1!"=="%E1%" set "S1OK=YES"
if "!S2!"=="%E2%" set "S2OK=YES"
>>"%DETAILS%" echo kb5043080_size_status=!S1OK!
>>"%DETAILS%" echo kb5121003_size_status=!S2OK!
>>"%DETAILS%" echo windows_servicing_performed=NO

>"%RESULT%" echo STATUS=PASS
>>"%RESULT%" echo MESSAGE=Downloaded-package integrity inspection completed without changing Windows.
>>"%RESULT%" echo EVIDENCE=Actual sizes and SHA-1 match status for both Microsoft packages attached.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=NO
>>"%RESULT%" echo NEXT_STEP=RescueMeAI will decide whether the KB5121003 file is valid, partial, or must be redownloaded.

echo.
echo ================================================================================
echo STATUS            : COMPLETE
echo KB5043080 SIZE     : !S1! bytes  ^(expected %E1%^) - !S1OK!
echo KB5043080 SHA-1    : !H1!
echo KB5121003 SIZE     : !S2! bytes  ^(expected %E2%^) - !S2OK!
echo KB5121003 SHA-1    : !H2!
echo WINDOWS CHANGES   : NONE
echo NEXT STEP         : RescueMeAI is reviewing these exact integrity results.
echo SCREENSHOT NEEDED : NO
echo WHAT TO DO        : Leave this window open and keep the PC connected to power.
echo ================================================================================
exit /b 0
