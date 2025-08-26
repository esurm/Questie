# Quest 26939 "Peace in Death" has completely incorrect data

## Description
Quest 26939 in the Project Epoch database contains 7 separate data errors, making the quest unusable. The quest displays as a generic placeholder and all associated data (NPCs, items, objects) is wrong.

## Current Incorrect Data
```lua
[26939] = {"[Epoch] Quest 26939",{{45099}},{{45099}},nil,5,nil,nil,nil,nil,{nil,{{4000010,nil}},{{60100,nil}}},nil,nil,{376},nil,nil,nil,85,nil,nil,nil,{60100},nil,nil,0,nil,nil,nil,nil,nil,nil}
```

## Errors Found
1. **Quest name**: Shows "[Epoch] Quest 26939" instead of "Peace in Death"
2. **Quest giver NPC**: Wrong ID (45099 instead of 45898)
3. **Object ID**: Wrong (4000010 instead of 4000009)
4. **Quest item ID**: Wrong (60100 instead of 62811)
5. **Reward items**: Wrong (60100 instead of 62808/62809/62810)
6. **Missing NPC data**: NPC 45898 doesn't exist in database
7. **Missing coordinates**: No spawn locations for quest giver or objectives

## Verified Correct Data
All data collected in-game on Project Epoch server:

**Quest:**
- Name: Peace in Death
- ID: 26939
- Level: 5
- Zone: Tirisfal Glades (85)
- Prerequisites: Quest 376

**NPCs:**
- Quest Giver/Turn-in: Luna Strinbrow (ID: 45898) at [30.8, 65.3]

**Objectives:**
- Loot Samuel's Remains (item 62811) from object 4000009 at [23.1, 59.8]
- Use Samuel's Remains at [30.7, 65.2] to complete quest

**Rewards:**
- Choice of items: 62808, 62809, or 62810

## Impact
- Quest shows generic placeholder name in tracker
- Quest giver doesn't appear on map
- Objective locations not marked
- Cannot complete quest without knowing coordinates
- Wrong rewards displayed

## Steps to Reproduce
1. Go to Tirisfal Glades [30.8, 65.3]
2. Accept quest from Luna Strinbrow
3. Observe incorrect quest name in tracker
4. Note missing map markers for objectives

## Version Information
- **Questie Version**: 1.3.4c
- **WoW Version**: 3.3.5a
- **Server**: Project Epoch

## Notes
This appears to be part of a larger pattern - the Epoch quest database contains 600+ quests, many with placeholder data that has never been verified in-game. This single quest had 7 separate errors, suggesting systematic issues with the database import.