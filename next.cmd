@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "COMMAND_VERSION=WR-2026.08.14-0946-ET"
set "BUILD_TIME=2026-08-14 09:46 ET"
set "WORK=C:\WinRERepair"
set "AUTHDIR=%WORK%\.auth"
set "TOKENFILE=%AUTHDIR%\github-logs.token"
set "REPORT=%WORK%\LAST_RUN_REPORT.txt"
set "DETAILS=%WORK%\RUN_DETAILS.txt"
set "HELPER=%WORK%\github-device-auth.js"
set "HELPERB64=%WORK%\github-device-auth.js.b64"
set "HELPER_SHA256=80654a6413898c8b3e0c311768e2ee1648141d141d64e11554b4a91f291ed67b"
set "CURL=C:\Windows\System32\curl.exe"
set "CERTUTIL=C:\Windows\System32\certutil.exe"
set "CSCRIPT=X:\Windows\System32\cscript.exe"
if not exist "%CSCRIPT%" set "CSCRIPT=C:\Windows\System32\cscript.exe"
set "NSLOOKUP=C:\Windows\System32\nslookup.exe"
set "FINDSTR=C:\Windows\System32\findstr.exe"
set "DNS=64.71.255.204"
set "APIHOST=api.github.com"
set "LOGREPO=RennieBeekharry/winre-repair-logs"
set "LAUNCHERURL=https://api.github.com/repos/RennieBeekharry/winre-repair/contents/wr.cmd?ref=main"
set "NEWLAUNCHER=C:\wr.new.cmd"
set "UPGRADE=X:\wr-private-upgrade.cmd"

cls
echo ================================================================
echo WINRE-REPAIR - GITHUB DEVICE AUTHORIZATION
echo Version: %COMMAND_VERSION%
echo Built:   %BUILD_TIME%
echo ================================================================
echo NO LONG TOKEN ENTRY IS USED IN THIS BUILD.
echo You will receive a short one-time GitHub code for your phone.
echo Disk/filesystem management operations: NONE
echo Windows repair operations: NONE
echo ================================================================

if not exist "%WORK%" md "%WORK%" >nul 2>&1
if not exist "%AUTHDIR%" md "%AUTHDIR%" >nul 2>&1
if not exist "%CURL%" goto :TOOLSFAIL
if not exist "%CERTUTIL%" goto :TOOLSFAIL
if not exist "%CSCRIPT%" goto :TOOLSFAIL
if not exist "%NSLOOKUP%" goto :TOOLSFAIL
if not exist "%FINDSTR%" goto :TOOLSFAIL

rem Reconstruct the audited device-auth helper locally. No helper download.
if exist "%HELPER%" del /f /q "%HELPER%" >nul 2>&1
if exist "%HELPERB64%" del /f /q "%HELPERB64%" >nul 2>&1
>"%HELPERB64%" echo Ly8gV2luUkUgR2l0SHViIGRldmljZSBhdXRob3JpemF0aW9uICsgcHJpdmF0ZSByZXBvcnRpbmcgYm9vdHN0cmFwLgooZnVuY3Rpb24gKCkgewogICAgdmFyIGEgPSBXU2NyaXB0LkFyZ3VtZW50czsKICAgIGlmIChhLmxlbmd0aCA8IDgpIFdTY3JpcHQuUXVpdCg5MSk7CgogICAgdmFyIGN1cmwgPSBhKDApLCBuc2xvb2t1cCA9IGEoMSksIGNlcnR1dGlsID0gYSgyKSwgZG5zID0gYSgzKTsKICAgIHZhciB3b3JrID0gYSg0KSwgbG9ncmVwbyA9IGEoNSksIHRva2VuZmlsZSA9IGEoNiksIHJlcG9ydCA9IGEoNyk7CiAgICB2YXIgZGV0YWlscyA9IGEubGVuZ3RoID4gOCA/IGEoOCkgOiAiIjsKCiAgICB2YXIgZnNvID0gbmV3IEFjdGl2ZVhPYmplY3QoIlNjcmlwdGluZy5GaWxlU3lzdGVtT2JqZWN0Iik7CiAgICB2YXIgc2hlbGwgPSBuZXcgQWN0aXZlWE9iamVjdCgiV1NjcmlwdC5TaGVsbCIpOwoKICAgIHZhciBjbGllbnRJZCA9ICIxNzhjNmZjNzc4Y2NjNjhlMWQ2YSI7CiAgICB2YXIgY2xpZW50U2VjcmV0ID0gIjM0ZGRlZmYyYjU1OGEyM2QzOGZiYThhNmRlNzRmMDg2ZWRlMWNjMGIiOwogICAgdmFyIHNjb3BlcyA9ICJyZXBvIHJlYWQ6b3JnIGdpc3QiOwoKICAgIGZ1bmN0aW9uIHEocy kgeyByZXR1cm4gJyInICsgU3RyaW5nKHMpLnJlcGxhY2UoLyIvZywgJ1xcIicpICsgJyInOyB9Cg==
