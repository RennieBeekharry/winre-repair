@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "COMMAND_VERSION=WR-2026.08.14-0907-ET"
set "BUILD_TIME=2026-08-14 09:07 ET"
set "WORK=C:\WinRERepair"
set "CURL=C:\Windows\System32\curl.exe"
set "NSLOOKUP=C:\Windows\System32\nslookup.exe"
set "FINDSTR=C:\Windows\System32\findstr.exe"
set "DISM=X:\Windows\System32\dism.exe"
if not exist "%DISM%" set "DISM=C:\Windows\System32\dism.exe"
set "WPEUTIL=X:\Windows\System32\wpeutil.exe"
set "PING=X:\Windows\System32\ping.exe"
set "CERTUTIL=C:\Windows\System32\certutil.exe"
set "CSCRIPT=X:\Windows\System32\cscript.exe"
if not exist "%CSCRIPT%" set "CSCRIPT=C:\Windows\System32\cscript.exe"
set "DNS=64.71.255.204"

set "UUPAPIHOST=api.uupdump.net"
set "UUPID=44ac3fa1-0cef-463b-a650-6240d396f894"
set "UUPBUILD=26100.8894"
set "UUPAPIURL=https://api.uupdump.net/get.php?id=%UUPID%&lang=en-us&edition=core"

set "GHAPIHOST=api.github.com"
set "HELPERURL=https://api.github.com/repos/RennieBeekharry/winre-repair/contents/uup-download.js?ref=main"
set "RECOVERYMANIFESTURL=https://api.github.com/repos/RennieBeekharry/winre-repair/contents/RECOVERY_MANIFEST.md?ref=main"

set "BOOTVOL="
set "DATAVOL="
set "BOOTCOUNT=0"
set "DATACOUNT=0"
set "OFFEDITION=UNKNOWN"
set "OFFLANG=UNKNOWN"
set "APIIP="
set "GHIP="

cls
echo ================================================================
echo WINRE-REPAIR - WINDOWS 11 24H2 SOURCE DOWNLOAD
echo Version: %COMMAND_VERSION%
echo Built:   %BUILD_TIME%
echo Fetched: %date% %time%
echo ================================================================
echo SAFETY MODE: SOURCE DOWNLOAD / HASH VERIFICATION ONLY.
echo Existing WIN11MEDIA and REPAIRDATA volumes are treated as fixed.
echo No disk-management or filesystem-creation tool is invoked by this build.
echo ================================================================

if not exist "%WORK%" md "%WORK%" >nul 2>&1
if not exist "%CURL%" goto :TOOLSFAIL
if not exist "%NSLOOKUP%" goto :TOOLSFAIL
if not exist "%FINDSTR%" goto :TOOLSFAIL
if not exist "%CERTUTIL%" goto :TOOLSFAIL
if not exist "%CSCRIPT%" goto :TOOLSFAIL

rem Locate the completed USB volumes by their unique labels. No disk-number access.
for %%D in (D E F G H I J K L M N O P Q R S T U V W Y Z) do (
  if exist %%D:\ (
    vol %%D: >"%WORK%\vol-%%D.txt" 2>&1
    "%FINDSTR%" /i /c:"WIN11MEDIA" "%WORK%\vol-%%D.txt" >nul 2>&1
    if not errorlevel 1 (
      set /a BOOTCOUNT+=1
      set "BOOTVOL=%%D:"
    )
    "%FINDSTR%" /i /c:"REPAIRDATA" "%WORK%\vol-%%D.txt" >nul 2>&1
    if not errorlevel 1 (
      set /a DATACOUNT+=1
      set "DATAVOL=%%D:"
    )
  )
)

if not "!BOOTCOUNT!"=="1" goto :MEDIAFAIL
if not "!DATACOUNT!"=="1" goto :MEDIAFAIL
if /i "!BOOTVOL!"=="!DATAVOL!" goto :MEDIAFAIL
if /i "!BOOTVOL!"=="C:" goto :MEDIAFAIL
if /i "!DATAVOL!"=="C:" goto :MEDIAFAIL

set "DEST=!DATAVOL!\RecoverySource\Win11-24H2-26100.8894-Core-en-us"
set "UUPDIR=!DEST!\UUPs"
set "JSON=!DEST!\uup-api-response.json"
set "STATE=!DEST!\DOWNLOAD_STATE.txt"
set "HELPER=!DEST!\uup-download.js"
set "LOCALMANIFEST=!DATAVOL!\RecoverySource\RECOVERY_MANIFEST.md"
set "EDITIONLOG=!DEST!\offline-edition.txt"
set "LANGLOG=!DEST!\offline-language.txt"
if not exist "!DEST!" md "!DEST!" >nul 2>&1
if not exist "!UUPDIR!" md "!UUPDIR!" >nul 2>&1

rem Read-only identity validation of the offline Windows installation.
if exist "%DISM%" if exist "C:\Windows\System32\Config\SYSTEM" (
  "%DISM%" /Image:C:\ /Get-CurrentEdition /English >"!EDITIONLOG!" 2>&1
  "%DISM%" /Image:C:\ /Get-Intl /English >"!LANGLOG!" 2>&1
  "%FINDSTR%" /i /c:"Current Edition : Core" "!EDITIONLOG!" >nul 2>&1
  if not errorlevel 1 set "OFFEDITION=CORE"
  "%FINDSTR%" /i /c:"Default system UI language : en-US" "!LANGLOG!" >nul 2>&1
  if not errorlevel 1 set "OFFLANG=EN-US"
)
if /i not "!OFFEDITION!"=="CORE" goto :WINDOWSFAIL
if /i not "!OFFLANG!"=="EN-US" goto :WINDOWSFAIL

rem Restore WinRE networking automatically if needed.
call :CHECKNET
if errorlevel 1 (
  "%WPEUTIL%" InitializeNetwork >nul 2>&1
  "%PING%" -n 3 127.0.0.1 >nul 2>&1
  call :CHECKNET
)
if errorlevel 1 goto :NETFAIL

rem Fetch the current recovery manifest and the small JSON downloader helper from
rem this repository through GitHub's API. These are text/code only; neither can
rem perform disk layout or filesystem creation.
call :RESOLVE %GHAPIHOST% GHIP
if defined GHIP (
  "%CURL%" --ssl-no-revoke --fail --silent --show-error --connect-timeout 20 --max-time 120 --resolve "%GHAPIHOST%:443:!GHIP!" -H "Accept: application/vnd.github.raw+json" -H "Cache-Control: no-cache, no-store, max-age=0" "%RECOVERYMANIFESTURL%" -o "!LOCALMANIFEST!"
  "%CURL%" --ssl-no-revoke --fail --silent --show-error --connect-timeout 20 --max-time 120 --resolve "%GHAPIHOST%:443:!GHIP!" -H "Accept: application/vnd.github.raw+json" -H "Cache-Control: no-cache, no-store, max-age=0" "%HELPERURL%" -o "!HELPER!"
) else (
  "%CURL%" --ssl-no-revoke --fail --silent --show-error --connect-timeout 20 --max-time 120 -H "Accept: application/vnd.github.raw+json" -H "Cache-Control: no-cache, no-store, max-age=0" "%RECOVERYMANIFESTURL%" -o "!LOCALMANIFEST!"
  "%CURL%" --ssl-no-revoke --fail --silent --show-error --connect-timeout 20 --max-time 120 -H "Accept: application/vnd.github.raw+json" -H "Cache-Control: no-cache, no-store, max-age=0" "%HELPERURL%" -o "!HELPER!"
)
if not exist "!HELPER!" goto :HELPERFAIL
"%FINDSTR%" /i /c:"WinRE-safe UUP dump JSON downloader" "!HELPER!" >nul 2>&1
if errorlevel 1 goto :HELPERFAIL

rem Correct automated endpoint: the official UUP dump JSON API. It returns a
rem response object containing build, arch, and per-file Microsoft URLs/SHA-1s.
call :RESOLVE %UUPAPIHOST% APIIP
if defined APIIP (
  "%CURL%" --ssl-no-revoke --fail --location --silent --show-error --connect-timeout 20 --max-time 300 --resolve "%UUPAPIHOST%:443:!APIIP!" "%UUPAPIURL%" -o "!JSON!"
) else (
  "%CURL%" --ssl-no-revoke --fail --location --silent --show-error --connect-timeout 20 --max-time 300 "%UUPAPIURL%" -o "!JSON!"
)
if errorlevel 1 goto :APIFAIL
if not exist "!JSON!" goto :APIFAIL
"%FINDSTR%" /i /c:"26100.8894" "!JSON!" >nul 2>&1
if errorlevel 1 goto :APIFAIL
"%FINDSTR%" /i /c:"amd64" "!JSON!" >nul 2>&1
if errorlevel 1 goto :APIFAIL

cls
echo ================================================================
echo WINDOWS 11 24H2 DOWNLOAD STARTED
echo Version: %COMMAND_VERSION%
echo ================================================================
echo Boot volume : !BOOTVOL! WIN11MEDIA [UNCHANGED]
echo Data volume : !DATAVOL! REPAIRDATA
echo Source      : UUP dump official JSON API -^> Microsoft UUP URLs
echo Target      : Windows 11 24H2 %UUPBUILD% x64 Core en-US
echo ---------------------------------------------------------------
echo Each completed source file is verified against the API-provided SHA-1.
echo Rerunning C:\wr.cmd safely reuses files that already pass verification.
echo ================================================================

"%CSCRIPT%" //nologo "!HELPER!" "!JSON!" "!UUPDIR!" "%UUPBUILD%" "%CURL%" "%CERTUTIL%" "%NSLOOKUP%" "%DNS%" "!STATE!"
set "DLRC=!errorlevel!"

set "DLSTATUS=UNKNOWN"
set "DLDONE=0"
set "DLTOTAL=0"
set "DLCURRENT="
set "DLMESSAGE="
if exist "!STATE!" (
  for /f "usebackq tokens=1,* delims==" %%A in ("!STATE!") do (
    if /i "%%A"=="status" set "DLSTATUS=%%B"
    if /i "%%A"=="done" set "DLDONE=%%B"
    if /i "%%A"=="total" set "DLTOTAL=%%B"
    if /i "%%A"=="current" set "DLCURRENT=%%B"
    if /i "%%A"=="message" set "DLMESSAGE=%%B"
  )
)

cls
echo ================================================================
echo RECOVERY DOWNLOAD SNAPSHOT
echo Version: %COMMAND_VERSION%
echo ================================================================
echo Recovery manifest : !LOCALMANIFEST!
echo Source build      : %UUPBUILD% / Core / en-US / x64
echo Download status   : !DLSTATUS!
echo Verified files    : !DLDONE! / !DLTOTAL!
if defined DLCURRENT echo Current file      : !DLCURRENT!
if defined DLMESSAGE echo Message           : !DLMESSAGE!
echo ---------------------------------------------------------------
if /i "!DLSTATUS!"=="COMPLETE" (
  echo ASSESSMENT: READY_FOR_UUP_CONVERSION_AND_BOOT_MEDIA_COPY
) else if /i "!DLSTATUS!"=="PAUSED" (
  echo ASSESSMENT: DOWNLOAD_CAN_RESUME_SAFELY
) else (
  echo ASSESSMENT: DOWNLOAD_STAGE_NEEDS_REVIEW
)
echo ---------------------------------------------------------------
echo Disk/filesystem management operations in this build: NONE
echo Take ONE photo of this screen and send it to ChatGPT.
echo ================================================================
exit /b !DLRC!

:CHECKNET
"%PING%" -n 1 -w 2000 1.1.1.1 >nul 2>&1
if not errorlevel 1 exit /b 0
"%PING%" -n 1 -w 2000 8.8.8.8 >nul 2>&1
if not errorlevel 1 exit /b 0
exit /b 1

:RESOLVE
set "%~2="
set "CAND="
for /f "delims=" %%L in ('"%NSLOOKUP%" %~1 %DNS% 2^>nul ^| "%FINDSTR%" /R "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*"') do (
  for %%T in (%%L) do set "CAND=%%T"
  if not "!CAND!"=="%DNS%" set "%~2=!CAND!"
)
exit /b 0

:APIFAIL
set "WHY=Official UUP JSON API did not return the expected 26100.8894 amd64 response."
goto :EARLYFAIL
:HELPERFAIL
set "WHY=Verified UUP JSON downloader helper could not be obtained."
goto :EARLYFAIL
:WINDOWSFAIL
set "WHY=Offline Windows identity did not match Core/en-US. Detected !OFFEDITION!/!OFFLANG!."
goto :EARLYFAIL
:MEDIAFAIL
set "WHY=WIN11MEDIA and REPAIRDATA were not uniquely identified by label."
goto :EARLYFAIL
:NETFAIL
set "WHY=Internet connectivity could not be restored."
goto :EARLYFAIL
:TOOLSFAIL
set "WHY=A required built-in Windows download/parser/verification tool is unavailable."
:EARLYFAIL
cls
echo ================================================================
echo RECOVERY DOWNLOAD SNAPSHOT
echo Version: %COMMAND_VERSION%
echo ================================================================
echo Download status : NOT_STARTED
echo Message         : !WHY!
echo ---------------------------------------------------------------
echo ASSESSMENT: DOWNLOAD_STAGE_NEEDS_REVIEW
echo Disk/filesystem management operations in this build: NONE
echo Take ONE photo of this screen and send it to ChatGPT.
echo ================================================================
exit /b 90
