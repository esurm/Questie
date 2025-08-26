## Quest 26939 has completely wrong data (5+ errors)

### Description
Quest 26939 in the Epoch database contains multiple data errors making it unusable. The quest shows generic placeholder text and all IDs are wrong.

### Errors Found
1. **Quest name**: Shows "[Epoch] Quest 26939" instead of "Peace in Death"
2. **Quest giver**: Wrong NPC ID (45099 instead of 45898)
3. **Object ID**: Wrong ID (4000010 instead of 4000009)  
4. **Item ID**: Wrong ID (60100 instead of 62811)
5. **Rewards**: Wrong items (60100 instead of 62808/62809/62810)
6. **Missing coordinates**: No spawn location for object
7. **Missing special objective**: No data for using item at specific location

### Impact
- Quest displays generic name in tracker
- Quest giver doesn't appear on map
- Objective location not shown
- Wrong rewards displayed

### Verified Correct Data
All data collected and verified in-game on Project Epoch:
```
Quest Name: Peace in Death
Quest Giver: Luna Strinbrow (45898) at [30.8, 65.3]
Object: ID 4000009 at [23.1, 59.8]
Quest Item: ID 62811
Special Objective: Use item 62811 at [30.7, 65.2] (cog marker location)
Rewards: Items 62808, 62809, 62810 (player choice)
```

### Version
- Questie: 1.3.4c
- Server: Project Epoch 3.3.5a

This appears to be a pattern - the Epoch quest database seems to have been bulk imported without verification, as this single quest had 5+ data errors.