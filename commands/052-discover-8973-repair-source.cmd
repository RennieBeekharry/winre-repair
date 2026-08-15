@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=READ_ONLY
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Discover and validate an exact Windows 11 24H2 x64 build 26100.8973 Home/Core Microsoft-UUP recovery-source candidate after command 51 confirmed that 26100.8973 is the installed cumulative build.
rem WR_ACTION=DISCOVER_EXACT_8973_REPAIR_SOURCE
rem WR_TARGET=Network metadata plus C:\WinRERepair media workspace and private recovery evidence only.
rem WR_CONSEQUENCE=Downloads metadata only. No Windows packages, registry values, drivers, boot files, partitions, or personal files are modified.
rem WR_ROLLBACK=Delete the temporary metadata files if no longer needed; Windows recovery state is unchanged.

set "R=C:\WinRERepair"
set "M=%R%\media"
set "O=%R%\COMMAND_RESULT.env"
set "A=%R%\runtime\github-auth.cmd"
set "N=%R%\runtime\network.cmd"
set "UI=%R%\runtime\ui.cmd"
set "C=C:\Windows\System32\curl.exe"
set "F=C:\Windows\System32\findstr.exe"
set "J=X:\Windows\System32\cscript.exe"
if not exist "%J%" set "J=C:\Windows\System32\cscript.exe"
set "DOH=%M%\doh-resolve.js"
set "SEL=%M%\uup-select-build.js"
set "IPOUT=%M%\uup52-addresses.txt"
set "LIST=%M%\uup52-list-26100.8973.json"
set "CHOICE=%M%\uup52-selected.env"
set "META=%M%\uup-26100.8973-core-en-us.json"
set "Q=%R%\diag52-uup-8973-source.txt"
set "UUPIP="
set "UUID="
if not exist "%M%" md "%M%" >nul 2>&1
if not exist "%C%" goto :BAD
if not exist "%F%" goto :BAD
if not exist "%J%" goto :BAD

call :STAGE "1 of 5" "Preparing the verified exact-build source-discovery helpers."
if not exist "%DOH%" (
  call "%N%" fetch "https://api.github.com/repos/RennieBeekharry/winre-repair/contents/tools/doh-resolve.js?ref=58ec5e2c1896ba1823df1ed9a88667072a17bfc7" "%DOH%"
  if errorlevel 1 goto :BAD
)
call "%N%" fetch "https://api.github.com/repos/RennieBeekharry/winre-repair/contents/tools/uup-select-build.js?ref=58ec5e2c1896ba1823df1ed9a88667072a17bfc7" "%SEL%"
if errorlevel 1 goto :BAD
"%F%" /i /c:"WR-MODULE: uup-select-build-js 2026.08.15-1040-ET" "%SEL%" >nul 2>&1
if errorlevel 1 goto :BAD

call :STAGE "2 of 5" "Resolving the UUP metadata service without relying on WinRE DNS state."
if exist "%IPOUT%" del /f /q "%IPOUT%" >nul 2>&1
"%J%" //nologo "%DOH%" "%C%" "api.uupdump.net" >"%IPOUT%" 2>nul
if errorlevel 1 goto :NETFAIL
for /f "usebackq tokens=1,2 delims=: " %%A in ("%IPOUT%") do if /i "%%A"=="Address" if not defined UUPIP set "UUPIP=%%B"
if not defined UUPIP goto :NETFAIL

call :STAGE "3 of 5" "Finding the exact Windows 11 build 26100.8973 x64 candidate."
if exist "%LIST%" del /f /q "%LIST%" >nul 2>&1
"%C%" --ssl-no-revoke --fail --silent --show-error --connect-timeout 20 --max-time 120 --resolve "api.uupdump.net:443:%UUPIP%" "https://api.uupdump.net/listid.php?search=26100.8973&sortByDate=1" -o "%LIST%" 2>"%M%\uup52-list-error.txt"
if errorlevel 1 goto :NETFAIL
if not exist "%LIST%" goto :NETFAIL
"%J%" //nologo "%SEL%" "%LIST%" "26100.8973" "amd64" >"%CHOICE%" 2>nul
set "SRC_RC=!errorlevel!"
if not "!SRC_RC!"=="0" goto :NOMATCH
for /f "usebackq tokens=1,* delims==" %%A in ("%CHOICE%") do (
  if /i "%%A"=="UUID" set "UUID=%%B"
)
if not defined UUID goto :NOMATCH

call :STAGE "4 of 5" "Validating Home/Core en-US file metadata for the exact 26100.8973 candidate."
if exist "%META%" del /f /q "%META%" >nul 2>&1
"%C%" --ssl-no-revoke --fail --silent --show-error --connect-timeout 20 --max-time 300 --resolve "api.uupdump.net:443:%UUPIP%" "https://api.uupdump.net/get.php?id=%UUID%&lang=en-us&edition=core" -o "%META%" 2>"%M%\uup52-meta-error.txt"
if errorlevel 1 goto :NETFAIL
if not exist "%META%" goto :NETFAIL
for %%Z in ("%META%") do if %%~zZ LSS 1024 goto :METFAIL
"%F%" /i /c:"26100.8973" "%META%" >nul 2>&1
if errorlevel 1 goto :METFAIL
"%F%" /i /c:"amd64" "%META%" >nul 2>&1
if errorlevel 1 goto :METFAIL

>"%Q%" echo RESCUEMEAI COMMAND 52 - EXACT REPAIR SOURCE DISCOVERY
>>"%Q%" echo windows_changes=NONE
>>"%Q%" echo installed_target_build=26100.8973
>>"%Q%" echo target_arch=amd64
>>"%Q%" echo target_edition=core
>>"%Q%" echo target_language=en-us
>>"%Q%" echo api_address=%UUPIP%
type "%CHOICE%" >>"%Q%"
for %%Z in ("%META%") do >>"%Q%" echo metadata_bytes=%%~zZ
>>"%Q%" echo metadata_path=%META%
>>"%Q%" echo decision=EXACT_8973_SOURCE_METADATA_VALIDATED

call :STAGE "5 of 5" "Uploading the exact-source candidate for AI review before any large download begins."
>"%R%\LAST_RUN_REPORT.txt" echo status=PASS
>>"%R%\LAST_RUN_REPORT.txt" echo message=Exact Windows 11 24H2 build 26100.8973 x64 Core recovery-source metadata was discovered and validated.
>"%R%\RUN_DETAILS.txt" echo diagnostic=DISCOVER_EXACT_8973_REPAIR_SOURCE
type "%Q%" >>"%R%\RUN_DETAILS.txt"
call "%A%" upload >nul 2>&1
if errorlevel 1 goto :UPLOADFAIL
>"%O%" echo STATUS=PASS
>>"%O%" echo MESSAGE=RescueMeAI found and validated exact build 26100.8973 x64 Home/Core recovery-source metadata; no large source files were downloaded yet.
>>"%O%" echo EVIDENCE=Private report contains the selected build UUID and validated metadata size/path.
>>"%O%" echo INSTRUCTION=No user action is required. Leave RescueMeAI online; do not reboot yet.
exit /b 0

:STAGE
if exist "%UI%" call "%UI%" screen "RMAI-AGENT-V2-2026.08.14-1508-ET" "CONNECTED" "RUNNING COMMAND 52" "READ ONLY" "AI-ASSISTED WINDOWS RECOVERY" "INFO"
echo.
echo RECOVERY ACTIVITY
echo ------------------------------------------------------------------------------------------------
echo Step %~1
echo %~2
echo.
echo No action is required. RescueMeAI is still working.
exit /b 0

:NOMATCH
set "WHY=No exact Windows 11 26100.8973 amd64 candidate was returned by the metadata service."
goto :FAIL
:METFAIL
set "WHY=The selected exact-build candidate did not return valid 26100.8973 amd64 Core metadata."
goto :FAIL
:NETFAIL
set "WHY=The recovery-source metadata service could not be reached or validated."
goto :FAIL
:UPLOADFAIL
>"%O%" echo STATUS=WARNING
>>"%O%" echo MESSAGE=Exact 26100.8973 source discovery completed locally but private upload failed.
>>"%O%" echo EVIDENCE=No Windows changes and no large source download occurred.
>>"%O%" echo INSTRUCTION=Leave RescueMeAI online; do not reboot.
exit /b 20
:BAD
set "WHY=RescueMeAI could not initialize exact-build source discovery."
:FAIL
>"%R%\LAST_RUN_REPORT.txt" echo status=FAIL
>>"%R%\LAST_RUN_REPORT.txt" echo message=%WHY%
>"%R%\RUN_DETAILS.txt" echo diagnostic=DISCOVER_EXACT_8973_REPAIR_SOURCE_FAIL
>>"%R%\RUN_DETAILS.txt" echo windows_changes=NONE
>>"%R%\RUN_DETAILS.txt" echo reason=%WHY%
if exist "%CHOICE%" type "%CHOICE%" >>"%R%\RUN_DETAILS.txt"
call "%A%" upload >nul 2>&1
>"%O%" echo STATUS=FAIL
>>"%O%" echo MESSAGE=%WHY%
>>"%O%" echo EVIDENCE=No Windows changes and no large recovery-source download occurred.
>>"%O%" echo INSTRUCTION=Leave RescueMeAI online; do not reboot.
exit /b 90
