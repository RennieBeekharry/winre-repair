@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=READ_ONLY
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Measure aggregate size and file counts in common personal-data folders before clean installation, without reading file contents or uploading filenames/profile names.
rem WR_ACTION=PREWIPE_USER_DATA_SIZE_INVENTORY
rem WR_TARGET=Directory metadata under C:\Users common personal-data folders and recovery-USB free-space metadata only.
rem WR_CONSEQUENCE=Enumerates file metadata to estimate backup capacity. No file contents, filenames, or profile names are uploaded. No files are copied/deleted, no Windows settings are changed, and no reboot occurs.
rem WR_ROLLBACK=Not applicable; this command is read-only.

set "FIX_VERSION=RMAI-FIX-2026.09.10.4"
set "STEP=86"
set "WORK=C:\WinRERepair"
set "RESULT=%WORK%\COMMAND_RESULT.env"
set "DETAILS=%WORK%\RUN_DETAILS.txt"

cls
echo ================================================================================
echo RescueMeAI - PRE-WIPE BACKUP SIZE CHECK
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : RUNNING
echo CURRENT DIAGNOSIS   : Hardware tests passed and Windows servicing remains broken.
echo                       Step 85 found personal files that must be protected first.
echo CURRENT TASK        : Measure aggregate backup size by common personal-data folder.
echo PRIVACY             : FILE CONTENTS, FILENAMES, AND PROFILE NAMES ARE NOT UPLOADED.
echo SAFETY              : READ-ONLY - NOTHING IS COPIED, DELETED, OR CHANGED.
echo PERSONAL FILES      : NOT TOUCHED
echo REBOOT              : NO
echo WHAT YOU SHOULD DO  : WAIT. Leave this window open.
echo SCREENSHOT REQUIRED : NO unless this step stops with an error.
echo ================================================================================

if not exist "%WORK%" md "%WORK%" >nul 2>&1
if not exist "C:\Users\" goto :FAIL
if not exist "C:\Windows\System32\config\SYSTEM" goto :FAIL

>"%DETAILS%" echo RESCUEMEAI PRE-WIPE BACKUP SIZE CHECK
>>"%DETAILS%" echo fix_version=%FIX_VERSION%
>>"%DETAILS%" echo step=%STEP%

set /a PROFILECOUNT=0
set /a DATAPROFILES=0
set /a TOTALFILES=0

echo [1/4] Identifying candidate user profiles without recording their names...
for /d %%U in ("C:\Users\*") do (
  set "SKIP=NO"
  if /i "%%~nxU"=="Default" set "SKIP=YES"
  if /i "%%~nxU"=="Default User" set "SKIP=YES"
  if /i "%%~nxU"=="Public" set "SKIP=YES"
  if /i "%%~nxU"=="All Users" set "SKIP=YES"
  if /i "%%~nxU"=="defaultuser0" set "SKIP=YES"
  if /i "!SKIP!"=="NO" (
    set /a PROFILECOUNT+=1
    set "PROFILEHAS=NO"
    call :MEASURE "%%~fU\Desktop" DESKTOP
    call :MEASURE "%%~fU\Documents" DOCUMENTS
    call :MEASURE "%%~fU\Downloads" DOWNLOADS
    call :MEASURE "%%~fU\Pictures" PICTURES
    call :MEASURE "%%~fU\Videos" VIDEOS
    call :MEASURE "%%~fU\Music" MUSIC
    call :MEASURE "%%~fU\OneDrive" ONEDRIVE
    if /i "!PROFILEHAS!"=="YES" set /a DATAPROFILES+=1
  )
)

echo [2/4] Recording reset-era container state...
set "WINDOWSOLD=NO"
set "SYSRESET=NO"
if exist "C:\Windows.old\" set "WINDOWSOLD=YES"
if exist "C:\$SysReset\" set "SYSRESET=YES"
>>"%DETAILS%" echo windows_old_present=!WINDOWSOLD!
>>"%DETAILS%" echo sysreset_present=!SYSRESET!

echo [3/4] Checking recovery USB presence and free-space metadata...
set "USB=NOT_DETECTED"
for %%D in (D E F G H I J K L M N O P Q R S T U V W Y Z) do (
  if /i "!USB!"=="NOT_DETECTED" if exist "%%D:\Wi-Fi-404 Network Unavailable.xml" set "USB=%%D:"
  if /i "!USB!"=="NOT_DETECTED" if exist "%%D:\RescueMeAI-Preinstall-Backup\" set "USB=%%D:"
)
if /i not "!USB!"=="NOT_DETECTED" (
  >>"%DETAILS%" echo recovery_usb_detected=YES
  for /f "tokens=*" %%L in ('fsutil volume diskfree !USB! 2^>nul ^| findstr /i /c:"free bytes"') do >>"%DETAILS%" echo recovery_usb_%%L
) else (
  >>"%DETAILS%" echo recovery_usb_detected=NO
)

echo [4/4] Recording privacy-preserving decision summary...
>>"%DETAILS%" echo candidate_user_profiles=!PROFILECOUNT!
>>"%DETAILS%" echo profiles_with_common_personal_files=!DATAPROFILES!
>>"%DETAILS%" echo aggregate_common_personal_file_count=!TOTALFILES!
>>"%DETAILS%" echo filenames_uploaded=NO
>>"%DETAILS%" echo profile_names_uploaded=NO
>>"%DETAILS%" echo personal_file_contents_read=NO
>>"%DETAILS%" echo files_copied=NO
>>"%DETAILS%" echo files_deleted=NO
>>"%DETAILS%" echo windows_changes_performed=NO
>>"%DETAILS%" echo reboot_performed=NO

>"%RESULT%" echo STATUS=PASS
>>"%RESULT%" echo MESSAGE=Pre-wipe backup-size inventory completed safely.
>>"%RESULT%" echo EVIDENCE=Candidate profiles=!PROFILECOUNT!; profiles with common personal files=!DATAPROFILES!; aggregate file count=!TOTALFILES!. Folder-level counts and byte totals captured without filenames, profile names, or file contents.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=NO
>>"%RESULT%" echo NEXT_STEP=STOP BEFORE WIPE. RescueMeAI will review backup capacity and ask for explicit authorization before any personal files are copied.

echo.
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : COMPLETE - BACKUP SIZE INVENTORY SENT
echo PERSONAL FILES      : NOT TOUCHED
echo REBOOT              : NO
echo WHAT YOU SHOULD DO  : WAIT. DO NOT REINSTALL OR FORMAT ANYTHING.
echo SCREENSHOT REQUIRED : NO
echo ================================================================================
exit /b 0

:MEASURE
if not exist "%~1\" exit /b 0
set "CNT=0"
set "BYTES=0"
for /f "tokens=1,3" %%A in ('dir /a-d /s /-c "%~1" 2^>nul ^| findstr /r /c:"^[ ]*[0-9][0-9]* File(s)"') do (
  set "CNT=%%A"
  set "BYTES=%%B"
)
if not defined CNT set "CNT=0"
if not defined BYTES set "BYTES=0"
if not "!CNT!"=="0" (
  set "PROFILEHAS=YES"
  set /a TOTALFILES+=CNT
)
>>"%DETAILS%" echo %~2_files=!CNT!;bytes=!BYTES!
exit /b 0

:FAIL
>"%RESULT%" echo STATUS=FAIL
>>"%RESULT%" echo MESSAGE=Pre-wipe backup-size inventory could not verify the offline Windows user-data root.
>>"%RESULT%" echo EVIDENCE=No personal file was copied, deleted, or modified; no Windows setting or reboot was performed.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=YES
echo.
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : STOPPED - BACKUP SIZE CHECK FAILED
echo REBOOT              : NO
echo SCREENSHOT REQUIRED : YES
echo WHAT YOU SHOULD DO  : Send ChatGPT a photo. Do not reinstall or format anything.
echo ================================================================================
exit /b 90
