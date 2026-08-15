@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=READ_ONLY
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Compare the current offline rdyboost filter-driver service configuration with the installed Windows INF package to determine whether its Start value was altered from the package-defined default.
rem WR_ACTION=VERIFY_RDYBOOST_INF_DEFAULTS
rem WR_TARGET=Offline rdyboost service registry values and local Windows INF/DriverStore metadata only.
rem WR_CONSEQUENCE=Read-only diagnostic. No registry values, driver packages, boot files, partitions, or personal files are changed.
rem WR_ROLLBACK=No rollback required; read-only.

set "R=C:\WinRERepair"
set "O=%R%\COMMAND_RESULT.env"
set "A=%R%\runtime\github-auth.cmd"
set "REG=C:\Windows\System32\reg.exe"
set "SYS=C:\Windows\System32\config\SYSTEM"
set "FS=C:\Windows\System32\findstr.exe"
if not exist "%REG%" set "REG=reg.exe"
if not exist "%FS%" set "FS=findstr.exe"
if not exist "%SYS%" goto :BAD

"%REG%" unload HKLM\RMAISYS48 >nul 2>&1
"%REG%" load HKLM\RMAISYS48 "%SYS%" >nul 2>&1
if errorlevel 1 goto :BAD
set "N="
for /f "tokens=3" %%V in ('"%REG%" query HKLM\RMAISYS48\Select /v Current 2^>nul ^| "%FS%" /i "Current"') do set /a N=%%V
if not defined N set "N=1"
if !N! LSS 10 (set "CS=ControlSet00!N!") else (set "CS=ControlSet0!N!")

>"%R%\LAST_RUN_REPORT.txt" echo status=PASS
>>"%R%\LAST_RUN_REPORT.txt" echo message=Command 48 compared rdyboost registry configuration with its installed INF metadata.
>"%R%\RUN_DETAILS.txt" echo diagnostic=VERIFY_RDYBOOST_INF_DEFAULTS
>>"%R%\RUN_DETAILS.txt" echo windows_changes=NONE
>>"%R%\RUN_DETAILS.txt" echo active_control_set=!CS!
>>"%R%\RUN_DETAILS.txt" echo [CURRENT_RDYBOOST_SERVICE]
for %%V in (Start Type Group ErrorControl ImagePath) do "%REG%" query "HKLM\RMAISYS48\!CS!\Services\rdyboost" /v %%V >>"%R%\RUN_DETAILS.txt" 2>&1
"%REG%" unload HKLM\RMAISYS48 >nul 2>&1

>>"%R%\RUN_DETAILS.txt" echo [WINDOWS_INF_RDYBOOST]
if exist C:\Windows\INF\rdyboost.inf (
  >>"%R%\RUN_DETAILS.txt" echo inf_path=C:\Windows\INF\rdyboost.inf
  "%FS%" /i /n /c:"AddService" /c:"StartType" /c:"ServiceType" /c:"ErrorControl" /c:"LoadOrderGroup" /c:"ServiceBinary" C:\Windows\INF\rdyboost.inf >>"%R%\RUN_DETAILS.txt" 2>&1
) else (
  >>"%R%\RUN_DETAILS.txt" echo inf_path=MISSING
)

>>"%R%\RUN_DETAILS.txt" echo [DRIVERSTORE_RDYBOOST]
set "FOUND=NO"
for /d %%D in (C:\Windows\System32\DriverStore\FileRepository\rdyboost.inf_*) do (
  if exist "%%D\rdyboost.inf" (
    set "FOUND=YES"
    >>"%R%\RUN_DETAILS.txt" echo package=%%D
    "%FS%" /i /n /c:"AddService" /c:"StartType" /c:"ServiceType" /c:"ErrorControl" /c:"LoadOrderGroup" /c:"ServiceBinary" "%%D\rdyboost.inf" >>"%R%\RUN_DETAILS.txt" 2>&1
  )
)
if /i "!FOUND!"=="NO" >>"%R%\RUN_DETAILS.txt" echo driverstore_package=NOT_FOUND_BY_NAME

call "%A%" upload >nul 2>&1
if errorlevel 1 goto :UPLOADFAIL
>"%O%" echo STATUS=PASS
>>"%O%" echo MESSAGE=RescueMeAI compared the current rdyboost filter-driver start configuration with the installed Windows driver package defaults.
>>"%O%" echo EVIDENCE=Private report contains current rdyboost service values and matching INF StartType/service-install lines.
>>"%O%" echo INSTRUCTION=No user action is required. Leave RescueMeAI online; do not reboot yet.
exit /b 0

:UPLOADFAIL
>"%O%" echo STATUS=WARNING
>>"%O%" echo MESSAGE=ReadyBoost INF comparison completed locally but private upload failed.
>>"%O%" echo EVIDENCE=No Windows changes were made.
>>"%O%" echo INSTRUCTION=Leave RescueMeAI online; do not reboot.
exit /b 20

:BAD
"%REG%" unload HKLM\RMAISYS48 >nul 2>&1
>"%O%" echo STATUS=FAIL
>>"%O%" echo MESSAGE=RescueMeAI could not compare the offline rdyboost service with installed INF metadata.
>>"%O%" echo EVIDENCE=No Windows changes were made.
>>"%O%" echo INSTRUCTION=Leave RescueMeAI online; do not reboot.
exit /b 90
