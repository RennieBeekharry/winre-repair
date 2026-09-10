@echo off
setlocal EnableExtensions DisableDelayedExpansion
rem WR_RISK=READ_ONLY
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Collect focused Startup Repair and recent boot failure evidence.
rem WR_ACTION=COLLECT_FOCUSED_BOOT_FAILURE_EVIDENCE
rem WR_TARGET=Offline Windows installation on C: only.
rem WR_CONSEQUENCE=Reads Startup Repair text, recent System log errors, and servicing pending state; makes no recovery changes.
rem WR_ROLLBACK=Not applicable; read-only collection only.

set "WORK=C:\WinRERepair"
set "DETAILS=%WORK%\RUN_DETAILS.txt"
set "RESULT=%WORK%\COMMAND_RESULT.env"
>"%DETAILS%" echo RESCUEMEAI FOCUSED BOOT FAILURE EVIDENCE

>>"%DETAILS%" echo --- STARTUP REPAIR CONVERTED SIGNALS ---
if exist "C:\Windows\System32\Logfiles\Srt\SrtTrail.txt" (
  more < "C:\Windows\System32\Logfiles\Srt\SrtTrail.txt" | findstr /i /c:"Root cause" /c:"Repair action" /c:"Result" /c:"Boot critical" /c:"corrupt" /c:"failed" /c:"error" >>"%DETAILS%" 2>&1
) else (
  >>"%DETAILS%" echo SrtTrail.txt not found
)

>>"%DETAILS%" echo.
>>"%DETAILS%" echo --- SERVICING PENDING STATE ---
if exist "C:\Windows\WinSxS\pending.xml" (echo pending.xml=PRESENT>>"%DETAILS%") else (echo pending.xml=ABSENT>>"%DETAILS%")
dism /image:C:\ /get-packages /format:table 2>&1 | findstr /i "Pending" >>"%DETAILS%"

>>"%DETAILS%" echo.
>>"%DETAILS%" echo --- RECENT STORAGE / BOOT ERRORS FROM SYSTEM LOG ---
wevtutil qe "C:\Windows\System32\winevt\Logs\System.evtx" /lf:true /q:"*[System[(EventID=7 or EventID=11 or EventID=51 or EventID=55 or EventID=129 or EventID=153 or EventID=161 or EventID=6008)]]" /c:10 /rd:true /f:text >>"%DETAILS%" 2>&1

>>"%DETAILS%" echo.
>>"%DETAILS%" echo --- BOOT MANAGER ENTRY ---
bcdedit /enum {bootmgr} >>"%DETAILS%" 2>&1

>"%RESULT%" echo STATUS=PASS
>>"%RESULT%" echo MESSAGE=Focused read-only boot failure evidence collected.
>>"%RESULT%" echo EVIDENCE=Startup Repair signals, servicing pending state, boot manager, and selected System errors attached.
exit /b 0
