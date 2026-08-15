@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=READ_ONLY
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Semantically verify the fresh UEFI BCD store created by command 39 without changing Windows, partitions, drivers, registry, or boot files.
rem WR_ACTION=VERIFY_FRESH_UEFI_BCD
rem WR_TARGET=Current Windows Boot Manager and default Windows loader configuration only.
rem WR_CONSEQUENCE=Read-only verification of BCD semantics and required loader file presence. No Windows recovery state is changed.
rem WR_ROLLBACK=No rollback is required because this command does not modify Windows recovery state.

set "R=C:\WinRERepair"
set "O=%R%\COMMAND_RESULT.env"
set "A=%R%\runtime\github-auth.cmd"
set "BCD=C:\Windows\System32\bcdedit.exe"
if not exist "%BCD%" set "BCD=bcdedit.exe"
set "BM=%R%\repair40-bootmgr.txt"
set "DF=%R%\repair40-default.txt"
set "Q=%R%\repair40-verify-bcd.txt"

set "BM_PATH=NO"
set "BM_DEVICE=NO"
set "BM_DEFAULT=NO"
set "DF_DEVICE=NO"
set "DF_OSDEVICE=NO"
set "DF_PATH=NO"
set "DF_SYSROOT=NO"
set "WINLOAD=NO"

"%BCD%" /enum {bootmgr} /v >"%BM%" 2>&1
set "BMRC=!errorlevel!"
"%BCD%" /enum {default} /v >"%DF%" 2>&1
set "DFRC=!errorlevel!"

if "!BMRC!"=="0" (
  for /f "usebackq tokens=1,*" %%A in ("%BM%") do (
    if /i "%%A"=="path" if /i "%%B"=="\EFI\Microsoft\Boot\bootmgfw.efi" set "BM_PATH=YES"
    if /i "%%A"=="device" set "BM_DEVICE=YES"
    if /i "%%A"=="default" set "BM_DEFAULT=YES"
  )
)

if "!DFRC!"=="0" (
  for /f "usebackq tokens=1,*" %%A in ("%DF%") do (
    if /i "%%A"=="device" if /i "%%B"=="partition=C:" set "DF_DEVICE=YES"
    if /i "%%A"=="osdevice" if /i "%%B"=="partition=C:" set "DF_OSDEVICE=YES"
    if /i "%%A"=="path" if /i "%%B"=="\Windows\system32\winload.efi" set "DF_PATH=YES"
    if /i "%%A"=="systemroot" if /i "%%B"=="\Windows" set "DF_SYSROOT=YES"
  )
)
if exist C:\Windows\System32\winload.efi set "WINLOAD=YES"

>"%Q%" echo RESCUEMEAI COMMAND 40 - SEMANTIC BCD VERIFICATION
>>"%Q%" echo bootmgr_return_code=!BMRC!
>>"%Q%" echo default_return_code=!DFRC!
>>"%Q%" echo bootmgr_path=!BM_PATH!
>>"%Q%" echo bootmgr_device_present=!BM_DEVICE!
>>"%Q%" echo bootmgr_default_present=!BM_DEFAULT!
>>"%Q%" echo default_device_c=!DF_DEVICE!
>>"%Q%" echo default_osdevice_c=!DF_OSDEVICE!
>>"%Q%" echo default_winload_path=!DF_PATH!
>>"%Q%" echo default_systemroot=!DF_SYSROOT!
>>"%Q%" echo winload_file_present=!WINLOAD!
>>"%Q%" echo.
>>"%Q%" echo [BOOTMGR]
type "%BM%" >>"%Q%"
>>"%Q%" echo.
>>"%Q%" echo [DEFAULT]
type "%DF%" >>"%Q%"

set "OK=YES"
for %%V in (BM_PATH BM_DEVICE BM_DEFAULT DF_DEVICE DF_OSDEVICE DF_PATH DF_SYSROOT WINLOAD) do if /i not "!%%V!"=="YES" set "OK=NO"
if not "!BMRC!"=="0" set "OK=NO"
if not "!DFRC!"=="0" set "OK=NO"

if /i "!OK!"=="YES" goto :PASS

>"%R%\LAST_RUN_REPORT.txt" echo status=WARNING
>>"%R%\LAST_RUN_REPORT.txt" echo message=Fresh BCD rebuild remains incomplete or inconsistent under semantic verification.
>"%R%\RUN_DETAILS.txt" echo repair=VERIFY_FRESH_UEFI_BCD_WARNING
type "%Q%" >>"%R%\RUN_DETAILS.txt"
if exist "%A%" call "%A%" upload >nul 2>&1
>"%O%" echo STATUS=WARNING
>>"%O%" echo MESSAGE=Fresh BCD verification found an inconsistency; RescueMeAI will not reboot.
>>"%O%" echo EVIDENCE=Detailed BCD semantic verification was uploaded privately.
>>"%O%" echo INSTRUCTION=No user relay is required. Leave RescueMeAI online for automatic review.
exit /b 0

:PASS
>"%R%\LAST_RUN_REPORT.txt" echo status=PASS
>>"%R%\LAST_RUN_REPORT.txt" echo message=Fresh UEFI BCD store is semantically valid for the current Windows installation.
>"%R%\RUN_DETAILS.txt" echo repair=VERIFY_FRESH_UEFI_BCD_PASS
type "%Q%" >>"%R%\RUN_DETAILS.txt"
if exist "%A%" call "%A%" upload >nul 2>&1
>"%O%" echo STATUS=PASS
>>"%O%" echo MESSAGE=Fresh UEFI BCD store is semantically valid; the previous command 39 warning was a verifier false negative.
>>"%O%" echo EVIDENCE=Boot Manager path, default loader path, C: device/osdevice, systemroot, and winload.efi were all verified.
>>"%O%" echo INSTRUCTION=No user action is required. RescueMeAI remains online for the controlled boot test.
exit /b 0
