# Questie Bug Tracker

This document tracks bugs found in Questie for Project Epoch, their status, and fixes applied.

## Status Legend
- 🔴 **Open** - Bug confirmed, not fixed yet
- 🟡 **In Progress** - Currently working on fix
- 🟢 **Fixed** - Fix implemented and tested
- 🔵 **PR Submitted** - Pull request created, awaiting merge
- ⚪ **Needs Info** - More information needed to reproduce

---

## Fixed Bugs

### ✅ Bug: Addon fails to load - InitializeTables() not found
**Status**: 🔵 PR Submitted (PR #19)
- **Issue**: Questie.lua calls non-existent InitializeTables() function
- **Error**: `attempt to call global 'InitializeTables' (a nil value)`
- **Fix**: Removed the non-existent function call
- **File**: Questie.lua:21
- **Notes**: esurm claims "cascading issues" but provided no evidence

### ✅ Bug: Quest tracking fails when GetQuestLogTitle returns 0
**Status**: 🔵 PR Submitted (PR #20)
- **Issue**: Quests like 3901 "Rattling the Rattlecages" couldn't be tracked
- **Symptoms**: Clicking quest in tracker does nothing
- **Root Cause**: GetQuestLogTitle returns 0 for questId in 3.3.5a
- **Fix**: Added proper questLogIndex vs questId detection logic
- **File**: Modules/Tracker/QuestieTracker.lua
- **Affected Quests**: 3901 and potentially others

### ✅ Bug: AutoUntrackedQuests nil error
**Status**: 🟢 Fixed (but with bandaid by esurm)
- **Issue**: SavedVariables AutoUntrackedQuests field was nil for existing users
- **Error**: `attempt to index field 'AutoUntrackedQuests' (a nil value)`
- **Proper Fix**: Runtime initialization in QuestieTracker.Initialize()
- **esurm's Fix**: Added to defaults (only helps new users)
- **Notes**: esurm's fix doesn't help existing users with corrupted SavedVariables

---

## Open Bugs

### 🔴 Bug: Corrections system not loading individual epoch files
**Status**: 🔴 Open
- **Issue**: Individual epoch correction files aren't being loaded
- **Symptoms**: Quest corrections in separate files don't apply
- **Workaround**: Modify database files directly instead of using corrections
- **Files Affected**: Database/Corrections/epoch*.lua files
- **Impact**: High - prevents modular quest fixes

---

## Bugs Under Investigation

### ⚪ Bug: Quest objectives sometimes don't update on map
**Status**: ⚪ Needs Info
- **Issue**: Map markers occasionally don't appear for quest objectives
- **Symptoms**: Quest tracked but no yellow markers on map
- **Reproduction**: Intermittent, seems to happen after /reload
- **Workaround**: Untrack and re-track quest

---

## Known Issues (Not Bugs)

### Database Issues
These are data problems, not code bugs:
- 600+ Epoch quests with placeholder data
- Many quests showing "[Epoch] Quest XXXXX" names
- Wrong NPC IDs (often 45099, 45100)
- Wrong item IDs (often 60100, 60102)
- Missing coordinates for objectives

See `EPOCH_QUEST_TRACKER.md` for quest data fixes.

---

## Testing Notes

### How to Test Fixes
1. Make changes to files
2. **Completely exit WoW** (not just /reload)
3. Start WoW
4. Enable Lua errors: `/console scriptErrors 1`
5. Test the specific scenario
6. Check for any new errors

### Common Testing Mistakes
- Using `/reload` instead of restarting (doesn't load file changes)
- Not enabling script errors
- Not recompiling database after quest data changes

---

## Pull Request Status

| PR # | Title | Status | Notes |
|------|-------|--------|-------|
| #19 | Fix InitializeTables() error | 🔵 Submitted | esurm claims issues without evidence |
| #20 | Fix quest tracking questId detection | 🔵 Submitted | Awaiting review |
| #23 | Fix quest 26939 data errors | 🔵 Submitted | Quest data fix |

---

## Debug Commands

```lua
-- Enable error display
/console scriptErrors 1

-- Check if a quest exists in database
/dump QuestieDB:GetQuest(26939)

-- Check SavedVariables
/dump Questie.db.char.AutoUntrackedQuests

-- Force database recompile
/questie db recompile
```

---

Last Updated: 2025-08-26