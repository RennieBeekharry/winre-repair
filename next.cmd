@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=REPAIR_WRITE
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_ACTION=LOCAL_FRESH_UEFI_BCD_REBUILD_V33
rem WR_TARGET=Windows UEFI boot files and BCD only.
rem WR_CONSEQUENCE=Backs up the current BCD, rebuilds it from C:\Windows BCD-Template with BCDBoot /c, verifies paths, and stops before reboot.
rem WR_ROLLBACK=BCD backup is retained in C:\WinRERepair. No formatting, repartitioning, reset, reinstall, or driver changes.

set "VERSION=RMAI-2026.08.15-BCD-LOCAL-33"
set "R=C:\WinRERepair"
set "BCD=C:\Windows\System32\bcdedit.exe"
set "BOOT=C:\Windows\System32\bcdboot.exe"
set "WINLOAD=C:\Windows\System32\winload.efi"
set "TEMPLATE=C:\Windows\System32\Config\BCD-Template"
set "BAK=%R%\BCD.before-fresh-rebuild3.bak"
set "LOG=%R%\START33_BCD_REBUILD.txt"
set "BM=%R%\START33_BOOTMGR.txt"
set "DF=%R%\START33_DEFAULT.txt"
set "STAGE=PRECHECK"
set "RC=N/A"
set "REASON=Not started"

title RescueMeAI - Windows Recovery
if not exist "%R%" md "%R%" >nul 2>&1
if exist "%LOG%" del /f /q "%LOG%" >nul 2>&1

call :SCREEN "PRECHECK" "Validating the offline Windows boot source before any change."
if not exist "%BCD%" set "REASON=Offline bcdedit.exe is missing." & goto :FAIL
if not exist "%BOOT%" set "REASON=Offline bcdboot.exe is missing." & goto :FAIL
if not exist "%WINLOAD%" set "REASON=Offline winload.efi is missing." & goto :FAIL
if not exist "%TEMPLATE%" set "REASON=Offline BCD-Template is missing." & goto :FAIL

>"%LOG%" echo RESCUEMEAI START-33 FRESH UEFI BCD REBUILD
>>"%LOG%" echo version=%VERSION%
>>"%LOG%" echo windows=C:\Windows
>>"%LOG%" echo backup=%BAK%
>>"%LOG%" echo precheck=PASS

set "STAGE=BACKUP"
call :SCREEN "BACKING UP CURRENT BCD" "Creating a rollback copy before changing boot configuration."
"%BCD%" /export "%BAK%" >>"%LOG%" 2>&1
set "RC=!errorlevel!"
>>"%LOG%" echo bcd_export_return_code=!RC!
if not "!RC!"=="0" set "REASON=BCD export failed; rebuild was not started." & goto :FAIL
if not exist "%BAK%" set "REASON=BCD export reported success but the backup file is missing." & goto :FAIL

set "STAGE=REBUILD"
call :SCREEN "FRESH UEFI / BCD REBUILD" "Rebuilding Windows boot configuration from the offline BCD template."
>>"%LOG%" echo.
>>"%LOG%" echo [BCDBOOT_C]
"%BOOT%" C:\Windows /l en-us /c /v >>"%LOG%" 2>&1
set "RC=!errorlevel!"
>>"%LOG%" echo bcdboot_return_code=!RC!
if not "!RC!"=="0" set "REASON=BCDBoot /c did not complete successfully." & goto :WARNING

set "STAGE=VERIFY"
call :SCREEN "VERIFYING FRESH BOOT CONFIGURATION" "Checking Boot Manager and Windows loader paths before any reboot."
"%BCD%" /enum {bootmgr} /v >"%BM%" 2>&1
set "BMRC=!errorlevel!"
"%BCD%" /enum {default} /v >"%DF%" 2>&1
set "DFRC=!errorlevel!"
>>"%LOG%" echo bootmgr_enum_return_code=!BMRC!
>>"%LOG%" echo default_enum_return_code=!DFRC!
>>"%LOG%" echo.
>>"%LOG%" echo [BOOTMGR_AFTER]
type "%BM%" >>"%LOG%"
>>"%LOG%" echo.
>>"%LOG%" echo [DEFAULT_AFTER]
type "%DF%" >>"%LOG%"
if not "!BMRC!"=="0" set "REASON=Fresh BCD was created, but Boot Manager enumeration failed." & goto :WARNING
if not "!DFRC!"=="0" set "REASON=Fresh BCD was created, but default loader enumeration failed." & goto :WARNING

findstr /i /c:"\EFI\Microsoft\Boot\bootmgfw.efi" "%BM%" >nul 2>&1
if errorlevel 1 set "REASON=Fresh BCD was created, but bootmgfw.efi was not verified." & goto :WARNING
findstr /i /c:"device                  partition=C:" "%DF%" >nul 2>&1
if errorlevel 1 set "REASON=Fresh BCD was created, but device=partition=C: was not verified." & goto :WARNING
findstr /i /c:"osdevice                partition=C:" "%DF%" >nul 2>&1
if errorlevel 1 set "REASON=Fresh BCD was created, but osdevice=partition=C: was not verified." & goto :WARNING
findstr /i /c:"\Windows\system32\winload.efi" "%DF%" >nul 2>&1
if errorlevel 1 set "REASON=Fresh BCD was created, but winload.efi was not verified." & goto :WARNING

>>"%LOG%" echo result=PASS
call :PASS
exit /b 0

:WARNING
>>"%LOG%" echo result=WARNING
>>"%LOG%" echo reason=!REASON!
cls
color 0E >nul 2>&1
echo ====================================================================================================
echo                                           RESCUEMEAI
echo                                      RESULT: WARNING
echo ====================================================================================================
echo Launcher/session : %VERSION%
echo Windows changes  : BOOT CONFIGURATION ONLY
echo Stage            : !STAGE!
echo ====================================================================================================
echo.
echo WHAT HAPPENED
echo ----------------------------------------------------------------------------------------------------
echo !REASON!
echo.
echo SAFETY STATUS
echo ----------------------------------------------------------------------------------------------------
echo BCD backup       : %BAK%
echo Personal files  : NOT MODIFIED
echo Partitions      : NOT MODIFIED
echo Drivers         : NOT MODIFIED
echo Reset/reinstall : NOT ATTEMPTED
echo Reboot          : NOT PERFORMED
echo.
echo LOCAL EVIDENCE
echo ----------------------------------------------------------------------------------------------------
echo %LOG%
echo.
echo WHAT YOU NEED TO DO
echo ----------------------------------------------------------------------------------------------------
echo Take one photo of this entire screen and send it to ChatGPT.
echo DO NOT reboot yet. RescueMeAI stopped before the boot test.
echo ====================================================================================================
pause
exit /b 0

:FAIL
>>"%LOG%" echo result=FAIL
>>"%LOG%" echo stage=!STAGE!
>>"%LOG%" echo reason=!REASON!
cls
color 0C >nul 2>&1
echo ====================================================================================================
echo                                           RESCUEMEAI
echo                                       RESULT: FAIL
echo ====================================================================================================
echo Launcher/session : %VERSION%
echo Windows changes  : STOPPED AT !STAGE!
echo ====================================================================================================
echo.
echo EXACT FAILURE LOCATION
echo ----------------------------------------------------------------------------------------------------
echo Stage       : !STAGE!
echo Reason      : !REASON!
echo Return code : !RC!
echo.
echo SAFETY STATUS
echo ----------------------------------------------------------------------------------------------------
echo No reset, reinstall, format, repartition, or driver update was attempted.
echo If the BCD backup step completed, the backup is retained at:
echo %BAK%
echo.
echo LOCAL EVIDENCE
echo ----------------------------------------------------------------------------------------------------
echo %LOG%
echo.
echo WHAT YOU NEED TO DO
echo ----------------------------------------------------------------------------------------------------
echo Take one photo of this entire screen and send it to ChatGPT.
echo DO NOT reboot yet.
echo ====================================================================================================
pause
exit /b 90

:PASS
cls
color 0A >nul 2>&1
echo ====================================================================================================
echo                                           RESCUEMEAI
echo                                         RESULT: PASS
echo ====================================================================================================
echo Launcher/session : %VERSION%
echo Windows changes  : FRESH UEFI / BCD REBUILD COMPLETED
echo ====================================================================================================
echo.
echo WHAT HAPPENED
echo ----------------------------------------------------------------------------------------------------
echo The existing BCD was backed up and BCDBoot /c rebuilt a fresh Windows boot configuration.
echo Boot Manager and the default Windows loader paths passed post-rebuild verification.
echo.
echo VERIFIED
echo ----------------------------------------------------------------------------------------------------
echo Boot Manager     : \EFI\Microsoft\Boot\bootmgfw.efi
echo Windows device   : partition=C:
echo Windows osdevice : partition=C:
echo Windows loader   : \Windows\system32\winload.efi
echo.
echo SAFETY STATUS
echo ----------------------------------------------------------------------------------------------------
echo BCD backup       : %BAK%
echo Personal files  : NOT MODIFIED
echo Partitions      : NOT MODIFIED
echo Drivers         : NOT MODIFIED
echo Reset/reinstall : NOT ATTEMPTED
echo Reboot          : NOT PERFORMED
echo.
echo LOCAL EVIDENCE
echo ----------------------------------------------------------------------------------------------------
echo %LOG%
echo.
echo WHAT YOU NEED TO DO
echo ----------------------------------------------------------------------------------------------------
echo Take one photo of this entire screen and send it to ChatGPT.
echo DO NOT reboot yet. We will perform a controlled boot test next.
echo ====================================================================================================
pause
exit /b 0

:SCREEN
cls
color 0B >nul 2>&1
echo ====================================================================================================
echo                                           RESCUEMEAI
echo                                  AI-ASSISTED WINDOWS RECOVERY
echo ====================================================================================================
echo Launcher/session : %VERSION%
echo Current stage    : %~1
echo Windows changes  : BOOT CONFIGURATION ONLY AFTER BACKUP
echo ====================================================================================================
echo.
echo %~2
echo.
echo PLEASE WAIT - no action is required.
echo Do not close this window or reboot the PC during this operation.
exit /b 0
