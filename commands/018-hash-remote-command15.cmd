@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=READ_ONLY
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Download the immutable command-15 file through RescueMeAI's normal source path and report its exact SHA-256 without executing it.
rem WR_ACTION=HASH_REMOTE_COMMAND15
rem WR_TARGET=RescueMeAI command transport and local diagnostic files only.
rem WR_CONSEQUENCE=Downloads and hashes a public recovery command file. It does not execute that file or change Windows.
rem WR_ROLLBACK=No Windows recovery state is changed.

set "WORK=C:\WinRERepair"
set "OUT=%WORK%\COMMAND_RESULT.env"
set "NETWORK=%WORK%\runtime\network.cmd"
set "TMP=%WORK%\agent\command15-hashprobe.cmd"
set "HASH=%WORK%\agent\command15-hashprobe.txt"
set "URL=https://api.github.com/repos/RennieBeekharry/winre-repair/contents/commands/015-boot-storage-diagnostic.cmd?ref=cc55e9e8a224912f3495cab217bbda4b157cf4e1"
if not exist "%NETWORK%" goto :BAD
if exist "%TMP%" del /f /q "%TMP%" >nul 2>&1
if exist "%HASH%" del /f /q "%HASH%" >nul 2>&1
call "%NETWORK%" fetch "%URL%" "%TMP%"
if errorlevel 1 goto :BAD
certutil -hashfile "%TMP%" SHA256 >"%HASH%" 2>&1
if errorlevel 1 goto :BAD
set "H="
for /f "usebackq skip=1 tokens=1" %%H in ("%HASH%") do if not defined H set "H=%%H"
if not defined H goto :BAD
>"%OUT%" echo STATUS=PASS
>>"%OUT%" echo MESSAGE=RescueMeAI calculated the exact SHA-256 of the immutable command-15 download.
>>"%OUT%" echo EVIDENCE=COMMAND15_REMOTE_SHA256=!H!
>>"%OUT%" echo INSTRUCTION=Reply pass. RescueMeAI remains online.
exit /b 0

:BAD
>"%OUT%" echo STATUS=FAIL
>>"%OUT%" echo MESSAGE=RescueMeAI could not calculate the immutable command-15 SHA-256.
>>"%OUT%" echo EVIDENCE=No Windows changes were attempted.
>>"%OUT%" echo INSTRUCTION=Reply fail. RescueMeAI remains online.
exit /b 90
