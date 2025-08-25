---@class QuestieEpochElwynnFixes
local QuestieEpochElwynnFixes = QuestieLoader:CreateModule("QuestieEpochElwynnFixes")
-------------------------
--Import modules.
-------------------------
---@type QuestieDB
local QuestieDB = QuestieLoader:ImportModule("QuestieDB")
---@type ZoneDB
local ZoneDB = QuestieLoader:ImportModule("ZoneDB")

-- Project Epoch specific fixes for Elwynn Forest / Goldshire
-- Remove Classic-only NPCs that shouldn't exist in WotLK Goldshire
-- Update coordinates for WotLK client compatibility

function QuestieEpochElwynnFixes:Load()
    local npcKeys = QuestieDB.npcKeys
    local zoneIDs = ZoneDB.zoneIDs

    -- Elwynn Forest/Goldshire NPCs with WotLK coordinates for Project Epoch
    return {
        -- Remove Classic Goldshire NPCs that don't exist in WotLK
        -- These NPCs are in zone 12 and should be hidden for Project Epoch
        [295] = { [npcKeys.spawns] = {} }, -- Innkeeper Farley (replaced by Innkeeper Heather in zone 40)
        [151] = { [npcKeys.spawns] = {} }, -- Brog Hamfist (General Supplies)
        [465] = { [npcKeys.spawns] = {} }, -- Barkeep Dobbins (Bartender)
        [2329] = { [npcKeys.spawns] = {} }, -- Michelle Belle (Physician)
        [844] = { [npcKeys.spawns] = {} }, -- Antonio Perelli (Traveling Salesman)
        [1430] = { [npcKeys.spawns] = {} }, -- Tomas (Cook)
        [3935] = { [npcKeys.spawns] = {} }, -- Toddrick (Butcher)
        [6749] = { [npcKeys.spawns] = {} }, -- Erma (Stable Master)
        [3937] = { [npcKeys.spawns] = {} }, -- Kira Songshine (Traveling Baker)
        
        -- Update WotLK coordinates for zone 40 NPCs
        [8931] = {
            [npcKeys.spawns] = {[40]={{52.86,53.72}}},
        }, -- Innkeeper Heather (WotLK Goldshire innkeeper)
    }
end
