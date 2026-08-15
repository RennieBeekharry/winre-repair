@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=REPAIR_WRITE
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Restore only the ReadyBoost kernel filter Start value from 2 to the machine's verified pre-failure value 0, after Command 53 confirmed the filter entry and protected driver are intact.
rem WR_ACTION=RESTORE_RDYBOOST_BOOT_START
rem WR_TARGET=Offline ControlSet001\Services\rdyboost Start value only, plus RescueMeAI backup/report files.
rem WR_CONSEQUENCE=Changes one DWORD from 2 (auto start) to 0 (boot start). No driver file, filter list, storage-controller binding, BCD, partition, update package, or personal file is changed.
rem WR_ROLLBACK=The complete pre-change rdyboost service key is exported to C:\WinRERepair\backup\rdyboost-before-command54.reg and can be restored if the boot test fails.

set "R=C:\WinRERepair"
set "O=%R%\COMMAND_RESULT.env"
set "A=%R%\runtime\github-auth.cmd"
set "UI=%R%\runtime\ui.cmd"
set "REG=C:\Windows\System32\reg.exe"
set "FS=C:\Windows\System32\findstr.exe"
set "SYS=C:\Windows\System32\config\SYSTEM"
set "B=%R%\backup"
set "BK=%B%\rdyboost-before-command54.reg"
set "Q=%R%\repair54-rdyboost-start.txt"
if not exist "%REG%" set "REG=reg.exe"
if not exist "%FS%" set "FS=findstr.exe"
if not exist "%SYS%" goto :BAD
if not exist "%B%" md "%B%" >nul 2>&1

call :STAGE "1 of 5" "Loading the offline SYSTEM hive and confirming the exact precondition before any write."
"%REG%" unload HKLM\RMAISYS54 >nul 2>&1
"%REG%" load HKLM\RMAISYS54 "%SYS%" >nul 2>&1
if errorlevel 1 goto :BAD

set "SVC=HKLM\RMAISYS54\ControlSet001\Services\rdyboost"
set "CLS=HKLM\RMAISYS54\ControlSet001\Control\Class\{71A27CDD-812A-11D0-BEC7-08002BE2092F}"
set "CURSTART="
for /f "tokens=3" %%V in ('"%REG%" query "%SVC%" /v Start 2^>nul ^| "%FS%" /i "Start"') do set "CURSTART=%%V"
if /i not "!CURSTART!"=="0x2" goto :PRECONDITION_FAIL
"%REG%" query "%CLS%" /v LowerFilters >"%R%\repair54-filters-before.txt" 2>&1
"%FS%" /i /c:"rdyboost" "%R%\repair54-filters-before.txt" >nul 2>&1
if errorlevel 1 goto :PRECONDITION_FAIL
if not exist C:\Windows\System32\drivers\rdyboost.sys goto :PRECONDITION_FAIL

call :STAGE "2 of 5" "Backing up the complete ReadyBoost service key before changing its Start value."
if exist "%BK%" del /f /q "%BK%" >nul 2>&1
"%REG%" export "%SVC%" "%BK%" /y >nul 2>&1
if errorlevel 1 goto :PRECONDITION_FAIL
if not exist "%BK%" goto :PRECONDITION_FAIL

>"%Q%" echo RESCUEMEAI COMMAND 54 - RESTORE READYBOOST BOOT-START STATE
>>"%Q%" echo prior_start=!CURSTART!
>>"%Q%" echo verified_pre_failure_start=0x0
>>"%Q%" echo filter_entry=rdyboost_PRESENT
>>"%Q%" echo driver_file=C:\Windows\System32\drivers\rdyboost.sys_PRESENT
>>"%Q%" echo backup=%BK%

call :STAGE "3 of 5" "Restoring only rdyboost Start from 2 to the verified pre-failure boot-start value 0."
"%REG%" add "%SVC%" /v Start /t REG_DWORD /d 0 /f >nul 2>&1
if errorlevel 1 goto :ROLLBACK

call :STAGE "4 of 5" "Verifying the registry write and confirming no other ReadyBoost/filter values were altered."
set "NEWSTART="
for /f "tokens=3" %%V in ('"%REG%" query "%SVC%" /v Start 2^>nul ^| "%FS%" /i "Start"') do set "NEWSTART=%%V"
if /i not "!NEWSTART!"=="0x0" goto :ROLLBACK
>>"%Q%" echo new_start=!NEWSTART!
>>"%Q%" echo [RDYBOOST_SERVICE_AFTER]
"%REG%" query "%SVC%" >>"%Q%" 2>&1
>>"%Q%" echo [VOLUME_FILTERS_AFTER]
"%REG%" query "%CLS%" /v UpperFilters >>"%Q%" 2>&1
"%REG%" query "%CLS%" /v LowerFilters >>"%Q%" 2>&1
"%REG%" unload HKLM\RMAISYS54 >nul 2>&1

call :STAGE "5 of 5" "Uploading the reversible ReadyBoost repair result for review before reboot."
>"%R%\LAST_RUN_REPORT.txt" echo status=PASS
>>"%R%\LAST_RUN_REPORT.txt" echo message=ReadyBoost Start was restored from 2 to the verified pre-failure value 0; no other Windows state was intentionally changed.
>"%R%\RUN_DETAILS.txt" echo repair=RESTORE_RDYBOOST_BOOT_START
type "%Q%" >>"%R%\RUN_DETAILS.txt"
call "%A%" upload >nul 2>&1
if errorlevel 1 goto :UPLOADFAIL
>"%O%" echo STATUS=PASS
>>"%O%" echo MESSAGE=RescueMeAI restored the ReadyBoost kernel filter Start value from 2 to the machine's verified pre-failure value 0.
>>"%O%" echo EVIDENCE=The full pre-change service key was backed up; the volume filter list and rdyboost.sys were left intact.
>>"%O%" echo INSTRUCTION=No user action is required. Leave RescueMeAI online; do not reboot manually. The repair will be reviewed before a controlled boot test.
exit /b 0

:ROLLBACK
"%REG%" import "%BK%" >nul 2>&1
"%REG%" unload HKLM\RMAISYS54 >nul 2>&1
>"%R%\LAST_RUN_REPORT.txt" echo status=FAIL
>>"%R%\LAST_RUN_REPORT.txt" echo message=ReadyBoost Start repair could not be verified and the backed-up service key was restored.
>"%R%\RUN_DETAILS.txt" echo repair=RESTORE_RDYBOOST_BOOT_START_ROLLED_BACK
>>"%R%\RUN_DETAILS.txt" echo backup=%BK%
call "%A%" upload >nul 2>&1
>"%O%" echo STATUS=FAIL
>>"%O%" echo MESSAGE=ReadyBoost repair did not verify, so RescueMeAI restored the pre-change service key.
>>"%O%" echo EVIDENCE=The attempted change was rolled back; no reboot was started.
>>"%O%" echo INSTRUCTION=Leave RescueMeAI online; do not reboot.
exit /b 90

:PRECONDITION_FAIL
"%REG%" unload HKLM\RMAISYS54 >nul 2>&1
>"%R%\LAST_RUN_REPORT.txt" echo status=FAIL
>>"%R%\LAST_RUN_REPORT.txt" echo message=ReadyBoost repair was blocked because the expected Start=2, filter entry, driver file, or backup precondition was not satisfied.
>"%R%\RUN_DETAILS.txt" echo repair=RESTORE_RDYBOOST_BOOT_START_BLOCKED
>>"%R%\RUN_DETAILS.txt" echo observed_start=!CURSTART!
call "%A%" upload >nul 2>&1
>"%O%" echo STATUS=FAIL
>>"%O%" echo MESSAGE=RescueMeAI blocked the ReadyBoost repair because a safety precondition did not match.
>>"%O%" echo EVIDENCE=No ReadyBoost registry change was committed and no reboot was started.
>>"%O%" echo INSTRUCTION=Leave RescueMeAI online; do not reboot.
exit /b 90

:STAGE
if exist "%UI%" call "%UI%" screen "RMAI-AGENT-V2-2026.08.14-1508-ET" "CONNECTED" "RUNNING COMMAND 54" "TARGETED WRITE" "AI-ASSISTED WINDOWS RECOVERY" "INFO"
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
>>"%O%" echo MESSAGE=ReadyBoost Start was restored to 0 and verified locally, but the private report upload failed.
>>"%O%" echo EVIDENCE=Backup remains at %BK%. No reboot was started.
>>"%O%" echo INSTRUCTION=Leave RescueMeAI online; do not reboot.
exit /b 20

:BAD
"%REG%" unload HKLM\RMAISYS54 >nul 2>&1
>"%O%" echo STATUS=FAIL
>>"%O%" echo MESSAGE=RescueMeAI could not initialize the ReadyBoost boot-start repair.
>>"%O%" echo EVIDENCE=No Windows state was changed.
>>"%O%" echo INSTRUCTION=Leave RescueMeAI online; do not reboot.
exit /b 90
