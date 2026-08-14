@echo off
setlocal EnableExtensions
rem WR_RISK=READ_ONLY
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Hold RescueMeAI recovery execution until repository-scoped GitHub App pairing is configured.
rem WR_ACTION=PAIRING_CONFIGURATION_HOLD
rem WR_TARGET=No Windows, disk, boot, registry, partition, or filesystem target.
rem WR_CONSEQUENCE=Displays configuration status only. No recovery action is executed.
rem WR_ROLLBACK=No changes are made.

set "COMMAND_VERSION=RMAI-2026.08.14-PAIRING-HOLD"
cls
color 0E >nul 2>&1
echo ================================================================
echo [WARNING] RESCUEMEAI SECURE PAIRING SETUP REQUIRED
echo ================================================================
echo RescueMeAI has intentionally stopped before authentication.
echo.
echo Reason:
echo   The temporary GitHub OAuth approach requested a permission scope
echo   broader than the single private recovery-evidence repository.
echo   RescueMeAI is fail-closed rather than weakening the security model.
echo.
echo No Windows repair action was executed.
echo No disk, partition, filesystem, boot, or registry change was made.
echo No GitHub authorization was requested.
echo.
echo WHAT YOU SHOULD DO:
echo   Do not rerun C:\wr.cmd until ChatGPT confirms secure pairing is ready.
echo.
echo ADDITIONAL INFORMATION REQUIRED:
echo   None from this PC.
echo.
echo Reply to ChatGPT with exactly: warning
echo ================================================================
exit /b 40
