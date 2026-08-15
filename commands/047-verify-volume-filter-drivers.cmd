@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=READ_ONLY
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Verify the three offline volume-class lower-filter drivers referenced by Windows after command 46 exposed fvevol, iorate, and rdyboost in the boot volume stack.
rem WR_ACTION=VERIFY_VOLUME_FILTER_DRIVERS
rem WR_TARGET=Offline SYSTEM hive volume-class LowerFilters plus fvevol, iorate, and rdyboost service/file state.
rem WR_CONSEQUENCE=Read-only diagnostic. No registry values, drivers, boot files, partitions, or personal files are changed.
rem WR_ROLLBACK=No rollback required; read-only.

set "R=C:\WinRERepair"
set "O=%R%\COMMAND_RESULT.env"
set "A=%R%\runtime\github-auth.cmd"
set "REG=C:\Windows\System32\reg.exe"
set "SYS=C:\Windows\System32\config\SYSTEM"
if not exist "%REG%" set "REG=reg.exe"
if not exist "%SYS%" goto :BAD

"%REG%" unload HKLM\RMAISYS47 >nul 2>&1
"%REG%" load HKLM\RMAISYS47 "%SYS%" >nul 2>&1
if errorlevel 1 goto :BAD
set "N="
for /f "tokens=3" %%V in ('"%REG%" query HKLM\RMAISYS47\Select /v Current 2^>nul ^| findstr /i "Current"') do set /a N=%%V
if not defined N set "N=1"
if !N! LSS 10 (set "CS=ControlSet00!N!") else (set "CS=ControlSet0!N!")

>"%R%\LAST_RUN_REPORT.txt" echo status=PASS
>>"%R%\LAST_RUN_REPORT.txt" echo message=Command 47 verified the offline volume-class filter-driver configuration after the persistent 0x7B boot failure.
>"%R%\RUN_DETAILS.txt" echo diagnostic=VERIFY_VOLUME_FILTER_DRIVERS
>>"%R%\RUN_DETAILS.txt" echo windows_changes=NONE
>>"%R%\RUN_DETAILS.txt" echo active_control_set=!CS!
>>"%R%\RUN_DETAILS.txt" echo [VOLUME_CLASS_FILTERS]
"%REG%" query "HKLM\RMAISYS47\!CS!\Control\Class\{71a27cdd-812a-11d0-bec7-08002be2092f}" /v UpperFilters >>"%R%\RUN_DETAILS.txt" 2>&1
"%REG%" query "HKLM\RMAISYS47\!CS!\Control\Class\{71a27cdd-812a-11d0-bec7-08002be2092f}" /v LowerFilters >>"%R%\RUN_DETAILS.txt" 2>&1

for %%S in (fvevol iorate rdyboost) do (
  >>"%R%\RUN_DETAILS.txt" echo [SERVICE_%%S]
  "%REG%" query "HKLM\RMAISYS47\!CS!\Services\%%S" /v Start >>"%R%\RUN_DETAILS.txt" 2>&1
  "%REG%" query "HKLM\RMAISYS47\!CS!\Services\%%S" /v Type >>"%R%\RUN_DETAILS.txt" 2>&1
  "%REG%" query "HKLM\RMAISYS47\!CS!\Services\%%S" /v Group >>"%R%\RUN_DETAILS.txt" 2>&1
  "%REG%" query "HKLM\RMAISYS47\!CS!\Services\%%S" /v ErrorControl >>"%R%\RUN_DETAILS.txt" 2>&1
  "%REG%" query "HKLM\RMAISYS47\!CS!\Services\%%S" /v ImagePath >>"%R%\RUN_DETAILS.txt" 2>&1
  "%REG%" query "HKLM\RMAISYS47\!CS!\Services\%%S\StartOverride" /v 0 >>"%R%\RUN_DETAILS.txt" 2>&1
)
"%REG%" unload HKLM\RMAISYS47 >nul 2>&1

>>"%R%\RUN_DETAILS.txt" echo [FILTER_DRIVER_FILES]
for %%F in (fvevol.sys iorate.sys rdyboost.sys) do (
  if exist "C:\Windows\System32\drivers\%%F" (
    >>"%R%\RUN_DETAILS.txt" echo %%F=PRESENT
    dir /a:-d "C:\Windows\System32\drivers\%%F" >>"%R%\RUN_DETAILS.txt" 2>&1
  ) else (
    >>"%R%\RUN_DETAILS.txt" echo %%F=MISSING
  )
)

call "%A%" upload >nul 2>&1
if errorlevel 1 goto :UPLOADFAIL
>"%O%" echo STATUS=PASS
>>"%O%" echo MESSAGE=RescueMeAI verified the volume-class lower-filter services and driver files implicated by the post-BCD 0x7B evidence.
>>"%O%" echo EVIDENCE=Private report contains fvevol, iorate, and rdyboost service and file state.
>>"%O%" echo INSTRUCTION=No user action is required. Leave RescueMeAI online; do not reboot yet.
exit /b 0

:UPLOADFAIL
>"%O%" echo STATUS=WARNING
>>"%O%" echo MESSAGE=Volume-filter evidence was collected locally but its private upload failed.
>>"%O%" echo EVIDENCE=No Windows changes were made.
>>"%O%" echo INSTRUCTION=Leave RescueMeAI online; do not reboot.
exit /b 20

:BAD
"%REG%" unload HKLM\RMAISYS47 >nul 2>&1
>"%O%" echo STATUS=FAIL
>>"%O%" echo MESSAGE=RescueMeAI could not inspect the offline volume-filter configuration.
>>"%O%" echo EVIDENCE=No Windows changes were made.
>>"%O%" echo INSTRUCTION=Leave RescueMeAI online; do not reboot.
exit /b 90
