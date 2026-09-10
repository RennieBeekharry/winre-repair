@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=READ_ONLY
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Return the exact current RollupFix package identity row.
rem WR_ACTION=GET_EXACT_ROLLUP_PACKAGE_ROW
rem WR_TARGET=Offline Windows installation on C: only.
rem WR_CONSEQUENCE=Reads servicing package metadata only; makes no Windows changes.
rem WR_ROLLBACK=Not applicable.

set "WORK=C:\WinRERepair"
set "DETAILS=%WORK%\RUN_DETAILS.txt"
set "RESULT=%WORK%\COMMAND_RESULT.env"
set "PKGS=%WORK%\packages-table.txt"
set "MATCH=%WORK%\exact-rollup.txt"
set "ROLL=%WORK%\rollup-only.txt"
set "SELECTED="
if not exist "%WORK%" md "%WORK%" >nul 2>&1

cls
echo ================================================================================
echo RescueMeAI - RECOVERY PROGRESS
echo ================================================================================
echo STATUS            : RUNNING
echo CURRENT DIAGNOSIS : Recently serviced boot binary corruption.
echo CURRENT TASK      : Confirming the exact current RollupFix package identity.
echo SAFETY            : READ-ONLY - no Windows changes are being made.
echo SCREENSHOT NEEDED : NO
echo ================================================================================
echo.

echo [1/3] Reading servicing package table...
dism /English /Image:C:\ /Get-Packages /Format:Table >"%PKGS%" 2>&1
if errorlevel 1 (
  >"%RESULT%" echo STATUS=FAIL
  >>"%RESULT%" echo MESSAGE=Package enumeration failed.
  >>"%RESULT%" echo SCREENSHOT_REQUIRED=YES
  echo [FAIL] Package enumeration failed.
  echo SCREENSHOT REQUIRED : YES
  echo Send ChatGPT a photo of THIS screen.
  exit /b 90
)

echo [2/3] Filtering for the current build package...
findstr /i /c:"9168" "%PKGS%" | findstr /c:"~" >"%MATCH%" 2>nul
for /f "usebackq delims=" %%L in ("%MATCH%") do set "SELECTED=%%L"
if not defined SELECTED (
  findstr /i /c:"RollupFix" "%PKGS%" >"%ROLL%" 2>nul
  for /f "usebackq delims=" %%L in ("%ROLL%") do set "SELECTED=%%L"
)
if not defined SELECTED set "SELECTED=NONE"

echo [3/3] Returning one package row...
>"%DETAILS%" echo exact_rollup_package_row=!SELECTED!
if exist "C:\Windows\WinSxS\pending.xml" (>>"%DETAILS%" echo pending_xml=PRESENT) else (>>"%DETAILS%" echo pending_xml=ABSENT)
if exist "C:\Windows\WinSxS\Temp\PendingRenames" (>>"%DETAILS%" echo pending_renames=PRESENT) else (>>"%DETAILS%" echo pending_renames=ABSENT)

>"%RESULT%" echo STATUS=PASS
>>"%RESULT%" echo MESSAGE=Exact RollupFix package row collected.
>>"%RESULT%" echo EVIDENCE=One current package row plus pending markers attached.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=NO
>>"%RESULT%" echo NEXT_STEP=RescueMeAI will decide whether direct cumulative-update rollback is appropriate.

echo.
echo ================================================================================
echo STATUS            : COMPLETE
echo RESULT            : Exact RollupFix package identity collected.
echo WINDOWS CHANGES   : NONE
echo NEXT STEP         : RescueMeAI is reviewing direct update rollback safety.
echo SCREENSHOT NEEDED : NO
echo WHAT TO DO        : Leave this window open and keep the PC connected to power.
echo ================================================================================
exit /b 0
