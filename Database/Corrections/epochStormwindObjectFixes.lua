---@class QuestieEpochStormwindObjectFixes
local QuestieEpochStormwindObjectFixes = QuestieLoader:CreateModule("QuestieEpochStormwindObjectFixes")
-------------------------
--Import modules.
-------------------------
---@type QuestieDB
local QuestieDB = QuestieLoader:ImportModule("QuestieDB")

-- Project Epoch specific fixes for Stormwind City Objects
-- Epoch uses Classic world but WotLK Stormwind layout, so we need to override
-- Stormwind (zone 1519) coordinates with WotLK data

function QuestieEpochStormwindObjectFixes:Load()
    local objectKeys = QuestieDB.objectKeys

    -- Stormwind City Objects with WotLK coordinates for Project Epoch
    return {
        -- Object ID 142075: Mailbox (important for players)
        [142075] = {
            [objectKeys.spawns] = {[1519]={{36.8,69.17}}},
        },
        -- Object ID 1561: Sealed Crate (quest object)
        [1561] = {
            [objectKeys.spawns] = {[1519]={{42.46,72.04}}},
        },
    }
end
