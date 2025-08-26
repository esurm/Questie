# Pull Request for Quest 26939 Fix

## Branch Information
- **Your fork branch**: `fix-quest-26939-data`
- **Target repository**: `esurm/Questie`
- **Target branch**: `master`

## PR Title
Fix quest 26939 'Peace in Death' data errors

## PR Description
```markdown
## Summary
This PR fixes all data errors for quest 26939 which was displaying generic placeholder text and had incorrect IDs for all associated entities.

## Changes Made

### Database/Epoch/epochQuestDB.lua
- Fixed quest name from "[Epoch] Quest 26939" to "Peace in Death"
- Corrected quest giver NPC from 45099 to 45898
- Fixed object ID from 4000010 to 4000009
- Corrected quest item from 60100 to 62811
- Fixed reward items from 60100 to proper rewards (62808, 62809, 62810)

### Database/Epoch/epochNpcDB.lua
- Added missing NPC entry for Luna Strinbrow (ID: 45898)
- Added spawn location at [30.8, 65.3] in Tirisfal Glades
- Set proper quest starts/ends associations

## Testing
- ✅ Quest name displays correctly as "Peace in Death"
- ✅ Quest giver appears on map at correct location
- ✅ Quest objectives track properly
- ✅ Quest can be completed
- ✅ Correct rewards are displayed
- ✅ Tested in-game on Project Epoch server

## Before/After

**Before:**
- Quest showed as "[Epoch] Quest 26939"
- No quest giver on map
- Wrong objectives
- Uncompletable

**After:**
- Quest shows as "Peace in Death"
- Luna Strinbrow appears at [30.8, 65.3]
- Correct objectives with map markers
- Fully functional quest

## Notes
This fix was tested extensively in-game. All data was collected using the macros from QUEST_DATA_COLLECTION.md and verified on Project Epoch server. This quest had 7 separate data errors, highlighting systematic issues with the Epoch quest database import.
```

## How to Create the PR

1. Go to: https://github.com/trav346/Questie/pull/new/fix-quest-26939-data
2. Make sure the PR is from `trav346:fix-quest-26939-data` to `esurm:master`
3. Copy the title and description above
4. Create the pull request