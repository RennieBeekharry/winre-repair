@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR-MODULE: acceptance 2026.08.14-1160-ET

if /i "%~1"=="check" goto :CHECK
if /i "%~1"=="show" goto :SHOW
exit /b 64

:CHECK
set "WORK=%~2"
if not defined WORK set "WORK=C:\WinRERepair"
set "LEGAL=%WORK%\legal"
set "RECORD=%LEGAL%\acceptance.txt"
set "TERMS_VERSION=2026-08-14"
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
cls
color 0E >nul 2>&1
echo ================================================================
echo RESCUEMEAI - TERMS AND RECOVERY RISK ACCEPTANCE
echo Terms version: %TERMS_VERSION%
echo ================================================================
echo RescueMeAI is system-recovery software. Recovery operations can
echo cause data loss, corruption, downtime, loss of bootability, or the
echo need for reset, reinstall, professional service, or hardware repair.
echo.
echo Key conditions:
echo   - Recovery results are NOT guaranteed.
echo   - AI recommendations can be wrong and must pass safety controls.
echo   - Back up important data and recovery keys where reasonably possible.
echo   - Technical recovery evidence may be stored locally and, when
echo     enabled, sent to the authenticated recovery backend.
echo   - RescueMeAI is provided AS IS to the maximum extent permitted by law.
echo   - Liability is limited and risks are assumed to the maximum extent
echo     permitted by applicable law.
echo   - Mandatory legal/consumer rights are not waived where law forbids it.
echo.
echo IMPORTANT:
echo   Typing ACCEPT agrees to the Terms of Use, Privacy Policy, Licence,
echo   and Disclaimer/Risk Notice. It does NOT authorize a destructive
echo   repair. Destructive actions still require their own local approval.
echo.
echo Local legal documents:
echo   %LEGAL%\TERMS_OF_USE.md
echo   %LEGAL%\PRIVACY_POLICY.md
echo   %LEGAL%\DISCLAIMER_AND_RISK_NOTICE.md
echo   %LEGAL%\LICENSE.md
echo.
echo Type VIEW to display the Terms of Use now.
echo Type exactly ACCEPT to agree and continue.
echo Anything else stops RescueMeAI without performing recovery actions.
echo ================================================================
set "TYPED="
set /p "TYPED=Selection: "
if "%TYPED%"=="ACCEPT" goto :ACCEPT
if /i "%TYPED%"=="VIEW" goto :SHOW_RETURN
color 0E >nul 2>&1
echo.
echo [WARNING] Terms were not accepted. RescueMeAI will not start.
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
color 07 >nul 2>&1
exit /b 0

:SHOW
set "WORK=%~2"
if not defined WORK set "WORK=C:\WinRERepair"
set "TERMS=%WORK%\legal\TERMS_OF_USE.md"
cls
if not exist "%TERMS%" (
  echo RescueMeAI Terms file is not available locally.
  echo The application will not treat this as acceptance.
  echo.
  pause
  exit /b 90
)
more < "%TERMS%"
echo.
pause
exit /b 0
