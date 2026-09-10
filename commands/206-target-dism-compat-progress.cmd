@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=READ_ONLY
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Verify whether the installed Windows DISM is new enough to service its own offline image.
rem WR_ACTION=VERIFY_TARGET_DISM_COMPATIBILITY
rem WR_TARGET=Offline Windows installation on C: only.
rem WR_CONSEQUENCE=Runs metadata-only DISM queries; makes no Windows changes.
rem WR_ROLLBACK=Not applicable; read-only verification only.

set "WORK=C:\WinRERepair"
set "DETAILS=%WORK%\RUN_DETAILS.txt"
set "RESULT=%WORK%\COMMAND_RESULT.env"
set "TDISM=C:\Windows\System32\dism.exe"

cls
echo ================================================================
echo RescueMeAI - Diagnostic Progress
echo ================================================================
echo Current task : Verifying the correct DISM engine for this Windows build
echo Safety       : READ-ONLY - no Windows changes are being made
echo ================================================================
echo.

> "%DETAILS%" echo RESCUEMEAI TARGET DISM COMPATIBILITY CHECK

echo [1/3] Checking the installed Windows DISM binary...
if exist "%TDISM%" (
  >>"%DETAILS%" echo target_dism_present=YES
) else (
  >>"%DETAILS%" echo target_dism_present=NO
  >"%RESULT%" echo STATUS=FAIL
  >>"%RESULT%" echo MESSAGE=Installed Windows DISM binary was not found.
  >>"%RESULT%" echo EVIDENCE=Target DISM path missing.
  echo [FAIL] Installed Windows DISM was not found.
  exit /b 90
)

echo [2/3] Reading installed DISM version...
>>"%DETAILS%" echo.
>>"%DETAILS%" echo --- TARGET DISM VERSION ---
"%TDISM%" /English /? 2>&1 | findstr /i /c:"Version:" >>"%DETAILS%"

echo [3/3] Testing a metadata-only offline image query...
>>"%DETAILS%" echo.
>>"%DETAILS%" echo --- TARGET DISM OFFLINE QUERY ---
"%TDISM%" /English /Image:C:\ /Get-CurrentEdition >>"%DETAILS%" 2>&1
set "DRC=!errorlevel!"
>>"%DETAILS%" echo target_dism_query_exit_code=!DRC!

if not "!DRC!"=="0" (
  >"%RESULT%" echo STATUS=WARNING
  >>"%RESULT%" echo MESSAGE=Installed Windows DISM exists but could not query the offline image successfully.
  >>"%RESULT%" echo EVIDENCE=Target DISM version and query exit code attached.
  echo.
  echo [WARNING] Installed DISM could not service-query the offline image.
  echo Sending the result through the secure GitHub channel...
  exit /b 40
)

>"%RESULT%" echo STATUS=PASS
>>"%RESULT%" echo MESSAGE=Installed Windows DISM can query the offline image successfully.
>>"%RESULT%" echo EVIDENCE=Target DISM version and metadata-only query result attached.

echo.
echo [PASS] Correct DISM compatibility check complete.
echo Sending the small result through the secure GitHub channel...
echo RescueMeAI will remain online for the next reviewed step.
echo ================================================================
exit /b 0
