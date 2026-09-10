@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=REPAIR_WRITE
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Capture the EFI BCD default loader verbatim after the boot-manager repair.
rem WR_ACTION=CAPTURE_EFI_BCD_VERBATIM
rem WR_TARGET=EFI BCD read only plus RescueMeAI diagnostic text.
rem WR_CONSEQUENCE=Temporarily assigns an EFI drive letter, reads BCD text, then removes the drive letter. No EFI content or personal file is changed.
rem WR_ROLLBACK=Temporary EFI drive letter is removed before exit.

set "FIX_VERSION=RMAI-FIX-2026.09.10.3"
set "STEP=48"
set "WORK=C:\WinRERepair"
set "RESULT=%WORK%\COMMAND_RESULT.env"
set "DETAILS=%WORK%\RUN_DETAILS.txt"
set "MOUNTVOL=X:\Windows\System32\mountvol.exe"
if not exist "%MOUNTVOL%" set "MOUNTVOL=C:\Windows\System32\mountvol.exe"
set "BCDEDIT=X:\Windows\System32\bcdedit.exe"
if not exist "%BCDEDIT%" set "BCDEDIT=C:\Windows\System32\bcdedit.exe"
set "SYS=S:"
if exist S:\nul set "SYS=T:"

cls
echo ================================================================================
echo RescueMeAI - EFI BCD EXACT CAPTURE
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : RUNNING
echo CURRENT TASK        : Reading the EFI BCD default loader exactly as stored.
echo SAFETY              : DIAGNOSTIC ONLY - no BCD modification.
echo PERSONAL FILES      : NOT TOUCHED
echo REBOOT              : NO
echo WHAT YOU SHOULD DO  : WAIT.
echo SCREENSHOT REQUIRED : NO
echo ================================================================================

"%MOUNTVOL%" %SYS% /S >"%WORK%\step48-mount.txt" 2>&1
if errorlevel 1 goto :FAIL
set "BCD=%SYS%\EFI\Microsoft\Boot\BCD"
if not exist "!BCD!" goto :MOUNTFAIL
"%BCDEDIT%" /store "!BCD!" /enum {default} >"%WORK%\step48-bcd.txt" 2>&1
set "RC=!errorlevel!"
>"%DETAILS%" echo RESCUEMEAI EFI BCD EXACT CAPTURE
>>"%DETAILS%" echo fix_version=%FIX_VERSION%
>>"%DETAILS%" echo step=%STEP%
>>"%DETAILS%" echo bcd_query_exit=!RC!
>>"%DETAILS%" echo.
>>"%DETAILS%" echo --- EFI BCD DEFAULT LOADER ---
if exist "%WORK%\step48-bcd.txt" type "%WORK%\step48-bcd.txt" >>"%DETAILS%"
>>"%DETAILS%" echo personal_files_targeted=NO
"%MOUNTVOL%" %SYS% /D >nul 2>&1
if not "!RC!"=="0" goto :FAIL
>"%RESULT%" echo STATUS=PASS
>>"%RESULT%" echo MESSAGE=EFI BCD default loader captured exactly for review.
>>"%RESULT%" echo EVIDENCE=BCD query returned exit code 0; no BCD content was changed.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=NO
>>"%RESULT%" echo NEXT_STEP=RescueMeAI will review the exact BCD text before any boot test.
echo.
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : COMPLETE - BCD SENT FOR REVIEW
echo WINDOWS CHANGES     : NONE
echo REBOOT              : NO
echo WHAT YOU SHOULD DO  : WAIT. Leave this window open.
echo SCREENSHOT REQUIRED : NO
echo ================================================================================
exit /b 0

:MOUNTFAIL
"%MOUNTVOL%" %SYS% /D >nul 2>&1
:FAIL
>"%RESULT%" echo STATUS=FAIL
>>"%RESULT%" echo MESSAGE=EFI BCD exact capture could not complete.
>>"%RESULT%" echo EVIDENCE=No BCD content or personal files were changed; no reboot was performed.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=YES
echo STATUS              : STOPPED - BCD CAPTURE FAILED
echo SCREENSHOT REQUIRED : YES
exit /b 90
