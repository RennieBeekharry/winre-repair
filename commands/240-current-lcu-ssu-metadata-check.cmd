@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=READ_ONLY
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Confirm whether the current 26200.9168 LCU and 26100.9156 servicing-stack metadata are present before package servicing.
rem WR_ACTION=CHECK_CURRENT_LCU_SSU_METADATA
rem WR_TARGET=C:\Windows\servicing\Packages and C:\Windows\WinSxS metadata only.
rem WR_CONSEQUENCE=Read-only file inventory. No Windows or personal-file changes.
rem WR_ROLLBACK=Not applicable.

set "FIX_VERSION=RMAI-FIX-2026.09.10.2"
set "STEP=43"
set "WORK=C:\WinRERepair"
set "RESULT=%WORK%\COMMAND_RESULT.env"
set "DETAILS=%WORK%\RUN_DETAILS.txt"
if not exist "%WORK%" md "%WORK%" >nul 2>&1

cls
echo ================================================================================
echo RescueMeAI - CURRENT UPDATE METADATA CHECK
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : RUNNING
echo CURRENT TASK        : Confirming LCU 26200.9168 and SSU 26100.9156 metadata.
echo SAFETY              : READ-ONLY
echo WINDOWS CHANGES     : NONE
echo REBOOT              : NO
echo WHAT YOU SHOULD DO  : WAIT.
echo SCREENSHOT REQUIRED : NO
echo ================================================================================

if not exist "C:\Windows\servicing\Packages" goto :FAIL
echo [1/4] Checking package manifests for build 9168...
dir /b "C:\Windows\servicing\Packages\*9168*.mum" >"%WORK%\diag43-9168.txt" 2>nul
set "N9168=0"
if exist "%WORK%\diag43-9168.txt" for /f %%N in ('find /c /v "" ^< "%WORK%\diag43-9168.txt"') do set "N9168=%%N"

echo [2/4] Checking package manifests for servicing stack 9156...
dir /b "C:\Windows\servicing\Packages\*9156*.mum" >"%WORK%\diag43-9156.txt" 2>nul
set "N9156=0"
if exist "%WORK%\diag43-9156.txt" for /f %%N in ('find /c /v "" ^< "%WORK%\diag43-9156.txt"') do set "N9156=%%N"

echo [3/4] Checking servicing-stack WinSxS folders...
dir /b /ad "C:\Windows\WinSxS\*servicingstack*9156*" >"%WORK%\diag43-ssu-folders.txt" 2>nul
set "NSSU=0"
if exist "%WORK%\diag43-ssu-folders.txt" for /f %%N in ('find /c /v "" ^< "%WORK%\diag43-ssu-folders.txt"') do set "NSSU=%%N"

echo [4/4] Recording the result...
>"%DETAILS%" echo RESCUEMEAI CURRENT UPDATE METADATA CHECK
>>"%DETAILS%" echo fix_version=%FIX_VERSION%
>>"%DETAILS%" echo step=%STEP%
>>"%DETAILS%" echo build_9168_manifest_count=!N9168!
>>"%DETAILS%" echo ssu_9156_manifest_count=!N9156!
>>"%DETAILS%" echo servicingstack_9156_folder_count=!NSSU!
>>"%DETAILS%" echo windows_changes_performed=NO
>>"%DETAILS%" echo personal_files_targeted=NO
if exist "%WORK%\diag43-9168.txt" (
  >>"%DETAILS%" echo.
  >>"%DETAILS%" echo --- 9168 PACKAGE MANIFESTS ---
  type "%WORK%\diag43-9168.txt" >>"%DETAILS%"
)
if exist "%WORK%\diag43-9156.txt" (
  >>"%DETAILS%" echo.
  >>"%DETAILS%" echo --- 9156 PACKAGE MANIFESTS ---
  type "%WORK%\diag43-9156.txt" >>"%DETAILS%"
)
if exist "%WORK%\diag43-ssu-folders.txt" (
  >>"%DETAILS%" echo.
  >>"%DETAILS%" echo --- 9156 SERVICING STACK FOLDERS ---
  type "%WORK%\diag43-ssu-folders.txt" >>"%DETAILS%"
)

>"%RESULT%" echo STATUS=PASS
>>"%RESULT%" echo MESSAGE=Current LCU/SSU metadata check completed.
>>"%RESULT%" echo EVIDENCE=Build 9168 manifests=!N9168!; SSU 9156 manifests=!N9156!; servicing-stack 9156 folders=!NSSU!.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=NO
>>"%RESULT%" echo NEXT_STEP=RescueMeAI will choose package repair or a matching repair source based on these results.

echo STATUS              : COMPLETE - RESULT SENT FOR REVIEW
echo 9168 MANIFESTS      : !N9168!
echo 9156 SSU MANIFESTS  : !N9156!
echo 9156 SSU FOLDERS    : !NSSU!
echo WHAT YOU SHOULD DO  : WAIT.
echo SCREENSHOT REQUIRED : NO
exit /b 0

:FAIL
>"%RESULT%" echo STATUS=FAIL
>>"%RESULT%" echo MESSAGE=Windows servicing package folder could not be verified.
>>"%RESULT%" echo EVIDENCE=No Windows changes were made.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=YES
echo STATUS              : STOPPED
echo SCREENSHOT REQUIRED : YES
exit /b 90
