@echo off
setlocal EnableExtensions DisableDelayedExpansion
rem WR_RISK=READ_ONLY
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Show the user a detailed RescueMeAI recovery status dashboard.
rem WR_ACTION=SHOW_RECOVERY_STATUS
rem WR_TARGET=Console display and RescueMeAI local status only.
rem WR_CONSEQUENCE=Displays diagnosis, completed work, current state, next action, and screenshot requirement. No Windows changes.
rem WR_ROLLBACK=Not applicable; display-only status command.

set "WORK=C:\WinRERepair"
set "RESULT=%WORK%\COMMAND_RESULT.env"
if not exist "%WORK%" md "%WORK%" >nul 2>&1

cls
echo ================================================================================
echo RescueMeAI - RECOVERY STATUS
echo ================================================================================
echo Status        : WAITING FOR NEXT REVIEWED STEP
echo Safety        : READ-ONLY STATUS SCREEN - no Windows changes are being made
echo Connection    : ONLINE - secure outbound GitHub channel active
echo.
echo CURRENT DIAGNOSIS
echo -------------------------------------------------------------------------------
echo 1. Windows Startup Repair found: a recently serviced boot binary is corrupt.
echo 2. Startup Repair tried to uninstall the latest cumulative update and failed
echo    with error 0x831.
echo 3. BCD/boot entries look structurally normal.
echo 4. BitLocker is unlocked and the C: filesystem is not dirty.
echo 5. The Windows component store is repairable.
echo 6. DISM RestoreHealth failed with error 0x800f0915.
echo 7. Recovery DISM reports version 10.0.26100.8972 while the Windows image is
echo    10.0.26200.9168.
echo 8. The installed Windows DISM binary can query the offline image successfully,
echo    but it reports the same DISM version. The version mismatch alone is therefore
echo    not yet proven to be the root cause of 0x800f0915.
echo.
echo COMPLETED SO FAR
echo -------------------------------------------------------------------------------
echo [PASS] Secure RescueMeAI channel established
echo [PASS] Read-only boot diagnostics collected
echo [PASS] Startup Repair root cause identified
echo [PASS] BCD / BitLocker / filesystem checks completed
echo [FAIL] First DISM RestoreHealth attempt - error 0x800f0915
echo [PASS] Follow-up servicing diagnostics completed
echo [PASS] Installed DISM metadata-only compatibility query completed
echo.
echo CURRENTLY BEING DONE
echo -------------------------------------------------------------------------------
echo No repair is running right now.
echo RescueMeAI is reviewing the servicing evidence before the next write operation.
echo The machine remains online and is waiting for a validated next command.
echo.
echo USER ACTION
echo -------------------------------------------------------------------------------
echo SCREENSHOT REQUIRED : NO
echo WHAT TO DO           : Leave this window open and keep the PC connected to power.
echo NEXT STEP            : RescueMeAI will update this screen when the next task starts.
echo.
echo IMPORTANT
echo -------------------------------------------------------------------------------
echo If a future screen says "SCREENSHOT REQUIRED : YES", send ChatGPT a photo of
echo that screen. Otherwise, you do not need to send a screenshot after every task.
echo ================================================================================

>"%RESULT%" echo STATUS=PASS
>>"%RESULT%" echo MESSAGE=Detailed recovery status screen displayed.
>>"%RESULT%" echo EVIDENCE=No Windows changes; user action is to leave the recovery channel open.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=NO
>>"%RESULT%" echo NEXT_STEP=Wait for the next reviewed RescueMeAI command.
exit /b 0
