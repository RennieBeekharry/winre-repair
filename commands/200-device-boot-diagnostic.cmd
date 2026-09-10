@echo off
setlocal EnableExtensions DisableDelayedExpansion
rem WR_RISK=READ_ONLY
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Collect bounded boot diagnostics for this RescueMeAI session.
rem WR_ACTION=COLLECT_BOOT_DIAGNOSTICS
rem WR_TARGET=Offline Windows installation on C: only.
rem WR_CONSEQUENCE=Reads boot, BitLocker, component-store, and Startup Repair status; makes no recovery changes.
rem WR_ROLLBACK=Not applicable; read-only collection only.

set "WORK=C:\WinRERepair"
set "DETAILS=%WORK%\RUN_DETAILS.txt"
set "RESULT=%WORK%\COMMAND_RESULT.env"
if not exist "%WORK%" md "%WORK%" >nul 2>&1

>"%DETAILS%" echo RESCUEMEAI BOUNDED BOOT DIAGNOSTIC
>>"%DETAILS%" echo windows_drive=C:
>>"%DETAILS%" echo.
>>"%DETAILS%" echo --- STARTUP REPAIR SIGNALS ---
if exist "C:\Windows\System32\Logfiles\Srt\SrtTrail.txt" (
  findstr /i /c:"Root cause" /c:"Repair action" /c:"Result" /c:"Boot critical" /c:"corrupt" /c:"failed" /c:"error" "C:\Windows\System32\Logfiles\Srt\SrtTrail.txt" >>"%DETAILS%" 2>&1
) else (
  >>"%DETAILS%" echo SrtTrail.txt not found
)

>>"%DETAILS%" echo.
>>"%DETAILS%" echo --- BCD DEFAULT ENTRY ---
bcdedit /enum {default} >>"%DETAILS%" 2>&1

>>"%DETAILS%" echo.
>>"%DETAILS%" echo --- BITLOCKER STATUS ---
manage-bde -status C: >>"%DETAILS%" 2>&1

>>"%DETAILS%" echo.
>>"%DETAILS%" echo --- FILESYSTEM DIRTY FLAG ---
fsutil dirty query C: >>"%DETAILS%" 2>&1

>>"%DETAILS%" echo.
>>"%DETAILS%" echo --- COMPONENT STORE CHECKHEALTH ---
dism /image:C:\ /cleanup-image /checkhealth >>"%DETAILS%" 2>&1

>>"%DETAILS%" echo.
>>"%DETAILS%" echo --- CRASH DUMP PRESENCE ---
if exist "C:\Windows\MEMORY.DMP" (echo MEMORY.DMP present>>"%DETAILS%") else (echo MEMORY.DMP absent>>"%DETAILS%")
if exist "C:\Windows\Minidump\*.dmp" (dir /b /o-d "C:\Windows\Minidump\*.dmp" >>"%DETAILS%" 2>&1) else (echo No minidumps present>>"%DETAILS%")

>"%RESULT%" echo STATUS=PASS
>>"%RESULT%" echo MESSAGE=Read-only boot diagnostic completed.
>>"%RESULT%" echo EVIDENCE=Bounded technical boot evidence attached in RUN_DETAILS.
exit /b 0
