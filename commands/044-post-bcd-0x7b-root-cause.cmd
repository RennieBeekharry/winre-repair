@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=READ_ONLY
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Collect the remaining Microsoft-defined boot-critical storage service, volume stack, filter, controller-enumeration, and recent driver-install evidence after the verified BCD rebuild still produced INACCESSIBLE_BOOT_DEVICE.
rem WR_ACTION=POST_BCD_0X7B_ROOT_CAUSE_DIAGNOSTIC
rem WR_TARGET=Offline Windows SYSTEM hive, boot-critical driver files, and SetupAPI device-install log only.
rem WR_CONSEQUENCE=Read-only diagnostic. No registry values, boot files, drivers, partitions, or personal files are changed.
rem WR_ROLLBACK=No rollback is required because this command does not modify Windows recovery state.

set "R=C:\WinRERepair"
set "O=%R%\COMMAND_RESULT.env"
set "A=%R%\runtime\github-auth.cmd"
set "Q=%R%\diag44-post-bcd-0x7b.txt"
set "REG=C:\Windows\System32\reg.exe"
set "FS=C:\Windows\System32\findstr.exe"
set "CERT=C:\Windows\System32\certutil.exe"
set "SYS=C:\Windows\System32\config\SYSTEM"
set "SETUP=C:\Windows\INF\setupapi.dev.log"
if not exist "%REG%" set "REG=reg.exe"
if not exist "%FS%" set "FS=findstr.exe"
if not exist "%CERT%" set "CERT=certutil.exe"

if not exist "%SYS%" goto :BAD

>"%Q%" echo RESCUEMEAI COMMAND 44 - POST-BCD 0x7B ROOT-CAUSE DIAGNOSTIC
>>"%Q%" echo windows_changes=NONE
>>"%Q%" echo confirmed_prior_state=Fresh UEFI BCD verified by command 40; boot test still returned INACCESSIBLE_BOOT_DEVICE 0x7B.
>>"%Q%" echo.

"%REG%" unload HKLM\RMAISYS44 >nul 2>&1
"%REG%" load HKLM\RMAISYS44 "%SYS%" >>"%Q%" 2>&1
if errorlevel 1 goto :BAD

set "N="
for /f "tokens=3" %%V in ('"%REG%" query HKLM\RMAISYS44\Select /v Current 2^>nul ^| "%FS%" /i "Current"') do set /a N=%%V
if not defined N set "N=1"
if !N! LSS 10 (set "CS=ControlSet00!N!") else (set "CS=ControlSet0!N!")

>>"%Q%" echo [SELECT]
"%REG%" query HKLM\RMAISYS44\Select >>"%Q%" 2>&1
>>"%Q%" echo ACTIVE_CONTROL_SET=!CS!
>>"%Q%" echo.

>>"%Q%" echo [MICROSOFT_BOOT_CRITICAL_SERVICES]
for %%S in (ACPI disk volmgr partmgr volsnap volume) do (
  >>"%Q%" echo --- %%S ---
  "%REG%" query "HKLM\RMAISYS44\!CS!\Services\%%S" /v Start >>"%Q%" 2>&1
  "%REG%" query "HKLM\RMAISYS44\!CS!\Services\%%S" /v Group >>"%Q%" 2>&1
  "%REG%" query "HKLM\RMAISYS44\!CS!\Services\%%S" /v ImagePath >>"%Q%" 2>&1
)
>>"%Q%" echo.

>>"%Q%" echo [STORAGE_STACK_SERVICES]
for %%S in (iaStorA iaStorAC storahci storport classpnp EhStorClass mountmgr volmgrx fvevol spaceport) do (
  >>"%Q%" echo --- %%S ---
  "%REG%" query "HKLM\RMAISYS44\!CS!\Services\%%S" /v Start >>"%Q%" 2>&1
  "%REG%" query "HKLM\RMAISYS44\!CS!\Services\%%S" /v Group >>"%Q%" 2>&1
  "%REG%" query "HKLM\RMAISYS44\!CS!\Services\%%S" /v ImagePath >>"%Q%" 2>&1
  "%REG%" query "HKLM\RMAISYS44\!CS!\Services\%%S" /v ErrorControl >>"%Q%" 2>&1
  "%REG%" query "HKLM\RMAISYS44\!CS!\Services\%%S\StartOverride" /v 0 >>"%Q%" 2>&1
)
>>"%Q%" echo.

>>"%Q%" echo [INTEL_CONTROLLER_ENUMERATION]
set "DEV=HKLM\RMAISYS44\!CS!\Enum\PCI\VEN_8086&DEV_A102&SUBSYS_2B45103C&REV_31\3&11583659&0&B8"
"%REG%" query "!DEV!" /s >>"%Q%" 2>&1
>>"%Q%" echo.

>>"%Q%" echo [INTEL_CONTROLLER_CLASS_INSTANCE]
"%REG%" query "HKLM\RMAISYS44\!CS!\Control\Class\{4d36e96a-e325-11ce-bfc1-08002be10318}\0000" /s >>"%Q%" 2>&1
>>"%Q%" echo.

>>"%Q%" echo [CRITICAL_DEVICE_DATABASE_A102]
"%REG%" query "HKLM\RMAISYS44\!CS!\Control\CriticalDeviceDatabase" /s /f "VEN_8086&DEV_A102" >>"%Q%" 2>&1
>>"%Q%" echo.

>>"%Q%" echo [SERVICE_GROUP_ORDER]
"%REG%" query "HKLM\RMAISYS44\!CS!\Control\ServiceGroupOrder" /v List >>"%Q%" 2>&1
>>"%Q%" echo [SCSI_MINIPORT_GROUP_ORDER]
"%REG%" query "HKLM\RMAISYS44\!CS!\Control\GroupOrderList" /v "SCSI miniport" >>"%Q%" 2>&1
>>"%Q%" echo.

>>"%Q%" echo [TARGETED_STORAGE_CLASS_FILTERS]
for %%G in ({4d36e96a-e325-11ce-bfc1-08002be10318} {4d36e967-e325-11ce-bfc1-08002be10318} {4d36e97b-e325-11ce-bfc1-08002be10318} {71a27cdd-812a-11d0-bec7-08002be2092f}) do (
  >>"%Q%" echo --- %%G ---
  "%REG%" query "HKLM\RMAISYS44\!CS!\Control\Class\%%G" /v UpperFilters >>"%Q%" 2>&1
  "%REG%" query "HKLM\RMAISYS44\!CS!\Control\Class\%%G" /v LowerFilters >>"%Q%" 2>&1
)
>>"%Q%" echo.

>>"%Q%" echo [SESSION_MANAGER_PENDING_FILE_RENAMES]
"%REG%" query "HKLM\RMAISYS44\!CS!\Control\Session Manager" /v PendingFileRenameOperations >>"%Q%" 2>&1
>>"%Q%" echo.

"%REG%" unload HKLM\RMAISYS44 >>"%Q%" 2>&1

>>"%Q%" echo.
>>"%Q%" echo [BOOT_CRITICAL_DRIVER_FILES]
for %%F in (iaStorA.sys iaStorAC.sys storahci.sys storport.sys disk.sys partmgr.sys volmgr.sys volsnap.sys volume.sys classpnp.sys EhStorClass.sys mountmgr.sys volmgrx.sys) do (
  if exist "C:\Windows\System32\drivers\%%F" (
    >>"%Q%" echo --- %%F PRESENT ---
    dir /a:-d "C:\Windows\System32\drivers\%%F" >>"%Q%" 2>&1
    "%CERT%" -hashfile "C:\Windows\System32\drivers\%%F" SHA256 >>"%Q%" 2>&1
  ) else (
    >>"%Q%" echo --- %%F MISSING ---
  )
)
>>"%Q%" echo.

>>"%Q%" echo [SETUPAPI_STORAGE_HISTORY]
if exist "%SETUP%" (
  "%FS%" /i /n /c:"VEN_8086&DEV_A102" /c:"iaStorA" /c:"iaStorAC" /c:"storahci" /c:"EhStorClass" "%SETUP%" >>"%Q%" 2>&1
) else (
  >>"%Q%" echo setupapi.dev.log=MISSING
)
>>"%Q%" echo.

> "%R%\LAST_RUN_REPORT.txt" echo status=PASS
>>"%R%\LAST_RUN_REPORT.txt" echo message=Post-BCD 0x7B root-cause evidence collected without changing Windows.
> "%R%\RUN_DETAILS.txt" echo diagnostic=POST_BCD_0X7B_ROOT_CAUSE
>>"%R%\RUN_DETAILS.txt" echo windows_changes=NONE
type "%Q%" >>"%R%\RUN_DETAILS.txt"
if exist "%A%" call "%A%" upload >nul 2>&1

>"%O%" echo STATUS=PASS
>>"%O%" echo MESSAGE=RescueMeAI collected the remaining boot-critical storage and volume-stack evidence after the verified BCD boot test still returned 0x7B.
>>"%O%" echo EVIDENCE=Private report includes Microsoft-required boot services, controller enumeration, service/group ordering, filters, driver files and hashes, and SetupAPI storage history.
>>"%O%" echo INSTRUCTION=No user relay is required. Leave RescueMeAI online; do not reboot yet.
exit /b 0

:BAD
"%REG%" unload HKLM\RMAISYS44 >nul 2>&1
>"%O%" echo STATUS=FAIL
>>"%O%" echo MESSAGE=Post-BCD 0x7B evidence collection could not complete.
>>"%O%" echo EVIDENCE=No Windows changes were made.
>>"%O%" echo INSTRUCTION=Leave RescueMeAI online for review; do not reboot.
exit /b 90
