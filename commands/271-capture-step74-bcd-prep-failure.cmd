@echo off
setlocal EnableExtensions
rem WR_RISK=READ_ONLY
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Capture the small Step 74 BCD preparation output files to identify exactly where the Safe Mode preparation parser failed.
rem WR_ACTION=CAPTURE_STEP74_BCD_PREP_FAILURE
rem WR_TARGET=RescueMeAI Step 74 temporary diagnostic text only.
rem WR_CONSEQUENCE=Reads local Step 74 command-output files. No Windows setting, BCD, EFI file, registry, package, partition, reboot, or personal file is changed.
rem WR_ROLLBACK=Not applicable; this command is read-only.

set "FIX_VERSION=RMAI-FIX-2026.09.10.3"
set "STEP=75"
set "WORK=C:\WinRERepair"
set "RESULT=%WORK%\COMMAND_RESULT.env"
set "DETAILS=%WORK%\RUN_DETAILS.txt"

cls
echo ================================================================================
echo RescueMeAI - STEP 74 FAILURE CAPTURE
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : RUNNING
echo CURRENT TASK        : Reading the exact BCD copy/set output from Step 74.
echo SAFETY              : READ-ONLY - no BCD change and no reboot.
echo PERSONAL FILES      : NOT TOUCHED
echo REBOOT              : NO
echo WHAT YOU SHOULD DO  : WAIT. Leave this window open.
echo SCREENSHOT REQUIRED : NO
echo ================================================================================

> "%DETAILS%" echo RESCUEMEAI STEP 74 FAILURE CAPTURE
>>"%DETAILS%" echo fix_version=%FIX_VERSION%
>>"%DETAILS%" echo step=%STEP%

call :CAPTURE step74-mount.txt
call :CAPTURE step74-copy.txt
call :CAPTURE step74-safeboot.txt
call :CAPTURE step74-bootlog.txt
call :CAPTURE step74-entry.txt

>>"%DETAILS%" echo windows_changes_performed=NO
>>"%DETAILS%" echo personal_files_targeted=NO

> "%RESULT%" echo STATUS=PASS
>>"%RESULT%" echo MESSAGE=Step 74 BCD preparation failure evidence captured.
>>"%RESULT%" echo EVIDENCE=Exact local output from the BCD mount/copy/set stages was captured; no Windows changes or reboot.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=NO
>>"%RESULT%" echo NEXT_STEP=RescueMeAI will correct the Safe Mode preparation only after reviewing the exact output.

echo.
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : COMPLETE - STEP 74 FAILURE EVIDENCE SENT
echo WINDOWS CHANGES     : NONE
echo REBOOT              : NO
echo WHAT YOU SHOULD DO  : WAIT. Leave this window open.
echo SCREENSHOT REQUIRED : NO
echo ================================================================================
exit /b 0

:CAPTURE
>>"%DETAILS%" echo.
>>"%DETAILS%" echo --- %~1 ---
if exist "%WORK%\%~1" (
  type "%WORK%\%~1" >>"%DETAILS%" 2>nul
) else (
  >>"%DETAILS%" echo FILE_NOT_PRESENT
)
exit /b 0
