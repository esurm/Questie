@echo off
echo.
echo This will help you find and copy your Questie SavedVariables
echo.
echo Looking for Questie SavedVariables files...
echo.

set "SOURCE_DIR=C:\Program Files\Ascension Launcher\resources\epoch_live\WTF\Account"
set "DEST_FILE=C:\Users\trav3\Dropbox\WoW Interfaces\epoch\AddOns\Questie\MY_SAVEDVARIABLES.lua"

echo Searching in: %SOURCE_DIR%
echo.

dir "%SOURCE_DIR%\*Questie*.lua" /s /b 2>nul

echo.
echo ============================================
echo.
echo To copy your SavedVariables file:
echo 1. Find the Questie.lua file for your character above
echo 2. Copy the full path
echo 3. Run: copy "FULL_PATH" "%DEST_FILE%"
echo.
echo Example:
echo copy "C:\Program Files\Ascension Launcher\resources\epoch_live\WTF\Account\YOURACCOUNT\Realm\Character\SavedVariables\Questie.lua" "%DEST_FILE%"
echo.
pause