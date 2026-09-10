@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=READ_ONLY
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Check whether the servicing failure is caused by missing or unusable repair-source content.
rem WR_ACTION=CHECK_REPAIR_SOURCE_SIGNALS
rem WR_TARGET=Offline DISM and CBS servicing logs on C: only.
rem WR_CONSEQUENCE=Reads servicing logs only; makes no Windows changes.
rem WR_ROLLBACK=Not applicable.

set "WORK=C:\WinRERepair"
set "DETAILS=%WORK%\RUN_DETAILS.txt"
set "RESULT=%WORK%\COMMAND_RESULT.env"
set "DLOG=%WORK%\dism-restorehealth.txt"
set "CBS=C:\Windows\Logs\CBS\CBS.log"
set "DISMLOG=C:\Windows\Logs\DISM\dism.log"
set "LASTD=NONE"
set "LASTC=NONE"
set "DADD=NO"
set "D7010=NO"
set "D0915=NO"
set "CADD=NO"
set "C7010=NO"
set "CMISS=NO"
if not exist "%WORK%" md "%WORK%" >nul 2>&1

cls
echo ================================================================================
echo RescueMeAI - RECOVERY PROGRESS
echo ================================================================================
echo STATUS            : RUNNING
echo CURRENT DIAGNOSIS : Windows servicing is damaged; RestoreHealth and direct
echo                     cumulative-update rollback both failed.
echo CURRENT TASK      : Checking whether Windows is missing a valid repair source.
echo SAFETY            : READ-ONLY - no Windows changes are being made.
echo SCREENSHOT NEEDED : NO - wait for the final status below.
echo ================================================================================
echo.

echo [1/4] Checking the failed RestoreHealth log for source-resolution errors...
if exist "%DLOG%" (
  findstr /i /c:"AddSource" "%DLOG%" >nul 2>&1 && set "DADD=YES"
  findstr /i /c:"0x8007010b" "%DLOG%" >nul 2>&1 && set "D7010=YES"
  findstr /i /c:"0x800f0915" "%DLOG%" >nul 2>&1 && set "D0915=YES"
  for /f "usebackq delims=" %%L in (`findstr /i /c:"AddSource" /c:"0x8007010b" /c:"0x800f0915" /c:"repair content" /c:"source files" "%DLOG%" 2^>nul`) do set "LASTD=%%L"
)

echo [2/4] Checking CBS for missing repair-content signals...
if exist "%CBS%" (
  findstr /i /c:"AddSource" "%CBS%" >nul 2>&1 && set "CADD=YES"
  findstr /i /c:"0x8007010b" "%CBS%" >nul 2>&1 && set "C7010=YES"
  findstr /i /c:"CBS_E_REPAIR_CONTENT_MISSING" "%CBS%" >nul 2>&1 && set "CMISS=YES"
  for /f "usebackq delims=" %%L in (`findstr /i /c:"AddSource" /c:"0x8007010b" /c:"CBS_E_REPAIR_CONTENT_MISSING" /c:"0x800f0915" "%CBS%" 2^>nul`) do set "LASTC=%%L"
)

echo [3/4] Checking the offline DISM log for matching source failures...
set "OFF0915=NO"
if exist "%DISMLOG%" findstr /i /c:"0x800f0915" "%DISMLOG%" >nul 2>&1 && set "OFF0915=YES"

echo [4/4] Building a small repair-source decision report...
>"%DETAILS%" echo RESCUEMEAI REPAIR-SOURCE SIGNAL CHECK
>>"%DETAILS%" echo restore_addsource=!DADD!
>>"%DETAILS%" echo restore_0x8007010b=!D7010!
>>"%DETAILS%" echo restore_0x800f0915=!D0915!
>>"%DETAILS%" echo cbs_addsource=!CADD!
>>"%DETAILS%" echo cbs_0x8007010b=!C7010!
>>"%DETAILS%" echo cbs_repair_content_missing=!CMISS!
>>"%DETAILS%" echo offline_dism_0x800f0915=!OFF0915!
>>"%DETAILS%" echo last_restore_signal=!LASTD!
>>"%DETAILS%" echo last_cbs_signal=!LASTC!

>"%RESULT%" echo STATUS=PASS
>>"%RESULT%" echo MESSAGE=Repair-source signal diagnostic completed.
>>"%RESULT%" echo EVIDENCE=Bounded source-resolution indicators and last matching servicing lines attached.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=NO
>>"%RESULT%" echo NEXT_STEP=RescueMeAI will decide whether a matching Microsoft repair source is required.

echo.
echo ================================================================================
echo STATUS            : COMPLETE
echo RESULT            : Repair-source diagnostic finished.
echo WINDOWS CHANGES   : NONE
echo NEXT STEP         : RescueMeAI is reviewing whether matching Microsoft repair
echo                     content is required before another servicing operation.
echo SCREENSHOT NEEDED : NO
echo WHAT TO DO        : Leave this window open and keep the PC connected to power.
echo ================================================================================
exit /b 0
