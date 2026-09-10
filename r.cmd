@echo off
C:\Windows\System32\curl.exe --ssl-no-revoke -fL "https://raw.githubusercontent.com/RennieBeekharry/winre-repair/5902c7e130ca4712e3355f8bf489e37fca9d625f/connect-device-v3.cmd" -o X:\r3.cmd
if errorlevel 1 exit /b 90
call X:\r3.cmd
