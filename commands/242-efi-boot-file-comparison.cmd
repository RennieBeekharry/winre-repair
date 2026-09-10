@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=READ_ONLY
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Compare EFI system-partition boot files with the repaired Windows boot-source copies after the update-related boot failure.
rem WR_ACTION=COMPARE_EFI_BOOT_FILES
rem WR_TARGET=EFI system partition and C:\Windows\Boot\EFI boot files only.
rem WR_CONSEQUENCE=Temporarily mounts the EFI partition read-only for comparison, then removes the mount point. No boot files, BCD, registry, packages, partitions, or personal files are changed.
rem WR_ROLLBACK=Not applicable; the temporary mount point is removed before exit.

set "FIX_VERSION=RMAI-FIX-2026.09.10.2"
set "STEP=45"
set "WORK=C:\WinRERepair"
set "RESULT=%WORK%\COMMAND_RESULT.env"
set "DETAILS=%WORK%\RUN_DETAILS.txt"
set "MOUNTVOL=X:\Windows\System32\mountvol.exe"
if not exist "%MOUNTVOL%" set "MOUNTVOL=C:\Windows\System32\mountvol.exe"
set "FC=X:\Windows\System32\fc.exe"
if not exist "%FC%" set "FC=C:\Windows\System32\fc.exe"
set "SYS=S:"
if exist S:\nul set "SYS=T:"
if not exist "%WORK%" md "%WORK%" >nul 2>&1

cls
echo ================================================================================
echo RescueMeAI - EFI BOOT FILE COMPARISON
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : RUNNING
echo CURRENT DIAGNOSIS   : Windows reaches the boot spinner but still hangs.
echo CURRENT TASK        : Comparing EFI boot files with C:\Windows boot-source copies.
echo SAFETY              : READ-ONLY COMPARISON
echo PERSONAL FILES      : NOT TOUCHED
echo REBOOT              : NO
echo WHAT YOU SHOULD DO  : WAIT.
echo SCREENSHOT REQUIRED : NO
echo ================================================================================

echo [1/4] Mounting the EFI system partition temporarily...
"%MOUNTVOL%" %SYS% /S >"%WORK%\diag45-mount.txt" 2>&1
if errorlevel 1 goto :FAIL

echo [2/4] Comparing bootmgfw.efi...
set "BOOTMGFW=UNKNOWN"
if exist "C:\Windows\Boot\EFI\bootmgfw.efi" if exist "%SYS%\EFI\Microsoft\Boot\bootmgfw.efi" (
  "%FC%" /b "C:\Windows\Boot\EFI\bootmgfw.efi" "%SYS%\EFI\Microsoft\Boot\bootmgfw.efi" >nul 2>&1
  set "RC=!errorlevel!"
  if "!RC!"=="0" set "BOOTMGFW=SAME"
  if "!RC!"=="1" set "BOOTMGFW=DIFFERENT"
  if not "!RC!"=="0" if not "!RC!"=="1" set "BOOTMGFW=COMPARE_ERROR"
)
if not exist "%SYS%\EFI\Microsoft\Boot\bootmgfw.efi" set "BOOTMGFW=EFI_COPY_MISSING"

echo [3/4] Comparing boot.stl and checking BCD...
set "BOOTSTL=UNKNOWN"
if exist "C:\Windows\Boot\EFI\boot.stl" if exist "%SYS%\EFI\Microsoft\Boot\boot.stl" (
  "%FC%" /b "C:\Windows\Boot\EFI\boot.stl" "%SYS%\EFI\Microsoft\Boot\boot.stl" >nul 2>&1
  set "RC=!errorlevel!"
  if "!RC!"=="0" set "BOOTSTL=SAME"
  if "!RC!"=="1" set "BOOTSTL=DIFFERENT"
  if not "!RC!"=="0" if not "!RC!"=="1" set "BOOTSTL=COMPARE_ERROR"
)
if exist "C:\Windows\Boot\EFI\boot.stl" if not exist "%SYS%\EFI\Microsoft\Boot\boot.stl" set "BOOTSTL=EFI_COPY_MISSING"
set "BCD=NO"
if exist "%SYS%\EFI\Microsoft\Boot\BCD" set "BCD=YES"

echo [4/4] Recording result and removing temporary mount...
>"%DETAILS%" echo RESCUEMEAI EFI BOOT FILE COMPARISON
>>"%DETAILS%" echo fix_version=%FIX_VERSION%
>>"%DETAILS%" echo step=%STEP%
>>"%DETAILS%" echo efi_bootmgfw_compare=!BOOTMGFW!
>>"%DETAILS%" echo efi_bootstl_compare=!BOOTSTL!
>>"%DETAILS%" echo efi_bcd_present=!BCD!
>>"%DETAILS%" echo windows_changes_performed=NO
>>"%DETAILS%" echo personal_files_targeted=NO
"%MOUNTVOL%" %SYS% /D >nul 2>&1

>"%RESULT%" echo STATUS=PASS
>>"%RESULT%" echo MESSAGE=EFI boot-file comparison completed.
>>"%RESULT%" echo EVIDENCE=bootmgfw=!BOOTMGFW!; boot.stl=!BOOTSTL!; EFI BCD=!BCD!.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=NO
>>"%RESULT%" echo NEXT_STEP=If EFI boot files are stale or missing, RescueMeAI will refresh them from C:\Windows before another boot test.

echo STATUS              : COMPLETE - RESULT SENT FOR REVIEW
echo EFI BOOTMGFW        : !BOOTMGFW!
echo EFI BOOT.STL        : !BOOTSTL!
echo EFI BCD             : !BCD!
echo WINDOWS CHANGES     : NONE
echo WHAT YOU SHOULD DO  : WAIT.
echo SCREENSHOT REQUIRED : NO
exit /b 0

:FAIL
"%MOUNTVOL%" %SYS% /D >nul 2>&1
>"%RESULT%" echo STATUS=FAIL
>>"%RESULT%" echo MESSAGE=EFI system partition could not be mounted for comparison.
>>"%RESULT%" echo EVIDENCE=No Windows or EFI files were changed.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=YES
echo STATUS              : STOPPED - EFI MOUNT FAILED
echo SCREENSHOT REQUIRED : YES
exit /b 90
