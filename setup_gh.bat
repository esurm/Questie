@echo off
echo Setting up GitHub CLI authentication...
echo.
"C:\Program Files\GitHub CLI\gh.exe" auth login
echo.
echo After authentication, run create_pr.bat to create the pull request.
pause