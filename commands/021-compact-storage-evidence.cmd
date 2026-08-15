@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=READ_ONLY
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Collect a compact set of boot-critical Intel storage values that can directly cause INACCESSIBLE_BOOT_DEVICE.
rem WR_ACTION=COMPACT_STORAGE_BOOT_EVIDENCE
rem WR_TARGET=C:\Windows offline SYSTEM hive and RescueMeAI private evidence only.
rem WR_CONSEQUENCE=Reads selected boot-critical registry values and uploads a compact report. It does not repair or modify Windows.
rem WR_ROLLBACK=No Windows recovery state is changed. The temporary SYSTEM hive mount is unloaded before exit.
set "R=C:\WinRERepair"
set "O=%R%\COMMAND_RESULT.env"
set "A=%R%\runtime\github-auth.cmd"
set "Q=%R%\compact21.txt"
set "REG=C:\Windows\System32\reg.exe"
set "FS=C:\Windows\System32\findstr.exe"
if not exist "%REG%" set "REG=reg.exe"
if not exist "%FS%" set "FS=findstr.exe"
if not exist C:\Windows\System32\config\SYSTEM goto :BAD
>"%Q%" echo RESCUEMEAI COMPACT 0x7B STORAGE EVIDENCE
"%REG%" unload HKLM\RMAISYS21 >nul 2>&1
"%REG%" load HKLM\RMAISYS21 C:\Windows\System32\config\SYSTEM >>"%Q%" 2>&1
if errorlevel 1 goto :BAD
set "N="
for /f "tokens=3" %%V in ('"%REG%" query HKLM\RMAISYS21\Select /v Current 2^>nul ^| "%FS%" /i "Current"') do set /a N=%%V
if not defined N set "N=1"
if !N! LSS 10 (set "CS=ControlSet00!N!") else (set "CS=ControlSet0!N!")
>>"%Q%" echo CONTROL_SET=!CS!
for %%S in (iaStorA iaStorAC storahci storport disk classpnp) do (
  >>"%Q%" echo [%%S]
  "%REG%" query "HKLM\RMAISYS21\!CS!\Services\%%S" /v Start >>"%Q%" 2>&1
  "%REG%" query "HKLM\RMAISYS21\!CS!\Services\%%S" /v Group >>"%Q%" 2>&1
  "%REG%" query "HKLM\RMAISYS21\!CS!\Services\%%S" /v ImagePath >>"%Q%" 2>&1
  "%REG%" query "HKLM\RMAISYS21\!CS!\Services\%%S\StartOverride" /v 0 >>"%Q%" 2>&1
)
>>"%Q%" echo [INTEL_CONTROLLER]
set "DEV=HKLM\RMAISYS21\!CS!\Enum\PCI\VEN_8086&DEV_A102&SUBSYS_2B45103C&REV_31\3&11583659&0&B8"
for %%V in (Service Driver ClassGUID ConfigFlags Problem) do "%REG%" query "!DEV!" /v %%V >>"%Q%" 2>&1
>>"%Q%" echo [CLASS_FILTERS]
for %%G in ({4d36e967-e325-11ce-bfc1-08002be10318} {4d36e96a-e325-11ce-bfc1-08002be10318} {4d36e97b-e325-11ce-bfc1-08002be10318}) do (
  >>"%Q%" echo %%G
  "%REG%" query "HKLM\RMAISYS21\!CS!\Control\Class\%%G" /v UpperFilters >>"%Q%" 2>&1
  "%REG%" query "HKLM\RMAISYS21\!CS!\Control\Class\%%G" /v LowerFilters >>"%Q%" 2>&1
)
"%REG%" unload HKLM\RMAISYS21 >>"%Q%" 2>&1
>"%R%\LAST_RUN_REPORT.txt" echo status=PASS
>>"%R%\LAST_RUN_REPORT.txt" echo message=Compact 0x7B storage evidence.
>"%R%\RUN_DETAILS.txt" echo diagnostic=COMPACT_STORAGE_BOOT_0X7B
>>"%R%\RUN_DETAILS.txt" echo windows_changes=NONE
type "%Q%" >>"%R%\RUN_DETAILS.txt"
call "%A%" upload >nul 2>&1
if errorlevel 1 goto :BAD
>"%O%" echo STATUS=PASS
>>"%O%" echo MESSAGE=Compact boot-critical Intel storage evidence was uploaded without changing Windows.
>>"%O%" echo EVIDENCE=ChatGPT can now select the smallest targeted 0x7B repair.
>>"%O%" echo INSTRUCTION=Reply pass. RescueMeAI remains online.
exit /b 0
:BAD
"%REG%" unload HKLM\RMAISYS21 >nul 2>&1
>"%O%" echo STATUS=FAIL
>>"%O%" echo MESSAGE=Compact storage evidence collection or upload failed.
>>"%O%" echo EVIDENCE=No Windows changes were attempted.
>>"%O%" echo INSTRUCTION=Reply fail. RescueMeAI remains online.
exit /b 90
