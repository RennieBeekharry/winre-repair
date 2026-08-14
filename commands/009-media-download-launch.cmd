@echo off
setlocal EnableExtensions
rem WR_RISK=REPAIR_WRITE
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Download and verify the selected Windows 11 recovery source into the existing REPAIRDATA media workspace.
rem WR_ACTION=DOWNLOAD_WINDOWS_RECOVERY_SOURCE
rem WR_TARGET=REPAIRDATA RescueMeAI Media workspace only.
rem WR_CONSEQUENCE=Downloads recovery source files only. Windows system state, boot configuration, disks, and partitions are not modified.
rem WR_ROLLBACK=Delete the RescueMeAI Media source folder if the downloaded source is no longer needed.
set "W=C:\WinRERepair"
set "N=%W%\runtime\network.cmd"
set "F=C:\Windows\System32\findstr.exe"
set "CORE=%W%\media\009-media-download-core.cmd"
set "O=%W%\COMMAND_RESULT.env"
if not exist "%W%\media" md "%W%\media" >nul 2>&1
call "%N%" fetch "https://api.github.com/repos/RennieBeekharry/winre-repair/contents/commands/009-media-download-core.cmd?ref=8fe3768de8e11d794af0d24883e6cd536749d2ab" "%CORE%"
if errorlevel 1 goto :FAIL
"%F%" /i /c:"WR-MODULE: media-download-core 2026.08.14-1611-ET" "%CORE%" >nul 2>&1
if errorlevel 1 goto :FAIL
call "%CORE%"
exit /b %errorlevel%
:FAIL
>"%O%" echo STATUS=FAIL
>>"%O%" echo MESSAGE=RescueMeAI could not stage the pinned media-download core.
>>"%O%" echo EVIDENCE=No Windows system, boot, disk, or partition state was changed.
>>"%O%" echo INSTRUCTION=Reply fail. RescueMeAI remains online.
exit /b 90
