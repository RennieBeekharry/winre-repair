@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=READ_ONLY
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Correct the KB5121003 integrity check by validating each downloaded MSU separately against the Microsoft catalog package split.
rem WR_ACTION=VALIDATE_KB5121003_PAYLOAD_SPLIT
rem WR_TARGET=C:\RescueMeAI\packages\KB5121003 downloaded Microsoft MSU files only.
rem WR_CONSEQUENCE=Reads file sizes and SHA-1 hashes only. No Windows servicing, deletion, reset, reboot, or package installation is performed.
rem WR_ROLLBACK=Not applicable; this command is read-only.

set "PKGDIR=C:\RescueMeAI\packages\KB5121003"
set "WORK=C:\WinRERepair"
set "DETAILS=%WORK%\RUN_DETAILS.txt"
set "RESULT=%WORK%\COMMAND_RESULT.env"
set "P1=%PKGDIR%\windows11.0-kb5043080-x64_953449672073f8fb99badb4cc6d5d7849b9c83e8.msu"
set "P2=%PKGDIR%\windows11.0-kb5121003-x64_dc58f03fef04b4c611e0db0ab3fadfb301194113.msu"
set "E1=533761740"
set "E2=5103847049"
set "ETOTAL=5637608789"
set "EH1=953449672073f8fb99badb4cc6d5d7849b9c83e8"
set "EH2=dc58f03fef04b4c611e0db0ab3fadfb301194113"
if not exist "%WORK%" md "%WORK%" >nul 2>&1

cls
echo ================================================================================
echo RescueMeAI - CORRECTED MICROSOFT PAYLOAD VALIDATION
echo ================================================================================
echo STATUS            : RUNNING
echo CURRENT DIAGNOSIS : The prior size check treated the Microsoft catalog's combined
echo                     checkpoint+LCU size as if it were the LCU file alone.
echo CURRENT TASK      : Validating both MSU files separately by exact size and SHA-1.
echo SAFETY            : READ-ONLY - no Windows changes are being made.
echo WINDOWS SERVICING : NOT STARTED
echo PERSONAL FILES    : NOT TOUCHED
echo SCREENSHOT NEEDED : NO - wait for the final status below.
echo ================================================================================
echo.

set "S1=MISSING"
set "S2=MISSING"
if exist "%P1%" for %%F in ("%P1%") do set "S1=%%~zF"
if exist "%P2%" for %%F in ("%P2%") do set "S2=%%~zF"

echo [1/4] Checking checkpoint package size...
set "S1OK=NO"
if "!S1!"=="%E1%" set "S1OK=YES"

echo [2/4] Checking checkpoint package SHA-1...
set "H1=MISSING"
if exist "%P1%" (
  set "H1="
  for /f "skip=1 delims=" %%H in ('certutil -hashfile "%P1%" SHA1 2^>nul') do if not defined H1 set "H1=%%H"
  set "H1=!H1: =!"
)
set "H1OK=NO"
if /i "!H1!"=="%EH1%" set "H1OK=YES"

echo [3/4] Checking cumulative update size...
set "S2OK=NO"
if "!S2!"=="%E2%" set "S2OK=YES"

echo [4/4] Checking cumulative update SHA-1...
set "H2=MISSING"
if exist "%P2%" (
  set "H2="
  for /f "skip=1 delims=" %%H in ('certutil -hashfile "%P2%" SHA1 2^>nul') do if not defined H2 set "H2=%%H"
  set "H2=!H2: =!"
)
set "H2OK=NO"
if /i "!H2!"=="%EH2%" set "H2OK=YES"

set /a "SUMLO=0" >nul 2>&1
> "%DETAILS%" echo RESCUEMEAI CORRECTED MICROSOFT PAYLOAD VALIDATION
>>"%DETAILS%" echo kb5043080_expected_bytes=%E1%
>>"%DETAILS%" echo kb5043080_actual_bytes=!S1!
>>"%DETAILS%" echo kb5043080_size_status=!S1OK!
>>"%DETAILS%" echo kb5043080_expected_sha1=%EH1%
>>"%DETAILS%" echo kb5043080_actual_sha1=!H1!
>>"%DETAILS%" echo kb5043080_hash_status=!H1OK!
>>"%DETAILS%" echo kb5121003_expected_bytes=%E2%
>>"%DETAILS%" echo kb5121003_actual_bytes=!S2!
>>"%DETAILS%" echo kb5121003_size_status=!S2OK!
>>"%DETAILS%" echo kb5121003_expected_sha1=%EH2%
>>"%DETAILS%" echo kb5121003_actual_sha1=!H2!
>>"%DETAILS%" echo kb5121003_hash_status=!H2OK!
>>"%DETAILS%" echo microsoft_catalog_combined_bytes=%ETOTAL%
>>"%DETAILS%" echo combined_size_math=%E1%+%E2%=%ETOTAL%
>>"%DETAILS%" echo windows_servicing_performed=NO

if /i "!S1OK!!H1OK!!S2OK!!H2OK!"=="YESYESYESYES" (
  >"%RESULT%" echo STATUS=PASS
  >>"%RESULT%" echo MESSAGE=Both official Microsoft repair packages passed corrected exact size and SHA-1 validation.
  >>"%RESULT%" echo EVIDENCE=Checkpoint and LCU were validated separately; their byte sizes sum to the Microsoft catalog combined size.
  >>"%RESULT%" echo SCREENSHOT_REQUIRED=NO
  >>"%RESULT%" echo NEXT_STEP=RescueMeAI will attempt the least invasive Windows system-file repair before applying update packages.
  echo.
  echo ================================================================================
  echo STATUS            : COMPLETE - PAYLOAD VERIFIED
  echo KB5043080         : SIZE MATCH / SHA-1 MATCH
  echo KB5121003         : SIZE MATCH / SHA-1 MATCH
  echo WINDOWS CHANGES   : NONE
  echo NEXT STEP         : RescueMeAI will try offline System File Checker first.
  echo SCREENSHOT NEEDED : NO
  echo WHAT TO DO        : Leave this window open and keep the PC connected to power.
  echo ================================================================================
  exit /b 0
)

>"%RESULT%" echo STATUS=FAIL
>>"%RESULT%" echo MESSAGE=One or more Microsoft repair-package integrity checks failed after corrected validation.
>>"%RESULT%" echo EVIDENCE=Exact sizes and actual SHA-1 values attached.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=YES
>>"%RESULT%" echo NEXT_STEP=Stop before Windows servicing and send ChatGPT a photo of this screen.
echo.
echo ================================================================================
echo STATUS            : INTEGRITY VALIDATION FAILED
echo KB5043080 SIZE    : !S1! / %E1% - !S1OK!
echo KB5043080 SHA-1   : !H1OK!
echo KB5121003 SIZE    : !S2! / %E2% - !S2OK!
echo KB5121003 SHA-1   : !H2OK!
echo WINDOWS CHANGES   : NONE
echo SCREENSHOT NEEDED : YES
echo WHAT TO DO        : Send ChatGPT a photo of THIS screen. Do not reboot.
echo ================================================================================
exit /b 90
