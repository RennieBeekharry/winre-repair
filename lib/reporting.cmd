@echo off
rem WR-MODULE: reporting 2026.08.14-0948-ET
if /i "%~1"=="write" goto :WRITE
if /i "%~1"=="usbcopy" goto :USBCOPY
exit /b 64

:WRITE
set "WR_R_STATUS=%~2"
set "WR_R_RC=%~3"
set "WR_R_COMMAND=%~4"
set "WR_R_MESSAGE=%~5"
if not exist "C:\WinRERepair" md "C:\WinRERepair" >nul 2>&1
>"C:\WinRERepair\LAST_RUN_REPORT.txt" echo status=%WR_R_STATUS%
>>"C:\WinRERepair\LAST_RUN_REPORT.txt" echo return_code=%WR_R_RC%
>>"C:\WinRERepair\LAST_RUN_REPORT.txt" echo command_version=%WR_R_COMMAND%
>>"C:\WinRERepair\LAST_RUN_REPORT.txt" echo date=%date%
>>"C:\WinRERepair\LAST_RUN_REPORT.txt" echo time=%time%
>>"C:\WinRERepair\LAST_RUN_REPORT.txt" echo message=%WR_R_MESSAGE%
exit /b 0

:USBCOPY
set "WR_R_VOL="
for %%D in (D E F G H I J K L M N O P Q R S T U V W Y Z) do (
  if exist %%D:\ (
    vol %%D: >"C:\WinRERepair\vol-report-%%D.txt" 2>&1
    findstr /i /c:"REPAIRDATA" "C:\WinRERepair\vol-report-%%D.txt" >nul 2>&1
    if not errorlevel 1 set "WR_R_VOL=%%D:"
  )
)
if not defined WR_R_VOL exit /b 40
if not exist "%WR_R_VOL%\RecoverySource" md "%WR_R_VOL%\RecoverySource" >nul 2>&1
copy /y "C:\WinRERepair\LAST_RUN_REPORT.txt" "%WR_R_VOL%\RecoverySource\LAST_RUN_REPORT.txt" >nul 2>&1
if exist "C:\WinRERepair\RUN_DETAILS.txt" copy /y "C:\WinRERepair\RUN_DETAILS.txt" "%WR_R_VOL%\RecoverySource\RUN_DETAILS.txt" >nul 2>&1
exit /b 0
