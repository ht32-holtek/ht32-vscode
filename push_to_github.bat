@echo off
setlocal

set REMOTE_URL=https://github.com/ht32-holtek/ht32-vscode.git
set BRANCH=main

cd /d "%~dp0"

REM Initialize git if not already done
if not exist ".git" (
    echo Initializing git repository...
    git init
    git remote add origin %REMOTE_URL%
) else (
    REM Make sure remote is set correctly
    git remote set-url origin %REMOTE_URL%
)

REM Stage all files
git add -A

REM Prompt for commit message
set /p COMMIT_MSG=Enter commit message (or press Enter for default):
if "%COMMIT_MSG%"=="" set COMMIT_MSG=Update files

git commit -m "%COMMIT_MSG%"

REM Push to remote
echo Pushing to %REMOTE_URL% [%BRANCH%]...
git push -u origin %BRANCH%

if %ERRORLEVEL% neq 0 (
    echo.
    echo Push failed. If this is the first push, trying with --force...
    echo If branch does not exist remotely, the above error is expected.
    echo Try: git push -u origin %BRANCH% --force
)

echo.
pause
