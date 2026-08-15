@echo off
setlocal EnableExtensions
rem WR_RISK=READ_ONLY
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Extract exact unrepaired file evidence from the existing offline SFC diagnostic log without rerunning SFC.
rem WR_ACTION=EXTRACT_SFC_CORRUPTION
rem WR_TARGET=C:\WinRERepair\diag12-sfc.log and RescueMeAI private evidence only.
rem WR_CONSEQUENCE=Reads an existing diagnostic log and uploads matching corruption lines. It does not scan, repair, or modify Windows.
rem WR_ROLLBACK=No Windows state is changed.

set "R=C:\WinRERepair"
set "O=%R%\COMMAND_RESULT.env"
set "A=%R%\runtime\github-auth.cmd"
set "S=%R%\diag12-sfc.log"
set "Q=%R%\sfc23-corruption.txt"
set "F=C:\Windows\System32\findstr.exe"
if not exist "%F%" set "F=findstr.exe"
if not exist "%S%" goto :BAD

>"%Q%" echo RESCUEMEAI EXISTING SFC CORRUPTION EVIDENCE
>>"%Q%" echo windows_changes=NONE
>>"%Q%" echo [CANNOT_REPAIR]
"%F%" /i /c:"Cannot repair member file" "%S%" >>"%Q%" 2>&1
>>"%Q%" echo [HASH_MISMATCH]
"%F%" /i /c:"Hashes for file member do not match" "%S%" >>"%Q%" 2>&1
>>"%Q%" echo [REPAIR_FAILED]
"%F%" /i /c:"Repair failed" "%S%" >>"%Q%" 2>&1

>"%R%\LAST_RUN_REPORT.txt" echo status=PASS
>>"%R%\LAST_RUN_REPORT.txt" echo message=Existing SFC corruption details.
>"%R%\RUN_DETAILS.txt" echo diagnostic=SFC_CORRUPTION_DETAILS
type "%Q%" >>"%R%\RUN_DETAILS.txt"
call "%A%" upload >nul 2>&1
if errorlevel 1 goto :BAD

>"%O%" echo STATUS=PASS
>>"%O%" echo MESSAGE=Existing SFC corruption details were extracted without rerunning SFC.
>>"%O%" echo EVIDENCE=Private SFC corruption file details uploaded for targeted repair selection.
>>"%O%" echo INSTRUCTION=Reply pass. RescueMeAI remains online.
exit /b 0

:BAD
>"%O%" echo STATUS=FAIL
>>"%O%" echo MESSAGE=Existing SFC corruption details could not be extracted.
>>"%O%" echo EVIDENCE=No Windows changes were attempted.
>>"%O%" echo INSTRUCTION=Reply fail. RescueMeAI remains online.
exit /b 90
