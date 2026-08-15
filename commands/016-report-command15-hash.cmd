@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=READ_ONLY
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Report the SHA-256 that RescueMeAI calculated for the previously downloaded command 15 file.
rem WR_ACTION=REPORT_LOCAL_COMMAND_HASH
rem WR_TARGET=RescueMeAI local command-integrity log only.
rem WR_CONSEQUENCE=Reads and reports a local hash. It does not change Windows.
rem WR_ROLLBACK=No Windows state is changed.

set "OUT=C:\WinRERepair\COMMAND_RESULT.env"
set "HF=C:\WinRERepair\agent\command-hash.txt"
set "H="
if not exist "%HF%" goto :BAD
for /f "usebackq skip=1 tokens=1" %%H in ("%HF%") do if not defined H set "H=%%H"
if not defined H goto :BAD
>"%OUT%" echo STATUS=PASS
>>"%OUT%" echo MESSAGE=RescueMeAI reported the locally calculated SHA-256 for command 15.
>>"%OUT%" echo EVIDENCE=COMMAND15_ACTUAL_SHA256=!H!
>>"%OUT%" echo INSTRUCTION=Reply pass. RescueMeAI remains online.
exit /b 0
:BAD
>"%OUT%" echo STATUS=FAIL
>>"%OUT%" echo MESSAGE=The prior command-integrity hash could not be read.
>>"%OUT%" echo EVIDENCE=No Windows changes were attempted.
>>"%OUT%" echo INSTRUCTION=Reply fail. RescueMeAI remains online.
exit /b 90
