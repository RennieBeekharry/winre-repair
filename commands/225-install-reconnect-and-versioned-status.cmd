@echo off
setlocal EnableExtensions
rem WR_RISK=REPAIR_WRITE
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Install persistent RescueMeAI reconnect and display versioned recovery status.
rem WR_ACTION=INSTALL_RECONNECT_AND_DISPLAY_VERSIONED_STATUS
rem WR_TARGET=C:\r.cmd, C:\RescueMeAI\reconnect.cmd, console status, and bounded result only.
rem WR_CONSEQUENCE=Creates or refreshes two small recovery helper scripts. No Windows system, boot, disk, registry, package, or personal-file changes are made.
rem WR_ROLLBACK=Delete C:\r.cmd and C:\RescueMeAI\reconnect.cmd if no longer wanted.

set "FIX_VERSION=RMAI-FIX-2026.09.10.1"
set "SESSION=RMAI-733546361603117444"
set "WORK=C:\WinRERepair"
set "DEST=C:\RescueMeAI"
set "RESULT=%WORK%\COMMAND_RESULT.env"
set "DETAILS=%WORK%\RUN_DETAILS.txt"
set "CURL=C:\Windows\System32\curl.exe"
set "SRC=https://raw.githubusercontent.com/RennieBeekharry/winre-repair/a1a690ceef2b0e4d03e90c87eb05f38aa9091e6b/reconnect.cmd"
if not exist "%DEST%" md "%DEST%" >nul 2>&1
cls
echo ================================================================================
echo RescueMeAI - RECOVERY CASE STATUS
echo ================================================================================
echo RECOVERY FIX      : %FIX_VERSION%
echo SESSION           : %SESSION%
echo STATUS            : RUNNING
echo CURRENT TASK      : Installing the permanent one-command reconnect helper.
echo SAFETY            : REPAIR-WRITE - RescueMeAI helper files only.
echo WINDOWS SYSTEM    : NOT MODIFIED
echo PERSONAL FILES    : NOT TOUCHED
echo REBOOT            : NO
echo SCREENSHOT NEEDED : NO - wait for the final status below.
echo ================================================================================
echo.
echo [1/3] Installing C:\RescueMeAI\reconnect.cmd...
"%CURL%" --ssl-no-revoke -fL "%SRC%" -o "%DEST%\reconnect.cmd"
if errorlevel 1 goto :FAIL
echo [2/3] Creating the short reconnect command C:\r.cmd...
>"C:\r.cmd" echo @echo off
>>"C:\r.cmd" echo call C:\RescueMeAI\reconnect.cmd
if not exist "%DEST%\reconnect.cmd" goto :FAIL
if not exist "C:\r.cmd" goto :FAIL
echo [3/3] Recording the versioned recovery status...
>"%DETAILS%" echo RESCUEMEAI VERSIONED RECOVERY CASE STATUS
>>"%DETAILS%" echo fix_version=%FIX_VERSION%
>>"%DETAILS%" echo session_id=%SESSION%
>>"%DETAILS%" echo quick_reconnect_installed=YES
>>"%DETAILS%" echo quick_reconnect_command=C:\r.cmd
>>"%DETAILS%" echo current_state=POST_SFC_BOOT_TEST_HUNG_RETURNED_TO_WINRE
>>"%DETAILS%" echo windows_changes_performed=NO
>"%RESULT%" echo STATUS=PASS
>>"%RESULT%" echo MESSAGE=Persistent reconnect installed and versioned recovery case status displayed.
>>"%RESULT%" echo EVIDENCE=Fix version %FIX_VERSION%; C:\r.cmd installed; no Windows system or personal files changed.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=NO
>>"%RESULT%" echo NEXT_STEP=Review the failed boot test before any additional repair or reboot.
echo.
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STATUS              : READY - SECURE RECOVERY SESSION STABILIZED
echo QUICK RECONNECT     : C:\r.cmd
echo CURRENT DIAGNOSIS   : SFC completed and verification was clean, but the first
echo                       controlled Windows boot test stalled at the HP logo.
echo                       BitLocker recovery is complete and WinRE is available.
echo CURRENT TASK        : WAITING for the next reviewed recovery step.
echo SAFETY              : NO WINDOWS CHANGES ARE RUNNING NOW
echo REBOOT              : NO
echo WHAT YOU SHOULD DO  : WAIT. Leave this window open and keep the laptop on power.
echo SCREENSHOT REQUIRED : NO
echo HOW TO REPLY        : SUCCESS if Windows boots; FAILED plus photo on an error;
echo                       STUCK if progress stops; READY when asked for confirmation.
echo ================================================================================
exit /b 0
:FAIL
>"%RESULT%" echo STATUS=FAIL
>>"%RESULT%" echo MESSAGE=Persistent reconnect installation failed.
>>"%RESULT%" echo EVIDENCE=No Windows system files or personal files were modified.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=YES
echo.
echo RECOVERY FIX        : %FIX_VERSION%
echo STATUS              : STOPPED - RECONNECT INSTALL FAILED
echo SCREENSHOT REQUIRED : YES
echo WHAT TO DO          : Send ChatGPT a photo of THIS screen. Do not reboot.
exit /b 90
