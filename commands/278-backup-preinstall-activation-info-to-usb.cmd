@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=REPAIR_WRITE
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Create a local-only preinstall activation and driver-information backup on the removable RescueMeAI USB before any Windows reinstall.
rem WR_ACTION=BACKUP_PREINSTALL_ACTIVATION_INFO_TO_USB
rem WR_TARGET=Removable USB containing Wi-Fi-404 Network Unavailable.xml; reads offline Windows licensing/edition metadata and driver inventory only.
rem WR_CONSEQUENCE=Creates RescueMeAI-Preinstall-Backup files on the removable USB. No Windows, BCD, EFI, package, partition, or personal file is changed. Product-key values are never uploaded to GitHub.
rem WR_ROLLBACK=Delete the RescueMeAI-Preinstall-Backup folder from the USB if no longer wanted.

set "FIX_VERSION=RMAI-FIX-2026.09.10.3"
set "STEP=82"
set "WORK=C:\WinRERepair"
set "RESULT=%WORK%\COMMAND_RESULT.env"
set "DETAILS=%WORK%\RUN_DETAILS.txt"
set "REG=X:\Windows\System32\reg.exe"
if not exist "%REG%" set "REG=C:\Windows\System32\reg.exe"
set "DISM=X:\Windows\System32\dism.exe"
if not exist "%DISM%" set "DISM=C:\Windows\System32\dism.exe"
set "WMIC=X:\Windows\System32\wbem\wmic.exe"
if not exist "%WMIC%" set "WMIC=C:\Windows\System32\wbem\wmic.exe"
set "CERT=X:\Windows\System32\certutil.exe"
if not exist "%CERT%" set "CERT=C:\Windows\System32\certutil.exe"

cls
echo ================================================================================
echo RescueMeAI - PREINSTALL ACTIVATION BACKUP
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : RUNNING
echo CURRENT TASK        : Save activation/license clues and installed-driver inventory
echo                       to the removable recovery USB before any reinstall.
echo PRIVACY             : FULL PRODUCT-KEY VALUES STAY LOCAL ON THE USB ONLY.
echo GITHUB UPLOAD       : KEY VALUES WILL NOT BE UPLOADED.
echo WINDOWS CHANGES     : NONE
echo PERSONAL FILES      : NOT TOUCHED
echo REBOOT              : NO
echo WHAT YOU SHOULD DO  : WAIT. Keep the Wi-Fi-profile USB inserted.
echo SCREENSHOT REQUIRED : NO unless this step stops with an error.
echo ================================================================================

if not exist "%WORK%" md "%WORK%" >nul 2>&1
if not exist "C:\Windows\System32\config\SOFTWARE" goto :FAIL

set "USB="
for %%D in (D E F G H I J K L M N O P Q R S T U V W Y Z) do if not defined USB if exist "%%D:\Wi-Fi-404 Network Unavailable.xml" set "USB=%%D:"
if not defined USB goto :NOUSB

set "BACKUP=!USB!\RescueMeAI-Preinstall-Backup"
set "ACT=!BACKUP!\activation-info.txt"
set "DRV=!BACKUP!\installed-drivers.txt"
set "NOTE=!BACKUP!\README.txt"
if not exist "!BACKUP!" md "!BACKUP!" >nul 2>&1
if not exist "!BACKUP!\" goto :NOUSB

> "!BACKUP!\write-test.tmp" echo RescueMeAI USB write test
if errorlevel 1 goto :NOUSB
del /f /q "!BACKUP!\write-test.tmp" >nul 2>&1

> "%DETAILS%" echo RESCUEMEAI PREINSTALL ACTIVATION BACKUP
>>"%DETAILS%" echo fix_version=%FIX_VERSION%
>>"%DETAILS%" echo step=%STEP%
>>"%DETAILS%" echo usb_detected=YES
>>"%DETAILS%" echo usb_drive=!USB!
>>"%DETAILS%" echo backup_folder=!BACKUP!

echo [1/5] Recording Windows edition/build information...
> "!ACT!" echo RescueMeAI Preinstall Activation Information
>>"!ACT!" echo Created: %date% %time%
>>"!ACT!" echo Source Windows: C:\Windows
>>"!ACT!" echo.
>>"!ACT!" echo === WINDOWS EDITION ===
"%DISM%" /English /Image:C:\ /Get-CurrentEdition >>"!ACT!" 2>&1

echo [2/5] Reading offline licensing registry values locally...
set "HIVELOADED=NO"
"%REG%" load HKLM\RMAISOFT "C:\Windows\System32\config\SOFTWARE" >"%WORK%\step82-regload.txt" 2>&1
if not errorlevel 1 (
  set "HIVELOADED=YES"
  >>"!ACT!" echo.
  >>"!ACT!" echo === WINDOWS IDENTITY ===
  "%REG%" query "HKLM\RMAISOFT\Microsoft\Windows NT\CurrentVersion" /v ProductName >>"!ACT!" 2>&1
  "%REG%" query "HKLM\RMAISOFT\Microsoft\Windows NT\CurrentVersion" /v EditionID >>"!ACT!" 2>&1
  "%REG%" query "HKLM\RMAISOFT\Microsoft\Windows NT\CurrentVersion" /v DisplayVersion >>"!ACT!" 2>&1
  "%REG%" query "HKLM\RMAISOFT\Microsoft\Windows NT\CurrentVersion" /v CurrentBuild >>"!ACT!" 2>&1
  "%REG%" query "HKLM\RMAISOFT\Microsoft\Windows NT\CurrentVersion" /v ProductId >>"!ACT!" 2>&1
  >>"!ACT!" echo.
  >>"!ACT!" echo === OFFLINE SOFTWARE PROTECTION PLATFORM ===
  "%REG%" query "HKLM\RMAISOFT\Microsoft\Windows NT\CurrentVersion\SoftwareProtectionPlatform" /v BackupProductKeyDefault >>"!ACT!" 2>&1
  "%REG%" query "HKLM\RMAISOFT\Microsoft\Windows NT\CurrentVersion\SoftwareProtectionPlatform" /v KeyManagementServiceName >>"!ACT!" 2>&1
  "%REG%" unload HKLM\RMAISOFT >"%WORK%\step82-regunload.txt" 2>&1
)
set "BACKUPKEY=NOT_DETECTED"
findstr /i /c:"BackupProductKeyDefault" "!ACT!" >nul 2>&1
if not errorlevel 1 set "BACKUPKEY=PRESENT_ON_USB_ONLY"

echo [3/5] Attempting firmware OEM-key lookup locally...
set "OEMKEY=NOT_DETECTED_OR_UNAVAILABLE"
if exist "%WMIC%" (
  >"%WORK%\step82-oemkey.txt" "%WMIC%" path SoftwareLicensingService get OA3xOriginalProductKey /value 2>&1
  findstr /i /c:"OA3xOriginalProductKey=" "%WORK%\step82-oemkey.txt" >nul 2>&1
  if not errorlevel 1 (
    for /f "tokens=1,* delims==" %%A in ('findstr /i /c:"OA3xOriginalProductKey=" "%WORK%\step82-oemkey.txt"') do if not "%%B"=="" set "OEMKEY=PRESENT_ON_USB_ONLY"
    >>"!ACT!" echo.
    >>"!ACT!" echo === FIRMWARE OEM KEY QUERY ===
    type "%WORK%\step82-oemkey.txt" >>"!ACT!"
  )
)
if /i "!OEMKEY!"=="NOT_DETECTED_OR_UNAVAILABLE" (
  >>"!ACT!" echo.
  >>"!ACT!" echo === FIRMWARE OEM KEY QUERY ===
  >>"!ACT!" echo Firmware OEM product key was not detected or is unavailable from WinRE.
  >>"!ACT!" echo This does NOT mean the PC lacks a digital Windows license.
)

echo [4/5] Saving installed third-party driver inventory...
"%DISM%" /English /Image:C:\ /Get-Drivers /Format:Table >"!DRV!" 2>&1
set "DRVRC=!errorlevel!"

> "!NOTE!" echo RescueMeAI Preinstall Backup
>>"!NOTE!" echo ============================
>>"!NOTE!" echo Windows target edition detected earlier: Windows Core / Home family.
>>"!NOTE!" echo Keep this USB until Windows is reinstalled and activated successfully.
>>"!NOTE!" echo During Windows Setup, use the SAME edition and choose "I don't have a product key"
>>"!NOTE!" echo if Setup asks for a key. A digital license may reactivate automatically online.
>>"!NOTE!" echo.
>>"!NOTE!" echo Files:
>>"!NOTE!" echo   activation-info.txt   - local activation/licensing clues; may contain a product key
>>"!NOTE!" echo   installed-drivers.txt - offline installed driver inventory
>>"!NOTE!" echo.
>>"!NOTE!" echo IMPORTANT: activation-info.txt stays on this USB. Do not upload it publicly.

echo [5/5] Verifying backup files...
set "ACTOK=NO"
set "DRVOUT=NO"
if exist "!ACT!" set "ACTOK=YES"
if exist "!DRV!" set "DRVOUT=YES"
if /i not "!ACTOK!"=="YES" goto :FAIL
if exist "%CERT%" (
  "%CERT%" -hashfile "!ACT!" SHA256 >"!BACKUP!\activation-info.sha256.txt" 2>&1
  "%CERT%" -hashfile "!DRV!" SHA256 >"!BACKUP!\installed-drivers.sha256.txt" 2>&1
)

>>"%DETAILS%" echo activation_file_written=!ACTOK!
>>"%DETAILS%" echo driver_inventory_written=!DRVOUT!
>>"%DETAILS%" echo driver_inventory_exit=!DRVRC!
>>"%DETAILS%" echo offline_backup_product_key=!BACKUPKEY!
>>"%DETAILS%" echo firmware_oem_key=!OEMKEY!
>>"%DETAILS%" echo full_key_value_uploaded=NO
>>"%DETAILS%" echo windows_changes_performed=NO
>>"%DETAILS%" echo personal_files_targeted=NO
>>"%DETAILS%" echo reboot_performed=NO

> "%RESULT%" echo STATUS=PASS
>>"%RESULT%" echo MESSAGE=Preinstall activation and driver backup was saved to the removable recovery USB.
>>"%RESULT%" echo EVIDENCE=USB backup created; offline backup-key presence=!BACKUPKEY!; firmware OEM-key presence=!OEMKEY!; no key value uploaded; no Windows changes or reboot.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=NO
>>"%RESULT%" echo NEXT_STEP=Keep the USB safe. RescueMeAI can proceed with hardware diagnostics and clean-install planning without exposing product-key values.

echo.
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : COMPLETE - PREINSTALL BACKUP SAVED
echo USB BACKUP FOLDER   : !BACKUP!
echo LICENSE INFO        : !BACKUPKEY!
echo FIRMWARE OEM KEY    : !OEMKEY!
echo KEY UPLOADED        : NO
echo WINDOWS CHANGES     : NONE
echo REBOOT              : NO
echo WHAT YOU SHOULD DO  : Keep this USB safe and leave RescueMeAI open.
echo SCREENSHOT REQUIRED : NO
echo ================================================================================
exit /b 0

:NOUSB
> "%RESULT%" echo STATUS=WARNING
>>"%RESULT%" echo MESSAGE=Preinstall backup could not identify or write to the recovery USB.
>>"%RESULT%" echo EVIDENCE=No Windows changes, personal-file access, product-key upload, or reboot occurred.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=YES
echo.
echo STATUS              : STOPPED - RECOVERY USB NOT WRITABLE/FOUND
echo REBOOT              : NO
echo SCREENSHOT REQUIRED : YES
echo WHAT YOU SHOULD DO  : Keep the Wi-Fi XML USB inserted and send ChatGPT a photo.
exit /b 40

:FAIL
if /i "!HIVELOADED!"=="YES" "%REG%" unload HKLM\RMAISOFT >nul 2>&1
> "%RESULT%" echo STATUS=FAIL
>>"%RESULT%" echo MESSAGE=Preinstall activation backup could not complete safely.
>>"%RESULT%" echo EVIDENCE=No Windows boot setting, partition, or personal file was changed and no reboot occurred.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=YES
echo.
echo STATUS              : STOPPED - PREINSTALL BACKUP FAILED
echo REBOOT              : NO
echo SCREENSHOT REQUIRED : YES
echo WHAT YOU SHOULD DO  : Send ChatGPT a photo. Do not reinstall Windows yet.
exit /b 90
