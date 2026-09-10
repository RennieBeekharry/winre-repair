@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=REPAIR_WRITE
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Enable Windows boot logging on the verified EFI BCD default entry, back up the BCD first, verify the change, and stop before reboot.
rem WR_ACTION=PREPARE_ONE_TIME_BOOTLOG_TEST
rem WR_TARGET=EFI Microsoft Boot BCD bootlog value for {default}, plus RescueMeAI rollback/state files only.
rem WR_CONSEQUENCE=Sets bootlog=Yes for the default Windows loader so the next controlled startup can create C:\Windows\ntbtlog.txt. Does not reboot. Personal files, partitions, packages, and Windows system binaries are not changed.
rem WR_ROLLBACK=Original EFI BCD is copied to C:\RescueMeAI\backups\pre-bootlog-step63\BCD and is automatically restored if the setting cannot be verified; after the diagnostic boot, RescueMeAI will clear bootlog.

set "FIX_VERSION=RMAI-FIX-2026.09.10.3"
set "STEP=63"
set "WORK=C:\WinRERepair"
set "STATE=C:\RescueMeAI\state"
set "BACKUP=C:\RescueMeAI\backups\pre-bootlog-step63"
set "RESULT=%WORK%\COMMAND_RESULT.env"
set "DETAILS=%WORK%\RUN_DETAILS.txt"
set "BCDTXT=%WORK%\step63-bcd-default.txt"
set "MOUNTVOL=X:\Windows\System32\mountvol.exe"
if not exist "%MOUNTVOL%" set "MOUNTVOL=C:\Windows\System32\mountvol.exe"
set "BCDEDIT=X:\Windows\System32\bcdedit.exe"
if not exist "%BCDEDIT%" set "BCDEDIT=C:\Windows\System32\bcdedit.exe"
set "FINDSTR=X:\Windows\System32\findstr.exe"
if not exist "%FINDSTR%" set "FINDSTR=C:\Windows\System32\findstr.exe"
set "SYS=S:"
if exist S:\nul set "SYS=T:"

cls
echo ================================================================================
echo RescueMeAI - PREPARE BOOT-LOGGING TEST
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : RUNNING
echo CURRENT DIAGNOSIS   : Core storage and storage-filter drivers are present with
echo                       boot-start configuration intact, but Windows still hangs.
echo CURRENT TASK        : Enabling boot logging for the NEXT controlled startup only.
echo SAFETY              : REPAIR-WRITE - one reversible BCD diagnostic setting.
echo PERSONAL FILES      : NOT TOUCHED
echo REBOOT              : NO - this step will stop before reboot.
echo BITLOCKER           : A recovery-key prompt is possible after a BCD change.
echo WHAT YOU SHOULD DO  : WAIT. Do not reboot manually.
echo SCREENSHOT REQUIRED : NO unless this step stops with an error.
echo ================================================================================

if not exist "%WORK%" md "%WORK%" >nul 2>&1
if not exist "%STATE%" md "%STATE%" >nul 2>&1
if not exist "%BACKUP%" md "%BACKUP%" >nul 2>&1
if not exist "%MOUNTVOL%" goto :FAIL
if not exist "%BCDEDIT%" goto :FAIL
if not exist "%FINDSTR%" goto :FAIL

>"%DETAILS%" echo RESCUEMEAI PREPARE ONE-TIME BOOTLOG TEST
>>"%DETAILS%" echo fix_version=%FIX_VERSION%
>>"%DETAILS%" echo step=%STEP%

echo [1/5] Mounting EFI system partition temporarily...
"%MOUNTVOL%" %SYS% /S >"%WORK%\step63-mount.txt" 2>&1
if errorlevel 1 goto :FAIL
set "MOUNTED=YES"
set "BCD=%SYS%\EFI\Microsoft\Boot\BCD"
if not exist "!BCD!" goto :MOUNTFAIL

echo [2/5] Saving rollback copy of the EFI BCD...
copy /y "!BCD!" "%BACKUP%\BCD" >nul
if errorlevel 1 goto :MOUNTFAIL

echo [3/5] Enabling boot logging on the default Windows loader...
"%BCDEDIT%" /store "!BCD!" /set {default} bootlog Yes >"%WORK%\step63-set.txt" 2>&1
if errorlevel 1 goto :ROLLBACK

echo [4/5] Verifying bootlog=Yes in the same EFI BCD store...
"%BCDEDIT%" /store "!BCD!" /enum {default} >"%BCDTXT%" 2>&1
if errorlevel 1 goto :ROLLBACK
"%FINDSTR%" /i /r /c:"bootlog *Yes" "%BCDTXT%" >nul 2>&1
if errorlevel 1 goto :ROLLBACK

echo [5/5] Recording prepared state and unmounting EFI...
>"%STATE%\bootlog-step63.prepared" echo status=PREPARED
>>"%STATE%\bootlog-step63.prepared" echo fix_version=%FIX_VERSION%
>>"%STATE%\bootlog-step63.prepared" echo rollback_bcd=%BACKUP%\BCD
>>"%DETAILS%" echo bcd_backup=%BACKUP%\BCD
>>"%DETAILS%" echo bootlog_default=YES
>>"%DETAILS%" echo reboot_performed=NO
>>"%DETAILS%" echo windows_system_files_changed=NO
>>"%DETAILS%" echo personal_files_targeted=NO
"%MOUNTVOL%" %SYS% /D >nul 2>&1
set "MOUNTED=NO"

>"%RESULT%" echo STATUS=PASS
>>"%RESULT%" echo MESSAGE=Boot logging prepared and verified; no reboot was performed.
>>"%RESULT%" echo EVIDENCE=EFI BCD was backed up and {default} bootlog=Yes was verified in the same store.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=NO
>>"%RESULT%" echo NEXT_STEP=Wait for ChatGPT review and explicit controlled-boot approval. Do not reboot manually.

echo.
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : READY - BOOT LOGGING PREPARED
echo BOOTLOG             : ENABLED AND VERIFIED FOR NEXT WINDOWS STARTUP
echo BCD BACKUP          : SAVED LOCALLY
echo REBOOT              : NO
echo WHAT YOU SHOULD DO  : WAIT. Do not reboot manually.
echo SCREENSHOT REQUIRED : NO
echo HOW TO REPLY        : Reply CONTINUE when ChatGPT asks to start the boot-log test.
echo ================================================================================
exit /b 0

:ROLLBACK
copy /y "%BACKUP%\BCD" "!BCD!" >nul 2>&1
if /i "!MOUNTED!"=="YES" "%MOUNTVOL%" %SYS% /D >nul 2>&1
set "MOUNTED=NO"
>"%RESULT%" echo STATUS=FAIL
>>"%RESULT%" echo MESSAGE=Boot-log preparation failed verification and the original EFI BCD was restored.
>>"%RESULT%" echo EVIDENCE=Automatic rollback was attempted; no reboot was performed and personal files were not targeted.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=YES
echo.
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : STOPPED - BOOTLOG PREP ROLLED BACK
echo REBOOT              : NO
echo SCREENSHOT REQUIRED : YES
echo WHAT YOU SHOULD DO  : Reply FAILED and send ChatGPT a photo. Do not reboot.
echo ================================================================================
exit /b 90

:MOUNTFAIL
if /i "!MOUNTED!"=="YES" "%MOUNTVOL%" %SYS% /D >nul 2>&1
set "MOUNTED=NO"
:FAIL
if /i "!MOUNTED!"=="YES" "%MOUNTVOL%" %SYS% /D >nul 2>&1
>"%RESULT%" echo STATUS=FAIL
>>"%RESULT%" echo MESSAGE=Boot-log preparation stopped before a verified BCD change completed.
>>"%RESULT%" echo EVIDENCE=No reboot was performed. Personal files were not targeted.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=YES
echo.
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : STOPPED - BOOTLOG PREPARATION FAILED
echo REBOOT              : NO
echo SCREENSHOT REQUIRED : YES
echo WHAT YOU SHOULD DO  : Reply FAILED and send ChatGPT a photo. Do not reboot.
echo ================================================================================
exit /b 90
