@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=READ_ONLY
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Collect bounded evidence explaining DISM error 0x800f0915 and servicing state.
rem WR_ACTION=COLLECT_DISM_0915_BOUNDED_EVIDENCE
rem WR_TARGET=Offline Windows installation on C: only.
rem WR_CONSEQUENCE=Reads DISM/CBS logs and package state only; makes no Windows changes.
rem WR_ROLLBACK=Not applicable; read-only collection only.

set "WORK=C:\WinRERepair"
set "DETAILS=%WORK%\RUN_DETAILS.txt"
set "RESULT=%WORK%\COMMAND_RESULT.env"
set "REL=%WORK%\dism-0915-relevant.txt"
set "PKG=%WORK%\dism-pending-packages.txt"

cls
echo ================================================================
echo RescueMeAI - Diagnostic Progress
echo ================================================================
echo Current task : Narrowing down DISM error 0x800f0915
echo Safety       : READ-ONLY - no Windows changes are being made
echo ================================================================
echo.

> "%DETAILS%" echo RESCUEMEAI DISM 0x800F0915 BOUNDED EVIDENCE

echo [1/4] Reading the failed RestoreHealth log...
> "%REL%" (
  findstr /i /c:"0x800f0915" /c:"source files" /c:"repair source" /c:"failed" /c:"error" "%WORK%\dism-restorehealth.txt" 2^>nul
)
for /f %%N in ('find /v /c "" ^< "%REL%"') do set "COUNT=%%N"
set /a SKIP=COUNT-24
if !SKIP! LSS 0 set "SKIP=0"
>>"%DETAILS%" echo.
>>"%DETAILS%" echo --- RESTOREHEALTH RELEVANT LINES ---
if !SKIP! GTR 0 (
  more +!SKIP! "%REL%" >>"%DETAILS%"
) else (
  type "%REL%" >>"%DETAILS%"
)

echo [2/4] Checking target and recovery DISM versions...
>>"%DETAILS%" echo.
>>"%DETAILS%" echo --- DISM VERSION SIGNALS ---
dism /english /image:C:\ /Get-CurrentEdition >>"%DETAILS%" 2>&1
>>"%DETAILS%" echo recovery_dism_version:
dism /? 2>&1 | findstr /i /c:"Version:" >>"%DETAILS%"

echo [3/4] Checking pending package state...
dism /english /image:C:\ /Get-Packages /Format:Table >"%PKG%" 2>&1
>>"%DETAILS%" echo.
>>"%DETAILS%" echo --- PENDING / STAGED PACKAGE ROWS ---
findstr /i /c:"Install Pending" /c:"Uninstall Pending" /c:"Staged" "%PKG%" >>"%DETAILS%" 2>&1

echo [4/4] Checking CBS/DISM logs for the same error...
>>"%DETAILS%" echo.
>>"%DETAILS%" echo --- DISM LOG 0x800F0915 ---
findstr /i /c:"0x800f0915" /c:"CBS_E" "C:\Windows\Logs\DISM\dism.log" >>"%DETAILS%" 2>&1
>>"%DETAILS%" echo.
>>"%DETAILS%" echo --- CBS LOG 0x800F0915 ---
findstr /i /c:"0x800f0915" /c:"CBS_E" "C:\Windows\Logs\CBS\CBS.log" >>"%DETAILS%" 2>&1

> "%RESULT%" echo STATUS=PASS
>>"%RESULT%" echo MESSAGE=Bounded DISM 0x800f0915 evidence collected.
>>"%RESULT%" echo EVIDENCE=Relevant RestoreHealth lines, DISM version signals, pending package rows, and matching CBS/DISM log lines attached.

echo.
echo [PASS] Focused diagnostic complete.
echo Sending the bounded result through the secure GitHub channel...
echo RescueMeAI will remain online for the next reviewed step.
echo ================================================================
exit /b 0
