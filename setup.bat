@echo off
:: Elevating script to admin
FSUTIL DIRTY query %SystemDrive% >NUL || (
    PowerShell "Start-Process -FilePath cmd.exe -Args '/C CHDIR /D %CD% & ""%0"" %*' -Verb RunAs"
    EXIT
)

echo Checking for Chocolatey...
where choco >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
    echo Installing Chocolatey...
    powershell -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command ^
        "Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))"
    RefreshEnv.cmd
) ELSE (
    echo Chocolatey is already installed.
)

echo Installing applications if missing...

:: Install VS Code
where code >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
    echo Installing VS Code...
    choco install -y vscode
) ELSE (
    echo VS Code is already installed.
)

:: Install Git
where git >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
    echo Installing Git...
    choco install -y git
) ELSE (
    echo Git is already installed.
)

:: Install VCXSRV
choco list --exact vcxsrv >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
    echo Installing VCXSRV...
    choco install -y vcxsrv
) ELSE (
    echo VCXSRV is already installed.
)

:: Install Docker Desktop
where "docker" >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
    echo Installing Docker Desktop...
    choco install -y docker-desktop
) ELSE (
    echo Docker Desktop is already installed.
)

:: Copy docker-compose.override.windows.yml to docker-compose.override.yml
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
exit /b
