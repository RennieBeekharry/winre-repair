@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR-MODULE: acceptance 2026.08.14-1325-ET

if /i "%~1"=="check" goto :CHECK
if /i "%~1"=="show" goto :SHOW
exit /b 64

:CHECK
set "WORK=%~2"
if not defined WORK set "WORK=C:\WinRERepair"
set "LEGAL=%WORK%\legal"
set "RECORD=%LEGAL%\acceptance.txt"
set "UI=%WORK%\runtime\ui.cmd"
set "TERMS_VERSION=2026-08-14"
set "VERSION=RMAI-TERMS-%TERMS_VERSION%"
set "ACCEPTED="
set "ACCEPTED_VERSION="

if not exist "%LEGAL%" md "%LEGAL%" >nul 2>&1
if exist "%RECORD%" (
  for /f "usebackq tokens=1,* delims==" %%A in ("%RECORD%") do (
    if /i "%%A"=="accepted" set "ACCEPTED=%%B"
    if /i "%%A"=="terms_version" set "ACCEPTED_VERSION=%%B"
  )
)
if /i "%ACCEPTED%"=="YES" if /i "%ACCEPTED_VERSION%"=="%TERMS_VERSION%" exit /b 0

:TERMS_SCREEN
if exist "%UI%" (
  call "%UI%" screen "%VERSION%" "CONNECTED" "TERMS AND RECOVERY RISK ACCEPTANCE" "REPAIR WRITE - NON-DESTRUCTIVE" "AI-ASSISTED WINDOWS RECOVERY"
  call "%UI%" section WARNING "TERMS AND RECOVERY RISK ACCEPTANCE"
  call "%UI%" line LABEL "Terms version: %TERMS_VERSION%"
  echo.
  call "%UI%" wrap INFO "RescueMeAI is system-recovery software. Recovery operations can cause data loss, corruption, downtime, loss of bootability, or the need for reset, reinstall, professional service, or hardware repair."
  call "%UI%" section INFO "KEY CONDITIONS"
  call "%UI%" wrap INFO "- Recovery results are NOT guaranteed."
  call "%UI%" wrap INFO "- AI recommendations can be wrong and must pass safety controls."
  call "%UI%" wrap INFO "- Back up important data and recovery keys where reasonably possible."
  call "%UI%" wrap INFO "- Technical recovery evidence may be stored locally and, when enabled, sent to the authenticated recovery backend."
  call "%UI%" wrap INFO "- RescueMeAI is provided AS IS to the maximum extent permitted by law."
  call "%UI%" wrap INFO "- Liability is limited and risks are assumed to the maximum extent permitted by applicable law."
  call "%UI%" wrap INFO "- Mandatory legal and consumer rights remain where applicable law does not permit waiver or exclusion."
  call "%UI%" section WARNING "IMPORTANT"
  call "%UI%" wrap WARNING "Typing ACCEPT agrees to the RescueMeAI Terms, Privacy Policy, Licence, and Risk Notice. It does NOT authorize a destructive repair. Destructive actions still require separate local approval."
  call "%UI%" section INFO "LOCAL LEGAL DOCUMENTS"
  call "%UI%" line LABEL "%LEGAL%\TERMS_OF_USE.md"
  call "%UI%" line LABEL "%LEGAL%\PRIVACY_POLICY.md"
  call "%UI%" line LABEL "%LEGAL%\DISCLAIMER_AND_RISK_NOTICE.md"
  call "%UI%" line LABEL "%LEGAL%\LICENSE.md"
  call "%UI%" section INSTRUCTION "ACTION REQUIRED"
  call "%UI%" wrap INSTRUCTION "Type VIEW to display the local Terms of Use. Type exactly ACCEPT to agree and continue. Anything else stops RescueMeAI safely."
  echo.
) else (
  cls
  echo RescueMeAI - Terms and Recovery Risk Acceptance
  echo Terms version: %TERMS_VERSION%
  echo.
  echo Type VIEW to display the local Terms of Use.
  echo Type exactly ACCEPT to agree and continue.
  echo Anything else stops RescueMeAI safely.
  echo.
)
set "TYPED="
set /p "TYPED=ACCEPT TERMS OF USE: "
if "%TYPED%"=="ACCEPT" goto :ACCEPT
if /i "%TYPED%"=="VIEW" goto :SHOW_RETURN
if exist "%UI%" (
  call "%UI%" result WARNING "Terms were not accepted. RescueMeAI will not start." "None." "Rerun RescueMeAI only if you want to review and accept the Terms." "%VERSION%" "CONNECTED"
) else (
  echo.
  echo [WARNING] Terms were not accepted. RescueMeAI will not start.
)
exit /b 40

:SHOW_RETURN
call :SHOW
goto :TERMS_SCREEN

:ACCEPT
>"%RECORD%" echo accepted=YES
>>"%RECORD%" echo terms_version=%TERMS_VERSION%
>>"%RECORD%" echo accepted_phrase=ACCEPT
>>"%RECORD%" echo date=%date%
>>"%RECORD%" echo time=%time%
>>"%RECORD%" echo destructive_authorization=NOT_GRANTED
exit /b 0

:SHOW
set "WORK=%~2"
if not defined WORK set "WORK=C:\WinRERepair"
set "TERMS=%WORK%\legal\TERMS_OF_USE.md"
set "UI=%WORK%\runtime\ui.cmd"
cls
if not exist "%TERMS%" (
  if exist "%UI%" (
    call "%UI%" result FAIL "The local RescueMeAI Terms file is not available." "None." "Do not treat this as acceptance. Restore the legal package before continuing." "RMAI-TERMS-%TERMS_VERSION%" "UNKNOWN"
  ) else (
    echo RescueMeAI Terms file is not available locally.
    echo The application will not treat this as acceptance.
  )
  echo.
  pause
  exit /b 90
)
more < "%TERMS%"
echo.
pause
exit /b 0
