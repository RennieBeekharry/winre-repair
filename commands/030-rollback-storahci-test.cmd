@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=REPAIR_WRITE
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Roll back the failed Microsoft storahci boot test to the previously verified Intel iaStorA configuration before further diagnosis.
rem WR_ACTION=ROLLBACK_STORAHCI_TO_IASTORA
rem WR_TARGET=Offline Windows SYSTEM registry controller service binding and storahci StartOverride only.
rem WR_CONSEQUENCE=Restores the exact pre-test controller service binding to iaStorA and storahci StartOverride value 0 to 3. Keeps all driver packages installed.
rem WR_ROLLBACK=If this rollback itself cannot be verified, the saved SYSTEM hive backup C:\WinRERepair\SYSTEM.before-storahci-test.hiv remains available.

set "R=C:\WinRERepair"
set "O=%R%\COMMAND_RESULT.env"
set "A=%R%\runtime\github-auth.cmd"
set "Q=%R%\repair30-storahci-rollback.txt"
set "G=C:\Windows\System32\reg.exe"
set "SYS=C:\Windows\System32\config\SYSTEM"
set "BAK=%R%\SYSTEM.before-storahci-test.hiv"
set "SNAP=%R%\SYSTEM.after-failed-storahci-test.hiv"
if not exist "%G%" set "G=reg.exe"
if not exist "%SYS%" goto :BAD
if not exist "%BAK%" goto :BAD

>"%Q%" echo RESCUEMEAI STORAHCI TEST ROLLBACK
>>"%Q%" echo risk=REPAIR_WRITE
>>"%Q%" echo original_backup=%BAK%

copy /y "%SYS%" "%SNAP%" >>"%Q%" 2>&1
if errorlevel 1 goto :BAD

"%G%" unload HKLM\RMAIREPAIR30 >nul 2>&1
"%G%" load HKLM\RMAIREPAIR30 "%SYS%" >>"%Q%" 2>&1
if errorlevel 1 goto :BAD

set "DEV=HKLM\RMAIREPAIR30\ControlSet001\Enum\PCI\VEN_8086&DEV_A102&SUBSYS_2B45103C&REV_31\3&11583659&0&B8"

>>"%Q%" echo [BEFORE_ROLLBACK]
"%G%" query "!DEV!" /v Service >>"%Q%" 2>&1
"%G%" query HKLM\RMAIREPAIR30\ControlSet001\Services\iaStorA /v Start >>"%Q%" 2>&1
"%G%" query HKLM\RMAIREPAIR30\ControlSet001\Services\storahci /v Start >>"%Q%" 2>&1
"%G%" query HKLM\RMAIREPAIR30\ControlSet001\Services\storahci\StartOverride /v 0 >>"%Q%" 2>&1

"%G%" add "!DEV!" /v Service /t REG_SZ /d iaStorA /f >>"%Q%" 2>&1
if errorlevel 1 goto :BADLOADED
"%G%" add HKLM\RMAIREPAIR30\ControlSet001\Services\iaStorA /v Start /t REG_DWORD /d 0 /f >>"%Q%" 2>&1
if errorlevel 1 goto :BADLOADED
"%G%" add HKLM\RMAIREPAIR30\ControlSet001\Services\storahci /v Start /t REG_DWORD /d 0 /f >>"%Q%" 2>&1
if errorlevel 1 goto :BADLOADED
"%G%" add HKLM\RMAIREPAIR30\ControlSet001\Services\storahci\StartOverride /v 0 /t REG_DWORD /d 3 /f >>"%Q%" 2>&1
if errorlevel 1 goto :BADLOADED

>>"%Q%" echo [AFTER_ROLLBACK]
"%G%" query "!DEV!" /v Service >>"%Q%" 2>&1
"%G%" query HKLM\RMAIREPAIR30\ControlSet001\Services\iaStorA /v Start >>"%Q%" 2>&1
"%G%" query HKLM\RMAIREPAIR30\ControlSet001\Services\storahci\StartOverride /v 0 >>"%Q%" 2>&1

for /f "tokens=3" %%V in ('"%G%" query "!DEV!" /v Service ^| find /i "Service"') do set "SVC=%%V"
for /f "tokens=3" %%V in ('"%G%" query HKLM\RMAIREPAIR30\ControlSet001\Services\storahci\StartOverride /v 0 ^| find "0"') do set "OVR=%%V"
if /i not "!SVC!"=="iaStorA" goto :BADLOADED
if /i not "!OVR!"=="0x3" goto :BADLOADED

"%G%" unload HKLM\RMAIREPAIR30 >>"%Q%" 2>&1
if errorlevel 1 goto :BAD

>"%R%\LAST_RUN_REPORT.txt" echo status=PASS
>>"%R%\LAST_RUN_REPORT.txt" echo message=Failed storahci boot test rolled back to iaStorA.
>"%R%\RUN_DETAILS.txt" echo repair=ROLLBACK_STORAHCI_TO_IASTORA
>>"%R%\RUN_DETAILS.txt" echo original_backup=%BAK%
>>"%R%\RUN_DETAILS.txt" echo failed_test_snapshot=%SNAP%
type "%Q%" >>"%R%\RUN_DETAILS.txt"
if exist "%A%" call "%A%" upload >nul 2>&1

>"%O%" echo STATUS=PASS
>>"%O%" echo MESSAGE=The failed storahci boot test was rolled back. The Intel iaStorA binding is restored.
>>"%O%" echo EVIDENCE=Controller Service=iaStorA; storahci StartOverride 0=3; both SYSTEM hive snapshots remain available.
>>"%O%" echo INSTRUCTION=Reply pass. RescueMeAI remains online; next step is internal EFI/BCD inspection.
exit /b 0

:BADLOADED
"%G%" unload HKLM\RMAIREPAIR30 >>"%Q%" 2>&1
goto :BAD

:BAD
"%G%" unload HKLM\RMAIREPAIR30 >nul 2>&1
>"%O%" echo STATUS=FAIL
>>"%O%" echo MESSAGE=RescueMeAI could not verify the storahci rollback safely.
>>"%O%" echo EVIDENCE=Do not reboot again until the saved SYSTEM hive backup is reviewed.
>>"%O%" echo INSTRUCTION=Reply fail. RescueMeAI remains online.
exit /b 90
