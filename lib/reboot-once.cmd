@echo off
setlocal EnableExtensions
rem RescueMeAI persistent one-shot reboot guard.
rem Usage: call lib\reboot-once.cmd <command-id>
rem Returns 0 only the first time that command-id is authorized to issue a reboot.
rem Returns 40 on every later attempt until the marker is explicitly reviewed/cleared.

set "RMAI_REBOOT_ID=%~1"
set "RMAI_REBOOT_STATE=C:\RescueMeAI\state"
if not defined RMAI_REBOOT_ID exit /b 64
if not exist "%RMAI_REBOOT_STATE%" md "%RMAI_REBOOT_STATE%" >nul 2>&1
set "RMAI_REBOOT_MARKER=%RMAI_REBOOT_STATE%\reboot-command-%RMAI_REBOOT_ID%.issued"

if exist "%RMAI_REBOOT_MARKER%" (
  echo RescueMeAI one-shot reboot guard: command %RMAI_REBOOT_ID% already issued a reboot.
  echo Reboot suppressed. Manual review is required before another reboot.
  exit /b 40
)

>"%RMAI_REBOOT_MARKER%" echo status=ISSUED
>>"%RMAI_REBOOT_MARKER%" echo command_id=%RMAI_REBOOT_ID%
>>"%RMAI_REBOOT_MARKER%" echo guard=ONE_SHOT_PERSISTENT
exit /b 0
