@echo off
setlocal EnableExtensions
rem WR_RISK=READ_ONLY
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Display the current versioned RescueMeAI recovery case status and clear user instructions without changing Windows.
rem WR_ACTION=DISPLAY_VERSIONED_RECOVERY_STATUS
rem WR_TARGET=Console display and bounded RescueMeAI result only.
rem WR_CONSEQUENCE=No Windows, boot, disk, registry, package, or personal-file changes are made.
rem WR_ROLLBACK=Not applicable; this command is read-only.

set "FIX_VERSION=RMAI-FIX-2026.09.10.1"
set "SESSION=RMAI-733546361603117444"
set "WORK=C:\WinRERepair"
set "RESULT=%WORK%\COMMAND_RESULT.env"
set "DETAILS=%WORK%\RUN_DETAILS.txt"
set "RECONNECT=NO"
if exist "C:\r.cmd" if exist "C:\RescueMeAI\reconnect.cmd" set "RECONNECT=YES"

cls
echo ================================================================================
echo RescueMeAI - RECOVERY CASE STATUS
echo ================================================================================
echo RECOVERY FIX      : %FIX_VERSION%
echo SESSION           : %SESSION%
echo STATUS            : CONNECTED - REVIEWED RECOVERY IN PROGRESS
echo.
echo CURRENT DIAGNOSIS : Windows previously failed to boot after Startup Repair
echo                     identified a recently serviced boot binary as corrupt.
echo                     Offline SFC completed successfully and post-repair
echo                     verification was clean, but the first controlled boot
echo                     test stalled at the HP loading screen.
echo                     BitLocker recovery has been completed and WinRE is open.
echo.
echo CURRENT TASK      : Stabilizing the recovery session before further boot repair.
echo QUICK RECONNECT   : %RECONNECT%
echo SAFETY            : READ-ONLY STATUS SCREEN - no Windows changes in this step.
echo PERSONAL FILES    : NOT TOUCHED
echo REBOOT            : NO
echo ================================================================================
echo.
echo WHAT YOU SHOULD DO NOW
echo   WAIT. Leave this window open and keep the laptop connected to power.
echo   Do not reboot, reset, format, or run additional commands unless this screen
echo   explicitly asks you to do so.
echo.
echo WHEN TO SEND A SCREENSHOT
echo   Only when SCREENSHOT REQUIRED says YES, or an unexpected blue/recovery/error
echo   screen appears.
echo.
echo HOW TO REPLY TO CHATGPT
echo   SUCCESS - if Windows reaches the normal sign-in screen or desktop.
echo   FAILED  - if Windows shows Recovery, a blue screen, or a boot error; attach photo.
echo   STUCK   - if a running step shows no progress for the time shown on-screen.
echo   READY   - if this screen says WAITING/READY and ChatGPT asks for confirmation.
echo.
echo SCREENSHOT REQUIRED : NO
echo NEXT STEP           : RescueMeAI is reviewing the failed boot test and will
echo                       display the next reviewed task here.
echo ================================================================================

>"%DETAILS%" echo RESCUEMEAI VERSIONED RECOVERY CASE STATUS
>>"%DETAILS%" echo fix_version=%FIX_VERSION%
>>"%DETAILS%" echo session_id=%SESSION%
>>"%DETAILS%" echo quick_reconnect_installed=%RECONNECT%
>>"%DETAILS%" echo current_state=POST_SFC_BOOT_TEST_HUNG_RETURNED_TO_WINRE
>>"%DETAILS%" echo windows_changes_performed=NO
>>"%DETAILS%" echo screenshot_required=NO

>"%RESULT%" echo STATUS=PASS
>>"%RESULT%" echo MESSAGE=Versioned recovery case status is displayed and RescueMeAI remains ready for the next reviewed step.
>>"%RESULT%" echo EVIDENCE=Fix version %FIX_VERSION%; reconnect installed=%RECONNECT%; no Windows changes were made.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=NO
>>"%RESULT%" echo NEXT_STEP=Review the failed boot test before any additional repair or reboot.
exit /b 0
