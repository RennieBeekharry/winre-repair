@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=READ_ONLY
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Compress command 44 into a small decisive 0x7B storage-state report that can be uploaded reliably.
rem WR_ACTION=COMPACT_POST_BCD_0X7B_EVIDENCE
rem WR_TARGET=Offline SYSTEM hive and presence of boot-critical storage driver files only.
rem WR_CONSEQUENCE=Read-only diagnostic. No registry values, drivers, boot files, partitions, or personal files are changed.
rem WR_ROLLBACK=No rollback required; read-only.

set "R=C:\WinRERepair"
set "O=%R%\COMMAND_RESULT.env"
set "A=%R%\runtime\github-auth.cmd"
set "Q=%R%\diag45-compact-post-bcd-0x7b.txt"
set "REG=C:\Windows\System32\reg.exe"
set "SYS=C:\Windows\System32\config\SYSTEM"
if not exist "%REG%" set "REG=reg.exe"
if not exist "%SYS%" goto :BAD

>"%Q%" echo RESCUEMEAI COMMAND 45 - COMPACT POST-BCD 0x7B EVIDENCE
>>"%Q%" echo windows_changes=NONE
>>"%Q%" echo prior_command_44=PASS_BUT_FULL_DETAILS_EXCEEDED_UPLOAD_LIMIT

"%REG%" unload HKLM\RMAISYS45 >nul 2>&1
"%REG%" load HKLM\RMAISYS45 "%SYS%" >>"%Q%" 2>&1
if errorlevel 1 goto :BAD

set "N="
for /f "tokens=3" %%V in ('"%REG%" query HKLM\RMAISYS45\Select /v Current 2^>nul ^| findstr /i "Current"') do set /a N=%%V
if not defined N set "N=1"
if !N! LSS 10 (set "CS=ControlSet00!N!") else (set "CS=ControlSet0!N!")

>>"%Q%" echo ACTIVE_CONTROL_SET=!CS!
>>"%Q%" echo [BOOT_CRITICAL_START_VALUES]
for %%S in (ACPI disk volmgr partmgr volsnap volume iaStorA iaStorAC storahci EhStorClass mountmgr fvevol spaceport) do (
  >>"%Q%" echo --- %%S ---
  "%REG%" query "HKLM\RMAISYS45\!CS!\Services\%%S" /v Start >>"%Q%" 2>&1
  "%REG%" query "HKLM\RMAISYS45\!CS!\Services\%%S" /v Group >>"%Q%" 2>&1
  "%REG%" query "HKLM\RMAISYS45\!CS!\Services\%%S" /v ImagePath >>"%Q%" 2>&1
  "%REG%" query "HKLM\RMAISYS45\!CS!\Services\%%S\StartOverride" /v 0 >>"%Q%" 2>&1
)

>>"%Q%" echo [INTEL_A102_CONTROLLER]
set "DEV=HKLM\RMAISYS45\!CS!\Enum\PCI\VEN_8086&DEV_A102&SUBSYS_2B45103C&REV_31\3&11583659&0&B8"
for %%V in (Service Driver ClassGUID ConfigFlags Problem) do "%REG%" query "!DEV!" /v %%V >>"%Q%" 2>&1

>>"%Q%" echo [INTEL_CONTROLLER_CLASS_INSTANCE]
set "CI=HKLM\RMAISYS45\!CS!\Control\Class\{4d36e96a-e325-11ce-bfc1-08002be10318}\0000"
for %%V in (DriverDesc ProviderName DriverDate DriverVersion InfPath InfSection MatchingDeviceId Service UpperFilters LowerFilters) do "%REG%" query "!CI!" /v %%V >>"%Q%" 2>&1

>>"%Q%" echo [STORAGE_CLASS_FILTERS]
for %%G in ({4d36e96a-e325-11ce-bfc1-08002be10318} {4d36e967-e325-11ce-bfc1-08002be10318} {4d36e97b-e325-11ce-bfc1-08002be10318} {71a27cdd-812a-11d0-bec7-08002be2092f}) do (
  >>"%Q%" echo --- %%G ---
  "%REG%" query "HKLM\RMAISYS45\!CS!\Control\Class\%%G" /v UpperFilters >>"%Q%" 2>&1
  "%REG%" query "HKLM\RMAISYS45\!CS!\Control\Class\%%G" /v LowerFilters >>"%Q%" 2>&1
)

>>"%Q%" echo [PENDING_FILE_RENAMES]
"%REG%" query "HKLM\RMAISYS45\!CS!\Control\Session Manager" /v PendingFileRenameOperations >>"%Q%" 2>&1

"%REG%" unload HKLM\RMAISYS45 >>"%Q%" 2>&1

>>"%Q%" echo [BOOT_DRIVER_FILE_PRESENCE]
for %%F in (iaStorA.sys iaStorAC.sys storahci.sys disk.sys partmgr.sys volmgr.sys volsnap.sys volume.sys classpnp.sys EhStorClass.sys mountmgr.sys fvevol.sys) do (
  if exist "C:\Windows\System32\drivers\%%F" (
    >>"%Q%" echo %%F=PRESENT
  ) else (
    >>"%Q%" echo %%F=MISSING
  )
)

>"%R%\LAST_RUN_REPORT.txt" echo status=PASS
>>"%R%\LAST_RUN_REPORT.txt" echo message=Compact post-BCD 0x7B evidence collected for reliable upload.
>"%R%\RUN_DETAILS.txt" echo diagnostic=COMPACT_POST_BCD_0X7B
>>"%R%\RUN_DETAILS.txt" echo windows_changes=NONE
type "%Q%" >>"%R%\RUN_DETAILS.txt"

if exist "%A%" call "%A%" upload >nul 2>&1
if errorlevel 1 goto :UPLOADFAIL

>"%O%" echo STATUS=PASS
>>"%O%" echo MESSAGE=RescueMeAI uploaded a compact decisive 0x7B storage-state report.
>>"%O%" echo EVIDENCE=Boot-critical service starts, Intel A102 binding/class instance, filters, pending renames, and driver-file presence were uploaded.
>>"%O%" echo INSTRUCTION=No user relay is required. Leave RescueMeAI online; do not reboot yet.
exit /b 0

:UPLOADFAIL
>"%O%" echo STATUS=WARNING
>>"%O%" echo MESSAGE=Compact 0x7B evidence was collected locally but upload failed.
>>"%O%" echo EVIDENCE=C:\WinRERepair\RUN_DETAILS.txt
>>"%O%" echo INSTRUCTION=Leave RescueMeAI online; do not reboot.
exit /b 20

:BAD
"%REG%" unload HKLM\RMAISYS45 >nul 2>&1
>"%O%" echo STATUS=FAIL
>>"%O%" echo MESSAGE=Compact post-BCD 0x7B evidence collection failed.
>>"%O%" echo EVIDENCE=No Windows changes were made.
>>"%O%" echo INSTRUCTION=Leave RescueMeAI online; do not reboot.
exit /b 90
