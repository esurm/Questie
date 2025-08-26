@echo off
echo Creating pull request for quest 26939 fix...
echo.

cd /d "C:\Users\trav3\Dropbox\WoW Interfaces\epoch\AddOns\Questie"

"C:\Program Files\GitHub CLI\gh.exe" pr create ^
  --repo esurm/Questie ^
  --title "Fix quest 26939 'Peace in Death' data errors" ^
  --body-file PR_26939_BODY.txt ^
  --head trav346:fix-quest-26939-data ^
  --base master

echo.
echo Pull request created!
pause