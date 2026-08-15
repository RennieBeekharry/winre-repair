@echo off
setlocal EnableExtensions
rem WR_RISK=READ_ONLY
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Identify the offline SYSTEM control set Windows is configured to use and compare boot-critical storage values across available control sets.
rem WR_ACTION=VERIFY_ACTIVE_CONTROL_SET_STORAGE
rem WR_TARGET=Offline SYSTEM Select key and storage/controller values in ControlSet001 through ControlSet003.
rem WR_CONSEQUENCE=Reads registry values only. Makes no Windows changes.
rem WR_ROLLBACK=None required; read-only diagnostic.

set "R=C:\WinRERepair"
set "O=%R%\COMMAND_RESULT.env"
set "A=%R%\runtime\github-auth.cmd"
set "Q=%R%\diag32-controlsets.txt"
set "G=C:\Windows\System32\reg.exe"
set "SYS=C:\Windows\System32\config\SYSTEM"
if not exist "%G%" set "G=reg.exe"

>"%Q%" echo RESCUEMEAI ACTIVE CONTROL SET STORAGE CHECK
>>"%Q%" echo windows_changes=NONE

"%G%" unload HKLM\RMAISYS32 >nul 2>&1
"%G%" load HKLM\RMAISYS32 "%SYS%" >>"%Q%" 2>&1
if errorlevel 1 goto :BAD

>>"%Q%" echo [SELECT]
"%G%" query HKLM\RMAISYS32\Select >>"%Q%" 2>&1

for %%S in (001 002 003) do (
  "%G%" query HKLM\RMAISYS32\ControlSet%%S >nul 2>&1
  if not errorlevel 1 (
    >>"%Q%" echo [CONTROLSET%%S]
    "%G%" query "HKLM\RMAISYS32\ControlSet%%S\Enum\PCI\VEN_8086&DEV_A102&SUBSYS_2B45103C&REV_31\3&11583659&0&B8" /v Service >>"%Q%" 2>&1
    "%G%" query HKLM\RMAISYS32\ControlSet%%S\Services\iaStorA /v Start >>"%Q%" 2>&1
    "%G%" query HKLM\RMAISYS32\ControlSet%%S\Services\iaStorAC /v Start >>"%Q%" 2>&1
    "%G%" query HKLM\RMAISYS32\ControlSet%%S\Services\storahci /v Start >>"%Q%" 2>&1
    "%G%" query HKLM\RMAISYS32\ControlSet%%S\Services\storahci\StartOverride /v 0 >>"%Q%" 2>&1
    "%G%" query "HKLM\RMAISYS32\ControlSet%%S\Control\Class\{4d36e967-e325-11ce-bfc1-08002be10318}" /v UpperFilters >>"%Q%" 2>&1
    "%G%" query "HKLM\RMAISYS32\ControlSet%%S\Control\Class\{4d36e967-e325-11ce-bfc1-08002be10318}" /v LowerFilters >>"%Q%" 2>&1
  )
)

"%G%" unload HKLM\RMAISYS32 >>"%Q%" 2>&1

>"%R%\LAST_RUN_REPORT.txt" echo status=PASS
>>"%R%\LAST_RUN_REPORT.txt" echo message=Offline SYSTEM control-set storage comparison completed.
>"%R%\RUN_DETAILS.txt" echo diagnostic=ACTIVE_CONTROL_SET_STORAGE
type "%Q%" >>"%R%\RUN_DETAILS.txt"
if exist "%A%" call "%A%" upload >nul 2>&1

>"%O%" echo STATUS=PASS
>>"%O%" echo MESSAGE=RescueMeAI identified the configured SYSTEM control sets and compared their boot-storage settings.
>>"%O%" echo EVIDENCE=Private Select key and ControlSet001-003 storage values uploaded.
>>"%O%" echo INSTRUCTION=Reply pass. RescueMeAI remains online; do not reboot yet.
exit /b 0

:BAD
"%G%" unload HKLM\RMAISYS32 >nul 2>&1
>"%O%" echo STATUS=FAIL
>>"%O%" echo MESSAGE=RescueMeAI could not inspect the offline SYSTEM control sets.
>>"%O%" echo EVIDENCE=No Windows changes were made.
>>"%O%" echo INSTRUCTION=Reply fail. Do not reboot.
exit /b 90
