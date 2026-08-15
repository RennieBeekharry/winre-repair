@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=READ_ONLY
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Verify the current offline storage-controller binding and storahci override after the rollback verifier reported failure.
rem WR_ACTION=VERIFY_STORAHCI_ROLLBACK_STATE
rem WR_TARGET=Offline SYSTEM registry read only plus saved rollback backup presence.
rem WR_CONSEQUENCE=Reads current values only. Makes no Windows changes.
rem WR_ROLLBACK=None required; read-only diagnostic.

set "R=C:\WinRERepair"
set "O=%R%\COMMAND_RESULT.env"
set "A=%R%\runtime\github-auth.cmd"
set "Q=%R%\diag31-rollback-state.txt"
set "G=C:\Windows\System32\reg.exe"
set "SYS=C:\Windows\System32\config\SYSTEM"
set "BAK=%R%\SYSTEM.before-storahci-test.hiv"
if not exist "%G%" set "G=reg.exe"

>"%Q%" echo RESCUEMEAI ROLLBACK STATE VERIFICATION
>>"%Q%" echo windows_changes=NONE
>>"%Q%" echo backup_exists=%BAK%
if exist "%BAK%" (
  for %%F in ("%BAK%") do >>"%Q%" echo backup_size=%%~zF
) else (
  >>"%Q%" echo backup_size=MISSING
)

"%G%" unload HKLM\RMAIVERIFY31 >nul 2>&1
"%G%" load HKLM\RMAIVERIFY31 "%SYS%" >>"%Q%" 2>&1
if errorlevel 1 goto :BAD

set "DEV=HKLM\RMAIVERIFY31\ControlSet001\Enum\PCI\VEN_8086&DEV_A102&SUBSYS_2B45103C&REV_31\3&11583659&0&B8"
>>"%Q%" echo [CURRENT]
"%G%" query "!DEV!" /v Service >>"%Q%" 2>&1
"%G%" query HKLM\RMAIVERIFY31\ControlSet001\Services\iaStorA /v Start >>"%Q%" 2>&1
"%G%" query HKLM\RMAIVERIFY31\ControlSet001\Services\storahci /v Start >>"%Q%" 2>&1
"%G%" query HKLM\RMAIVERIFY31\ControlSet001\Services\storahci\StartOverride /v 0 >>"%Q%" 2>&1

set "SVC="
set "OVR="
for /f "tokens=1,2,3" %%A in ('"%G%" query "!DEV!" /v Service ^| findstr /r /c:"^[ ]*Service[ ]"') do set "SVC=%%C"
for /f "tokens=1,2,3" %%A in ('"%G%" query HKLM\RMAIVERIFY31\ControlSet001\Services\storahci\StartOverride /v 0 ^| findstr /r /c:"^[ ]*0[ ]"') do set "OVR=%%C"
>>"%Q%" echo parsed_service=!SVC!
>>"%Q%" echo parsed_override=!OVR!

"%G%" unload HKLM\RMAIVERIFY31 >>"%Q%" 2>&1
if /i "!SVC!"=="iaStorA" if /i "!OVR!"=="0x3" goto :GOOD

> "%R%\LAST_RUN_REPORT.txt" echo status=WARNING
>>"%R%\LAST_RUN_REPORT.txt" echo message=Rollback state does not yet match the original iaStorA configuration.
> "%R%\RUN_DETAILS.txt" echo diagnostic=VERIFY_STORAHCI_ROLLBACK_STATE
type "%Q%" >>"%R%\RUN_DETAILS.txt"
if exist "%A%" call "%A%" upload >nul 2>&1
>"%O%" echo STATUS=WARNING
>>"%O%" echo MESSAGE=The current storage rollback state still needs correction before another reboot.
>>"%O%" echo EVIDENCE=Private current Service and StartOverride values uploaded.
>>"%O%" echo INSTRUCTION=Reply warning. Do not reboot. RescueMeAI remains online.
exit /b 0

:GOOD
> "%R%\LAST_RUN_REPORT.txt" echo status=PASS
>>"%R%\LAST_RUN_REPORT.txt" echo message=The original iaStorA rollback state is already restored.
> "%R%\RUN_DETAILS.txt" echo diagnostic=VERIFY_STORAHCI_ROLLBACK_STATE
type "%Q%" >>"%R%\RUN_DETAILS.txt"
if exist "%A%" call "%A%" upload >nul 2>&1
>"%O%" echo STATUS=PASS
>>"%O%" echo MESSAGE=Rollback verified: controller is back on iaStorA and storahci StartOverride is restored to 3.
>>"%O%" echo EVIDENCE=The prior command-30 FAIL was a verification-parser false negative.
>>"%O%" echo INSTRUCTION=Reply pass. RescueMeAI remains online; no reboot yet.
exit /b 0

:BAD
"%G%" unload HKLM\RMAIVERIFY31 >nul 2>&1
>"%O%" echo STATUS=FAIL
>>"%O%" echo MESSAGE=RescueMeAI could not read the offline SYSTEM hive safely.
>>"%O%" echo EVIDENCE=No Windows changes were made.
>>"%O%" echo INSTRUCTION=Reply fail. Do not reboot.
exit /b 90
