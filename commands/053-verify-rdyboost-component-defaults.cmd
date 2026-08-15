@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=READ_ONLY
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Compare the current ReadyBoost boot-filter registry state against alternate control sets, WinSxS component manifests/copies, SFC protection, and CBS evidence after command 52 found no exact UUP image.
rem WR_ACTION=VERIFY_RDYBOOST_COMPONENT_DEFAULTS
rem WR_TARGET=Offline SYSTEM registry hive, WinSxS manifests/files, SFC verification, CBS log, and private recovery evidence only.
rem WR_CONSEQUENCE=Read-only verification. No registry values, driver files, packages, boot files, partitions, or personal files are changed.
rem WR_ROLLBACK=No rollback required; read-only.

set "R=C:\WinRERepair"
set "O=%R%\COMMAND_RESULT.env"
set "A=%R%\runtime\github-auth.cmd"
set "UI=%R%\runtime\ui.cmd"
set "REG=C:\Windows\System32\reg.exe"
set "FS=C:\Windows\System32\findstr.exe"
set "CERT=C:\Windows\System32\certutil.exe"
set "SFC=X:\Windows\System32\sfc.exe"
set "SYS=C:\Windows\System32\config\SYSTEM"
set "Q=%R%\diag53-rdyboost-defaults.txt"
set "SFCLOG=%R%\diag53-rdyboost-sfc.txt"
set "MATCH=%R%\diag53-rdyboost-manifests.txt"
if not exist "%REG%" set "REG=reg.exe"
if not exist "%FS%" set "FS=findstr.exe"
if not exist "%CERT%" set "CERT=certutil.exe"
if not exist "%SFC%" set "SFC=sfc.exe"
if not exist "%SYS%" goto :BAD

call :STAGE "1 of 5" "Comparing ReadyBoost service configuration across every offline Windows control set."
"%REG%" unload HKLM\RMAISYS53 >nul 2>&1
"%REG%" load HKLM\RMAISYS53 "%SYS%" >nul 2>&1
if errorlevel 1 goto :BAD

>"%Q%" echo RESCUEMEAI COMMAND 53 - READYBOOST COMPONENT DEFAULT VERIFICATION
>>"%Q%" echo windows_changes=NONE
>>"%Q%" echo [CONTROL_SET_SELECTOR]
"%REG%" query HKLM\RMAISYS53\Select >>"%Q%" 2>&1
for %%S in (ControlSet001 ControlSet002 ControlSet003 ControlSet004) do (
  "%REG%" query "HKLM\RMAISYS53\%%S\Services\rdyboost" /v Start >nul 2>&1
  if not errorlevel 1 (
    >>"%Q%" echo [%%S_RDYBOOST]
    for %%V in (Start Type ErrorControl Group ImagePath DisplayName Description) do "%REG%" query "HKLM\RMAISYS53\%%S\Services\rdyboost" /v %%V >>"%Q%" 2>&1
    >>"%Q%" echo [%%S_VOLUME_FILTERS]
    "%REG%" query "HKLM\RMAISYS53\%%S\Control\Class\{71A27CDD-812A-11D0-BEC7-08002BE2092F}" /v UpperFilters >>"%Q%" 2>&1
    "%REG%" query "HKLM\RMAISYS53\%%S\Control\Class\{71A27CDD-812A-11D0-BEC7-08002BE2092F}" /v LowerFilters >>"%Q%" 2>&1
  )
)
"%REG%" unload HKLM\RMAISYS53 >nul 2>&1

call :STAGE "2 of 5" "Finding Windows component-store manifests and protected copies that define or carry rdyboost.sys."
>>"%Q%" echo [WINSXS_RDYBOOST_FILES]
dir /s /b C:\Windows\WinSxS\rdyboost.sys >>"%Q%" 2>&1
for /f "delims=" %%F in ('dir /s /b C:\Windows\WinSxS\rdyboost.sys 2^>nul') do (
  >>"%Q%" echo FILE=%%F
  "%CERT%" -hashfile "%%F" SHA256 >>"%Q%" 2>&1
)
>"%MATCH%" ("%FS%" /s /i /m /c:"rdyboost" C:\Windows\WinSxS\Manifests\*.manifest 2>nul)
>>"%Q%" echo [WINSXS_MANIFEST_MATCHES]
if exist "%MATCH%" (
  for /f "usebackq delims=" %%M in ("%MATCH%") do (
    >>"%Q%" echo MANIFEST=%%M
    "%FS%" /i /c:"rdyboost" /c:"PnP Filter" /c:"start=" /c:"Start" "%%M" >>"%Q%" 2>&1
  )
) else (
  >>"%Q%" echo manifest_match_file=ABSENT
)

call :STAGE "3 of 5" "Verifying the live ReadyBoost driver as a protected Windows file."
>>"%Q%" echo [LIVE_RDYBOOST_FILE]
if exist C:\Windows\System32\drivers\rdyboost.sys (
  dir C:\Windows\System32\drivers\rdyboost.sys >>"%Q%" 2>&1
  "%CERT%" -hashfile C:\Windows\System32\drivers\rdyboost.sys SHA256 >>"%Q%" 2>&1
  "%SFC%" /verifyfile=C:\Windows\System32\drivers\rdyboost.sys /offbootdir=C:\ /offwindir=C:\Windows /offlogfile="%SFCLOG%" >nul 2>&1
  >>"%Q%" echo sfc_verify_return_code=!errorlevel!
) else (
  >>"%Q%" echo live_rdyboost=MISSING
)

call :STAGE "4 of 5" "Checking CBS servicing evidence for ReadyBoost ownership or repair activity."
>>"%Q%" echo [CBS_RDYBOOST_LINES]
if exist C:\Windows\Logs\CBS\CBS.log (
  "%FS%" /i /c:"rdyboost" C:\Windows\Logs\CBS\CBS.log >>"%Q%" 2>&1
) else (
  >>"%Q%" echo cbs_log=ABSENT
)
>>"%Q%" echo [REGISTRY_BACKUP_AVAILABILITY]
if exist C:\Windows\System32\config\RegBack\SYSTEM (
  for %%Z in (C:\Windows\System32\config\RegBack\SYSTEM) do >>"%Q%" echo regback_system_bytes=%%~zZ
) else (
  >>"%Q%" echo regback_system=ABSENT
)

call :STAGE "5 of 5" "Uploading the ReadyBoost default-state comparison for AI review."
>"%R%\LAST_RUN_REPORT.txt" echo status=PASS
>>"%R%\LAST_RUN_REPORT.txt" echo message=ReadyBoost service defaults and protected-component evidence were compared without changing Windows.
>"%R%\RUN_DETAILS.txt" echo diagnostic=VERIFY_RDYBOOST_COMPONENT_DEFAULTS
type "%Q%" >>"%R%\RUN_DETAILS.txt"
call "%A%" upload >nul 2>&1
if errorlevel 1 goto :UPLOADFAIL
>"%O%" echo STATUS=PASS
>>"%O%" echo MESSAGE=RescueMeAI compared the current ReadyBoost filter configuration with alternate control sets, WinSxS component evidence, protected-file verification, and CBS history.
>>"%O%" echo EVIDENCE=Private report contains control-set values, component-store manifests/copies, hashes, SFC verification result, and CBS ReadyBoost evidence.
>>"%O%" echo INSTRUCTION=No user action is required. Leave RescueMeAI online; do not reboot yet.
exit /b 0

:STAGE
if exist "%UI%" call "%UI%" screen "RMAI-AGENT-V2-2026.08.14-1508-ET" "CONNECTED" "RUNNING COMMAND 53" "READ ONLY" "AI-ASSISTED WINDOWS RECOVERY" "INFO"
echo.
echo RECOVERY ACTIVITY
echo ------------------------------------------------------------------------------------------------
echo Step %~1
echo %~2
echo.
echo No action is required. RescueMeAI is still working.
exit /b 0

:UPLOADFAIL
>"%O%" echo STATUS=WARNING
>>"%O%" echo MESSAGE=ReadyBoost component verification completed locally but private upload failed.
>>"%O%" echo EVIDENCE=No Windows changes were made.
>>"%O%" echo INSTRUCTION=Leave RescueMeAI online; do not reboot.
exit /b 20

:BAD
"%REG%" unload HKLM\RMAISYS53 >nul 2>&1
>"%O%" echo STATUS=FAIL
>>"%O%" echo MESSAGE=RescueMeAI could not initialize ReadyBoost component-default verification.
>>"%O%" echo EVIDENCE=No Windows changes were made.
>>"%O%" echo INSTRUCTION=Leave RescueMeAI online; do not reboot.
exit /b 90
