@echo off
setlocal EnableExtensions
if not exist C:\RescueMeAI md C:\RescueMeAI >nul 2>&1
C:\Windows\System32\curl.exe --ssl-no-revoke -fL "https://raw.githubusercontent.com/RennieBeekharry/winre-repair/36b0dc7fa3b142845a066f7ab985952ef1dfb5db/reconnect.cmd" -o C:\RescueMeAI\reconnect.cmd
if errorlevel 1 exit /b 90
call C:\RescueMeAI\reconnect.cmd
exit /b %errorlevel%
