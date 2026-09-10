@echo off
setlocal EnableExtensions
if not exist C:\RescueMeAI md C:\RescueMeAI >nul 2>&1
C:\Windows\System32\curl.exe --ssl-no-revoke -fL "https://raw.githubusercontent.com/RennieBeekharry/winre-repair/main/reconnect.cmd" -o C:\RescueMeAI\reconnect.cmd
if errorlevel 1 exit /b 90
> C:\r.cmd echo @echo off
>>C:\r.cmd echo call C:\RescueMeAI\reconnect.cmd
call C:\RescueMeAI\reconnect.cmd
