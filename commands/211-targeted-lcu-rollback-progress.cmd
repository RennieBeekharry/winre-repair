@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=REPAIR_WRITE
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Remove the exact installed RollupFix cumulative update that matches the serviced-boot-binary failure.
rem WR_ACTION=ROLLBACK_CURRENT_LCU
rem WR_TARGET=Offline Windows installation on C:; exact RollupFix package 26100.9168.1.19 only.
rem WR_CONSEQUENCE=Uninstalls the current Windows cumulative update package. Personal files are not targeted. A reboot will be required before validating boot.
rem WR_ROLLBACK=If removal fails, RescueMeAI stops and preserves DISM logs. If it succeeds, the package is rolled back to the previous servicing level on reboot.

set "WORK=C:\WinRERepair"
set "SCRATCH=C:\RescueMeAI\scratch"
set "BACKUP=C:\RescueMeAI\backups\pre-lcu-rollback"
set "LOG=%WORK%\remove-rollupfix-9168.log"
set "DETAILS=%WORK%\RUN_DETAILS.txt"
set "RESULT=%WORK%\COMMAND_RESULT.env"
set "PKG=Package_for_RollupFix~31bf3856ad364e35~amd64~~26100.9168.1.19"
if not exist "%WORK%" md "%WORK%" >nul 2>&1
if not exist "%SCRATCH%" md "%SCRATCH%" >nul 2>&1
if not exist "%BACKUP%" md "%BACKUP%" >nul 2>&1

cls
echo ================================================================================
echo RescueMeAI - TARGETED WINDOWS REPAIR
echo ================================================================================
echo STATUS            : RUNNING
echo CURRENT DIAGNOSIS : Startup Repair found a recently serviced boot binary corrupt.
echo                     The exact installed RollupFix package is 26100.9168.1.19.
echo CURRENT TASK      : Rolling back that exact cumulative-update package.
echo SAFETY            : REPAIR-WRITE - Windows system components will change.
echo PERSONAL FILES    : NOT TARGETED
echo RESET/FORMAT      : NO
echo SCREENSHOT NEEDED : NO - wait for the final status below.
echo ================================================================================
echo.

>"%DETAILS%" echo RESCUEMEAI TARGETED LCU ROLLBACK
>>"%DETAILS%" echo package=%PKG%
>>"%DETAILS%" echo diagnosis=recently serviced boot binary corrupt
>>"%DETAILS%" echo personal_files_targeted=NO

echo [1/4] Verifying the exact package is still installed...
dism /English /Image:C:\ /Get-Packages /Format:Table >"%WORK%\pre-remove-packages.txt" 2>&1
findstr /i /c:"%PKG%" "%WORK%\pre-remove-packages.txt" >nul 2>&1
if errorlevel 1 (
  >"%RESULT%" echo STATUS=FAIL
  >>"%RESULT%" echo MESSAGE=The exact RollupFix package is no longer present; rollback was not attempted.
  >>"%RESULT%" echo EVIDENCE=Preflight package check failed.
  >>"%RESULT%" echo SCREENSHOT_REQUIRED=YES
  echo.
  echo [STOPPED] Exact target package was not found.
  echo WINDOWS CHANGES   : NONE
  echo SCREENSHOT NEEDED : YES
  echo Send ChatGPT a photo of THIS screen.
  exit /b 90
)

echo [2/4] Saving small boot-file safety copies...
if exist "C:\Windows\System32\winload.efi" copy /y "C:\Windows\System32\winload.efi" "%BACKUP%\winload.efi" >nul 2>&1
if exist "C:\Windows\System32\winresume.efi" copy /y "C:\Windows\System32\winresume.efi" "%BACKUP%\winresume.efi" >nul 2>&1
if exist "C:\Windows\Boot\EFI\bootmgfw.efi" copy /y "C:\Windows\Boot\EFI\bootmgfw.efi" "%BACKUP%\bootmgfw.efi" >nul 2>&1
>>"%DETAILS%" echo boot_file_safety_copy=%BACKUP%

echo [3/4] Removing the current cumulative update...
echo.
echo DISM will show its own percentage/progress below.
echo Do NOT power off the computer while this step is running.
echo ------------------------------------------------------------------------------
dism /English /Image:C:\ /Remove-Package /PackageName:"%PKG%" /ScratchDir:"%SCRATCH%" /LogPath:"%LOG%"
set "DRC=!errorlevel!"
echo ------------------------------------------------------------------------------
>>"%DETAILS%" echo dism_remove_exit_code=!DRC!

echo [4/4] Verifying the post-removal package state...
dism /English /Image:C:\ /Get-Packages /Format:Table >"%WORK%\post-remove-packages.txt" 2>&1
findstr /i /c:"%PKG%" "%WORK%\post-remove-packages.txt" >"%WORK%\post-remove-match.txt" 2>nul
for /f "usebackq delims=" %%L in ("%WORK%\post-remove-match.txt") do >>"%DETAILS%" echo post_remove_package_row=%%L
if not exist "%WORK%\post-remove-match.txt" >>"%DETAILS%" echo post_remove_package_row=NOT_LISTED

if not "!DRC!"=="0" (
  >>"%DETAILS%" echo rollback_result=FAILED
  >"%RESULT%" echo STATUS=FAIL
  >>"%RESULT%" echo MESSAGE=Targeted cumulative-update rollback failed; Windows was not rebooted.
  >>"%RESULT%" echo EVIDENCE=DISM exit code and post-removal package state attached; full log retained locally.
  >>"%RESULT%" echo SCREENSHOT_REQUIRED=YES
  >>"%RESULT%" echo NEXT_STEP=Send ChatGPT a photo of the final screen; RescueMeAI will review the failure before any further write.
  echo.
  echo ================================================================================
  echo STATUS            : FAILED
  echo RESULT            : Targeted cumulative-update rollback did not complete.
  echo WINDOWS REBOOTED  : NO
  echo NEXT STEP         : RescueMeAI must review the DISM failure before continuing.
  echo SCREENSHOT NEEDED : YES
  echo WHAT TO DO        : Send ChatGPT a photo of THIS screen. Do not reboot yet.
  echo ================================================================================
  exit /b 90
)

>>"%DETAILS%" echo rollback_result=SUCCESS
>"%RESULT%" echo STATUS=PASS
>>"%RESULT%" echo MESSAGE=Targeted cumulative-update rollback completed successfully; reboot is required to finalize and test boot.
>>"%RESULT%" echo EVIDENCE=DISM exit code and post-removal package state attached; full log retained locally.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=NO
>>"%RESULT%" echo NEXT_STEP=RescueMeAI will review the successful rollback and then perform a controlled reboot.

echo.
echo ================================================================================
echo STATUS            : COMPLETE - REPAIR APPLIED
echo RESULT            : Targeted cumulative-update rollback completed successfully.
echo WINDOWS CHANGES   : RollupFix 26100.9168.1.19 removed from the offline image.
echo PERSONAL FILES    : NOT TARGETED
echo REBOOT REQUIRED   : YES - but wait for RescueMeAI to issue the controlled reboot.
echo NEXT STEP         : RescueMeAI is reviewing this result now.
echo SCREENSHOT NEEDED : NO
echo WHAT TO DO        : Leave this window open and keep the PC connected to power.
echo ================================================================================
exit /b 0
