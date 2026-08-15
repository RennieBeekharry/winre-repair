@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=READ_ONLY
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Upload the already-collected focused 0x7B storage diagnostic without rerunning diagnostics or changing Windows.
rem WR_ACTION=UPLOAD_STORAGE_DIAGNOSTIC
rem WR_TARGET=Existing C:\WinRERepair\diag19-storage.txt and private RescueMeAI evidence repository only.
rem WR_CONSEQUENCE=Uploads existing diagnostic text. It does not read or modify additional Windows state.
rem WR_ROLLBACK=No Windows recovery state is changed.
set "R=C:\WinRERepair"
set "O=%R%\COMMAND_RESULT.env"
set "A=%R%\runtime\github-auth.cmd"
set "D=%R%\diag19-storage.txt"
if not exist "%D%" goto :BAD
>"%R%\LAST_RUN_REPORT.txt" echo status=PASS
>>"%R%\LAST_RUN_REPORT.txt" echo message=Focused 0x7B Intel storage evidence attachment.
>"%R%\RUN_DETAILS.txt" echo diagnostic=STORAGE_BOOT_0X7B
>>"%R%\RUN_DETAILS.txt" echo windows_changes=NONE
>>"%R%\RUN_DETAILS.txt" echo --- EVIDENCE ---
type "%D%" >>"%R%\RUN_DETAILS.txt"
call "%A%" upload >nul 2>&1
if errorlevel 1 goto :BAD
>"%O%" echo STATUS=PASS
>>"%O%" echo MESSAGE=The focused 0x7B storage evidence was uploaded for ChatGPT review.
>>"%O%" echo EVIDENCE=Existing diagnostic was resent; Windows was not changed.
>>"%O%" echo INSTRUCTION=Reply pass. RescueMeAI remains online.
exit /b 0
:BAD
>"%O%" echo STATUS=FAIL
>>"%O%" echo MESSAGE=RescueMeAI could not upload the existing focused storage diagnostic.
>>"%O%" echo EVIDENCE=No Windows changes were attempted.
>>"%O%" echo INSTRUCTION=Reply fail. RescueMeAI remains online.
exit /b 90
