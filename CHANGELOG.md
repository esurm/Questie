# Questie Changelog

## [1.3.3] - 2025-08-25

### Added
- Zone header toggle option in tracker settings - allows users to hide zone headers like "Trade District", "[Epoch]", "Quests (By Level)" while keeping quest content
- GitHub repository URL display during addon initialization

### Fixed
- **Critical**: Fixed objective progress tracking for database quests - progress numbers (e.g., "Mindless Zombie slain: 0/8") now display correctly in tracker
- **Critical**: Fixed party progress tooltips for database quests - party member progress now shows in tooltips for custom server quests without ObjectiveData
- **Critical**: Replaced incompatible `Item:CreateFromItemID()` API calls with 3.3.5-compatible `GetItemInfo()` to prevent initialization errors
- Added missing `onlyPartyShared` setting to defaults - fixes party progress tooltip filtering functionality
- Suppressed spam database mismatch error messages for custom server quests (expected behavior on Ascension Epoch using older Epoch IDs)
- Removed debug spam messages during addon startup ("Addon object created successfully", "OnInitialize called", "OnEnable called")

### Changed
- Database mismatch errors are now debug-level messages instead of error-level spam
- Quest objective formatting now properly shows progress for all quest types (database and stub quests)
- Initialization message now shows GitHub repository instead of generic debug text

### Technical Details
- Added `trackerHideZoneHeaders` setting to QuestieOptionsDefaults.lua
- Added `onlyPartyShared` setting to QuestieOptionsDefaults.lua (was missing, causing tooltip filtering issues)
- Added fallback objective creation for database quests in QuestieQuest.lua PopulateQuestLogInfo function
- Added fallback communication data creation for database quests in QuestieComms.lua CreateQuestDataPacket function
- Added zone header toggle UI in QuestieOptionsTracker.lua with proper localization
- Modified QuestieTracker.lua to conditionally create zone headers based on user setting
- Fixed QuestieLib.lua CacheItemNames function to use compatible item API
- Fixed QuestieCommsData.lua item loading to use compatible approach
- Enhanced objective text formatting to include progress numbers for database quests

### Developer Notes
- All changes maintain backward compatibility
- Fixes are specific to 3.3.5 client compatibility
- Custom server compatibility improved for Ascension Epoch
