@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=REPAIR_WRITE
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Repair the offline Windows component store, then verify and repair protected system files.
rem WR_ACTION=REPAIR_SERVICED_BOOT_BINARIES
rem WR_TARGET=Offline Windows installation on C: only.
rem WR_CONSEQUENCE=DISM RestoreHealth and offline SFC may replace corrupted Windows system components; personal files are not targeted.
rem WR_ROLLBACK=System-file replacements are servicing operations; if they fail, RescueMeAI stops and preserves logs for review.

set "WORK=C:\WinRERepair"
set "SCRATCH=C:\RescueMeAI\scratch"
set "DLOG=%WORK%\dism-restorehealth.txt"
set "SLOG=%WORK%\sfc-offline.txt"
set "DETAILS=%WORK%\RUN_DETAILS.txt"
set "RESULT=%WORK%\COMMAND_RESULT.env"
if not exist "%WORK%" md "%WORK%" >nul 2>&1
if not exist "%SCRATCH%" md "%SCRATCH%" >nul 2>&1

>"%DETAILS%" echo RESCUEMEAI SERVICING REPAIR
>>"%DETAILS%" echo root_cause=Startup Repair reported a recently serviced boot binary is corrupt
>>"%DETAILS%" echo action=DISM RestoreHealth then offline SFC

dism /image:C:\ /cleanup-image /restorehealth /ScratchDir:"%SCRATCH%" >"%DLOG%" 2>&1
set "DRC=!errorlevel!"
>>"%DETAILS%" echo dism_exit_code=!DRC!
findstr /i /c:"restore operation completed" /c:"component store" /c:"source files" /c:"error:" /c:"failed" /c:"completed successfully" "%DLOG%" >>"%DETAILS%" 2>&1

if not "!DRC!"=="0" (
  >"%RESULT%" echo STATUS=FAIL
  >>"%RESULT%" echo MESSAGE=DISM RestoreHealth did not complete successfully; SFC was not started.
  >>"%RESULT%" echo EVIDENCE=DISM summary and exit code attached; full log retained locally.
  exit /b 90
)

sfc /scannow /offbootdir=C:\ /offwindir=C:\Windows >"%SLOG%" 2>&1
set "SRC=!errorlevel!"
>>"%DETAILS%" echo.
>>"%DETAILS%" echo sfc_exit_code=!SRC!
findstr /i /c:"Windows Resource Protection" /c:"corrupt" /c:"repair" /c:"failed" /c:"could not" "%SLOG%" >>"%DETAILS%" 2>&1

if not "!SRC!"=="0" (
  >"%RESULT%" echo STATUS=WARNING
  >>"%RESULT%" echo MESSAGE=Component-store repair succeeded, but offline SFC returned a non-zero status.
  >>"%RESULT%" echo EVIDENCE=DISM and SFC summaries attached; full logs retained locally.
  exit /b 40
)

>"%RESULT%" echo STATUS=PASS
>>"%RESULT%" echo MESSAGE=Offline component-store and protected-system-file repair completed.
>>"%RESULT%" echo EVIDENCE=DISM and SFC summaries attached; no personal files were targeted.
exit /b 0
