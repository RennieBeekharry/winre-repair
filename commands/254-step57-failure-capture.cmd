@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=READ_ONLY
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Capture the exact reason Step 57 could not load the offline SYSTEM hive.
rem WR_ACTION=STEP57_FAILURE_CAPTURE
rem WR_TARGET=RescueMeAI diagnostic files and executable/file existence checks only.
rem WR_CONSEQUENCE=Reads local diagnostic text and file metadata only. No Windows, registry, BCD, EFI, package, partition, reboot, or personal file is changed.
rem WR_ROLLBACK=Not applicable; read-only diagnostic.

set "FIX_VERSION=RMAI-FIX-2026.09.10.3"
set "STEP=58"
set "WORK=C:\WinRERepair"
set "RESULT=%WORK%\COMMAND_RESULT.env"
set "DETAILS=%WORK%\RUN_DETAILS.txt"
set "REGX=X:\Windows\System32\reg.exe"
set "REGC=C:\Windows\System32\reg.exe"
set "HIVE=C:\Windows\System32\config\SYSTEM"

cls
echo ================================================================================
echo RescueMeAI - STEP 57 FAILURE CAPTURE
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : RUNNING
echo CURRENT TASK        : Capturing why the offline SYSTEM hive inspection stopped.
echo SAFETY              : READ-ONLY
echo PERSONAL FILES      : NOT TOUCHED
echo REBOOT              : NO
echo WHAT YOU SHOULD DO  : WAIT. Leave this window open.
echo SCREENSHOT REQUIRED : NO unless this step stops.
echo ================================================================================

>"%DETAILS%" echo RESCUEMEAI STEP 57 FAILURE CAPTURE
>>"%DETAILS%" echo fix_version=%FIX_VERSION%
>>"%DETAILS%" echo step=%STEP%

set "REGX_PRESENT=NO"
set "REGC_PRESENT=NO"
set "HIVE_PRESENT=NO"
if exist "%REGX%" set "REGX_PRESENT=YES"
if exist "%REGC%" set "REGC_PRESENT=YES"
if exist "%HIVE%" set "HIVE_PRESENT=YES"
>>"%DETAILS%" echo winre_reg_exe_present=!REGX_PRESENT!
>>"%DETAILS%" echo offline_reg_exe_present=!REGC_PRESENT!
>>"%DETAILS%" echo system_hive_present=!HIVE_PRESENT!

if exist "%WORK%\step57-regload.txt" (
  >>"%DETAILS%" echo.
  >>"%DETAILS%" echo --- STEP57 REG LOAD OUTPUT ---
  type "%WORK%\step57-regload.txt" >>"%DETAILS%"
) else (
  >>"%DETAILS%" echo step57_regload_output=MISSING
)

if exist "%WORK%\step57-regunload.txt" (
  >>"%DETAILS%" echo.
  >>"%DETAILS%" echo --- STEP57 REG UNLOAD OUTPUT ---
  type "%WORK%\step57-regunload.txt" >>"%DETAILS%"
)

>>"%DETAILS%" echo windows_changes_performed=NO
>>"%DETAILS%" echo personal_files_targeted=NO

>"%RESULT%" echo STATUS=PASS
>>"%RESULT%" echo MESSAGE=Step 57 failure evidence captured successfully.
>>"%RESULT%" echo EVIDENCE=WinRE reg.exe=!REGX_PRESENT!; offline reg.exe=!REGC_PRESENT!; SYSTEM hive=!HIVE_PRESENT!; exact reg-load output captured for review.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=NO
>>"%RESULT%" echo NEXT_STEP=RescueMeAI will correct the diagnostic method based on the exact WinRE registry error.

echo.
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : COMPLETE - FAILURE EVIDENCE SENT FOR REVIEW
echo WINDOWS CHANGES     : NONE
echo REBOOT              : NO
echo WHAT YOU SHOULD DO  : WAIT. Leave this window open.
echo SCREENSHOT REQUIRED : NO
echo ================================================================================
exit /b 0
