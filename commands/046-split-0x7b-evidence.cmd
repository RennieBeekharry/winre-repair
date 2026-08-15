@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=READ_ONLY
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Recollect the decisive post-BCD 0x7B storage evidence and upload it in small independent reports below the RescueMeAI 6000-byte report limit.
rem WR_ACTION=SPLIT_POST_BCD_0X7B_EVIDENCE
rem WR_TARGET=Offline SYSTEM hive and boot-critical driver-file presence only.
rem WR_CONSEQUENCE=Read-only diagnostic. No registry values, drivers, boot files, partitions, or personal files are changed.
rem WR_ROLLBACK=No rollback required; read-only.

set "R=C:\WinRERepair"
set "O=%R%\COMMAND_RESULT.env"
set "A=%R%\runtime\github-auth.cmd"
set "REG=C:\Windows\System32\reg.exe"
set "SYS=C:\Windows\System32\config\SYSTEM"
if not exist "%REG%" set "REG=reg.exe"
if not exist "%SYS%" goto :BAD

"%REG%" unload HKLM\RMAISYS46 >nul 2>&1
"%REG%" load HKLM\RMAISYS46 "%SYS%" >nul 2>&1
if errorlevel 1 goto :BAD
set "N="
for /f "tokens=3" %%V in ('"%REG%" query HKLM\RMAISYS46\Select /v Current 2^>nul ^| findstr /i "Current"') do set /a N=%%V
if not defined N set "N=1"
if !N! LSS 10 (set "CS=ControlSet00!N!") else (set "CS=ControlSet0!N!")

rem PART 1: Microsoft-required and core boot-storage service starts.
>"%R%\LAST_RUN_REPORT.txt" echo status=PASS
>>"%R%\LAST_RUN_REPORT.txt" echo message=Command 46 part 1 of 4: boot-critical service starts.
>"%R%\RUN_DETAILS.txt" echo diagnostic=SPLIT_0X7B_PART_1_BOOT_SERVICES
>>"%R%\RUN_DETAILS.txt" echo windows_changes=NONE
>>"%R%\RUN_DETAILS.txt" echo active_control_set=!CS!
for %%S in (ACPI disk volmgr partmgr volsnap volume iaStorA iaStorAC storahci EhStorClass mountmgr fvevol spaceport) do (
  >>"%R%\RUN_DETAILS.txt" echo [%%S]
  "%REG%" query "HKLM\RMAISYS46\!CS!\Services\%%S" /v Start >>"%R%\RUN_DETAILS.txt" 2>&1
  "%REG%" query "HKLM\RMAISYS46\!CS!\Services\%%S\StartOverride" /v 0 >>"%R%\RUN_DETAILS.txt" 2>&1
)
call "%A%" upload >nul 2>&1
if errorlevel 1 goto :UPLOADFAIL

rem PART 2: Intel controller binding and class instance.
>"%R%\LAST_RUN_REPORT.txt" echo status=PASS
>>"%R%\LAST_RUN_REPORT.txt" echo message=Command 46 part 2 of 4: Intel A102 controller binding and class instance.
>"%R%\RUN_DETAILS.txt" echo diagnostic=SPLIT_0X7B_PART_2_INTEL_CONTROLLER
set "DEV=HKLM\RMAISYS46\!CS!\Enum\PCI\VEN_8086&DEV_A102&SUBSYS_2B45103C&REV_31\3&11583659&0&B8"
for %%V in (Service Driver ClassGUID ConfigFlags Problem) do "%REG%" query "!DEV!" /v %%V >>"%R%\RUN_DETAILS.txt" 2>&1
set "CI=HKLM\RMAISYS46\!CS!\Control\Class\{4d36e96a-e325-11ce-bfc1-08002be10318}\0000"
for %%V in (DriverDesc ProviderName DriverDate DriverVersion InfPath InfSection MatchingDeviceId Service UpperFilters LowerFilters) do "%REG%" query "!CI!" /v %%V >>"%R%\RUN_DETAILS.txt" 2>&1
call "%A%" upload >nul 2>&1
if errorlevel 1 goto :UPLOADFAIL

rem PART 3: storage class filters and pending rename state.
>"%R%\LAST_RUN_REPORT.txt" echo status=PASS
>>"%R%\LAST_RUN_REPORT.txt" echo message=Command 46 part 3 of 4: storage filters and pending rename state.
>"%R%\RUN_DETAILS.txt" echo diagnostic=SPLIT_0X7B_PART_3_FILTERS_PENDING
for %%G in ({4d36e96a-e325-11ce-bfc1-08002be10318} {4d36e967-e325-11ce-bfc1-08002be10318} {4d36e97b-e325-11ce-bfc1-08002be10318} {71a27cdd-812a-11d0-bec7-08002be2092f}) do (
  >>"%R%\RUN_DETAILS.txt" echo [%%G]
  "%REG%" query "HKLM\RMAISYS46\!CS!\Control\Class\%%G" /v UpperFilters >>"%R%\RUN_DETAILS.txt" 2>&1
  "%REG%" query "HKLM\RMAISYS46\!CS!\Control\Class\%%G" /v LowerFilters >>"%R%\RUN_DETAILS.txt" 2>&1
)
>>"%R%\RUN_DETAILS.txt" echo [PENDING_FILE_RENAMES]
"%REG%" query "HKLM\RMAISYS46\!CS!\Control\Session Manager" /v PendingFileRenameOperations >>"%R%\RUN_DETAILS.txt" 2>&1
call "%A%" upload >nul 2>&1
if errorlevel 1 goto :UPLOADFAIL

"%REG%" unload HKLM\RMAISYS46 >nul 2>&1

rem PART 4: required driver-file presence only.
>"%R%\LAST_RUN_REPORT.txt" echo status=PASS
>>"%R%\LAST_RUN_REPORT.txt" echo message=Command 46 part 4 of 4: boot-critical driver-file presence.
>"%R%\RUN_DETAILS.txt" echo diagnostic=SPLIT_0X7B_PART_4_DRIVER_FILES
for %%F in (iaStorA.sys iaStorAC.sys storahci.sys storport.sys disk.sys partmgr.sys volmgr.sys volsnap.sys volume.sys classpnp.sys EhStorClass.sys mountmgr.sys fvevol.sys spaceport.sys) do (
  if exist "C:\Windows\System32\drivers\%%F" (
    >>"%R%\RUN_DETAILS.txt" echo %%F=PRESENT
  ) else (
    >>"%R%\RUN_DETAILS.txt" echo %%F=MISSING
  )
)
call "%A%" upload >nul 2>&1
if errorlevel 1 goto :UPLOADFAIL

>"%O%" echo STATUS=PASS
>>"%O%" echo MESSAGE=RescueMeAI uploaded the decisive 0x7B evidence as four upload-safe private reports.
>>"%O%" echo EVIDENCE=Boot services, Intel controller binding, storage filters/pending state, and boot driver-file presence were uploaded separately.
>>"%O%" echo INSTRUCTION=No user action is required. Leave RescueMeAI online; do not reboot yet.
exit /b 0

:UPLOADFAIL
"%REG%" unload HKLM\RMAISYS46 >nul 2>&1
>"%O%" echo STATUS=WARNING
>>"%O%" echo MESSAGE=Command 46 collected evidence but one split private upload failed.
>>"%O%" echo EVIDENCE=No Windows changes were made.
>>"%O%" echo INSTRUCTION=Leave RescueMeAI online; do not reboot.
exit /b 20

:BAD
"%REG%" unload HKLM\RMAISYS46 >nul 2>&1
>"%O%" echo STATUS=FAIL
>>"%O%" echo MESSAGE=Command 46 could not inspect the offline storage state.
>>"%O%" echo EVIDENCE=No Windows changes were made.
>>"%O%" echo INSTRUCTION=Leave RescueMeAI online; do not reboot.
exit /b 90
