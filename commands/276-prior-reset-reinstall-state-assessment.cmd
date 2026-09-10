@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=READ_ONLY
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Assess whether a prior Windows Reset/reinstall attempt left rollback or setup state that changes the recovery-vs-clean-install decision.
rem WR_ACTION=ASSESS_PRIOR_RESET_REINSTALL_STATE
rem WR_TARGET=Known Windows reset/setup/servicing marker paths and file metadata only; no personal-file contents are read or uploaded.
rem WR_CONSEQUENCE=Reads only existence, size, and timestamp metadata for known Windows recovery/setup artifacts. No Windows setting, BCD, EFI file, registry, package, partition, personal file, or reboot is changed.
rem WR_ROLLBACK=Not applicable; this command is read-only.

set "FIX_VERSION=RMAI-FIX-2026.09.10.3"
set "STEP=79"
set "WORK=C:\WinRERepair"
set "RESULT=%WORK%\COMMAND_RESULT.env"
set "DETAILS=%WORK%\RUN_DETAILS.txt"

cls
echo ================================================================================
echo RescueMeAI - PRIOR RESET / REINSTALL STATE ASSESSMENT
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : RUNNING
echo CURRENT DIAGNOSIS   : Normal boot and Safe Mode both stall. We learned that a
echo                       Windows recovery/reset/reinstall was attempted beforehand.
echo CURRENT TASK        : Check for partial-reset, rollback, setup, and servicing state
echo                       before deciding whether further repair is worthwhile.
echo SAFETY              : READ-ONLY - NO REBOOT.
echo PRIVACY             : Known Windows paths/metadata only; personal files not read.
echo PERSONAL FILES      : NOT TOUCHED
echo REBOOT              : NO
echo WHAT YOU SHOULD DO  : WAIT. Leave this window open.
echo SCREENSHOT REQUIRED : NO unless this step stops with an error.
echo ================================================================================

if not exist "%WORK%" md "%WORK%" >nul 2>&1
if not exist "C:\Windows\System32\config\SYSTEM" goto :FAIL

>"%DETAILS%" echo RESCUEMEAI PRIOR RESET / REINSTALL STATE ASSESSMENT
>>"%DETAILS%" echo fix_version=%FIX_VERSION%
>>"%DETAILS%" echo step=%STEP%

echo [1/4] Checking reset and rollback directories...
call :DIRSTATE "C:\$SysReset" SYSRESET
call :DIRSTATE "C:\Windows.old" WINDOWS_OLD
call :DIRSTATE "C:\$WINDOWS.~BT" WINDOWS_BT
call :DIRSTATE "C:\$WINDOWS.~WS" WINDOWS_WS
call :DIRSTATE "C:\Windows\Panther" PANTHER
call :DIRSTATE "C:\Windows\Logs\MoSetup" MOSETUP
call :DIRSTATE "C:\Windows\LiveKernelReports" LIVE_KERNEL_REPORTS

echo [2/4] Recording metadata for known reset/setup logs only...
call :FILEMETA "C:\$SysReset\Logs\setupact.log" SYSRESET_SETUPACT
call :FILEMETA "C:\$SysReset\Logs\setuperr.log" SYSRESET_SETUPERR
call :FILEMETA "C:\Windows\Panther\setupact.log" PANTHER_SETUPACT
call :FILEMETA "C:\Windows\Panther\setuperr.log" PANTHER_SETUPERR
call :FILEMETA "C:\$WINDOWS.~BT\Sources\Panther\setupact.log" BT_SETUPACT
call :FILEMETA "C:\$WINDOWS.~BT\Sources\Panther\setuperr.log" BT_SETUPERR
call :FILEMETA "C:\Windows\Logs\MoSetup\BlueBox.log" MOSETUP_BLUEBOX
call :FILEMETA "C:\Windows\System32\LogFiles\Srt\SrtTrail.txt" SRTTRAIL

echo [3/4] Checking servicing/recovery markers and crash evidence metadata...
call :FILEMETA "C:\Windows\WinSxS\pending.xml" WINSXS_PENDING
call :FILEMETA "C:\Windows\WinSxS\reboot.xml" WINSXS_REBOOT
call :FILEMETA "C:\Windows\System32\Recovery\ReAgent.xml" REAGENT_XML
call :FILEMETA "C:\Windows\MEMORY.DMP" MEMORY_DMP
call :DIRSTATE "C:\Windows\Minidump" MINIDUMP_DIR

echo [4/4] Recording decision-support summary...
>>"%DETAILS%" echo windows_target=PASS
>>"%DETAILS%" echo personal_file_contents_read=NO
>>"%DETAILS%" echo windows_changes_performed=NO
>>"%DETAILS%" echo reboot_performed=NO

>"%RESULT%" echo STATUS=PASS
>>"%RESULT%" echo MESSAGE=Prior reset/reinstall state assessment completed safely.
>>"%RESULT%" echo EVIDENCE=Known reset/setup/rollback/servicing artifact metadata captured without reading personal files; no Windows changes or reboot.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=NO
>>"%RESULT%" echo NEXT_STEP=RescueMeAI will use this evidence with the failed normal and Safe Mode boots to decide between one final targeted repair path and clean Windows installation.

echo.
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : COMPLETE - RESET/REINSTALL STATE SENT FOR REVIEW
echo WINDOWS CHANGES     : NONE
echo PERSONAL FILES      : NOT TOUCHED
echo REBOOT              : NO
echo WHAT YOU SHOULD DO  : WAIT. Leave this window open.
echo SCREENSHOT REQUIRED : NO
echo ================================================================================
exit /b 0

:DIRSTATE
if exist "%~1\" (
  >>"%DETAILS%" echo %~2=YES
) else (
  >>"%DETAILS%" echo %~2=NO
)
exit /b 0

:FILEMETA
if exist "%~1" (
  for %%F in ("%~1") do >>"%DETAILS%" echo %~2=YES;size=%%~zF;modified=%%~tF
) else (
  >>"%DETAILS%" echo %~2=NO
)
exit /b 0

:FAIL
>"%RESULT%" echo STATUS=FAIL
>>"%RESULT%" echo MESSAGE=Prior reset/reinstall state assessment could not verify the offline Windows target.
>>"%RESULT%" echo EVIDENCE=No Windows setting, personal file, or reboot was performed.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=YES
echo.
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : STOPPED - WINDOWS TARGET NOT VERIFIED
echo REBOOT              : NO
echo SCREENSHOT REQUIRED : YES
echo WHAT YOU SHOULD DO  : Reply FAILED and send ChatGPT a photo. Do not reboot.
echo ================================================================================
exit /b 90
