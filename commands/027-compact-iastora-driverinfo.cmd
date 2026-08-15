@echo off
setlocal EnableExtensions
rem WR_RISK=READ_ONLY
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Extract compact oem27 and oem47 version, boot-critical, and DEV_A102 support lines from the existing DISM driver-info output.
rem WR_ACTION=EXTRACT_IASTORA_DRIVERINFO
rem WR_TARGET=C:\WinRERepair\diag26-driverinfo.txt and RescueMeAI private evidence only.
rem WR_CONSEQUENCE=Reads an existing DISM output file and uploads selected lines. It does not rerun DISM or modify Windows.
rem WR_ROLLBACK=No Windows state is changed.

set "R=C:\WinRERepair"
set "O=%R%\COMMAND_RESULT.env"
set "A=%R%\runtime\github-auth.cmd"
set "S=%R%\diag26-driverinfo.txt"
set "Q=%R%\diag27-driverinfo-compact.txt"
set "F=C:\Windows\System32\findstr.exe"
if not exist "%F%" set "F=findstr.exe"
if not exist "%S%" goto :BAD

>"%Q%" echo RESCUEMEAI COMPACT IASTORA DRIVERINFO
>>"%Q%" echo windows_changes=NONE
"%F%" /i /c:"[OEM27]" /c:"[OEM47]" /c:"Published Name :" /c:"Driver Store Path :" /c:"Date :" /c:"Version :" /c:"Boot Critical :" /c:"DEV_A102" "%S%" >>"%Q%" 2>&1

>"%R%\LAST_RUN_REPORT.txt" echo status=PASS
>>"%R%\LAST_RUN_REPORT.txt" echo message=Compact iaStorA driver metadata.
>"%R%\RUN_DETAILS.txt" echo diagnostic=COMPACT_IASTORA_DRIVERINFO
type "%Q%" >>"%R%\RUN_DETAILS.txt"
call "%A%" upload >nul 2>&1
if errorlevel 1 goto :BAD

>"%O%" echo STATUS=PASS
>>"%O%" echo MESSAGE=Compact staged iaStorA metadata was extracted without changing Windows.
>>"%O%" echo EVIDENCE=Private package version, boot-critical, and exact DEV_A102 support lines uploaded.
>>"%O%" echo INSTRUCTION=Reply pass. RescueMeAI remains online.
exit /b 0

:BAD
>"%O%" echo STATUS=FAIL
>>"%O%" echo MESSAGE=Compact staged iaStorA metadata could not be extracted.
>>"%O%" echo EVIDENCE=No Windows changes were attempted.
>>"%O%" echo INSTRUCTION=Reply fail. RescueMeAI remains online.
exit /b 90
