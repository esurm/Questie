## Quest 26939 "Peace in Death" has incorrect data

### Description
Quest 26939 in the Epoch database has incorrect/placeholder data. The quest shows as "Quest 26939" in the tracker instead of its actual name "Peace in Death", and the quest giver NPC ID is wrong.

### Current (Incorrect) Data
```lua
[26939] = {"[Epoch] Quest 26939",{{45099}},{{45099}},nil,5,nil,nil,nil,nil,{nil,{{4000010,nil}},{{60100,nil}}},nil,nil,{376},nil,nil,nil,85,nil,nil,nil,{60100},nil,nil,0,nil,nil,nil,nil,nil,nil}
```

**Issues:**
- Name: Shows as "[Epoch] Quest 26939" instead of "Peace in Death"
- Quest Giver: Listed as NPC 45099 (incorrect)
- Quest rewards: Listed as item 60100 (incorrect)

### Correct Data (Collected In-Game)
- **Quest Name**: "Peace in Death"
- **Quest ID**: 26939
- **Quest Giver**: Luna Strinbrow (NPC ID: 45898) at [30.8, 65.3]
- **Quest Level**: 5
- **Zone**: Tirisfal Glades (ID: 85)
- **Rewards**: Items 62808, 62809, 62810 (choice of rewards)
- **Objectives**: 
  - Interact with object ID: 4000009 at [23.1, 59.8] (was incorrectly 4000010, no coords)
  - Collect item ID: 62811 (was incorrectly 60100)
  - Use item 62811 at location [30.7, 65.2] to complete quest (special objective - was completely missing)

### Steps to Reproduce
1. Go to Tirisfal Glades coordinates [30.8, 65.3]
2. Accept quest from Luna Strinbrow
3. Note that tracker shows "Quest 26939" instead of "Peace in Death"
4. Check quest rewards - they don't match database

### Expected Behavior
- Quest should display as "Peace in Death" in tracker
- Quest giver should be NPC 45898
- Rewards should be items 62808, 62809, 62810

### Impact
Players see generic quest names in tracker making it difficult to identify quests. Quest giver location may not show correctly on map.

### Version Information
- **Questie Version**: 1.3.4c
- **WoW Version**: 3.3.5a
- **Server**: Project Epoch