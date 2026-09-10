@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=READ_ONLY
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Compare the pre-SFC safety copies of key boot binaries with the current files to determine whether SFC changed them.
rem WR_ACTION=COMPARE_PRE_AND_POST_SFC_BOOT_BINARIES
rem WR_TARGET=C:\RescueMeAI\backups\pre-sfc and current protected boot binaries under C:\Windows only.
rem WR_CONSEQUENCE=Reads file size and binary equality only and writes bounded diagnostic text under C:\WinRERepair. No Windows, boot, registry, package, disk, or personal-file changes are made.
rem WR_ROLLBACK=Not applicable; this command is read-only.

set "FIX_VERSION=RMAI-FIX-2026.09.10.2"
set "STEP=36"
set "WORK=C:\WinRERepair"
set "BACKUP=C:\RescueMeAI\backups\pre-sfc"
set "DETAILS=%WORK%\RUN_DETAILS.txt"
set "RESULT=%WORK%\COMMAND_RESULT.env"
set "FC=C:\Windows\System32\fc.exe"
if not exist "%FC%" set "FC=X:\Windows\System32\fc.exe"
if not exist "%WORK%" md "%WORK%" >nul 2>&1

cls
echo ================================================================================
echo RescueMeAI - PRE/POST SFC BOOT BINARY COMPARISON
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : RUNNING
echo CURRENT DIAGNOSIS   : BCD is structurally normal and no servicing transaction
echo                       is pending. Windows still stalls during normal boot.
echo CURRENT TASK        : Comparing the exact boot binaries saved before SFC with
echo                       the files currently present after SFC.
echo SAFETY              : READ-ONLY - no Windows repair is running in this step.
echo PERSONAL FILES      : NOT TOUCHED
echo REBOOT              : NO
echo WHAT YOU SHOULD DO  : WAIT. Leave this window open and keep the laptop on power.
echo SCREENSHOT REQUIRED : NO
echo ================================================================================

>"%DETAILS%" echo RESCUEMEAI PRE POST SFC BOOT BINARY COMPARISON
>>"%DETAILS%" echo fix_version=%FIX_VERSION%
>>"%DETAILS%" echo step=%STEP%

echo.
echo [1/4] Verifying the Windows target, backup folder, and reconnect helper...
set "TARGET=NO"
set "BACKUP_OK=NO"
set "RECONNECT=NO"
if exist "C:\Windows\System32\config\SYSTEM" set "TARGET=YES"
if exist "%BACKUP%" set "BACKUP_OK=YES"
if exist "C:\r.cmd" if exist "C:\RescueMeAI\reconnect.cmd" set "RECONNECT=YES"
>>"%DETAILS%" echo target_verified=!TARGET!
>>"%DETAILS%" echo backup_folder_present=!BACKUP_OK!
>>"%DETAILS%" echo quick_reconnect_installed=!RECONNECT!
if /i not "!TARGET!"=="YES" goto :FAIL
if /i not "!BACKUP_OK!"=="YES" goto :FAIL

set "WINLOAD=NOT_AVAILABLE"
set "WINRESUME=NOT_AVAILABLE"
set "BOOTMGFW=NOT_AVAILABLE"

echo [2/4] Comparing winload.efi...
call :COMPARE_ONE "%BACKUP%\winload.efi" "C:\Windows\System32\winload.efi" WINLOAD

echo [3/4] Comparing winresume.efi...
call :COMPARE_ONE "%BACKUP%\winresume.efi" "C:\Windows\System32\winresume.efi" WINRESUME

echo [4/4] Comparing bootmgfw.efi and recording the result...
call :COMPARE_ONE "%BACKUP%\bootmgfw.efi" "C:\Windows\Boot\EFI\bootmgfw.efi" BOOTMGFW

set "ANY_CHANGED=NO"
if /i "!WINLOAD!"=="CHANGED" set "ANY_CHANGED=YES"
if /i "!WINRESUME!"=="CHANGED" set "ANY_CHANGED=YES"
if /i "!BOOTMGFW!"=="CHANGED" set "ANY_CHANGED=YES"

>>"%DETAILS%" echo winload_compare=!WINLOAD!
>>"%DETAILS%" echo winresume_compare=!WINRESUME!
>>"%DETAILS%" echo bootmgfw_compare=!BOOTMGFW!
>>"%DETAILS%" echo any_key_boot_binary_changed_by_sfc=!ANY_CHANGED!
>>"%DETAILS%" echo windows_changes_performed=NO
>>"%DETAILS%" echo personal_files_targeted=NO

>"%RESULT%" echo STATUS=PASS
>>"%RESULT%" echo MESSAGE=Pre/post SFC boot-binary comparison completed successfully.
>>"%RESULT%" echo EVIDENCE=Fix %FIX_VERSION%; winload=!WINLOAD!; winresume=!WINRESUME!; bootmgfw=!BOOTMGFW!; any changed=!ANY_CHANGED!; reconnect=!RECONNECT!.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=NO
>>"%RESULT%" echo NEXT_STEP=RescueMeAI will use this result to choose between a boot-driver isolation test and targeted servicing.

echo.
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : COMPLETE - RESULT SENT FOR REVIEW
echo WINLOAD.EFI         : !WINLOAD!
echo WINRESUME.EFI       : !WINRESUME!
echo BOOTMGFW.EFI        : !BOOTMGFW!
echo ANY KEY FILE CHANGED: !ANY_CHANGED!
echo QUICK RECONNECT     : !RECONNECT!  (future command: C:\r.cmd)
echo WINDOWS CHANGES     : NONE
echo REBOOT              : NO
echo WHAT YOU SHOULD DO  : WAIT. Leave this window open.
echo SCREENSHOT REQUIRED : NO
echo ================================================================================
exit /b 0

:COMPARE_ONE
set "OLD=%~1"
set "NEW=%~2"
set "OUTVAR=%~3"
if not exist "%OLD%" (
  set "%OUTVAR%=BACKUP_MISSING"
  exit /b 0
)
if not exist "%NEW%" (
  set "%OUTVAR%=CURRENT_MISSING"
  exit /b 0
)
for %%F in ("%OLD%") do >>"%DETAILS%" echo %OUTVAR%_backup_bytes=%%~zF
for %%F in ("%NEW%") do >>"%DETAILS%" echo %OUTVAR%_current_bytes=%%~zF
"%FC%" /b "%OLD%" "%NEW%" >nul 2>&1
if errorlevel 2 (
  set "%OUTVAR%=COMPARE_ERROR"
  exit /b 0
)
if errorlevel 1 (
  set "%OUTVAR%=CHANGED"
  exit /b 0
)
set "%OUTVAR%=SAME"
exit /b 0

:FAIL
>"%RESULT%" echo STATUS=FAIL
>>"%RESULT%" echo MESSAGE=Boot-binary comparison stopped because required local recovery evidence was missing.
>>"%RESULT%" echo EVIDENCE=No Windows changes were made.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=YES
echo.
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : STOPPED - REQUIRED LOCAL EVIDENCE MISSING
echo WINDOWS CHANGES     : NONE
echo REBOOT              : NO
echo SCREENSHOT REQUIRED : YES
echo WHAT YOU SHOULD DO  : Reply FAILED and send ChatGPT a photo of THIS screen.
echo ================================================================================
exit /b 90
