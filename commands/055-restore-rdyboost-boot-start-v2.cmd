@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=REPAIR_WRITE
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Correct the Command 54 registry-value parser, re-check the exact ReadyBoost safety preconditions, and if still justified restore only rdyboost Start from 2 to 0 with a full rollback backup.
rem WR_ACTION=RESTORE_RDYBOOST_BOOT_START_V2
rem WR_TARGET=Offline ControlSet001\Services\rdyboost Start DWORD only, plus RescueMeAI backup/report files.
rem WR_CONSEQUENCE=If and only if the current value is exactly 2 and all safety checks pass, changes one DWORD to 0. No driver file, filter list, storage-controller binding, BCD, partition, update package, or personal file is changed.
rem WR_ROLLBACK=The complete pre-change rdyboost service key is exported before any write and can be imported to restore the prior state.

set "R=C:\WinRERepair"
set "O=%R%\COMMAND_RESULT.env"
set "A=%R%\runtime\github-auth.cmd"
set "UI=%R%\runtime\ui.cmd"
set "REG=C:\Windows\System32\reg.exe"
set "FS=C:\Windows\System32\findstr.exe"
set "SYS=C:\Windows\System32\config\SYSTEM"
set "B=%R%\backup"
set "BK=%B%\rdyboost-before-command55.reg"
set "STARTQ=%R%\repair55-start-before.txt"
set "STARTA=%R%\repair55-start-after.txt"
set "FILTERQ=%R%\repair55-filters.txt"
set "Q=%R%\repair55-rdyboost-start.txt"
set "SVC=HKLM\RMAISYS55\ControlSet001\Services\rdyboost"
set "CLS=HKLM\RMAISYS55\ControlSet001\Control\Class\{71A27CDD-812A-11D0-BEC7-08002BE2092F}"
set "CURSTART="
set "NEWSTART="
set "FILTER_OK=NO"
set "DRIVER_OK=NO"
set "BACKUP_OK=NO"
set "CHANGED=NO"
set "WHY="

if not exist "%REG%" set "REG=reg.exe"
if not exist "%FS%" set "FS=findstr.exe"
if not exist "%SYS%" goto :INITFAIL
if not exist "%B%" md "%B%" >nul 2>&1

call :STAGE "1 of 5" "Re-reading the ReadyBoost Start value with the corrected parser." "No Windows change yet."
"%REG%" unload HKLM\RMAISYS55 >nul 2>&1
"%REG%" load HKLM\RMAISYS55 "%SYS%" >nul 2>&1
if errorlevel 1 (
  set "WHY=The offline SYSTEM hive could not be loaded."
  goto :BLOCK
)

"%REG%" query "%SVC%" /v Start >"%STARTQ%" 2>&1
if errorlevel 1 (
  set "WHY=The rdyboost Start value could not be queried."
  goto :BLOCK
)
for /f "usebackq tokens=1,2,3" %%A in ("%STARTQ%") do (
  if /i "%%A"=="Start" if /i "%%B"=="REG_DWORD" set "CURSTART=%%C"
)
if not defined CURSTART (
  set "WHY=The corrected parser still could not read the rdyboost Start DWORD."
  goto :BLOCK
)

call :STAGE "2 of 5" "Checking the volume-filter entry, driver file, and exact current value before writing." "Expected current value: Start=2."
"%REG%" query "%CLS%" /v LowerFilters >"%FILTERQ%" 2>&1
if not errorlevel 1 (
  "%FS%" /i /c:"rdyboost" "%FILTERQ%" >nul 2>&1
  if not errorlevel 1 set "FILTER_OK=YES"
)
if exist C:\Windows\System32\drivers\rdyboost.sys set "DRIVER_OK=YES"

if /i "%FILTER_OK%" NEQ "YES" (
  set "WHY=The volume LowerFilters list does not contain rdyboost."
  goto :BLOCK
)
if /i "%DRIVER_OK%" NEQ "YES" (
  set "WHY=C:\Windows\System32\drivers\rdyboost.sys is missing."
  goto :BLOCK
)

if /i "%CURSTART%"=="0x0" goto :ALREADY
if /i not "%CURSTART%"=="0x2" (
  set "WHY=The current rdyboost Start value is %CURSTART%, not the expected pre-repair value 0x2."
  goto :BLOCK
)

call :STAGE "3 of 5" "Creating a complete rollback backup of the ReadyBoost service key." "No registry write will occur unless this backup succeeds."
if exist "%BK%" del /f /q "%BK%" >nul 2>&1
"%REG%" export "%SVC%" "%BK%" /y >nul 2>&1
if errorlevel 1 (
  set "WHY=The ReadyBoost service-key rollback backup could not be created."
  goto :BLOCK
)
if not exist "%BK%" (
  set "WHY=The ReadyBoost rollback backup file is missing after export."
  goto :BLOCK
)
for %%Z in ("%BK%") do if %%~zZ GTR 0 set "BACKUP_OK=YES"
if /i "%BACKUP_OK%" NEQ "YES" (
  set "WHY=The ReadyBoost rollback backup file is empty."
  goto :BLOCK
)

call :STAGE "4 of 5" "Applying the single targeted registry repair: rdyboost Start 2 -> 0." "Rollback backup is ready."
"%REG%" add "%SVC%" /v Start /t REG_DWORD /d 0 /f >nul 2>&1
if errorlevel 1 (
  set "WHY=Windows rejected the ReadyBoost Start-value write."
  goto :ROLLBACK
)
set "CHANGED=YES"

"%REG%" query "%SVC%" /v Start >"%STARTA%" 2>&1
if errorlevel 1 (
  set "WHY=The post-write ReadyBoost Start value could not be queried."
  goto :ROLLBACK
)
for /f "usebackq tokens=1,2,3" %%A in ("%STARTA%") do (
  if /i "%%A"=="Start" if /i "%%B"=="REG_DWORD" set "NEWSTART=%%C"
)
if /i not "%NEWSTART%"=="0x0" (
  set "WHY=The post-write ReadyBoost Start value did not verify as 0x0."
  goto :ROLLBACK
)

call :STAGE "5 of 5" "Verifying the final state and uploading the detailed result before any reboot." "A reboot is NOT started by this command."
> "%Q%" echo RESCUEMEAI COMMAND 55 - READYBOOST BOOT-START REPAIR V2
>>"%Q%" echo result=PASS
>>"%Q%" echo command54_issue=REGISTRY_VALUE_PARSER_RETURNED_BLANK
>>"%Q%" echo prior_start=%CURSTART%
>>"%Q%" echo new_start=%NEWSTART%
>>"%Q%" echo lowerfilters_rdyboost=%FILTER_OK%
>>"%Q%" echo driver_file_present=%DRIVER_OK%
>>"%Q%" echo rollback_backup=%BK%
>>"%Q%" echo rollback_backup_ok=%BACKUP_OK%
>>"%Q%" echo changed=%CHANGED%
>>"%Q%" echo reboot_started=NO
"%REG%" unload HKLM\RMAISYS55 >nul 2>&1

> "%R%\LAST_RUN_REPORT.txt" echo status=PASS
>>"%R%\LAST_RUN_REPORT.txt" echo message=Command 55 corrected the Command 54 parser issue and restored rdyboost Start from 2 to 0 after all safety checks passed.
> "%R%\RUN_DETAILS.txt" echo repair=RESTORE_RDYBOOST_BOOT_START_V2_PASS
type "%Q%" >>"%R%\RUN_DETAILS.txt"
call "%A%" upload >nul 2>&1
if errorlevel 1 goto :UPLOADFAIL

> "%O%" echo STATUS=PASS
>>"%O%" echo MESSAGE=Command 55 - ReadyBoost boot-start repair PASSED. rdyboost Start changed from 2 to 0.
>>"%O%" echo EVIDENCE=Safety checks: Start=2 PASS; LowerFilters contains rdyboost PASS; rdyboost.sys present PASS; rollback backup PASS; post-write Start=0 PASS. Reboot started: NO.
>>"%O%" echo INSTRUCTION=No action required. Leave RescueMeAI online. The AI will review this verified repair before scheduling a controlled boot test.
exit /b 0

:ALREADY
call :STAGE "3 of 5" "The corrected parser found rdyboost Start is already 0." "No registry write is required."
> "%Q%" echo RESCUEMEAI COMMAND 55 - READYBOOST BOOT-START REPAIR V2
>>"%Q%" echo result=PASS_ALREADY_CORRECT
>>"%Q%" echo command54_issue=REGISTRY_VALUE_PARSER_RETURNED_BLANK
>>"%Q%" echo observed_start=%CURSTART%
>>"%Q%" echo lowerfilters_rdyboost=%FILTER_OK%
>>"%Q%" echo driver_file_present=%DRIVER_OK%
>>"%Q%" echo changed=NO
>>"%Q%" echo reboot_started=NO
"%REG%" unload HKLM\RMAISYS55 >nul 2>&1
> "%R%\LAST_RUN_REPORT.txt" echo status=PASS
>>"%R%\LAST_RUN_REPORT.txt" echo message=Command 55 corrected the parser check and found rdyboost Start is already 0; no registry write was needed.
> "%R%\RUN_DETAILS.txt" echo repair=RESTORE_RDYBOOST_BOOT_START_V2_ALREADY_CORRECT
type "%Q%" >>"%R%\RUN_DETAILS.txt"
call "%A%" upload >nul 2>&1
> "%O%" echo STATUS=PASS
>>"%O%" echo MESSAGE=Command 55 - ReadyBoost boot-start repair check PASSED. The corrected parser shows rdyboost Start is already 0, so nothing was changed.
>>"%O%" echo EVIDENCE=LowerFilters contains rdyboost PASS; rdyboost.sys present PASS; registry write: NO; reboot started: NO.
>>"%O%" echo INSTRUCTION=No action required. Leave RescueMeAI online for AI review.
exit /b 0

:ROLLBACK
call :STAGE "5 of 5" "A write/verification step failed; restoring the complete pre-change ReadyBoost key." "No reboot will be started."
if exist "%BK%" "%REG%" import "%BK%" >nul 2>&1
set "RBRC=!errorlevel!"
"%REG%" unload HKLM\RMAISYS55 >nul 2>&1
> "%R%\LAST_RUN_REPORT.txt" echo status=FAIL
>>"%R%\LAST_RUN_REPORT.txt" echo message=Command 55 could not verify the targeted ReadyBoost repair and attempted automatic rollback.
> "%R%\RUN_DETAILS.txt" echo repair=RESTORE_RDYBOOST_BOOT_START_V2_ROLLBACK
>>"%R%\RUN_DETAILS.txt" echo reason=%WHY%
>>"%R%\RUN_DETAILS.txt" echo prior_start=%CURSTART%
>>"%R%\RUN_DETAILS.txt" echo attempted_new_start=%NEWSTART%
>>"%R%\RUN_DETAILS.txt" echo rollback_return_code=%RBRC%
>>"%R%\RUN_DETAILS.txt" echo backup=%BK%
call "%A%" upload >nul 2>&1
> "%O%" echo STATUS=FAIL
>>"%O%" echo MESSAGE=Command 55 - ReadyBoost repair FAILED verification. Automatic rollback was attempted.
>>"%O%" echo EVIDENCE=Reason: %WHY% Rollback return code: %RBRC%. Reboot started: NO.
>>"%O%" echo INSTRUCTION=No local action required. Leave RescueMeAI online for AI review.
exit /b 90

:BLOCK
call :STAGE "5 of 5" "Safety gate blocked the repair before any registry write." "%WHY%"
"%REG%" unload HKLM\RMAISYS55 >nul 2>&1
> "%R%\LAST_RUN_REPORT.txt" echo status=FAIL
>>"%R%\LAST_RUN_REPORT.txt" echo message=Command 55 blocked the ReadyBoost repair before any registry write because a named safety check failed.
> "%R%\RUN_DETAILS.txt" echo repair=RESTORE_RDYBOOST_BOOT_START_V2_BLOCKED
>>"%R%\RUN_DETAILS.txt" echo reason=%WHY%
>>"%R%\RUN_DETAILS.txt" echo observed_start=%CURSTART%
>>"%R%\RUN_DETAILS.txt" echo lowerfilters_rdyboost=%FILTER_OK%
>>"%R%\RUN_DETAILS.txt" echo driver_file_present=%DRIVER_OK%
>>"%R%\RUN_DETAILS.txt" echo registry_write=NO
>>"%R%\RUN_DETAILS.txt" echo reboot_started=NO
call "%A%" upload >nul 2>&1
> "%O%" echo STATUS=FAIL
>>"%O%" echo MESSAGE=Command 55 - ReadyBoost repair BLOCKED before any write.
>>"%O%" echo EVIDENCE=Failed safety check: %WHY% Observed Start=%CURSTART%; LowerFilters rdyboost=%FILTER_OK%; driver present=%DRIVER_OK%; reboot started=NO.
>>"%O%" echo INSTRUCTION=No local action required. Leave RescueMeAI online for AI review.
exit /b 90

:UPLOADFAIL
> "%O%" echo STATUS=WARNING
>>"%O%" echo MESSAGE=Command 55 repaired and verified rdyboost Start=0 locally, but private report upload failed.
>>"%O%" echo EVIDENCE=Rollback backup remains at %BK%. Reboot started: NO.
>>"%O%" echo INSTRUCTION=Leave RescueMeAI online; do not reboot manually.
exit /b 20

:INITFAIL
> "%O%" echo STATUS=FAIL
>>"%O%" echo MESSAGE=Command 55 could not initialize the ReadyBoost repair.
>>"%O%" echo EVIDENCE=Offline SYSTEM hive or required registry tools were unavailable. Registry write: NO. Reboot started: NO.
>>"%O%" echo INSTRUCTION=Leave RescueMeAI online for AI review.
exit /b 90

:STAGE
if exist "%UI%" call "%UI%" screen "RMAI-AGENT-V2-2026.08.14-1508-ET" "CONNECTED" "RUNNING COMMAND 55" "TARGETED WRITE" "AI-ASSISTED WINDOWS RECOVERY" "INFO"
echo.
echo COMMAND DETAILS
echo ------------------------------------------------------------------------------------------------
echo Command ID : 55
echo Name       : Restore ReadyBoost Boot-Start V2
echo Risk       : TARGETED WRITE - one DWORD only, with rollback backup
echo Goal       : Restore rdyboost Start from 2 to 0 only if every safety check passes
echo Reboot     : NO - this command will not reboot the PC
echo.
echo RECOVERY ACTIVITY
echo ------------------------------------------------------------------------------------------------
echo Step %~1
echo %~2
echo.
echo Current detail: %~3
echo.
echo No user action is required while this command is running.
exit /b 0
