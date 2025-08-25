# Questie Changelog
## [1.3.4b] - 2025-08-25

- Bugfixes

## [1.3.4] - 2025-08-25

### Added
- **Major**: Comprehensive Stormwind coordinate fixes for Project Epoch server compatibility
- **259 Classic NPCs** now positioned correctly in WotLK Stormwind layout
- Alliance Shaman trainer (Farseer Umbrua) added for WotLK expansion compatibility
- Automated coordinate conversion system for Classic-to-WotLK positioning
- Enhanced quest tracking system with improved stub quest support
- Better quest abandonment cleanup and objective management
- Improved progress formatting for custom server quest objectives

### Fixed
- **Critical**: All Stormwind NPCs (trainers, vendors, quest givers, guards, bankers) now appear in correct WotLK positions
- **Critical**: Fixed stub quest tracking and untracking issues - stub quests now properly add/remove from tracker without errors
- **Critical**: Fixed quest abandonment cleanup - abandoned quests now properly remove from tracker and clear all objectives
- **Critical**: Fixed duplicate objective displays - eliminated multiple copies of the same objective appearing in tracker
- **Critical**: Fixed quest progress formatting - progress numbers now display correctly for all quest types
- **Critical**: Fixed rapid quest acceptance problems - multiple quick accepts no longer cause tracker conflicts
- **Critical**: Fixed QuestieCompat.GetContainerItemInfo and enhanced Tracker Item Detection 
--**Party Progress**: Party quest progress on tooltip should now update correctly
- **Quest Tracking**: Improved objective text formatting and progress tracking for custom server quests
- **Zone Text**: Fixed zone text changes and coordinate display issues during quest progression
- **Goldshire**: Removed conflicting Classic NPCs that shouldn't exist in WotLK layout

### Changed
- Stormwind NPCs now use WotLK coordinate system instead of Classic positions
- Classic NPCs that conflict with WotLK layout are properly hidden in Goldshire area

### Technical Details
- Added `epochStormwindFixes.lua` with 260 NPC coordinate corrections
- Enhanced `epochElwynnFixes.lua` for Goldshire NPC conflict resolution
- Added systematic database cross-referencing for accurate positioning
- Fixed module definition pattern for epoch-specific corrections
- Coordinate fixes cover zone 1519 (Stormwind City) and zone 40 (Elwynn Forest)
- Improved quest tracking logic for stub quests and custom server compatibility
- Enhanced objective cleanup during quest abandonment
- Fixed duplicate objective detection and removal
- Improved progress text formatting for all quest types
- Enhanced zone text handling during quest progression


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
