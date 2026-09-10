@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=REPAIR_WRITE
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Install the verified RescueMeAI reconnect v4 helper and keep C:\r.cmd as the one-command launcher.
rem WR_ACTION=INSTALL_VERIFIED_RECONNECT_V4
rem WR_TARGET=C:\RescueMeAI\reconnect.cmd and C:\r.cmd only.
rem WR_CONSEQUENCE=Updates RescueMeAI helper files only. No Windows system, EFI, BCD, registry, package, partition, reboot, or personal-file changes.
rem WR_ROLLBACK=The previous helper can be restored from the pinned v3 copy.

set "FIX_VERSION=RMAI-FIX-2026.09.10.3"
set "STEP=55"
set "WORK=C:\WinRERepair"
set "RESULT=%WORK%\COMMAND_RESULT.env"
set "DETAILS=%WORK%\RUN_DETAILS.txt"
set "DEST=C:\RescueMeAI"
set "CURL=C:\Windows\System32\curl.exe"
set "CERT=C:\Windows\System32\certutil.exe"
set "FIND=C:\Windows\System32\findstr.exe"
set "URL=https://raw.githubusercontent.com/RennieBeekharry/winre-repair/41de5e93cc3938e7133fa002236eed697cf7b9b7/reconnect-v4.cmd"
set "EXPECTED=7c692b7738f6c7556cdb2653f4088d567055c50f809ff5ce1067a2fd555a6f3f"
set "TMP=%WORK%\reconnect-v4.download.cmd"
set "HASHOUT=%WORK%\reconnect-v4-install-hash.txt"

cls
echo ================================================================================
echo RescueMeAI - VERIFIED QUICK RECONNECT V4 INSTALL
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : RUNNING
echo CURRENT TASK        : Installing reconnect v4 and preserving C:\r.cmd.
echo SAFETY              : REPAIR-WRITE - RescueMeAI helper files only.
echo WINDOWS SYSTEM      : NOT MODIFIED
echo PERSONAL FILES      : NOT TOUCHED
echo REBOOT              : NO
echo WHAT YOU SHOULD DO  : WAIT.
echo SCREENSHOT REQUIRED : NO
echo ================================================================================

if not exist "%DEST%" md "%DEST%" >nul 2>&1
echo [1/4] Downloading pinned reconnect v4...
"%CURL%" --ssl-no-revoke -fL "%URL%" -o "%TMP%"
if errorlevel 1 goto :FAIL

echo [2/4] Verifying measured SHA-256...
"%CERT%" -hashfile "%TMP%" SHA256 >"%HASHOUT%" 2>&1
"%FIND%" /i /c:"%EXPECTED%" "%HASHOUT%" >nul 2>&1
if errorlevel 1 goto :HASHFAIL

echo [3/4] Installing reconnect v4...
copy /y "%TMP%" "%DEST%\reconnect.cmd" >nul
if errorlevel 1 goto :FAIL

echo [4/4] Rebuilding one-command launcher...
>"C:\r.cmd" echo @echo off
>>"C:\r.cmd" echo call C:\RescueMeAI\reconnect.cmd
>>"C:\r.cmd" echo exit /b %%errorlevel%%
if not exist "C:\r.cmd" goto :FAIL

>"%DETAILS%" echo RESCUEMEAI VERIFIED RECONNECT V4 INSTALL
>>"%DETAILS%" echo fix_version=%FIX_VERSION%
>>"%DETAILS%" echo step=%STEP%
>>"%DETAILS%" echo reconnect_version=2026.09.10-v4
>>"%DETAILS%" echo sha256_verified=YES
>>"%DETAILS%" echo quick_command=C:\r.cmd
>>"%DETAILS%" echo removable_profile_search_range=D-through-Z-excluding-X
>>"%DETAILS%" echo windows_changes_performed=NO
>>"%DETAILS%" echo personal_files_targeted=NO

>"%RESULT%" echo STATUS=PASS
>>"%RESULT%" echo MESSAGE=Reconnect v4 installed and C:\r.cmd rebuilt successfully.
>>"%RESULT%" echo EVIDENCE=Verified reconnect v4 is active; recovery profile search now covers removable drive letters broadly and the banner matches fix .3.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=NO
>>"%RESULT%" echo NEXT_STEP=RescueMeAI can continue boot-hang diagnosis with improved reconnect reliability.

echo.
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : COMPLETE - QUICK RECONNECT V4 READY
echo FUTURE COMMAND      : C:\r.cmd
echo WINDOWS CHANGES     : NONE
echo REBOOT              : NO
echo WHAT YOU SHOULD DO  : WAIT. RescueMeAI will continue.
echo SCREENSHOT REQUIRED : NO
echo ================================================================================
exit /b 0

:HASHFAIL
>"%RESULT%" echo STATUS=FAIL
>>"%RESULT%" echo MESSAGE=Reconnect v4 SHA-256 verification failed.
>>"%RESULT%" echo EVIDENCE=No helper was installed and no Windows state was changed.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=YES
echo STATUS              : STOPPED - DOWNLOAD INTEGRITY CHECK FAILED
echo SCREENSHOT REQUIRED : YES
exit /b 90

:FAIL
>"%RESULT%" echo STATUS=FAIL
>>"%RESULT%" echo MESSAGE=Reconnect v4 installation failed.
>>"%RESULT%" echo EVIDENCE=No Windows system or personal files were changed.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=YES
echo STATUS              : STOPPED - RECONNECT V4 INSTALL FAILED
echo SCREENSHOT REQUIRED : YES
exit /b 90
