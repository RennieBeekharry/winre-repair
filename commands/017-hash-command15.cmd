@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=READ_ONLY
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Calculate and report the SHA-256 of the preserved local command-15 file.
rem WR_ACTION=HASH_LOCAL_COMMAND15
rem WR_TARGET=RescueMeAI local command-15 file only.
rem WR_CONSEQUENCE=Hashes a local RescueMeAI command file. It does not change Windows.
rem WR_ROLLBACK=No Windows state is changed.

set "OUT=C:\WinRERepair\COMMAND_RESULT.env"
set "F=C:\WinRERepair\agent\command-15.cmd"
set "T=C:\WinRERepair\agent\command15-sha256.txt"
set "H="
if not exist "%F%" goto :BAD
certutil -hashfile "%F%" SHA256 >"%T%" 2>&1
if errorlevel 1 goto :BAD
for /f "usebackq skip=1 tokens=1" %%H in ("%T%") do if not defined H set "H=%%H"
if not defined H goto :BAD
>"%OUT%" echo STATUS=PASS
>>"%OUT%" echo MESSAGE=RescueMeAI calculated the SHA-256 of the preserved local command-15 file.
>>"%OUT%" echo EVIDENCE=COMMAND15_FILE_SHA256=!H!
>>"%OUT%" echo INSTRUCTION=Reply pass. RescueMeAI remains online.
exit /b 0
:BAD
>"%OUT%" echo STATUS=FAIL
>>"%OUT%" echo MESSAGE=RescueMeAI could not hash the preserved command-15 file.
>>"%OUT%" echo EVIDENCE=No Windows changes were attempted.
>>"%OUT%" echo INSTRUCTION=Reply fail. RescueMeAI remains online.
exit /b 90
