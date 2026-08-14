@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "COMMAND_VERSION=WR-2026.08.14-0918-ET"
set "BUILD_TIME=2026-08-14 09:18 ET"
set "WORK=C:\WinRERepair"
set "CURL=C:\Windows\System32\curl.exe"
set "NSLOOKUP=C:\Windows\System32\nslookup.exe"
set "FINDSTR=C:\Windows\System32\findstr.exe"
set "DISM=X:\Windows\System32\dism.exe"
if not exist "%DISM%" set "DISM=C:\Windows\System32\dism.exe"
set "WPEUTIL=X:\Windows\System32\wpeutil.exe"
set "PING=X:\Windows\System32\ping.exe"
set "CERTUTIL=C:\Windows\System32\certutil.exe"
set "CSCRIPT=X:\Windows\System32\cscript.exe"
if not exist "%CSCRIPT%" set "CSCRIPT=C:\Windows\System32\cscript.exe"
set "DNS=64.71.255.204"

set "UUPAPIHOST=api.uupdump.net"
set "UUPID=44ac3fa1-0cef-463b-a650-6240d396f894"
set "UUPBUILD=26100.8894"
set "UUPAPIURL=https://api.uupdump.net/get.php?id=%UUPID%&lang=en-us&edition=core"
set "RAWHOST=raw.githubusercontent.com"
set "RAWMANIFESTURL=https://raw.githubusercontent.com/RennieBeekharry/winre-repair/main/RECOVERY_MANIFEST.md?cb=%RANDOM%%RANDOM%"
set "HELPER_SHA256=21464db3c0cbd6d47b10925ae9da8dcd7910307ce6eeff95d31440d284690173"

set "BOOTVOL="
set "DATAVOL="
set "BOOTCOUNT=0"
set "DATACOUNT=0"
set "OFFEDITION=UNKNOWN"
set "OFFLANG=UNKNOWN"
set "APIIP="

cls
echo ================================================================
echo WINRE-REPAIR - WINDOWS 11 24H2 SOURCE DOWNLOAD
echo Version: %COMMAND_VERSION%
echo Built:   %BUILD_TIME%
echo Fetched: %date% %time%
echo ================================================================
echo SAFETY MODE: SOURCE DOWNLOAD / HASH VERIFICATION ONLY.
echo Existing WIN11MEDIA and REPAIRDATA volumes are treated as fixed.
echo Embedded downloader: YES - no second helper download is required.
echo Disk/filesystem management operations in this build: NONE
echo ================================================================

if not exist "%WORK%" md "%WORK%" >nul 2>&1
if not exist "%CURL%" goto :TOOLSFAIL
if not exist "%NSLOOKUP%" goto :TOOLSFAIL
if not exist "%FINDSTR%" goto :TOOLSFAIL
if not exist "%CERTUTIL%" goto :TOOLSFAIL
if not exist "%CSCRIPT%" goto :TOOLSFAIL

for %%D in (D E F G H I J K L M N O P Q R S T U V W Y Z) do (
  if exist %%D:\ (
    vol %%D: >"%WORK%\vol-%%D.txt" 2>&1
    "%FINDSTR%" /i /c:"WIN11MEDIA" "%WORK%\vol-%%D.txt" >nul 2>&1
    if not errorlevel 1 (
      set /a BOOTCOUNT+=1
      set "BOOTVOL=%%D:"
    )
    "%FINDSTR%" /i /c:"REPAIRDATA" "%WORK%\vol-%%D.txt" >nul 2>&1
    if not errorlevel 1 (
      set /a DATACOUNT+=1
      set "DATAVOL=%%D:"
    )
  )
)

if not "!BOOTCOUNT!"=="1" goto :MEDIAFAIL
if not "!DATACOUNT!"=="1" goto :MEDIAFAIL
if /i "!BOOTVOL!"=="!DATAVOL!" goto :MEDIAFAIL
if /i "!BOOTVOL!"=="C:" goto :MEDIAFAIL
if /i "!DATAVOL!"=="C:" goto :MEDIAFAIL

set "DEST=!DATAVOL!\RecoverySource\Win11-24H2-26100.8894-Core-en-us"
set "UUPDIR=!DEST!\UUPs"
set "JSON=!DEST!\uup-api-response.json"
set "STATE=!DEST!\DOWNLOAD_STATE.txt"
set "HELPER=!DEST!\uup-download.js"
set "HELPERB64=!DEST!\uup-download.js.b64"
set "LOCALMANIFEST=!DATAVOL!\RecoverySource\RECOVERY_MANIFEST.md"
set "EDITIONLOG=!DEST!\offline-edition.txt"
set "LANGLOG=!DEST!\offline-language.txt"
if not exist "!DEST!" md "!DEST!" >nul 2>&1
if not exist "!UUPDIR!" md "!UUPDIR!" >nul 2>&1

call :FETCHRAW "%RAWMANIFESTURL%" "!LOCALMANIFEST!"
if errorlevel 1 call :WRITELOCALMANIFEST

if exist "%DISM%" if exist "C:\Windows\System32\Config\SYSTEM" (
  "%DISM%" /Image:C:\ /Get-CurrentEdition /English >"!EDITIONLOG!" 2>&1
  "%DISM%" /Image:C:\ /Get-Intl /English >"!LANGLOG!" 2>&1
  "%FINDSTR%" /i /c:"Current Edition : Core" "!EDITIONLOG!" >nul 2>&1
  if not errorlevel 1 set "OFFEDITION=CORE"
  "%FINDSTR%" /i /c:"Default system UI language : en-US" "!LANGLOG!" >nul 2>&1
  if not errorlevel 1 set "OFFLANG=EN-US"
)
if /i not "!OFFEDITION!"=="CORE" goto :WINDOWSFAIL
if /i not "!OFFLANG!"=="EN-US" goto :WINDOWSFAIL

call :CHECKNET
if errorlevel 1 (
  "%WPEUTIL%" InitializeNetwork >nul 2>&1
  "%PING%" -n 3 127.0.0.1 >nul 2>&1
  call :CHECKNET
)
if errorlevel 1 goto :NETFAIL

if exist "!HELPER!" del /f /q "!HELPER!" >nul 2>&1
if exist "!HELPERB64!" del /f /q "!HELPERB64!" >nul 2>&1
>"!HELPERB64!" echo Ly8gRW1iZWRkZWQgV2luUkUtc2FmZSBVVVAgSlNPTiBkb3dubG9hZGVyL3ZlcmlmaWVyLgooZnVuY3Rpb24gKCkgewogICAgdmFyIGEgPSBXU2NyaXB0LkFyZ3VtZW50czsKICAgIGlmIChhLmxlbmd0aCA8IDgpIFdTY3JpcHQuUXVpdCgyMCk7CiAgICB2YXIganNvblBhdGg9YSgwKSwgZGVzdERpcj1hKDEpLCBleHBlY3RlZEJ1aWxkPWEoMiksIGN1cmw9YSgzKSwKICAgICAgICBjZXJ0dXRpbD1hKDQpLCBuc2xvb2t1cD1hKDUpLCBkbnM9YSg2KSwgc3RhdGVQYXRoPWEoNyk7CiAgICB2YXIgZnNvPW5ldyBBY3RpdmVYT2JqZWN0KCJTY3JpcHRpbmcuRmlsZVN5c3RlbU9iamVjdCIpOwogICAgdmFyIHNoZWxsPW5ldyBBY3RpdmVYT2JqZWN0KCJXU2NyaXB0LlNoZWxsIik7CgogICAgZnVuY3Rpb24gcShzKXsgcmV0dXJuICciJyArIFN0cmluZyhzKS5yZXBsYWNlKC8iL2csJ1xcIicpICsgJyInOyB9CiAgICBmdW5jdGlvbiByZWFkQWxsKHApeyB2YXIgdD1mc28uT3BlblRleHRGaWxlKHAsMSxmYWxzZSksIHM9dC5SZWFkQWxsKCk7IHQuQ2xvc2UoKTsgcmV0dXJuIHM7IH0KICAgIGZ1bmN0aW9uIHN0YXRlKHN0YXR1cyxkb25lLHRvdGFsLGN1cnJlbnQsbWVzc2FnZSl7CiAgICAgICAgdHJ5ewogICAgICAgICAgICB2YXIgdD1mc28uQ3JlYXRlVGV4dEZpbGUoc3RhdGVQYXRoLHRydWUsZmFsc2UpOwogICAgICAgICAgICB0LldyaXRlTGluZSgic3RhdHVzPSIrc3RhdHVzKTsKICAgICAgICAgICAgdC5Xcml0ZUxpbmUoImRvbmU9Iitkb25lKTsKICAgICAgICAgICAgdC5Xcml0ZUxpbmUoInRvdGFsPSIrdG90YWwpOwogICAgICAgICAgICB0LldyaXRlTGluZSgiY3VycmVudD0iK2N1cnJlbnQpOwogICAgICAgICAgICB0LldyaXRlTGluZSgibWVzc2FnZT0iK21lc3NhZ2UpOwogICAgICAgICAgICB0LkNsb3NlKCk7CiAgICAgICAgfWNhdGNoKGUpe30KICAgIH0KICAgIGZ1bmN0aW9uIGV4ZWMoY21kKXsKICAgICAgICB2YXIgcD1zaGVsbC5FeGVjKGNtZCk7CiAgICAgICAgd2hpbGUocC5TdGF0dXM9PT0wKSBXU2NyaXB0LlNsZWVwKDEwMCk7CiAgICAgICAgdmFyIG91dD0iIjsKICAgICAgICB0cnl7b3V0Kz1wLlN0ZE91dC5SZWFkQWxsKCk7fWNhdGNoKGUxKXt9CiAgICAgICAgdHJ5e291dCs9cC5TdGRFcnIuUmVhZEFsbCgpO31jYXRjaChlMil7fQogICAgICAgIHJldHVybiB7Y29kZTpwLkV4aXRDb2RlLG91dDpvdXR9OwogICAgfQogICAgZnVuY3Rpb24gc2hhMShwKXsKICAgICAgICB2YXIgcj1leGVjKHEoY2VydHV0aWwpKyIgLWhhc2hmaWxlICIrcShwKSsiIFNIQTEiKTsKICAgICAgICBpZihyLmNvZGUhPT0wKSByZXR1cm4gIiI7CiAgICAgICAgdmFyIG09ci5vdXQubWF0Y2goL1xiWzAtOWEtZkEtRl17NDB9XGIvKTsKICAgICAgICByZXR1cm4gbT9tWzBdLnRvTG93ZXJDYXNlKCk6IiI7CiAgICB9CiAgICBmdW5jdGlvbiBob3N0RnJvbVVybCh1KXsgdmFyIG09L15odHRwcz86XC9cLyhbXlwvOl0rKS9pLmV4ZWModSk7IHJldHVybiBtP21bMV06IiI7IH0KICAgIGZ1bmN0aW9uIHJlc29sdmVIb3N0KGgpewogICAgICAgIHZhciByPWV4ZWMocShuc2xvb2t1cCkrIiAiK2grIiAiK2Rucyk7CiAgICAgICAgaWYoci5jb2RlIT09MCkgcmV0dXJuICIiOwogICAgICAgIHZhciBtPXIub3V0Lm1hdGNoKC9cYig/OlxkezEsM31cLil7M31cZHsxLDN9XGIvZyk7CiAgICAgICAgaWYoIW0pIHJldHVybiAiIjsKICAgICAgICBmb3IodmFyIGk9bS5sZW5ndGgtMTtpPj0wO2ktLSkgaWYobVtpXSE9PWRucykgcmV0dXJuIG1baV07CiAgICAgICAgcmV0dXJuICIiOwogICAgfQogICAgZnVuY3Rpb24gZG93bmxvYWQodXJsLHBhcnQpewogICAgICAgIHZhciBoPWhvc3RGcm9tVXJsKHVybCksIGh0dHBzPS9eaHR0cHM6L2kudGVzdCh1cmwpLCBpcD1oP3Jlc29sdmVIb3N0KGgpOiIiLCBwb3J0PWh0dHBzPyI0NDMiOiI4MCI7CiAgICAgICAgdmFyIGJhc2U9cShjdXJsKSsiIC0tc3NsLW5vLXJldm9rZSAtLWZhaWwgLS1sb2NhdGlvbiAtLXNpbGVudCAtLXNob3ctZXJyb3IgLS1yZXRyeSA0IC0tcmV0cnktZGVsYXkgMyAtLWNvbm5lY3QtdGltZW91dCAyMCAtLW1heC10aW1lIDcyMDAgIjsKICAgICAgICBpZihpcCkgYmFzZSs9Ii0tcmVzb2x2ZSAiK3EoaCsiOiIrcG9ydCsiOiIraXApKyIgIjsKICAgICAgICB2YXIgcmVzdW1lPWZzby5GaWxlRXhpc3RzKHBhcnQpOwogICAgICAgIHZhciByPWV4ZWMoYmFzZSsocmVzdW1lPyItLWNvbnRpbnVlLWF0IC0gIjoiIikrcSh1cmwpKyIgLW8gIitxKHBhcnQpKTsKICAgICAgICBpZihyLmNvZGU9PT0wKSByZXR1cm4gdHJ1ZTsKICAgICAgICBpZihyZXN1bWUpewogICAgICAgICAgICB0cnl7ZnNvLkRlbGV0ZUZpbGUocGFydCx0cnVlKTt9Y2F0Y2goZSl7fQogICAgICAgICAgICByPWV4ZWMoYmFzZStxKHVybCkrIiAtbyAiK3EocGFydCkpOwogICAgICAgICAgICBpZihyLmNvZGU9PT0wKSByZXR1cm4gdHJ1ZTsKICAgICAgICB9CiAgICAgICAgcmV0dXJuIGZhbHNlOwogICAgfQoKICAgIGlmKCFmc28uRmlsZUV4aXN0cyhqc29uUGF0aCkpe3N0YXRlKCJFUlJPUiIsMCwwLCIiLCJKU09OIHJlc3BvbnNlIG1pc3NpbmciKTtXU2NyaXB0LlF1aXQoMjEpO30KICAgIGlmKCFmc28uRm9sZGVyRXhpc3RzKGRlc3REaXIpKSBmc28uQ3JlYXRlRm9sZGVyKGRlc3REaXIpOwoKICAgIHZhciBkYXRhOwogICAgdHJ5eyBkYXRhPWV2YWwoIigiK3JlYWRBbGwoanNvblBhdGgpKyIpIik7IH0KICAgIGNhdGNoKGUpe3N0YXRlKCJFUlJPUiIsMCwwLCIiLCJKU09OIHBhcnNlIGZhaWxlZCIpO1dTY3JpcHQuUXVpdCgyMik7fQogICAgaWYoIWRhdGF8fCFkYXRhLnJlc3BvbnNlfHxkYXRhLnJlc3BvbnNlLmVycm9yKXsKICAgICAgICBzdGF0ZSgiRVJST1IiLDAsMCwiIixkYXRhJiZkYXRhLnJlc3BvbnNlJiZkYXRhLnJlc3BvbnNlLmVycm9yP1N0cmluZyhkYXRhLnJlc3BvbnNlLmVycm9yKToiTWlzc2luZyByZXNwb25zZSBvYmplY3QiKTsKICAgICAgICBXU2NyaXB0LlF1aXQoMjMpOwogICAgfQogICAgdmFyIHI9ZGF0YS5yZXNwb25zZTsKICAgIGlmKFN0cmluZyhyLmJ1aWxkKSE9PVN0cmluZyhleHBlY3RlZEJ1aWxkKSl7c3RhdGUoIkVSUk9SIiwwLDAsIiIsIlVuZXhwZWN0ZWQgYnVpbGQgIityLmJ1aWxkKTtXU2NyaXB0LlF1aXQoMjQpO30KICAgIGlmKFN0cmluZyhyLmFyY2gpLnRvTG93ZXJDYXNlKCkhPT0iYW1kNjQiKXtzdGF0ZSgiRVJST1IiLDAsMCwiIiwiVW5leHBlY3RlZCBhcmNoaXRlY3R1cmUgIityLmFyY2gpO1dTY3JpcHQuUXVpdCgyNSk7fQogICAgaWYoIXIuZmlsZXMpe3N0YXRlKCJFUlJPUiIsMCwwLCIiLCJBUEkgcmV0dXJuZWQgbm8gZmlsZXMiKTtXU2NyaXB0LlF1aXQoMjYpO30KCiAgICB2YXIgbGlzdD1bXSwgdG90YWxCeXRlcz0wOwogICAgZm9yKHZhciBuYW1lIGluIHIuZmlsZXMpewogICAgICAgIGlmKCFyLmZpbGVzLmhhc093blByb3BlcnR5KG5hbWUpKSBjb250aW51ZTsKICAgICAgICB2YXIgeD1yLmZpbGVzW25hbWVdOwogICAgICAgIGlmKCF4fHwheC51cmx8fCF4LnNoYTF8fCF4LnNpemUpIGNvbnRpbnVlOwogICAgICAgIGxpc3QucHVzaCh7bmFtZTpuYW1lLHVybDpTdHJpbmcoeC51cmwpLHNoYTE6U3RyaW5nKHguc2hhMSkudG9Mb3dlckNhc2UoKSxzaXplOnBhcnNlSW50KHguc2l6ZSwxMCl8fDB9KTsKICAgICAgICB0b3RhbEJ5dGVzICs9IHBhcnNlSW50KHguc2l6ZSwxMCl8fDA7CiAgICB9CiAgICBpZihsaXN0Lmxlbmd0aD09PTApe3N0YXRlKCJFUlJPUiIsMCwwLCIiLCJObyBkb3dubG9hZGFibGUgZmlsZXMgaW4gQVBJIHJlc3BvbnNlIik7V1NjcmlwdC5RdWl0KDI3KTt9CiAgICB0cnl7CiAgICAgICAgdmFyIGRyaXZlPWZzby5HZXREcml2ZShkZXN0RGlyLnN1YnN0cigwLDIpKSwgcmVzZXJ2ZT0xMDczNzQxODI0OwogICAgICAgIGlmKGRyaXZlLkZyZWVTcGFjZSA8IHRvdGFsQnl0ZXMrcmVzZXJ2ZSl7c3RhdGUoIkVSUk9SIiwwLGxpc3QubGVuZ3RoLCIiLCJJbnN1ZmZpY2llbnQgZnJlZSBzcGFjZSIpO1dTY3JpcHQuUXVpdCgyOCk7fQogICAgfWNhdGNoKGUpe3N0YXRlKCJFUlJPUiIsMCxsaXN0Lmxlbmd0aCwiIiwiQ291bGQgbm90IHZlcmlmeSBmcmVlIHNwYWNlIik7V1NjcmlwdC5RdWl0KDI5KTt9CgogICAgdmFyIGRvbmU9MDsKICAgIHN0YXRlKCJET1dOTE9BRElORyIsZG9uZSxsaXN0Lmxlbmd0aCwiIiwiVmFsaWRhdGVkIFVVUCBKU09OIEFQSSByZXNwb25zZSIpOwogICAgZm9yKHZhciBpPTA7aTxsaXN0Lmxlbmd0aDtpKyspewogICAgICAgIHZhciBpdGVtPWxpc3RbaV0sIHNhZmU9aXRlbS5uYW1lLnJlcGxhY2UoL1tcXFwvOio/Ijw+fF0vZywiXyIpLAogICAgICAgICAgICBmaW5hbFBhdGg9ZGVzdERpcisiXFwiK3NhZmUsIHBhcnRQYXRoPWZpbmFsUGF0aCsiLnBhcnQiOwogICAgICAgIFdTY3JpcHQuRWNobygiWyIrKGkrMSkrIi8iK2xpc3QubGVuZ3RoKyJdICIrc2FmZSk7CiAgICAgICAgc3RhdGUoIkRPV05MT0FESU5HIixkb25lLGxpc3QubGVuZ3RoLHNhZmUsIkRvd25sb2FkaW5nL3ZlcmlmeWluZyIpOwogICAgICAgIGlmKGZzby5GaWxlRXhpc3RzKGZpbmFsUGF0aCkpewogICAgICAgICAgICBpZihzaGExKGZpbmFsUGF0aCk9PT1pdGVtLnNoYTEpe2RvbmUrKztjb250aW51ZTt9CiAgICAgICAgICAgIHRyeXtmc28uRGVsZXRlRmlsZShmaW5hbFBhdGgsdHJ1ZSk7fWNhdGNoKGVEZWwpe3N0YXRlKCJFUlJPUiIsZG9uZSxsaXN0Lmxlbmd0aCxzYWZlLCJFeGlzdGluZyBmaWxlIGhhc2ggbWlzbWF0Y2ggYW5kIGNvdWxkIG5vdCBiZSByZXBsYWNlZCIpO1dTY3JpcHQuUXVpdCgzMCk7fQogICAgICAgIH0KICAgICAgICBpZighZG93bmxvYWQoaXRlbS51cmwscGFydFBhdGgpKXtzdGF0ZSgiUEFVU0VEIixkb25lLGxpc3QubGVuZ3RoLHNhZmUsIkRvd25sb2FkIGZhaWxlZDsgcmVydW4gaXMgc2FmZSIpO1dTY3JpcHQuUXVpdCgzMSk7fQogICAgICAgIGlmKHNoYTEocGFydFBhdGgpIT09aXRlbS5zaGExKXsKICAgICAgICAgICAgdHJ5e2Zzby5EZWxldGVGaWxlKHBhcnRQYXRoLHRydWUpO31jYXRjaChlQmFkKXt9CiAgICAgICAgICAgIHN0YXRlKCJQQVVTRUQiLGRvbmUsbGlzdC5sZW5ndGgsc2FmZSwiU0hBLTEgdmVyaWZpY2F0aW9uIGZhaWxlZDsgcmVydW4gaXMgc2FmZSIpO1dTY3JpcHQuUXVpdCgzMik7CiAgICAgICAgfQogICAgICAgIHRyeXsKICAgICAgICAgICAgaWYoZnNvLkZpbGVFeGlzdHMoZmluYWxQYXRoKSkgZnNvLkRlbGV0ZUZpbGUoZmluYWxQYXRoLHRydWUpOwogICAgICAgICAgICBmc28uTW92ZUZpbGUocGFydFBhdGgsZmluYWxQYXRoKTsKICAgICAgICB9Y2F0Y2goZU1vdmUpe3N0YXRlKCJQQVVTRUQiLGRvbmUsbGlzdC5sZW5ndGgsc2FmZSwiVmVyaWZpZWQgZmlsZSBjb3VsZCBub3QgYmUgZmluYWxpemVkIik7V1NjcmlwdC5RdWl0KDMzKTt9CiAgICAgICAgZG9uZSsrOwogICAgfQogICAgc3RhdGUoIkNPTVBMRVRFIixkb25lLGxpc3QubGVuZ3RoLCIiLCJBbGwgVVVQIGZpbGVzIFNIQS0xIHZlcmlmaWVkIik7CiAgICBXU2NyaXB0LlF1aXQoMCk7Cn0pKCk7
"%CERTUTIL%" -f -decode "!HELPERB64!" "!HELPER!" >nul 2>&1
if errorlevel 1 goto :HELPERFAIL
"%FINDSTR%" /i /c:"Embedded WinRE-safe UUP JSON downloader/verifier" "!HELPER!" >nul 2>&1
if errorlevel 1 goto :HELPERFAIL
"%CERTUTIL%" -hashfile "!HELPER!" SHA256 2>nul | "%FINDSTR%" /i /c:"%HELPER_SHA256%" >nul 2>&1
if errorlevel 1 goto :HELPERFAIL
del /f /q "!HELPERB64!" >nul 2>&1

call :RESOLVE %UUPAPIHOST% APIIP
if defined APIIP (
  "%CURL%" --ssl-no-revoke --fail --location --silent --show-error --connect-timeout 20 --max-time 300 --resolve "%UUPAPIHOST%:443:!APIIP!" "%UUPAPIURL%" -o "!JSON!"
) else (
  "%CURL%" --ssl-no-revoke --fail --location --silent --show-error --connect-timeout 20 --max-time 300 "%UUPAPIURL%" -o "!JSON!"
)
if errorlevel 1 goto :APIFAIL
if not exist "!JSON!" goto :APIFAIL
"%FINDSTR%" /i /c:"26100.8894" "!JSON!" >nul 2>&1
if errorlevel 1 goto :APIFAIL
"%FINDSTR%" /i /c:"amd64" "!JSON!" >nul 2>&1
if errorlevel 1 goto :APIFAIL
"%FINDSTR%" /i /c:"\"files\"" "!JSON!" >nul 2>&1
if errorlevel 1 goto :APIFAIL

cls
echo ================================================================
echo WINDOWS 11 24H2 DOWNLOAD STARTED
echo Version: %COMMAND_VERSION%
echo ================================================================
echo Boot volume : !BOOTVOL! WIN11MEDIA [UNCHANGED]
echo Data volume : !DATAVOL! REPAIRDATA
echo Source      : UUP dump official JSON API -^> Microsoft UUP URLs
echo Target      : Windows 11 24H2 %UUPBUILD% x64 Core en-US
echo ---------------------------------------------------------------
echo Every completed file is verified against API-provided SHA-1.
echo Rerunning C:\wr.cmd safely reuses files that already verify.
echo ================================================================

"%CSCRIPT%" //nologo "!HELPER!" "!JSON!" "!UUPDIR!" "%UUPBUILD%" "%CURL%" "%CERTUTIL%" "%NSLOOKUP%" "%DNS%" "!STATE!"
set "DLRC=!errorlevel!"

set "DLSTATUS=UNKNOWN"
set "DLDONE=0"
set "DLTOTAL=0"
set "DLCURRENT="
set "DLMESSAGE="
if exist "!STATE!" (
  for /f "usebackq tokens=1,* delims==" %%A in ("!STATE!") do (
    if /i "%%A"=="status" set "DLSTATUS=%%B"
    if /i "%%A"=="done" set "DLDONE=%%B"
    if /i "%%A"=="total" set "DLTOTAL=%%B"
    if /i "%%A"=="current" set "DLCURRENT=%%B"
    if /i "%%A"=="message" set "DLMESSAGE=%%B"
  )
)

cls
echo ================================================================
echo RECOVERY DOWNLOAD SNAPSHOT
echo Version: %COMMAND_VERSION%
echo ================================================================
echo Recovery manifest : !LOCALMANIFEST!
echo Source build      : %UUPBUILD% / Core / en-US / x64
echo Download status   : !DLSTATUS!
echo Verified files    : !DLDONE! / !DLTOTAL!
if defined DLCURRENT echo Current file      : !DLCURRENT!
if defined DLMESSAGE echo Message           : !DLMESSAGE!
echo ---------------------------------------------------------------
if /i "!DLSTATUS!"=="COMPLETE" (
  echo ASSESSMENT: READY_FOR_UUP_CONVERSION_AND_BOOT_MEDIA_COPY
) else if /i "!DLSTATUS!"=="PAUSED" (
  echo ASSESSMENT: DOWNLOAD_CAN_RESUME_SAFELY
) else (
  echo ASSESSMENT: DOWNLOAD_STAGE_NEEDS_REVIEW
)
echo ---------------------------------------------------------------
echo Disk/filesystem management operations in this build: NONE
echo Take ONE photo of this screen and send it to ChatGPT.
echo ================================================================
exit /b !DLRC!

:FETCHRAW
set "FETCHURL=%~1"
set "FETCHOUT=%~2"
set "RAWIP="
call :RESOLVE %RAWHOST% RAWIP
if exist "%FETCHOUT%.tmp" del /f /q "%FETCHOUT%.tmp" >nul 2>&1
if defined RAWIP (
  "%CURL%" --ssl-no-revoke --fail --location --silent --show-error --connect-timeout 20 --max-time 120 --resolve "%RAWHOST%:443:!RAWIP!" "%FETCHURL%" -o "%FETCHOUT%.tmp"
) else (
  "%CURL%" --ssl-no-revoke --fail --location --silent --show-error --connect-timeout 20 --max-time 120 "%FETCHURL%" -o "%FETCHOUT%.tmp"
)
if errorlevel 1 (
  if exist "%FETCHOUT%.tmp" del /f /q "%FETCHOUT%.tmp" >nul 2>&1
  exit /b 1
)
for %%Z in ("%FETCHOUT%.tmp") do if %%~zZ LSS 32 (
  del /f /q "%FETCHOUT%.tmp" >nul 2>&1
  exit /b 1
)
move /y "%FETCHOUT%.tmp" "%FETCHOUT%" >nul 2>&1
exit /b 0

:WRITELOCALMANIFEST
>"!LOCALMANIFEST!" echo Windows Recovery Manifest - local fallback
>>"!LOCALMANIFEST!" echo Current failure: INACCESSIBLE_BOOT_DEVICE 0x7B
>>"!LOCALMANIFEST!" echo Current Windows: Home/Core 24H2 x64; offline build 26100.9168
>>"!LOCALMANIFEST!" echo Current storage binding: iaStorA
>>"!LOCALMANIFEST!" echo PASS: disk readable; boot-file reads pass; NTFS clean; read-only CHKDSK clean
>>"!LOCALMANIFEST!" echo PASS: Intel 16.7.1.1012 signed DEV_A102 package staged
>>"!LOCALMANIFEST!" echo FAIL: iaStorA to iaStorAC binding test did not resolve 0x7B; rolled back
>>"!LOCALMANIFEST!" echo PASS: WIN11MEDIA FAT32 plus REPAIRDATA NTFS USB created
>>"!LOCALMANIFEST!" echo FAIL: interactive UUP website endpoint was wrong for automation
>>"!LOCALMANIFEST!" echo FAIL: 0907 GitHub API helper retrieval failed
>>"!LOCALMANIFEST!" echo FAIL: 0915 raw/local helper retrieval also failed
>>"!LOCALMANIFEST!" echo CURRENT: 0918 embeds downloader in next.cmd; no helper network dependency
>>"!LOCALMANIFEST!" echo NEXT: UUP JSON API; SHA-1 verified Microsoft files; conversion; fresh recovery boot; targeted repair
>>"!LOCALMANIFEST!" echo POLICY: no disk clean; format; repartition; or filesystem creation in active workflow
exit /b 0

:CHECKNET
"%PING%" -n 1 -w 2000 1.1.1.1 >nul 2>&1
if not errorlevel 1 exit /b 0
"%PING%" -n 1 -w 2000 8.8.8.8 >nul 2>&1
if not errorlevel 1 exit /b 0
exit /b 1

:RESOLVE
set "%~2="
set "CAND="
for /f "delims=" %%L in ('"%NSLOOKUP%" %~1 %DNS% 2^>nul ^| "%FINDSTR%" /R "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*"') do (
  for %%T in (%%L) do set "CAND=%%T"
  if not "!CAND!"=="%DNS%" set "%~2=!CAND!"
)
exit /b 0

:APIFAIL
set "WHY=Official UUP JSON API did not return expected build/arch/files."
goto :EARLYFAIL
:HELPERFAIL
set "WHY=Embedded downloader reconstruction or SHA-256 validation failed."
goto :EARLYFAIL
:WINDOWSFAIL
set "WHY=Offline Windows identity did not match Core/en-US. Detected !OFFEDITION!/!OFFLANG!."
goto :EARLYFAIL
:MEDIAFAIL
set "WHY=WIN11MEDIA and REPAIRDATA were not uniquely identified by label."
goto :EARLYFAIL
:NETFAIL
set "WHY=Internet connectivity could not be restored."
goto :EARLYFAIL
:TOOLSFAIL
set "WHY=A required built-in Windows download/parser/verification tool is unavailable."
:EARLYFAIL
cls
echo ================================================================
echo RECOVERY DOWNLOAD SNAPSHOT
echo Version: %COMMAND_VERSION%
echo ================================================================
echo Download status : NOT_STARTED
echo Message         : !WHY!
echo ---------------------------------------------------------------
echo ASSESSMENT: DOWNLOAD_STAGE_NEEDS_REVIEW
echo Disk/filesystem management operations in this build: NONE
echo Take ONE photo of this screen and send it to ChatGPT.
echo ================================================================
exit /b 90
