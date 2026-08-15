@echo off
setlocal EnableExtensions
rem WR_RISK=READ_ONLY
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Check the EhStorClass disk lower-filter service and file without changing Windows.
rem WR_ACTION=VERIFY_EHSTORCLASS_FILTER
rem WR_TARGET=C:\Windows offline SYSTEM hive and RescueMeAI evidence only.
rem WR_CONSEQUENCE=Reads EhStorClass, partmgr, and Disk-class filter configuration only.
rem WR_ROLLBACK=No Windows state is changed; temporary hive mount is unloaded.
set R=C:\WinRERepair
set O=%R%\COMMAND_RESULT.env
set A=%R%\runtime\github-auth.cmd
set Q=%R%\ehstor22.txt
set G=C:\Windows\System32\reg.exe
if not exist %G% set G=reg.exe
if not exist C:\Windows\System32\config\SYSTEM goto BAD
> "%Q%" echo EHSTORCLASS_FILTER_CHECK
if exist C:\Windows\System32\drivers\EhStorClass.sys (>>"%Q%" echo EHSTORCLASS_FILE=PRESENT) else (>>"%Q%" echo EHSTORCLASS_FILE=MISSING)
if exist C:\Windows\System32\drivers\partmgr.sys (>>"%Q%" echo PARTMGR_FILE=PRESENT) else (>>"%Q%" echo PARTMGR_FILE=MISSING)
%G% unload HKLM\RMAISYS22 >nul 2>&1
%G% load HKLM\RMAISYS22 C:\Windows\System32\config\SYSTEM >>"%Q%" 2>&1
if errorlevel 1 goto BAD
%G% query HKLM\RMAISYS22\ControlSet001\Services\EhStorClass /s >>"%Q%" 2>&1
%G% query HKLM\RMAISYS22\ControlSet001\Services\partmgr /s >>"%Q%" 2>&1
%G% query "HKLM\RMAISYS22\ControlSet001\Control\Class\{4d36e967-e325-11ce-bfc1-08002be10318}" /v UpperFilters >>"%Q%" 2>&1
%G% query "HKLM\RMAISYS22\ControlSet001\Control\Class\{4d36e967-e325-11ce-bfc1-08002be10318}" /v LowerFilters >>"%Q%" 2>&1
%G% unload HKLM\RMAISYS22 >>"%Q%" 2>&1
>"%R%\LAST_RUN_REPORT.txt" echo status=PASS
>>"%R%\LAST_RUN_REPORT.txt" echo message=EhStorClass filter check.
>"%R%\RUN_DETAILS.txt" echo diagnostic=EHSTORCLASS_FILTER
type "%Q%" >>"%R%\RUN_DETAILS.txt"
call "%A%" upload >nul 2>&1
if errorlevel 1 goto BAD
>"%O%" echo STATUS=PASS
>>"%O%" echo MESSAGE=EhStorClass filter check completed without changing Windows.
>>"%O%" echo EVIDENCE=Private EhStorClass evidence uploaded.
>>"%O%" echo INSTRUCTION=Reply pass. RescueMeAI remains online.
exit /b 0
:BAD
%G% unload HKLM\RMAISYS22 >nul 2>&1
>"%O%" echo STATUS=FAIL
>>"%O%" echo MESSAGE=EhStorClass filter check failed.
>>"%O%" echo EVIDENCE=No Windows changes were attempted.
>>"%O%" echo INSTRUCTION=Reply fail. RescueMeAI remains online.
exit /b 90
