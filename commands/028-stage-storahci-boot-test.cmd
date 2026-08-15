@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=REPAIR_WRITE
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Stage a reversible Microsoft storahci boot test for the Intel DEV_A102 SATA AHCI controller after Intel driver paths remained unable to boot Windows.
rem WR_ACTION=STAGE_STORAHCI_BOOT_TEST
rem WR_TARGET=Offline Windows SYSTEM registry controller service binding and storahci boot-start override only.
rem WR_CONSEQUENCE=Backs up the SYSTEM hive, keeps iaStorA installed and boot-start, binds the exact SATA AHCI controller to storahci, and enables storahci at boot for one controlled boot test.
rem WR_ROLLBACK=Restore controller Service to iaStorA and storahci StartOverride value 0 to 3, or restore the saved SYSTEM hive backup.

set "R=C:\WinRERepair"
set "O=%R%\COMMAND_RESULT.env"
set "A=%R%\runtime\github-auth.cmd"
set "Q=%R%\repair28-storahci.txt"
set "G=C:\Windows\System32\reg.exe"
set "SYS=C:\Windows\System32\config\SYSTEM"
set "BAK=%R%\SYSTEM.before-storahci-test.hiv"
if not exist "%G%" set "G=reg.exe"
if not exist "%SYS%" goto :BAD
if not exist C:\Windows\System32\drivers\storahci.sys goto :BAD

>"%Q%" echo RESCUEMEAI STORAHCI BOOT TEST STAGING
>>"%Q%" echo risk=REPAIR_WRITE
>>"%Q%" echo rollback_available=YES

copy /y "%SYS%" "%BAK%" >>"%Q%" 2>&1
if errorlevel 1 goto :BAD

"%G%" unload HKLM\RMAIREPAIR28 >nul 2>&1
"%G%" load HKLM\RMAIREPAIR28 "%SYS%" >>"%Q%" 2>&1
if errorlevel 1 goto :BAD

set "DEV=HKLM\RMAIREPAIR28\ControlSet001\Enum\PCI\VEN_8086&DEV_A102&SUBSYS_2B45103C&REV_31\3&11583659&0&B8"
>>"%Q%" echo [BEFORE]
"%G%" query "!DEV!" /v Service >>"%Q%" 2>&1
"%G%" query HKLM\RMAIREPAIR28\ControlSet001\Services\storahci /v Start >>"%Q%" 2>&1
"%G%" query HKLM\RMAIREPAIR28\ControlSet001\Services\storahci\StartOverride /v 0 >>"%Q%" 2>&1

"%G%" add "!DEV!" /v Service /t REG_SZ /d storahci /f >>"%Q%" 2>&1
if errorlevel 1 goto :ROLLBACK
"%G%" add HKLM\RMAIREPAIR28\ControlSet001\Services\storahci /v Start /t REG_DWORD /d 0 /f >>"%Q%" 2>&1
if errorlevel 1 goto :ROLLBACK
"%G%" add HKLM\RMAIREPAIR28\ControlSet001\Services\storahci\StartOverride /v 0 /t REG_DWORD /d 0 /f >>"%Q%" 2>&1
if errorlevel 1 goto :ROLLBACK

>>"%Q%" echo [AFTER]
"%G%" query "!DEV!" /v Service >>"%Q%" 2>&1
"%G%" query HKLM\RMAIREPAIR28\ControlSet001\Services\iaStorA /v Start >>"%Q%" 2>&1
"%G%" query HKLM\RMAIREPAIR28\ControlSet001\Services\storahci /v Start >>"%Q%" 2>&1
"%G%" query HKLM\RMAIREPAIR28\ControlSet001\Services\storahci\StartOverride /v 0 >>"%Q%" 2>&1

"%G%" unload HKLM\RMAIREPAIR28 >>"%Q%" 2>&1
if errorlevel 1 goto :BAD

>"%R%\LAST_RUN_REPORT.txt" echo status=PASS
>>"%R%\LAST_RUN_REPORT.txt" echo message=Reversible storahci boot test staged.
>"%R%\RUN_DETAILS.txt" echo repair=STORAHCI_BOOT_TEST
>>"%R%\RUN_DETAILS.txt" echo backup=%BAK%
type "%Q%" >>"%R%\RUN_DETAILS.txt"
call "%A%" upload >nul 2>&1

>"%O%" echo STATUS=PASS
>>"%O%" echo MESSAGE=Microsoft storahci boot test was staged successfully and the Intel iaStorA driver was left installed as rollback.
>>"%O%" echo EVIDENCE=SYSTEM hive backup saved at C:\WinRERepair\SYSTEM.before-storahci-test.hiv; controller now targets storahci with boot override enabled.
>>"%O%" echo INSTRUCTION=Reply pass. RescueMeAI remains online; the next step is the controlled reboot test.
exit /b 0

:ROLLBACK
>>"%Q%" echo [ROLLBACK_DURING_STAGING]
"%G%" add "!DEV!" /v Service /t REG_SZ /d iaStorA /f >>"%Q%" 2>&1
"%G%" add HKLM\RMAIREPAIR28\ControlSet001\Services\storahci /v Start /t REG_DWORD /d 0 /f >>"%Q%" 2>&1
"%G%" add HKLM\RMAIREPAIR28\ControlSet001\Services\storahci\StartOverride /v 0 /t REG_DWORD /d 3 /f >>"%Q%" 2>&1
"%G%" unload HKLM\RMAIREPAIR28 >>"%Q%" 2>&1
goto :BAD

:BAD
"%G%" unload HKLM\RMAIREPAIR28 >nul 2>&1
>"%O%" echo STATUS=FAIL
>>"%O%" echo MESSAGE=The storahci boot test could not be staged safely.
>>"%O%" echo EVIDENCE=RescueMeAI did not proceed to reboot; review the private staging report.
>>"%O%" echo INSTRUCTION=Reply fail. RescueMeAI remains online.
exit /b 90
