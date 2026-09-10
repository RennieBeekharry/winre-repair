@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=READ_ONLY
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Return only the exact installed LCU package identity and rollback markers.
rem WR_ACTION=GET_MINIMAL_LCU_IDENTITY
rem WR_TARGET=Offline Windows installation on C: only.
rem WR_CONSEQUENCE=Reads package metadata only; makes no Windows changes.
rem WR_ROLLBACK=Not applicable.

set "WORK=C:\WinRERepair"
set "DETAILS=%WORK%\RUN_DETAILS.txt"
set "RESULT=%WORK%\COMMAND_RESULT.env"
set "PKGS=%WORK%\packages-table.txt"
set "MATCH=%WORK%\lcu-match.txt"
set "ROLL=%WORK%\rollup-only.txt"
if not exist "%WORK%" md "%WORK%" >nul 2>&1

cls
echo ================================================================================
echo RescueMeAI - RECOVERY PROGRESS
echo ================================================================================
echo STATUS            : RUNNING
echo CURRENT DIAGNOSIS : A recently serviced boot binary is corrupt.
echo CURRENT TASK      : Identifying the exact installed cumulative-update package.
echo SAFETY            : READ-ONLY - no Windows changes are being made.
echo SCREENSHOT NEEDED : NO - wait for the final status below.
echo ================================================================================
echo.

>"%DETAILS%" echo RESCUEMEAI MINIMAL LCU IDENTITY

echo [1/4] Reading offline cumulative-update packages...
dism /English /Image:C:\ /Get-Packages /Format:Table >"%PKGS%" 2>&1
if errorlevel 1 (
  >"%RESULT%" echo STATUS=FAIL
  >>"%RESULT%" echo MESSAGE=DISM could not enumerate offline packages.
  >>"%RESULT%" echo SCREENSHOT_REQUIRED=YES
  echo [FAIL] DISM could not enumerate offline packages.
  echo SCREENSHOT REQUIRED : YES
  echo Send ChatGPT a photo of THIS screen.
  exit /b 90
)

echo [2/4] Matching the current build 26200.9168...
findstr /i /c:"9168" /c:"5121003" "%PKGS%" >"%MATCH%" 2>nul
for %%Z in ("%MATCH%") do set "MSIZE=%%~zZ"
>>"%DETAILS%" echo.
>>"%DETAILS%" echo --- BUILD-MATCHING PACKAGE ROWS ---
if defined MSIZE if !MSIZE! GTR 0 (
  type "%MATCH%" >>"%DETAILS%"
) else (
  >>"%DETAILS%" echo NONE
)

echo [3/4] Capturing only the newest RollupFix rows...
findstr /i /c:"RollupFix" "%PKGS%" >"%ROLL%" 2>nul
set "COUNT=0"
for /f %%N in ('find /v /c "" ^< "%ROLL%"') do set "COUNT=%%N"
set /a SKIP=COUNT-8
if !SKIP! LSS 0 set "SKIP=0"
>>"%DETAILS%" echo.
>>"%DETAILS%" echo --- LAST ROLLUPFIX ROWS ---
if !COUNT! GTR 0 (
  if !SKIP! GTR 0 (
    more +!SKIP! "%ROLL%" >>"%DETAILS%"
  ) else (
    type "%ROLL%" >>"%DETAILS%"
  )
) else (
  >>"%DETAILS%" echo NONE
)

echo [4/4] Checking rollback/pending markers...
>>"%DETAILS%" echo.
>>"%DETAILS%" echo --- ROLLBACK MARKERS ---
if exist "C:\Windows\WinSxS\pending.xml" (>>"%DETAILS%" echo pending_xml=PRESENT) else (>>"%DETAILS%" echo pending_xml=ABSENT)
if exist "C:\Windows\WinSxS\Temp\PendingRenames" (>>"%DETAILS%" echo pending_renames=PRESENT) else (>>"%DETAILS%" echo pending_renames=ABSENT)
if exist "C:\Windows\SoftwareDistribution\Download" (>>"%DETAILS%" echo update_cache_dir=PRESENT) else (>>"%DETAILS%" echo update_cache_dir=ABSENT)

>"%RESULT%" echo STATUS=PASS
>>"%RESULT%" echo MESSAGE=Exact cumulative-update package identity diagnostic completed.
>>"%RESULT%" echo EVIDENCE=Only build-matching and newest RollupFix rows plus rollback markers attached.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=NO
>>"%RESULT%" echo NEXT_STEP=RescueMeAI will choose the least-destructive repair path.

echo.
echo ================================================================================
echo STATUS            : COMPLETE
echo RESULT            : Exact cumulative-update identity collected.
echo WINDOWS CHANGES   : NONE
echo NEXT STEP         : RescueMeAI is selecting the least-destructive repair path.
echo SCREENSHOT NEEDED : NO
echo WHAT TO DO        : Leave this window open and keep the PC connected to power.
echo ================================================================================
exit /b 0
