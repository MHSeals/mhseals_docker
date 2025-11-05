@echo off
setlocal enabledelayedexpansion

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

echo Installing VSCode, Git, VCXSRV, and Docker if missing...
choco install -y vcxsrv docker-desktop git vscode jq --ignore-missing

echo Installing VSCode extensions...

:: Parse the extensions from JSON into a temporary file
IF EXIST ".vscode\extensions.json" (
    jq -r ".recommendations[]" .vscode\extensions.json > extensions.txt

    :: Install extensions listed in file
    set "EXT_LIST="
    for /F "delims=" %%e in (extensions.txt) do (
        if not "%%e"=="" (
            set EXT_LIST=!EXT_LIST! %%e
        )
    )
    start "" cmd /C code --install-extension !EXT_LIST! --force

    :: Clean up
    del extensions.txt
) ELSE (
    echo Warning: .vscode\extensions.json not found, skipping extensions installation
)

:: Copy docker-compose.override.windows.yml to docker-compose.override.yml
IF EXIST ".\.devcontainer\docker-compose.override.windows.yml" (
    copy /Y ".\.devcontainer\docker-compose.override.windows.yml" ".\.devcontainer\docker-compose.override.yml"
    echo Copied docker-compose.override.windows.yml to docker-compose.override.yml
) ELSE (
    echo Warning: .devcontainer\docker-compose.override.windows.yml not found!
)

echo Synchronizing the time...
net start W32Time > NUL 2>&1
w32tm /resync

echo.
echo Installation complete!
echo Please restart your computer to finish WSL and Docker Desktop setup.
pause
exit /b