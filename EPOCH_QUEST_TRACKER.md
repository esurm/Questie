# Epoch Quest Data Collection Tracker

## Data Collection Status
- **Collection System**: ACTIVE ✅
- **Auto-initialization**: Working ✅
- **SavedVariables**: Saving properly ✅
- **Last Updated**: 2025-08-25

## Collected Quests

### Quest 26926: A Box of Relics
- **Status**: Data collected
- **Level**: 9
- **Zone**: Tirisfal Glades
- **Quest Giver**: Unknown (need to capture)
- **Turn-in NPC**: Unknown (need to capture)
- **Objectives**:
  1. Northshore Mine Explored (event)
  2. Box of Collected Relics: 0/1 (item)
- **NPCs Involved**: 
  - Historian Todd Page (ID: 45887) at [60.6, 51]
- **Notes**: Has objective progress locations captured

### Quest 26934: Filling the Armory
- **Status**: Data collected
- **Level**: 9
- **Zone**: Tirisfal Glades (Brill)
- **Quest Giver**: Oliver Dwor (ID: 2136) at [60.1, 53.3]
- **Turn-in NPC**: Unknown (need to capture)
- **Objectives**:
  1. Case of Ore: 0/6 (item)
- **Notes**: Accepted multiple times during testing

### Quest 26936: Northshore Mine
- **Status**: Data collected
- **Zone**: Tirisfal Glades
- **Notes**: Newly captured, need quest giver and objectives details

### Quest 26940: Reclaim the Mine
- **Status**: Data collected
- **Zone**: Tirisfal Glades
- **Notes**: Newly captured, need quest giver and objectives details

### Quest 26942: Stillwater Eels
- **Status**: Data collected
- **Zone**: Tirisfal Glades
- **Notes**: Newly captured, need quest giver and objectives details

## Known Issues (Fixed)
- **Quest Giver Capture**: Was not working due to coordinate API issue
  - Fixed by using QuestieCoords.GetPlayerMapPosition()
  - Added debug output to verify NPC capture
  - Requires testing after WoW restart

## Missing Data Priority  
1. Quest givers for ALL quests (capture was broken, now fixed)
2. Turn-in NPCs for all quests
3. Full objective details for newer quests

## Commands Reference
- `/qdc status` - Check if data collection is enabled
- `/qdc show` - Show all tracked quests
- `/qdc export <questId>` - Export specific quest data for GitHub
- `/qdc enable` - Enable data collection
- `/qdc disable` - Disable data collection
- `/reload` - Save current data to disk

## GitHub Submission Process
1. Complete the quest fully (accept → complete objectives → turn in)
2. Type `/qdc export <questId>` to get formatted data
3. Create issue at: https://github.com/trav346/Questie/issues
4. Title: "Missing Quest: [Quest Name] (ID: #####)"
5. Paste the exported data in the issue description

## Technical Notes
- Data is stored in: `WTF\Account\TRAV346\SavedVariables\Questie.lua`
- Table name: `QuestieDataCollection`
- Auto-saves on `/reload` or logout
- No duplicate entries when re-accepting quests (uses quest ID as key)