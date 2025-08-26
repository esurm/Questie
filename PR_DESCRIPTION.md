## Fix: Questie fails to load in v1.3.4c

Closes #18, Closes #19, Closes #20

### Problem
In v1.3.4c, Questie completely fails to load due to line 26 in `Questie.lua` calling `QuestieTracker.InitializeTables()` which doesn't exist in the codebase. This causes a Lua error that prevents the entire addon from initializing.

### Solution
Commented out the problematic function call on line 26. The table initialization is already properly handled in `QuestieTracker.Initialize()` (lines 90-113 of `QuestieTracker.lua`), making the removed call both redundant and broken.

### Changes
- **Questie.lua:26** - Commented out non-existent `QuestieTracker.InitializeTables()` call

### Testing
- ✅ Addon loads successfully after fix
- ✅ All tracker functionality works as expected  
- ✅ Tables are properly initialized through the existing `QuestieTracker.Initialize()` function
- ✅ No Lua errors on startup

This is a critical fix that resolves the complete loading failure introduced in v1.3.4c.