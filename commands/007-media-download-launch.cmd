@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=REPAIR_WRITE
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Start the resumable verified Windows recovery-source download on the existing REPAIRDATA volume.
rem WR_ACTION=DOWNLOAD_WINDOWS_RECOVERY_SOURCE
rem WR_TARGET=REPAIRDATA RescueMeAI Media workspace only.
rem WR_CONSEQUENCE=Downloads recovery source files only; Windows, boot configuration, disks, and partitions are not modified.
rem WR_ROLLBACK=Delete the downloaded RescueMeAI Media source folder if it is no longer needed.
set "W=C:\WinRERepair"
set "R=%W%\runtime"
set "M=%W%\media"
set "N=%R%\network.cmd"
set "V=%R%\resolve.cmd"
set "C=C:\Windows\System32\curl.exe"
set "H=C:\Windows\System32\certutil.exe"
set "F=C:\Windows\System32\findstr.exe"
set "J=X:\Windows\System32\cscript.exe"
if not exist "%J%" set "J=C:\Windows\System32\cscript.exe"
set "O=%W%\COMMAND_RESULT.env"
set "SRC=7fa4eac814f5a4b017187fdbec05f697df955815"
set "HELP=%M%\uup-download.js"
set "DNS=%M%\rescuemeai-nslookup.cmd"
set "META=%M%\uup-26100.8894-core-en-us.json"
set "UID=44ac3fa1-0cef-463b-a650-6240d396f894"
set "D="
set "IP="
if not exist "%M%" md "%M%" >nul 2>&1
for %%X in (D E F G H I J K L M N O P Q R S T U V W Y Z) do (vol %%X: 2>nul|"%F%" /i /c:"REPAIRDATA" >nul 2>&1&if not errorlevel 1 if not defined D set "D=%%X:")
if not defined D goto :NOVOL
set "DEST=%D%\RescueMeAI\Media\UUP\26100.8894-amd64-core-en-us"
for %%P in ("%D%\RescueMeAI" "%D%\RescueMeAI\Media" "%D%\RescueMeAI\Media\UUP" "%DEST%") do if not exist %%P md %%P >nul 2>&1
call "%N%" fetch "https://api.github.com/repos/RennieBeekharry/winre-repair/contents/tools/uup-download.js?ref=%SRC%" "%HELP%"
if errorlevel 1 goto :FETCHFAIL
call "%N%" fetch "https://api.github.com/repos/RennieBeekharry/winre-repair/contents/tools/rescuemeai-nslookup.cmd?ref=%SRC%" "%DNS%"
if errorlevel 1 goto :FETCHFAIL
"%F%" /i /c:"WR-MODULE: uup-download-js 2026.08.14-1535-ET" "%HELP%" >nul 2>&1
if errorlevel 1 goto :FETCHFAIL
"%F%" /i /c:"WR-MODULE: rescuemeai-nslookup 2026.08.14-1600-ET" "%DNS%" >nul 2>&1
if errorlevel 1 goto :FETCHFAIL
call "%V%" resolve "api.uupdump.net" IP
if errorlevel 1 goto :NETFAIL
"%C%" --ssl-no-revoke --fail --silent --show-error --connect-timeout 15 --max-time 240 --resolve "api.uupdump.net:443:%IP%" "https://api.uupdump.net/get.php?id=%UID%^&lang=en-us^&edition=core" -o "%META%"
if errorlevel 1 goto :NETFAIL
cls
echo ================================================================================================
echo                                    RESCUEMEAI
echo                           WINDOWS RECOVERY MEDIA DOWNLOAD
echo ================================================================================================
echo Source         : Windows 11 24H2 build 26100.8894 x64 Home/Core en-US
echo Destination    : %DEST%
echo Windows changes: NONE
echo ================================================================================================
echo.
echo PLEASE WAIT - the recovery source is downloading and verifying.
echo Leave this window open. Partial downloads are resumable.
echo.
"%J%" //nologo "%HELP%" "%C%" "%H%" "%DNS%" "%META%" "%DEST%" "%M%\uup-download-state.txt"
set "RC=!errorlevel!"
if not "!RC!"=="0" goto :DLFAIL
>"%O%" echo STATUS=PASS
>>"%O%" echo MESSAGE=Windows recovery source download completed and passed verification.
>>"%O%" echo EVIDENCE=Destination=%DEST%; source build 26100.8894 amd64 Core en-us.
>>"%O%" echo INSTRUCTION=Reply pass. RescueMeAI remains online.
exit /b 0
:NOVOL
set "MSG=The existing REPAIRDATA volume could not be found."
set "RC=90"
goto :FAIL
:FETCHFAIL
set "MSG=The pinned recovery-media downloader could not be staged."
set "RC=90"
goto :FAIL
:NETFAIL
set "MSG=The recovery-source metadata service could not be reached."
set "RC=92"
goto :FAIL
:DLFAIL
set "MSG=The recovery-source download stopped before all files verified. Partial files remain resumable."
if not defined RC set "RC=90"
:FAIL
>"%O%" echo STATUS=FAIL
>>"%O%" echo MESSAGE=%MSG%
>>"%O%" echo EVIDENCE=No Windows system, boot, disk, or partition state was changed.
>>"%O%" echo INSTRUCTION=Reply fail. RescueMeAI remains online.
exit /b %RC%
