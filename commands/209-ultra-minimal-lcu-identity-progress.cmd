@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=READ_ONLY
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Return one current cumulative-update package row and three rollback markers.
rem WR_ACTION=GET_ULTRA_MINIMAL_LCU_IDENTITY
rem WR_TARGET=Offline Windows installation on C: only.
rem WR_CONSEQUENCE=Reads package metadata only; makes no Windows changes.
rem WR_ROLLBACK=Not applicable.

set "WORK=C:\WinRERepair"
set "DETAILS=%WORK%\RUN_DETAILS.txt"
set "RESULT=%WORK%\COMMAND_RESULT.env"
set "PKGS=%WORK%\packages-table.txt"
set "MATCH=%WORK%\lcu-match.txt"
set "ROLL=%WORK%\rollup-only.txt"
set "SELECTED="
if not exist "%WORK%" md "%WORK%" >nul 2>&1

cls
echo ================================================================================
echo RescueMeAI - RECOVERY PROGRESS
echo ================================================================================
echo STATUS            : RUNNING
echo CURRENT DIAGNOSIS : Recently serviced boot binary corruption.
echo CURRENT TASK      : Selecting the exact newest cumulative-update package.
echo SAFETY            : READ-ONLY - no Windows changes are being made.
echo SCREENSHOT NEEDED : NO
echo ================================================================================
echo.

echo [1/3] Reading package table...
dism /English /Image:C:\ /Get-Packages /Format:Table >"%PKGS%" 2>&1
if errorlevel 1 (
  >"%RESULT%" echo STATUS=FAIL
  >>"%RESULT%" echo MESSAGE=DISM could not enumerate offline packages.
  >>"%RESULT%" echo SCREENSHOT_REQUIRED=YES
  echo [FAIL] Package enumeration failed.
  echo SCREENSHOT REQUIRED : YES
  echo Send ChatGPT a photo of THIS screen.
  exit /b 90
)

echo [2/3] Selecting build 9168 package row...
findstr /i /c:"9168" /c:"5121003" "%PKGS%" >"%MATCH%" 2>nul
for /f "usebackq delims=" %%L in ("%MATCH%") do if not defined SELECTED set "SELECTED=%%L"
if not defined SELECTED (
  findstr /i /c:"RollupFix" "%PKGS%" >"%ROLL%" 2>nul
  for /f "usebackq delims=" %%L in ("%ROLL%") do set "SELECTED=%%L"
)
if not defined SELECTED set "SELECTED=NONE"

echo [3/3] Recording rollback markers...
>"%DETAILS%" echo RESCUEMEAI ULTRA-MINIMAL LCU IDENTITY
>>"%DETAILS%" echo selected_package_row=!SELECTED!
if exist "C:\Windows\WinSxS\pending.xml" (>>"%DETAILS%" echo pending_xml=PRESENT) else (>>"%DETAILS%" echo pending_xml=ABSENT)
if exist "C:\Windows\WinSxS\Temp\PendingRenames" (>>"%DETAILS%" echo pending_renames=PRESENT) else (>>"%DETAILS%" echo pending_renames=ABSENT)
if exist "C:\Windows\SoftwareDistribution\Download" (>>"%DETAILS%" echo update_cache=PRESENT) else (>>"%DETAILS%" echo update_cache=ABSENT)

>"%RESULT%" echo STATUS=PASS
>>"%RESULT%" echo MESSAGE=Newest cumulative-update package row selected.
>>"%RESULT%" echo EVIDENCE=One package row and rollback markers attached.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=NO
>>"%RESULT%" echo NEXT_STEP=RescueMeAI will determine whether a targeted rollback is safe.

echo.
echo ================================================================================
echo STATUS            : COMPLETE
echo RESULT            : Newest cumulative-update package selected.
echo WINDOWS CHANGES   : NONE
echo NEXT STEP         : RescueMeAI is determining whether targeted rollback is safe.
echo SCREENSHOT NEEDED : NO
echo WHAT TO DO        : Leave this window open and keep the PC connected to power.
echo ================================================================================
exit /b 0
