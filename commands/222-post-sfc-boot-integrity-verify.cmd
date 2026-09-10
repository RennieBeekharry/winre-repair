@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=READ_ONLY
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Verify the offline Windows image after SFC and summarize boot-file repair evidence without making further changes.
rem WR_ACTION=POST_SFC_BOOT_INTEGRITY_VERIFY
rem WR_TARGET=Offline Windows installation C:\Windows and its CBS/SFC logs only.
rem WR_CONSEQUENCE=Runs SFC in verify-only mode and reads servicing logs. No Windows files, packages, partitions, or personal data are changed.
rem WR_ROLLBACK=Not applicable; this command is read-only.

set "WORK=C:\WinRERepair"
set "DETAILS=%WORK%\RUN_DETAILS.txt"
set "RESULT=%WORK%\COMMAND_RESULT.env"
set "CBS=C:\Windows\Logs\CBS\CBS.log"
set "SFC=X:\Windows\System32\sfc.exe"
if not exist "%SFC%" set "SFC=C:\Windows\System32\sfc.exe"
if not exist "%WORK%" md "%WORK%" >nul 2>&1

cls
echo ================================================================================
echo RescueMeAI - POST-REPAIR BOOT INTEGRITY CHECK
echo ================================================================================
echo STATUS            : RUNNING
echo CURRENT DIAGNOSIS : Startup Repair reported a recently serviced boot binary
echo                     as corrupt. Offline SFC has now completed successfully.
echo CURRENT TASK      : Verifying protected Windows files and reviewing SFC evidence.
echo SAFETY            : READ-ONLY - no additional Windows changes are being made.
echo PERSONAL FILES    : NOT TOUCHED
echo REBOOT            : NOT YET
echo SCREENSHOT NEEDED : NO - wait for the final status below.
echo ================================================================================
echo.

>"%DETAILS%" echo RESCUEMEAI POST-SFC BOOT INTEGRITY VERIFY

echo [1/4] Confirming the offline Windows target and key boot binaries...
set "TARGET=YES"
if not exist "C:\Windows\System32\config\SYSTEM" set "TARGET=NO"
set "WINLOAD=NO"
set "WINRESUME=NO"
set "BOOTMGFW=NO"
if exist "C:\Windows\System32\winload.efi" set "WINLOAD=YES"
if exist "C:\Windows\System32\winresume.efi" set "WINRESUME=YES"
if exist "C:\Windows\Boot\EFI\bootmgfw.efi" set "BOOTMGFW=YES"
>>"%DETAILS%" echo target_verified=!TARGET!
>>"%DETAILS%" echo winload_present=!WINLOAD!
>>"%DETAILS%" echo winresume_present=!WINRESUME!
>>"%DETAILS%" echo bootmgfw_present=!BOOTMGFW!
if /i not "!TARGET!"=="YES" goto :VERIFYFAIL
if not exist "%SFC%" goto :VERIFYFAIL

echo [2/4] Running SFC verification only against C:\Windows...
echo.
echo       This is a verification scan only. It does not repair or replace files.
echo -------------------------------------------------------------------------------
"%SFC%" /verifyonly /offbootdir=C:\ /offwindir=C:\Windows
set "VRC=!errorlevel!"
echo -------------------------------------------------------------------------------
>>"%DETAILS%" echo sfc_verify_exit_code=!VRC!

echo [3/4] Reviewing CBS/SFC evidence from the completed repair...
set "UNREPAIRED=UNKNOWN"
set "REPAIRED=UNKNOWN"
if exist "%CBS%" (
  for /f "delims=" %%N in ('findstr /i /c:"Cannot repair member file" "%CBS%" ^| find /c /v ""') do set "UNREPAIRED=%%N"
  for /f "delims=" %%N in ('findstr /i /c:"Repairing corrupted file" /c:"Repairing corrupted member file" "%CBS%" ^| find /c /v ""') do set "REPAIRED=%%N"
)
>>"%DETAILS%" echo cbs_unrepaired_member_lines=!UNREPAIRED!
>>"%DETAILS%" echo cbs_repair_action_lines=!REPAIRED!

echo [4/4] Recording the boot-test readiness decision...
set "READY=YES"
if not "!VRC!"=="0" set "READY=NO"
if /i not "!WINLOAD!"=="YES" set "READY=NO"
if /i not "!WINRESUME!"=="YES" set "READY=NO"
if /i not "!BOOTMGFW!"=="YES" set "READY=NO"
if not "!UNREPAIRED!"=="UNKNOWN" if not "!UNREPAIRED!"=="0" set "READY=NO"
>>"%DETAILS%" echo controlled_boot_test_ready=!READY!
>>"%DETAILS%" echo windows_changes_performed=NO

if /i "!READY!"=="YES" (
  >"%RESULT%" echo STATUS=PASS
  >>"%RESULT%" echo MESSAGE=Post-SFC verification is clean and the offline image is ready for a controlled Windows boot test.
  >>"%RESULT%" echo EVIDENCE=SFC verify-only exit 0; key boot binaries present; no unrepaired-member lines detected in CBS.
  >>"%RESULT%" echo SCREENSHOT_REQUIRED=NO
  >>"%RESULT%" echo NEXT_STEP=RescueMeAI will prepare a controlled reboot to test Windows startup.
  echo.
  echo ================================================================================
  echo STATUS            : COMPLETE - VERIFICATION CLEAN
  echo RESULT            : Protected Windows files passed the post-repair verification.
  echo BOOT FILES        : winload.efi, winresume.efi, and bootmgfw.efi are present.
  echo WINDOWS CHANGES   : NONE IN THIS STEP
  echo NEXT STEP         : RescueMeAI will prepare a controlled Windows boot test.
  echo SCREENSHOT NEEDED : NO
  echo WHAT TO DO        : Leave this window open and keep the computer on power.
  echo ================================================================================
  exit /b 0
)

>"%RESULT%" echo STATUS=WARNING
>>"%RESULT%" echo MESSAGE=Post-SFC verification needs review before any reboot.
>>"%RESULT%" echo EVIDENCE=Verify-only exit code, boot-file presence, and bounded CBS repair indicators attached.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=YES
>>"%RESULT%" echo NEXT_STEP=Send ChatGPT a photo of the final screen; do not reboot yet.
echo.
echo ================================================================================
echo STATUS            : NEEDS REVIEW
echo SFC VERIFY CODE   : !VRC!
echo BOOT FILES        : winload=!WINLOAD! winresume=!WINRESUME! bootmgfw=!BOOTMGFW!
echo UNREPAIRED LINES  : !UNREPAIRED!
echo REBOOT            : NO
echo SCREENSHOT NEEDED : YES
echo WHAT TO DO        : Send ChatGPT a photo of THIS screen. Do not reboot yet.
echo ================================================================================
exit /b 40

:VERIFYFAIL
>"%RESULT%" echo STATUS=FAIL
>>"%RESULT%" echo MESSAGE=Post-SFC verification could not start because the Windows target or SFC executable was unavailable.
>>"%RESULT%" echo EVIDENCE=No Windows changes were made.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=YES
echo.
echo STATUS            : STOPPED - VERIFY PREREQUISITE MISSING
echo WINDOWS CHANGES   : NONE
echo SCREENSHOT NEEDED : YES
exit /b 90
