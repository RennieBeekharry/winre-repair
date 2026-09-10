@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=REPAIR_WRITE
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Verify the actual EFI BCD store, verify the refreshed EFI boot manager, then perform a controlled Windows boot test.
rem WR_ACTION=CONTROLLED_BOOT_TEST_WITH_EFI_STORE_VALIDATION
rem WR_TARGET=Temporary EFI mount plus current computer restart only.
rem WR_CONSEQUENCE=Temporarily mounts the EFI system partition read-only in practice, reads its BCD, verifies bootmgfw.efi, unmounts EFI, then restarts. No EFI content, BCD content, registry, update package, partition layout, or personal file is changed.
rem WR_ROLLBACK=The EFI drive letter is removed before restart. Existing EFI and BCD safety copies remain on C:.

set "FIX_VERSION=RMAI-FIX-2026.09.10.3"
set "STEP=51"
set "WORK=C:\WinRERepair"
set "STATE=C:\RescueMeAI\state"
set "RESULT=%WORK%\COMMAND_RESULT.env"
set "DETAILS=%WORK%\RUN_DETAILS.txt"
set "SOURCE=C:\Windows\Boot\EFI\bootmgfw.efi"
set "MOUNTVOL=X:\Windows\System32\mountvol.exe"
if not exist "%MOUNTVOL%" set "MOUNTVOL=C:\Windows\System32\mountvol.exe"
set "BCDEDIT=X:\Windows\System32\bcdedit.exe"
if not exist "%BCDEDIT%" set "BCDEDIT=C:\Windows\System32\bcdedit.exe"
set "FC=X:\Windows\System32\fc.exe"
if not exist "%FC%" set "FC=C:\Windows\System32\fc.exe"
set "WPE=X:\Windows\System32\wpeutil.exe"
if not exist "%WPE%" set "WPE=wpeutil.exe"
set "PING=X:\Windows\System32\ping.exe"
if not exist "%PING%" set "PING=C:\Windows\System32\ping.exe"
set "SYS=S:"
if exist S:\nul set "SYS=T:"
if not exist "%STATE%" md "%STATE%" >nul 2>&1

cls
echo ================================================================================
echo RescueMeAI - CONTROLLED WINDOWS BOOT TEST
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : PRE-FLIGHT CHECK
echo CURRENT DIAGNOSIS   : The stale EFI boot manager has been replaced and verified.
echo PREVIOUS BLOCK      : Steps 49/50 queried the WinRE-visible BCD context instead
echo                       of explicitly validating the EFI BCD store.
echo CURRENT TASK        : Validate the actual EFI BCD and boot manager, then restart.
echo SAFETY              : EFI READ/VERIFY + RESTART ONLY; no BCD or EFI content edits.
echo PERSONAL FILES      : NOT TOUCHED
echo BITLOCKER           : A recovery-key prompt may appear after restart.
echo WHAT YOU SHOULD DO  : WAIT, then watch the screen during startup.
echo SCREENSHOT REQUIRED : ONLY if this step blocks or an error/recovery screen appears.
echo ================================================================================

>"%DETAILS%" echo RESCUEMEAI EFI-STORE VALIDATED BOOT TEST
>>"%DETAILS%" echo fix_version=%FIX_VERSION%
>>"%DETAILS%" echo step=%STEP%
>>"%DETAILS%" echo prior_step49_issue=wrong_reconnect_filename_check
>>"%DETAILS%" echo prior_step50_issue=wrong_bcd_context_check

echo [1/5] Verifying Windows and permanent reconnect...
if not exist "C:\Windows\System32\config\SYSTEM" goto :BLOCK_WINDOWS
if not exist "C:\Windows\System32\winload.efi" goto :BLOCK_WINDOWS
if not exist "%SOURCE%" goto :BLOCK_WINDOWS
if not exist "C:\r.cmd" goto :BLOCK_RECONNECT
if not exist "C:\RescueMeAI\reconnect.cmd" goto :BLOCK_RECONNECT
>>"%DETAILS%" echo windows_target=PASS
>>"%DETAILS%" echo reconnect_v3=PASS

echo [2/5] Confirming Wi-Fi recovery fallback...
set "PROFILE=NO"
for %%D in (E F G H I J K L M) do if exist "%%D:\Wi-Fi-404 Network Unavailable.xml" set "PROFILE=YES"
>>"%DETAILS%" echo wifi_recovery_profile=!PROFILE!
echo       Wi-Fi fallback profile: !PROFILE!

echo [3/5] Mounting EFI and validating the actual EFI boot manager...
"%MOUNTVOL%" %SYS% /S >"%WORK%\step51-mount.txt" 2>&1
if errorlevel 1 goto :BLOCK_EFI
set "DEST=%SYS%\EFI\Microsoft\Boot\bootmgfw.efi"
set "BCD=%SYS%\EFI\Microsoft\Boot\BCD"
if not exist "!DEST!" goto :BLOCK_EFI_MOUNTED
if not exist "!BCD!" goto :BLOCK_EFI_MOUNTED
"%FC%" /b "%SOURCE%" "!DEST!" >nul 2>&1
if errorlevel 1 goto :BLOCK_EFI_MOUNTED
>>"%DETAILS%" echo efi_bootmgfw_compare=SAME

echo [4/5] Validating the actual EFI BCD default loader...
"%BCDEDIT%" /store "!BCD!" /enum {default} >"%WORK%\step51-efi-bcd.txt" 2>&1
if errorlevel 1 goto :BLOCK_BCD_MOUNTED
findstr /i /c:"\WINDOWS\system32\winload.efi" "%WORK%\step51-efi-bcd.txt" >nul 2>&1
if errorlevel 1 goto :BLOCK_BCD_MOUNTED
set "PARTC=0"
for /f "delims=" %%N in ('findstr /i /c:"partition=C:" "%WORK%\step51-efi-bcd.txt" ^| find /c /v ""') do set "PARTC=%%N"
if !PARTC! LSS 2 goto :BLOCK_BCD_MOUNTED
>>"%DETAILS%" echo efi_bcd_default=PASS
>>"%DETAILS%" echo efi_bcd_partition_c_lines=!PARTC!
"%MOUNTVOL%" %SYS% /D >nul 2>&1

echo [5/5] Marking the controlled test and restarting...
>"%STATE%\boot-test-51.pending" echo status=STARTING
>>"%STATE%\boot-test-51.pending" echo fix_version=%FIX_VERSION%
>>"%STATE%\boot-test-51.pending" echo reason=efi_store_and_boot_manager_verified
>>"%DETAILS%" echo boot_test_marker=C:\RescueMeAI\state\boot-test-51.pending

>"%RESULT%" echo STATUS=PASS
>>"%RESULT%" echo MESSAGE=Controlled Windows boot test is starting after direct EFI boot manager and EFI BCD validation.
>>"%RESULT%" echo EVIDENCE=Windows target and reconnect helper passed; EFI bootmgfw matched C:\Windows byte-for-byte; EFI BCD default points to C:\WINDOWS\system32\winload.efi with device and osdevice on C:.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=CONDITIONAL
>>"%RESULT%" echo NEXT_STEP=If Windows boots, reply SUCCESS. If BitLocker appears, enter the key locally. If Recovery/error returns, send a photo; at CMD use C:\r.cmd.

echo.
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : READY - RESTARTING INTO WINDOWS
echo EFI BOOT MANAGER    : VERIFIED
echo EFI BCD             : VERIFIED
echo QUICK RECONNECT     : C:\r.cmd
echo IF BITLOCKER APPEARS: Enter the 48-digit key locally; do not send it.
echo IF WINDOWS BOOTS    : Reply SUCCESS.
echo IF RECOVERY/ERROR   : Reply FAILED and send a photo.
echo IF HP SPINNER HANGS : Wait 10 minutes, then reply STUCK with a photo.
echo ================================================================================
echo Rebooting in about 10 seconds...
"%PING%" -n 11 127.0.0.1 >nul 2>&1
"%WPE%" reboot
set "RRC=!errorlevel!"
>"%RESULT%" echo STATUS=FAIL
>>"%RESULT%" echo MESSAGE=The controlled restart command returned instead of restarting.
>>"%RESULT%" echo EVIDENCE=wpeutil reboot exit code !RRC!.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=YES
echo STATUS              : RESTART DID NOT START
echo SCREENSHOT REQUIRED : YES
echo WHAT YOU SHOULD DO  : Reply FAILED and send a photo.
exit /b 90

:BLOCK_EFI_MOUNTED
set "BLOCK_REASON=EFI_FILE_OR_BCD_MISSING"
goto :BLOCK_MOUNTED
:BLOCK_BCD_MOUNTED
set "BLOCK_REASON=EFI_BCD_VALIDATION_FAILED"
goto :BLOCK_MOUNTED
:BLOCK_MOUNTED
"%MOUNTVOL%" %SYS% /D >nul 2>&1
goto :BLOCK
:BLOCK_EFI
set "BLOCK_REASON=EFI_MOUNT_FAILED"
goto :BLOCK
:BLOCK_WINDOWS
set "BLOCK_REASON=WINDOWS_PREREQUISITE_MISSING"
goto :BLOCK
:BLOCK_RECONNECT
set "BLOCK_REASON=RECONNECT_HELPER_MISSING"
goto :BLOCK

:BLOCK
>"%RESULT%" echo STATUS=WARNING
>>"%RESULT%" echo MESSAGE=Controlled boot test was blocked by a direct EFI-store pre-flight check.
>>"%RESULT%" echo EVIDENCE=block_reason=!BLOCK_REASON!; no restart was started and no EFI or BCD content or personal file was changed.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=YES
>>"%DETAILS%" echo block_reason=!BLOCK_REASON!
echo.
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : BOOT TEST BLOCKED
echo BLOCK REASON        : !BLOCK_REASON!
echo REBOOT              : NO
echo SCREENSHOT REQUIRED : YES
echo WHAT YOU SHOULD DO  : Reply FAILED and send a photo. Do not reboot manually.
echo ================================================================================
exit /b 40
