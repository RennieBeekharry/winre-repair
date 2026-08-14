@echo off
setlocal EnableExtensions EnableDelayedExpansion

rem Post-driver 0x7B evidence pass. READ-ONLY against the offline Windows image.
set "COMMAND_VERSION=WR-2026.08.14-0106-ET"
set "BUILD_TIME=2026-08-14 01:06 ET"
set "OS=C:"
set "WORK=C:\WinRERepair"
set "LOG=%WORK%\post-driver-0x7b-diagnostic.log"
set "USBLOG=H:\RepairLogs"
set "REG=X:\Windows\System32\reg.exe"
set "DISM=X:\Windows\System32\dism.exe"
set "BCDEDIT=X:\Windows\System32\bcdedit.exe"
set "FINDSTR=C:\Windows\System32\findstr.exe"

cls
echo ================================================================
echo WINRE-REPAIR - POST-DRIVER 0x7B DIAGNOSTIC
echo Version: %COMMAND_VERSION%
echo Built:   %BUILD_TIME%
echo Fetched: %date% %time%
echo Mode:    READ-ONLY - NO REPAIR CHANGES
echo ================================================================

if not exist "%OS%\Windows\System32\Config\SYSTEM" (
  echo Windows was not found on C:. Stopping.
  exit /b 10
)
if not exist "%WORK%" md "%WORK%" >nul 2>&1
if exist "H:\" if not exist "%USBLOG%" md "%USBLOG%" >nul 2>&1

>"%LOG%" echo [%date% %time%] START %COMMAND_VERSION%
call :LOG "Build: %BUILD_TIME%"
call :LOG "Target: %OS%\Windows"
call :LOG "Purpose: verify post-install driver binding and Microsoft-documented 0x7B state"

rem -----------------------------------------------------------------
rem 1. Offline Windows version and installed third-party driver state.
rem -----------------------------------------------------------------
call :SECTION "OFFLINE WINDOWS VERSION"
%REG% unload HKLM\WR_SOFT >nul 2>&1
%REG% load HKLM\WR_SOFT "%OS%\Windows\System32\Config\SOFTWARE" >>"%LOG%" 2>&1
if not errorlevel 1 (
  %REG% query "HKLM\WR_SOFT\Microsoft\Windows NT\CurrentVersion" /v ProductName >>"%LOG%" 2>&1
  %REG% query "HKLM\WR_SOFT\Microsoft\Windows NT\CurrentVersion" /v DisplayVersion >>"%LOG%" 2>&1
  %REG% query "HKLM\WR_SOFT\Microsoft\Windows NT\CurrentVersion" /v CurrentBuildNumber >>"%LOG%" 2>&1
  %REG% query "HKLM\WR_SOFT\Microsoft\Windows NT\CurrentVersion" /v UBR >>"%LOG%" 2>&1
  %REG% unload HKLM\WR_SOFT >>"%LOG%" 2>&1
)

call :SECTION "DISM DRIVER INVENTORY"
%DISM% /Image:%OS%\ /Get-Drivers /All /English /Format:Table /LogPath:"%WORK%\dism-post-driver-inventory.log" >"%WORK%\driver-inventory.txt" 2>&1
type "%WORK%\driver-inventory.txt" >>"%LOG%"
call :LOG "Matches for Intel 16.7 / iaAHCI / iaStor:"
%FINDSTR% /i "16.7.1.1012 iaahc iastor" "%WORK%\driver-inventory.txt" >>"%LOG%" 2>&1

rem -----------------------------------------------------------------
rem 2. Active control set, controller binding, boot-critical services.
rem -----------------------------------------------------------------
call :SECTION "OFFLINE SYSTEM HIVE"
%REG% unload HKLM\WR_SYS >nul 2>&1
%REG% load HKLM\WR_SYS "%OS%\Windows\System32\Config\SYSTEM" >>"%LOG%" 2>&1
if errorlevel 1 (
  call :LOG "ERROR: Could not load SYSTEM hive"
  goto :AFTER_SYSTEM
)

%REG% query HKLM\WR_SYS\Select >>"%LOG%" 2>&1
set "CSNUM="
for /f "tokens=3" %%A in ('%REG% query HKLM\WR_SYS\Select /v Current 2^>nul ^| %FINDSTR% /i "Current"') do set /a CSDEC=%%A
if defined CSDEC (
  set "CSNUM=00!CSDEC!"
  set "CSNUM=!CSNUM:~-3!"
) else (
  set "CSNUM=001"
)
set "CS=ControlSet!CSNUM!"
call :LOG "Resolved active control set: !CS!"

call :SECTION "DEV_A102 CONTROLLER ENUM BINDING"
%REG% query "HKLM\WR_SYS\!CS!\Enum\PCI" /s /f "VEN_8086&DEV_A102" >>"%LOG%" 2>&1

call :SECTION "BOOT-CRITICAL STORAGE SERVICES"
for %%S in (iaStorA iaStorAC iaStorAVC iaStorV storahci storport disk partmgr volmgr volsnap volume) do (
  echo ---- %%S ---->>"%LOG%"
  %REG% query "HKLM\WR_SYS\!CS!\Services\%%S" /v Start >>"%LOG%" 2>&1
  %REG% query "HKLM\WR_SYS\!CS!\Services\%%S" /v ImagePath >>"%LOG%" 2>&1
  %REG% query "HKLM\WR_SYS\!CS!\Services\%%S" /v Group >>"%LOG%" 2>&1
)

call :SECTION "STORAGE CLASS FILTERS"
for %%G in ({4D36E96A-E325-11CE-BFC1-08002BE10318} {4D36E967-E325-11CE-BFC1-08002BE10318} {4D36E97B-E325-11CE-BFC1-08002BE10318} {71A27CDD-812A-11D0-BEC7-08002BE2092F}) do (
  echo ---- %%G ---->>"%LOG%"
  %REG% query "HKLM\WR_SYS\!CS!\Control\Class\%%G" /v UpperFilters >>"%LOG%" 2>&1
  %REG% query "HKLM\WR_SYS\!CS!\Control\Class\%%G" /v LowerFilters >>"%LOG%" 2>&1
)

call :SECTION "PENDING FILE RENAME OPERATIONS"
%REG% query "HKLM\WR_SYS\!CS!\Control\Session Manager" /v PendingFileRenameOperations >>"%LOG%" 2>&1

%REG% unload HKLM\WR_SYS >>"%LOG%" 2>&1
:AFTER_SYSTEM

rem -----------------------------------------------------------------
rem 3. Servicing pending state. Inspection only; nothing is reverted.
rem -----------------------------------------------------------------
call :SECTION "COMPONENT SERVICING PENDING STATE"
%REG% unload HKLM\WR_COMP >nul 2>&1
if exist "%OS%\Windows\System32\Config\COMPONENTS" (
  %REG% load HKLM\WR_COMP "%OS%\Windows\System32\Config\COMPONENTS" >>"%LOG%" 2>&1
  if not errorlevel 1 (
    %REG% query HKLM\WR_COMP /v PendingXmlIdentifier >>"%LOG%" 2>&1
    %REG% query HKLM\WR_COMP /s /f PendingXmlIdentifier >>"%LOG%" 2>&1
    %REG% unload HKLM\WR_COMP >>"%LOG%" 2>&1
  )
)

call :SECTION "DISM PACKAGE STATES"
%DISM% /Image:%OS%\ /Get-Packages /English /Format:Table /LogPath:"%WORK%\dism-package-state.log" >"%WORK%\package-state.txt" 2>&1
type "%WORK%\package-state.txt" >>"%LOG%"
call :LOG "Pending-state package matches:"
%FINDSTR% /i "Pending Install Pending Uninstall Staged" "%WORK%\package-state.txt" >>"%LOG%" 2>&1

rem -----------------------------------------------------------------
rem 4. Boot and storage files; SetupAPI evidence from attempted startup.
rem -----------------------------------------------------------------
call :SECTION "STORAGE DRIVER FILES"
dir /a "%OS%\Windows\System32\drivers\iaStor*.sys" >>"%LOG%" 2>&1
dir /a "%OS%\Windows\System32\drivers\storahci.sys" >>"%LOG%" 2>&1
dir /a "%OS%\Windows\System32\drivers\storport.sys" >>"%LOG%" 2>&1

call :SECTION "SETUPAPI STORAGE BINDING EVIDENCE"
if exist "%OS%\Windows\INF\setupapi.dev.log" (
  %FINDSTR% /i "DEV_A102 iaAHCIC iaStorAC iaStorA 16.7.1.1012" "%OS%\Windows\INF\setupapi.dev.log" >"%WORK%\setupapi-storage.txt" 2>&1
  type "%WORK%\setupapi-storage.txt" >>"%LOG%"
) else (
  call :LOG "setupapi.dev.log not found"
)

call :SECTION "BCD ENUMERATION"
%BCDEDIT% /enum all >>"%LOG%" 2>&1

rem -----------------------------------------------------------------
rem 5. Copy evidence and print a compact screen summary.
rem -----------------------------------------------------------------
if exist "H:\" (
  copy /y "%LOG%" "%USBLOG%\post-driver-0x7b-diagnostic-%COMMAND_VERSION%.log" >nul 2>&1
  if exist "%WORK%\driver-inventory.txt" copy /y "%WORK%\driver-inventory.txt" "%USBLOG%\driver-inventory-%COMMAND_VERSION%.txt" >nul 2>&1
  if exist "%WORK%\package-state.txt" copy /y "%WORK%\package-state.txt" "%USBLOG%\package-state-%COMMAND_VERSION%.txt" >nul 2>&1
  if exist "%WORK%\setupapi-storage.txt" copy /y "%WORK%\setupapi-storage.txt" "%USBLOG%\setupapi-storage-%COMMAND_VERSION%.txt" >nul 2>&1
)

echo.
echo ================================================================
echo DIAGNOSTIC COMPLETE - NO WINDOWS CHANGES WERE MADE
echo Version: %COMMAND_VERSION%
echo.
echo Key controller/service evidence:
%FINDSTR% /i "Resolved active control set Service REG_SZ Start REG_DWORD iaStorAC iaStorA storahci DEV_A102 PendingXmlIdentifier PendingFileRenameOperations" "%LOG%" 2>nul
echo.
echo Full log: %LOG%
if exist "H:\" echo USB copy: %USBLOG%\post-driver-0x7b-diagnostic-%COMMAND_VERSION%.log
echo ================================================================
exit /b 0

:SECTION
echo.>>"%LOG%"
echo ================================================================>>"%LOG%"
echo %~1>>"%LOG%"
echo ================================================================>>"%LOG%"
echo [%date% %time%] %~1
exit /b 0

:LOG
echo [%date% %time%] %~1
echo [%date% %time%] %~1>>"%LOG%"
exit /b 0
