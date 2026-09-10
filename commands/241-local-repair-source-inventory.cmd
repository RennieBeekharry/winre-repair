@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=READ_ONLY
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Look for a local Windows install WIM or ESD that could serve as a matching DISM repair source.
rem WR_ACTION=LOCAL_REPAIR_SOURCE_INVENTORY
rem WR_TARGET=Likely installation-media paths on local and removable drive roots only.
rem WR_CONSEQUENCE=Read-only source inventory. No Windows or personal-file changes.
rem WR_ROLLBACK=Not applicable.

set "FIX_VERSION=RMAI-FIX-2026.09.10.2"
set "STEP=44"
set "WORK=C:\WinRERepair"
set "RESULT=%WORK%\COMMAND_RESULT.env"
set "DETAILS=%WORK%\RUN_DETAILS.txt"
set "DISM=C:\Windows\System32\dism.exe"
if not exist "%DISM%" set "DISM=X:\Windows\System32\dism.exe"
if not exist "%WORK%" md "%WORK%" >nul 2>&1

cls
echo ================================================================================
echo RescueMeAI - LOCAL REPAIR SOURCE INVENTORY
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : RUNNING
echo CURRENT TASK        : Looking for a local install.wim or install.esd repair source.
echo SAFETY              : READ-ONLY
echo WINDOWS CHANGES     : NONE
echo REBOOT              : NO
echo WHAT YOU SHOULD DO  : WAIT.
echo SCREENSHOT REQUIRED : NO
echo ================================================================================

set "FOUND=0"
set "SOURCE="
>"%WORK%\diag44-sources.txt" echo LOCAL REPAIR SOURCE CANDIDATES
echo [1/3] Checking common installation-media paths...
for %%D in (C D E F G H I J K L M) do (
  if exist "%%D:\sources\install.wim" (
    set /a FOUND+=1
    >>"%WORK%\diag44-sources.txt" echo %%D:\sources\install.wim
    if not defined SOURCE set "SOURCE=%%D:\sources\install.wim"
  )
  if exist "%%D:\sources\install.esd" (
    set /a FOUND+=1
    >>"%WORK%\diag44-sources.txt" echo %%D:\sources\install.esd
    if not defined SOURCE set "SOURCE=%%D:\sources\install.esd"
  )
  if exist "%%D:\install.wim" (
    set /a FOUND+=1
    >>"%WORK%\diag44-sources.txt" echo %%D:\install.wim
    if not defined SOURCE set "SOURCE=%%D:\install.wim"
  )
  if exist "%%D:\install.esd" (
    set /a FOUND+=1
    >>"%WORK%\diag44-sources.txt" echo %%D:\install.esd
    if not defined SOURCE set "SOURCE=%%D:\install.esd"
  )
)

echo [2/3] Reading metadata for the first candidate, if present...
set "WIMINFO=NOT_RUN"
if defined SOURCE (
  "%DISM%" /Get-WimInfo /WimFile:"!SOURCE!" >"%WORK%\diag44-wiminfo.txt" 2>&1
  set "WIMRC=!errorlevel!"
  if "!WIMRC!"=="0" set "WIMINFO=PASS"
  if not "!WIMRC!"=="0" set "WIMINFO=FAIL_!WIMRC!"
)

echo [3/3] Recording the result...
>"%DETAILS%" echo RESCUEMEAI LOCAL REPAIR SOURCE INVENTORY
>>"%DETAILS%" echo fix_version=%FIX_VERSION%
>>"%DETAILS%" echo step=%STEP%
>>"%DETAILS%" echo candidate_count=!FOUND!
>>"%DETAILS%" echo first_candidate=!SOURCE!
>>"%DETAILS%" echo wiminfo_status=!WIMINFO!
>>"%DETAILS%" echo windows_changes_performed=NO
>>"%DETAILS%" echo personal_files_targeted=NO
>>"%DETAILS%" echo.
type "%WORK%\diag44-sources.txt" >>"%DETAILS%"
if exist "%WORK%\diag44-wiminfo.txt" (
  >>"%DETAILS%" echo.
  >>"%DETAILS%" echo --- FIRST CANDIDATE WIM INFO ---
  type "%WORK%\diag44-wiminfo.txt" >>"%DETAILS%"
)
>"%RESULT%" echo STATUS=PASS
>>"%RESULT%" echo MESSAGE=Local repair-source inventory completed.
>>"%RESULT%" echo EVIDENCE=Candidate WIM/ESD files=!FOUND!; first candidate=!SOURCE!; metadata query=!WIMINFO!.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=NO
>>"%RESULT%" echo NEXT_STEP=Use a matching local source if available; otherwise continue with the next bounded recovery strategy.

echo STATUS              : COMPLETE - RESULT SENT FOR REVIEW
echo SOURCE CANDIDATES   : !FOUND!
echo FIRST CANDIDATE     : !SOURCE!
echo WHAT YOU SHOULD DO  : WAIT.
echo SCREENSHOT REQUIRED : NO
exit /b 0
