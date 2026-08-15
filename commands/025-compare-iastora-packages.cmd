@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=READ_ONLY
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Compare staged Intel iaStorA HDC driver packages and class instances for the exact DEV_A102 controller before a reversible package-binding repair.
rem WR_ACTION=COMPARE_IASTORA_PACKAGES
rem WR_TARGET=C:\Windows INF files, offline SYSTEM HDC class registry, and RescueMeAI private evidence only.
rem WR_CONSEQUENCE=Reads package metadata and controller-class instances only. It does not repair or modify Windows.
rem WR_ROLLBACK=No Windows state is changed; the temporary SYSTEM hive mount is unloaded.

set "R=C:\WinRERepair"
set "O=%R%\COMMAND_RESULT.env"
set "A=%R%\runtime\github-auth.cmd"
set "Q=%R%\diag25-iastora-packages.txt"
set "G=C:\Windows\System32\reg.exe"
set "F=C:\Windows\System32\findstr.exe"
if not exist "%G%" set "G=reg.exe"
if not exist "%F%" set "F=findstr.exe"
if not exist C:\Windows\System32\config\SYSTEM goto :BAD

>"%Q%" echo RESCUEMEAI IASTORA PACKAGE COMPARISON
>>"%Q%" echo windows_changes=NONE

for %%I in (oem27.inf oem47.inf) do (
  >>"%Q%" echo [%%I]
  if exist C:\Windows\INF\%%I (
    "%F%" /i /c:"DriverVer" /c:"DEV_A102" /c:"iaStorA_inst_8" C:\Windows\INF\%%I >>"%Q%" 2>&1
  ) else (
    >>"%Q%" echo FILE=MISSING
  )
)

"%G%" unload HKLM\RMAISYS25 >nul 2>&1
"%G%" load HKLM\RMAISYS25 C:\Windows\System32\config\SYSTEM >>"%Q%" 2>&1
if errorlevel 1 goto :BAD

>>"%Q%" echo [HDC_CLASS_INSTANCES]
for %%N in (0000 0001 0002 0003 0004 0005 0006 0007 0008 0009 0010) do (
  set "K=HKLM\RMAISYS25\ControlSet001\Control\Class\{4d36e96a-e325-11ce-bfc1-08002be10318}\%%N"
  "%G%" query "!K!" /v InfPath >nul 2>&1
  if not errorlevel 1 (
    >>"%Q%" echo INSTANCE=%%N
    for %%V in (DriverDesc ProviderName DriverVersion InfPath InfSection MatchingDeviceId) do "%G%" query "!K!" /v %%V >>"%Q%" 2>&1
  )
)

>>"%Q%" echo [CONTROLLER_BINDING]
set "D=HKLM\RMAISYS25\ControlSet001\Enum\PCI\VEN_8086&DEV_A102&SUBSYS_2B45103C&REV_31\3&11583659&0&B8"
"%G%" query "!D!" /v Service >>"%Q%" 2>&1
"%G%" query "!D!" /v Driver >>"%Q%" 2>&1

"%G%" unload HKLM\RMAISYS25 >>"%Q%" 2>&1

>"%R%\LAST_RUN_REPORT.txt" echo status=PASS
>>"%R%\LAST_RUN_REPORT.txt" echo message=iaStorA package comparison.
>"%R%\RUN_DETAILS.txt" echo diagnostic=IASTORA_PACKAGE_COMPARISON
type "%Q%" >>"%R%\RUN_DETAILS.txt"
call "%A%" upload >nul 2>&1
if errorlevel 1 goto :BAD

>"%O%" echo STATUS=PASS
>>"%O%" echo MESSAGE=Staged iaStorA package comparison completed without changing Windows.
>>"%O%" echo EVIDENCE=Private package versions, exact DEV_A102 matches, HDC instances, and current binding uploaded.
>>"%O%" echo INSTRUCTION=Reply pass. RescueMeAI remains online.
exit /b 0

:BAD
"%G%" unload HKLM\RMAISYS25 >nul 2>&1
>"%O%" echo STATUS=FAIL
>>"%O%" echo MESSAGE=Staged iaStorA package comparison could not complete.
>>"%O%" echo EVIDENCE=No Windows changes were attempted.
>>"%O%" echo INSTRUCTION=Reply fail. RescueMeAI remains online.
exit /b 90
