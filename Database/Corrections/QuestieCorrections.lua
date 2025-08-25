---@class QuestieCorrections
local QuestieCorrections = QuestieLoader:CreateModule("QuestieCorrections")

---@type QuestieDB
local QuestieDB = QuestieLoader:ImportModule("QuestieDB")
---@type ZoneDB
local ZoneDB = QuestieLoader:ImportModule("ZoneDB")
---@type QuestieLib
local QuestieLib = QuestieLoader:ImportModule("QuestieLib")
---@type RamerDouglasPeucker
local RamerDouglasPeucker = QuestieLoader:ImportModule("RamerDouglasPeucker")
---@type QuestieEvent
local QuestieEvent = QuestieLoader:ImportModule("QuestieEvent")
---@type QuestieQuestBlacklist
local QuestieQuestBlacklist = QuestieLoader:ImportModule("QuestieQuestBlacklist")
---@type QuestieNPCBlacklist
local QuestieNPCBlacklist = QuestieLoader:ImportModule("QuestieNPCBlacklist")
---@type QuestieItemBlacklist
local QuestieItemBlacklist = QuestieLoader:ImportModule("QuestieItemBlacklist")
---@type HardcoreBlacklist
local HardcoreBlacklist = QuestieLoader:ImportModule("HardcoreBlacklist")
---@type SeasonOfDiscovery
local SeasonOfDiscovery = QuestieLoader:ImportModule("SeasonOfDiscovery")

---@type QuestieQuestFixes
local QuestieQuestFixes = QuestieLoader:ImportModule("QuestieQuestFixes")
---@type QuestieClassicQuestReputationFixes
local QuestieClassicQuestReputationFixes = QuestieLoader:ImportModule("QuestieClassicQuestReputationFixes")
---@type QuestieNPCFixes
local QuestieNPCFixes = QuestieLoader:ImportModule("QuestieNPCFixes")
---@type QuestieEpochStormwindFixes
local QuestieEpochStormwindFixes = QuestieLoader:ImportModule("QuestieEpochStormwindFixes")
---@type QuestieEpochStormwindObjectFixes
local QuestieEpochStormwindObjectFixes = QuestieLoader:ImportModule("QuestieEpochStormwindObjectFixes")
---@type QuestieEpochElwynnFixes
local QuestieEpochElwynnFixes = QuestieLoader:ImportModule("QuestieEpochElwynnFixes")
---@type QuestieItemFixes
local QuestieItemFixes = QuestieLoader:ImportModule("QuestieItemFixes")
---@type QuestieObjectFixes
local QuestieObjectFixes = QuestieLoader:ImportModule("QuestieObjectFixes")

-- TBC and WotLK modules - only import if they exist
---@type QuestieTBCQuestFixes
local QuestieTBCQuestFixes = nil
---@type QuestieTBCNpcFixes
local QuestieTBCNpcFixes = nil
---@type QuestieTBCItemFixes
local QuestieTBCItemFixes = nil
---@type QuestieTBCObjectFixes
local QuestieTBCObjectFixes = nil

---@type QuestieWotlkQuestFixes
local QuestieWotlkQuestFixes = nil
---@type QuestieWotlkNpcFixes
local QuestieWotlkNpcFixes = nil
---@type QuestieWotlkItemFixes
local QuestieWotlkItemFixes = nil
---@type QuestieWotlkObjectFixes
local QuestieWotlkObjectFixes = nil

-- Safe import function for optional modules
local function safeImport(moduleName)
    local success, module = pcall(function()
        local mod = QuestieLoader:ImportModule(moduleName)
        -- Check if the module has the expected Load method
        if mod and mod.Load then
            return mod
        end
        return nil
    end)
    return success and module or nil
end

-- Conditionally import TBC/WotLK modules
if Questie.IsTBC or Questie.IsWotlk then
    QuestieTBCQuestFixes = safeImport("QuestieTBCQuestFixes")
    QuestieTBCNpcFixes = safeImport("QuestieTBCNpcFixes") 
    QuestieTBCItemFixes = safeImport("QuestieTBCItemFixes")
    QuestieTBCObjectFixes = safeImport("QuestieTBCObjectFixes")
end

if Questie.IsWotlk then
    QuestieWotlkQuestFixes = safeImport("QuestieWotlkQuestFixes")
    QuestieWotlkNpcFixes = safeImport("QuestieWotlkNpcFixes")
    QuestieWotlkItemFixes = safeImport("QuestieWotlkItemFixes")
    QuestieWotlkObjectFixes = safeImport("QuestieWotlkObjectFixes")
end

---@type IsleOfQuelDanas
local IsleOfQuelDanas = QuestieLoader:ImportModule("IsleOfQuelDanas")

--- Automatic corrections
local QuestieItemStartFixes = QuestieLoader:ImportModule("QuestieItemStartFixes")

--- COMPATIBILITY ---
local C_Timer = QuestieCompat.C_Timer

--[[
    This file load the corrections of the database files.

    It is a separate file so we can upstream those changes easier to cmangos and can still
    update the database files with a script.

    Most of the corrections can be done by accessing a specific key instead of copying the
    whole object over and change it.
    You can find the keys at the beginning of each file (e.g. 'questKeys' are at the beginning of 'questDB.lua').

    Further information on how to use this can be found at the wiki
    https://github.com/Questie/Questie/wiki/Corrections
--]]

-- flags that can be used in corrections (currently only blacklists)
QuestieCorrections.TBC_ONLY = 1 -- Hide only in TBC
QuestieCorrections.CLASSIC_ONLY = 2 -- Hide only in Classic
QuestieCorrections.WOTLK_ONLY = 3 -- Hide only in Wotlk
QuestieCorrections.TBC_AND_WOTLK = 4 -- Hide in TBC and Wotlk
QuestieCorrections.SOD_ONLY = 5 -- Hide when *not* Season of Discovery; use for SoD-only quests
QuestieCorrections.HIDE_SOD = 6 -- Hide when Season of Discovery; use to hide quests that are not available in SoD
QuestieCorrections.CLASSIC_AND_TBC = 7 -- Hide in both Classic and TBC

QuestieCorrections.killCreditObjectiveFirst = {} -- Only used for TBC quests

-- this function filters a table of values, if the value is TBC_ONLY or CLASSIC_ONLY, set it to true or nil if that case is met
---@generic T
---@param values T
---@return T
local function filterExpansion(values)
    local isClassic = Questie.IsClassic
    local isTBC = Questie.IsTBC
    local isWotlk = Questie.IsWotlk
    local isSoD = Questie.IsSoD
    for k, v in pairs(values) do
        if v == QuestieCorrections.WOTLK_ONLY then
            if isWotlk then
                values[k] = true
            else
                values[k] = nil
            end
        elseif v == QuestieCorrections.TBC_ONLY then
            if isTBC then
                values[k] = true
            else
                values[k] = nil
            end
        elseif v == QuestieCorrections.CLASSIC_ONLY then
            if isTBC or isWotlk then
                values[k] = nil
            else
                values[k] = true
            end
        elseif v == QuestieCorrections.TBC_AND_WOTLK then
            if isTBC or isWotlk then
                values[k] = true
            else
                values[k] = nil
            end
        elseif v == QuestieCorrections.SOD_ONLY then
            if not isSoD then
                values[k] = true
            else
                values[k] = nil
            end
        elseif v == QuestieCorrections.HIDE_SOD then
            if isSoD then
                values[k] = true
            else
                values[k] = nil
            end
        elseif v == QuestieCorrections.CLASSIC_AND_TBC then
            if isClassic or isTBC then
                values[k] = true
            else
                values[k] = nil
            end
        end
    end
    return values
end

do
    local type, assert = type, assert
    --- Add runtime overrides for the database
    ---@param override_table table<number, table<number, string|table|number>>
    ---@param new_overrides table<number, table<number, string|table|number>>
    local function addOverride(override_table, new_overrides)
        assert(type(override_table) == "table", "Override table must be a table!")
        assert(type(new_overrides) == "table", "New overrides must be a table!")
        for id, data in pairs(new_overrides) do
            assert(type(id) == "number", "Override id must be a number!")
            assert(type(data) == "table", "Override data must be a table!")
            -- If no override exist assign it
            if not override_table[id] then
                override_table[id] = data
            else
                -- Override already exists, merge the new data
                for key, value in pairs(data) do
                    override_table[id][key] = value
                end
            end
        end
    end

    function QuestieCorrections:MinimalInit() -- db already compiled

        -- Classic Era Corrections
        addOverride(QuestieDB.itemDataOverrides, QuestieItemFixes:LoadFactionFixes())
        addOverride(QuestieDB.npcDataOverrides, QuestieNPCFixes:LoadFactionFixes())
        addOverride(QuestieDB.objectDataOverrides, QuestieObjectFixes:LoadFactionFixes())
        addOverride(QuestieDB.questDataOverrides, QuestieQuestFixes:LoadFactionFixes())

        -- TBC Corrections
        if (Questie.IsTBC or Questie.IsWotlk) then
            if QuestieTBCItemFixes and QuestieTBCItemFixes.LoadFactionFixes then
                addOverride(QuestieDB.itemDataOverrides, QuestieTBCItemFixes:LoadFactionFixes())
            end
            if QuestieTBCNpcFixes and QuestieTBCNpcFixes.LoadFactionFixes then
                addOverride(QuestieDB.npcDataOverrides, QuestieTBCNpcFixes:LoadFactionFixes())
            end
            if QuestieTBCObjectFixes and QuestieTBCObjectFixes.LoadFactionFixes then
                addOverride(QuestieDB.objectDataOverrides, QuestieTBCObjectFixes:LoadFactionFixes())
            end
            if QuestieTBCQuestFixes and QuestieTBCQuestFixes.LoadFactionFixes then
                addOverride(QuestieDB.questDataOverrides, QuestieTBCQuestFixes:LoadFactionFixes())
            end
        end

        -- WOTLK Corrections
        if (Questie.IsWotlk) then
            if QuestieWotlkNpcFixes and QuestieWotlkNpcFixes.LoadFactionFixes then
                addOverride(QuestieDB.npcDataOverrides, QuestieWotlkNpcFixes:LoadFactionFixes())
            end
            if QuestieWotlkItemFixes and QuestieWotlkItemFixes.LoadFactionFixes then
                addOverride(QuestieDB.itemDataOverrides, QuestieWotlkItemFixes:LoadFactionFixes())
            end
            if QuestieWotlkObjectFixes and QuestieWotlkObjectFixes.LoadFactionFixes then
                addOverride(QuestieDB.objectDataOverrides, QuestieWotlkObjectFixes:LoadFactionFixes())
            end
        end

        -- Season of Discovery Corrections
        if Questie.IsSoD then
            addOverride(QuestieDB.questDataOverrides, SeasonOfDiscovery:LoadFactionQuestFixes())
        end

        QuestieCorrections.questItemBlacklist = filterExpansion(QuestieItemBlacklist:Load())
        QuestieCorrections.questNPCBlacklist = filterExpansion(QuestieNPCBlacklist:Load())
        QuestieCorrections.hiddenQuests = filterExpansion(QuestieQuestBlacklist:Load())

        -- TBC Quel Danas Blacklist
        if Questie.db.global.isleOfQuelDanasPhase == IsleOfQuelDanas.MAX_ISLE_OF_QUEL_DANAS_PHASES then
            for id, hide in pairs(IsleOfQuelDanas.quests[Questie.db.global.isleOfQuelDanasPhase]) do
                -- This has to be a nil-check, because the value could be false
                if (QuestieCorrections.hiddenQuests[id] == nil) then
                    QuestieCorrections.hiddenQuests[id] = hide
                end
            end
        end

        -- Wotlk Blacklist
        if (Questie.IsWotlk) then
            -- We only add blacklist if no blacklist entry for the quest already exists
            for id, hide in pairs(QuestieQuestBlacklist.LoadAutoBlacklistWotlk()) do
                -- This has to be a nil-check, because the value could be false
                if (QuestieCorrections.hiddenQuests[id] == nil) then
                    QuestieCorrections.hiddenQuests[id] = hide
                end
            end
        end

        -- Hardcore Blacklist
        if (Questie.IsHardcore) then
            for id, _ in pairs(HardcoreBlacklist:Load()) do
                QuestieCorrections.hiddenQuests[id] = true
            end
        end

        if QuestieCompat.Is335 then QuestieCompat.LoadBlacklists() end

        if Questie.db.profile.showEventQuests then
            C_Timer.After(1, function()
                 -- This is done with a delay because on startup the Blizzard API seems to be
                 -- very slow and therefore the date calculation in QuestieEvents isn't done
                 -- correctly.
                QuestieEvent:Load()
            end)
        end
    end
end

---@param databaseTableName string The name of the QuestieDB field that should be manipulated (e.g. "itemData", "questData")
---@param corrections table All corrections for the given databaseTableName (e.g. all quest corrections)
---@param reversedKeys table The reverted QuestieDB keys for the given databaseTableName (e.g. QuestieDB.questKeys)
---@param validationTables table Only used by the CI validation scripts to validate the corrections against the original database values and find irrelevant corrections
---@param noOverwrites true? Do not overwrite existing values
---@param noNewEntries true? Do not create new entries in the database
local _LoadCorrections = function(databaseTableName, corrections, reversedKeys, validationTables, noOverwrites, noNewEntries)
    for id, data in pairs(corrections) do
        for key, value in pairs(data) do
            -- Create the id if missing unless noNewEntries is set
            if not QuestieDB[databaseTableName][id] and not noNewEntries then
                QuestieDB[databaseTableName][id] = {}
            end
            if validationTables and QuestieDB[databaseTableName][id] then
                if value and QuestieLib.equals(QuestieDB[databaseTableName][id][key], value) and validationTables[databaseTableName][id] and
                    QuestieLib.equals(validationTables[databaseTableName][id][key], value) then
                    Questie:Warning("Correction of " ..
                                    databaseTableName .. " " .. tostring(id) .. "." .. reversedKeys[key] .. " matches base DB! Value:" .. tostring(value))
                end
            end
            if QuestieDB[databaseTableName][id] then
                if noOverwrites and QuestieDB[databaseTableName][id][key] == nil then
                    QuestieDB[databaseTableName][id][key] = value
                elseif not noOverwrites then
                    QuestieDB[databaseTableName][id][key] = value
                end
            end
        end
    end
end

---@param validationTables table? Only used by the CI validation scripts to validate the corrections against the original database values and find irrelevant corrections
function QuestieCorrections:Initialize(validationTables)
    QuestieQuestFixes:LoadMissingQuests()

    -- Classic Corrections
    _LoadCorrections("questData", QuestieClassicQuestReputationFixes:Load(), QuestieDB.questKeysReversed, validationTables)
    _LoadCorrections("questData", QuestieQuestFixes:Load(), QuestieDB.questKeysReversed, validationTables)
    _LoadCorrections("npcData", QuestieNPCFixes:Load(), QuestieDB.npcKeysReversed, validationTables)
    -- Epoch-specific Stormwind fixes for WotLK coordinates
    _LoadCorrections("npcData", QuestieEpochStormwindFixes:Load(), QuestieDB.npcKeysReversed, validationTables)
    -- Epoch-specific Elwynn Forest fixes for WotLK coordinates
    _LoadCorrections("npcData", QuestieEpochElwynnFixes:Load(), QuestieDB.npcKeysReversed, validationTables)
    _LoadCorrections("itemData", QuestieItemFixes:Load(), QuestieDB.itemKeysReversed, validationTables)
    _LoadCorrections("objectData", QuestieObjectFixes:Load(), QuestieDB.objectKeysReversed, validationTables)
    -- Epoch-specific Stormwind object fixes for WotLK coordinates
    _LoadCorrections("objectData", QuestieEpochStormwindObjectFixes:Load(), QuestieDB.objectKeysReversed, validationTables)

    if Questie.IsTBC or Questie.IsWotlk then
        if QuestieTBCQuestFixes and QuestieTBCQuestFixes.Load then
            _LoadCorrections("questData", QuestieTBCQuestFixes:Load(), QuestieDB.questKeysReversed, validationTables)
        end
        if QuestieTBCNpcFixes and QuestieTBCNpcFixes.Load then
            _LoadCorrections("npcData", QuestieTBCNpcFixes:Load(), QuestieDB.npcKeysReversed, validationTables)
        end
        if QuestieTBCItemFixes and QuestieTBCItemFixes.Load then
            _LoadCorrections("itemData", QuestieTBCItemFixes:Load(), QuestieDB.itemKeysReversed, validationTables)
        end
        if QuestieTBCObjectFixes and QuestieTBCObjectFixes.Load then
            _LoadCorrections("objectData", QuestieTBCObjectFixes:Load(), QuestieDB.objectKeysReversed, validationTables)
        end
    end

    if Questie.IsWotlk then
        if QuestieWotlkQuestFixes and QuestieWotlkQuestFixes.Load then
            _LoadCorrections("questData", QuestieWotlkQuestFixes:Load(), QuestieDB.questKeysReversed, validationTables)
        end
        if QuestieWotlkNpcFixes and QuestieWotlkNpcFixes.LoadAutomatics then
            _LoadCorrections("npcData", QuestieWotlkNpcFixes:LoadAutomatics(), QuestieDB.npcKeysReversed, validationTables)
        end
        if QuestieWotlkNpcFixes and QuestieWotlkNpcFixes.Load then
            _LoadCorrections("npcData", QuestieWotlkNpcFixes:Load(), QuestieDB.npcKeysReversed, validationTables)
        end
        if QuestieWotlkItemFixes and QuestieWotlkItemFixes.Load then
            _LoadCorrections("itemData", QuestieWotlkItemFixes:Load(), QuestieDB.itemKeysReversed, validationTables)
        end
        if QuestieWotlkObjectFixes and QuestieWotlkObjectFixes.Load then
            _LoadCorrections("objectData", QuestieWotlkObjectFixes:Load(), QuestieDB.objectKeysReversed, validationTables)
        end
    end

    if Questie.IsSoD then
        _LoadCorrections("questData", SeasonOfDiscovery:LoadBaseQuests(), QuestieDB.questKeysReversed, validationTables)
        _LoadCorrections("questData", SeasonOfDiscovery:LoadQuests(), QuestieDB.questKeysReversed, validationTables)
        _LoadCorrections("npcData", SeasonOfDiscovery:LoadBaseNPCs(), QuestieDB.npcKeysReversed, validationTables)
        _LoadCorrections("npcData", SeasonOfDiscovery:LoadNPCs(), QuestieDB.npcKeysReversed, validationTables)
        _LoadCorrections("itemData", SeasonOfDiscovery:LoadBaseItems(), QuestieDB.itemKeysReversed, validationTables)
        _LoadCorrections("itemData", SeasonOfDiscovery:LoadItems(), QuestieDB.itemKeysReversed, validationTables)
        _LoadCorrections("objectData", SeasonOfDiscovery:LoadBaseObjects(), QuestieDB.objectKeysReversed, validationTables)
        _LoadCorrections("objectData", SeasonOfDiscovery:LoadObjects(), QuestieDB.objectKeysReversed, validationTables)
    end

    --- Corrections that apply to all versions
    _LoadCorrections("itemData", QuestieItemStartFixes:LoadAutomaticQuestStarts(), QuestieDB.itemKeysReversed, validationTables, true, true)

    if QuestieCompat.Is335 then QuestieCompat.LoadCorrections(_LoadCorrections, validationTables) end

    local patchCount = 0
    for _, quest in pairs(QuestieDB.questData) do
        if (not quest[QuestieDB.questKeys.requiredRaces]) or quest[QuestieDB.questKeys.requiredRaces] == 0 then
            -- check against questgiver
            local canHorde = false
            local canAlliance = false
            local starts = quest[QuestieDB.questKeys.startedBy]
            if starts then
                starts = starts[1]
                if starts then
                    for _, id in pairs(starts) do
                        local npc = QuestieDB.npcData[id]
                        if npc then
                            local friendly = npc[QuestieDB.npcKeys.friendlyToFaction]
                            if friendly then
                                if friendly == "H" then
                                    canHorde = true
                                elseif friendly == "A" then
                                    canAlliance = true
                                elseif friendly == "AH" then
                                    canAlliance = true
                                    canHorde = true
                                end
                            end
                        end
                    end
                end
                if canAlliance ~= canHorde then
                    patchCount = patchCount + 1
                    if canAlliance then
                        quest[QuestieDB.questKeys.requiredRaces] = QuestieDB.raceKeys.ALL_ALLIANCE
                    else
                        quest[QuestieDB.questKeys.requiredRaces] = QuestieDB.raceKeys.ALL_HORDE
                    end
                end
            end
        end
    end

    QuestieCorrections:MinimalInit()

end

local WAYPOINT_MIN_DISTANCE = 1.5 -- todo: make this a config value maybe?
local ZONE_SCALES = {
    [ZoneDB.zoneIDs.STORMWIND_CITY] = 0.5,
    [ZoneDB.zoneIDs.IRONFORGE] = 0.5,
    [ZoneDB.zoneIDs.TELDRASSIL] = 0.5,

    [ZoneDB.zoneIDs.ORGRIMMAR] = 0.5,
    [ZoneDB.zoneIDs.THUNDER_BLUFF] = 0.5,
    [ZoneDB.zoneIDs.UNDERCITY] = 0.5,
}


local abs, sqrt = math.abs, math.sqrt
local function euclid(x, y, i, e)
    local xd = abs(x - i)
    local yd = abs(y - e)
    return sqrt(xd * xd + yd * yd)
end

function QuestieCorrections:OptimizeWaypoints(waypointData)
    local newWaypointZones = {}
    for zone, waypointList in pairs(waypointData) do
        local newWaypointList = {}
        if waypointList[1] and type(waypointList[1][1]) == "number" then
            waypointList = {waypointList} -- corrections support both {{x,y}, ...} and {{{x,y}, ...}, {{x,y}, ...}, ...}
        end
        for _, waypoints in pairs(waypointList) do
            -- apply RDP algorithm
            local minDist = WAYPOINT_MIN_DISTANCE * (ZONE_SCALES[zone] or 1)
            local newWaypoints = RamerDouglasPeucker(waypoints, 0.1, true)

            waypoints = newWaypoints
            newWaypoints = {}

            -- subdivide waypoints where needed
            -- We do this because the clickable area of waypoint lines can only be a square, so lines need to be broken up in some places
            local lastWay
            for _, way in pairs(waypoints) do
                if lastWay then
                    local dist = euclid(way[1], way[2], lastWay[1], lastWay[2])
                    if dist > minDist then
                        local divs = math.ceil(dist/minDist)
                        for i=1,divs do
                            local mul0 = i/divs
                            local mul1 = 1-mul0
                            newWaypoints[#newWaypoints+1] = {way[1] * mul0 + lastWay[1] * mul1, way[2] * mul0 + lastWay[2] * mul1}
                        end
                    else
                        newWaypoints[#newWaypoints+1] = way
                    end
                else
                    newWaypoints[#newWaypoints+1] = way
                end
                lastWay = way
            end
            newWaypointList[#newWaypointList+1] = newWaypoints
        end
        newWaypointZones[zone] = newWaypointList
    end
    return newWaypointZones
end

function QuestieCorrections:PreCompile() -- this happens only if we are about to compile the database. Run intensive preprocessing tasks here (like ramer-douglas-peucker)
    local waypointKey = QuestieDB.npcKeys["waypoints"]
    local npcData = QuestieDB.npcData

    local count = 0
    for id, data in pairs(npcData) do
        local way = data[waypointKey]
        if way then
            npcData[id][waypointKey] = QuestieCorrections:OptimizeWaypoints(way)
        end

        if count > 500 then -- 500 seems like a good number
            count = 0
            coroutine.yield()
        end
        count = count + 1
    end
end
