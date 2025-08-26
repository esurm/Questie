---@class QuestieDataCollector
local QuestieDataCollector = QuestieLoader:CreateModule("QuestieDataCollector")

---@type QuestieDB
local QuestieDB = QuestieLoader:ImportModule("QuestieDB")
---@type QuestieLib
local QuestieLib = QuestieLoader:ImportModule("QuestieLib")

-- SavedVariables table for collected data
-- This will be initialized after ADDON_LOADED event

local _activeTracking = {} -- Currently tracking these quest IDs
local _lastQuestGiver = nil -- Store last NPC interacted with
local _questAcceptCoords = {} -- Store coordinates when accepting quests
local _originalTooltipSettings = nil -- Store original tooltip settings for restoration
local _recentKills = {} -- Store recent combat kills for objective correlation
local _initialized = false -- Track if we've initialized
local _currentLootSource = nil -- Track what we're currently looting from
local _lastInteractedObject = nil -- Track last object we moused over

function QuestieDataCollector:Initialize()
    -- Prevent double initialization
    if _initialized then
        return
    end
    
    -- Only initialize if explicitly enabled
    if not Questie or not Questie.db or not Questie.db.profile.enableDataCollection then
        return
    end
    
    -- Create or ensure the global SavedVariable exists
    -- This happens AFTER SavedVariables are loaded
    if type(QuestieDataCollection) ~= "table" then
        _G.QuestieDataCollection = {}
    end
    if not QuestieDataCollection.quests then
        QuestieDataCollection.quests = {}
    end
    if not QuestieDataCollection.version then
        QuestieDataCollection.version = 1
    end
    if not QuestieDataCollection.sessionStart then
        QuestieDataCollection.sessionStart = date("%Y-%m-%d %H:%M:%S")
    end
    
    -- Count tracked quests
    local questCount = 0
    for _ in pairs(QuestieDataCollection.quests) do
        questCount = questCount + 1
    end
    
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[QuestieDataCollector] Initialized with " .. questCount .. " tracked quests|r", 0, 1, 0)
    
    -- Hook into events
    QuestieDataCollector:RegisterEvents()
    
    -- Enable tooltip IDs
    QuestieDataCollector:EnableTooltipIDs()
    
    _initialized = true
    
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[Questie Data Collector]|r DEVELOPER MODE ACTIVE - Tracking missing quest data", 1, 0, 0)
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00Use /qdc for commands. Disable in Advanced settings when done.|r", 1, 1, 0)
end

function QuestieDataCollector:RegisterEvents()
    -- Only create event frame if it doesn't exist
    if QuestieDataCollector.eventFrame then
        return -- Already registered
    end
    
    local eventFrame = CreateFrame("Frame")
    QuestieDataCollector.eventFrame = eventFrame
    
    -- Register all needed events
    eventFrame:RegisterEvent("QUEST_ACCEPTED")
    eventFrame:RegisterEvent("QUEST_TURNED_IN")
    eventFrame:RegisterEvent("QUEST_COMPLETE")
    eventFrame:RegisterEvent("QUEST_LOG_UPDATE")
    eventFrame:RegisterEvent("GOSSIP_SHOW")
    eventFrame:RegisterEvent("QUEST_DETAIL")
    eventFrame:RegisterEvent("CHAT_MSG_LOOT")
    eventFrame:RegisterEvent("UI_INFO_MESSAGE")
    eventFrame:RegisterEvent("ITEM_PUSH")
    eventFrame:RegisterEvent("LOOT_OPENED")
    eventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    eventFrame:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
    eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    eventFrame:RegisterEvent("LOOT_OPENED")
    eventFrame:RegisterEvent("ITEM_PUSH")
    
    eventFrame:SetScript("OnEvent", function(self, event, ...)
        QuestieDataCollector:HandleEvent(event, ...)
    end)
    
    -- Hook interact with target to capture NPC data
    hooksecurefunc("InteractUnit", function(unit)
        if UnitExists(unit) and not UnitIsPlayer(unit) then
            QuestieDataCollector:CaptureNPCData(unit)
        end
    end)
    
    -- Hook tooltip functions to capture IDs
    QuestieDataCollector:SetupTooltipHooks()
    
    -- Hook game object interactions
    QuestieDataCollector:SetupObjectTracking()
    
    -- Enable ID display in tooltips when data collection is active
    if Questie.db.profile.enableDataCollection then
        QuestieDataCollector:EnableTooltipIDs()
    end
end

function QuestieDataCollector:EnableTooltipIDs()
    -- Store original settings
    if not _originalTooltipSettings then
        _originalTooltipSettings = {
            itemID = Questie.db.profile.enableTooltipsItemID,
            npcID = Questie.db.profile.enableTooltipsNPCID,
            objectID = Questie.db.profile.enableTooltipsObjectID,
            questID = Questie.db.profile.enableTooltipsQuestID
        }
    end
    
    -- Enable all ID displays for data collection
    Questie.db.profile.enableTooltipsItemID = true
    Questie.db.profile.enableTooltipsNPCID = true
    Questie.db.profile.enableTooltipsObjectID = true
    Questie.db.profile.enableTooltipsQuestID = true
    
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00[DATA COLLECTOR] Tooltip IDs enabled for data collection|r", 1, 1, 0)
end

function QuestieDataCollector:RestoreTooltipIDs()
    -- Restore original settings
    if _originalTooltipSettings then
        Questie.db.profile.enableTooltipsItemID = _originalTooltipSettings.itemID
        Questie.db.profile.enableTooltipsNPCID = _originalTooltipSettings.npcID
        Questie.db.profile.enableTooltipsObjectID = _originalTooltipSettings.objectID
        Questie.db.profile.enableTooltipsQuestID = _originalTooltipSettings.questID
        _originalTooltipSettings = nil
    end
end

function QuestieDataCollector:SetupTooltipHooks()
    -- Hook GameTooltip to capture item/NPC info when shown
    GameTooltip:HookScript("OnTooltipSetItem", function(self)
        if not Questie.db.profile.enableDataCollection then return end
        
        local name, link = self:GetItem()
        if link then
            local itemId = tonumber(string.match(link, "item:(%d+)"))
            if itemId then
                QuestieDataCollector:CaptureItemData(itemId, name, link)
            end
        end
    end)
    
    GameTooltip:HookScript("OnTooltipSetUnit", function(self)
        if not Questie.db.profile.enableDataCollection then return end
        
        local name, unit = self:GetUnit()
        if unit and not UnitIsPlayer(unit) then
            local guid = UnitGUID(unit)
            if guid then
                local npcId = tonumber(string.match(guid, "Creature%-0%-%d+%-%d+%-%d+%-(%d+)%-")) or 
                              tonumber(string.match(guid, "Creature%-0%-%d+%-%d+%-(%d+)%-"))
                if npcId then
                    QuestieDataCollector:CaptureTooltipNPCData(npcId, name)
                end
            end
        end
    end)
    
    -- Hook container item tooltips (bags)
    hooksecurefunc(GameTooltip, "SetBagItem", function(self, bag, slot)
        if not Questie.db.profile.enableDataCollection then return end
        
        local texture, count, locked, quality, readable, lootable, link = GetContainerItemInfo(bag, slot)
        if link then
            local itemId = tonumber(string.match(link, "item:(%d+)"))
            local name = GetItemInfo(link)
            if itemId and name then
                QuestieDataCollector:CaptureItemData(itemId, name, link)
            end
        end
    end)
end

function QuestieDataCollector:CaptureItemData(itemId, name, link)
    -- Store item data for active quests
    for questId, _ in pairs(_activeTracking) do
        if QuestieDataCollection.quests[questId] then
            if not QuestieDataCollection.quests[questId].items then
                QuestieDataCollection.quests[questId].items = {}
            end
            
            -- Check if this item is a quest objective
            local questLogIndex = QuestieDataCollector:GetQuestLogIndexById(questId)
            if questLogIndex then
                SelectQuestLogEntry(questLogIndex)
                local numObjectives = GetNumQuestLeaderBoards(questLogIndex)
                
                for i = 1, numObjectives do
                    local text, objectiveType, finished = GetQuestLogLeaderBoard(i, questLogIndex)
                    if objectiveType == "item" and string.find(text, name) then
                        QuestieDataCollection.quests[questId].items[itemId] = {
                            name = name,
                            objectiveIndex = i,
                            link = link
                        }
                        
                        -- Update objective with item ID
                        if QuestieDataCollection.quests[questId].objectives[i] then
                            QuestieDataCollection.quests[questId].objectives[i].itemId = itemId
                            QuestieDataCollection.quests[questId].objectives[i].itemName = name
                        end
                    end
                end
            end
        end
    end
end

function QuestieDataCollector:CaptureTooltipNPCData(npcId, name)
    -- Store NPC data for active quests
    for questId, _ in pairs(_activeTracking) do
        if QuestieDataCollection.quests[questId] then
            if not QuestieDataCollection.quests[questId].npcs then
                QuestieDataCollection.quests[questId].npcs = {}
            end
            
            -- Store with current location
            local coords = QuestieDataCollector:GetPlayerCoords()
            QuestieDataCollection.quests[questId].npcs[npcId] = {
                name = name,
                coords = coords,
                zone = GetRealZoneText(),
                timestamp = time()
            }
        end
    end
end

function QuestieDataCollector:HandleEvent(event, ...)
    if event == "QUEST_ACCEPTED" then
        local questLogIndex, questId = ...
        -- In 3.3.5a, second param might be questId or nil
        if not questId or questId == 0 then
            questId = QuestieDataCollector:GetQuestIdFromLogIndex(questLogIndex)
        end
        QuestieDataCollector:OnQuestAccepted(questId)
        
    elseif event == "QUEST_TURNED_IN" then
        local questId = ...
        QuestieDataCollector:OnQuestTurnedIn(questId)
        
    elseif event == "QUEST_COMPLETE" then
        QuestieDataCollector:OnQuestComplete()
        
    elseif event == "GOSSIP_SHOW" or event == "QUEST_DETAIL" then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00[DEBUG] " .. event .. " event fired!|r", 1, 1, 0)
        QuestieDataCollector:CaptureNPCData("target")
        
    elseif event == "CHAT_MSG_LOOT" then
        local message = ...
        QuestieDataCollector:OnLootReceived(message)
        
    elseif event == "UI_INFO_MESSAGE" then
        local message = ...
        QuestieDataCollector:OnUIInfoMessage(message)
        
    elseif event == "QUEST_LOG_UPDATE" then
        QuestieDataCollector:OnQuestLogUpdate()
        
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        QuestieDataCollector:OnCombatLogEvent(...)
        
    elseif event == "UPDATE_MOUSEOVER_UNIT" then
        if UnitExists("mouseover") and not UnitIsPlayer("mouseover") then
            QuestieDataCollector:TrackMob("mouseover")
        end
        
    elseif event == "PLAYER_TARGET_CHANGED" then
        if UnitExists("target") and not UnitIsPlayer("target") and not UnitIsFriend("player", "target") then
            QuestieDataCollector:TrackMob("target")
        end
        
    elseif event == "LOOT_OPENED" then
        QuestieDataCollector:OnLootOpened()
        
    elseif event == "ITEM_PUSH" then
        local bagSlot, iconFileID = ...
        QuestieDataCollector:OnItemPush(bagSlot)
    end
end

function QuestieDataCollector:GetQuestIdFromLogIndex(index)
    local title, level, questTag, suggestedGroup, isHeader, isCollapsed, isComplete, isDaily, questId = GetQuestLogTitle(index)
    
    if questId and questId > 0 then
        return questId
    end
    
    -- Try to find quest ID by matching title in quest log
    for i = 1, GetNumQuestLogEntries() do
        local qTitle, qLevel, _, _, qIsHeader, _, _, _, qId = GetQuestLogTitle(i)
        if not qIsHeader and qTitle == title and qLevel == level then
            if qId and qId > 0 then
                return qId
            end
        end
    end
    
    return nil
end

function QuestieDataCollector:TrackMob(unit)
    if not UnitExists(unit) or UnitIsPlayer(unit) then return end
    
    local name = UnitName(unit)
    local guid = UnitGUID(unit)
    
    if guid and UnitCanAttack("player", unit) then
        -- Extract NPC ID using same method as quest givers
        local npcId = tonumber(guid:sub(6, 12), 16)
        
        if npcId then
            local coords = QuestieDataCollector:GetPlayerCoords()
            
            -- Check all active tracked quests
            for questId, _ in pairs(_activeTracking or {}) do
                local questData = QuestieDataCollection.quests[questId]
                if questData then
                    -- Store in the quest's npcs table
                    questData.npcs = questData.npcs or {}
                    
                    -- Only store each NPC once per quest
                    if not questData.npcs[npcId] then
                        questData.npcs[npcId] = {
                            name = name,
                            coords = coords,
                            zone = GetRealZoneText(),
                            subzone = GetSubZoneText(),
                            level = UnitLevel(unit),
                            timestamp = time()
                        }
                        
                        DEFAULT_CHAT_FRAME:AddMessage("|cFF888800[DATA] Tracked mob for quest " .. questId .. ": " .. name .. 
                            " (ID: " .. npcId .. ") at [" .. (coords.x or 0) .. ", " .. (coords.y or 0) .. "]|r", 0.5, 0.5, 0)
                    end
                    
                    -- Also check if this mob matches any objectives (more flexible matching)
                    for _, objective in ipairs(questData.objectives or {}) do
                        if objective.type == "monster" then
                            -- Try to match the mob name in the objective text
                            -- Remove common words like "slain", "killed", etc. for better matching
                            local cleanText = string.lower(objective.text or "")
                            local cleanName = string.lower(name)
                            
                            if string.find(cleanText, cleanName) or string.find(cleanText, string.gsub(cleanName, "s$", "")) then
                                -- Store mob location with the quest objective
                                objective.mobLocations = objective.mobLocations or {}
                                
                                -- Check if we already have this location
                                local alreadyTracked = false
                                for _, loc in ipairs(objective.mobLocations) do
                                    if loc.npcId == npcId then
                                        alreadyTracked = true
                                        break
                                    end
                                end
                                
                                if not alreadyTracked then
                                    table.insert(objective.mobLocations, {
                                        npcId = npcId,
                                        name = name,
                                        coords = coords,
                                        zone = GetRealZoneText(),
                                        subzone = GetSubZoneText(),
                                        level = UnitLevel(unit)
                                    })
                                    
                                    DEFAULT_CHAT_FRAME:AddMessage("|cFF00AA00[DATA] Linked " .. name .. " to objective: " .. objective.text .. "|r", 0, 0.7, 0)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

function QuestieDataCollector:CaptureNPCData(unit)
    if not UnitExists(unit) then 
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[DEBUG] Unit doesn't exist: " .. tostring(unit) .. "|r", 1, 0, 0)
        return 
    end
    
    if UnitIsPlayer(unit) then 
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[DEBUG] Unit is a player, not an NPC|r", 1, 0, 0)
        return 
    end
    
    local name = UnitName(unit)
    local guid = UnitGUID(unit)
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[DEBUG] Capturing NPC: " .. (name or "nil") .. " GUID: " .. (guid or "nil") .. "|r", 0, 1, 1)
    
    if guid then
        -- WoW 3.3.5 GUID format: 0xF13000085800126C
        -- Use same extraction as QuestieCompat.UnitGUID
        local npcId = tonumber(guid:sub(6, 12), 16)
        
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00[DEBUG] Extracted NPC ID: " .. (npcId or "nil") .. " from GUID: " .. guid .. "|r", 1, 1, 0)
        
        if npcId then
            local coords = QuestieDataCollector:GetPlayerCoords()
            _lastQuestGiver = {
                name = name,
                npcId = npcId,
                coords = coords,
                zone = GetRealZoneText(),
                subzone = GetSubZoneText(),
                timestamp = time()
            }
            
            -- Debug output to verify NPC capture
            if Questie.db.profile.enableDataCollection then
                DEFAULT_CHAT_FRAME:AddMessage("|cFFAAAA00[DATA] Captured NPC: " .. name .. " (ID: " .. npcId .. ") at [" .. 
                    (coords and coords.x or "?") .. ", " .. (coords and coords.y or "?") .. "]|r", 0.7, 0.7, 0.4)
            end
        end
    end
end

function QuestieDataCollector:GetPlayerCoords()
    -- Use Questie's coordinate system for better compatibility
    local QuestieCoords = QuestieLoader:ImportModule("QuestieCoords")
    if QuestieCoords and QuestieCoords.GetPlayerMapPosition then
        local position = QuestieCoords.GetPlayerMapPosition()
        if position and position.x and position.y and (position.x > 0 or position.y > 0) then
            return {x = math.floor(position.x * 1000) / 10, y = math.floor(position.y * 1000) / 10}
        end
    end
    
    -- Fallback to direct API if QuestieCoords not available
    local x, y = GetPlayerMapPosition("player")
    if x and y and (x > 0 or y > 0) then
        return {x = math.floor(x * 1000) / 10, y = math.floor(y * 1000) / 10}
    end
    
    -- Return approximate coordinates based on zone if map position fails
    return {x = 0, y = 0}
end

function QuestieDataCollector:OnQuestAccepted(questId)
    if not questId then return end
    
    -- Double-check that data collection is enabled
    if not Questie.db.profile.enableDataCollection then
        return
    end
    
    -- Ensure we're initialized
    if not QuestieDataCollection or not QuestieDataCollection.quests then
        QuestieDataCollector:Initialize()
    end
    
    -- Check if quest is in database
    local questData = QuestieDB:GetQuest(questId)
    local isMissing = not questData or (questData.name and string.find(questData.name, "%[Epoch%]"))
    
    if isMissing then
        -- ALERT! Missing quest detected!
        local questTitle = GetQuestLogTitle(QuestieDataCollector:GetQuestLogIndexById(questId))
        
        PlaySound("RaidWarning")
        DEFAULT_CHAT_FRAME:AddMessage("===========================================", 1, 0, 0)
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[DATA COLLECTOR] MISSING QUEST DETECTED!|r", 1, 0, 0)
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00Quest: " .. (questTitle or "Unknown") .. " (ID: " .. questId .. ")|r", 1, 1, 0)
        
        -- Initialize collection data for this quest
        if not QuestieDataCollection.quests[questId] then
            QuestieDataCollection.quests[questId] = {
                id = questId,
                name = questTitle,
                acceptTime = time(),
                level = nil,
                zone = GetRealZoneText(),
                objectives = {},
                items = {},
                npcs = {}
            }
        else
            -- Quest already exists, just update accept time and clear duplicate objectives
            QuestieDataCollection.quests[questId].acceptTime = time()
            -- Reset objectives to prevent duplicates
            QuestieDataCollection.quests[questId].objectives = {}
        end
        
        -- Capture quest giver data
        if _lastQuestGiver and (time() - _lastQuestGiver.timestamp < 5) then
            QuestieDataCollection.quests[questId].questGiver = _lastQuestGiver
            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00Quest Giver: " .. _lastQuestGiver.name .. " (ID: " .. _lastQuestGiver.npcId .. ")|r", 0, 1, 0)
            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00Location: " .. string.format("[%.1f, %.1f]", _lastQuestGiver.coords.x, _lastQuestGiver.coords.y) .. "|r", 0, 1, 0)
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000Quest Giver: NOT CAPTURED - Target the NPC!|r", 1, 0, 0)
        end
        
        -- Get quest details from log
        local questLogIndex = QuestieDataCollector:GetQuestLogIndexById(questId)
        if questLogIndex then
            SelectQuestLogEntry(questLogIndex)
            local _, level = GetQuestLogTitle(questLogIndex)
            QuestieDataCollection.quests[questId].level = level
            
            -- Get objectives
            local numObjectives = GetNumQuestLeaderBoards(questLogIndex)
            for i = 1, numObjectives do
                local text, objectiveType, finished = GetQuestLogLeaderBoard(i, questLogIndex)
                table.insert(QuestieDataCollection.quests[questId].objectives, {
                    text = text,
                    type = objectiveType,
                    index = i,
                    completed = finished
                })
            end
        end
        
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00NOW TRACKING THIS QUEST FOR DATA COLLECTION|r", 1, 1, 0)
        DEFAULT_CHAT_FRAME:AddMessage("===========================================", 1, 0, 0)
        
        _activeTracking[questId] = true
    end
end

function QuestieDataCollector:GetQuestLogIndexById(questId)
    for i = 1, GetNumQuestLogEntries() do
        local _, _, _, _, isHeader, _, _, _, qId = GetQuestLogTitle(i)
        if not isHeader then
            if qId == questId then
                return i
            end
        end
    end
    return nil
end

function QuestieDataCollector:OnQuestTurnedIn(questId)
    if not questId or not QuestieDataCollection.quests[questId] then return end
    
    -- Capture turn-in NPC
    if _lastQuestGiver and (time() - _lastQuestGiver.timestamp < 5) then
        QuestieDataCollection.quests[questId].turnInNpc = _lastQuestGiver
        
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[DATA COLLECTOR] Quest Turn-in Captured!|r", 0, 1, 0)
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00NPC: " .. _lastQuestGiver.name .. " (ID: " .. _lastQuestGiver.npcId .. ")|r", 0, 1, 0)
    end
    
    _activeTracking[questId] = nil
end

function QuestieDataCollector:OnQuestComplete()
    -- Capture the NPC we're turning in to
    QuestieDataCollector:CaptureNPCData("target")
end

function QuestieDataCollector:OnCombatLogEvent(...)
    local timestamp, eventType, _, sourceGUID, sourceName, _, _, destGUID, destName = ...
    
    -- Track when player kills something
    if eventType == "PARTY_KILL" or eventType == "UNIT_DIED" then
        if sourceGUID == UnitGUID("player") and destGUID then
            -- Extract NPC ID from GUID
            local npcId = tonumber(destGUID:sub(9, 12), 16)
            if npcId then
                -- Store recent kill for correlation with quest updates
                _recentKills = _recentKills or {}
                table.insert(_recentKills, {
                    npcId = npcId,
                    name = destName,
                    timestamp = time(),
                    coords = QuestieDataCollector:GetPlayerCoords(),
                    zone = GetRealZoneText(),
                    subzone = GetSubZoneText()
                })
                
                -- Keep only last 10 kills
                if #_recentKills > 10 then
                    table.remove(_recentKills, 1)
                end
            end
        end
    end
end

function QuestieDataCollector:OnQuestLogUpdate()
    -- Check all tracked quests for objective changes
    for questId, _ in pairs(_activeTracking) do
        if QuestieDataCollection.quests[questId] then
            local questLogIndex = QuestieDataCollector:GetQuestLogIndexById(questId)
            if questLogIndex then
                SelectQuestLogEntry(questLogIndex)
                local numObjectives = GetNumQuestLeaderBoards(questLogIndex)
                
                for i = 1, numObjectives do
                    local text, objectiveType, finished = GetQuestLogLeaderBoard(i, questLogIndex)
                    local objData = QuestieDataCollection.quests[questId].objectives[i]
                    
                    if objData and objData.lastText ~= text then
                        -- Objective has changed
                        objData.lastText = text
                        objData.type = objectiveType
                        
                        if not objData.progressLocations then
                            objData.progressLocations = {}
                        end
                        
                        local locData = {
                            coords = QuestieDataCollector:GetPlayerCoords(),
                            zone = GetRealZoneText(),
                            subzone = GetSubZoneText(),
                            text = text,
                            timestamp = time()
                        }
                        
                        -- Try to correlate with recent kills for monster objectives
                        if objectiveType == "monster" and _recentKills and #_recentKills > 0 then
                            -- Check most recent kill (within 2 seconds)
                            local recentKill = _recentKills[#_recentKills]
                            if time() - recentKill.timestamp <= 2 then
                                locData.npcId = recentKill.npcId
                                locData.npcName = recentKill.name
                                locData.action = "Killed " .. recentKill.name .. " (ID: " .. recentKill.npcId .. ")"
                                objData.objectiveType = "kill"
                                
                                -- Store NPC info for this objective
                                if not objData.npcs then
                                    objData.npcs = {}
                                end
                                objData.npcs[recentKill.npcId] = recentKill.name
                            end
                        elseif objectiveType == "item" then
                            objData.objectiveType = "item"
                            locData.action = "Item collection"
                            
                            -- Check if we have a target for source info
                            if UnitExists("target") then
                                local targetGUID = UnitGUID("target")
                                if targetGUID then
                                    local npcId = tonumber(targetGUID:sub(9, 12), 16)
                                    if npcId then
                                        locData.sourceNpcId = npcId
                                        locData.sourceNpcName = UnitName("target")
                                        locData.action = locData.action .. " from " .. UnitName("target") .. " (ID: " .. npcId .. ")"
                                    end
                                end
                            end
                        elseif objectiveType == "object" then
                            objData.objectiveType = "object"
                            locData.action = "Object interaction"
                        elseif objectiveType == "event" then
                            objData.objectiveType = "event"
                            locData.action = "Event/Exploration completed"
                            
                            -- Special handling for exploration/discovery objectives
                            if string.find(string.lower(text or ""), "explore") or 
                               string.find(string.lower(text or ""), "discover") or
                               string.find(string.lower(text or ""), "find") or
                               string.find(string.lower(text or ""), "reach") then
                                
                                -- Mark this as a discovery/exploration point
                                objData.discoveryPoint = {
                                    coords = locData.coords,
                                    zone = locData.zone,
                                    subzone = locData.subzone,
                                    completedText = text,
                                    timestamp = time()
                                }
                                
                                DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[DATA] DISCOVERY POINT CAPTURED!|r", 0, 1, 1)
                                DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF  Objective: " .. text .. "|r", 0, 1, 1)
                                DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF  Exact coords: [" .. locData.coords.x .. ", " .. locData.coords.y .. "]|r", 0, 1, 1)
                                DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF  Zone: " .. locData.zone .. (locData.subzone ~= "" and " (" .. locData.subzone .. ")" or "") .. "|r", 0, 1, 1)
                            end
                        end
                        
                        table.insert(objData.progressLocations, locData)
                        
                        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[DATA] Objective progress: " .. text .. "|r", 0, 1, 0)
                        if locData.action then
                            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00  Action: " .. locData.action .. "|r", 0, 1, 0)
                        end
                        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00  Location: [" .. locData.coords.x .. ", " .. locData.coords.y .. "] in " .. locData.zone .. "|r", 0, 1, 0)
                    end
                end
            end
        end
    end
end

function QuestieDataCollector:OnLootReceived(message)
    -- Parse loot message for item info
    local itemLink = string.match(message, "|c.-|Hitem:.-|h%[.-%]|h|r")
    if itemLink then
        local itemId = tonumber(string.match(itemLink, "item:(%d+):"))
        local itemName = string.match(itemLink, "%[(.-)%]")
        
        if itemId and itemName then
            -- Use current loot source if available (from LOOT_OPENED)
            if _currentLootSource and (time() - _currentLootSource.timestamp < 3) then
                -- We know exactly what we looted from
                for questId, _ in pairs(_activeTracking or {}) do
                    local questData = QuestieDataCollection.quests[questId]
                    if questData then
                        for objIndex, objective in ipairs(questData.objectives or {}) do
                            if objective.type == "item" and string.find(string.lower(objective.text or ""), string.lower(itemName)) then
                                -- Quest item received!
                                objective.itemLootData = objective.itemLootData or {}
                                
                                local lootEntry = {
                                    itemId = itemId,
                                    itemName = itemName,
                                    sourceType = _currentLootSource.type,
                                    sourceId = _currentLootSource.id,
                                    sourceName = _currentLootSource.name,
                                    coords = _currentLootSource.coords,
                                    zone = _currentLootSource.zone,
                                    subzone = _currentLootSource.subzone,
                                    timestamp = time()
                                }
                                
                                table.insert(objective.itemLootData, lootEntry)
                                
                                -- Update quest progress location
                                objective.progressLocations = objective.progressLocations or {}
                                table.insert(objective.progressLocations, {
                                    coords = _currentLootSource.coords,
                                    zone = _currentLootSource.zone,
                                    subzone = _currentLootSource.subzone,
                                    text = objective.text,
                                    action = "Looted " .. itemName .. " from " .. _currentLootSource.name,
                                    timestamp = time()
                                })
                                
                                if _currentLootSource.type == "mob" then
                                    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[DATA] Confirmed: '" .. itemName .. 
                                        "' (ID: " .. itemId .. ") from mob " .. _currentLootSource.name .. "|r", 0, 1, 0)
                                else
                                    DEFAULT_CHAT_FRAME:AddMessage("|cFF00AAFF[DATA] Confirmed: '" .. itemName .. 
                                        "' (ID: " .. itemId .. ") from object " .. _currentLootSource.name .. "|r", 0, 0.67, 1)
                                end
                            end
                        end
                    end
                end
            elseif _recentKills and #_recentKills > 0 then
                -- Fallback: Check recent kills
                local mostRecentKill = _recentKills[#_recentKills]
                if (time() - mostRecentKill.timestamp) < 5 then
                    -- Link this item drop to the mob
                    for questId, questData in pairs(QuestieDataCollection.quests or {}) do
                        for _, objective in ipairs(questData.objectives or {}) do
                            if objective.type == "item" and string.find(string.lower(objective.text or ""), string.lower(itemName)) then
                                objective.itemSources = objective.itemSources or {}
                                table.insert(objective.itemSources, {
                                    itemId = itemId,
                                    itemName = itemName,
                                    sourceNpcId = mostRecentKill.npcId,
                                    sourceNpcName = mostRecentKill.name,
                                    coords = mostRecentKill.coords,
                                    zone = mostRecentKill.zone,
                                    subzone = mostRecentKill.subzone
                                })
                                
                                DEFAULT_CHAT_FRAME:AddMessage("|cFF00AA00[DATA] Quest item '" .. itemName .. 
                                    "' likely from " .. mostRecentKill.name .. " (ID: " .. mostRecentKill.npcId .. ")|r", 0, 0.7, 0)
                            end
                        end
                    end
                end
            end
        end
    end
    
    -- Trigger quest log check when loot is received
    QuestieDataCollector:OnQuestLogUpdate()
end

function QuestieDataCollector:SetupObjectTracking()
    -- Track when player interacts with game objects
    _lastInteractedObject = nil
    
    -- Hook the tooltip to capture object names when mousing over
    GameTooltip:HookScript("OnShow", function(self)
        if Questie.db.profile.enableDataCollection then
            local name = GameTooltipTextLeft1:GetText()
            if name and not UnitExists("mouseover") then
                -- This might be a game object
                _lastInteractedObject = {
                    name = name,
                    coords = QuestieDataCollector:GetPlayerCoords(),
                    zone = GetRealZoneText(),
                    subzone = GetSubZoneText(),
                    timestamp = time()
                }
            end
        end
    end)
end

function QuestieDataCollector:OnLootOpened()
    local coords = QuestieDataCollector:GetPlayerCoords()
    local zone = GetRealZoneText()
    local subzone = GetSubZoneText()
    
    -- Determine loot source type
    local lootSourceType = nil
    local lootSourceId = nil
    local lootSourceName = nil
    
    -- Check if we're looting a corpse (mob)
    if UnitExists("target") and UnitIsDead("target") then
        lootSourceType = "mob"
        lootSourceName = UnitName("target")
        local guid = UnitGUID("target")
        if guid then
            lootSourceId = tonumber(guid:sub(6, 12), 16)
        end
        
        DEFAULT_CHAT_FRAME:AddMessage("|cFFAA8800[DATA] Looting mob: " .. lootSourceName .. 
            " (ID: " .. (lootSourceId or "unknown") .. ") at [" .. coords.x .. ", " .. coords.y .. "]|r", 0.67, 0.53, 0)
    else
        -- This is likely an object interaction
        lootSourceType = "object"
        -- Try to get object name from loot window
        local lootName = GetLootSourceInfo(1)
        if lootName then
            lootSourceName = lootName
        elseif _lastInteractedObject and (time() - _lastInteractedObject.timestamp < 2) then
            lootSourceName = _lastInteractedObject.name
        else
            lootSourceName = "Unknown Object"
        end
        
        DEFAULT_CHAT_FRAME:AddMessage("|cFF8888FF[DATA] Looting object: " .. lootSourceName .. 
            " at [" .. coords.x .. ", " .. coords.y .. "]|r", 0.5, 0.5, 1)
    end
    
    -- Store loot source for item tracking
    _currentLootSource = {
        type = lootSourceType,
        id = lootSourceId,
        name = lootSourceName,
        coords = coords,
        zone = zone,
        subzone = subzone,
        timestamp = time()
    }
    
    -- Check all loot items
    local numItems = GetNumLootItems()
    for i = 1, numItems do
        local lootIcon, lootName, lootQuantity, rarity, locked = GetLootSlotInfo(i)
        if lootName then
            local itemLink = GetLootSlotLink(i)
            if itemLink then
                local itemId = tonumber(string.match(itemLink, "item:(%d+):"))
                
                -- Check if this is a quest item
                for questId, _ in pairs(_activeTracking or {}) do
                    local questData = QuestieDataCollection.quests[questId]
                    if questData then
                        for objIndex, objective in ipairs(questData.objectives or {}) do
                            if objective.type == "item" and string.find(string.lower(objective.text or ""), string.lower(lootName)) then
                                -- This is a quest item!
                                objective.itemLootData = objective.itemLootData or {}
                                
                                local lootEntry = {
                                    itemId = itemId,
                                    itemName = lootName,
                                    sourceType = lootSourceType,  -- "mob" or "object"
                                    sourceId = lootSourceId,
                                    sourceName = lootSourceName,
                                    coords = coords,
                                    zone = zone,
                                    subzone = subzone,
                                    timestamp = time()
                                }
                                
                                table.insert(objective.itemLootData, lootEntry)
                                
                                -- Also store in quest's items table
                                questData.items = questData.items or {}
                                questData.items[itemId] = {
                                    name = lootName,
                                    objectiveIndex = objIndex,
                                    sources = questData.items[itemId] and questData.items[itemId].sources or {}
                                }
                                table.insert(questData.items[itemId].sources, lootEntry)
                                
                                if lootSourceType == "mob" then
                                    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[DATA] Quest item '" .. lootName .. 
                                        "' (ID: " .. itemId .. ") from mob: " .. lootSourceName .. "|r", 0, 1, 0)
                                else
                                    DEFAULT_CHAT_FRAME:AddMessage("|cFF00AAFF[DATA] Quest item '" .. lootName .. 
                                        "' (ID: " .. itemId .. ") from object: " .. lootSourceName .. "|r", 0, 0.67, 1)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

function QuestieDataCollector:OnItemPush(bagSlot)
    -- Track when quest items are received from objects
    if _lastInteractedObject and (time() - _lastInteractedObject.timestamp < 3) then
        -- Get item info from the bag slot
        C_Timer.After(0.1, function()
            for bag = 0, 4 do
                for slot = 1, GetContainerNumSlots(bag) do
                    local itemLink = GetContainerItemLink(bag, slot)
                    if itemLink then
                        local itemName = string.match(itemLink, "%[(.-)%]")
                        -- Check if this is a quest item
                        for questId, questData in pairs(QuestieDataCollection.quests or {}) do
                            for _, objective in ipairs(questData.objectives or {}) do
                                if objective.type == "item" and string.find(objective.text or "", itemName or "") then
                                    objective.objectSources = objective.objectSources or {}
                                    table.insert(objective.objectSources, {
                                        objectName = _lastInteractedObject.name,
                                        itemName = itemName,
                                        coords = _lastInteractedObject.coords,
                                        zone = _lastInteractedObject.zone,
                                        subzone = _lastInteractedObject.subzone
                                    })
                                    
                                    DEFAULT_CHAT_FRAME:AddMessage("|cFF00AAFF[DATA] Quest item '" .. itemName .. 
                                        "' obtained from object: " .. _lastInteractedObject.name .. "|r", 0, 0.7, 1)
                                end
                            end
                        end
                    end
                end
            end
        end)
    end
end

function QuestieDataCollector:OnUIInfoMessage(message)
    -- Capture exploration and discovery objectives
    for questId, _ in pairs(_activeTracking) do
        local questData = QuestieDataCollection.quests[questId]
        if questData then
            local coords = QuestieDataCollector:GetPlayerCoords()
            local zone = GetRealZoneText()
            local subzone = GetSubZoneText()
            
            -- Check if this message is related to quest progress
            -- Common patterns: "Explored X", "Discovered X", "X Explored", "X Discovered", location names
            if message and message ~= "" then
                -- Initialize explorations table if needed
                questData.explorations = questData.explorations or {}
                
                -- Store the exploration event
                local explorationData = {
                    message = message,
                    coords = coords,
                    zone = zone,
                    subzone = subzone,
                    timestamp = time()
                }
                table.insert(questData.explorations, explorationData)
                
                -- Also check objectives for exploration/event types
                for objIndex, objective in ipairs(questData.objectives or {}) do
                    if objective.type == "event" or objective.type == "object" or 
                       string.find(string.lower(objective.text or ""), "explore") or
                       string.find(string.lower(objective.text or ""), "discover") or
                       string.find(string.lower(objective.text or ""), "find") or
                       string.find(string.lower(objective.text or ""), "reach") then
                        
                        -- Store as progress location
                        objective.progressLocations = objective.progressLocations or {}
                        table.insert(objective.progressLocations, {
                            coords = coords,
                            zone = zone,
                            subzone = subzone,
                            text = objective.text,
                            action = "Discovery: " .. message,
                            timestamp = time()
                        })
                        
                        -- Store specific discovery coordinates
                        objective.discoveryCoords = objective.discoveryCoords or {}
                        table.insert(objective.discoveryCoords, {
                            coords = coords,
                            zone = zone,
                            subzone = subzone,
                            trigger = message,
                            timestamp = time()
                        })
                        
                        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[DATA] Discovery objective progress: " .. message .. "|r", 0, 1, 1)
                        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF  Location: [" .. coords.x .. ", " .. coords.y .. "] in " .. zone .. 
                            (subzone ~= "" and " (" .. subzone .. ")" or "") .. "|r", 0, 1, 1)
                    end
                end
                
                -- Always log exploration messages for Epoch quests
                if string.find(message, "Explored") or string.find(message, "Discovered") or 
                   string.find(message, "Reached") or string.find(message, "Found") then
                    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[DATA] Exploration captured: " .. message .. " at [" .. 
                        string.format("%.1f, %.1f", coords.x, coords.y) .. "]|r", 0, 1, 0)
                end
            end
        end
    end
end


-- Export function to generate database entry
function QuestieDataCollector:ExportQuest(questId)
    local data = QuestieDataCollection.quests[questId]
    if not data then
        DEFAULT_CHAT_FRAME:AddMessage("No data collected for quest " .. questId, 1, 0, 0)
        return
    end
    
    DEFAULT_CHAT_FRAME:AddMessage("=== QUEST DATA EXPORT FOR #" .. questId .. " ===", 0, 1, 1)
    DEFAULT_CHAT_FRAME:AddMessage("Quest: " .. (data.name or "Unknown"), 1, 1, 0)
    
    -- Quest giver info
    if data.questGiver then
        DEFAULT_CHAT_FRAME:AddMessage(string.format("Quest Giver: %s (ID: %d) at %.1f, %.1f in %s",
            data.questGiver.name, data.questGiver.npcId, 
            data.questGiver.coords.x, data.questGiver.coords.y,
            data.questGiver.zone or "Unknown"), 0, 1, 0)
    end
    
    -- Turn in info
    if data.turnInNpc then
        DEFAULT_CHAT_FRAME:AddMessage(string.format("Turn In: %s (ID: %d) at %.1f, %.1f in %s",
            data.turnInNpc.name, data.turnInNpc.npcId,
            data.turnInNpc.coords.x, data.turnInNpc.coords.y,
            data.turnInNpc.zone or "Unknown"), 0, 1, 0)
    end
    
    -- Objectives
    if data.objectives and #data.objectives > 0 then
        DEFAULT_CHAT_FRAME:AddMessage("Objectives:", 0, 1, 1)
        for _, obj in ipairs(data.objectives) do
            DEFAULT_CHAT_FRAME:AddMessage("  - " .. obj, 1, 1, 1)
        end
    end
    
    -- Mobs tracked
    if data.mobs and next(data.mobs) then
        DEFAULT_CHAT_FRAME:AddMessage("Mobs:", 0, 1, 1)
        for mobId, mobData in pairs(data.mobs) do
            DEFAULT_CHAT_FRAME:AddMessage(string.format("  %s (ID: %d) Level %s",
                mobData.name, mobId, mobData.level or "?"), 1, 1, 1)
            if mobData.coords and #mobData.coords > 0 then
                DEFAULT_CHAT_FRAME:AddMessage("    Locations:", 0.8, 0.8, 0.8)
                for i = 1, math.min(3, #mobData.coords) do
                    local coord = mobData.coords[i]
                    DEFAULT_CHAT_FRAME:AddMessage(string.format("      %.1f, %.1f", coord.x, coord.y), 0.8, 0.8, 0.8)
                end
                if #mobData.coords > 3 then
                    DEFAULT_CHAT_FRAME:AddMessage("      ... and " .. (#mobData.coords - 3) .. " more locations", 0.8, 0.8, 0.8)
                end
            end
        end
    end
    
    -- Items looted
    if data.items and next(data.items) then
        DEFAULT_CHAT_FRAME:AddMessage("Items:", 0, 1, 1)
        for itemId, itemData in pairs(data.items) do
            DEFAULT_CHAT_FRAME:AddMessage(string.format("  %s (ID: %d)",
                itemData.name, itemId), 1, 1, 1)
            if itemData.source then
                DEFAULT_CHAT_FRAME:AddMessage("    Source: " .. itemData.source, 0.8, 0.8, 0.8)
            end
        end
    end
    
    -- Objects interacted
    if data.objects and #data.objects > 0 then
        DEFAULT_CHAT_FRAME:AddMessage("Objects:", 0, 1, 1)
        for _, objData in ipairs(data.objects) do
            DEFAULT_CHAT_FRAME:AddMessage(string.format("  %s at %.1f, %.1f",
                objData.name, objData.coords.x, objData.coords.y), 1, 1, 1)
        end
    end
    
    DEFAULT_CHAT_FRAME:AddMessage("=== END EXPORT ===", 0, 1, 1)
    DEFAULT_CHAT_FRAME:AddMessage("Copy this data to create a GitHub issue", 0, 1, 0)
end

-- Slash commands
SLASH_QUESTIECOLLECTOR1 = "/qdc"
SLASH_QUESTIECOLLECTOR2 = "/questiecollector"
SlashCmdList["QUESTIECOLLECTOR"] = function(msg)
    local cmd, arg = strsplit(" ", msg)
    
    if cmd == "export" then
        local questId = tonumber(arg)
        if questId then
            QuestieDataCollector:ExportQuest(questId)
        else
            DEFAULT_CHAT_FRAME:AddMessage("Usage: /qdc export <questId>", 1, 0, 0)
        end
    elseif cmd == "show" then
        QuestieDataCollector:ShowTrackedQuests()
    elseif cmd == "clear" then
        QuestieDataCollection = {quests = {}, version = 1, sessionStart = date("%Y-%m-%d %H:%M:%S")}
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[DATA COLLECTOR] All quest data cleared.|r", 0, 1, 0)
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00Do /reload to save the cleared state.|r", 1, 1, 0)
    else
        DEFAULT_CHAT_FRAME:AddMessage("Questie Data Collector Commands:", 0, 1, 1)
        DEFAULT_CHAT_FRAME:AddMessage("/qdc show - Show all tracked quests", 1, 1, 1)
        DEFAULT_CHAT_FRAME:AddMessage("/qdc export <questId> - Export quest data for database", 1, 1, 1)
        DEFAULT_CHAT_FRAME:AddMessage("/qdc clear - Clear all collected data", 1, 1, 1)
    end
end

function QuestieDataCollector:ShowTrackedQuests()
    DEFAULT_CHAT_FRAME:AddMessage("=== Tracked Quest Data ===", 0, 1, 1)
    for questId, data in pairs(QuestieDataCollection.quests) do
        local status = _activeTracking[questId] and "|cFF00FF00[ACTIVE]|r" or "|cFFFFFF00[COMPLETE]|r"
        DEFAULT_CHAT_FRAME:AddMessage(string.format("%s %d: %s", status, questId, data.name or "Unknown"), 1, 1, 1)
        
        if data.questGiver then
            DEFAULT_CHAT_FRAME:AddMessage(string.format("  Giver: %s (%d) at [%.1f, %.1f]", 
                data.questGiver.name, data.questGiver.npcId, 
                data.questGiver.coords.x, data.questGiver.coords.y), 0.7, 0.7, 0.7)
        end
        
        if data.turnInNpc then
            DEFAULT_CHAT_FRAME:AddMessage(string.format("  Turn-in: %s (%d) at [%.1f, %.1f]", 
                data.turnInNpc.name, data.turnInNpc.npcId,
                data.turnInNpc.coords.x, data.turnInNpc.coords.y), 0.7, 0.7, 0.7)
        end
    end
end

function QuestieDataCollector:ShowPendingSubmissions()
    local pendingCount = 0
    local completedQuests = {}
    
    -- Find all completed quests (those with turn-in data or not in active tracking)
    for questId, data in pairs(QuestieDataCollection.quests or {}) do
        if not _activeTracking[questId] then
            pendingCount = pendingCount + 1
            table.insert(completedQuests, {id = questId, data = data})
        end
    end
    
    if pendingCount == 0 then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[QUESTIE] No completed quests pending submission.|r", 0, 1, 0)
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00Complete some [Epoch] quests to collect data!|r", 1, 1, 0)
        return
    end
    
    DEFAULT_CHAT_FRAME:AddMessage("===========================================", 0, 1, 1)
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[QUESTIE] Completed Quests Ready for Submission:|r", 0, 1, 0)
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00You have " .. pendingCount .. " quest(s) with collected data:|r", 1, 1, 0)
    DEFAULT_CHAT_FRAME:AddMessage("===========================================", 0, 1, 1)
    
    -- Sort by quest ID
    table.sort(completedQuests, function(a, b) return a.id < b.id end)
    
    -- Show each completed quest with a clickable link
    for _, quest in ipairs(completedQuests) do
        local questName = quest.data.name or "Unknown Quest"
        local questId = quest.id
        
        DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFFFFFF00%d: %s|r", questId, questName), 1, 1, 0)
        
        -- Show basic data summary
        local hasGiver = quest.data.questGiver and "✓" or "✗"
        local hasTurnIn = quest.data.turnInNpc and "✓" or "✗"
        local npcCount = 0
        local itemCount = 0
        
        if quest.data.npcs then
            for _ in pairs(quest.data.npcs) do npcCount = npcCount + 1 end
        end
        if quest.data.items then
            for _ in pairs(quest.data.items) do itemCount = itemCount + 1 end
        end
        
        DEFAULT_CHAT_FRAME:AddMessage(string.format("  Data: Giver[%s] Turn-in[%s] NPCs[%d] Items[%d]", 
            hasGiver, hasTurnIn, npcCount, itemCount), 0.7, 0.7, 0.7)
        
        -- Add clickable link
        DEFAULT_CHAT_FRAME:AddMessage("  " .. CreateQuestDataLink(questId, questName), 1, 1, 1)
    end
    
    DEFAULT_CHAT_FRAME:AddMessage("===========================================", 0, 1, 1)
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00Type '/qdc export <questId>' to export a specific quest|r", 1, 1, 0)
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00Or click the links above to open the export window|r", 1, 1, 0)
end

-- Community contribution popup
function QuestieDataCollector:ShowContributionPopup()
    StaticPopupDialogs["QUESTIE_CONTRIBUTE_DATA"] = {
        text = "|cFF00FF00Help Improve Questie for Project Epoch!|r\n\nWe've detected you're playing on Project Epoch. Many quests are missing from our database.\n\nWould you like to help the community by automatically collecting quest data? This will:\n\n• Alert you when accepting missing quests\n• Capture NPC locations and IDs\n• Enable tooltip IDs to show item/NPC/object IDs\n• Track where quest objectives are completed\n• Generate data for GitHub contributions\n\n|cFFFFFF00Your data will only be saved locally.|r",
        button1 = "Yes, I'll Help!",
        button2 = "No Thanks",
        OnAccept = function()
            Questie.db.profile.enableDataCollection = true
            Questie.db.profile.dataCollectionPrompted = true
            QuestieDataCollector:Initialize()
            QuestieDataCollector:EnableTooltipIDs()
            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[Questie] Thank you for contributing! Data collection is now active.|r", 0, 1, 0)
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00Tooltip IDs have been enabled to help with data collection.|r", 1, 1, 0)
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00When you complete a missing quest, we'll show you the data to submit.|r", 1, 1, 0)
        end,
        OnCancel = function()
            Questie.db.profile.dataCollectionPrompted = true
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00[Questie] Data collection disabled. You can enable it later in Advanced settings.|r", 1, 1, 0)
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = false,
        preferredIndex = 3,
    }
    StaticPopup_Show("QUESTIE_CONTRIBUTE_DATA")
end

-- Export window for completed quests
function QuestieDataCollector:ShowExportWindow(questId)
    local data = QuestieDataCollection.quests[questId]
    if not data then return end
    
    -- Create frame if it doesn't exist
    if not QuestieDataCollectorExportFrame then
        local f = CreateFrame("Frame", "QuestieDataCollectorExportFrame", UIParent)
        f:SetFrameStrata("DIALOG")
        f:SetWidth(600)
        f:SetHeight(400)
        f:SetPoint("CENTER")
        
        -- Use Questie's frame style
        f:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 32, edgeSize = 32,
            insets = { left = 11, right = 12, top = 12, bottom = 11 }
        })
        
        -- Title
        local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOP", 0, -20)
        title:SetText("|cFF00FF00Quest Data Ready for Submission!|r")
        f.title = title
        
        -- Quest name
        local questName = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        questName:SetPoint("TOP", title, "BOTTOM", 0, -10)
        f.questName = questName
        
        -- Instructions
        local instructions = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        instructions:SetPoint("TOP", questName, "BOTTOM", 0, -10)
        instructions:SetText("Copy this data and create an issue at: github.com/trav346/Questie/issues")
        instructions:SetTextColor(1, 1, 0)
        
        -- Scroll frame for data
        local scrollFrame = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
        scrollFrame:SetPoint("TOPLEFT", 20, -80)
        scrollFrame:SetPoint("BOTTOMRIGHT", -40, 50)
        
        local editBox = CreateFrame("EditBox", nil, scrollFrame)
        editBox:SetMultiLine(true)
        editBox:SetFontObject(ChatFontNormal)
        editBox:SetWidth(540)
        editBox:SetAutoFocus(false)
        editBox:SetScript("OnEscapePressed", function() f:Hide() end)
        scrollFrame:SetScrollChild(editBox)
        f.editBox = editBox
        
        -- Copy button
        local copyButton = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        copyButton:SetPoint("BOTTOMLEFT", 40, 20)
        copyButton:SetWidth(120)
        copyButton:SetHeight(25)
        copyButton:SetText("Select All")
        copyButton:SetScript("OnClick", function()
            editBox:SetFocus()
            editBox:HighlightText()
        end)
        
        -- Submit & Clear button
        local submitButton = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        submitButton:SetPoint("BOTTOM", 0, 20)
        submitButton:SetWidth(180)
        submitButton:SetHeight(25)
        submitButton:SetText("Submitted to GitHub")
        submitButton:SetScript("OnClick", function()
            -- Clear this quest's data
            local questId = f.currentQuestId
            if questId and QuestieDataCollection.quests[questId] then
                QuestieDataCollection.quests[questId] = nil
                DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[DATA COLLECTOR] Thank you for contributing!|r", 0, 1, 0)
                DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00Quest " .. questId .. " data cleared from local storage.|r", 0, 1, 0)
                DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00Remember to /reload to save changes.|r", 1, 1, 0)
            end
            f:Hide()
        end)
        f.submitButton = submitButton
        
        -- Keep button (close without clearing)
        local keepButton = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        keepButton:SetPoint("BOTTOMRIGHT", -40, 20)
        keepButton:SetWidth(120)
        keepButton:SetHeight(25)
        keepButton:SetText("Keep Data")
        keepButton:SetScript("OnClick", function() f:Hide() end)
        
        -- Close button
        local closeButton = CreateFrame("Button", nil, f, "UIPanelCloseButton")
        closeButton:SetPoint("TOPRIGHT", -5, -5)
        closeButton:SetScript("OnClick", function() f:Hide() end)
        
        f:Hide()
    end
    
    -- Generate export data
    local exportText = QuestieDataCollector:GenerateExportText(questId, data)
    
    -- Update and show frame
    QuestieDataCollectorExportFrame.questName:SetText("Quest: " .. (data.name or "Unknown") .. " (ID: " .. questId .. ")")
    QuestieDataCollectorExportFrame.editBox:SetText(exportText)
    QuestieDataCollectorExportFrame:Show()
end

function QuestieDataCollector:GenerateExportText(questId, data)
    local text = "=== HOW TO SUBMIT THIS DATA ===\n"
    text = text .. "1. Select all text in this window (click 'Select All' button)\n"
    text = text .. "2. Copy it (Ctrl+C)\n"
    text = text .. "3. Go to: github.com/trav346/Questie/issues\n"
    text = text .. "4. Click 'New Issue'\n"
    text = text .. "5. Title: 'Missing Quest: " .. (data.name or "Unknown") .. " (" .. questId .. ")'\n"
    text = text .. "6. Paste this entire text in the description\n"
    text = text .. "7. Click 'Submit new issue'\n\n"
    text = text .. "=== MISSING QUEST DATA FOR QUESTIE ===\n\n"
    text = text .. "Quest ID: " .. questId .. "\n"
    text = text .. "Quest Name: " .. (data.name or "Unknown") .. "\n"
    text = text .. "Level: " .. (data.level or "Unknown") .. "\n"
    text = text .. "Zone: " .. (data.zone or "Unknown") .. "\n\n"
    
    if data.questGiver then
        text = text .. "QUEST GIVER:\n"
        text = text .. "  NPC: " .. data.questGiver.name .. " (ID: " .. data.questGiver.npcId .. ")\n"
        text = text .. "  Location: [" .. data.questGiver.coords.x .. ", " .. data.questGiver.coords.y .. "]\n"
        text = text .. "  Zone: " .. data.questGiver.zone .. "\n\n"
    end
    
    if data.objectives and #data.objectives > 0 then
        text = text .. "OBJECTIVES:\n"
        for i, obj in ipairs(data.objectives) do
            text = text .. "  " .. i .. ". " .. obj.text .. " (" .. (obj.type or "unknown") .. ")\n"
            
            -- Show item IDs if collected
            if obj.itemId then
                text = text .. "     Item: " .. obj.itemName .. " (ID: " .. obj.itemId .. ")\n"
            end
            
            -- Show NPC IDs for kill objectives
            if obj.npcs then
                text = text .. "     NPCs: "
                for npcId, npcName in pairs(obj.npcs) do
                    text = text .. npcName .. " (ID: " .. npcId .. ") "
                end
                text = text .. "\n"
            end
            
            -- Show progress locations
            if obj.progressLocations and #obj.progressLocations > 0 then
                text = text .. "     Progress locations:\n"
                for _, loc in ipairs(obj.progressLocations) do
                    text = text .. "       - [" .. loc.coords.x .. ", " .. loc.coords.y .. "] in " .. loc.zone
                    if loc.action then
                        text = text .. " - " .. loc.action
                    end
                    text = text .. "\n"
                end
            end
        end
        text = text .. "\n"
    end
    
    -- Add collected NPCs section
    if data.npcs then
        text = text .. "NPCS ENCOUNTERED:\n"
        for npcId, npcInfo in pairs(data.npcs) do
            text = text .. "  " .. npcInfo.name .. " (ID: " .. npcId .. ")"
            if npcInfo.coords then
                text = text .. " at [" .. npcInfo.coords.x .. ", " .. npcInfo.coords.y .. "] in " .. npcInfo.zone
            end
            text = text .. "\n"
        end
        text = text .. "\n"
    end
    
    -- Add collected items section with detailed loot sources
    if data.items then
        text = text .. "ITEMS COLLECTED:\n"
        for itemId, itemInfo in pairs(data.items) do
            text = text .. "  " .. itemInfo.name .. " (ID: " .. itemId .. ")"
            if itemInfo.objectiveIndex then
                text = text .. " - Objective #" .. itemInfo.objectiveIndex
            end
            text = text .. "\n"
            
            -- Show loot sources for this item
            if itemInfo.sources and #itemInfo.sources > 0 then
                text = text .. "    Sources:\n"
                for _, source in ipairs(itemInfo.sources) do
                    if source.sourceType == "mob" then
                        text = text .. "      - Mob: " .. source.sourceName
                        if source.sourceId then
                            text = text .. " (ID: " .. source.sourceId .. ")"
                        end
                    else
                        text = text .. "      - Object: " .. source.sourceName
                    end
                    text = text .. " at [" .. source.coords.x .. ", " .. source.coords.y .. "] in " .. source.zone .. "\n"
                end
            end
        end
        text = text .. "\n"
    end
    
    -- Add detailed loot data from objectives
    local hasLootData = false
    for _, obj in ipairs(data.objectives or {}) do
        if obj.itemLootData and #obj.itemLootData > 0 then
            if not hasLootData then
                text = text .. "DETAILED LOOT DATA:\n"
                hasLootData = true
            end
            text = text .. "  Objective: " .. (obj.text or "Unknown") .. "\n"
            for _, loot in ipairs(obj.itemLootData) do
                text = text .. "    - " .. loot.itemName .. " (ID: " .. loot.itemId .. ")\n"
                if loot.sourceType == "mob" then
                    text = text .. "      From mob: " .. loot.sourceName
                    if loot.sourceId then
                        text = text .. " (ID: " .. loot.sourceId .. ")"
                    end
                    text = text .. " [Sack icon]\n"
                else
                    text = text .. "      From object: " .. loot.sourceName .. " [Cog icon]\n"
                end
                text = text .. "      Location: [" .. loot.coords.x .. ", " .. loot.coords.y .. "] in " .. loot.zone .. "\n"
            end
        end
    end
    if hasLootData then
        text = text .. "\n"
    end
    
    if data.turnInNpc then
        text = text .. "TURN-IN NPC:\n"
        text = text .. "  NPC: " .. data.turnInNpc.name .. " (ID: " .. data.turnInNpc.npcId .. ")\n"
        text = text .. "  Location: [" .. data.turnInNpc.coords.x .. ", " .. data.turnInNpc.coords.y .. "]\n"
        text = text .. "  Zone: " .. data.turnInNpc.zone .. "\n\n"
    end
    
    text = text .. "DATABASE ENTRIES:\n"
    text = text .. "-- Add to epochQuestDB.lua:\n"
    
    local questGiver = data.questGiver and "{{" .. data.questGiver.npcId .. "}}" or "nil"
    local turnIn = data.turnInNpc and "{{" .. data.turnInNpc.npcId .. "}}" or "nil"
    
    text = text .. string.format('[%d] = {"%s",%s,%s,nil,%d,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,85,nil,nil,nil,nil,nil,nil,0,nil,nil,nil,nil,nil,nil},\n\n',
        questId, data.name or "Unknown", questGiver, turnIn, data.level or 1)
    
    if data.questGiver then
        text = text .. "-- Add to epochNpcDB.lua:\n"
        text = text .. string.format('[%d] = {"%s",nil,nil,%d,%d,0,{[85]={{%.1f,%.1f}}},nil,85,{%d},nil,nil,nil,nil,0},\n',
            data.questGiver.npcId, data.questGiver.name, data.level or 1, data.level or 1,
            data.questGiver.coords.x, data.questGiver.coords.y, questId)
    end
    
    if data.turnInNpc and (not data.questGiver or data.turnInNpc.npcId ~= data.questGiver.npcId) then
        text = text .. string.format('[%d] = {"%s",nil,nil,%d,%d,0,{[85]={{%.1f,%.1f}}},nil,85,nil,{%d},nil,nil,nil,0},\n',
            data.turnInNpc.npcId, data.turnInNpc.name, data.level or 1, data.level or 1,
            data.turnInNpc.coords.x, data.turnInNpc.coords.y, questId)
    end
    
    return text
end

-- Create clickable hyperlink for quest data submission
local function CreateQuestDataLink(questId, questName)
    local linkText = "|cFF00FF00|Hquestiedata:" .. questId .. "|h[Click here to submit quest data for: " .. (questName or "Quest " .. questId) .. "]|h|r"
    return linkText
end

-- Hook for custom hyperlink handling
local originalSetItemRef = SetItemRef
SetItemRef = function(link, text, button)
    if string.sub(link, 1, 11) == "questiedata" then
        local questId = tonumber(string.sub(link, 13))
        if questId then
            QuestieDataCollector:ShowExportWindow(questId)
        end
    else
        originalSetItemRef(link, text, button)
    end
end

-- Modified turn-in handler to show export window
local originalOnQuestTurnedIn = QuestieDataCollector.OnQuestTurnedIn
function QuestieDataCollector:OnQuestTurnedIn(questId)
    originalOnQuestTurnedIn(self, questId)
    
    -- If this was a tracked quest and data collection is enabled
    if questId and QuestieDataCollection.quests[questId] and Questie.db.profile.enableDataCollection then
        local questData = QuestieDataCollection.quests[questId]
        local questName = questData.name or "Unknown Quest"
        
        -- Play achievement sound for quest completion
        PlaySound("ACHIEVEMENT_EARNED")
        
        -- Show prominent notification
        RaidNotice_AddMessage(RaidWarningFrame, "|cFF00FF00Missing Quest Completed!|r", ChatTypeInfo["RAID_WARNING"])
        
        -- Print clickable link in chat
        DEFAULT_CHAT_FRAME:AddMessage("===========================================", 0, 1, 1)
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[QUESTIE] Congratulations! You completed a missing quest!|r", 0, 1, 0)
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00Quest: " .. questName .. " (ID: " .. questId .. ")|r", 1, 1, 0)
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00Your data has been collected and is ready for submission.|r", 1, 1, 0)
        DEFAULT_CHAT_FRAME:AddMessage(CreateQuestDataLink(questId, questName), 1, 1, 1)
        DEFAULT_CHAT_FRAME:AddMessage("===========================================", 0, 1, 1)
        
        -- Auto-show export window after short delay
        C_Timer.After(2, function()
            QuestieDataCollector:ShowExportWindow(questId)
        end)
    end
end

-- Auto-initialize on first load if enabled
local autoInitFrame = CreateFrame("Frame")
autoInitFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
autoInitFrame:SetScript("OnEvent", function(self, event, isInitialLogin, isReloadingUi)
    if event == "PLAYER_ENTERING_WORLD" then
        self:UnregisterEvent("PLAYER_ENTERING_WORLD")
        -- Delay to ensure SavedVariables are loaded
        C_Timer.After(3, function()
            if Questie and Questie.db and Questie.db.profile.enableDataCollection then
                if not _initialized then
                    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00[DATA COLLECTOR] Auto-initializing after login (enableDataCollection = true)|r", 1, 1, 0)
                    QuestieDataCollector:Initialize()
                else
                    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[DATA COLLECTOR] Already initialized|r", 0, 1, 0)
                end
            else
                if not Questie then
                    DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[DATA COLLECTOR] Questie not found|r", 1, 0, 0)
                elseif not Questie.db then
                    DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[DATA COLLECTOR] Questie.db not found|r", 1, 0, 0)
                elseif not Questie.db.profile.enableDataCollection then
                    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00[DATA COLLECTOR] Not enabled in profile|r", 1, 1, 0)
                end
            end
        end)
    end
end)

-- Register slash commands for debugging and control
SLASH_QUESTIEDATACOLLECTOR1 = "/qdc"
SlashCmdList["QUESTIEDATACOLLECTOR"] = function(msg)
    local cmd = string.lower(msg)
    
    if cmd == "enable" then
        Questie.db.profile.enableDataCollection = true
        Questie.db.profile.dataCollectionPrompted = true
        QuestieDataCollector:Initialize()
        QuestieDataCollector:EnableTooltipIDs()
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[DATA COLLECTOR] ENABLED!|r", 0, 1, 0)
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00Abandon and re-accept quests to collect data|r", 1, 1, 0)
        
    elseif cmd == "disable" then
        Questie.db.profile.enableDataCollection = false
        QuestieDataCollector:RestoreTooltipIDs()
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[DATA COLLECTOR] DISABLED|r", 1, 0, 0)
        
    elseif cmd == "status" then
        DEFAULT_CHAT_FRAME:AddMessage("=== DATA COLLECTOR STATUS ===", 0, 1, 1)
        if Questie.db.profile.enableDataCollection then
            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00Status: ENABLED|r", 0, 1, 0)
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000Status: DISABLED|r", 1, 0, 0)
        end
        
        if QuestieDataCollection and QuestieDataCollection.quests then
            local count = 0
            for _ in pairs(QuestieDataCollection.quests) do count = count + 1 end
            DEFAULT_CHAT_FRAME:AddMessage("Tracked quests: " .. count, 1, 1, 1)
        else
            DEFAULT_CHAT_FRAME:AddMessage("No data collected yet", 1, 1, 0)
        end
        
    elseif cmd == "test" then
        -- Force test with current target quest
        DEFAULT_CHAT_FRAME:AddMessage("Testing with quest 26926...", 0, 1, 1)
        QuestieDataCollector:OnQuestAccepted(26926)
        
    elseif cmd == "show" then
        QuestieDataCollector:ShowTrackedQuests()
        
    elseif cmd == "pending" or cmd == "list" then
        QuestieDataCollector:ShowPendingSubmissions()
        
    elseif string.sub(cmd, 1, 6) == "export" then
        local questId = tonumber(string.sub(cmd, 8))
        if questId then
            QuestieDataCollector:ShowExportWindow(questId)
        end
        
    elseif cmd == "clear" then
        QuestieDataCollection = {quests = {}, version = 1, sessionStart = date("%Y-%m-%d %H:%M:%S")}
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[DATA COLLECTOR] All quest data cleared.|r", 0, 1, 0)
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00Do /reload to save the cleared state.|r", 1, 1, 0)
        
    elseif cmd == "debug" then
        DEFAULT_CHAT_FRAME:AddMessage("QuestieDataCollection table:", 0, 1, 1)
        if QuestieDataCollection then
            DEFAULT_CHAT_FRAME:AddMessage("  Exists: YES", 0, 1, 0)
            DEFAULT_CHAT_FRAME:AddMessage("  Type: " .. type(QuestieDataCollection), 1, 1, 1)
            if QuestieDataCollection.quests then
                local count = 0
                for k,v in pairs(QuestieDataCollection.quests) do 
                    count = count + 1
                    DEFAULT_CHAT_FRAME:AddMessage("    Quest " .. k .. ": " .. (v.name or "Unknown"), 1, 1, 1)
                end
                DEFAULT_CHAT_FRAME:AddMessage("  Total quests: " .. count, 1, 1, 1)
            end
        else
            DEFAULT_CHAT_FRAME:AddMessage("  Exists: NO", 1, 0, 0)
        end
        
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF=== QUESTIE DATA COLLECTOR ===|r", 0, 1, 1)
        DEFAULT_CHAT_FRAME:AddMessage("/qdc enable - Enable data collection", 1, 1, 1)
        DEFAULT_CHAT_FRAME:AddMessage("/qdc disable - Disable data collection", 1, 1, 1)
        DEFAULT_CHAT_FRAME:AddMessage("/qdc status - Check current status", 1, 1, 1)
        DEFAULT_CHAT_FRAME:AddMessage("/qdc pending - Show completed quests ready for submission", 1, 1, 1)
        DEFAULT_CHAT_FRAME:AddMessage("/qdc show - Show all tracked quests", 1, 1, 1)
        DEFAULT_CHAT_FRAME:AddMessage("/qdc export <id> - Export specific quest data", 1, 1, 1)
        DEFAULT_CHAT_FRAME:AddMessage("/qdc clear - Clear all data", 1, 1, 1)
        DEFAULT_CHAT_FRAME:AddMessage("/qdc debug - Debug SavedVariables", 1, 1, 1)
    end
end

return QuestieDataCollector