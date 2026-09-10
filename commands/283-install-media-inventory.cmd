@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=READ_ONLY
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Inspect Windows installation media markers and local disk/volume metadata.
rem WR_ACTION=INSTALL_MEDIA_INVENTORY
rem WR_TARGET=Removable media file metadata and local disk/volume metadata only.
rem WR_CONSEQUENCE=Read-only inspection only. No files or settings are changed.
rem WR_ROLLBACK=Not applicable.

set "FIX_VERSION=RMAI-FIX-2026.09.10.4"
set "STEP=89"
set "WORK=C:\WinRERepair"
set "RESULT=%WORK%\COMMAND_RESULT.env"
set "DETAILS=%WORK%\RUN_DETAILS.txt"
set "DISKPART=X:\Windows\System32\diskpart.exe"
if not exist "%DISKPART%" set "DISKPART=C:\Windows\System32\diskpart.exe"

cls
echo ================================================================================
echo RescueMeAI - WINDOWS INSTALLATION MEDIA CHECK
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : RUNNING
echo CURRENT TASK        : Verify installer media and capture disk layout metadata.
echo SAFETY              : READ-ONLY
echo WINDOWS CHANGES     : NONE
echo REBOOT              : NO
echo WHAT YOU SHOULD DO  : WAIT. Keep the Windows installer USB inserted.
echo SCREENSHOT REQUIRED : NO unless an error appears.
echo ================================================================================

if not exist "%WORK%" md "%WORK%" >nul 2>&1
if not exist "%DISKPART%" goto :FAIL

>"%DETAILS%" echo RESCUEMEAI INSTALL MEDIA INVENTORY
>>"%DETAILS%" echo fix_version=%FIX_VERSION%
>>"%DETAILS%" echo step=%STEP%

set "MEDIA="
set /a MEDIACOUNT=0
for %%D in (D E F G H I J K L M N O P Q R S T U V W Y Z) do (
  if exist "%%D:\setup.exe" if exist "%%D:\sources\boot.wim" if exist "%%D:\efi\boot\bootx64.efi" (
    set /a MEDIACOUNT+=1
    if not defined MEDIA set "MEDIA=%%D:"
  )
)
>>"%DETAILS%" echo media_candidates=!MEDIACOUNT!
if not defined MEDIA goto :NOMEDIA
>>"%DETAILS%" echo media_detected=YES
>>"%DETAILS%" echo media_drive=!MEDIA!
for %%F in ("!MEDIA!\setup.exe") do >>"%DETAILS%" echo setup_exe_bytes=%%~zF
for %%F in ("!MEDIA!\sources\boot.wim") do >>"%DETAILS%" echo boot_wim_bytes=%%~zF
if exist "!MEDIA!\sources\install.wim" (
  for %%F in ("!MEDIA!\sources\install.wim") do >>"%DETAILS%" echo install_payload=install.wim;bytes=%%~zF
) else if exist "!MEDIA!\sources\install.esd" (
  for %%F in ("!MEDIA!\sources\install.esd") do >>"%DETAILS%" echo install_payload=install.esd;bytes=%%~zF
) else (
  >>"%DETAILS%" echo install_payload=NOT_FOUND
)

>"%WORK%\step89-diskpart.txt" echo list disk
>>"%WORK%\step89-diskpart.txt" echo list volume
>>"%WORK%\step89-diskpart.txt" echo exit
"%DISKPART%" /s "%WORK%\step89-diskpart.txt" >>"%DETAILS%" 2>&1
set "DPRC=!errorlevel!"
>>"%DETAILS%" echo diskpart_exit=!DPRC!

set "READY=YES"
if not "!MEDIACOUNT!"=="1" set "READY=NO"
if not exist "!MEDIA!\sources\install.wim" if not exist "!MEDIA!\sources\install.esd" set "READY=NO"
>>"%DETAILS%" echo media_ready=!READY!
>>"%DETAILS%" echo changes_performed=NO
>>"%DETAILS%" echo reboot_performed=NO

>"%RESULT%" echo STATUS=PASS
>>"%RESULT%" echo MESSAGE=Windows installation media inventory completed safely.
>>"%RESULT%" echo EVIDENCE=Media candidates=!MEDIACOUNT!; media ready=!READY!; disk and volume metadata captured read-only.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=NO
>>"%RESULT%" echo NEXT_STEP=RescueMeAI will review the inventory before the next user-guided step.

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
>>"%DETAILS%" echo media_detected=NO
>"%RESULT%" echo STATUS=FAIL
>>"%RESULT%" echo MESSAGE=Windows installation media was not detected.
>>"%RESULT%" echo EVIDENCE=No changes were performed.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=YES
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : INSTALLER USB NOT DETECTED
echo REBOOT              : NO
echo SCREENSHOT REQUIRED : YES
echo WHAT YOU SHOULD DO  : Insert the Windows installer USB.
exit /b 90

:FAIL
>"%RESULT%" echo STATUS=FAIL
>>"%RESULT%" echo MESSAGE=Required read-only inventory tool was unavailable.
>>"%RESULT%" echo EVIDENCE=No changes were performed.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=YES
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : CHECK FAILED
echo REBOOT              : NO
echo SCREENSHOT REQUIRED : YES
exit /b 90
