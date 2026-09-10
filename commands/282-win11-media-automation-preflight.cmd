@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=READ_ONLY
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Check whether the current WinRE environment can safely automate creation of official Windows 11 installation media from Microsoft without formatting or downloading the ISO yet.
rem WR_ACTION=WIN11_MEDIA_AUTOMATION_PREFLIGHT
rem WR_TARGET=WinRE tool availability, recovery USB capacity metadata, C: free-space metadata, and Microsoft Windows 11 download-page reachability only.
rem WR_CONSEQUENCE=Read-only preflight. No ISO is downloaded, no USB is formatted, no partition is changed, no Windows file or personal file is modified, and no reboot occurs.
rem WR_ROLLBACK=Not applicable; this command is read-only.

set "FIX_VERSION=RMAI-FIX-2026.09.10.4"
set "STEP=89"
set "WORK=C:\WinRERepair"
set "RESULT=%WORK%\COMMAND_RESULT.env"
set "DETAILS=%WORK%\RUN_DETAILS.txt"
set "CURL=C:\Windows\System32\curl.exe"
if not exist "%CURL%" set "CURL=X:\Windows\System32\curl.exe"
set "CERT=X:\Windows\System32\certutil.exe"
if not exist "%CERT%" set "CERT=C:\Windows\System32\certutil.exe"
set "DISM=X:\Windows\System32\dism.exe"
if not exist "%DISM%" set "DISM=C:\Windows\System32\dism.exe"
set "DISKPART=X:\Windows\System32\diskpart.exe"
if not exist "%DISKPART%" set "DISKPART=C:\Windows\System32\diskpart.exe"
set "TAR=X:\Windows\System32\tar.exe"
if not exist "%TAR%" set "TAR=C:\Windows\System32\tar.exe"
set "POWERSHELL=X:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
if not exist "%POWERSHELL%" set "POWERSHELL=C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"

cls
echo ================================================================================
echo RescueMeAI - WINDOWS 11 MEDIA AUTOMATION PREFLIGHT
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : RUNNING
echo CURRENT TASK        : Determine whether this WinRE session can safely download an
echo                       official Microsoft Windows 11 image and build the installer USB.
echo SAFETY              : READ-ONLY - USB WILL NOT BE FORMATTED IN THIS STEP.
echo DOWNLOAD            : NO WINDOWS ISO DOWNLOADED IN THIS STEP.
echo PERSONAL FILES      : NOT TOUCHED
echo REBOOT              : NO
echo WHAT YOU SHOULD DO  : WAIT. Leave this window open.
echo SCREENSHOT REQUIRED : NO unless this step stops with an error.
echo ================================================================================

if not exist "%WORK%" md "%WORK%" >nul 2>&1
if not exist "C:\Windows\System32\config\SYSTEM" goto :FAIL

>"%DETAILS%" echo RESCUEMEAI WINDOWS 11 MEDIA AUTOMATION PREFLIGHT
>>"%DETAILS%" echo fix_version=%FIX_VERSION%
>>"%DETAILS%" echo step=%STEP%
>>"%DETAILS%" echo processor_architecture=%PROCESSOR_ARCHITECTURE%

echo [1/4] Locating the recovery USB and checking capacity metadata...
set "USB="
for %%D in (D E F G H I J K L M N O P Q R S T U V W Y Z) do (
  if not defined USB if exist "%%D:\Wi-Fi-404 Network Unavailable.xml" set "USB=%%D:"
  if not defined USB if exist "%%D:\RescueMeAI-Reconnect-Kit\" set "USB=%%D:"
  if not defined USB if exist "%%D:\RescueMeAI-Preinstall-Backup\" set "USB=%%D:"
)
if defined USB (
  >>"%DETAILS%" echo recovery_usb_detected=YES
  >>"%DETAILS%" echo recovery_usb_drive=!USB!
  fsutil volume diskfree !USB! >>"%DETAILS%" 2>&1
) else (
  >>"%DETAILS%" echo recovery_usb_detected=NO
)
>>"%DETAILS%" echo --- C DRIVE FREE SPACE ---
fsutil volume diskfree C: >>"%DETAILS%" 2>&1

echo [2/4] Checking required WinRE tools...
call :TOOLSTATE "%CURL%" CURL
call :TOOLSTATE "%CERT%" CERTUTIL
call :TOOLSTATE "%DISM%" DISM
call :TOOLSTATE "%DISKPART%" DISKPART
call :TOOLSTATE "%TAR%" TAR
call :TOOLSTATE "%POWERSHELL%" POWERSHELL

set "MOUNTISO=UNKNOWN"
if exist "%POWERSHELL%" (
  "%POWERSHELL%" -NoProfile -Command "if (Get-Command Mount-DiskImage -ErrorAction SilentlyContinue) { exit 0 } else { exit 2 }" >nul 2>&1
  if errorlevel 2 (set "MOUNTISO=NO") else set "MOUNTISO=YES"
)
>>"%DETAILS%" echo powershell_mount_diskimage=!MOUNTISO!

echo [3/4] Checking official Microsoft Windows 11 download service reachability...
set "MSHTTP="
if exist "%CURL%" (
  "%CURL%" --ssl-no-revoke --silent --show-error --location --connect-timeout 15 --max-time 45 -o nul -w "%%{http_code}" "https://www.microsoft.com/en-ca/software-download/windows11" >"%WORK%\step89-ms-http.txt" 2>"%WORK%\step89-ms-curl.txt"
  set "CURLRC=!errorlevel!"
  if exist "%WORK%\step89-ms-http.txt" set /p "MSHTTP="<"%WORK%\step89-ms-http.txt"
  >>"%DETAILS%" echo microsoft_download_page_curl_exit=!CURLRC!
  >>"%DETAILS%" echo microsoft_download_page_http=!MSHTTP!
) else (
  >>"%DETAILS%" echo microsoft_download_page_curl_exit=TOOL_MISSING
)

echo [4/4] Recording feasibility summary...
set "BASE=YES"
if not defined USB set "BASE=NO"
if not exist "%CURL%" set "BASE=NO"
if not exist "%CERT%" set "BASE=NO"
if not exist "%DISM%" set "BASE=NO"
if not exist "%DISKPART%" set "BASE=NO"
if not "!MSHTTP!"=="200" set "BASE=NO"
>>"%DETAILS%" echo base_automation_prerequisites=!BASE!
>>"%DETAILS%" echo usb_formatted=NO
>>"%DETAILS%" echo iso_downloaded=NO
>>"%DETAILS%" echo personal_files_targeted=NO
>>"%DETAILS%" echo windows_changes_performed=NO
>>"%DETAILS%" echo reboot_performed=NO

>"%RESULT%" echo STATUS=PASS
>>"%RESULT%" echo MESSAGE=Windows 11 installer-media automation preflight completed safely.
>>"%RESULT%" echo EVIDENCE=USB detected=!BASE! prerequisite-summary; Microsoft download page HTTP=!MSHTTP!; ISO not downloaded; USB not formatted; no Windows or personal-file changes.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=NO
>>"%RESULT%" echo NEXT_STEP=RescueMeAI will review tool/capacity results and either automate official Microsoft media creation or fall back to Microsoft Media Creation Tool on the working PC.

echo.
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : COMPLETE - MEDIA AUTOMATION PREFLIGHT SENT
echo USB FORMATTED       : NO
echo WINDOWS ISO         : NOT DOWNLOADED
echo PERSONAL FILES      : NOT TOUCHED
echo REBOOT              : NO
echo WHAT YOU SHOULD DO  : WAIT. Do not format the USB yet.
echo SCREENSHOT REQUIRED : NO
echo ================================================================================
exit /b 0

:TOOLSTATE
if exist "%~1" (
  >>"%DETAILS%" echo %~2=YES;path=%~1
) else (
  >>"%DETAILS%" echo %~2=NO
)
exit /b 0

:FAIL
>"%RESULT%" echo STATUS=FAIL
>>"%RESULT%" echo MESSAGE=Windows 11 installer-media automation preflight could not verify the offline Windows target.
>>"%RESULT%" echo EVIDENCE=No USB formatting, ISO download, Windows change, personal-file action, or reboot was performed.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=YES
echo.
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : STOPPED - MEDIA PREFLIGHT FAILED
echo REBOOT              : NO
echo SCREENSHOT REQUIRED : YES
echo WHAT YOU SHOULD DO  : Send ChatGPT a photo. Do not format the USB.
echo ================================================================================
exit /b 90
