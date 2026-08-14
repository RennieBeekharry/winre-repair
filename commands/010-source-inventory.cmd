@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=READ_ONLY
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Inventory the verified Windows recovery source and determine whether boot-media components are present.
rem WR_ACTION=INVENTORY_WINDOWS_RECOVERY_SOURCE
rem WR_TARGET=F:\RescueMeAI\Media\UUP\26100.8894-amd64-core-en-us and local RescueMeAI report files only.
rem WR_CONSEQUENCE=Reads recovery-source files and records an inventory result. Windows, boot configuration, disks, and partitions are not modified.
rem WR_ROLLBACK=None required; this command is read-only.

set "SRC=F:\RescueMeAI\Media\UUP\26100.8894-amd64-core-en-us"
set "OUT=C:\WinRERepair\COMMAND_RESULT.env"
set "INV=C:\WinRERepair\media-source-inventory.txt"
set "BOOTWIM=NO"
set "INSTALLWIM=NO"
set "INSTALLESD=NO"
set "SETUPEXE=NO"
set "BOOTMGR=NO"
set "BOOTX64=NO"
set "CABCOUNT=0"
set "ESDCOUNT=0"

if not exist "%SRC%\" goto :MISSING

> "%INV%" echo RescueMeAI recovery source inventory
>>"%INV%" echo source=%SRC%
>>"%INV%" echo.
for /r "%SRC%" %%F in (*) do (
  >>"%INV%" echo %%~fF
  if /i "%%~nxF"=="boot.wim" set "BOOTWIM=YES"
  if /i "%%~nxF"=="install.wim" set "INSTALLWIM=YES"
  if /i "%%~nxF"=="install.esd" set "INSTALLESD=YES"
  if /i "%%~nxF"=="setup.exe" set "SETUPEXE=YES"
  if /i "%%~nxF"=="bootmgr" set "BOOTMGR=YES"
  if /i "%%~nxF"=="bootx64.efi" set "BOOTX64=YES"
  if /i "%%~xF"==".cab" set /a CABCOUNT+=1
  if /i "%%~xF"==".esd" set /a ESDCOUNT+=1
)

> "%OUT%" echo STATUS=PASS
>>"%OUT%" echo MESSAGE=Verified recovery source inventory completed.
>>"%OUT%" echo EVIDENCE=boot.wim=!BOOTWIM!; install.wim=!INSTALLWIM!; install.esd=!INSTALLESD!; setup.exe=!SETUPEXE!; bootmgr=!BOOTMGR!; bootx64.efi=!BOOTX64!; CABs=!CABCOUNT!; ESDs=!ESDCOUNT!.
>>"%OUT%" echo INSTRUCTION=Reply pass. RescueMeAI remains online.
exit /b 0

:MISSING
> "%OUT%" echo STATUS=FAIL
>>"%OUT%" echo MESSAGE=The verified recovery source folder could not be found at its expected location.
>>"%OUT%" echo EVIDENCE=Expected source: %SRC%. No Windows state was changed.
>>"%OUT%" echo INSTRUCTION=Reply fail. RescueMeAI remains online.
exit /b 90
