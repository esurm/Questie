---@class QuestEventHandler
local QuestEventHandler = QuestieLoader:CreateModule("QuestEventHandler")
---@class QuestEventHandlerPrivate
local _QuestEventHandler = QuestEventHandler.private

local _QuestLogUpdateQueue = {} -- Helper module
local questLogUpdateQueue = {}  -- The actual queue

-- Track recently accepted database quests for forced tracker updates
-- No longer needed since we use direct tracker integration
-- local recentlyAcceptedDatabaseQuests = {}

-- Import Questie for debug logging
local Questie = _G.Questie

---@type QuestEventHandlerPrivate
QuestEventHandler.private = QuestEventHandler.private or {}
---@type QuestLogCache
local QuestLogCache = QuestieLoader:ImportModule("QuestLogCache")
---@type QuestieQuest
local QuestieQuest = QuestieLoader:ImportModule("QuestieQuest")
---@type QuestieJourney
local QuestieJourney = QuestieLoader:ImportModule("QuestieJourney")
---@type QuestieNameplate
local QuestieNameplate = QuestieLoader:ImportModule("QuestieNameplate")
---@type QuestieLib
local QuestieLib = QuestieLoader:ImportModule("QuestieLib")
---@type QuestieDB
local QuestieDB = QuestieLoader:ImportModule("QuestieDB")
---@type QuestieAnnounce
local QuestieAnnounce = QuestieLoader:ImportModule("QuestieAnnounce")
---@type IsleOfQuelDanas
local IsleOfQuelDanas = QuestieLoader:ImportModule("IsleOfQuelDanas")
---@type QuestieCombatQueue
local QuestieCombatQueue = QuestieLoader:ImportModule("QuestieCombatQueue")
---@type QuestieTracker
local QuestieTracker = QuestieLoader:ImportModule("QuestieTracker")
---@type QuestiePlayer
local QuestiePlayer = QuestieLoader:ImportModule("QuestiePlayer")
---@type l10n
local l10n = QuestieLoader:ImportModule("l10n")

--- COMPATIBILITY ---
local C_Timer = QuestieCompat.C_Timer
local GetQuestLogTitle = QuestieCompat.GetQuestLogTitle
local GetItemInfo = QuestieCompat.GetItemInfo
-- GetSubZoneText is a standard WoW API, available globally
-- SelectQuestLogEntry and GetQuestLogSelection are standard WoW APIs
-- GetQuestDifficultyColor is a standard WoW API, available globally

local tableRemove = table.remove

local QUEST_LOG_STATES = {
    QUEST_ACCEPTED = "QUEST_ACCEPTED",
    QUEST_TURNED_IN = "QUEST_TURNED_IN",
    QUEST_REMOVED = "QUEST_REMOVED",
    QUEST_ABANDONED = "QUEST_ABANDONED"
}

local eventFrame = CreateFrame("Frame", "QuestieQuestEventFrame")
local questLog = {}
local questLogUpdateQueueSize = 1
local skipNextUQLCEvent = false
local doFullQuestLogScan = false
local deletedQuestItem = false

--- Registers all events that are required for questing (accepting, removing, objective updates, ...)
function QuestEventHandler:RegisterEvents()
    Questie:Debug(Questie.DEBUG_DEVELOP, "[Quest Event] RegisterEvents")
    eventFrame:RegisterEvent("QUEST_ACCEPTED")
    eventFrame:RegisterEvent("QUEST_TURNED_IN")
    eventFrame:RegisterEvent("QUEST_REMOVED")
    eventFrame:RegisterEvent("QUEST_LOG_UPDATE")
    eventFrame:RegisterEvent("QUEST_WATCH_UPDATE")
    eventFrame:RegisterEvent("UNIT_QUEST_LOG_CHANGED")
    eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    eventFrame:RegisterEvent("NEW_RECIPE_LEARNED") -- Spell objectives; Runes in SoD count as recipes because "Engraving" is a profession?
    --eventFrame:RegisterEvent("SPELLS_CHANGED") -- Spell objectives

    eventFrame:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_HIDE")

    eventFrame:RegisterEvent("CHAT_MSG_COMBAT_FACTION_CHANGE")
    eventFrame:SetScript("OnEvent", _QuestEventHandler.OnEvent)

    -- StaticPopup dialog hooks. Deleteing Quest items do not always trigger a Quest Log Update.
    hooksecurefunc("StaticPopup_Show", function(...)
        -- Hook StaticPopup_Show. If we find the "DELETE_ITEM" dialog, check for Quest Items and notify the player.
        local which, text_arg1 = ...
        if which == "DELETE_ITEM" then
            local quest
            local questName
            local foundQuestItem = false

            Questie:Debug(Questie.DEBUG_DEVELOP, "[QuestieQuest] StaticPopup_Show: Item Name: ", text_arg1)

            if deletedQuestItem == true then
                deletedQuestItem = false
            end

            for questLogIndex = 1, 75 do
                local title, _, _, isHeader, _, _, _, questId = GetQuestLogTitle(questLogIndex)

                if (not title) then
                    break
                end

                if (not isHeader) then
                    quest = QuestieDB.GetQuest(questId)

                    if quest then
                        local info = StaticPopupDialogs[which]
                        local sourceItemId, soureItemName, sourceItemType, soureClassID
                        local reqSourceItemId, reqSoureItemName, reqSourceItemType, reqSoureClassID

                        if quest.sourceItemId then
                            sourceItemId = quest.sourceItemId

                            if sourceItemId then
                                soureItemName, _, _, _, _, sourceItemType, _, _, _, _, _, soureClassID = GetItemInfo(sourceItemId)
                            end
                        end

                        if quest.requiredSourceItems then
                            reqSourceItemId = quest.requiredSourceItems[1]

                            if reqSourceItemId then
                                reqSoureItemName, _, _, _, _, reqSourceItemType, _, _, _, _, _, reqSoureClassID = GetItemInfo(reqSourceItemId)
                            end
                        end

                        if sourceItemId and soureItemName and sourceItemType and soureClassID and (sourceItemType == "Quest" or soureClassID == 12) and QuestieDB.QueryItemSingle(sourceItemId, "class") == 12 and text_arg1 == soureItemName then
                            questName = quest.name
                            foundQuestItem = true
                            break
                        elseif reqSourceItemId and reqSoureItemName and reqSourceItemType and reqSoureClassID and (reqSourceItemType == "Quest" or reqSoureClassID == 12) and QuestieDB.QueryItemSingle(reqSourceItemId, "class") == 12 and text_arg1 == reqSoureItemName then
                            questName = quest.name
                            foundQuestItem = true
                            break
                        else
                            if quest.Objectives and #quest.Objectives > 0 then
                                for _, objective in pairs(quest.Objectives) do
                                    if text_arg1 == objective.Description then
                                        questName = quest.name
                                        foundQuestItem = true
                                        break
                                    end
                                end
                            end
                        end
                    end
                end
            end

            if foundQuestItem and quest and questName then
                local frame, text

                for i = 1, STATICPOPUP_NUMDIALOGS do
                    frame = _G["StaticPopup" .. i]
                    if (frame:IsShown()) and ((frame.text.text_arg1 == text_arg1) or (string.find(frame.text:GetText(), text_arg1))) then
                        text = _G[frame:GetName() .. "Text"]
                        break
                    end
                end

                if frame ~= nil and text ~= nil then
                    local updateText = l10n("Quest Item %%s might be needed for the quest %%s. \n\nAre you sure you want to delete this?")
                    text:SetFormattedText(updateText, text_arg1, questName)
                    text.text_arg1 = updateText

                    StaticPopup_Resize(frame, which)
                    deletedQuestItem = true

                    Questie:Debug(Questie.DEBUG_DEVELOP, "[QuestieQuest] StaticPopup_Show: Quest Item Detected. Updating Static Popup.")
                end
            end
        end
    end)

    hooksecurefunc("DeleteCursorItem", function()
        -- Hook DeleteCursorItem so we know when the player clicks the Accept button
        if deletedQuestItem then
            Questie:Debug(Questie.DEBUG_DEVELOP, "[QuestieQuest] DeleteCursorItem: Quest Item deleted. Update all quests.")

            C_Timer.After(0.25, function()
				_QuestEventHandler:UpdateAllQuests()
				deletedQuestItem = false
			end)
        end
    end)

    _QuestEventHandler:InitQuestLog()
end

--- On Login mark all quests in the quest log with QUEST_ACCEPTED state
function _QuestEventHandler:InitQuestLog()
    -- Fill the QuestLogCache for first time
    local cacheMiss, changes = QuestLogCache.CheckForChanges(nil)
    -- if cacheMiss then
        -- TODO actually can happen in rare edge case if player accepts new quest during questie init. *cough*
        -- or if someone managed to overflow game cache already at this point.
        --Questie:Error("Did you accept a quest during InitQuestLog? Please report on Github or Discord. Game's quest log cache is not ok. This shouldn't happen. Questie may malfunction.")
    -- end

    for questId, _ in pairs(changes) do
        questLog[questId] = {
            state = QUEST_LOG_STATES.QUEST_ACCEPTED
        }
        QuestieLib:CacheItemNames(questId)
    end
end

--- Fires when a quest is accepted in anyway.
---@param questLogIndex number
---@param questId number
function _QuestEventHandler:QuestAccepted(questLogIndex, questId)
    questId = questId or select(8, GetQuestLogTitle(questLogIndex))
    Questie:Debug(Questie.DEBUG_DEVELOP, "[QuestAccepted] *** QUEST ACCEPTED FUNCTION CALLED ***", questLogIndex, questId)
    Questie:Debug(Questie.DEBUG_DEVELOP, "[Quest Event] QUEST_ACCEPTED", questLogIndex, questId)

    if questLog[questId] and questLog[questId].timer then
        -- We had a QUEST_REMOVED event which started this timer and now it was accepted again.
        -- So the quest was abandoned before, because QUEST_TURNED_IN would have run before QUEST_ACCEPTED.
        questLog[questId].timer:Cancel()
        questLog[questId].timer = nil
        QuestieCombatQueue:Queue(function()
            _QuestEventHandler:MarkQuestAsAbandoned(questId)
        end)
    end

    questLog[questId] = {}

    -- Check if this is a quest not in the database and create a runtime stub IMMEDIATELY (synchronously)
    -- This must happen before any tracker updates to prevent "Unknown Zone" flash
    if Questie.db.profile.debugEnabled then
        Questie:Debug(Questie.DEBUG_DEVELOP, "[QuestAccepted] Checking if quest", questId, "needs runtime stub...")
    end
    local isInDatabase = QuestieDB.QuestPointers[questId] ~= nil
    if Questie.db.profile.debugEnabled then
        Questie:Debug(Questie.DEBUG_DEVELOP, "[QuestAccepted] Quest", questId, "is in database:", isInDatabase)
    end
    
    if not isInDatabase then
        if Questie.db.profile.debugEnabled then
            Questie:Debug(Questie.DEBUG_DEVELOP, "[QuestAccepted] Creating runtime stub IMMEDIATELY for unknown quest:", questId)
        end
        -- Create stub immediately using the questLogIndex we have right now
        local title, level, questTag, suggestedGroup, isHeader, isCollapsed, isComplete, isDaily, questIdFromLog = GetQuestLogTitle(questLogIndex)
        if Questie.db.profile.debugEnabled then
            Questie:Debug(Questie.DEBUG_DEVELOP, "[QuestAccepted] GetQuestLogTitle results:")
            Questie:Debug(Questie.DEBUG_DEVELOP, "  title:", title, "level:", level, "questTag:", questTag)
            Questie:Debug(Questie.DEBUG_DEVELOP, "  suggestedGroup:", suggestedGroup, "isDaily:", isDaily, "isComplete:", isComplete)
            Questie:Debug(Questie.DEBUG_DEVELOP, "  questId:", questIdFromLog, "target questId:", questId)
        end
        
        if title then  -- Only require title, questIdFromLog is often nil immediately after quest acceptance
            -- We have valid quest data, create a minimal stub with zone info right away
            local currentZoneName = nil
            if GetSubZoneText then
                currentZoneName = GetSubZoneText()
                if currentZoneName and currentZoneName ~= "" then
                    Questie:Debug(Questie.DEBUG_INFO, "[QuestAccepted] GetSubZoneText() returned:", currentZoneName)
                else
                    currentZoneName = nil
                    Questie:Debug(Questie.DEBUG_INFO, "[QuestAccepted] GetSubZoneText() returned empty")
                end
            end
            
            -- Also try to get a more accurate quest level using alternative methods
            local actualQuestLevel = level
            
            -- Try SelectQuestLogEntry + GetQuestLogSelection approach for more accurate level
            if SelectQuestLogEntry and GetQuestLogSelection then
                local originalSelection = GetQuestLogSelection()
                SelectQuestLogEntry(questLogIndex)
                local selectedTitle, selectedLevel, selectedQuestTag, selectedSuggestedGroup, selectedIsHeader, selectedIsCollapsed, selectedIsComplete, selectedIsDaily = GetQuestLogTitle(questLogIndex)
                if selectedLevel and selectedLevel > 0 then
                    actualQuestLevel = selectedLevel
                    -- Also update other values if they're more accurate
                    questTag = questTag or selectedQuestTag
                    suggestedGroup = suggestedGroup or selectedSuggestedGroup
                    isDaily = isDaily or selectedIsDaily
                    isComplete = isComplete or selectedIsComplete
                    Questie:Debug(Questie.DEBUG_INFO, "[QuestAccepted] SelectQuestLogEntry enhanced data:")
                    Questie:Debug(Questie.DEBUG_INFO, "  level:", selectedLevel, "questTag:", selectedQuestTag, "suggestedGroup:", selectedSuggestedGroup, "isDaily:", selectedIsDaily)
                end
                -- Restore original selection
                if originalSelection and originalSelection > 0 then
                    SelectQuestLogEntry(originalSelection)
                end
            end
            
            -- Fallback to player level if quest level is invalid
            if not actualQuestLevel or actualQuestLevel <= 0 then
                actualQuestLevel = QuestiePlayer.GetPlayerLevel()
                Questie:Debug(Questie.DEBUG_INFO, "[QuestAccepted] Using player level fallback:", actualQuestLevel)
            else
                Questie:Debug(Questie.DEBUG_INFO, "[QuestAccepted] Using quest level:", actualQuestLevel)
            end
            
            -- Calculate quest difficulty color based on level difference
            local questDifficultyColor = nil
            if GetQuestDifficultyColor and actualQuestLevel then
                questDifficultyColor = GetQuestDifficultyColor(actualQuestLevel)
                Questie:Debug(Questie.DEBUG_INFO, "[QuestAccepted] Quest difficulty color - r:", questDifficultyColor.r, "g:", questDifficultyColor.g, "b:", questDifficultyColor.b)
            end
            
            -- Convert questTag to proper quest type for Questie compatibility
            local questType = nil
            local questTypeTag = questTag
            if questTag then
                if questTag == "Dungeon" then
                    questType = 81 -- QUESTTYPE_DUNGEON
                elseif questTag == "Elite" then
                    questType = 1 -- QUESTTYPE_ELITE  
                elseif questTag == "Group" then
                    questType = 81 -- QUESTTYPE_GROUP
                elseif questTag == "Heroic" then
                    questType = 85 -- QUESTTYPE_HEROIC
                elseif questTag == "PVP" then
                    questType = 41 -- QUESTTYPE_PVP
                elseif questTag == "Raid" then
                    questType = 62 -- QUESTTYPE_RAID
                else
                    questType = 0 -- Standard quest
                end
                Questie:Debug(Questie.DEBUG_INFO, "[QuestAccepted] Converted questTag:", questTag, "to questType:", questType)
            end
            
            -- Create a basic stub immediately with full quest metadata
            local immediateStub = {
                Id = questId,
                name = "[Epoch] " .. tostring(title),
                LocalizedName = "[Epoch] " .. tostring(title),
                Level = actualQuestLevel,
                level = actualQuestLevel, -- tracker uses lower-case 'level'
                zoneOrSort = currentZoneName and -9999 or 0,
                runtimeZoneName = currentZoneName,
                -- Quest metadata from API
                questTag = questTypeTag, -- Keep original questTag string for display
                questType = questType, -- Numeric type for Questie compatibility 
                suggestedGroup = suggestedGroup, -- Group size recommendation
                isDaily = isDaily and (isDaily == 1), -- Convert to boolean
                isComplete = isComplete, -- Keep original API value (-1, 1, nil)
                difficultyColor = questDifficultyColor, -- Store color for tracker use
                -- Standard Questie fields
                Objectives = {},
                SpecialObjectives = {},
                ObjectiveData = {}, -- empty so icon spawn logic won't try to resolve DB data
                Color = questDifficultyColor or QuestieLib:ColorWheel(), -- Use difficulty color if available
                IsRepeatable = isDaily and (isDaily == 1) or false, -- Daily quests are repeatable
                sourceItemId = 0,
                requiredSourceItems = nil,
                Description = { "" },
                WasComplete = nil,
                __isRuntimeStub = true,
            }
            
            if Questie.db.profile.debugEnabled then
                Questie:Debug(Questie.DEBUG_DEVELOP, "[QuestAccepted] Created stub with metadata:")
                Questie:Debug(Questie.DEBUG_DEVELOP, "  Level:", actualQuestLevel, "questTag:", questTypeTag, "questType:", questType)
                Questie:Debug(Questie.DEBUG_DEVELOP, "  suggestedGroup:", suggestedGroup, "isDaily:", isDaily, "isRepeatable:", immediateStub.IsRepeatable)
            end
            
            QuestiePlayer.currentQuestlog = QuestiePlayer.currentQuestlog or {}
            QuestiePlayer.currentQuestlog[questId] = immediateStub
            if Questie.db.profile.debugEnabled then
                Questie:Debug(Questie.DEBUG_DEVELOP, "[QuestAccepted] Immediate runtime stub created with zone:", currentZoneName or "Unknown Zone")
            end
        else
            if Questie.db.profile.debugEnabled then
                Questie:Debug(Questie.DEBUG_DEVELOP, "[QuestAccepted] Could not get quest data for immediate stub creation")
            end
        end
    else
        -- Database quest - handle it with direct tracker integration for foolproof reliability
        if Questie.db.profile.debugEnabled then
            Questie:Debug(Questie.DEBUG_DEVELOP, "[QuestAccepted] Database quest detected - using direct tracker integration")
        end
    end

    -- Timed quests do not need a full Quest Log Update.
    -- TODO: Add achievement timers later.
    local questTimers = GetQuestTimers(questId)
    if type(questTimers) == "number" then
        skipNextUQLCEvent = false
    else
        -- Only skip QUEST_LOG_UPDATE for runtime stubs
        -- For database quests, allow fallback QUEST_LOG_UPDATE processing to handle rapid acceptance edge cases
        local questInDatabase = QuestieDB.QuestPointers[questId] ~= nil
        if not questInDatabase then
            -- Runtime stub - skip QUEST_LOG_UPDATE since we'll force a full scan
            skipNextUQLCEvent = true
            if Questie.db.profile.debugEnabled then
                Questie:Debug(Questie.DEBUG_DEVELOP, "[QuestAccepted] Skipping QUEST_LOG_UPDATE for runtime stub:", questId)
            end
        else
            -- Database quest - allow QUEST_LOG_UPDATE as fallback for rapid acceptance reliability
            skipNextUQLCEvent = false
            if Questie.db.profile.debugEnabled then
                Questie:Debug(Questie.DEBUG_DEVELOP, "[QuestAccepted] Allowing QUEST_LOG_UPDATE fallback for database quest:", questId)
            end
        end
    end

    QuestieCombatQueue:Queue(function()
        QuestieLib:CacheItemNames(questId)
        -- Now do the full quest processing (which may enhance the stub we just created)
        _QuestEventHandler:HandleQuestAccepted(questId)
    end)

    Questie:Debug(Questie.DEBUG_DEVELOP, "[Quest Event] QUEST_ACCEPTED - skipNextUQLCEvent - ", skipNextUQLCEvent)
end

---@param questId number
---@return boolean true @if the function was successful, false otherwise
function _QuestEventHandler:HandleQuestAccepted(questId)
    -- Debug: ALWAYS log that this function was called
    Questie:Debug(Questie.DEBUG_INFO, "[HandleQuestAccepted] *** FUNCTION CALLED FOR QUEST:", questId, "***")
    
    -- We first check the quest objectives and retry in the next QLU event if they are not correct yet
    local cacheMiss, changes = QuestLogCache.CheckForChanges({ [questId] = true })
    if cacheMiss then
        -- if cacheMiss, no need to check changes as only 1 questId
        Questie:Debug(Questie.DEBUG_INFO, "Objectives are not cached yet")
        _QuestLogUpdateQueue:Insert(function()
            return _QuestEventHandler:HandleQuestAccepted(questId)
        end)

        return false
    end

    Questie:Debug(Questie.DEBUG_INFO, "Objectives are correct. Calling accept logic. quest:", questId)
    questLog[questId].state = QUEST_LOG_STATES.QUEST_ACCEPTED
    QuestieQuest:SetObjectivesDirty(questId)

    -- Debug: Always log quest acceptance and check database status
    Questie:Debug(Questie.DEBUG_INFO, "[HandleQuestAccepted] Processing quest acceptance for questId:", questId)
    local isInDatabase = QuestieDB.QuestPointers[questId] ~= nil
    Questie:Debug(Questie.DEBUG_INFO, "[HandleQuestAccepted] Quest", questId, "is in database:", isInDatabase)
    
    -- For unknown quests, enhance the existing runtime stub with detailed objectives
    if not isInDatabase then
        Questie:Debug(Questie.DEBUG_INFO, "[HandleQuestAccepted] Enhancing existing runtime stub for quest:", questId)
        local questLogData = QuestLogCache.GetQuest(questId)
        Questie:Debug(Questie.DEBUG_INFO, "[HandleQuestAccepted] QuestLogCache data retrieved for quest:", questId, "data exists:", questLogData ~= nil)
        
        -- Check if we already have a stub (we should, from the immediate creation)
        local existingStub = QuestiePlayer.currentQuestlog and QuestiePlayer.currentQuestlog[questId]
        if existingStub and existingStub.__isRuntimeStub then
            Questie:Debug(Questie.DEBUG_INFO, "[HandleQuestAccepted] Found existing runtime stub, enhancing with full data")
            -- Enhance the existing stub with complete objective data
            local enhancedStub = QuestieQuest._CreateRuntimeQuestStub(questId, questLogData)
            if enhancedStub then
                -- Preserve the zone name we set earlier (it might be more accurate than re-detecting it)
                if existingStub.runtimeZoneName then
                    enhancedStub.runtimeZoneName = existingStub.runtimeZoneName
                    enhancedStub.zoneOrSort = -9999
                    Questie:Debug(Questie.DEBUG_INFO, "[HandleQuestAccepted] Preserved existing zone name:", existingStub.runtimeZoneName)
                end
                QuestiePlayer.currentQuestlog[questId] = enhancedStub
                Questie:Debug(Questie.DEBUG_INFO, "[HandleQuestAccepted] Runtime stub enhanced successfully for quest:", questId)
            end
        else
            Questie:Debug(Questie.DEBUG_INFO, "[HandleQuestAccepted] No existing runtime stub found, creating new one")
            local stub = QuestieQuest._CreateRuntimeQuestStub(questId, questLogData)
            if stub then
                QuestiePlayer.currentQuestlog = QuestiePlayer.currentQuestlog or {}
                QuestiePlayer.currentQuestlog[questId] = stub
                Questie:Debug(Questie.DEBUG_INFO, "[HandleQuestAccepted] New runtime stub created for quest:", questId)
            else
                Questie:Debug(Questie.DEBUG_INFO, "[HandleQuestAccepted] Failed to create runtime stub for quest:", questId)
            end
        end
    else
        Questie:Debug(Questie.DEBUG_INFO, "[HandleQuestAccepted] Quest", questId, "is already in database, no runtime stub needed")
    end

    QuestieJourney:AcceptQuest(questId)
    QuestieAnnounce:AcceptedQuest(questId)

    local isLastIslePhase = Questie.db.global.isleOfQuelDanasPhase == IsleOfQuelDanas.MAX_ISLE_OF_QUEL_DANAS_PHASES
    if Questie.IsWotlk and (not isLastIslePhase) and IsleOfQuelDanas.CheckForActivePhase(questId) then
        QuestieQuest:SmoothReset()
    else
        QuestieQuest:AcceptQuest(questId)
        -- Single tracker update for all quest types to avoid redundancy
        QuestieCombatQueue:Queue(function()
            QuestieTracker:Update()
        end)
    end

    return true
end

--- Fires when a quest is turned in
---@param questId number
---@param xpReward number
---@param moneyReward number
function _QuestEventHandler:QuestTurnedIn(questId, xpReward, moneyReward)
    Questie:Debug(Questie.DEBUG_DEVELOP, "[Quest Event] QUEST_TURNED_IN", xpReward, moneyReward, questId)

    if questLog[questId] and questLog[questId].timer then
        -- Cancel the timer so the quest is not marked as abandoned
        questLog[questId].timer:Cancel()
        questLog[questId].timer = nil
    end

    Questie:Debug(Questie.DEBUG_INFO, "Quest:", questId, "was turned in and is completed")

    if questLog[questId] then
        -- There are quests which you just turn in so there is no preceding QUEST_ACCEPTED event and questLog[questId]
        -- is empty
        questLog[questId].state = QUEST_LOG_STATES.QUEST_TURNED_IN
    elseif QuestieCompat.Is335 then
        questLog[questId] = {state = QUEST_LOG_STATES.QUEST_TURNED_IN}
    end

    local parentQuest = QuestieDB.QueryQuestSingle(questId, "parentQuest")

    if parentQuest and parentQuest > 0 then
        -- Quests like "The Warsong Reports" have child quests which are just turned in. These child quests only
        -- fire QUEST_TURNED_IN + QUEST_LOG_UPDATE
        Questie:Debug(Questie.DEBUG_DEVELOP, "Quest:", questId, "Has a Parent Quest - do a full Quest Log check")
        doFullQuestLogScan = true
    end

    local itemName, _, _, quality, _, itemID = GetQuestLogRewardInfo(GetNumQuestLogRewards(questId), questId)

    if (itemID ~= nil or itemName ~= nil) and quality == 1 then
        Questie:Debug(Questie.DEBUG_DEVELOP, "Quest:", questId, "Recieved a possible Quest Item - do a full Quest Log check")
        doFullQuestLogScan = true
        skipNextUQLCEvent = false
    else
        skipNextUQLCEvent = true
    end

    QuestLogCache.RemoveQuest(questId)
    QuestieQuest:SetObjectivesDirty(questId) -- is this necessary? should whole quest.Objectives be cleared at some point of quest removal?

    QuestieQuest:CompleteQuest(questId)
    QuestieJourney:CompleteQuest(questId)
    QuestieAnnounce:CompletedQuest(questId)
end

--- Fires when a quest is removed from the quest log. This includes turning it in and abandoning it.
---@param questId number
function _QuestEventHandler:QuestRemoved(questId)
    Questie:Debug(Questie.DEBUG_DEVELOP, "[Quest Event] QUEST_REMOVED", questId)
    doFullQuestLogScan = false

    if (not questLog[questId]) then
        questLog[questId] = {}
    end

    -- The party members don't care whether a quest was turned in or abandoned, so we can just broadcast here
    Questie:SendMessage("QC_ID_BROADCAST_QUEST_REMOVE", questId)

    -- QUEST_TURNED_IN was called before QUEST_REMOVED --> quest was turned in
    if questLog[questId].state == QUEST_LOG_STATES.QUEST_TURNED_IN then
        Questie:Debug(Questie.DEBUG_INFO, "Quest:", questId, "was turned in before. Nothing do to.")
        questLog[questId] = nil
        return
    end

    -- QUEST_REMOVED can fire before QUEST_TURNED_IN. If QUEST_TURNED_IN is not called after X seconds the quest
    -- was abandoned
    questLog[questId] = {
        state = QUEST_LOG_STATES.QUEST_REMOVED,
        timer = C_Timer.NewTicker(1, function()
            _QuestEventHandler:MarkQuestAsAbandoned(questId)
        end, 1)
    }
    skipNextUQLCEvent = true
    Questie:Debug(Questie.DEBUG_DEVELOP, "[Quest Event] QUEST_REMOVED - skipNextUQLCEvent - ", skipNextUQLCEvent)
end

---@param questId number
function _QuestEventHandler:MarkQuestAsAbandoned(questId)
    Questie:Debug(Questie.DEBUG_DEVELOP, "QuestEventHandler:MarkQuestAsAbandoned")
    if questLog[questId].state == QUEST_LOG_STATES.QUEST_REMOVED then
        Questie:Debug(Questie.DEBUG_INFO, "Quest:", questId, "was abandoned")
        questLog[questId].state = QUEST_LOG_STATES.QUEST_ABANDONED

        QuestLogCache.RemoveQuest(questId)
        QuestieQuest:SetObjectivesDirty(questId) -- is this necessary? should whole quest.Objectives be cleared at some point of quest removal?

        QuestieQuest:AbandonedQuest(questId)
        QuestieJourney:AbandonQuest(questId)
        QuestieAnnounce:AbandonedQuest(questId)
        questLog[questId] = nil
    end
end

---Fires when the quest log changed in any way. This event fires very often!
function _QuestEventHandler:QuestLogUpdate()
    Questie:Debug(Questie.DEBUG_DEVELOP, "[Quest Event] QUEST_LOG_UPDATE")

    local continueQueuing = true
    -- Some of the other quest event didn't have the required information and ordered to wait for the next QLU.
    -- We are now calling the function which the event added.
    while continueQueuing and next(questLogUpdateQueue) do
        continueQueuing = _QuestLogUpdateQueue:GetFirst()()
    end

    if doFullQuestLogScan then
        doFullQuestLogScan = false
        -- Function call updates doFullQuestLogScan. Order matters.
        _QuestEventHandler:UpdateAllQuests()
    else
        -- Check if we have runtime stubs that need updating - if so, do a full scan
        local hasRuntimeStubs = false
        for questId, quest in pairs(QuestiePlayer.currentQuestlog) do
            if quest.__isRuntimeStub then
                hasRuntimeStubs = true
                break
            end
        end
        
        if hasRuntimeStubs then
            -- Force a full quest log scan for runtime stubs to ensure proper updates
            Questie:Debug(Questie.DEBUG_INFO, "[QuestLogUpdate] Runtime stubs detected, forcing full quest log scan")
            doFullQuestLogScan = true
            _QuestEventHandler:UpdateAllQuests()
        else
            QuestieCombatQueue:Queue(function()
                QuestieTracker:Update()
            end)
        end
    end
end

--- Fires whenever a quest objective progressed
---@param questId number
function _QuestEventHandler:QuestWatchUpdate(questId)
    Questie:Debug(Questie.DEBUG_DEVELOP, "[Quest Event] QUEST_WATCH_UPDATE", questId)

    -- We do a full scan even though we have the questId because many QUEST_WATCH_UPDATE can fire before
    -- a QUEST_LOG_UPDATE. Also not every QUEST_WATCH_UPDATE gets a single QUEST_LOG_UPDATE and doing a full
    -- scan is less error prone
    doFullQuestLogScan = true
end

local _UnitQuestLogChangedCallback = function()
    -- We also check in here because UNIT_QUEST_LOG_CHANGED is fired before the relevant events
    -- (Accept, removed, ...)
    if (not skipNextUQLCEvent) then
        doFullQuestLogScan = true
    else
        doFullQuestLogScan = false
        skipNextUQLCEvent = false
        Questie:Debug(Questie.DEBUG_INFO, "Skipping UnitQuestLogChanged")
    end
    return true
end

--- Fires when an objective changed in the quest log of the unitTarget. The required data is not available yet though
---@param unitTarget string
function _QuestEventHandler:UnitQuestLogChanged(unitTarget)
    Questie:Debug(Questie.DEBUG_DEVELOP, "[Quest Event] UNIT_QUEST_LOG_CHANGED", unitTarget)
    Questie:Debug(Questie.DEBUG_DEVELOP, "[Quest Event] UNIT_QUEST_LOG_CHANGED - skipNextUQLCEvent - ", skipNextUQLCEvent)

    -- There seem to be quests which don't trigger a QUEST_WATCH_UPDATE.
    -- We don't add a full check to the queue if skipNextUQLCEvent == true (from QUEST_WATCH_UPDATE or QUEST_TURNED_IN)
    if (not skipNextUQLCEvent) then
        doFullQuestLogScan = true
        _QuestLogUpdateQueue:Insert(_UnitQuestLogChangedCallback)
    else
        Questie:Debug(Questie.DEBUG_INFO, "Skipping UnitQuestLogChanged")
    end
    skipNextUQLCEvent = false
end

--- Does a full scan of the quest log and updates every quest that is in the QUEST_ACCEPTED state and which hash changed
--- since the last check
function _QuestEventHandler:UpdateAllQuests()
    Questie:Debug(Questie.DEBUG_INFO, "Running full questlog check")
    
    -- Update runtime stubs first to ensure they have latest data
    QuestieQuest:UpdateRuntimeStubs()
    
    local questIdsToCheck = {}

    -- TODO replace with a ready table so no need to generate at each call
    for questId, data in pairs(questLog) do
        if data.state == QUEST_LOG_STATES.QUEST_ACCEPTED then
            questIdsToCheck[questId] = true
        end
    end
    
    -- Also check runtime stubs
    for questId, quest in pairs(QuestiePlayer.currentQuestlog) do
        if quest.__isRuntimeStub then
            questIdsToCheck[questId] = true
            Questie:Debug(Questie.DEBUG_INFO, "Including runtime stub quest", questId, "in full scan")
        end
    end

    local cacheMiss, changes = QuestLogCache.CheckForChanges(questIdsToCheck)

    if next(changes) then
        for questId, objIds in pairs(changes) do
            --Questie:Debug(Questie.DEBUG_INFO, "Quest:", questId, "objectives:", table.concat(objIds, ","), "will be updated")
            Questie:Debug(Questie.DEBUG_INFO, "Quest:", questId, "will be updated")
            QuestieQuest:SetObjectivesDirty(questId)

            QuestieNameplate:UpdateNameplate()
            QuestieQuest:UpdateQuest(questId)
        end
        QuestieCombatQueue:Queue(function()
            C_Timer.After(1.0, function()
                QuestieTracker:Update()
            end)
        end)
    else
        -- Even if no changes detected, update tracker if we have runtime stubs
        -- This ensures runtime stubs display correctly after initialization
        local hasRuntimeStubs = false
        for questId, quest in pairs(QuestiePlayer.currentQuestlog) do
            if quest.__isRuntimeStub then
                hasRuntimeStubs = true
                break
            end
        end
        
        if hasRuntimeStubs then
            Questie:Debug(Questie.DEBUG_INFO, "Updating tracker for runtime stubs")
            QuestieCombatQueue:Queue(function()
                QuestieTracker:Update()
            end)
        else
            Questie:Debug(Questie.DEBUG_INFO, "Nothing to update (database quests use direct integration)")
        end
    end

    -- Do UpdateAllQuests() again at next QUEST_LOG_UPDATE if there was "cacheMiss" (game's cache and addon's cache didn't have all required data yet)
    doFullQuestLogScan = doFullQuestLogScan or cacheMiss
end

local lastTimeQuestRelatedFrameClosedEvent = -1
--- Blizzard does not fire any event when quest items are received or retrieved from sources other than looting.
--- So we hook events which fires once or twice after closing certain frames and do a full quest log check.
function _QuestEventHandler:QuestRelatedFrameClosed(event)
    local now = math.floor(GetTime())
    -- Don't do update if event fired twice
    if lastTimeQuestRelatedFrameClosedEvent ~= now then
        Questie:Debug(Questie.DEBUG_DEVELOP, "[Quest Event]", event)

        lastTimeQuestRelatedFrameClosedEvent = now
        _QuestEventHandler:UpdateAllQuests()
        QuestieTracker:Update()
    end
end

function _QuestEventHandler:ReputationChange()
    Questie:Debug(Questie.DEBUG_DEVELOP, "[Quest Event] CHAT_MSG_COMBAT_FACTION_CHANGE")

    -- Reputational quest progression doesn't fire UNIT_QUEST_LOG_CHANGED event, only QUEST_LOG_UPDATE event.
    doFullQuestLogScan = true
end

--- Helper function to insert a callback to the questLogUpdateQueue and increase the index
function _QuestLogUpdateQueue:Insert(callback)
    questLogUpdateQueue[questLogUpdateQueueSize] = callback
    questLogUpdateQueueSize = questLogUpdateQueueSize + 1
end

--- Helper function to retrieve the first element of questLogUpdateQueue
---@return function @The callback that was inserted first into questLogUpdateQueue
function _QuestLogUpdateQueue:GetFirst()
    questLogUpdateQueueSize = questLogUpdateQueueSize - 1
    return tableRemove(questLogUpdateQueue, 1)
end

local trackerMinimizedByDungeon = false
function _QuestEventHandler:ZoneChangedNewArea()
    Questie:Debug(Questie.DEBUG_DEVELOP, "[EVENT] ZONE_CHANGED_NEW_AREA")
    -- By my tests it takes a full 6-7 seconds for the world to load. There are a lot of
    -- backend Questie updates that occur when a player zones in/out of an instance. This
    -- is necessary to get everything back into it's "normal" state after all the updates.
    local isInInstance, instanceType = IsInInstance()

    if isInInstance then
        C_Timer.After(8, function()
            Questie:Debug(Questie.DEBUG_DEVELOP, "[EVENT] ZONE_CHANGED_NEW_AREA: Entering Instance")
            if Questie.db.profile.hideTrackerInDungeons then
                trackerMinimizedByDungeon = true

                QuestieCombatQueue:Queue(function()
                    QuestieTracker:Collapse()
                end)
            end
        end)

    -- We only want this to fire outside of an instance if the player isn't dead and we need to reset the Tracker
    elseif (not Questie.db.char.isTrackerExpanded and not UnitIsGhost("player")) and trackerMinimizedByDungeon == true then
        C_Timer.After(8, function()
            Questie:Debug(Questie.DEBUG_DEVELOP, "[EVENT] ZONE_CHANGED_NEW_AREA: Exiting Instance")
            if Questie.db.profile.hideTrackerInDungeons then
                trackerMinimizedByDungeon = false

                QuestieCombatQueue:Queue(function()
                    QuestieTracker:Expand()
                end)
            end
        end)
    end
end

--- Is executed whenever an event is fired and triggers relevant event handling.
---@param event string
function _QuestEventHandler:OnEvent(event, ...)
    if event == "QUEST_ACCEPTED" then
        Questie:Debug(Questie.DEBUG_DEVELOP, "[OnEvent] *** QUEST_ACCEPTED EVENT FIRED ***", ...)
        _QuestEventHandler:QuestAccepted(...)
    elseif event == "QUEST_TURNED_IN" then
        _QuestEventHandler:QuestTurnedIn(...)
    elseif event == "QUEST_REMOVED" then
        _QuestEventHandler:QuestRemoved(...)
    elseif event == "QUEST_LOG_UPDATE" then
        _QuestEventHandler:QuestLogUpdate()
    elseif event == "QUEST_WATCH_UPDATE" then
        _QuestEventHandler:QuestWatchUpdate(...)
    elseif event == "UNIT_QUEST_LOG_CHANGED" and select(1, ...) == "player" then
        _QuestEventHandler:UnitQuestLogChanged(...)
    elseif event == "ZONE_CHANGED_NEW_AREA" then
        _QuestEventHandler:ZoneChangedNewArea()
    elseif event == "NEW_RECIPE_LEARNED" then
        Questie:Debug(Questie.DEBUG_DEVELOP, "[EVENT] NEW_RECIPE_LEARNED (QuestEventHandler)")
        doFullQuestLogScan = true -- If this event is related to a spell objective, a QUEST_LOG_UPDATE will be fired afterwards
    elseif event == "PLAYER_INTERACTION_MANAGER_FRAME_HIDE" then
        local eventType = select(1, ...)
        if eventType == 1 then
            event = "TRADE_CLOSED"
        elseif eventType == 5 then
            event = "MERCHANT_CLOSED"
        elseif eventType == 8 then
            event = "BANKFRAME_CLOSED"
        elseif eventType == 10 then
            event = "GUILDBANKFRAME_CLOSED"
        elseif eventType == 12 then
            event = "VENDOR_CLOSED"
        elseif eventType == 17 then
            event = "MAIL_CLOSED"
        elseif eventType == 21 then
            event = "AUCTION_HOUSE_CLOSED"
        else
            -- Unknown event which we will simply ignore
            return
        end
        _QuestEventHandler:QuestRelatedFrameClosed(event)
    elseif event == "CHAT_MSG_COMBAT_FACTION_CHANGE" then
        _QuestEventHandler:ReputationChange()
    end
end
