@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=READ_ONLY
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Discover the actual installed Windows package/DriverDatabase metadata that owns rdyboost.sys and compare it with the current offline rdyboost service after command 48 found no standalone rdyboost.inf by filename.
rem WR_ACTION=DISCOVER_RDYBOOST_PACKAGE_METADATA
rem WR_TARGET=Offline SYSTEM and DRIVERS registry hives plus local INF/DriverStore metadata and rdyboost.sys file metadata only.
rem WR_CONSEQUENCE=Read-only diagnostic. No registry values, driver packages, boot files, partitions, or personal files are changed.
rem WR_ROLLBACK=No rollback required; read-only.

set "R=C:\WinRERepair"
set "O=%R%\COMMAND_RESULT.env"
set "A=%R%\runtime\github-auth.cmd"
set "REG=C:\Windows\System32\reg.exe"
set "FS=C:\Windows\System32\findstr.exe"
set "CERT=C:\Windows\System32\certutil.exe"
set "SYS=C:\Windows\System32\config\SYSTEM"
set "DRV=C:\Windows\System32\config\DRIVERS"
if not exist "%REG%" set "REG=reg.exe"
if not exist "%FS%" set "FS=findstr.exe"
if not exist "%CERT%" set "CERT=certutil.exe"
if not exist "%SYS%" goto :BAD

>"%R%\LAST_RUN_REPORT.txt" echo status=PASS
>>"%R%\LAST_RUN_REPORT.txt" echo message=Command 49 discovered ReadyBoost package ownership metadata without changing Windows.
>"%R%\RUN_DETAILS.txt" echo diagnostic=DISCOVER_RDYBOOST_PACKAGE_METADATA
>>"%R%\RUN_DETAILS.txt" echo windows_changes=NONE

"%REG%" unload HKLM\RMAISYS49 >nul 2>&1
"%REG%" load HKLM\RMAISYS49 "%SYS%" >nul 2>&1
if errorlevel 1 goto :BAD
set "N="
for /f "tokens=3" %%V in ('"%REG%" query HKLM\RMAISYS49\Select /v Current 2^>nul ^| "%FS%" /i "Current"') do set /a N=%%V
if not defined N set "N=1"
if !N! LSS 10 (set "CS=ControlSet00!N!") else (set "CS=ControlSet0!N!")
>>"%R%\RUN_DETAILS.txt" echo active_control_set=!CS!
>>"%R%\RUN_DETAILS.txt" echo [CURRENT_RDYBOOST_SERVICE_FULL]
"%REG%" query "HKLM\RMAISYS49\!CS!\Services\rdyboost" /s >>"%R%\RUN_DETAILS.txt" 2>&1
"%REG%" unload HKLM\RMAISYS49 >nul 2>&1

>>"%R%\RUN_DETAILS.txt" echo [DRIVERS_HIVE_DRIVER_DATABASE]
if exist "%DRV%" (
  "%REG%" unload HKLM\RMAIDRV49 >nul 2>&1
  "%REG%" load HKLM\RMAIDRV49 "%DRV%" >nul 2>&1
  if not errorlevel 1 (
    >>"%R%\RUN_DETAILS.txt" echo -- DriverInfFiles search rdyboost --
    "%REG%" query "HKLM\RMAIDRV49\DriverDatabase\DriverInfFiles" /s /f "rdyboost" >>"%R%\RUN_DETAILS.txt" 2>&1
    >>"%R%\RUN_DETAILS.txt" echo -- DriverPackages search rdyboost --
    "%REG%" query "HKLM\RMAIDRV49\DriverDatabase\DriverPackages" /s /f "rdyboost" >>"%R%\RUN_DETAILS.txt" 2>&1
    "%REG%" unload HKLM\RMAIDRV49 >nul 2>&1
  ) else (
    >>"%R%\RUN_DETAILS.txt" echo drivers_hive_load=FAILED
  )
) else (
  >>"%R%\RUN_DETAILS.txt" echo drivers_hive=MISSING
)

>>"%R%\RUN_DETAILS.txt" echo [INF_CONTENT_DISCOVERY]
set /a INFCOUNT=0
for /f "delims=" %%I in ('"%FS%" /s /i /m /c:"rdyboost.sys" C:\Windows\INF\*.inf 2^>nul') do (
  set /a INFCOUNT+=1
  if !INFCOUNT! LEQ 3 (
    >>"%R%\RUN_DETAILS.txt" echo inf_match=%%I
    "%FS%" /i /n /c:"rdyboost" /c:"AddService" /c:"StartType" /c:"ServiceType" /c:"ErrorControl" /c:"LoadOrderGroup" /c:"ServiceBinary" "%%I" >>"%R%\RUN_DETAILS.txt" 2>&1
  )
)
if !INFCOUNT! EQU 0 >>"%R%\RUN_DETAILS.txt" echo inf_content_match=NONE

>>"%R%\RUN_DETAILS.txt" echo [DRIVERSTORE_CONTENT_DISCOVERY]
set /a DSCOUNT=0
for /f "delims=" %%I in ('"%FS%" /s /i /m /c:"rdyboost.sys" C:\Windows\System32\DriverStore\FileRepository\*.inf 2^>nul') do (
  set /a DSCOUNT+=1
  if !DSCOUNT! LEQ 3 (
    >>"%R%\RUN_DETAILS.txt" echo driverstore_inf_match=%%I
    "%FS%" /i /n /c:"rdyboost" /c:"AddService" /c:"StartType" /c:"ServiceType" /c:"ErrorControl" /c:"LoadOrderGroup" /c:"ServiceBinary" "%%I" >>"%R%\RUN_DETAILS.txt" 2>&1
  )
)
if !DSCOUNT! EQU 0 >>"%R%\RUN_DETAILS.txt" echo driverstore_content_match=NONE

>>"%R%\RUN_DETAILS.txt" echo [RDYBOOST_FILE]
if exist C:\Windows\System32\drivers\rdyboost.sys (
  dir /a:-d C:\Windows\System32\drivers\rdyboost.sys >>"%R%\RUN_DETAILS.txt" 2>&1
  "%CERT%" -hashfile C:\Windows\System32\drivers\rdyboost.sys SHA256 >>"%R%\RUN_DETAILS.txt" 2>&1
) else (
  >>"%R%\RUN_DETAILS.txt" echo rdyboost.sys=MISSING
)

call "%A%" upload >nul 2>&1
if errorlevel 1 goto :UPLOADFAIL
>"%O%" echo STATUS=PASS
>>"%O%" echo MESSAGE=RescueMeAI discovered the installed ReadyBoost driver-package ownership metadata for comparison with the current boot filter configuration.
>>"%O%" echo EVIDENCE=Private report contains DRIVERS-hive package mappings, INF content matches, DriverStore matches, current service values, and rdyboost.sys metadata.
>>"%O%" echo INSTRUCTION=No user action is required. Leave RescueMeAI online; do not reboot yet.
exit /b 0

:UPLOADFAIL
>"%O%" echo STATUS=WARNING
>>"%O%" echo MESSAGE=ReadyBoost package discovery completed locally but private upload failed.
>>"%O%" echo EVIDENCE=No Windows changes were made.
>>"%O%" echo INSTRUCTION=Leave RescueMeAI online; do not reboot.
exit /b 20

:BAD
"%REG%" unload HKLM\RMAISYS49 >nul 2>&1
"%REG%" unload HKLM\RMAIDRV49 >nul 2>&1
>"%O%" echo STATUS=FAIL
>>"%O%" echo MESSAGE=RescueMeAI could not inspect ReadyBoost package ownership metadata.
>>"%O%" echo EVIDENCE=No Windows changes were made.
>>"%O%" echo INSTRUCTION=Leave RescueMeAI online; do not reboot.
exit /b 90
