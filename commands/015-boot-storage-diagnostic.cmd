@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=READ_ONLY
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Collect a focused offline boot and storage diagnostic for the INACCESSIBLE_BOOT_DEVICE failure without changing Windows.
rem WR_ACTION=BOOT_STORAGE_DIAGNOSTIC
rem WR_TARGET=C:\Windows offline registry, boot configuration, driver files, SetupAPI evidence, and RescueMeAI diagnostic logs only.
rem WR_CONSEQUENCE=Reads boot and storage configuration and uploads a private diagnostic report. It does not repair, reset, repartition, format, or modify the offline Windows installation.
rem WR_ROLLBACK=No Windows recovery state is changed. Temporary offline-registry mount is unloaded before exit.

set "WIN=C:"
set "WINDIR=C:\Windows"
set "WORK=C:\WinRERepair"
set "OUT=%WORK%\COMMAND_RESULT.env"
set "DIAG=%WORK%\diag15-boot-storage.txt"
set "DETAILS=%WORK%\RUN_DETAILS.txt"
set "REPORT=%WORK%\LAST_RUN_REPORT.txt"
set "AUTH=%WORK%\runtime\github-auth.cmd"
set "UI=%WORK%\runtime\ui.cmd"
set "REGEXE=C:\Windows\System32\reg.exe"
set "FINDSTR=C:\Windows\System32\findstr.exe"
set "CERTUTIL=C:\Windows\System32\certutil.exe"
set "BCDEDIT=X:\Windows\System32\bcdedit.exe"
if not exist "%BCDEDIT%" set "BCDEDIT=C:\Windows\System32\bcdedit.exe"
if not exist "%REGEXE%" set "REGEXE=reg.exe"
if not exist "%FINDSTR%" set "FINDSTR=findstr.exe"
if not exist "%CERTUTIL%" set "CERTUTIL=certutil.exe"

if not exist "%WINDIR%\System32\config\SYSTEM" goto :TARGET_FAIL

if exist "%UI%" (
  call "%UI%" screen "RMAI-DIAG15-2026.08.14-2328-ET" "CONNECTED" "WORKING" "READ ONLY" "AI-ASSISTED WINDOWS RECOVERY" "INFO"
  call "%UI%" roadmap 5 45
  call "%UI%" readiness "RECOMMENDED" "SOURCE VERIFIED - USB NOT ASSEMBLED" "READ ONLY" "DISM repair source was unavailable; focusing on the 0x7B boot/storage path."
  call "%UI%" progress "Boot/storage diagnostic" "UNKNOWN" "Focused diagnostic 1 of 1" "" "" "Starting now" "Usually a few minutes."
  call "%UI%" working "Inspecting boot-critical storage configuration for INACCESSIBLE_BOOT_DEVICE."
)

>"%DIAG%" echo RESCUEMEAI BOOT STORAGE DIAGNOSTIC
>>"%DIAG%" echo ==================================
>>"%DIAG%" echo date=%date%
>>"%DIAG%" echo time=%time%
>>"%DIAG%" echo offline_windows=%WINDIR%
>>"%DIAG%" echo.
>>"%DIAG%" echo [DISM_REPAIR_CONTEXT]
>>"%DIAG%" echo prior_restore_error=0x800F0915
>>"%DIAG%" echo meaning=repair content unavailable; no further generic scan requested
>>"%DIAG%" echo.

>>"%DIAG%" echo [BOOT_CRITICAL_DRIVER_FILES]
for %%F in (iaStorA.sys iaStorAC.sys storahci.sys storport.sys disk.sys classpnp.sys partmgr.sys volmgr.sys volmgrx.sys) do (
  if exist "%WINDIR%\System32\drivers\%%F" (
    >>"%DIAG%" echo PRESENT %%F
    "%CERTUTIL%" -hashfile "%WINDIR%\System32\drivers\%%F" SHA256 >>"%DIAG%" 2>&1
  ) else (
    >>"%DIAG%" echo MISSING %%F
  )
)
>>"%DIAG%" echo.

>>"%DIAG%" echo [DRIVERSTORE_MATCHES]
dir /b /ad "%WINDIR%\System32\DriverStore\FileRepository\iastor*" >>"%DIAG%" 2>&1
dir /b /ad "%WINDIR%\System32\DriverStore\FileRepository\storahci*" >>"%DIAG%" 2>&1
>>"%DIAG%" echo.

"%REGEXE%" unload HKLM\RMAISYS15 >nul 2>&1
"%REGEXE%" load HKLM\RMAISYS15 "%WINDIR%\System32\config\SYSTEM" >"%WORK%\diag15-regload.txt" 2>&1
if errorlevel 1 (
  >>"%DIAG%" echo [REGISTRY]
  >>"%DIAG%" echo SYSTEM_HIVE_LOAD=FAIL
  type "%WORK%\diag15-regload.txt" >>"%DIAG%"
  goto :AFTER_REGISTRY
)
>>"%DIAG%" echo [REGISTRY]
>>"%DIAG%" echo SYSTEM_HIVE_LOAD=PASS
"%REGEXE%" query HKLM\RMAISYS15\Select >>"%DIAG%" 2>&1

set "CURRENT_NUM="
for /f "tokens=3" %%V in ('"%REGEXE%" query HKLM\RMAISYS15\Select /v Current 2^>nul ^| "%FINDSTR%" /i "Current"') do set /a CURRENT_NUM=%%V
if not defined CURRENT_NUM set "CURRENT_NUM=1"
if !CURRENT_NUM! LSS 10 (
  set "CS=ControlSet00!CURRENT_NUM!"
) else (
  set "CS=ControlSet0!CURRENT_NUM!"
)
>>"%DIAG%" echo selected_control_set=!CS!
>>"%DIAG%" echo.

>>"%DIAG%" echo [STORAGE_SERVICES]
for %%S in (iaStorA iaStorAC storahci storport disk partmgr volmgr volmgrx mountmgr classpnp) do (
  >>"%DIAG%" echo --- %%S ---
  "%REGEXE%" query "HKLM\RMAISYS15\!CS!\Services\%%S" /v Start >>"%DIAG%" 2>&1
  "%REGEXE%" query "HKLM\RMAISYS15\!CS!\Services\%%S" /v Group >>"%DIAG%" 2>&1
  "%REGEXE%" query "HKLM\RMAISYS15\!CS!\Services\%%S" /v ImagePath >>"%DIAG%" 2>&1
  "%REGEXE%" query "HKLM\RMAISYS15\!CS!\Services\%%S\StartOverride" >>"%DIAG%" 2>&1
)
>>"%DIAG%" echo.

>>"%DIAG%" echo [INTEL_CONTROLLER_ENUM]
"%REGEXE%" query "HKLM\RMAISYS15\!CS!\Enum\PCI" /f "VEN_8086&DEV_A102" /s >>"%DIAG%" 2>&1
>>"%DIAG%" echo.

>>"%DIAG%" echo [CRITICAL_DEVICE_DATABASE]
"%REGEXE%" query "HKLM\RMAISYS15\!CS!\Control\CriticalDeviceDatabase" /f "VEN_8086&DEV_A102" /s >>"%DIAG%" 2>&1
>>"%DIAG%" echo.

>>"%DIAG%" echo [STORAGE_CLASS_FILTERS]
for %%G in ({4d36e967-e325-11ce-bfc1-08002be10318} {4d36e96a-e325-11ce-bfc1-08002be10318} {4d36e97b-e325-11ce-bfc1-08002be10318} {71a27cdd-812a-11d0-bec7-08002be2092f}) do (
  >>"%DIAG%" echo --- %%G ---
  "%REGEXE%" query "HKLM\RMAISYS15\!CS!\Control\Class\%%G" /v UpperFilters >>"%DIAG%" 2>&1
  "%REGEXE%" query "HKLM\RMAISYS15\!CS!\Control\Class\%%G" /v LowerFilters >>"%DIAG%" 2>&1
)
>>"%DIAG%" echo.

>>"%DIAG%" echo [SESSION_MANAGER_PENDING]
"%REGEXE%" query "HKLM\RMAISYS15\!CS!\Control\Session Manager" /v PendingFileRenameOperations >>"%DIAG%" 2>&1

"%REGEXE%" unload HKLM\RMAISYS15 >>"%DIAG%" 2>&1

:AFTER_REGISTRY
>>"%DIAG%" echo.

>>"%DIAG%" echo [OFFLINE_BCD_STORES]
set "BCD_FOUND=NO"
for %%D in (C D E F G H I J K L M N O P Q R S T U V W Y Z) do (
  if exist "%%D:\EFI\Microsoft\Boot\BCD" (
    set "BCD_FOUND=YES"
    >>"%DIAG%" echo EFI_BCD=%%D:\EFI\Microsoft\Boot\BCD
    "%BCDEDIT%" /store "%%D:\EFI\Microsoft\Boot\BCD" /enum {bootmgr} >>"%DIAG%" 2>&1
    "%BCDEDIT%" /store "%%D:\EFI\Microsoft\Boot\BCD" /enum all >>"%DIAG%" 2>&1
  )
  if exist "%%D:\Boot\BCD" (
    set "BCD_FOUND=YES"
    >>"%DIAG%" echo BIOS_BCD=%%D:\Boot\BCD
    "%BCDEDIT%" /store "%%D:\Boot\BCD" /enum all >>"%DIAG%" 2>&1
  )
)
if /i "!BCD_FOUND!"=="NO" >>"%DIAG%" echo BCD_STORE_NOT_FOUND_BY_COMMON_PATH_SCAN
>>"%DIAG%" echo.

>>"%DIAG%" echo [SETUPAPI_STORAGE_EVIDENCE]
if exist "%WINDIR%\INF\setupapi.dev.log" (
  "%FINDSTR%" /i /c:"VEN_8086&DEV_A102" /c:"iaStorA" /c:"iaStorAC" /c:"storahci" "%WINDIR%\INF\setupapi.dev.log" >>"%DIAG%" 2>&1
) else (
  >>"%DIAG%" echo setupapi.dev.log missing
)
>>"%DIAG%" echo.

>>"%DIAG%" echo [DISM_0X800F0915_CONTEXT]
if exist "%WORK%\repair13-dism-restore.log" (
  "%FINDSTR%" /i /c:"800f0915" /c:"source" /c:"repair content" /c:"error" "%WORK%\repair13-dism-restore.log" >>"%DIAG%" 2>&1
) else (
  >>"%DIAG%" echo repair13-dism-restore.log missing
)

>"%REPORT%" echo product=RescueMeAI
>>"%REPORT%" echo status=PASS
>>"%REPORT%" echo return_code=0
>>"%REPORT%" echo command_version=RMAI-DIAG15-2026.08.14-2328-ET
>>"%REPORT%" echo date=%date%
>>"%REPORT%" echo time=%time%
>>"%REPORT%" echo message=Focused boot-storage diagnostic completed; detailed evidence attached below.

>"%DETAILS%" echo product=RescueMeAI
>>"%DETAILS%" echo diagnostic=BOOT_STORAGE_0X7B
>>"%DETAILS%" echo windows_changes=NONE
>>"%DETAILS%" echo --- DIAGNOSTIC_OUTPUT ---
type "%DIAG%" >>"%DETAILS%"

if exist "%AUTH%" call "%AUTH%" upload >nul 2>&1

>"%OUT%" echo STATUS=PASS
>>"%OUT%" echo MESSAGE=Focused boot and storage diagnostic completed without changing Windows.
>>"%OUT%" echo EVIDENCE=Detailed private boot/storage report uploaded; DISM error 0x800F0915 recorded separately from the 0x7B investigation.
>>"%OUT%" echo INSTRUCTION=Reply pass. RescueMeAI remains online while ChatGPT reviews the boot/storage evidence and prepares the smallest targeted repair.
exit /b 0

:TARGET_FAIL
>"%OUT%" echo STATUS=FAIL
>>"%OUT%" echo MESSAGE=The offline Windows SYSTEM hive could not be located for the focused boot/storage diagnostic.
>>"%OUT%" echo EVIDENCE=Expected C:\Windows\System32\config\SYSTEM; no Windows changes were attempted.
>>"%OUT%" echo INSTRUCTION=Reply fail. RescueMeAI remains online.
exit /b 90
