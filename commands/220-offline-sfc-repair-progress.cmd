@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=REPAIR_WRITE
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Run offline System File Checker against the installed Windows image to repair protected system files using the local component store.
rem WR_ACTION=OFFLINE_SFC_REPAIR
rem WR_TARGET=Protected Windows system files under C:\Windows only; personal files are not targeted.
rem WR_CONSEQUENCE=SFC may replace corrupted protected Windows system files from the component store. No reset, format, partition, or personal-file operation is performed.
rem WR_ROLLBACK=Small boot-file safety copies are retained under C:\RescueMeAI\backups\pre-sfc. If SFC cannot repair files, RescueMeAI stops for review.

set "WORK=C:\WinRERepair"
set "BACKUP=C:\RescueMeAI\backups\pre-sfc"
set "DETAILS=%WORK%\RUN_DETAILS.txt"
set "RESULT=%WORK%\COMMAND_RESULT.env"
set "SFC=X:\Windows\System32\sfc.exe"
if not exist "%SFC%" set "SFC=C:\Windows\System32\sfc.exe"
if not exist "%WORK%" md "%WORK%" >nul 2>&1
if not exist "%BACKUP%" md "%BACKUP%" >nul 2>&1

cls
echo ================================================================================
echo RescueMeAI - OFFLINE SYSTEM FILE REPAIR
echo ================================================================================
echo STATUS            : RUNNING
echo CURRENT DIAGNOSIS : Startup Repair reported a recently serviced boot binary
echo                     is corrupt. The Microsoft repair payload is now verified.
echo CURRENT TASK      : Running System File Checker against C:\Windows.
echo SAFETY            : REPAIR-WRITE - protected Windows system files may be repaired.
echo PERSONAL FILES    : NOT TARGETED
echo RESET/FORMAT      : NO
echo REBOOT            : NOT YET
echo SCREENSHOT NEEDED : NO - wait for the final status below.
echo ================================================================================
echo.

echo [1/4] Saving small safety copies of key boot binaries...
if exist "C:\Windows\System32\winload.efi" copy /y "C:\Windows\System32\winload.efi" "%BACKUP%\winload.efi" >nul 2>&1
if exist "C:\Windows\System32\winresume.efi" copy /y "C:\Windows\System32\winresume.efi" "%BACKUP%\winresume.efi" >nul 2>&1
if exist "C:\Windows\Boot\EFI\bootmgfw.efi" copy /y "C:\Windows\Boot\EFI\bootmgfw.efi" "%BACKUP%\bootmgfw.efi" >nul 2>&1

echo [2/4] Confirming the offline Windows target...
if not exist "C:\Windows\System32\config\SYSTEM" goto :TARGETFAIL
if not exist "%SFC%" goto :SFCMISSING

echo [3/4] Scanning and repairing protected Windows system files...
echo.
echo       SFC will display its own progress below.
echo       Do NOT power off the computer while this scan is running.
echo -------------------------------------------------------------------------------
"%SFC%" /scannow /offbootdir=C:\ /offwindir=C:\Windows
set "SRC=!errorlevel!"
echo -------------------------------------------------------------------------------

echo [4/4] Recording the repair result...
>"%DETAILS%" echo RESCUEMEAI OFFLINE SFC REPAIR
>>"%DETAILS%" echo sfc_binary=%SFC%
>>"%DETAILS%" echo sfc_exit_code=!SRC!
>>"%DETAILS%" echo offbootdir=C:\
>>"%DETAILS%" echo offwindir=C:\Windows
>>"%DETAILS%" echo boot_file_safety_copy=%BACKUP%
>>"%DETAILS%" echo personal_files_targeted=NO
>>"%DETAILS%" echo reset_or_format=NO

if "!SRC!"=="0" (
  >"%RESULT%" echo STATUS=PASS
  >>"%RESULT%" echo MESSAGE=Offline System File Checker completed successfully.
  >>"%RESULT%" echo EVIDENCE=SFC exit code 0; key pre-repair boot-file safety copies retained locally.
  >>"%RESULT%" echo SCREENSHOT_REQUIRED=NO
  >>"%RESULT%" echo NEXT_STEP=RescueMeAI will run a read-only post-repair integrity check before deciding whether to reboot.
  echo.
  echo ================================================================================
  echo STATUS            : COMPLETE - SFC FINISHED
  echo RESULT            : Offline System File Checker completed successfully.
  echo WINDOWS CHANGES   : Protected system files may have been repaired.
  echo PERSONAL FILES    : NOT TARGETED
  echo REBOOT            : NOT YET
  echo NEXT STEP         : RescueMeAI will verify the repair before any boot test.
  echo SCREENSHOT NEEDED : NO
  echo WHAT TO DO        : Leave this window open and keep the PC connected to power.
  echo ================================================================================
  exit /b 0
)

>"%RESULT%" echo STATUS=WARNING
>>"%RESULT%" echo MESSAGE=Offline System File Checker did not return a clean success code.
>>"%RESULT%" echo EVIDENCE=SFC exit code attached; no reset, format, or reboot was performed.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=YES
>>"%RESULT%" echo NEXT_STEP=Send ChatGPT a photo of the final SFC screen before any further write.
echo.
echo ================================================================================
echo STATUS            : SFC NEEDS REVIEW
echo SFC EXIT CODE     : !SRC!
echo REBOOT            : NO
echo SCREENSHOT NEEDED : YES
echo WHAT TO DO        : Send ChatGPT a photo of THIS screen. Do not reboot yet.
echo ================================================================================
exit /b 40

:TARGETFAIL
>"%RESULT%" echo STATUS=FAIL
>>"%RESULT%" echo MESSAGE=Offline Windows target C:\Windows could not be verified.
>>"%RESULT%" echo EVIDENCE=No SFC repair was started.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=YES
echo.
echo STATUS            : STOPPED - WINDOWS TARGET NOT VERIFIED
echo WINDOWS CHANGES   : NONE
echo SCREENSHOT NEEDED : YES
exit /b 90

:SFCMISSING
>"%RESULT%" echo STATUS=FAIL
>>"%RESULT%" echo MESSAGE=No usable SFC executable was found.
>>"%RESULT%" echo EVIDENCE=No SFC repair was started.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=YES
echo.
echo STATUS            : STOPPED - SFC NOT AVAILABLE
echo WINDOWS CHANGES   : NONE
echo SCREENSHOT NEEDED : YES
exit /b 90
