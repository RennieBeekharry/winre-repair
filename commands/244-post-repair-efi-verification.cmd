@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=REPAIR_WRITE
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Temporarily mount the EFI system partition, verify the refreshed boot manager and inspect its BCD, then unmount it.
rem WR_ACTION=VERIFY_EFI_BOOT_REPAIR
rem WR_TARGET=EFI system partition read verification plus RescueMeAI diagnostic text only.
rem WR_CONSEQUENCE=Temporarily assigns an EFI drive letter for verification and removes it afterward. No EFI file, BCD entry, Windows registry, update package, or personal file is changed.
rem WR_ROLLBACK=The temporary EFI drive letter is removed before exit.

set "FIX_VERSION=RMAI-FIX-2026.09.10.3"
set "STEP=47"
set "WORK=C:\WinRERepair"
set "RESULT=%WORK%\COMMAND_RESULT.env"
set "DETAILS=%WORK%\RUN_DETAILS.txt"
set "SOURCE=C:\Windows\Boot\EFI\bootmgfw.efi"
set "MOUNTVOL=X:\Windows\System32\mountvol.exe"
if not exist "%MOUNTVOL%" set "MOUNTVOL=C:\Windows\System32\mountvol.exe"
set "FC=X:\Windows\System32\fc.exe"
if not exist "%FC%" set "FC=C:\Windows\System32\fc.exe"
set "BCDEDIT=X:\Windows\System32\bcdedit.exe"
if not exist "%BCDEDIT%" set "BCDEDIT=C:\Windows\System32\bcdedit.exe"
set "SYS=S:"
if exist S:\nul set "SYS=T:"

cls
echo ================================================================================
echo RescueMeAI - POST-REPAIR EFI VERIFICATION
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : RUNNING
echo CURRENT TASK        : Verifying the refreshed EFI boot manager and active BCD.
echo SAFETY              : DIAGNOSTIC - temporary EFI mount only; no EFI content change.
echo PERSONAL FILES      : NOT TOUCHED
echo REBOOT              : NO
echo WHAT YOU SHOULD DO  : WAIT. Keep the laptop on power.
echo SCREENSHOT REQUIRED : NO unless this step stops.
echo ================================================================================

if not exist "%SOURCE%" goto :FAIL
echo [1/4] Temporarily mounting EFI system partition...
"%MOUNTVOL%" %SYS% /S >"%WORK%\step47-mount.txt" 2>&1
if errorlevel 1 goto :FAIL
set "DEST=%SYS%\EFI\Microsoft\Boot\bootmgfw.efi"
set "BCD=%SYS%\EFI\Microsoft\Boot\BCD"
if not exist "!DEST!" goto :MOUNTFAIL
if not exist "!BCD!" goto :MOUNTFAIL

echo [2/4] Comparing EFI boot manager byte-for-byte...
set "COMPARE=DIFFERENT"
"%FC%" /b "%SOURCE%" "!DEST!" >nul 2>&1 && set "COMPARE=SAME"

echo [3/4] Reading EFI BCD default loader...
"%BCDEDIT%" /store "!BCD!" /enum {default} >"%WORK%\step47-bcd-default.txt" 2>&1
set "BCDRC=!errorlevel!"
set "WINLOAD=NO"
set "DEVICE=NO"
set "OSDEVICE=NO"
if exist "%WORK%\step47-bcd-default.txt" (
  findstr /i /c:"\WINDOWS\system32\winload.efi" "%WORK%\step47-bcd-default.txt" >nul 2>&1 && set "WINLOAD=YES"
  findstr /i /c:"device                  partition=C:" "%WORK%\step47-bcd-default.txt" >nul 2>&1 && set "DEVICE=YES"
  findstr /i /c:"osdevice                partition=C:" "%WORK%\step47-bcd-default.txt" >nul 2>&1 && set "OSDEVICE=YES"
)

echo [4/4] Recording result and removing temporary EFI drive letter...
>"%DETAILS%" echo RESCUEMEAI POST REPAIR EFI VERIFICATION
>>"%DETAILS%" echo fix_version=%FIX_VERSION%
>>"%DETAILS%" echo step=%STEP%
>>"%DETAILS%" echo efi_bootmgfw_compare=!COMPARE!
>>"%DETAILS%" echo bcd_query_exit=!BCDRC!
>>"%DETAILS%" echo bcd_winload=!WINLOAD!
>>"%DETAILS%" echo bcd_device_c=!DEVICE!
>>"%DETAILS%" echo bcd_osdevice_c=!OSDEVICE!
>>"%DETAILS%" echo reconnect_v3_present=YES
>>"%DETAILS%" echo personal_files_targeted=NO
"%MOUNTVOL%" %SYS% /D >nul 2>&1

if /i "!COMPARE!!WINLOAD!!DEVICE!!OSDEVICE!"=="SAMEYESYESYES" goto :PASS
>"%RESULT%" echo STATUS=WARNING
>>"%RESULT%" echo MESSAGE=Post-repair EFI verification needs review before any boot test.
>>"%RESULT%" echo EVIDENCE=bootmgfw=!COMPARE!; BCD rc=!BCDRC!; winload=!WINLOAD!; device C=!DEVICE!; osdevice C=!OSDEVICE!.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=YES
echo STATUS              : REVIEW REQUIRED
echo SCREENSHOT REQUIRED : YES
echo WHAT YOU SHOULD DO  : Reply FAILED and send a photo. Do not reboot.
exit /b 40

:PASS
>"%RESULT%" echo STATUS=PASS
>>"%RESULT%" echo MESSAGE=EFI boot repair verified successfully and active BCD remains valid.
>>"%RESULT%" echo EVIDENCE=EFI bootmgfw matches C:\Windows source byte-for-byte; BCD default uses C:\Windows\system32\winload.efi with device and osdevice on C:.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=NO
>>"%RESULT%" echo NEXT_STEP=RescueMeAI may proceed to a controlled Windows boot test after review.
echo.
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : COMPLETE - EFI REPAIR VERIFIED
echo EFI BOOT MANAGER    : MATCH
echo ACTIVE BCD          : VALID
echo QUICK RECONNECT     : C:\r.cmd
echo REBOOT              : NOT YET
echo WHAT YOU SHOULD DO  : WAIT. Leave this window open.
echo SCREENSHOT REQUIRED : NO
echo ================================================================================
exit /b 0

:MOUNTFAIL
"%MOUNTVOL%" %SYS% /D >nul 2>&1
:FAIL
>"%RESULT%" echo STATUS=FAIL
>>"%RESULT%" echo MESSAGE=EFI verification could not complete.
>>"%RESULT%" echo EVIDENCE=No EFI file or BCD entry was changed; no reboot was performed.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=YES
echo STATUS              : STOPPED - EFI VERIFICATION FAILED
echo SCREENSHOT REQUIRED : YES
echo WHAT YOU SHOULD DO  : Reply FAILED and send a photo. Do not reboot.
exit /b 90
