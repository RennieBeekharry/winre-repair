@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "COMMAND_VERSION=WR-2026.08.14-0425-ET"
set "BUILD_TIME=2026-08-14 04:25 ET"
set "WORK=C:\WinRERepair"
set "CURL=C:\Windows\System32\curl.exe"
set "NSLOOKUP=C:\Windows\System32\nslookup.exe"
set "FINDSTR=C:\Windows\System32\findstr.exe"
set "FIND=C:\Windows\System32\find.exe"
set "CERTUTIL=C:\Windows\System32\certutil.exe"
set "DISM=X:\Windows\System32\dism.exe"
if not exist "%DISM%" set "DISM=C:\Windows\System32\dism.exe"
set "WPEUTIL=X:\Windows\System32\wpeutil.exe"
set "PING=X:\Windows\System32\ping.exe"
set "DNS=64.71.255.204"
set "UUPHOST=uupdump.net"
set "UUPID=44ac3fa1-0cef-463b-a650-6240d396f894"
set "UUPBUILD=26100.8894"
set "UUPURL=https://uupdump.net/get.php?id=%UUPID%&pack=en-us&edition=core&aria2=2"
set "BOOTVOL="
set "DATAVOL="
set "BOOTCOUNT=0"
set "DATACOUNT=0"
set "OFFEDITION=UNKNOWN"
set "OFFLANG=UNKNOWN"
set "TOTAL=0"
set "DONE=0"
set "FAILED=0"
set "FAILFILE="

cls
echo ================================================================
echo WINRE-REPAIR - WINDOWS 11 24H2 RECOVERY SOURCE DOWNLOAD
echo Version: %COMMAND_VERSION%
echo Built:   %BUILD_TIME%
echo Fetched: %date% %time%
echo ================================================================
echo.
echo SAFETY MODE: DOWNLOAD/VERIFY ONLY.
echo This command contains no disk-management or filesystem-creation operations.
echo It writes recovery-source files only to the existing REPAIRDATA volume.
echo.

if not exist "%WORK%" md "%WORK%" >nul 2>&1
if not exist "%CURL%" goto :TOOLSFAIL
if not exist "%FINDSTR%" goto :TOOLSFAIL
if not exist "%CERTUTIL%" goto :TOOLSFAIL

rem Locate the already-created media volumes by LABEL, not by disk number.
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
set "MANIFEST=!DEST!\uup-26100.8894-core-en-us.aria2.txt"
set "EDITIONLOG=!DEST!\offline-edition.txt"
set "LANGLOG=!DEST!\offline-language.txt"
if not exist "!DEST!" md "!DEST!" >nul 2>&1
if not exist "!UUPDIR!" md "!UUPDIR!" >nul 2>&1

rem Read-only validation of the offline Windows edition and base language.
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

rem Restore WinRE networking automatically if necessary.
call :CHECKNET
if errorlevel 1 (
  "%WPEUTIL%" InitializeNetwork >nul 2>&1
  "%PING%" -n 3 127.0.0.1 >nul 2>&1
  call :CHECKNET
)
if errorlevel 1 goto :NETFAIL

rem Obtain a fresh UUP file manifest. UUP dump generates Microsoft delivery URLs
rem and SHA-1 checksums; no executable is downloaded or run from UUP dump.
set "UUPIP="
call :RESOLVE %UUPHOST% UUPIP
if defined UUPIP (
  "%CURL%" --ssl-no-revoke --fail --location --silent --show-error --connect-timeout 20 --max-time 180 --resolve "%UUPHOST%:443:!UUPIP!" "%UUPURL%" -o "!MANIFEST!"
) else (
  "%CURL%" --ssl-no-revoke --fail --location --silent --show-error --connect-timeout 20 --max-time 180 "%UUPURL%" -o "!MANIFEST!"
)
if errorlevel 1 goto :MANIFESTFAIL
if not exist "!MANIFEST!" goto :MANIFESTFAIL
"%FINDSTR%" /i /c:"#UUPDUMP_ERROR:" "!MANIFEST!" >nul 2>&1
if not errorlevel 1 goto :MANIFESTFAIL
"%FINDSTR%" /b /i "http" "!MANIFEST!" >nul 2>&1
if errorlevel 1 goto :MANIFESTFAIL
"%FINDSTR%" /b /c:"  checksum=sha-1=" "!MANIFEST!" >nul 2>&1
if errorlevel 1 goto :MANIFESTFAIL

for /f %%N in ('"%FINDSTR%" /b /c:"  checksum=sha-1=" "!MANIFEST!" ^| "%FIND%" /c /v ""') do set "TOTAL=%%N"
if "!TOTAL!"=="0" goto :MANIFESTFAIL

cls
echo ================================================================
echo WINDOWS 11 24H2 DOWNLOAD STARTED
echo Version: %COMMAND_VERSION%
echo ================================================================
echo Boot volume : !BOOTVOL! WIN11MEDIA  [READ ONLY THIS PASS]
echo Data volume : !DATAVOL! REPAIRDATA
 echo Source      : Windows 11 24H2 %UUPBUILD% x64 Core en-US
 echo Files       : !TOTAL!
echo ---------------------------------------------------------------
echo This can take a long time. Completed files are hash-checked and reused
 echo if C:\wr.cmd is run again after an interruption.
echo ================================================================

set "CURURL="
set "CUROUT="
set "CURHASH="
for /f "usebackq delims=" %%L in ("!MANIFEST!") do (
  set "LINE=%%L"
  if /i "!LINE:~0,4!"=="http" (
    set "CURURL=!LINE!"
    set "CUROUT="
    set "CURHASH="
  )
  if /i "!LINE:~0,6!"=="  out=" set "CUROUT=!LINE:~6!"
  if /i "!LINE:~0,17!"=="  checksum=sha-1=" (
    set "CURHASH=!LINE:~17!"
    if defined CURURL if defined CUROUT if defined CURHASH call :DOWNLOAD_CURRENT
  )
  if "!FAILED!"=="1" goto :DOWNLOADFAIL
)

if not "!DONE!"=="!TOTAL!" goto :DOWNLOADFAIL

cls
echo ================================================================
echo RECOVERY SOURCE DOWNLOAD COMPLETE
echo Version: %COMMAND_VERSION%
echo ================================================================
echo Windows source : Windows 11 24H2 %UUPBUILD% x64 Core en-US
echo Downloaded     : !DONE! / !TOTAL! files
echo Verification   : SHA-1 PASSED FOR ALL FILES
echo Stored at      : !UUPDIR!
echo Boot volume    : !BOOTVOL! WIN11MEDIA [UNCHANGED]
echo Data volume    : !DATAVOL! REPAIRDATA
echo ---------------------------------------------------------------
echo STATUS: READY_FOR_UUP_CONVERSION_AND_BOOT_MEDIA_COPY
echo ================================================================
echo No disk layout or filesystem creation operation exists in this build.
exit /b 0

:DOWNLOAD_CURRENT
set /a DONE+=1
set "FINAL=!UUPDIR!\!CUROUT!"
set "PART=!FINAL!.part"
echo [!DONE!/!TOTAL!] !CUROUT!

rem Reuse a previously completed file only after its published SHA-1 matches.
if exist "!FINAL!" (
  "%CERTUTIL%" -hashfile "!FINAL!" SHA1 2>nul | "%FINDSTR%" /i /c:"!CURHASH!" >nul 2>&1
  if not errorlevel 1 exit /b 0
  move /y "!FINAL!" "!FINAL!.unverified" >nul 2>&1
)

set "DLHOST="
for /f "tokens=2 delims=/" %%H in ("!CURURL!") do set "DLHOST=%%H"
set "DLIP="
if defined DLHOST call :RESOLVE !DLHOST! DLIP

if defined DLIP (
  "%CURL%" --ssl-no-revoke --fail --location --silent --show-error --retry 4 --retry-delay 3 --connect-timeout 20 --max-time 7200 --resolve "!DLHOST!:443:!DLIP!" "!CURURL!" -o "!PART!"
) else (
  "%CURL%" --ssl-no-revoke --fail --location --silent --show-error --retry 4 --retry-delay 3 --connect-timeout 20 --max-time 7200 "!CURURL!" -o "!PART!"
)
if errorlevel 1 (
  set "FAILED=1"
  set "FAILFILE=!CUROUT!"
  exit /b 1
)

"%CERTUTIL%" -hashfile "!PART!" SHA1 2>nul | "%FINDSTR%" /i /c:"!CURHASH!" >nul 2>&1
if errorlevel 1 (
  set "FAILED=1"
  set "FAILFILE=!CUROUT! [SHA-1 mismatch]"
  exit /b 1
)
move /y "!PART!" "!FINAL!" >nul 2>&1
exit /b 0

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

:DOWNLOADFAIL
cls
echo ================================================================
echo RECOVERY SOURCE DOWNLOAD PAUSED
echo Version: %COMMAND_VERSION%
echo ================================================================
echo Completed before stop : !DONE! / !TOTAL!
echo File needing retry    : !FAILFILE!
echo Stored at             : !UUPDIR!
echo ---------------------------------------------------------------
echo No disk layout or filesystem operation was performed.
echo Run C:\wr.cmd again later; verified completed files will be reused.
echo ================================================================
exit /b 94

:MANIFESTFAIL
cls
echo ================================================================
echo RECOVERY DOWNLOAD NOT STARTED
echo UUP dump did not return a valid Microsoft download manifest.
echo Build: %UUPBUILD% / Core / en-US / x64
echo No disk or filesystem operation was performed.
echo ================================================================
exit /b 93

:WINDOWSFAIL
cls
echo ================================================================
echo RECOVERY DOWNLOAD NOT STARTED
echo Offline Windows identity did not match the selected recovery source.
echo Detected edition : !OFFEDITION!
echo Detected language: !OFFLANG!
echo Expected         : CORE / EN-US
echo No disk or filesystem operation was performed.
echo ================================================================
exit /b 92

:MEDIAFAIL
cls
echo ================================================================
echo RECOVERY DOWNLOAD NOT STARTED
echo Existing WIN11MEDIA / REPAIRDATA labels were not uniquely identified.
echo No disk or filesystem operation was performed.
echo ================================================================
exit /b 91

:NETFAIL
cls
echo ================================================================
echo RECOVERY DOWNLOAD NOT STARTED
echo Internet connection could not be restored.
echo No disk or filesystem operation was performed.
echo ================================================================
exit /b 90

:TOOLSFAIL
cls
echo ================================================================
echo RECOVERY DOWNLOAD NOT STARTED
echo A required built-in Windows download or verification tool is unavailable.
echo No disk or filesystem operation was performed.
echo ================================================================
exit /b 89
