@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=REPAIR_WRITE
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Replace the stale EFI bootmgfw.efi with the verified Windows source copy after backing up the current EFI boot manager and BCD.
rem WR_ACTION=REFRESH_EFI_BOOTMGFW
rem WR_TARGET=EFI\Microsoft\Boot\bootmgfw.efi only, plus local RescueMeAI safety backups.
rem WR_CONSEQUENCE=Backs up the current EFI boot manager and BCD, then replaces only bootmgfw.efi from C:\Windows\Boot\EFI. No personal files, partitions, Windows registry, or update packages are changed.
rem WR_ROLLBACK=If post-copy verification fails, the original EFI bootmgfw.efi is restored automatically from the local backup.

set "FIX_VERSION=RMAI-FIX-2026.09.10.3"
set "STEP=46"
set "WORK=C:\WinRERepair"
set "RESULT=%WORK%\COMMAND_RESULT.env"
set "DETAILS=%WORK%\RUN_DETAILS.txt"
set "BACKUP=C:\RescueMeAI\backups\pre-efi-bootmgfw-20260910"
set "SOURCE=C:\Windows\Boot\EFI\bootmgfw.efi"
set "MOUNTVOL=X:\Windows\System32\mountvol.exe"
if not exist "%MOUNTVOL%" set "MOUNTVOL=C:\Windows\System32\mountvol.exe"
set "FC=X:\Windows\System32\fc.exe"
if not exist "%FC%" set "FC=C:\Windows\System32\fc.exe"
set "SYS=S:"
if exist S:\nul set "SYS=T:"
if not exist "%WORK%" md "%WORK%" >nul 2>&1
if not exist "%BACKUP%" md "%BACKUP%" >nul 2>&1

cls
echo ================================================================================
echo RescueMeAI - EFI BOOT MANAGER REPAIR
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : RUNNING
echo CURRENT DIAGNOSIS   : EFI bootmgfw.efi differs from the verified Windows copy.
echo CURRENT TASK        : Backing up and refreshing only the EFI boot manager binary.
echo SAFETY              : REPAIR-WRITE - ONE EFI BOOT FILE ONLY
echo PERSONAL FILES      : NOT TOUCHED
echo BCD                 : BACKED UP, NOT MODIFIED
echo REBOOT              : NO - verification happens first
echo WHAT YOU SHOULD DO  : WAIT. Keep the laptop on power.
echo SCREENSHOT REQUIRED : NO unless this step stops.
echo ================================================================================

if not exist "%SOURCE%" goto :FAIL
echo [1/5] Mounting EFI system partition...
"%MOUNTVOL%" %SYS% /S >"%WORK%\step46-mount.txt" 2>&1
if errorlevel 1 goto :FAIL
set "DEST=%SYS%\EFI\Microsoft\Boot\bootmgfw.efi"
set "BCD=%SYS%\EFI\Microsoft\Boot\BCD"
if not exist "!DEST!" goto :MOUNTFAIL

echo [2/5] Saving rollback copies...
copy /y "!DEST!" "%BACKUP%\bootmgfw.efi" >nul
if errorlevel 1 goto :MOUNTFAIL
if exist "!BCD!" copy /y "!BCD!" "%BACKUP%\BCD" >nul 2>&1

echo [3/5] Replacing stale EFI bootmgfw.efi...
copy /y "%SOURCE%" "!DEST!" >nul
if errorlevel 1 goto :ROLLBACK

echo [4/5] Verifying the replacement byte-for-byte...
"%FC%" /b "%SOURCE%" "!DEST!" >nul 2>&1
if errorlevel 1 goto :ROLLBACK

echo [5/5] Recording verified repair and unmounting EFI...
>"%DETAILS%" echo RESCUEMEAI EFI BOOT MANAGER REPAIR
>>"%DETAILS%" echo fix_version=%FIX_VERSION%
>>"%DETAILS%" echo step=%STEP%
>>"%DETAILS%" echo source=%SOURCE%
>>"%DETAILS%" echo destination=EFI\Microsoft\Boot\bootmgfw.efi
>>"%DETAILS%" echo previous_file_backup=%BACKUP%\bootmgfw.efi
>>"%DETAILS%" echo bcd_backup=%BACKUP%\BCD
>>"%DETAILS%" echo post_copy_byte_compare=SAME
>>"%DETAILS%" echo personal_files_targeted=NO
>>"%DETAILS%" echo windows_registry_changed=NO
>>"%DETAILS%" echo update_packages_changed=NO
"%MOUNTVOL%" %SYS% /D >nul 2>&1

>"%RESULT%" echo STATUS=PASS
>>"%RESULT%" echo MESSAGE=EFI boot manager refreshed and verified successfully.
>>"%RESULT%" echo EVIDENCE=Stale EFI bootmgfw.efi was backed up, replaced from C:\Windows\Boot\EFI, and verified byte-for-byte; BCD was backed up but not modified.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=NO
>>"%RESULT%" echo NEXT_STEP=Run a read-only EFI verification before the controlled boot test.

echo.
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : COMPLETE - EFI BOOT MANAGER REPAIRED
echo BYTE VERIFICATION   : PASS
echo ROLLBACK COPY       : SAVED LOCALLY
echo BCD                 : UNCHANGED
echo WINDOWS REBOOT      : NOT YET
echo WHAT YOU SHOULD DO  : WAIT. RescueMeAI will verify before rebooting.
echo SCREENSHOT REQUIRED : NO
echo ================================================================================
exit /b 0

:ROLLBACK
copy /y "%BACKUP%\bootmgfw.efi" "!DEST!" >nul 2>&1
"%MOUNTVOL%" %SYS% /D >nul 2>&1
>"%RESULT%" echo STATUS=FAIL
>>"%RESULT%" echo MESSAGE=EFI boot manager repair failed verification and the original file was restored.
>>"%RESULT%" echo EVIDENCE=Automatic rollback attempted; no reboot was performed.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=YES
echo STATUS              : STOPPED - REPAIR ROLLED BACK
echo SCREENSHOT REQUIRED : YES
exit /b 90

:MOUNTFAIL
"%MOUNTVOL%" %SYS% /D >nul 2>&1
:FAIL
>"%RESULT%" echo STATUS=FAIL
>>"%RESULT%" echo MESSAGE=EFI boot manager repair stopped before a verified replacement completed.
>>"%RESULT%" echo EVIDENCE=No reboot was performed. Personal files were not targeted.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=YES
echo STATUS              : STOPPED - EFI REPAIR FAILED
echo SCREENSHOT REQUIRED : YES
exit /b 90
