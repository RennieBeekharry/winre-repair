@echo off
setlocal EnableExtensions
rem WR_RISK=REPAIR_WRITE
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Install a durable local RescueMeAI reconnect shortcut so the recovery agent can be restarted with C:\r.cmd after a reboot.
rem WR_ACTION=INSTALL_PERSISTENT_RECONNECT
rem WR_TARGET=C:\RescueMeAI\reconnect.cmd and C:\r.cmd only.
rem WR_CONSEQUENCE=Creates two small local recovery helper scripts; Windows system files, boot configuration, partitions, and personal files are not modified.
rem WR_ROLLBACK=Delete C:\r.cmd and C:\RescueMeAI\reconnect.cmd if no longer wanted.

set "WORK=C:\WinRERepair"
set "DEST=C:\RescueMeAI"
set "RESULT=%WORK%\COMMAND_RESULT.env"
set "DETAILS=%WORK%\RUN_DETAILS.txt"
set "CURL=C:\Windows\System32\curl.exe"
set "SRC=https://raw.githubusercontent.com/RennieBeekharry/winre-repair/a1a690ceef2b0e4d03e90c87eb05f38aa9091e6b/reconnect.cmd"

if not exist "%DEST%" md "%DEST%" >nul 2>&1

cls
echo ================================================================
echo RescueMeAI - INSTALLING QUICK RECONNECT
echo ================================================================
echo STATUS            : RUNNING
echo CURRENT TASK      : Installing a persistent RescueMeAI reconnect shortcut.
echo SAFETY            : REPAIR-WRITE - recovery helper files only.
echo WINDOWS FILES     : NOT MODIFIED
echo PERSONAL FILES    : NOT TOUCHED
echo ================================================================

"%CURL%" --ssl-no-revoke -fL "%SRC%" -o "%DEST%\reconnect.cmd"
if errorlevel 1 goto :FAIL

>"C:\r.cmd" echo @echo off
>>"C:\r.cmd" echo call C:\RescueMeAI\reconnect.cmd

if not exist "%DEST%\reconnect.cmd" goto :FAIL
if not exist "C:\r.cmd" goto :FAIL

>"%DETAILS%" echo RESCUEMEAI PERSISTENT RECONNECT INSTALL
>>"%DETAILS%" echo reconnect_file=C:\RescueMeAI\reconnect.cmd
>>"%DETAILS%" echo shortcut_file=C:\r.cmd
>>"%DETAILS%" echo future_reconnect_command=C:\r.cmd
>>"%DETAILS%" echo windows_system_files_modified=NO
>>"%DETAILS%" echo personal_files_targeted=NO

>"%RESULT%" echo STATUS=PASS
>>"%RESULT%" echo MESSAGE=Persistent RescueMeAI reconnect shortcut installed successfully.
>>"%RESULT%" echo EVIDENCE=C:\r.cmd now launches C:\RescueMeAI\reconnect.cmd and reuses the existing local session when possible.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=NO
>>"%RESULT%" echo NEXT_STEP=After any future reboot into recovery, run C:\r.cmd to reconnect.

echo.
echo ================================================================
echo STATUS            : COMPLETE
echo QUICK RECONNECT   : C:\r.cmd
echo NEXT TIME         : Type only C:\r.cmd
echo SCREENSHOT NEEDED : NO
echo ================================================================
exit /b 0

:FAIL
>"%RESULT%" echo STATUS=FAIL
>>"%RESULT%" echo MESSAGE=Persistent reconnect shortcut could not be installed.
>>"%RESULT%" echo EVIDENCE=No Windows system files or personal files were modified.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=YES
echo.
echo STATUS            : RECONNECT INSTALL FAILED
echo SCREENSHOT NEEDED : YES
exit /b 90
