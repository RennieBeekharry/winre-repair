@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=READ_ONLY
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Identify the exact cumulative update package and whether a safe offline rollback path exists.
rem WR_ACTION=CHECK_LCU_ROLLBACK_READINESS
rem WR_TARGET=Offline Windows installation on C: only.
rem WR_CONSEQUENCE=Reads Windows build, servicing package state, and rollback markers only; makes no Windows changes.
rem WR_ROLLBACK=Not applicable; read-only diagnostic only.

set "WORK=C:\WinRERepair"
set "DETAILS=%WORK%\RUN_DETAILS.txt"
set "RESULT=%WORK%\COMMAND_RESULT.env"
set "PKGS=%WORK%\packages-table.txt"
set "ROLL=%WORK%\rollup-lines.txt"
if not exist "%WORK%" md "%WORK%" >nul 2>&1

cls
echo ================================================================================
echo RescueMeAI - RECOVERY PROGRESS
echo ================================================================================
echo STATUS            : RUNNING
echo CURRENT DIAGNOSIS : Windows Startup Repair found a recently serviced boot
echo                     binary is corrupt. DISM RestoreHealth failed with 0x800f0915.
echo CURRENT TASK      : Identifying the exact cumulative update and safe rollback path.
echo SAFETY            : READ-ONLY - no Windows changes are being made.
echo SCREENSHOT NEEDED : NO - wait for the final status on this screen.
echo ================================================================================
echo.

>"%DETAILS%" echo RESCUEMEAI LCU ROLLBACK READINESS
>>"%DETAILS%" echo diagnosis=recently serviced boot binary corrupt
>>"%DETAILS%" echo image_build=26200.9168
>>"%DETAILS%" echo restorehealth_error=0x800f0915

echo [1/5] Confirming installed Windows build and edition...
>>"%DETAILS%" echo.
>>"%DETAILS%" echo --- OFFLINE WINDOWS VERSION ---
reg load HKLM\RMAISOFT C:\Windows\System32\Config\SOFTWARE >nul 2>&1
if !errorlevel! EQU 0 (
  reg query "HKLM\RMAISOFT\Microsoft\Windows NT\CurrentVersion" /v ProductName >>"%DETAILS%" 2>&1
  reg query "HKLM\RMAISOFT\Microsoft\Windows NT\CurrentVersion" /v DisplayVersion >>"%DETAILS%" 2>&1
  reg query "HKLM\RMAISOFT\Microsoft\Windows NT\CurrentVersion" /v CurrentBuild >>"%DETAILS%" 2>&1
  reg query "HKLM\RMAISOFT\Microsoft\Windows NT\CurrentVersion" /v UBR >>"%DETAILS%" 2>&1
  reg query "HKLM\RMAISOFT\Microsoft\Windows NT\CurrentVersion" /v EditionID >>"%DETAILS%" 2>&1
  reg unload HKLM\RMAISOFT >nul 2>&1
) else (
  >>"%DETAILS%" echo offline_software_hive_load=FAILED
)

echo [2/5] Reading cumulative-update package state...
dism /English /Image:C:\ /Get-Packages /Format:Table >"%PKGS%" 2>&1
set "DRC=!errorlevel!"
>>"%DETAILS%" echo dism_get_packages_exit_code=!DRC!
if not "!DRC!"=="0" (
  >"%RESULT%" echo STATUS=FAIL
  >>"%RESULT%" echo MESSAGE=Could not read offline servicing package state.
  >>"%RESULT%" echo EVIDENCE=DISM Get-Packages failed; no repair was attempted.
  >>"%RESULT%" echo SCREENSHOT_REQUIRED=YES
  echo.
  echo [FAIL] Could not read the Windows servicing package state.
  echo SCREENSHOT REQUIRED : YES
  echo Send ChatGPT a photo of THIS screen.
  exit /b 90
)

>"%ROLL%" findstr /i /c:"RollupFix" /c:"5121003" /c:"9168" "%PKGS%"
>>"%DETAILS%" echo.
>>"%DETAILS%" echo --- CUMULATIVE / BUILD-MATCHING PACKAGE ROWS ---
type "%ROLL%" >>"%DETAILS%" 2>&1

echo [3/5] Checking whether servicing is pending...
>>"%DETAILS%" echo.
>>"%DETAILS%" echo --- PENDING SERVICING MARKERS ---
if exist "C:\Windows\WinSxS\pending.xml" (
  >>"%DETAILS%" echo pending_xml=PRESENT
) else (
  >>"%DETAILS%" echo pending_xml=ABSENT
)
if exist "C:\Windows\WinSxS\Temp\PendingRenames" (
  >>"%DETAILS%" echo pending_renames_dir=PRESENT
) else (
  >>"%DETAILS%" echo pending_renames_dir=ABSENT
)

echo [4/5] Checking for locally cached repair/update material...
>>"%DETAILS%" echo.
>>"%DETAILS%" echo --- LOCAL UPDATE / REPAIR SOURCE SIGNALS ---
if exist "C:\Windows\SoftwareDistribution\Download" (
  >>"%DETAILS%" echo softwaredistribution_download=PRESENT
  dir /s /b "C:\Windows\SoftwareDistribution\Download\*5121003*" >>"%DETAILS%" 2>nul
  dir /s /b "C:\Windows\SoftwareDistribution\Download\*9168*" >>"%DETAILS%" 2>nul
) else (
  >>"%DETAILS%" echo softwaredistribution_download=ABSENT
)
if exist "C:\$WINDOWS.~BT\Sources\install.wim" >>"%DETAILS%" echo local_install_wim=PRESENT
if exist "C:\$WINDOWS.~BT\Sources\install.esd" >>"%DETAILS%" echo local_install_esd=PRESENT
if exist "C:\Recovery\WindowsRE\winre.wim" >>"%DETAILS%" echo local_winre_wim=PRESENT

echo [5/5] Building rollback-readiness summary...
set "MATCH=NO"
findstr /i /c:"RollupFix" /c:"5121003" /c:"9168" "%ROLL%" >nul 2>&1 && set "MATCH=YES"
>>"%DETAILS%" echo.
>>"%DETAILS%" echo --- SUMMARY ---
>>"%DETAILS%" echo matching_rollup_package_found=!MATCH!
>>"%DETAILS%" echo no_write_action_performed=YES

>"%RESULT%" echo STATUS=PASS
>>"%RESULT%" echo MESSAGE=Cumulative-update rollback readiness diagnostic completed.
>>"%RESULT%" echo EVIDENCE=Offline build, matching rollup package rows, pending state, and local repair-source signals attached.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=NO
>>"%RESULT%" echo NEXT_STEP=RescueMeAI will review whether targeted LCU rollback or a matching repair source is safer.

echo.
echo ================================================================================
echo STATUS            : COMPLETE
echo RESULT            : Read-only rollback-readiness diagnostic finished.
echo WINDOWS CHANGES   : NONE
echo NEXT STEP         : RescueMeAI is reviewing whether to roll back the latest
echo                     cumulative update or use a matching repair source.
echo SCREENSHOT NEEDED : NO
echo WHAT TO DO        : Leave this window open and keep the PC connected to power.
echo ================================================================================
exit /b 0
