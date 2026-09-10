@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=READ_ONLY
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Collect bounded evidence for DISM RestoreHealth error 0x800f0915.
rem WR_ACTION=DIAGNOSE_DISM_0X800F0915
rem WR_TARGET=Offline Windows installation on C: and RescueMeAI servicing logs only.
rem WR_CONSEQUENCE=Reads servicing logs, image metadata, and recent package filenames; makes no Windows changes.
rem WR_ROLLBACK=Not applicable; read-only collection only.

set "WORK=C:\WinRERepair"
set "DETAILS=%WORK%\RUN_DETAILS.txt"
set "RESULT=%WORK%\COMMAND_RESULT.env"
set "MATCHES=%WORK%\dism-0915-matches.txt"
if not exist "%WORK%" md "%WORK%" >nul 2>&1

>"%DETAILS%" echo RESCUEMEAI DISM 0x800f0915 SOURCE DIAGNOSTIC
>>"%DETAILS%" echo.
>>"%DETAILS%" echo --- IMAGE METADATA ---
dism /image:C:\ /get-currentedition >>"%DETAILS%" 2>&1

>>"%DETAILS%" echo.
>>"%DETAILS%" echo --- FAILED RESTOREHEALTH SIGNALS ---
if exist "%WORK%\dism-restorehealth.txt" (
  findstr /i /c:"0x800f0915" /c:"source" /c:"error" /c:"failed" /c:"repair" /c:"component store" "%WORK%\dism-restorehealth.txt" >"%MATCHES%" 2>&1
  set /a N=0
  for /f "usebackq delims=" %%L in ("%MATCHES%") do if !N! LSS 40 (
    >>"%DETAILS%" echo %%L
    set /a N+=1
  )
) else (
  >>"%DETAILS%" echo DISM RestoreHealth log not found
)

>>"%DETAILS%" echo.
>>"%DETAILS%" echo --- CBS ERROR SIGNALS ---
if exist "C:\Windows\Logs\CBS\CBS.log" (
  findstr /i /c:"0x800f0915" /c:"source files" /c:"failed to" /c:"corrupt" /c:"repair" "C:\Windows\Logs\CBS\CBS.log" >"%MATCHES%" 2>&1
  set /a N=0
  for /f "usebackq delims=" %%L in ("%MATCHES%") do if !N! LSS 45 (
    >>"%DETAILS%" echo %%L
    set /a N+=1
  )
) else (
  >>"%DETAILS%" echo CBS.log not found
)

>>"%DETAILS%" echo.
>>"%DETAILS%" echo --- RECENT ROLLUP PACKAGE FILES ---
set /a N=0
for /f "delims=" %%F in ('dir /b /o-d "C:\Windows\servicing\Packages\Package_for_RollupFix*.mum" 2^>nul') do if !N! LSS 12 (
  >>"%DETAILS%" echo %%F
  set /a N+=1
)

>"%RESULT%" echo STATUS=PASS
>>"%RESULT%" echo MESSAGE=DISM 0x800f0915 source diagnostic completed.
>>"%RESULT%" echo EVIDENCE=Bounded servicing and source-resolution evidence attached.
exit /b 0
