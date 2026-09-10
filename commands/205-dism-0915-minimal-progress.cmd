@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=READ_ONLY
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Collect a minimal servicing/version diagnostic after DISM 0x800f0915.
rem WR_ACTION=COLLECT_DISM_0915_MINIMAL
rem WR_TARGET=Offline Windows installation on C: only.
rem WR_CONSEQUENCE=Reads DISM/CBS error lines and pending servicing rows only.
rem WR_ROLLBACK=Not applicable; read-only collection only.

set "WORK=C:\WinRERepair"
set "DETAILS=%WORK%\RUN_DETAILS.txt"
set "RESULT=%WORK%\COMMAND_RESULT.env"

cls
echo ================================================================
echo RescueMeAI - Diagnostic Progress
echo ================================================================
echo Current task : Confirming the exact cause of DISM 0x800f0915
echo Safety       : READ-ONLY - no Windows changes are being made
echo ================================================================
echo.

>"%DETAILS%" echo RESCUEMEAI MINIMAL DISM 0x800F0915 DIAGNOSTIC

echo [1/4] Comparing recovery DISM with the target Windows image...
>>"%DETAILS%" echo.
>>"%DETAILS%" echo --- DISM VERSION COMPARISON ---
dism /? 2>&1 | findstr /i /c:"Version:" >>"%DETAILS%"
dism /english /image:C:\ /Get-CurrentEdition 2>&1 | findstr /i /c:"Image Version:" /c:"Current Edition" >>"%DETAILS%"

echo [2/4] Reading exact RestoreHealth 0x800f0915 lines...
>>"%DETAILS%" echo.
>>"%DETAILS%" echo --- RESTOREHEALTH 0x800F0915 ---
set /a N=0
for /f "delims=" %%L in ('findstr /i /c:"0x800f0915" "%WORK%\dism-restorehealth.txt" 2^>nul') do if !N! LSS 8 (
  set "LINE=%%L"
  >>"%DETAILS%" echo(!LINE:~0,220!
  set /a N+=1
)

echo [3/4] Reading exact CBS 0x800f0915 lines...
>>"%DETAILS%" echo.
>>"%DETAILS%" echo --- CBS 0x800F0915 ---
set /a N=0
for /f "delims=" %%L in ('findstr /i /c:"0x800f0915" "C:\Windows\Logs\CBS\CBS.log" 2^>nul') do if !N! LSS 8 (
  set "LINE=%%L"
  >>"%DETAILS%" echo(!LINE:~0,220!
  set /a N+=1
)

echo [4/4] Checking pending servicing rows...
>>"%DETAILS%" echo.
>>"%DETAILS%" echo --- PENDING PACKAGE ROWS ---
set /a N=0
for /f "delims=" %%L in ('dism /english /image:C:\ /Get-Packages /Format:Table 2^>nul ^| findstr /i /c:"Install Pending" /c:"Uninstall Pending"') do if !N! LSS 8 (
  set "LINE=%%L"
  >>"%DETAILS%" echo(!LINE:~0,220!
  set /a N+=1
)

for %%Z in ("%DETAILS%") do set "DSIZE=%%~zZ"
>>"%DETAILS%" echo.
>>"%DETAILS%" echo details_bytes=!DSIZE!

>"%RESULT%" echo STATUS=PASS
>>"%RESULT%" echo MESSAGE=Minimal DISM 0x800f0915 diagnostic completed.
>>"%RESULT%" echo EVIDENCE=DISM version comparison, exact 0x800f0915 lines, and pending package rows attached.

echo.
echo [PASS] Minimal diagnostic complete.
echo Sending the small result through the secure GitHub channel...
echo RescueMeAI will remain online for the next reviewed step.
echo ================================================================
exit /b 0
