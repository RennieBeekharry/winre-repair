@echo off
setlocal EnableExtensions
rem WR-MODULE: runtime-local-ready 2026.08.14-1555-ET
rem Current recovery-session bootstrap: modules are staged by next.cmd before the agent starts.

set "RUNTIME=C:\WinRERepair\runtime"
for %%F in (ui.cmd network.cmd resolve.cmd reporting.cmd github-auth.cmd safety.cmd agent-core.js) do (
  if not exist "%RUNTIME%\%%F" exit /b 91
)
exit /b 0
