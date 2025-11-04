@echo off
REM Ensure script is running as admin
NET SESSION >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
    echo Please run this script as Administrator.
    pause
    exit /b
)

echo Setting up all needed tools for you (may need to run script multiple times)...

echo Checking for Chocolatey...
where choco >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
    echo Installing Chocolatey...
    powershell -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command ^
        "Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))"
    
    REM Refresh environment only if choco was just installed
    IF EXIST "%ChocolateyInstall%\bin\refreshenv.cmd" (
        echo Refreshing environment...
        call "%ChocolateyInstall%\bin\refreshenv.cmd" 2>nul
    )
)

echo Installing WSL...
powershell -NoProfile -ExecutionPolicy Bypass -Command "wsl --install"

echo Installing VS Code, Git, VCXSRV, and Docker Desktop...
choco install -y vscode git vcxsrv docker-desktop

REM Copy docker-compose.override.windows.yml to docker-compose.override.yml
IF EXIST ".\.devcontainer\docker-compose.override.windows.yml" (
    copy /Y ".\.devcontainer\docker-compose.override.windows.yml" ".\.devcontainer\docker-compose.override.yml"
    echo Copied docker-compose.override.windows.yml to docker-compose.override.yml
) ELSE (
    echo Warning: .devcontainer\docker-compose.override.windows.yml not found!
)

echo.
echo Installation complete!
echo Please restart your computer to finish WSL and Docker Desktop setup.
pause