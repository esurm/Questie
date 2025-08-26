## Fix: Quest tracking fails when clicked from quest log

### Problem
Many quests cannot be tracked by clicking the track checkbox in the quest log. The checkbox doesn't appear and the quest doesn't get added to the tracker. This affects quest 3901 "Rattling the Rattlecages" and numerous other quests.

### Root Cause
The `AQW_Insert` function in `QuestieTracker.lua` incorrectly identifies the questId when a quest is manually tracked from the quest log. When `GetQuestLogTitle(index)` returns 0 for the questId (8th return value), the code incorrectly assumes the `index` parameter is the questId, when it's actually the questLogIndex (position in quest log).

### Solution
This PR adds proper detection logic to determine whether the `index` parameter is a questId or questLogIndex:
1. First attempts to use `GetQuestLogIndexByID` to determine the type
2. If it's a questLogIndex, iterates through the quest log to find the correct entry
3. Extracts the actual questId from the correct quest log entry
4. Falls back to original behavior only if all methods fail

### Changes
- **File Modified**: `Modules/Tracker/QuestieTracker.lua`
- **Function**: `QuestieTracker:AQW_Insert` (lines ~2121-2159)

### Testing
- ✅ Tested with quest 3901 "Rattling the Rattlecages" - now tracks correctly
- ✅ Checkbox appears in quest log when tracking
- ✅ Quest appears in Questie tracker
- ✅ No console errors
- ✅ Existing tracking functionality remains intact

### Impact
This fix resolves tracking issues for all quests where `GetQuestLogTitle` returns 0 for the questId field, which appears to affect many quests in the game.