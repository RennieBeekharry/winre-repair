@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=REPAIR_WRITE
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Save the minimum RescueMeAI reconnect toolkit to the removable recovery USB before clean installation, excluding GitHub authorization tokens and personal files.
rem WR_ACTION=BACKUP_RECONNECT_TOOLKIT_TO_USB
rem WR_TARGET=Removable recovery USB RescueMeAI-Reconnect-Kit folder only.
rem WR_CONSEQUENCE=Copies only RescueMeAI scripts/configuration needed for recovery reconnection to the user's removable USB. The GitHub authorization token is explicitly excluded. No Windows system setting, partition, BCD/EFI file, personal file, or reboot is changed.
rem WR_ROLLBACK=Delete the RescueMeAI-Reconnect-Kit folder from the USB if no longer wanted.
set "FIX_VERSION=RMAI-FIX-2026.09.10.4"
set "STEP=87"
set "WORK=C:\WinRERepair"
set "RESULT=%WORK%\COMMAND_RESULT.env"
set "DETAILS=%WORK%\RUN_DETAILS.txt"
set "CERT=X:\Windows\System32\certutil.exe"
if not exist "%CERT%" set "CERT=C:\Windows\System32\certutil.exe"

cls
echo ================================================================================
echo RescueMeAI - SAVE RECONNECT TOOLKIT TO USB
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : RUNNING
echo CURRENT TASK        : Save the minimum reconnect toolkit needed for this recovery.
echo PRIVACY             : PERSONAL FILES ARE NOT READ OR COPIED.
echo SECRETS             : GITHUB AUTHORIZATION TOKEN WILL NOT BE COPIED.
echo WINDOWS CHANGES     : NONE
echo REBOOT              : NO
echo WHAT YOU SHOULD DO  : WAIT. Keep the recovery USB inserted.
echo SCREENSHOT REQUIRED : NO unless this step stops with an error.
echo ================================================================================

if not exist "%WORK%" md "%WORK%" >nul 2>&1
> "%DETAILS%" echo RESCUEMEAI RECONNECT TOOLKIT USB BACKUP
>>"%DETAILS%" echo fix_version=%FIX_VERSION%
>>"%DETAILS%" echo step=%STEP%

echo [1/4] Locating the removable recovery USB...
set "USB="
for %%D in (D E F G H I J K L M N O P Q R S T U V W Y Z) do (
  if not defined USB if exist "%%D:\Wi-Fi-404 Network Unavailable.xml" set "USB=%%D:"
  if not defined USB if exist "%%D:\RescueMeAI-Preinstall-Backup\" set "USB=%%D:"
)
if not defined USB goto :FAIL
set "DEST=!USB!\RescueMeAI-Reconnect-Kit"
if not exist "!DEST!" md "!DEST!" >nul 2>&1
if errorlevel 1 goto :FAIL
>>"%DETAILS%" echo recovery_usb_detected=YES
>>"%DETAILS%" echo reconnect_kit_folder_created=YES

echo [2/4] Copying non-secret RescueMeAI reconnect files...
set /a COPIED=0
call :COPYONE "C:\r.cmd" "!DEST!\r-current.cmd" R_CMD
call :COPYONE "C:\RescueMeAI\reconnect.cmd" "!DEST!\reconnect-current.cmd" RECONNECT_CMD
call :COPYONE "C:\WinRERepair\runtime\device-agent-v2.cmd" "!DEST!\device-agent-v2.cmd" DEVICE_AGENT
call :COPYONE "C:\WinRERepair\agent.cfg" "!DEST!\agent.cfg" AGENT_CFG
call :COPYONE "C:\WinRERepair\connect-device-v3.cmd" "!DEST!\connect-device-v3.cmd" CONNECT_BOOTSTRAP

echo [3/4] Writing local instructions and integrity hashes...
> "!DEST!\README-RESCUEMEAI.txt" echo RescueMeAI reconnect archive for this recovery session.
>>"!DEST!\README-RESCUEMEAI.txt" echo.
>>"!DEST!\README-RESCUEMEAI.txt" echo The Wi-Fi XML at the USB root is intentionally kept as the network recovery profile.
>>"!DEST!\README-RESCUEMEAI.txt" echo GitHub authorization tokens are intentionally NOT copied to this USB.
>>"!DEST!\README-RESCUEMEAI.txt" echo Before the Windows disk is wiped, use C:\r.cmd from WinRE.
>>"!DEST!\README-RESCUEMEAI.txt" echo After a clean install starts, these files are a fallback archive only; reauthorization may be required.
>>"!DEST!\README-RESCUEMEAI.txt" echo Do not publish this USB contents because the Wi-Fi XML may contain network credentials.
> "!DEST!\SHA256.txt" echo RescueMeAI reconnect-kit SHA-256 hashes
for %%F in ("!DEST!\*.cmd" "!DEST!\*.cfg" "!DEST!\README-RESCUEMEAI.txt") do if exist "%%~fF" (
  >>"!DEST!\SHA256.txt" echo.
  >>"!DEST!\SHA256.txt" echo FILE=%%~nxF
  if exist "%CERT%" "%CERT%" -hashfile "%%~fF" SHA256 >>"!DEST!\SHA256.txt" 2>&1
)
if exist "!USB!\Wi-Fi-404 Network Unavailable.xml" (
  >>"%DETAILS%" echo wifi_profile_present_at_usb_root=YES
) else (
  >>"%DETAILS%" echo wifi_profile_present_at_usb_root=NO
)

echo [4/4] Recording safe completion...
>>"%DETAILS%" echo reconnect_files_copied=!COPIED!
>>"%DETAILS%" echo github_token_copied=NO
>>"%DETAILS%" echo personal_files_targeted=NO
>>"%DETAILS%" echo windows_changes_performed=NO
>>"%DETAILS%" echo reboot_performed=NO

> "%RESULT%" echo STATUS=PASS
>>"%RESULT%" echo MESSAGE=Minimum RescueMeAI reconnect toolkit saved to the recovery USB without copying the GitHub authorization token.
>>"%RESULT%" echo EVIDENCE=Reconnect kit folder created; files copied=!COPIED!; Wi-Fi profile presence recorded; authorization token excluded; no personal files, Windows changes, or reboot.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=NO
>>"%RESULT%" echo NEXT_STEP=RescueMeAI can now proceed to clean-install readiness. Do not format or reinstall until ChatGPT gives the next instructions.

echo.
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : COMPLETE - RECONNECT TOOLKIT SAVED TO USB
echo GITHUB TOKEN        : NOT COPIED
echo PERSONAL FILES      : NOT TOUCHED
echo WINDOWS CHANGES     : NONE
echo REBOOT              : NO
echo WHAT YOU SHOULD DO  : WAIT. Do not format or reinstall yet.
echo SCREENSHOT REQUIRED : NO
echo ================================================================================
exit /b 0

:COPYONE
if not exist "%~1" (
  >>"%DETAILS%" echo %~3=NOT_PRESENT
  exit /b 0
)
copy /y "%~1" "%~2" >nul 2>&1
if errorlevel 1 (
  >>"%DETAILS%" echo %~3=COPY_FAILED
  exit /b 0
)
set /a COPIED+=1
>>"%DETAILS%" echo %~3=COPIED
exit /b 0

:FAIL
> "%RESULT%" echo STATUS=FAIL
>>"%RESULT%" echo MESSAGE=Reconnect-toolkit USB backup could not locate or write to the recovery USB.
>>"%RESULT%" echo EVIDENCE=No personal files, Windows settings, partitions, EFI/BCD files, or reboot were changed.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=YES
echo.
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : STOPPED - RECONNECT TOOLKIT USB BACKUP FAILED
echo REBOOT              : NO
echo SCREENSHOT REQUIRED : YES
echo WHAT YOU SHOULD DO  : Send ChatGPT a photo. Do not format or reinstall.
echo ================================================================================
exit /b 90
