@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "COMMAND_VERSION=WR-2026.08.14-0230-ET"
set "BUILD_TIME=2026-08-14 02:30 ET"
set "OS=C:"
set "WORK=C:\WinRERepair"
set "REG=X:\Windows\System32\reg.exe"
set "DISM=X:\Windows\System32\dism.exe"
set "FINDSTR=C:\Windows\System32\findstr.exe"
set "INFO=%WORK%\candidate-driver-info.txt"
set "INV=%WORK%\driver-inventory-compact.txt"
set "INF=%WORK%\intel167\iaAHCIC.inf"
set "DEVICEKEY=HKLM\WR_SYS\ControlSet001\Enum\PCI\VEN_8086&DEV_A102&SUBSYS_2B45103C&REV_31\3&11583659&0&B8"
set "READY=YES"

cls
echo ================================================================
echo WINRE-REPAIR - STORAGE BINDING PROBE
echo Version: %COMMAND_VERSION%
echo Built:   %BUILD_TIME%
echo Fetched: %date% %time%
echo Mode:    READ-ONLY - NO WINDOWS CHANGES
echo ================================================================

if not exist "%WORK%" md "%WORK%" >nul 2>&1
if not exist "%OS%\Windows\System32\Config\SYSTEM" goto :FAIL_OS

%REG% unload HKLM\WR_SYS >nul 2>&1
%REG% load HKLM\WR_SYS "%OS%\Windows\System32\Config\SYSTEM" >nul 2>&1
if errorlevel 1 goto :FAIL_HIVE

set "CURSERVICE=UNKNOWN"
set "CURDRIVER=UNKNOWN"
for /f "tokens=2,*" %%A in ('%REG% query "%DEVICEKEY%" /v Service 2^>nul ^| %FINDSTR% /i "Service"') do set "CURSERVICE=%%B"
for /f "tokens=2,*" %%A in ('%REG% query "%DEVICEKEY%" /v Driver 2^>nul ^| %FINDSTR% /i "Driver"') do set "CURDRIVER=%%B"

set "ACSTART=UNKNOWN"
set "ACIMAGE=UNKNOWN"
for /f "tokens=2,*" %%A in ('%REG% query HKLM\WR_SYS\ControlSet001\Services\iaStorAC /v Start 2^>nul ^| %FINDSTR% /i "Start"') do set "ACSTART=%%B"
for /f "tokens=2,*" %%A in ('%REG% query HKLM\WR_SYS\ControlSet001\Services\iaStorAC /v ImagePath 2^>nul ^| %FINDSTR% /i "ImagePath"') do set "ACIMAGE=%%B"
%REG% unload HKLM\WR_SYS >nul 2>&1

set "SYSFILE=NO"
if exist "%OS%\Windows\System32\drivers\iaStorAC.sys" set "SYSFILE=YES"

set "STALEPKG=MISSING"
if exist "%OS%\Windows\System32\DriverStore\FileRepository\iastorac.inf_amd64_11836ca5fd4acebc" set "STALEPKG=PRESENT"

set "META_HW=NO"
set "META_VER=NO"
set "META_AC=NO"
set "META_AMD64=NO"
if not exist "%INF%" (
  set "READY=NO"
  goto :INVENTORY
)

%DISM% /Image:%OS%\ /Get-DriverInfo /Driver:"%INF%" /English /Format:List >"%INFO%" 2>&1
if errorlevel 1 (
  set "READY=NO"
  goto :INVENTORY
)
%FINDSTR% /l /i /c:"PCI\VEN_8086&DEV_A102&CC_0106" "%INFO%" >nul 2>&1
if not errorlevel 1 set "META_HW=YES"
%FINDSTR% /l /i /c:"16.7.1.1012" "%INFO%" >nul 2>&1
if not errorlevel 1 set "META_VER=YES"
%FINDSTR% /l /i /c:"iaStorAC" "%INFO%" >nul 2>&1
if not errorlevel 1 set "META_AC=YES"
%FINDSTR% /l /i /c:"amd64" "%INFO%" >nul 2>&1
if not errorlevel 1 set "META_AMD64=YES"

:INVENTORY
%DISM% /Image:%OS%\ /Get-Drivers /All /English /Format:Table >"%INV%" 2>&1
set "INSTALLED167=NO"
%FINDSTR% /l /i /c:"16.7.1.1012" "%INV%" >nul 2>&1
if not errorlevel 1 set "INSTALLED167=YES"

if /i not "%META_HW%"=="YES" set "READY=NO"
if /i not "%META_VER%"=="YES" set "READY=NO"
if /i not "%META_AC%"=="YES" set "READY=NO"
if /i not "%META_AMD64%"=="YES" set "READY=NO"
if /i not "%INSTALLED167%"=="YES" set "READY=NO"
if /i not "%SYSFILE%"=="YES" set "READY=NO"

cls
echo ================================================================
echo STORAGE BINDING PROBE COMPLETE
echo Version: %COMMAND_VERSION%
echo ================================================================
echo Current controller service : %CURSERVICE%
echo Current controller driver  : %CURDRIVER%
echo iaStorAC Start              : %ACSTART%
echo iaStorAC.sys present        : %SYSFILE%
echo Intel 16.7.1.1012 installed : %INSTALLED167%
echo 16.7 metadata DEV_A102      : %META_HW%
echo 16.7 metadata iaStorAC      : %META_AC%
echo Old iaStorAC package folder : %STALEPKG%
echo ---------------------------------------------------------------
if /i "%READY%"=="YES" (
  echo DECISION: READY_FOR_REVERSIBLE_BINDING_TEST
) else (
  echo DECISION: NOT_READY_FOR_BINDING_TEST
)
echo ================================================================
echo No Windows changes were made.
exit /b 0

:FAIL_OS
echo PROBE FAILED: offline Windows SYSTEM hive was not found on C:.
exit /b 10
:FAIL_HIVE
echo PROBE FAILED: could not load offline SYSTEM hive.
exit /b 11
