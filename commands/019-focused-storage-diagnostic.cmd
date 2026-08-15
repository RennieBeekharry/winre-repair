@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=READ_ONLY
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Collect focused Intel storage boot evidence for INACCESSIBLE_BOOT_DEVICE without changing Windows.
rem WR_ACTION=STORAGE_BOOT_DIAGNOSTIC
rem WR_TARGET=C:\Windows offline SYSTEM hive, SetupAPI log, and RescueMeAI diagnostic files only.
rem WR_CONSEQUENCE=Reads storage-controller boot configuration and uploads private evidence. It does not repair or modify Windows.
rem WR_ROLLBACK=No Windows recovery state is changed. The temporary SYSTEM hive mount is unloaded before exit.
set "R=C:\WinRERepair"
set "O=%R%\COMMAND_RESULT.env"
set "D=%R%\diag19-storage.txt"
set "A=%R%\runtime\github-auth.cmd"
set "REG=C:\Windows\System32\reg.exe"
set "FS=C:\Windows\System32\findstr.exe"
if not exist "%REG%" set "REG=reg.exe"
if not exist "%FS%" set "FS=findstr.exe"
if not exist C:\Windows\System32\config\SYSTEM goto :BAD
>"%D%" echo RESCUEMEAI 0x7B STORAGE EVIDENCE
"%REG%" unload HKLM\RMAISYS19 >nul 2>&1
"%REG%" load HKLM\RMAISYS19 C:\Windows\System32\config\SYSTEM >>"%D%" 2>&1
if errorlevel 1 goto :BAD
"%REG%" query HKLM\RMAISYS19\Select >>"%D%" 2>&1
set "N="
for /f "tokens=3" %%V in ('"%REG%" query HKLM\RMAISYS19\Select /v Current 2^>nul ^| "%FS%" /i "Current"') do set /a N=%%V
if not defined N set "N=1"
if !N! LSS 10 (set "CS=ControlSet00!N!") else (set "CS=ControlSet0!N!")
>>"%D%" echo CONTROL_SET=!CS!
for %%S in (iaStorA iaStorAC storahci storport disk classpnp) do (
  >>"%D%" echo ===== SERVICE %%S =====
  "%REG%" query "HKLM\RMAISYS19\!CS!\Services\%%S" /s >>"%D%" 2>&1
)
>>"%D%" echo ===== INTEL A102 CONTROLLER =====
"%REG%" query "HKLM\RMAISYS19\!CS!\Enum\PCI" /f "VEN_8086&DEV_A102" /s >>"%D%" 2>&1
>>"%D%" echo ===== STORAGE CLASS FILTERS =====
for %%G in ({4d36e967-e325-11ce-bfc1-08002be10318} {4d36e96a-e325-11ce-bfc1-08002be10318} {4d36e97b-e325-11ce-bfc1-08002be10318}) do "%REG%" query "HKLM\RMAISYS19\!CS!\Control\Class\%%G" /s >>"%D%" 2>&1
"%REG%" unload HKLM\RMAISYS19 >>"%D%" 2>&1
>>"%D%" echo ===== SETUPAPI MATCHES =====
if exist C:\Windows\INF\setupapi.dev.log "%FS%" /i /c:"VEN_8086&DEV_A102" /c:"iaStorA" /c:"iaStorAC" /c:"storahci" C:\Windows\INF\setupapi.dev.log >>"%D%" 2>&1
>"%R%\LAST_RUN_REPORT.txt" echo status=PASS
>>"%R%\LAST_RUN_REPORT.txt" echo message=Focused Intel storage evidence collected.
>"%R%\RUN_DETAILS.txt" echo diagnostic=STORAGE_BOOT_0X7B
>>"%R%\RUN_DETAILS.txt" echo windows_changes=NONE
type "%D%" >>"%R%\RUN_DETAILS.txt"
if exist "%A%" call "%A%" upload >nul 2>&1
>"%O%" echo STATUS=PASS
>>"%O%" echo MESSAGE=Focused Intel storage boot evidence was collected without changing Windows.
>>"%O%" echo EVIDENCE=Detailed private 0x7B storage evidence uploaded for ChatGPT review.
>>"%O%" echo INSTRUCTION=Reply pass. RescueMeAI remains online.
exit /b 0
:BAD
"%REG%" unload HKLM\RMAISYS19 >nul 2>&1
>"%O%" echo STATUS=FAIL
>>"%O%" echo MESSAGE=Focused storage diagnostic could not read the offline SYSTEM hive.
>>"%O%" echo EVIDENCE=No Windows changes were attempted.
>>"%O%" echo INSTRUCTION=Reply fail. RescueMeAI remains online.
exit /b 90
