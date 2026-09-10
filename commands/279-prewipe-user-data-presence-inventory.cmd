@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=READ_ONLY
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Perform the final pre-wipe privacy-preserving inventory of common user-data locations without reading file contents, copying files, or changing Windows.
rem WR_ACTION=PREWIPE_USER_DATA_PRESENCE_INVENTORY
rem WR_TARGET=Directory metadata under C:\Users common personal-data folders plus removable recovery-USB free-space metadata only.
rem WR_CONSEQUENCE=Enumerates directory/file metadata only to determine whether personal data appears to remain before clean installation. Filenames, profile names, and file contents are not uploaded. No files are copied or deleted, no Windows settings are changed, and no reboot occurs.
rem WR_ROLLBACK=Not applicable; this command is read-only.

set "FIX_VERSION=RMAI-FIX-2026.09.10.4"
set "STEP=85"
set "WORK=C:\WinRERepair"
set "RESULT=%WORK%\COMMAND_RESULT.env"
set "DETAILS=%WORK%\RUN_DETAILS.txt"

cls
echo ================================================================================
echo RescueMeAI - FINAL PRE-WIPE USER DATA CHECK
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : RUNNING
echo CURRENT DIAGNOSIS   : Hardware diagnostics passed; Windows servicing remains broken.
echo CURRENT TASK        : Check whether common personal-data folders still contain files
echo                       before authorizing a clean Windows installation.
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

>"%DETAILS%" echo RESCUEMEAI FINAL PRE-WIPE USER DATA CHECK
>>"%DETAILS%" echo fix_version=%FIX_VERSION%
>>"%DETAILS%" echo step=%STEP%

set /a PROFILECOUNT=0
set /a DATAPROFILES=0
set /a LOCATIONS=0
set /a FILECOUNT=0

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
    call :CHECKFOLDER "%%~fU\Desktop"
    call :CHECKFOLDER "%%~fU\Documents"
    call :CHECKFOLDER "%%~fU\Downloads"
    call :CHECKFOLDER "%%~fU\Pictures"
    call :CHECKFOLDER "%%~fU\Videos"
    call :CHECKFOLDER "%%~fU\Music"
    call :CHECKFOLDER "%%~fU\OneDrive"
    if /i "!PROFILEHAS!"=="YES" set /a DATAPROFILES+=1
  )
)

echo [2/4] Checking for reset-era user-data container presence...
set "WINDOWSOLD=NO"
set "SYSRESET=NO"
if exist "C:\Windows.old\" set "WINDOWSOLD=YES"
if exist "C:\$SysReset\" set "SYSRESET=YES"

echo [3/4] Recording recovery USB free-space metadata...
set "USB=NOT_DETECTED"
for %%D in (D E F G H I J K L M N O P Q R S T U V W Y Z) do if /i "!USB!"=="NOT_DETECTED" if exist "%%D:\Wi-Fi-404 Network Unavailable.xml" set "USB=%%D:"
if /i not "!USB!"=="NOT_DETECTED" (
  >>"%DETAILS%" echo recovery_usb_detected=YES
  for /f "tokens=*" %%L in ('fsutil volume diskfree !USB! 2^>nul ^| findstr /i /c:"free bytes"') do >>"%DETAILS%" echo recovery_usb_%%L
) else (
  >>"%DETAILS%" echo recovery_usb_detected=NO
)

echo [4/4] Recording privacy-preserving decision summary...
set "PERSONALDATA=NO"
if !DATAPROFILES! GTR 0 set "PERSONALDATA=YES"

>>"%DETAILS%" echo candidate_user_profiles=!PROFILECOUNT!
>>"%DETAILS%" echo profiles_with_common_personal_files=!DATAPROFILES!
>>"%DETAILS%" echo common_personal_locations_with_files=!LOCATIONS!
>>"%DETAILS%" echo common_personal_file_count=!FILECOUNT!
>>"%DETAILS%" echo personal_data_detected=!PERSONALDATA!
>>"%DETAILS%" echo windows_old_present=!WINDOWSOLD!
>>"%DETAILS%" echo sysreset_present=!SYSRESET!
>>"%DETAILS%" echo filenames_uploaded=NO
>>"%DETAILS%" echo profile_names_uploaded=NO
>>"%DETAILS%" echo personal_file_contents_read=NO
>>"%DETAILS%" echo files_copied=NO
>>"%DETAILS%" echo files_deleted=NO
>>"%DETAILS%" echo windows_changes_performed=NO
>>"%DETAILS%" echo reboot_performed=NO

>"%RESULT%" echo STATUS=PASS
>>"%RESULT%" echo MESSAGE=Final pre-wipe user-data presence inventory completed safely.
>>"%RESULT%" echo EVIDENCE=Candidate profiles=!PROFILECOUNT!; profiles with common personal files=!DATAPROFILES!; common locations with files=!LOCATIONS!; aggregate file count=!FILECOUNT!; personal data detected=!PERSONALDATA!. No filenames, profile names, or file contents were uploaded.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=NO
if /i "!PERSONALDATA!"=="YES" (
  >>"%RESULT%" echo NEXT_STEP=STOP BEFORE WIPE. Ask whether the niece wants personal data backed up to separate storage before clean installation.
) else (
  >>"%RESULT%" echo NEXT_STEP=No common personal data detected by this bounded check. RescueMeAI will perform one final clean-install readiness review before any destructive action.
)

echo.
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : COMPLETE - PRE-WIPE DATA CHECK SENT
echo PERSONAL DATA FOUND : !PERSONALDATA!
echo PERSONAL FILES      : NOT TOUCHED
echo REBOOT              : NO
if /i "!PERSONALDATA!"=="YES" (
  echo WHAT YOU SHOULD DO  : WAIT. DO NOT REINSTALL OR FORMAT ANYTHING.
) else (
  echo WHAT YOU SHOULD DO  : WAIT. DO NOT REINSTALL OR FORMAT ANYTHING YET.
)
echo SCREENSHOT REQUIRED : NO
echo ================================================================================
exit /b 0

:CHECKFOLDER
if not exist "%~1\" exit /b 0
set "N=0"
for /f %%N in ('dir /a-d /s /b "%~1" 2^>nul ^| find /v /c ""') do set "N=%%N"
if not defined N set "N=0"
if !N! GTR 0 (
  set /a LOCATIONS+=1
  set /a FILECOUNT+=N
  set "PROFILEHAS=YES"
)
exit /b 0

:FAIL
>"%RESULT%" echo STATUS=FAIL
>>"%RESULT%" echo MESSAGE=Final pre-wipe data inventory could not verify the offline Windows user-data root.
>>"%RESULT%" echo EVIDENCE=No personal file was copied, deleted, or modified; no Windows setting or reboot was performed.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=YES
echo.
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : STOPPED - PRE-WIPE DATA CHECK FAILED
echo REBOOT              : NO
echo SCREENSHOT REQUIRED : YES
echo WHAT YOU SHOULD DO  : Send ChatGPT a photo. Do not reinstall or format anything.
echo ================================================================================
exit /b 90
