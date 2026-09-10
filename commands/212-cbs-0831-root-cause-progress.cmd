@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=READ_ONLY
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Extract the exact CBS/DISM reason the RollupFix rollback failed with 0x800f0831.
rem WR_ACTION=DIAGNOSE_CBS_STORE_CORRUPTION
rem WR_TARGET=Offline Windows servicing logs on C: only.
rem WR_CONSEQUENCE=Reads servicing logs only; makes no Windows changes.
rem WR_ROLLBACK=Not applicable.

set "WORK=C:\WinRERepair"
set "DETAILS=%WORK%\RUN_DETAILS.txt"
set "RESULT=%WORK%\COMMAND_RESULT.env"
set "RMATCH=%WORK%\remove-0831-lines.txt"
set "CMATCH=%WORK%\cbs-0831-lines.txt"
if not exist "%WORK%" md "%WORK%" >nul 2>&1

cls
echo ================================================================================
echo RescueMeAI - RECOVERY PROGRESS
echo ================================================================================
echo STATUS            : RUNNING
echo CURRENT DIAGNOSIS : Targeted LCU rollback failed with 0x800f0831.
echo CURRENT TASK      : Finding the exact corrupt or missing servicing dependency.
echo SAFETY            : READ-ONLY - no Windows changes are being made.
echo SCREENSHOT NEEDED : NO - wait for the final status below.
echo ================================================================================
echo.

>"%DETAILS%" echo RESCUEMEAI CBS 0x800F0831 ROOT-CAUSE DIAGNOSTIC

echo [1/3] Reading the failed package-removal DISM log...
findstr /i /c:"0x800f0831" /c:"CBS_E_STORE_CORRUPTION" /c:"failed" /c:"corrupt" /c:"Package_for_" "%WORK%\remove-rollupfix-9168.log" >"%RMATCH%" 2>nul
set "RCOUNT=0"
for /f %%N in ('find /v /c "" ^< "%RMATCH%"') do set "RCOUNT=%%N"
set /a RSKIP=RCOUNT-8
if !RSKIP! LSS 0 set "RSKIP=0"
>>"%DETAILS%" echo.
>>"%DETAILS%" echo --- REMOVE LOG LAST MATCHES ---
if !RCOUNT! GTR 0 (
  if !RSKIP! GTR 0 (more +!RSKIP! "%RMATCH%" >>"%DETAILS%") else (type "%RMATCH%" >>"%DETAILS%")
) else (
  >>"%DETAILS%" echo NONE
)

echo [2/3] Reading CBS for the same servicing failure...
findstr /i /c:"0x800f0831" /c:"CBS_E_STORE_CORRUPTION" /c:"Failed to" "C:\Windows\Logs\CBS\CBS.log" >"%CMATCH%" 2>nul
set "CCOUNT=0"
for /f %%N in ('find /v /c "" ^< "%CMATCH%"') do set "CCOUNT=%%N"
set /a CSKIP=CCOUNT-8
if !CSKIP! LSS 0 set "CSKIP=0"
>>"%DETAILS%" echo.
>>"%DETAILS%" echo --- CBS LOG LAST MATCHES ---
if !CCOUNT! GTR 0 (
  if !CSKIP! GTR 0 (more +!CSKIP! "%CMATCH%" >>"%DETAILS%") else (type "%CMATCH%" >>"%DETAILS%")
) else (
  >>"%DETAILS%" echo NONE
)

echo [3/3] Recording servicing state...
>>"%DETAILS%" echo.
>>"%DETAILS%" echo package=Package_for_RollupFix~31bf3856ad364e35~amd64~~26100.9168.1.19
>>"%DETAILS%" echo remove_hresult=0x800f0831
if exist "C:\Windows\WinSxS\pending.xml" (>>"%DETAILS%" echo pending_xml=PRESENT) else (>>"%DETAILS%" echo pending_xml=ABSENT)
if exist "C:\Windows\WinSxS\Temp\PendingRenames" (>>"%DETAILS%" echo pending_renames=PRESENT) else (>>"%DETAILS%" echo pending_renames=ABSENT)

>"%RESULT%" echo STATUS=PASS
>>"%RESULT%" echo MESSAGE=CBS 0x800f0831 root-cause evidence collected.
>>"%RESULT%" echo EVIDENCE=Last relevant DISM/CBS failure lines and servicing state attached.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=NO
>>"%RESULT%" echo NEXT_STEP=RescueMeAI will select the matching repair payload or other least-destructive servicing path.

echo.
echo ================================================================================
echo STATUS            : COMPLETE
echo RESULT            : Servicing failure evidence collected.
echo WINDOWS CHANGES   : NONE
echo NEXT STEP         : RescueMeAI is selecting the matching repair source.
echo SCREENSHOT NEEDED : NO
echo WHAT TO DO        : Leave this window open and keep the PC connected to power.
echo ================================================================================
exit /b 0
