@echo off
setlocal EnableExtensions DisableDelayedExpansion
title RescueMeAI New Device Bootstrap

set "BOOTSTRAP_VERSION=2026-09-09.1"
set "TERMS_VERSION=2026-08-14"

echo ============================================================
echo RescueMeAI - New Device Bootstrap
echo ============================================================
echo.
echo This bootstrap is for a NEW recovery computer.
echo It creates isolated RescueMeAI local state and runs only
echo non-destructive discovery checks. It does NOT run repair.cmd,
echo next.cmd, wr.cmd, reset, format, repartition, or boot repair.
echo.
echo RescueMeAI Terms version: %TERMS_VERSION%
echo Type ACCEPT to continue. Anything else stops.
set /p "RMAI_ACCEPT=> "
if not "%RMAI_ACCEPT%"=="ACCEPT" goto :declined

set "OSDRIVE="
for %%D in (C D E F G H I J K L M N O P Q R S T U V W Y Z) do if not defined OSDRIVE if exist "%%D:\Windows\System32\config\SYSTEM" set "OSDRIVE=%%D:"

if not defined OSDRIVE (
  echo.
  echo [FAIL] No offline Windows installation was found.
  echo WHAT YOU SHOULD DO: Stop and send this screen to ChatGPT.
  echo ADDITIONAL INFORMATION REQUIRED: Drive/volume layout.
  echo ADDITIONAL INSTRUCTIONS: Do not run repair scripts.
  exit /b 20
)

set "BASE=%OSDRIVE%\RescueMeAI"
set "STATE=%BASE%\state"
set "LOGS=%BASE%\logs\current"
set "DIAG=%BASE%\evidence\diagnostics"
set "SUPPORT=%BASE%\evidence\support-bundles"
set "AUTH=%BASE%\auth"
set "CACHE=%BASE%\cache"

for %%P in ("%BASE%" "%STATE%" "%LOGS%" "%DIAG%" "%SUPPORT%" "%AUTH%" "%CACHE%") do if not exist "%%~P" mkdir "%%~P" >nul 2>&1

set "SESSION="
if exist "%STATE%\session-id.txt" set /p "SESSION="<"%STATE%\session-id.txt"
if not defined SESSION set "SESSION=RMAI-%RANDOM%%RANDOM%%RANDOM%%RANDOM%"
>"%STATE%\session-id.txt" echo %SESSION%
>"%STATE%\acceptance.json" echo {"terms_version":"%TERMS_VERSION%","accepted":true}
>"%STATE%\current-session.json" echo {"session_id":"%SESSION%","bootstrap_version":"%BOOTSTRAP_VERSION%","phase":"DISCOVERY","risk":"READ_ONLY","status":"RUNNING"}

set "ONLINE=NO"
ping -n 1 github.com >nul 2>&1 && set "ONLINE=YES"

>"%DIAG%\network.txt" echo RescueMeAI local network evidence - %SESSION%
>>"%DIAG%\network.txt" ipconfig /all

>"%CACHE%\diskpart-readonly.txt" echo list disk
>>"%CACHE%\diskpart-readonly.txt" echo list volume
diskpart /s "%CACHE%\diskpart-readonly.txt" >"%DIAG%\storage-layout.txt" 2>&1
del /q "%CACHE%\diskpart-readonly.txt" >nul 2>&1

bcdedit /enum all >"%DIAG%\bcd.txt" 2>&1
manage-bde -status >"%DIAG%\bitlocker-status.txt" 2>&1

set "SRT=NO"
if exist "%OSDRIVE%\Windows\System32\Logfiles\Srt\SrtTrail.txt" (
  copy /y "%OSDRIVE%\Windows\System32\Logfiles\Srt\SrtTrail.txt" "%DIAG%\SrtTrail.txt" >nul
  set "SRT=YES"
)

dism /Image:%OSDRIVE%\ /Cleanup-Image /CheckHealth >"%DIAG%\dism-checkhealth.txt" 2>&1
set "DISMRC=%ERRORLEVEL%"

set "SUMMARY=%SUPPORT%\RescueMeAI-Support-%SESSION%.txt"
>"%SUMMARY%" echo RescueMeAI Support Summary
>>"%SUMMARY%" echo bootstrap_version=%BOOTSTRAP_VERSION%
>>"%SUMMARY%" echo session_id=%SESSION%
>>"%SUMMARY%" echo terms_version=%TERMS_VERSION%
>>"%SUMMARY%" echo installed_windows_drive=%OSDRIVE%
>>"%SUMMARY%" echo internet_reachable=%ONLINE%
>>"%SUMMARY%" echo startup_repair_log_present=%SRT%
>>"%SUMMARY%" echo dism_checkhealth_exit_code=%DISMRC%
>>"%SUMMARY%" echo system_repair_performed=NO
>>"%SUMMARY%" echo destructive_action_performed=NO
>>"%SUMMARY%" echo raw_evidence_location=%DIAG%

if exist "%DIAG%\dism-checkhealth.txt" (
  >>"%SUMMARY%" echo.
  >>"%SUMMARY%" echo --- DISM CHECKHEALTH RESULT ---
  findstr /I /C:"No component store corruption detected" /C:"The component store is repairable" /C:"The component store cannot be repaired" /C:"Error:" "%DIAG%\dism-checkhealth.txt" >>"%SUMMARY%" 2>nul
)

if exist "%DIAG%\SrtTrail.txt" (
  >>"%SUMMARY%" echo.
  >>"%SUMMARY%" echo --- STARTUP REPAIR EXCERPT ---
  findstr /I /C:"Root cause" /C:"Repair action" /C:"Error code" /C:"Result" "%DIAG%\SrtTrail.txt" >>"%SUMMARY%" 2>nul
)

>"%STATE%\current-session.json" echo {"session_id":"%SESSION%","bootstrap_version":"%BOOTSTRAP_VERSION%","phase":"DISCOVERY","risk":"READ_ONLY","status":"COMPLETE"}

set "USBCOPY=NO"
if not "%~1"=="" if exist "%~1\" (
  copy /y "%SUMMARY%" "%~1\RescueMeAI-Support-%SESSION%.txt" >nul 2>&1
  if not errorlevel 1 set "USBCOPY=YES"
)

echo.
echo ============================================================
echo [PASS] RescueMeAI new-device bootstrap complete.
echo ============================================================
echo Session: %SESSION%
echo Windows: %OSDRIVE%\Windows
echo Internet: %ONLINE%
echo Repair performed: NO
echo Destructive action performed: NO
echo Local evidence: %DIAG%
echo Support summary: %SUMMARY%
if "%USBCOPY%"=="YES" echo USB support-summary copy: %~1\RescueMeAI-Support-%SESSION%.txt
echo.
echo WHAT YOU SHOULD DO: Send ChatGPT a photo of the summary below,
echo or upload the RescueMeAI-Support file copied to your USB.
echo ADDITIONAL INFORMATION REQUIRED: Current crash/boot symptom.
echo ADDITIONAL INSTRUCTIONS: Do not run legacy repair.cmd/next.cmd/wr.cmd.
echo.
type "%SUMMARY%"
exit /b 0

:declined
echo.
echo [WARNING] Terms were not accepted. RescueMeAI did not start.
echo WHAT YOU SHOULD DO: Stop here unless you choose to accept the Terms.
echo ADDITIONAL INFORMATION REQUIRED: None.
echo ADDITIONAL INSTRUCTIONS: No recovery action was performed.
exit /b 10
