@echo off
setlocal
set "ROOT=%~dp0"
set "PROJECT_ROOT=%ROOT:~0,-1%"
set "TOOL_DIR=%ROOT%dev_tools\acceptance_tool"
set "PS_SCRIPT=%TOOL_DIR%\uninstall.ps1"

if not exist "%PS_SCRIPT%" (
  echo [FAILED] The acceptance tool uninstaller was not found. Nothing was deleted.
  pause
  exit /b 20
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%" -ProjectRoot "%PROJECT_ROOT%"
if errorlevel 1 (
  echo.
  echo Uninstall validation failed. Tool files were kept to protect the project.
  pause
  exit /b 21
)

if exist "%TOOL_DIR%" rmdir /s /q "%TOOL_DIR%"
if exist "%TOOL_DIR%" (
  echo [FAILED] Autoload was removed, but the tool folder is in use.
  echo Close Godot and delete this folder manually:
  echo %TOOL_DIR%
  pause
  exit /b 22
)

echo.
echo Acceptance tool was removed. Restart the Godot editor.
echo This wrapper will delete itself after closing.
set "ACCEPTANCE_SELF_DELETE=%~f0"
start "" /b powershell.exe -NoProfile -WindowStyle Hidden -Command "Start-Sleep -Milliseconds 700; Remove-Item -LiteralPath $env:ACCEPTANCE_SELF_DELETE -Force"
endlocal
exit /b 0
