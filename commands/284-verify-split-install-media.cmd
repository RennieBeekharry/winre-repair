@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=READ_ONLY
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Confirm whether the Microsoft-created Windows installer uses a split install image on FAT32 media.
rem WR_ACTION=VERIFY_SPLIT_INSTALL_MEDIA
rem WR_TARGET=Windows installer USB file metadata only.
rem WR_CONSEQUENCE=Read-only inspection only. No files or settings are changed.
rem WR_ROLLBACK=Not applicable.

set "FIX_VERSION=RMAI-FIX-2026.09.10.4"
set "STEP=90"
set "WORK=C:\WinRERepair"
set "RESULT=%WORK%\COMMAND_RESULT.env"
set "DETAILS=%WORK%\RUN_DETAILS.txt"

cls
echo ================================================================================
echo RescueMeAI - WINDOWS INSTALLER PAYLOAD CHECK
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : RUNNING
echo CURRENT TASK        : Confirm the installer payload on the Microsoft USB.
echo SAFETY              : READ-ONLY
echo WINDOWS CHANGES     : NONE
echo REBOOT              : NO
echo WHAT YOU SHOULD DO  : WAIT. Keep the Windows installer USB inserted.
echo SCREENSHOT REQUIRED : NO unless an error appears.
echo ================================================================================

if not exist "%WORK%" md "%WORK%" >nul 2>&1
>"%DETAILS%" echo RESCUEMEAI WINDOWS INSTALLER PAYLOAD CHECK
>>"%DETAILS%" echo fix_version=%FIX_VERSION%
>>"%DETAILS%" echo step=%STEP%

set "MEDIA="
for %%D in (D E F G H I J K L M N O P Q R S T U V W Y Z) do (
  if not defined MEDIA if exist "%%D:\setup.exe" if exist "%%D:\sources\boot.wim" if exist "%%D:\efi\boot\bootx64.efi" set "MEDIA=%%D:"
)
if not defined MEDIA goto :NOMEDIA
>>"%DETAILS%" echo media_drive=!MEDIA!

set "PAYLOAD=NO"
set /a SWMCOUNT=0
if exist "!MEDIA!\sources\install.wim" set "PAYLOAD=YES"
if exist "!MEDIA!\sources\install.esd" set "PAYLOAD=YES"
for %%F in ("!MEDIA!\sources\install*.swm") do if exist "%%~fF" (
  set /a SWMCOUNT+=1
  set "PAYLOAD=YES"
  >>"%DETAILS%" echo split_image_file=%%~nxF;bytes=%%~zF
)
>>"%DETAILS%" echo split_image_count=!SWMCOUNT!
>>"%DETAILS%" echo install_payload_present=!PAYLOAD!

set "READY=NO"
if /i "!PAYLOAD!"=="YES" if exist "!MEDIA!\setup.exe" if exist "!MEDIA!\sources\boot.wim" if exist "!MEDIA!\efi\boot\bootx64.efi" set "READY=YES"
>>"%DETAILS%" echo media_ready=!READY!
>>"%DETAILS%" echo changes_performed=NO
>>"%DETAILS%" echo reboot_performed=NO

>"%RESULT%" echo STATUS=PASS
>>"%RESULT%" echo MESSAGE=Windows installer payload check completed safely.
>>"%RESULT%" echo EVIDENCE=Install payload present=!PAYLOAD!; split-image files=!SWMCOUNT!; media ready=!READY!; no changes performed.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=NO
>>"%RESULT%" echo NEXT_STEP=RescueMeAI will review the result before the next user-guided step.

echo.
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : COMPLETE
echo MEDIA READY         : !READY!
echo REBOOT              : NO
echo WHAT YOU SHOULD DO  : WAIT.
echo SCREENSHOT REQUIRED : NO
echo ================================================================================
exit /b 0

:NOMEDIA
>"%RESULT%" echo STATUS=FAIL
>>"%RESULT%" echo MESSAGE=Windows installation media was not detected.
>>"%RESULT%" echo EVIDENCE=No changes were performed.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=YES
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : INSTALLER USB NOT DETECTED
echo REBOOT              : NO
echo SCREENSHOT REQUIRED : YES
exit /b 90
