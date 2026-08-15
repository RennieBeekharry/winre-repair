@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=READ_ONLY
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Inspect the exact active iaStorA driver package metadata, live driver hash, and offline BCD device mapping before a targeted 0x7B repair.
rem WR_ACTION=VERIFY_IASTORA_PACKAGE_AND_BCD
rem WR_TARGET=C:\Windows offline SYSTEM hive, iaStorA driver file, active HDC class key, offline BCD stores, and RescueMeAI private evidence only.
rem WR_CONSEQUENCE=Reads storage-driver and boot-configuration evidence only. It does not repair or modify Windows.
rem WR_ROLLBACK=No Windows state is changed; the temporary SYSTEM hive mount is unloaded.

set "R=C:\WinRERepair"
set "O=%R%\COMMAND_RESULT.env"
set "A=%R%\runtime\github-auth.cmd"
set "Q=%R%\diag24-iastora-bcd.txt"
set "G=C:\Windows\System32\reg.exe"
set "C=C:\Windows\System32\certutil.exe"
set "B=X:\Windows\System32\bcdedit.exe"
if not exist "%G%" set "G=reg.exe"
if not exist "%C%" set "C=certutil.exe"
if not exist "%B%" set "B=bcdedit.exe"
if not exist C:\Windows\System32\config\SYSTEM goto :BAD

>"%Q%" echo RESCUEMEAI IASTORA PACKAGE AND BCD CHECK
>>"%Q%" echo windows_changes=NONE

if exist C:\Windows\System32\drivers\iaStorA.sys (
  >>"%Q%" echo [LIVE_IASTORA_SHA256]
  "%C%" -hashfile C:\Windows\System32\drivers\iaStorA.sys SHA256 >>"%Q%" 2>&1
) else (
  >>"%Q%" echo LIVE_IASTORA_FILE=MISSING
)

"%G%" unload HKLM\RMAISYS24 >nul 2>&1
"%G%" load HKLM\RMAISYS24 C:\Windows\System32\config\SYSTEM >>"%Q%" 2>&1
if errorlevel 1 goto :BAD

>>"%Q%" echo [IASTORA_SERVICE]
"%G%" query HKLM\RMAISYS24\ControlSet001\Services\iaStorA /s >>"%Q%" 2>&1

>>"%Q%" echo [ACTIVE_CONTROLLER]
set "DEV=HKLM\RMAISYS24\ControlSet001\Enum\PCI\VEN_8086&DEV_A102&SUBSYS_2B45103C&REV_31\3&11583659&0&B8"
"%G%" query "!DEV!" /v Service >>"%Q%" 2>&1
"%G%" query "!DEV!" /v Driver >>"%Q%" 2>&1

>>"%Q%" echo [ACTIVE_HDC_CLASS_0000]
set "CLS=HKLM\RMAISYS24\ControlSet001\Control\Class\{4d36e96a-e325-11ce-bfc1-08002be10318}\0000"
for %%V in (DriverDesc ProviderName DriverVersion InfPath InfSection MatchingDeviceId) do "%G%" query "!CLS!" /v %%V >>"%Q%" 2>&1

"%G%" unload HKLM\RMAISYS24 >>"%Q%" 2>&1

>>"%Q%" echo [DRIVERSTORE_IASTORA_FILES]
for /f "delims=" %%F in ('dir /s /b C:\Windows\System32\DriverStore\FileRepository\iaStorA.sys 2^>nul') do (
  >>"%Q%" echo FILE=%%F
  "%C%" -hashfile "%%F" SHA256 >>"%Q%" 2>&1
)
for /f "delims=" %%F in ('dir /s /b C:\Windows\System32\DriverStore\FileRepository\*iastor*\iaStorA.sys 2^>nul') do (
  >>"%Q%" echo FILE=%%F
  "%C%" -hashfile "%%F" SHA256 >>"%Q%" 2>&1
)

>>"%Q%" echo [OFFLINE_BCD_DEFAULT]
set "FOUND=NO"
for %%D in (C D E F G H I J K L M N O P Q R S T U V W Y Z) do (
  if exist "%%D:\EFI\Microsoft\Boot\BCD" (
    set "FOUND=YES"
    >>"%Q%" echo STORE=%%D:\EFI\Microsoft\Boot\BCD
    "%B%" /store "%%D:\EFI\Microsoft\Boot\BCD" /enum {default} >>"%Q%" 2>&1
  )
  if exist "%%D:\Boot\BCD" (
    set "FOUND=YES"
    >>"%Q%" echo STORE=%%D:\Boot\BCD
    "%B%" /store "%%D:\Boot\BCD" /enum {default} >>"%Q%" 2>&1
  )
)
if /i "!FOUND!"=="NO" >>"%Q%" echo BCD_STORE=NOT_FOUND

>"%R%\LAST_RUN_REPORT.txt" echo status=PASS
>>"%R%\LAST_RUN_REPORT.txt" echo message=iaStorA package and BCD evidence.
>"%R%\RUN_DETAILS.txt" echo diagnostic=IASTORA_PACKAGE_AND_BCD
type "%Q%" >>"%R%\RUN_DETAILS.txt"
call "%A%" upload >nul 2>&1
if errorlevel 1 goto :BAD

>"%O%" echo STATUS=PASS
>>"%O%" echo MESSAGE=iaStorA package and BCD validation completed without changing Windows.
>>"%O%" echo EVIDENCE=Private active-driver package and boot-device evidence uploaded.
>>"%O%" echo INSTRUCTION=Reply pass. RescueMeAI remains online.
exit /b 0

:BAD
"%G%" unload HKLM\RMAISYS24 >nul 2>&1
>"%O%" echo STATUS=FAIL
>>"%O%" echo MESSAGE=iaStorA package and BCD validation could not complete.
>>"%O%" echo EVIDENCE=No Windows changes were attempted.
>>"%O%" echo INSTRUCTION=Reply fail. RescueMeAI remains online.
exit /b 90
