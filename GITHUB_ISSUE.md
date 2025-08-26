## Quests fail to track when clicked from quest log (returns wrong questId)

### Description
Many quests cannot be tracked by clicking the track checkbox in the quest log. When attempting to track these quests, the checkbox doesn't appear and the quest doesn't get added to the tracker. The console shows the tracker attempting to add the quest but immediately removing it.

### Steps to Reproduce
1. Have a quest in your quest log (confirmed with quest 3901 "Rattling the Rattlecages" and others)
2. Open the quest log
3. Click the checkbox next to the quest to track it
4. The checkbox doesn't appear and quest doesn't track

### Expected Behavior
- Checkbox should appear next to the quest in the quest log
- Quest should be added to the Questie tracker
- Quest objectives should display on the map

### Actual Behavior
- No checkbox appears
- Quest is not tracked
- Console shows:
```
Questie: [DEVELOP] [QuestieTracker:AQW_Insert]
Questie: [DEVELOP] [QuestieTracker.RemoveQuestWatch] - by Questie
Questie: [DEVELOP] [QuestieTracker:Update]
```

### Root Cause
The `AQW_Insert` function in `QuestieTracker.lua` incorrectly identifies the questId when a quest is manually tracked from the quest log. When `GetQuestLogTitle(index)` returns 0 for the questId (8th return value), the code incorrectly assumes the `index` parameter itself is the questId, when it's actually the questLogIndex (position in quest log).

This causes the tracker to use the wrong ID (e.g., using questLogIndex 3 instead of questId 3901), which fails to find the quest in the database and causes tracking to fail.

### Technical Details
- **File**: `Modules/Tracker/QuestieTracker.lua`
- **Function**: `QuestieTracker:AQW_Insert`
- **Line**: ~2121-2126

The original code:
```lua
local questId = select(8, GetQuestLogTitle(index))
if questId == 0 then
    questId = index  -- WRONG: assumes index is questId when it's actually questLogIndex
end
```

### Solution
Properly detect whether `index` is a questId or questLogIndex, and if it's a questLogIndex, iterate through the quest log to find the correct entry and extract the actual questId.

### Affected Quests
This issue affects any quest where `GetQuestLogTitle(questLogIndex)` returns 0 for the questId field. This appears to be many quests, possibly all custom server quests or quests in certain zones.

### Version Information
- **Questie Version**: 1.3.4c
- **WoW Version**: 3.3.5a
- **Server**: Project Epoch