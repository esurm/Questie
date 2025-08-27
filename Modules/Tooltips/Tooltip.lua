---@class QuestieTooltips
local QuestieTooltips = QuestieLoader:CreateModule("QuestieTooltips");
local _QuestieTooltips = QuestieTooltips.private
-------------------------
--Import modules.
-------------------------
---@type QuestieComms
local QuestieComms = QuestieLoader:ImportModule("QuestieComms");
---@type QuestieLib
local QuestieLib = QuestieLoader:ImportModule("QuestieLib");
---@type QuestiePlayer
local QuestiePlayer = QuestieLoader:ImportModule("QuestiePlayer");
---@type QuestieDB
local QuestieDB = QuestieLoader:ImportModule("QuestieDB");
---@type l10n
local l10n = QuestieLoader:ImportModule("l10n")

--- COMPATIBILITY ---
local UnitInParty = QuestieCompat.UnitInParty
local IsInGroup   = QuestieCompat.IsInGroup
local GetClassColor = QuestieCompat.GetClassColor

local tinsert = table.insert
QuestieTooltips.lastGametooltip = ""
QuestieTooltips.lastGametooltipCount = -1;
QuestieTooltips.lastGametooltipType = "";
QuestieTooltips.lastFrameName = "";

QuestieTooltips.lookupByKey = {
    --["u_Grell"] = {questid, {"Line 1", "Line 2"}}
}
QuestieTooltips.lookupKeysByQuestId = {
    --["questId"] = {"u_Grell", ... }
}

local MAX_GROUP_MEMBER_COUNT = 6

local _InitObjectiveTexts

---@param questId number
---@param key string monster: m_, items: i_, objects: o_ + string name of the objective
---@param objective table
function QuestieTooltips:RegisterObjectiveTooltip(questId, key, objective)
    if not QuestieTooltips.lookupByKey[key] then
        QuestieTooltips.lookupByKey[key] = {};
    end
    if not QuestieTooltips.lookupKeysByQuestId[questId] then
        QuestieTooltips.lookupKeysByQuestId[questId] = {}
    end
    local tooltip = {
        questId = questId,
        objective = objective,
    };
    QuestieTooltips.lookupByKey[key][tostring(questId) .. " " .. objective.Index] = tooltip
    tinsert(QuestieTooltips.lookupKeysByQuestId[questId], key)
end

---@param questId number
---@param name string The name of the object or NPC the tooltip should show on
---@param starterId number The ID of the object or NPC the tooltip should show on
---@param key string @Either m_<npcId> or o_<objectId>
function QuestieTooltips:RegisterQuestStartTooltip(questId, name, starterId, key)
    if not QuestieTooltips.lookupByKey[key] then
        QuestieTooltips.lookupByKey[key] = {};
    end
    if not QuestieTooltips.lookupKeysByQuestId[questId] then
        QuestieTooltips.lookupKeysByQuestId[questId] = {}
    end
    local tooltip = {
        questId = questId,
        name = name,
        starterId = starterId,
    };
    QuestieTooltips.lookupByKey[key][tostring(questId) .. " " .. name .. " " .. starterId] = tooltip
    tinsert(QuestieTooltips.lookupKeysByQuestId[questId], key)
end

---@param questId number
function QuestieTooltips:RemoveQuest(questId)
    if (not QuestieTooltips.lookupKeysByQuestId[questId]) then
        -- Tooltip has already been removed
        return
    end

    -- Remove tooltip related keys from quest table so that
    -- it can be readded/registered by other quest functions.
    local quest = QuestieDB.GetQuest(questId)

    if quest then
        for _, objective in pairs(quest.Objectives) do
            objective.AlreadySpawned = {}
            objective.hasRegisteredTooltips = false
            objective.registeredItemTooltips = false
        end

        for _, objective in pairs(quest.SpecialObjectives) do
            objective.AlreadySpawned = {}
            objective.hasRegisteredTooltips = false
            objective.registeredItemTooltips = false
        end
    end

    Questie:Debug(Questie.DEBUG_DEVELOP, "[QuestieTooltips:RemoveQuest]", questId)

    for _, key in pairs(QuestieTooltips.lookupKeysByQuestId[questId] or {}) do
        --Count to see if we should remove the main object
        local totalCount = 0
        local totalRemoved = 0
        for _, tooltipData in pairs(QuestieTooltips.lookupByKey[key] or {}) do
            --Remove specific quest
            if (tooltipData.questId == questId and tooltipData.objective) then
                QuestieTooltips.lookupByKey[key][tostring(tooltipData.questId) .. " " .. tooltipData.objective.Index] = nil
                totalRemoved = totalRemoved + 1
            elseif (tooltipData.questId == questId and tooltipData.name) then
                QuestieTooltips.lookupByKey[key][tostring(tooltipData.questId) .. " " .. tooltipData.name .. " " .. tooltipData.starterId] = nil
                totalRemoved = totalRemoved + 1
            end
            totalCount = totalCount + 1
        end
        if (totalCount == totalRemoved) then
            QuestieTooltips.lookupByKey[key] = nil
        end
    end

    QuestieTooltips.lookupKeysByQuestId[questId] = nil
end

-- === Group tooltip fetch via comms (original) ===
local function _FetchTooltipsForGroupMembers(key, tooltipData)
    local anotherPlayer = false;
    if QuestieComms and QuestieComms.data:KeyExists(key) then
        ---@tooltipData @tooltipData[questId][playerName][objectiveIndex].text
        local tooltipDataExternal = QuestieComms.data:GetTooltip(key);
        for questId, playerList in pairs(tooltipDataExternal) do
            if (not tooltipData[questId]) then
                tooltipData[questId] = {
                    title = QuestieLib:GetColoredQuestName(questId, Questie.db.profile.enableTooltipsQuestLevel, true, true)
                }
            end
            for playerName, _ in pairs(playerList) do
                local playerInfo = QuestiePlayer:GetPartyMemberByName(playerName);
                if playerInfo or QuestieComms.remotePlayerEnabled[playerName] then
                    anotherPlayer = true
                    break
                end
            end
            if anotherPlayer then
                break
            end
        end
    end

    if QuestieComms.data:KeyExists(key) and anotherPlayer then
        local tooltipDataExternal = QuestieComms.data:GetTooltip(key);
        for questId, playerList in pairs(tooltipDataExternal) do
            if (not tooltipData[questId]) then
                tooltipData[questId] = {
                    title = QuestieLib:GetColoredQuestName(questId, Questie.db.profile.enableTooltipsQuestLevel, true, true)
                }
            end
            for playerName, objectives in pairs(playerList) do
                local playerInfo = QuestiePlayer:GetPartyMemberByName(playerName);
                if playerInfo or QuestieComms.remotePlayerEnabled[playerName] then
                    anotherPlayer = true;
                    for objectiveIndex, objective in pairs(objectives) do
                        if (not objective) then
                            objective = {}
                        end
                        tooltipData[questId].objectivesText = _InitObjectiveTexts(tooltipData[questId].objectivesText, objectiveIndex, playerName)
                        local text;
                        local color = QuestieLib:GetRGBForObjective(objective)
                        if objective.required then
                            text = "   " .. color .. tostring(objective.fulfilled) .. "/" .. tostring(objective.required) .. " " .. objective.text;
                        else
                            text = "   " .. color .. objective.text;
                        end
                        tooltipData[questId].objectivesText[objectiveIndex][playerName] = { ["color"] = color, ["text"] = text };
                    end
                end
            end
        end
    end

    -- === DWD FALLBACK: if no per-mob tooltip cache, enrich from remote quest logs by questId/objectiveIndex ===
    if IsInGroup() then
  local me = UnitName("player")
  for questId, qdata in pairs(tooltipData) do
    local rq = QuestieComms.remoteQuestLogs and QuestieComms.remoteQuestLogs[questId]
    if rq and qdata.objectivesText then
      for objectiveIndex, perPlayer in pairs(qdata.objectivesText) do
        -- grab the description from *your* line (so we can reuse it for party)
        local baseDesc
        do
          local my = perPlayer[me] and perPlayer[me].text
          if my then
            local plain = my:gsub("|c%x%x%x%x%x%x%x%x",""):gsub("|r","")
            baseDesc = plain:match("%d+%s*/%s*%d+%s+(.+)$") or plain
          end
        end

        for who, log in pairs(rq) do
          if (UnitInParty(who) or QuestieComms.remotePlayerEnabled[who]) and not perPlayer[who] then
            local robj = log.objectives and log.objectives[objectiveIndex]
            if robj then
              local color = (perPlayer[me] and perPlayer[me].color) or "|cFFFFFFFF"
              local desc  = robj.text or baseDesc or ""
              local text
              if robj.required then
                text = "   " .. color .. tostring(robj.fulfilled or 0) .. "/" .. tostring(robj.required or 0)
                if desc ~= "" then text = text .. " " .. desc end
              else
                text = "   " .. color .. desc
              end
              qdata.objectivesText[objectiveIndex][who] = { color = color, text = text }
              anotherPlayer = true
            end
          end
        end
      end
    end
  end
end
    -- === /DWD FALLBACK ===

    return anotherPlayer
end

---@param key string
function QuestieTooltips:GetTooltip(key)
    Questie:Debug(Questie.DEBUG_SPAM, "[QuestieTooltips:GetTooltip]", key)
    if (not key) then
        return nil
    end

    if QuestiePlayer.numberOfGroupMembers > MAX_GROUP_MEMBER_COUNT then
        return nil -- temporary disable tooltips in raids, we should make a proper fix
    end

    -- datastructure reminder:
    -- tooltipdata[questId] = { title=..., objectivesText = { [objectiveIndex] = { [playerName] = { color=, text=} } } }
    local tooltipData = {}
    local tooltipLines = {}

    if QuestieTooltips.lookupByKey[key] then
        local playerName = UnitName("player")
        for k, tooltip in pairs(QuestieTooltips.lookupByKey[key]) do
            if tooltip.name then
                if Questie.db.profile.showQuestsInNpcTooltip then
                    local questString = QuestieLib:GetColoredQuestName(tooltip.questId, Questie.db.profile.enableTooltipsQuestLevel, true, true)
                    tinsert(tooltipLines, questString)
                end
            else
                local objective = tooltip.objective
                if not (objective.IsSourceItem or objective.IsRequiredSourceItem) then
                    objective:Update()
                end

                local questId = tooltip.questId
                local objectiveIndex = objective.Index;
                if (not tooltipData[questId]) then
                    tooltipData[questId] = {
                        title = QuestieLib:GetColoredQuestName(questId, Questie.db.profile.enableTooltipsQuestLevel, true, true)
                    }
                end
                if not QuestiePlayer.currentQuestlog[questId] then
                    QuestieTooltips.lookupByKey[key][k] = nil
                else
                    tooltipData[questId].objectivesText = _InitObjectiveTexts(tooltipData[questId].objectivesText, objectiveIndex, playerName)
                    local text;
                    local color = QuestieLib:GetRGBForObjective(objective)

                    if objective.Type == "spell" and objective.spawnList[tonumber(key:sub(3))].ItemId then
                        text = "   " .. color .. tostring(QuestieDB.QueryItemSingle(objective.spawnList[tonumber(key:sub(3))].ItemId, "name"));
                        tooltipData[questId].objectivesText[objectiveIndex][playerName] = { ["color"] = color, ["text"] = text };
                    elseif objective.Needed then
                        text = "   " .. color .. tostring(objective.Collected) .. "/" .. tostring(objective.Needed) .. " " .. tostring(objective.Description);
                        tooltipData[questId].objectivesText[objectiveIndex][playerName] = { ["color"] = color, ["text"] = text };
                    else
                        text = "   " .. color .. tostring(objective.Description);
                        tooltipData[questId].objectivesText[objectiveIndex][playerName] = { ["color"] = color, ["text"] = text };
                    end
                end
            end
        end
    end

    local anotherPlayer = false
    if IsInGroup() then
        anotherPlayer = _FetchTooltipsForGroupMembers(key, tooltipData)
    end

    local playerName = UnitName("player")

    for questId, questData in pairs(tooltipData) do
        local hasObjective = false
        local tempObjectives = {}

        for _, playerList in pairs(questData.objectivesText or {}) do
            for objectivePlayerName, objectiveInfo in pairs(playerList) do
                local playerInfo = QuestiePlayer:GetPartyMemberByName(objectivePlayerName)
                local playerColor
                local playerType = "" -- suppress "(Nearby)"

                if playerInfo then
                    playerColor = "|c" .. playerInfo.colorHex
                elseif QuestieComms.remotePlayerEnabled[objectivePlayerName] and QuestieComms.remoteQuestLogs[questId] and QuestieComms.remoteQuestLogs[questId][objectivePlayerName] and (not Questie.db.profile.onlyPartyShared or UnitInParty(objectivePlayerName)) then
                    playerColor = QuestieComms.remotePlayerClasses[objectivePlayerName]
                    if playerColor then
                        playerColor = Questie:GetClassColor(playerColor)
                        playerType = "" -- not shown
                    end
                end

                -- === DWD DISPLAY: party-only + one-line-per-player
                local inParty = (objectivePlayerName == playerName) or UnitInParty(objectivePlayerName)

                if inParty and objectivePlayerName == playerName then
                    local _, classFilename = UnitClass("player");
                    local _, _, _, argbHex = GetClassColor(classFilename)
                    objectiveInfo.text = (objectiveInfo.text or "") ..
                        " (|c" .. (argbHex or "FFFFFFFF") .. objectivePlayerName .. "|r" .. (objectiveInfo.color or "") .. ")|r"

                elseif inParty then
                    if playerColor then
                        objectiveInfo.text = (objectiveInfo.text or "") ..
                            " (" .. playerColor .. objectivePlayerName .. "|r" .. (objectiveInfo.color or "") .. ")|r"
                    else
                        -- derive from unit class if possible
                        local hex = "FFFFFFFF"
                        for i=1, (GetNumPartyMembers() or 0) do
                            local u = "party"..i
                            if UnitExists(u) and UnitName(u) == objectivePlayerName then
                                local _, cls = UnitClass(u)
                                local _, _, _, h = GetClassColor(cls or "")
                                if h then hex = h end
                                break
                            end
                        end
                        objectiveInfo.text = (objectiveInfo.text or "") ..
                            " (|c" .. hex .. objectivePlayerName .. "|r" .. (objectiveInfo.color or "") .. ")|r"
                    end
                end
                -- === /DWD DISPLAY ===

                -- Player on top; include only party members
                if objectivePlayerName == playerName then
                    tinsert(tempObjectives, 1, objectiveInfo.text); hasObjective = true
                elseif inParty then
                    tinsert(tempObjectives, objectiveInfo.text); hasObjective = true
                end
            end
        end

        -- If we *only* have our own line, strip the "(Me)" tag so it reads clean.
        -- If only your own line exists, remove the trailing " (Name)" (handles colored names and final |r)
if #tempObjectives == 1 then
    local t = tempObjectives[1]
    -- case 1: "(…)" immediately before a final |r
    t = t:gsub("%s*%b()%s*|r%s*$", "|r")
    -- case 2: "(…)" truly at end (no trailing |r)
    t = t:gsub("%s*%b()%s*$", "")
    tempObjectives[1] = t
end


        if hasObjective then
            tinsert(tooltipLines, questData.title);
            for _, text in ipairs(tempObjectives) do
                tinsert(tooltipLines, text);
            end
        end
    end

    return tooltipLines
end

_InitObjectiveTexts = function(objectivesText, objectiveIndex, playerName)
    if (not objectivesText) then objectivesText = {} end
    if (not objectivesText[objectiveIndex]) then objectivesText[objectiveIndex] = {} end
    if (not objectivesText[objectiveIndex][playerName]) then objectivesText[objectiveIndex][playerName] = {} end
    return objectivesText
end

function QuestieTooltips:Initialize()
    -- For the clicked item frame.
    ItemRefTooltip:HookScript("OnTooltipSetItem", _QuestieTooltips.AddItemDataToTooltip)
    ItemRefTooltip:HookScript("OnHide", function(self)
        if (not self.IsForbidden) or (not self:IsForbidden()) then
            QuestieTooltips.lastGametooltip = ""
            QuestieTooltips.lastItemRefTooltip = ""
            QuestieTooltips.lastGametooltipItem = nil
            QuestieTooltips.lastGametooltipUnit = nil
            QuestieTooltips.lastGametooltipCount = 0
            QuestieTooltips.lastFrameName = "";
        end
    end)

    -- For the hover frame.
    GameTooltip:HookScript("OnTooltipSetUnit", function(self)
        if QuestiePlayer.numberOfGroupMembers > MAX_GROUP_MEMBER_COUNT then
            return
        end
        _QuestieTooltips.AddUnitDataToTooltip(self)
    end)
    GameTooltip:HookScript("OnTooltipSetItem", _QuestieTooltips.AddItemDataToTooltip)
    GameTooltip:HookScript("OnShow", function(self)
        if QuestiePlayer.numberOfGroupMembers > MAX_GROUP_MEMBER_COUNT then
            return
        end
        if (not self.IsForbidden) or (not self:IsForbidden()) then
            QuestieTooltips.lastGametooltipItem = nil
            QuestieTooltips.lastGametooltipUnit = nil
            QuestieTooltips.lastGametooltipCount = 0
            QuestieTooltips.lastFrameName = "";
        end
    end)
    GameTooltip:HookScript("OnHide", function(self)
        if QuestiePlayer.numberOfGroupMembers > MAX_GROUP_MEMBER_COUNT then
            return
        end
        if (not self.IsForbidden) or (not self:IsForbidden()) then
            QuestieTooltips.lastGametooltip = ""
            QuestieTooltips.lastItemRefTooltip = ""
            QuestieTooltips.lastGametooltipItem = nil
            QuestieTooltips.lastGametooltipUnit = nil
            QuestieTooltips.lastGametooltipCount = 0
        end
    end)

    -- Fired whenever the cursor hovers something with a tooltip. And then on every frame
    GameTooltip:HookScript("OnUpdate", function(self)
        if QuestiePlayer.numberOfGroupMembers > MAX_GROUP_MEMBER_COUNT then
            return
        end

        if (not self.IsForbidden) or (not self:IsForbidden()) then
            local uName, unit = self:GetUnit()
            local iName, link = self:GetItem()
            local sName, spell = self:GetSpell()
            if (uName == nil and unit == nil and iName == nil and link == nil and sName == nil and spell == nil) and (
                QuestieTooltips.lastGametooltip ~= GameTooltipTextLeft1:GetText()
                or (not QuestieTooltips.lastGametooltipCount)
                or _QuestieTooltips:CountTooltip() < QuestieTooltips.lastGametooltipCount
                or QuestieTooltips.lastGametooltipType ~= "object"
            ) and (not self.ShownAsMapIcon) then
                _QuestieTooltips:AddObjectDataToTooltip(GameTooltipTextLeft1:GetText())
                QuestieTooltips.lastGametooltipCount = _QuestieTooltips:CountTooltip()
            end
            QuestieTooltips.lastGametooltip = GameTooltipTextLeft1:GetText()
        end
    end)
end

-- === DWDQ inline listener (3.3.5a-safe) ===
do
  local f=CreateFrame("Frame")
  if RegisterAddonMessagePrefix then RegisterAddonMessagePrefix("DWDQ") end
  f:RegisterEvent("CHAT_MSG_ADDON")

  local function partyClassFor(n)
    if n==UnitName("player") then local _,c=UnitClass("player"); return c end
    for i=1,(GetNumPartyMembers() or 0) do
      local u="party"..i
      if UnitExists(u) and UnitName(u)==n then local _,c=UnitClass(u); return c end
    end
  end

  f:SetScript("OnEvent", function(_,_,p,m,_,s)
    if p~="DWDQ" then return end
    local q=tonumber(m:match("Q:(%d+)")); if not q then return end
    local who=m:match("N=([^;]+)") or s; if not who then return end

    QuestieComms.remoteQuestLogs     = QuestieComms.remoteQuestLogs     or {}
    QuestieComms.remotePlayerEnabled = QuestieComms.remotePlayerEnabled or {}
    QuestieComms.remotePlayerClasses = QuestieComms.remotePlayerClasses or {}

    local rq=QuestieComms.remoteQuestLogs
    rq[q]=rq[q] or {}; rq[q][who]=rq[q][who] or {objectives={}}

    for i,fv,rv in m:gmatch(";(%%d+)=(%%d+)/(%%d+)") do end -- old-Lua pre-scan
    for i,fv,rv in m:gmatch(";(%d+)=(%d+)/(%d+)") do
      rq[q][who].objectives[tonumber(i)]={fulfilled=tonumber(fv),required=tonumber(rv)}
    end

    QuestieComms.remotePlayerEnabled[who]=true
    local cls=partyClassFor(who); if cls then QuestieComms.remotePlayerClasses[who]=cls end
  end)
end
-- === /DWDQ inline listener ===

-- === DWDQ inline broadcaster (3.3.5a-safe, auto on reload/join + REQ responder) ===
do
  if not DWDQ_BC_INLINE then
    DWDQ_BC_INLINE = 1  -- /run print(DWDQ_BC_INLINE and "BC OK" or "BC MISSING")
    local f = CreateFrame("Frame")
    if RegisterAddonMessagePrefix then RegisterAddonMessagePrefix("DWDQ") end

    local ENABLED = true
    local lastPayload = {}                 -- questId -> last string sent (dedup)
    local pollAcc = 0
    local lastGroupSize = (GetNumRaidMembers() or 0) + (GetNumPartyMembers() or 0)

    local function OutChan()
      if (GetNumRaidMembers() or 0) > 0 then return "RAID" end
      if (GetNumPartyMembers() or 0) > 0 then return "PARTY" end
    end

    local function Delay(sec, fn)
      local t = CreateFrame("Frame"); local untilAt = GetTime() + (sec or 0)
      t:SetScript("OnUpdate", function(self)
        if GetTime() >= untilAt then self:SetScript("OnUpdate", nil); fn() end
      end)
    end

    local function QID(link)
      local id = link and link:match("Hquest:(%d+):")
      return id and tonumber(id) or nil
    end

    local function SendREQ()
      local ch = OutChan()
      if ch then SendAddonMessage("DWDQ", "REQ", ch) end
    end

    local function SendAll(force)
      if not ENABLED then return 0 end
      local ch = OutChan(); if not ch then return 0 end
      local me = UnitName("player")
      local n = GetNumQuestLogEntries() or 0
      local sent = 0
      for i = 1, n do
        local link = GetQuestLink(i) -- nil for headers
        if link then
          local q = QID(link)
          if q then
            local s = "Q:"..q..";N="..me
            local m = GetNumQuestLeaderBoards(i) or 0
            for j = 1, m do
              local t = GetQuestLogLeaderBoard(j, i) or ""
              local f, r = t:match("(%d+)%s*/%s*(%d+)")
              if f and r then s = s..";"..j.."="..f.."/"..r end
            end
            if force or s ~= lastPayload[q] then
              lastPayload[q] = s
              SendAddonMessage("DWDQ", s, ch)
              sent = sent + 1
            end
          end
        end
      end
      return sent
    end

    -- Events: on reload/zone-in: ask party (REQ) then force-send your log
    f:RegisterEvent("PLAYER_LOGIN")
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:RegisterEvent("QUEST_LOG_UPDATE")
    f:RegisterEvent("QUEST_ACCEPTED")
    f:RegisterEvent("QUEST_REMOVED")
    f:RegisterEvent("QUEST_WATCH_UPDATE")
    f:RegisterEvent("CHAT_MSG_ADDON") -- respond to REQ

    f:SetScript("OnEvent", function(_, e, p, m, c, s)
      if e == "CHAT_MSG_ADDON" then
        if p == "DWDQ" and m == "REQ" then
          -- Someone reloaded/joined; answer with a forced send
          Delay(0.3, function() SendAll(true) end)
        end
      elseif e == "PLAYER_LOGIN" or e == "PLAYER_ENTERING_WORLD" then
        if (GetNumRaidMembers() + GetNumPartyMembers()) > 0 then
          Delay(0.6, SendREQ)                 -- ask others right after your reload
          Delay(1.0, function() SendAll(true) end) -- also send yours
        end
      else
        -- normal quest changes (deduped)
        SendAll(false)
      end
    end)

    -- Poll roster changes (works on every 3.3.5 fork): when party size changes, REQ + force-send
    f:SetScript("OnUpdate", function(_, elapsed)
      pollAcc = pollAcc + elapsed
      if pollAcc < 0.7 then return end
      pollAcc = 0
      local size = (GetNumRaidMembers() or 0) + (GetNumPartyMembers() or 0)
      if size ~= lastGroupSize then
        lastGroupSize = size
        if size > 0 then
          Delay(0.4, SendREQ)                      -- ask new party to broadcast
          Delay(0.7, function() SendAll(true) end) -- and send your own
        end
      end
    end)

    -- Optional: slash commands
    SLASH_DWDQ1 = "/dwdq"
    SlashCmdList["DWDQ"] = function()
      local n = SendAll(true)
      DEFAULT_CHAT_FRAME:AddMessage("DWDQ: sent "..n.." quest(s)")
    end
    SLASH_DWDQON1 = "/dwdqon"
    SlashCmdList["DWDQON"] = function()
      DEFAULT_CHAT_FRAME:AddMessage("DWDQ: ON"); ENABLED = true; SendAll(true)
    end
    SLASH_DWDQOFF1 = "/dwdqoff"
    SlashCmdList["DWDQOFF"] = function()
      DEFAULT_CHAT_FRAME:AddMessage("DWDQ: OFF"); ENABLED = false
    end
  end
end
-- === /DWDQ inline broadcaster ===


return QuestieTooltips
