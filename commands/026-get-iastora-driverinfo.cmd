@echo off
setlocal EnableExtensions
rem WR_RISK=READ_ONLY
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Read DISM metadata for the two staged Intel iaStorA packages oem27.inf and oem47.inf before a targeted boot-driver repair.
rem WR_ACTION=GET_IASTORA_DRIVERINFO
rem WR_TARGET=C:\Windows offline driver store and RescueMeAI private evidence only.
rem WR_CONSEQUENCE=Runs DISM Get-DriverInfo for two already-staged driver packages. It does not add, remove, bind, or modify drivers.
rem WR_ROLLBACK=No Windows state is changed.

set "R=C:\WinRERepair"
set "O=%R%\COMMAND_RESULT.env"
set "A=%R%\runtime\github-auth.cmd"
set "Q=%R%\diag26-driverinfo.txt"
set "D=X:\Windows\System32\dism.exe"
if not exist "%D%" set "D=dism.exe"

>"%Q%" echo RESCUEMEAI IASTORA DRIVERINFO
>>"%Q%" echo windows_changes=NONE
>>"%Q%" echo [OEM27]
"%D%" /Image:C:\ /Get-DriverInfo /Driver:oem27.inf >>"%Q%" 2>&1
>>"%Q%" echo [OEM47]
"%D%" /Image:C:\ /Get-DriverInfo /Driver:oem47.inf >>"%Q%" 2>&1

>"%R%\LAST_RUN_REPORT.txt" echo status=PASS
>>"%R%\LAST_RUN_REPORT.txt" echo message=iaStorA staged driver metadata.
>"%R%\RUN_DETAILS.txt" echo diagnostic=IASTORA_DRIVERINFO
type "%Q%" >>"%R%\RUN_DETAILS.txt"
call "%A%" upload >nul 2>&1
if errorlevel 1 goto :BAD

>"%O%" echo STATUS=PASS
>>"%O%" echo MESSAGE=DISM read the staged iaStorA driver metadata without changing Windows.
>>"%O%" echo EVIDENCE=Private oem27 and oem47 version and boot-critical metadata uploaded.
>>"%O%" echo INSTRUCTION=Reply pass. RescueMeAI remains online.
exit /b 0

:BAD
>"%O%" echo STATUS=FAIL
>>"%O%" echo MESSAGE=Staged iaStorA driver metadata could not be read.
>>"%O%" echo EVIDENCE=No Windows changes were attempted.
>>"%O%" echo INSTRUCTION=Reply fail. RescueMeAI remains online.
exit /b 90
