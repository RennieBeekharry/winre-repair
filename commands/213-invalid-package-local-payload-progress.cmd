@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=READ_ONLY
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Identify the invalid servicing package context and check for a local repair payload.
rem WR_ACTION=FIND_INVALID_PACKAGE_AND_LOCAL_PAYLOAD
rem WR_TARGET=Offline CBS log and Windows Update cache on C: only.
rem WR_CONSEQUENCE=Reads servicing logs and cached update file metadata only; makes no Windows changes.
rem WR_ROLLBACK=Not applicable.

set "WORK=C:\WinRERepair"
set "DETAILS=%WORK%\RUN_DETAILS.txt"
set "RESULT=%WORK%\COMMAND_RESULT.env"
set "CTX=%WORK%\cbs-invalid-context.txt"
set "ERR=%WORK%\cbs-invalid-errors.txt"
if not exist "%WORK%" md "%WORK%" >nul 2>&1

cls
echo ================================================================================
echo RescueMeAI - RECOVERY PROGRESS
echo ================================================================================
echo STATUS            : RUNNING
echo CURRENT DIAGNOSIS : Windows servicing store is corrupt; exact LCU rollback failed.
echo CURRENT TASK      : Finding the invalid package and any local repair payload.
echo SAFETY            : READ-ONLY - no Windows changes are being made.
echo SCREENSHOT NEEDED : NO - wait for the final status below.
echo ================================================================================
echo.

>"%DETAILS%" echo RESCUEMEAI INVALID PACKAGE / LOCAL PAYLOAD DIAGNOSTIC

echo [1/3] Reading CBS context around the latest invalid-package event...
findstr /c:"2026-08-24 15:43:45" "C:\Windows\Logs\CBS\CBS.log" >"%CTX%" 2>nul
set "COUNT=0"
for /f %%N in ('find /v /c "" ^< "%CTX%"') do set "COUNT=%%N"
set /a SKIP=COUNT-10
if !SKIP! LSS 0 set "SKIP=0"
>>"%DETAILS%" echo.
>>"%DETAILS%" echo --- CBS CONTEXT 2026-08-24 15:43:45 ---
if !COUNT! GTR 0 (
  if !SKIP! GTR 0 (more +!SKIP! "%CTX%" >>"%DETAILS%") else (type "%CTX%" >>"%DETAILS%")
) else (
  >>"%DETAILS%" echo NONE
)

echo [2/3] Capturing the newest invalid-package error lines...
findstr /i /c:"0x800f0805" /c:"CBS_E_INVALID_PACKAGE" "C:\Windows\Logs\CBS\CBS.log" >"%ERR%" 2>nul
set "ECOUNT=0"
for /f %%N in ('find /v /c "" ^< "%ERR%"') do set "ECOUNT=%%N"
set /a ESKIP=ECOUNT-6
if !ESKIP! LSS 0 set "ESKIP=0"
>>"%DETAILS%" echo.
>>"%DETAILS%" echo --- LAST INVALID-PACKAGE ERRORS ---
if !ECOUNT! GTR 0 (
  if !ESKIP! GTR 0 (more +!ESKIP! "%ERR%" >>"%DETAILS%") else (type "%ERR%" >>"%DETAILS%")
) else (
  >>"%DETAILS%" echo NONE
)

echo [3/3] Checking Windows Update cache for large repair-payload candidates...
>>"%DETAILS%" echo.
>>"%DETAILS%" echo --- LOCAL CACHE CANDIDATES OVER 100 MB ---
set "FOUND=0"
if exist "C:\Windows\SoftwareDistribution\Download" (
  for /r "C:\Windows\SoftwareDistribution\Download" %%F in (*.cab *.psf *.msu) do (
    if %%~zF GEQ 100000000 if !FOUND! LSS 6 (
      >>"%DETAILS%" echo cache_candidate=%%~zF^|%%F
      set /a FOUND+=1
    )
  )
)
if !FOUND! EQU 0 >>"%DETAILS%" echo NONE

>"%RESULT%" echo STATUS=PASS
>>"%RESULT%" echo MESSAGE=Invalid-package context and local repair-payload candidates collected.
>>"%RESULT%" echo EVIDENCE=Bounded CBS context plus up to six large local update-cache candidates attached.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=NO
>>"%RESULT%" echo NEXT_STEP=RescueMeAI will decide whether local payload repair is possible before downloading anything large.

echo.
echo ================================================================================
echo STATUS            : COMPLETE
echo RESULT            : Invalid-package and local-payload check finished.
echo WINDOWS CHANGES   : NONE
echo NEXT STEP         : RescueMeAI is checking whether the repair can use local files.
echo SCREENSHOT NEEDED : NO
echo WHAT TO DO        : Leave this window open and keep the PC connected to power.
echo ================================================================================
exit /b 0
