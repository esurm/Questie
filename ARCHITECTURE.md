# Questie Technical Architecture Documentation

## Overview

Questie is a comprehensive quest helper addon for World of Warcraft, specifically designed for Project Epoch (WotLK client). Built on a sophisticated modular architecture with custom dependency injection, it provides real-time quest tracking, spatial mapping, and advanced UI integration.

## System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        WoW Client Environment                    │
├─────────────────────────────────────────────────────────────────┤
│                      Questie Addon Stack                       │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  │
│  │   Presentation  │  │   Integration   │  │   User Input    │  │
│  │     Layer       │  │     Layer       │  │     Layer       │  │
│  ├─────────────────┤  ├─────────────────┤  ├─────────────────┤  │
│  │ QuestieTracker  │  │ QuestieTooltips │  │ QuestieOptions  │  │
│  │ QuestieMap      │  │ QuestieNameplate│  │ QuestieSlash    │  │
│  │ TrackerFrames   │  │ QuestieDBM      │  │ QuestieMenu     │  │
│  │ MinimapIcon     │  │ WorldMapButton  │  │ Journey         │  │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘  │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  │
│  │   Business      │  │  Communication  │  │   Threading     │  │
│  │   Logic Layer   │  │     Layer       │  │     Layer       │  │
│  ├─────────────────┤  ├─────────────────┤  ├─────────────────┤  │
│  │ QuestieQuest    │  │ QuestieComms    │  │ ThreadLib       │  │
│  │ QuestiePlayer   │  │ QuestieAnnounce │  │ TaskQueue       │  │
│  │ AvailableQuests │  │ EventHandler    │  │ CombatQueue     │  │
│  │ QuestieAuto     │  │ MessageHandler  │  │ FramePool       │  │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘  │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  │
│  │   Data Access   │  │   Compatibility │  │   Core System   │  │
│  │     Layer       │  │     Layer       │  │     Layer       │  │
│  ├─────────────────┤  ├─────────────────┤  ├─────────────────┤  │
│  │ QuestieDB       │  │ QuestieCompat   │  │ QuestieLoader   │  │
│  │ QuestXP         │  │ API Wrappers    │  │ Module Registry │  │
│  │ ZoneDB          │  │ Version Detect  │  │ Dependency DI   │  │
│  │ Corrections     │  │ Feature Gates   │  │ Lifecycle Mgmt  │  │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘  │
├─────────────────────────────────────────────────────────────────┤
│               External Dependencies (Ace3, HBD, etc.)           │
├─────────────────────────────────────────────────────────────────┤
│                    WoW API & Event System                      │
└─────────────────────────────────────────────────────────────────┘
```

## Module Dependency Graph

```
                    ┌─────────────────┐
                    │  QuestieLoader  │
                    │   (Singleton)   │
                    └─────────┬───────┘
                              │
            ┌─────────────────┼─────────────────┐
            │                 │                 │
    ┌───────▼──────┐  ┌──────▼──────┐  ┌──────▼──────┐
    │  QuestieDB   │  │QuestiePlayer│  │QuestieCompat│
    │  (Data Hub)  │  │ (State Mgr) │  │(API Bridge)│
    └───────┬──────┘  └──────┬──────┘  └──────┬──────┘
            │                │                │
      ┌─────▼─────┐    ┌─────▼─────┐    ┌─────▼─────┐
      │QuestieQuest│   │QuestieMap │   │QuestieEvent│
      │(Core Logic)│   │(Rendering)│   │(Handlers) │
      └─────┬─────┘    └─────┬─────┘    └─────┬─────┘
            │                │                │
    ┌───────▼───────┐ ┌──────▼──────┐ ┌───────▼───────┐
    │QuestieTracker │ │QuestieTooltip│ │QuestieOptions │
    │  (UI Track)   │ │ (UI Enhance)│ │  (Config UI)  │
    └───────────────┘ └─────────────┘ └───────────────┘
```

## Core Design Principles & Patterns

### 1. Dependency Injection with Custom IoC Container
The `QuestieLoader` implements a lightweight Inversion of Control container:

```lua
-- Singleton Factory Pattern
function QuestieLoader:CreateModule(name)
    if (not modules[name]) then
        modules[name] = { 
            private = {},  -- Encapsulated state
            __moduleId = name,
            __dependencies = {}
        }
        return modules[name]
    else
        return modules[name]  -- Singleton behavior
    end
end

-- Dependency Resolution
function QuestieLoader:ImportModule(name)
    -- Lazy instantiation with circular dependency handling
    if (not modules[name]) then
        modules[name] = { private = {} }
    end
    return modules[name]
end
```

### 2. Event-Driven Reactive Architecture
Implements the Observer pattern with WoW's event system:

```lua
-- Event Registration Pipeline
QuestieEventHandler:RegisterEvent("QUEST_LOG_UPDATE", function(...)
    QuestLogCache:InvalidateCache()
    QuestieQuest:UpdateQuestStates()
    QuestieTracker:RefreshDisplay()
    QuestieMap:UpdateIcons()
end)

-- Event Flow Diagram:
-- WoW Event → QuestieEventHandler → Business Logic → UI Updates → Network Sync
```

### 3. Memory-Efficient Object Pooling
Custom object pool implementation for UI frames:

```lua
-- Frame Pool Pattern
local framePool = {
    available = {},  -- Unused frames
    active = {},     -- In-use frames
    template = "QuestieIconTemplate"
}

function framePool:Acquire()
    local frame = table.remove(self.available) or CreateFrame(...)
    self.active[frame] = true
    return frame
end

function framePool:Release(frame)
    self.active[frame] = nil
    table.insert(self.available, frame)
    frame:Hide()
    frame:ClearAllPoints()
end
```

### 4. Coroutine-Based Cooperative Multitasking

```lua
-- Non-blocking processing with yield points
function ThreadLib.Thread(func, delay, errorHandler, callback)
    local thread = coroutine.create(func)
    local timer = C_Timer.NewTicker(delay or 0.01, function()
        if coroutine.status(thread) == "suspended" then
            local success, result = coroutine.resume(thread)
            if not success then
                errorHandler(result)
                timer:Cancel()
            end
        elseif coroutine.status(thread) == "dead" then
            timer:Cancel()
            if callback then callback() end
        end
    end)
    return timer, thread
end
```

## Technical Module System (`QuestieLoader`)

### Module Lifecycle Management

```
┌─────────────────────────────────────────────────────────────┐
│                Module Lifecycle States                      │
├─────────────────────────────────────────────────────────────┤
│  UNREGISTERED → CREATED → DEPENDENCIES_RESOLVED →          │
│  INITIALIZED → CONFIGURED → ACTIVE → CLEANUP → DESTROYED  │
└─────────────────────────────────────────────────────────────┘

Phase 1: Registration    ┌──────────────────┐
QuestieLoader:CreateModule ──────→ │   Module Created   │
                                   │  { private = {} }  │
                                   └────────┬───────────┘
                                            │
Phase 2: Dependency Resolution              │
QuestieLoader:ImportModule ←────────────────┘
                                            │
Phase 3: Initialization                     │
Module:Initialize() ←───────────────────────┘
```

### Type System and Annotations

```lua
---@class QuestieQuest : QuestieModule
---@field private QuestieQuestPrivate
local QuestieQuest = QuestieLoader:CreateModule("QuestieQuest")

---@class QuestieQuestPrivate
---@field questCache table<number, Quest>
---@field iconFrames table<string, Frame>
---@field updateQueue table<number, boolean>
QuestieQuest.private = QuestieQuest.private or {}

-- Interface segregation principle
---@class Quest
---@field id number
---@field name string
---@field level number
---@field objectives QuestObjective[]
---@field IsComplete fun(self: Quest): boolean
---@field GetObjectives fun(self: Quest): QuestObjective[]
```

## Detailed Architecture Layers

### Data Access Layer - Database Architecture

```
Database Compilation Pipeline:
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   Source    │───→│  Compiler   │───→│   Runtime   │───→│   Memory    │
│  Lua Tables │    │ String-ify  │    │ loadstring  │    │ Live Tables │
│             │    │ Compression │    │ Execution   │    │             │
└─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘
     │                    │                   │                   │
     │ Build Time         │ Addon Load        │ Runtime           │ Active Use
     │ DB Generation      │ String Storage    │ Table Creation    │ Query & Lookup
```


### Business Logic Layer - Quest Processing Engine

```
Quest State Machine:
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│ UNAVAILABLE │───→│  AVAILABLE  │───→│   ACTIVE    │───→│  COMPLETE   │
│             │    │             │    │             │    │             │
│ - No prereqs│    │ - All prereqs│   │ - In log    │    │ - Ready to  │
│ - Wrong lvl │    │   met       │    │ - Tracking  │    │   turn in   │
│ - Wrong race│    │ - Can accept│    │ - Progress  │    │ - All objs  │
│             │    │             │    │   tracking  │    │   done      │
└─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘
                            │                                     │
                            │                                     │
                            └─────────────────────────────────────┘
                                         TURNED_IN
                                    (Permanently completed)
```

#### Quest Availability Algorithm

```lua
-- Multi-stage filtering pipeline
function QuestieDB:IsQuestAvailable(questId, playerData)
    local quest = self.questData[questId]
    if not quest then return false end
    
    -- Stage 1: Hard Requirements Check
    if not self:CheckLevelRequirement(quest, playerData.level) then
        return false, "LEVEL_TOO_LOW"
    end
    
    if not self:CheckRaceRequirement(quest, playerData.race) then
        return false, "WRONG_RACE"
    end
    
    if not self:CheckClassRequirement(quest, playerData.class) then
        return false, "WRONG_CLASS"
    end
    
    -- Stage 2: Prerequisite Chain Resolution
    if quest[9] then  -- preQuestGroup (OR logic)
        if not self:CheckPrequestGroup(quest[9], playerData.completedQuests) then
            return false, "MISSING_PREQUEST_GROUP"
        end
    end
    
    if quest[10] then  -- preQuestSingle (AND logic)
        if not playerData.completedQuests[quest[10]] then
            return false, "MISSING_PREQUEST_SINGLE"
        end
    end
    
    -- Stage 3: Mutual Exclusivity Check
    if quest[12] then  -- inGroupWith
        for _, groupQuestId in ipairs(quest[12]) do
            if playerData.completedQuests[groupQuestId] then
                return false, "ALREADY_COMPLETED_IN_GROUP"
            end
        end
    end
    
    -- Stage 4: Dynamic State Validation
    if self:IsQuestRepeatable(quest) then
        return self:CheckRepeatability(questId, playerData)
    end
    
    return true, "AVAILABLE"
end
```

### Presentation Layer - UI Component Architecture

```
UI Component Hierarchy:
┌─────────────────────────────────────────────────────────────────┐
│                        QuestieTracker                          │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  │
│  │ TrackerBaseFrame│  │TrackerHeaderFrm │  │TrackerQuestFrm  │  │
│  │                 │  │                 │  │                 │  │
│  │ - Positioning   │  │ - Title Display │  │ - Quest Lines   │  │
│  │ - Drag/Resize   │  │ - Collapse Btn  │  │ - Objective Text│  │
│  │ - Fade Effects  │  │ - Menu Button   │  │ - Progress Bars │  │
│  │ - Backdrop      │  │ - Quest Count   │  │ - Timer Display │  │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                               │
                ┌──────────────┼───────────────┐
                │              │               │
    ┌───────────▼──────────┐   │   ┌───────────▼──────────┐
    │   TrackerLinePool    │   │   │ TrackerFadeTicker    │
    │                      │   │   │                      │
    │ - Line Object Pool   │   │   │ - Alpha Animation    │
    │ - Memory Management  │   │   │ - Mouse Hover Events │
    │ - Dynamic Allocation │   │   │ - Visibility States  │
    └──────────────────────┘   │   └──────────────────────┘
                               │
                    ┌──────────▼──────────┐
                    │  TrackerQuestTimers │
                    │                     │
                    │ - Timer Tracking    │
                    │ - Countdown Display │
                    │ - Expiration Alerts │
                    └─────────────────────┘
```

#### Frame Pool Implementation

```lua
-- Advanced object pool with type safety and lifecycle hooks
---@class TrackerLinePool
local TrackerLinePool = QuestieLoader:CreateModule("TrackerLinePool")

---@class PooledLine : Frame
---@field questId number
---@field objectiveIndex number
---@field lineType string
---@field inUse boolean

local linePool = {
    available = {},  -- Stack of available lines
    active = {},     -- Hash map of active lines [questId][objIndex] = line
    maxSize = 50,    -- Memory cap
    created = 0,     -- Total lines ever created
    template = "QuestieTrackerLineTemplate"
}

function TrackerLinePool:AcquireLine(questId, objectiveIndex, lineType)
    local line = table.remove(linePool.available)
    
    if not line then
        -- Create new line if pool empty and under cap
        if linePool.created < linePool.maxSize then
            line = CreateFrame("Frame", nil, parentFrame, linePool.template)
            line.poolIndex = linePool.created + 1
            linePool.created = linePool.created + 1
        else
            -- Pool exhausted, reuse oldest active line
            line = self:EvictOldestLine()
        end
    end
    
    -- Initialize line state
    line.questId = questId
    line.objectiveIndex = objectiveIndex
    line.lineType = lineType
    line.inUse = true
    line.lastAccess = GetTime()
    
    -- Register in active pool
    if not linePool.active[questId] then
        linePool.active[questId] = {}
    end
    linePool.active[questId][objectiveIndex] = line
    
    return line
end

function TrackerLinePool:ReleaseLine(questId, objectiveIndex)
    local line = linePool.active[questId] and linePool.active[questId][objectiveIndex]
    if not line then return end
    
    -- Cleanup line state
    line:Hide()
    line:ClearAllPoints()
    line.questId = nil
    line.objectiveIndex = nil
    line.inUse = false
    
    -- Return to available pool
    linePool.active[questId][objectiveIndex] = nil
    table.insert(linePool.available, line)
end
```

## Advanced Threading and Performance Systems

### Cooperative Threading Architecture

```
Thread Execution Model:
┌─────────────────────────────────────────────────────────────────┐
│                     Main UI Thread                             │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐         │
│  │   Frame N   │───→│  Frame N+1  │───→│  Frame N+2  │         │
│  │             │    │             │    │             │         │
│  │ yield() ────┼────┤ yield() ────┼────┤ yield() ────┼─────    │
│  │ resume()    │    │ resume()    │    │ resume()    │         │
│  └─────────────┘    └─────────────┘    └─────────────┘         │
├─────────────────────────────────────────────────────────────────┤
│                   Coroutine Workers                            │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  │
│  │   DB Loading    │  │  Icon Updates   │  │  Quest Parse    │  │
│  │   Coroutine     │  │   Coroutine     │  │   Coroutine     │  │
│  │                 │  │                 │  │                 │  │
│  │ State: RUNNING  │  │ State: WAITING  │  │ State: DONE     │  │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

#### Thread Scheduler Implementation

```lua
---@class ThreadScheduler
local ThreadScheduler = {
    activeThreads = {},      -- Currently running threads
    queuedThreads = {},      -- Waiting to start
    completedThreads = {},   -- Finished threads
    maxConcurrent = 3,       -- Concurrency limit
    frameTimeLimit = 0.016,  -- 16ms per frame (60 FPS)
}

function ThreadScheduler:ScheduleThread(func, priority, context)
    local thread = {
        coroutine = coroutine.create(func),
        priority = priority or 0,
        context = context or "unknown",
        startTime = GetTime(),
        frameTime = 0,
        yields = 0,
        id = self:GenerateThreadId()
    }
    
    table.insert(self.queuedThreads, thread)
    table.sort(self.queuedThreads, function(a, b) 
        return a.priority > b.priority 
    end)
    
    return thread.id
end

function ThreadScheduler:ProcessThreads()
    local frameStart = debugprofilestop()
    
    -- Start new threads if under concurrency limit
    while #self.activeThreads < self.maxConcurrent and #self.queuedThreads > 0 do
        local thread = table.remove(self.queuedThreads, 1)
        table.insert(self.activeThreads, thread)
    end
    
    -- Process active threads
    for i = #self.activeThreads, 1, -1 do
        local thread = self.activeThreads[i]
        local threadStart = debugprofilestop()
        
        if coroutine.status(thread.coroutine) == "suspended" then
            local success, result = coroutine.resume(thread.coroutine)
            
            thread.frameTime = debugprofilestop() - threadStart
            thread.yields = thread.yields + 1
            
            if not success then
                Questie:Error("Thread error in " .. thread.context, result)
                table.remove(self.activeThreads, i)
            elseif coroutine.status(thread.coroutine) == "dead" then
                thread.endTime = GetTime()
                table.insert(self.completedThreads, thread)
                table.remove(self.activeThreads, i)
            end
        end
        
        -- Yield if we've used too much frame time
        if (debugprofilestop() - frameStart) > self.frameTimeLimit then
            break
        end
    end
end
```

### Memory Management & Garbage Collection

```lua
-- Smart memory management with weak references
local memoryManager = {
    weakCache = setmetatable({}, {__mode = "v"}),  -- Weak values
    strongCache = {},                              -- Strong references
    cacheStats = {
        hits = 0,
        misses = 0,
        evictions = 0,
        maxSize = 1000
    }
}

function memoryManager:CacheGet(key)
    local value = self.weakCache[key] or self.strongCache[key]
    if value then
        self.cacheStats.hits = self.cacheStats.hits + 1
        -- Promote frequently accessed items to strong cache
        if not self.strongCache[key] and self.cacheStats.hits % 10 == 0 then
            self:PromoteToStrong(key, value)
        end
        return value
    else
        self.cacheStats.misses = self.cacheStats.misses + 1
        return nil
    end
end

function memoryManager:CacheSet(key, value, strong)
    if strong then
        self.strongCache[key] = value
        if self:GetStrongCacheSize() > self.cacheStats.maxSize then
            self:EvictLeastRecentlyUsed()
        end
    else
        self.weakCache[key] = value
    end
end
```

## Network Communication Protocol

### Message Structure & Serialization

```
Questie Communication Protocol v5.0:
┌─────────────────────────────────────────────────────────────────┐
│                     Message Header (32 bytes)                  │
├─────────────────────────────────────────────────────────────────┤
│ Version (4) │ Type (4) │ Length (8) │ Checksum (8) │ Flags (8) │
├─────────────────────────────────────────────────────────────────┤
│                      Message Payload                           │
│              (Serialized Lua Tables/Primitives)                │
└─────────────────────────────────────────────────────────────────┘

Message Types:
- QUEST_PROGRESS (0x01): Quest objective updates
- QUEST_COMPLETE (0x02): Quest completion notification  
- QUEST_ABANDON  (0x03): Quest abandoned
- VERSION_CHECK  (0x04): Addon version synchronization
- PLAYER_STATE   (0x05): Character level/class info
- LOCATION_SHARE (0x06): Player position for grouping
```

#### Advanced Serialization Engine

```lua
---@class QuestieSerializer
local QuestieSerializer = QuestieLoader:CreateModule("QuestieSerializer")

-- Custom serialization for performance-critical data
function QuestieSerializer:SerializeQuestProgress(questId, objectives)
    local buffer = {}
    
    -- Pack quest ID as variable-length integer
    self:WriteVarInt(buffer, questId)
    
    -- Pack objective count
    buffer[#buffer + 1] = string.char(#objectives)
    
    -- Pack each objective
    for i, objective in ipairs(objectives) do
        self:WriteVarInt(buffer, objective.type)
        self:WriteVarInt(buffer, objective.index)
        self:WriteVarInt(buffer, objective.current)
        self:WriteVarInt(buffer, objective.required)
        
        if objective.text then
            local textBytes = {objective.text:byte(1, -1)}
            buffer[#buffer + 1] = string.char(#textBytes)
            buffer[#buffer + 1] = string.char(unpack(textBytes))
        else
            buffer[#buffer + 1] = string.char(0)  -- No text
        end
    end
    
    return table.concat(buffer)
end

-- Variable-length integer encoding (protobuf-style)
function QuestieSerializer:WriteVarInt(buffer, value)
    while value >= 0x80 do
        buffer[#buffer + 1] = string.char(bit.bor(bit.band(value, 0x7F), 0x80))
        value = bit.rshift(value, 7)
    end
    buffer[#buffer + 1] = string.char(bit.band(value, 0x7F))
end
```

## Spatial Data Structures & Algorithms

### Coordinate System & Transformations

```
World Coordinate Systems:
┌─────────────────────────────────────────────────────────────────┐
│                     World Coordinates                          │
│                    (Absolute positions)                        │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐    ┌─────────────────┐                    │
│  │  Zone Coords    │────│   Map Coords    │                    │
│  │ (Relative X,Y)  │    │(Normalized 0-1) │                    │
│  │                 │    │                 │                    │
│  │ • Quest Icons   │    │ • WorldMapFrame │                    │
│  │ • NPC Spawns    │    │ • AddOn Pins    │                    │
│  └─────────────────┘    └─────────────────┘                    │
│           │                       │                           │
│           │                       │                           │
│  ┌─────────▼───────┐    ┌─────────▼───────┐                    │
│  │ Minimap Coords  │    │ Screen Coords   │                    │
│  │  (Polar R,θ)    │    │  (Pixel X,Y)    │                    │
│  │                 │    │                 │                    │
│  │ • Minimap Pins  │    │ • UI Elements   │                    │
│  │ • Distance Calc │    │ • Tooltips      │                    │
│  └─────────────────┘    └─────────────────┘                    │
└─────────────────────────────────────────────────────────────────┘
```

#### Efficient Spatial Queries

```lua
-- R-Tree inspired spatial indexing for quest icons
---@class SpatialIndex
local SpatialIndex = {
    root = nil,
    maxNodeCapacity = 8,
    minNodeCapacity = 4
}

---@class SpatialNode
---@field bounds Rectangle
---@field children SpatialNode[]|SpatialLeaf[]
---@field isLeaf boolean

---@class Rectangle
---@field minX number
---@field minY number  
---@field maxX number
---@field maxY number

function SpatialIndex:Insert(point, data)
    if not self.root then
        self.root = self:CreateLeafNode()
    end
    
    local insertResult = self:InsertRecursive(self.root, point, data)
    
    -- Handle root split
    if insertResult.split then
        local newRoot = self:CreateInternalNode()
        newRoot.children = {self.root, insertResult.newNode}
        self:UpdateBounds(newRoot)
        self.root = newRoot
    end
end

function SpatialIndex:Query(bounds)
    local results = {}
    if self.root then
        self:QueryRecursive(self.root, bounds, results)
    end
    return results
end

function SpatialIndex:QueryRecursive(node, queryBounds, results)
    if not self:BoundsIntersect(node.bounds, queryBounds) then
        return
    end
    
    if node.isLeaf then
        for _, item in ipairs(node.items) do
            if self:PointInBounds(item.point, queryBounds) then
                table.insert(results, item.data)
            end
        end
    else
        for _, child in ipairs(node.children) do
            self:QueryRecursive(child, queryBounds, results)
        end
    end
end
```

## Advanced Configuration System

### Multi-Tier Configuration Architecture

```
Configuration Hierarchy:
┌─────────────────────────────────────────────────────────────────┐
│                    Global Defaults                             │
│               (QuestieOptionsDefaults)                         │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐    ┌─────────────────┐                    │
│  │ Account Profile │    │Character Profile│                    │
│  │   (Shared)      │    │  (Per-char)     │                    │
│  │                 │    │                 │                    │
│  │ • UI Settings   │    │ • Tracked Quest │                    │
│  │ • Map Config    │    │ • Char-specific │                    │
│  │ • Debug Opts    │    │ • Progress Data │                    │
│  └─────────────────┘    └─────────────────┘                    │
├─────────────────────────────────────────────────────────────────┤
│                  Runtime Overrides                             │
│               (Temporary Modifications)                         │
└─────────────────────────────────────────────────────────────────┘
```

#### Dynamic Configuration Schema

```lua
---@class QuestieOptionsDefaults
local QuestieOptionsDefaults = QuestieLoader:CreateModule("QuestieOptionsDefaults")

-- Nested configuration with type safety and validation
function QuestieOptionsDefaults:Load()
    return {
        profile = {
            -- Map display options with constraints
            alwaysGlowMap = {
                type = "boolean",
                default = true,
                description = "Quest objectives always glow on map",
                category = "map",
                validation = function(value) return type(value) == "boolean" end
            },
            
            iconScale = {
                type = "range",
                default = 1.0,
                min = 0.1,
                max = 3.0,
                step = 0.1,
                description = "Icon size multiplier",
                category = "map",
                validation = function(value) 
                    return type(value) == "number" and value >= 0.1 and value <= 3.0 
                end,
                onChange = function(value)
                    QuestieMap:RefreshAllIcons()
                end
            },
            
            -- Tracker configuration with nested options
            tracker = {
                type = "group",
                args = {
                    enabled = {
                        type = "boolean",
                        default = true,
                        order = 1
                    },
                    maxHeight = {
                        type = "range",
                        default = 400,
                        min = 100,
                        max = 1200,
                        step = 10,
                        order = 2
                    },
                    font = {
                        type = "select",
                        default = "Friz Quadrata TT",
                        values = function() return LSM30:HashTable("font") end,
                        order = 3
                    }
                }
            }
        },
        
        char = {
            -- Character-specific data
            trackedQuests = {
                type = "table",
                default = {},
                description = "Manually tracked quest IDs"
            },
            
            autoUntrackedQuests = {
                type = "table", 
                default = {},
                description = "Quests player manually untracked"
            },
            
            completedQuests = {
                type = "table",
                default = {},
                description = "Quest completion state cache"
            }
        }
    }
end
```

## Detailed Event System Architecture

### Event Flow Pipeline

```
Event Processing Pipeline:
┌─────────────────────────────────────────────────────────────────┐
│                        WoW Event                               │
│                   (QUEST_LOG_UPDATE)                          │
└─────────────────────────┬───────────────────────────────────────┘
                          │
┌─────────────────────────▼───────────────────────────────────────┐
│                  QuestieEventHandler                           │
│                                                                │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐         │
│  │Event Filter  │─▶│Event Router  │─▶│Event Queue   │         │
│  │              │  │              │  │              │         │
│  │•Dedupe       │  │•Module Map   │  │•Priority Ord │         │
│  │•Throttle     │  │•Handler List │  │•Batch Proc   │         │
│  │•Validate     │  │•Async Route  │  │•Error Handle │         │
│  └──────────────┘  └──────────────┘  └──────────────┘         │
└─────────────────────────┬───────────────────────────────────────┘
                          │
┌─────────────────────────▼───────────────────────────────────────┐
│                   Module Handlers                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐         │
│  │QuestieQuest  │  │QuestieTracker│  │ QuestieMap   │         │
│  │              │  │              │  │              │         │
│  │•Update State │  │•Refresh UI   │  │•Redraw Icons │         │
│  │•Validate Log │  │•Update Lines │  │•Update Coords│         │
│  │•Trigger Hooks│  │•Timer Update │  │•Tooltip Sync │         │
│  └──────────────┘  └──────────────┘  └──────────────┘         │
└─────────────────────────────────────────────────────────────────┘
```

#### Event Handler Implementation

```lua
---@class QuestieEventHandler
local QuestieEventHandler = QuestieLoader:CreateModule("QuestieEventHandler")

-- Event registration with priority and filtering
local eventHandlers = {
    ["QUEST_LOG_UPDATE"] = {
        {
            handler = function(...) QuestLogCache:InvalidateCache() end,
            priority = 100,  -- High priority - data layer
            module = "QuestLogCache",
            throttle = 0.1   -- Max once per 100ms
        },
        {
            handler = function(...) QuestieQuest:UpdateQuestStates() end,
            priority = 50,   -- Medium priority - business logic
            module = "QuestieQuest",
            dependencies = {"QuestLogCache"}
        },
        {
            handler = function(...) QuestieTracker:RefreshDisplay() end,
            priority = 10,   -- Low priority - UI updates
            module = "QuestieTracker",
            dependencies = {"QuestieQuest"}
        }
    }
}

function QuestieEventHandler:RegisterEventHandler(event, handler, options)
    options = options or {}
    
    if not eventHandlers[event] then
        eventHandlers[event] = {}
        -- Register with WoW event system on first handler
        self:RegisterEvent(event, self.ProcessEvent)
    end
    
    local handlerData = {
        handler = handler,
        priority = options.priority or 0,
        module = options.module or "unknown",
        throttle = options.throttle,
        dependencies = options.dependencies or {},
        lastExecution = 0,
        executionCount = 0,
        totalTime = 0
    }
    
    table.insert(eventHandlers[event], handlerData)
    
    -- Sort by priority (higher priority first)
    table.sort(eventHandlers[event], function(a, b)
        return a.priority > b.priority
    end)
end

function QuestieEventHandler:ProcessEvent(event, ...)
    local handlers = eventHandlers[event]
    if not handlers then return end
    
    local currentTime = GetTime()
    
    for _, handlerData in ipairs(handlers) do
        -- Check throttle
        if handlerData.throttle then
            if (currentTime - handlerData.lastExecution) < handlerData.throttle then
                goto continue  -- Skip this handler
            end
        end
        
        -- Check dependencies
        if handlerData.dependencies then
            for _, dep in ipairs(handlerData.dependencies) do
                if not self:IsDependencySatisfied(dep, event) then
                    goto continue
                end
            end
        end
        
        -- Execute handler with error protection
        local startTime = debugprofilestop()
        local success, result = pcall(handlerData.handler, ...)
        local executionTime = debugprofilestop() - startTime
        
        -- Update statistics
        handlerData.lastExecution = currentTime
        handlerData.executionCount = handlerData.executionCount + 1
        handlerData.totalTime = handlerData.totalTime + executionTime
        
        if not success then
            Questie:Error("Event handler error", {
                event = event,
                module = handlerData.module,
                error = result,
                args = {...}
            })
        end
        
        ::continue::
    end
end
```

## Database Optimization & Indexing

### Advanced Query Optimization

```lua
-- Multi-level indexing for fast quest lookups
---@class QuestieDBIndex
local QuestieDBIndex = {
    -- Primary indices
    byLevel = {},           -- [level] = {questId1, questId2, ...}
    byZone = {},            -- [zoneId] = {questId1, questId2, ...}
    byNPC = {},             -- [npcId] = {starts = {...}, ends = {...}}
    
    -- Composite indices  
    byLevelAndZone = {},    -- [level][zoneId] = {questId1, ...}
    byClassAndLevel = {},   -- [classId][level] = {questId1, ...}
    
    -- Specialized indices
    dailyQuests = {},       -- Fast daily quest lookup
    eliteQuests = {},       -- Elite/group quest filtering
    professionQuests = {},  -- [professionId] = {questId1, ...}
    
    -- Spatial indices
    npcSpatialIndex = {},   -- For proximity queries
    objectSpatialIndex = {}
}

function QuestieDBIndex:BuildIndices()
    -- Clear existing indices
    self:ClearAll()
    
    -- Build quest indices
    for questId, questData in pairs(QuestieDB.questData) do
        local level = questData[5]          -- Quest level
        local zone = questData[14]          -- Zone or sort
        local requiredClasses = questData[7] -- Class bitmask
        
        -- Level index
        if not self.byLevel[level] then
            self.byLevel[level] = {}
        end
        table.insert(self.byLevel[level], questId)
        
        -- Zone index
        if zone and zone > 0 then  -- Positive values are zones
            if not self.byZone[zone] then
                self.byZone[zone] = {}
            end
            table.insert(self.byZone[zone], questId)
            
            -- Composite level+zone index
            if not self.byLevelAndZone[level] then
                self.byLevelAndZone[level] = {}
            end
            if not self.byLevelAndZone[level][zone] then
                self.byLevelAndZone[level][zone] = {}
            end
            table.insert(self.byLevelAndZone[level][zone], questId)
        end
        
        -- Class-specific index
        if requiredClasses and requiredClasses > 0 then
            for classId = 1, 11 do  -- All WoW classes
                if bit.band(requiredClasses, bit.lshift(1, classId - 1)) > 0 then
                    if not self.byClassAndLevel[classId] then
                        self.byClassAndLevel[classId] = {}
                    end
                    if not self.byClassAndLevel[classId][level] then
                        self.byClassAndLevel[classId][level] = {}
                    end
                    table.insert(self.byClassAndLevel[classId][level], questId)
                end
            end
        end
    end
    
    -- Build NPC indices
    for npcId, npcData in pairs(QuestieDB.npcData) do
        local questStarts = npcData[5]  -- Quests this NPC starts
        local questEnds = npcData[6]    -- Quests this NPC ends
        
        if questStarts or questEnds then
            self.byNPC[npcId] = {
                starts = questStarts or {},
                ends = questEnds or {}
            }
        end
    end
end

-- Optimized query methods
function QuestieDBIndex:GetQuestsInZoneByLevel(zoneId, minLevel, maxLevel)
    local results = {}
    
    for level = minLevel, maxLevel do
        local levelZoneQuests = self.byLevelAndZone[level] and 
                               self.byLevelAndZone[level][zoneId]
        if levelZoneQuests then
            for _, questId in ipairs(levelZoneQuests) do
                table.insert(results, questId)
            end
        end
    end
    
    return results
end
```

## System Initialization & Bootstrap Sequence

### Detailed Startup Flow

```
Addon Loading Timeline:
┌─────────────────────────────────────────────────────────────────┐
│  Phase 1: Core Module Registration (< 1ms)                     │
├─────────────────────────────────────────────────────────────────┤
│  QuestieLoader:CreateModule() calls for all core modules       │
│  ↓                                                             │
│  Module instances created with private namespaces              │
│  ↓                                                             │
│  Dependency graph established (no resolution yet)              │
└─────────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────▼───────────────────────────────────┐
│  Phase 2: Database Compilation (50-200ms)                      │
├─────────────────────────────────────────────────────────────────┤
│  loadstring() conversion of embedded database strings          │
│  ↓                                                             │
│  Runtime table construction for quest/NPC/object data          │
│  ↓                                                             │
│  Epoch-specific data merging and validation                    │
│  ↓                                                             │
│  Index construction for optimized queries                      │
└─────────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────▼───────────────────────────────────┐
│  Phase 3: Correction & Validation (10-50ms)                    │
├─────────────────────────────────────────────────────────────────┤
│  QuestieCorrections:Initialize() - Data fixes applied          │
│  ↓                                                             │
│  Cross-reference validation (orphaned quests, missing NPCs)    │
│  ↓                                                             │
│  Player state initialization and cache warming                 │
└─────────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────▼───────────────────────────────────┐
│  Phase 4: UI Framework Setup (20-100ms)                        │
├─────────────────────────────────────────────────────────────────┤
│  Frame pool initialization                                     │
│  ↓                                                             │
│  Tracker UI components created                                 │
│  ↓                                                             │
│  Map integration hooks established                             │
│  ↓                                                             │
│  Options menu registration with Ace3                          │
└─────────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────▼───────────────────────────────────┐
│  Phase 5: Event Registration & Activation (5-20ms)             │
├─────────────────────────────────────────────────────────────────┤
│  WoW event handlers registered                                 │
│  ↓                                                             │
│  Communication protocols initialized                           │
│  ↓                                                             │
│  Background processing threads started                         │
│  ↓                                                             │
│  Initial quest state synchronization                           │
└─────────────────────────────────────────────────────────────────┘
```

#### Startup Performance Metrics

```lua
---@class QuestieBootstrap
local QuestieBootstrap = {
    startTime = 0,
    phaseTimings = {},
    memoryBaseline = 0,
    initializationSteps = {}
}

function QuestieBootstrap:StartPhase(phaseName)
    local phaseData = {
        name = phaseName,
        startTime = debugprofilestop(),
        startMemory = collectgarbage("count"),
        steps = {}
    }
    
    table.insert(self.phaseTimings, phaseData)
    return phaseData
end

function QuestieBootstrap:EndPhase(phaseData, status)
    phaseData.endTime = debugprofilestop()
    phaseData.endMemory = collectgarbage("count")
    phaseData.duration = phaseData.endTime - phaseData.startTime
    phaseData.memoryDelta = phaseData.endMemory - phaseData.startMemory
    phaseData.status = status or "completed"
    
    Questie:Debug(Questie.DEBUG_INFO, string.format(
        "[Bootstrap] %s: %.2fms, %.2fMB memory delta, %s",
        phaseData.name,
        phaseData.duration,
        phaseData.memoryDelta,
        phaseData.status
    ))
end

-- Progressive loading with user feedback
function QuestieBootstrap:InitializeDatabase()
    local phase = self:StartPhase("Database Compilation")
    
    -- Stage 1: Core data tables
    self:LoadDatabaseTable("questData", "Loading quest database...")
    coroutine.yield()
    
    self:LoadDatabaseTable("npcData", "Loading NPC database...")
    coroutine.yield()
    
    self:LoadDatabaseTable("objectData", "Loading object database...")
    coroutine.yield()
    
    -- Stage 2: Supplemental data
    if QuestieDB._epochQuestData then
        self:MergeEpochData()
        coroutine.yield()
    end
    
    -- Stage 3: Index construction
    QuestieDBIndex:BuildIndices()
    coroutine.yield()
    
    self:EndPhase(phase, "success")
end
```

## Error Handling & Resilience Patterns

### Comprehensive Error Management

```lua
---@class QuestieErrorHandler
local QuestieErrorHandler = {
    errorLog = {},
    errorCounts = {},
    suppressedErrors = {},
    maxLogSize = 100,
    errorCategories = {
        DATA_CORRUPTION = 1,
        UI_TAINT = 2, 
        NETWORK_ERROR = 3,
        ADDON_CONFLICT = 4,
        PERFORMANCE_ISSUE = 5
    }
}

-- Structured error reporting with context
function QuestieErrorHandler:ReportError(category, message, context)
    local errorData = {
        timestamp = GetTime(),
        category = category,
        message = message,
        context = context or {},
        stackTrace = debugstack(2),  -- Skip this function in stack
        gameVersion = GetBuildInfo(),
        addonVersion = Questie.Version,
        playerInfo = {
            name = UnitName("player"),
            realm = GetRealmName(),
            class = select(2, UnitClass("player")),
            level = UnitLevel("player")
        }
    }
    
    -- Check if this error should be suppressed
    local errorSignature = self:GenerateErrorSignature(errorData)
    if self.suppressedErrors[errorSignature] then
        return false  -- Suppressed
    end
    
    -- Add to error log
    table.insert(self.errorLog, errorData)
    
    -- Maintain log size
    if #self.errorLog > self.maxLogSize then
        table.remove(self.errorLog, 1)
    end
    
    -- Update error counts
    self.errorCounts[category] = (self.errorCounts[category] or 0) + 1
    
    -- Trigger error handlers based on category
    self:HandleErrorByCategory(errorData)
    
    return true  -- Error was logged
end

-- Category-specific error handling
function QuestieErrorHandler:HandleErrorByCategory(errorData)
    if errorData.category == self.errorCategories.DATA_CORRUPTION then
        -- Attempt data recovery
        QuestieDB:ValidateAndRepair()
        
    elseif errorData.category == self.errorCategories.UI_TAINT then
        -- Queue UI updates for next frame
        QuestieCombatQueue:Queue(function()
            QuestieTracker:RefreshDisplay()
        end)
        
    elseif errorData.category == self.errorCategories.NETWORK_ERROR then
        -- Retry network operations with backoff
        QuestieComms:ScheduleRetry(errorData.context.operation)
        
    elseif errorData.category == self.errorCategories.PERFORMANCE_ISSUE then
        -- Reduce processing load temporarily
        ThreadLib:ReduceConcurrency()
    end
end

-- Circuit breaker pattern for flaky operations
---@class CircuitBreaker
local CircuitBreaker = {
    state = "CLOSED",  -- CLOSED, OPEN, HALF_OPEN
    failureCount = 0,
    failureThreshold = 5,
    timeout = 30,  -- seconds
    lastFailureTime = 0
}

function CircuitBreaker:Call(operation, ...)
    if self.state == "OPEN" then
        if (GetTime() - self.lastFailureTime) > self.timeout then
            self.state = "HALF_OPEN"
            self.failureCount = 0
        else
            return nil, "Circuit breaker is OPEN"
        end
    end
    
    local success, result = pcall(operation, ...)
    
    if success then
        if self.state == "HALF_OPEN" then
            self.state = "CLOSED"
        end
        self.failureCount = 0
        return result
    else
        self.failureCount = self.failureCount + 1
        self.lastFailureTime = GetTime()
        
        if self.failureCount >= self.failureThreshold then
            self.state = "OPEN"
        end
        
        return nil, result
    end
end
```



### Architectural Patterns for Extensibility

```lua
-- Plugin architecture with dependency injection
---@class QuestiePluginManager
local QuestiePluginManager = {
    registeredPlugins = {},
    pluginHooks = {},
    extensionPoints = {
        "questObjectiveProcessor",
        "mapIconRenderer", 
        "trackerLineFormatter",
        "tooltipEnhancer",
        "questAvailabilityFilter"
    }
}

-- Plugin registration with capability declarations
function QuestiePluginManager:RegisterPlugin(pluginInfo)
    local plugin = {
        id = pluginInfo.id,
        name = pluginInfo.name,
        version = pluginInfo.version,
        author = pluginInfo.author,
        
        -- Capability declarations
        capabilities = pluginInfo.capabilities or {},
        
        -- Extension point implementations
        extensions = pluginInfo.extensions or {},
        
        -- Resource requirements
        resources = {
            memory = pluginInfo.maxMemory or (1024 * 1024), -- 1MB default
            cpu = pluginInfo.maxCpuTime or 5,  -- 5ms per frame
            storage = pluginInfo.maxStorage or (100 * 1024) -- 100KB
        },
        
        -- Lifecycle hooks
        onLoad = pluginInfo.onLoad,
        onUnload = pluginInfo.onUnload,
        onConfigChange = pluginInfo.onConfigChange
    }
    
    -- Validate plugin requirements
    if not self:ValidatePlugin(plugin) then
        return false, "Plugin validation failed"
    end
    
    self.registeredPlugins[plugin.id] = plugin
    
    -- Register extension implementations
    for extensionPoint, implementation in pairs(plugin.extensions) do
        if not self.pluginHooks[extensionPoint] then
            self.pluginHooks[extensionPoint] = {}
        end
        table.insert(self.pluginHooks[extensionPoint], {
            plugin = plugin,
            implementation = implementation
        })
    end
    
    return true
end

-- Extension point execution with error isolation
function QuestiePluginManager:ExecuteExtension(extensionPoint, ...)
    local hooks = self.pluginHooks[extensionPoint]
    if not hooks then return end
    
    for _, hook in ipairs(hooks) do
        local success, result = pcall(hook.implementation, ...)
        if not success then
            QuestieErrorHandler:ReportError(
                QuestieErrorHandler.errorCategories.ADDON_CONFLICT,
                "Plugin extension error",
                {
                    plugin = hook.plugin.id,
                    extensionPoint = extensionPoint,
                    error = result
                }
            )
        end
    end
end
```

## Technical Debt & Optimization Opportunities

### Current Technical Debt Analysis

```
Technical Debt Heatmap:
┌─────────────────────────────────────────────────────────────────┐
│  Module Name           │ Complexity │ Coupling │ Test Coverage  │
├─────────────────────────────────────────────────────────────────┤
│  QuestieQuest          │    HIGH     │   HIGH   │     LOW       │
│  QuestieTracker        │    HIGH     │  MEDIUM  │    MEDIUM     │
│  QuestieDB             │   MEDIUM    │   LOW    │     HIGH      │
│  QuestieMap            │    HIGH     │  MEDIUM  │     LOW       │
│  QuestieComms          │   MEDIUM    │   LOW    │    MEDIUM     │
│  QuestieEventHandler   │   MEDIUM    │   HIGH   │     LOW       │
└─────────────────────────────────────────────────────────────────┘

Priority Refactoring Targets:
1. QuestieQuest: Monolithic quest processing (1900+ lines)
2. QuestieMap: Complex icon management with tight coupling
3. QuestieEventHandler: Event routing logic needs simplification
4. TrackerLinePool: Memory leak potential in frame pooling
```

### Performance Optimization Opportunities

```lua
-- Memory-efficient data structures
-- Current: Wasteful table structure
local inefficientStorage = {
    [questId] = {
        name = "Quest Name",
        level = 25,
        objectives = {...},
        -- Many nil/unused fields consume memory
    }
}

-- Proposed: Packed arrays with field maps
local efficientStorage = {
    -- Parallel arrays for better cache locality
    questNames = {[questId] = "Quest Name"},
    questLevels = {[questId] = 25},
    questObjectives = {[questId] = {...}},
    
    -- Bitfields for boolean properties
    questFlags = {[questId] = 0x1A4B},  -- Packed flags
    
    -- Intern strings to reduce memory usage
    stringPool = setmetatable({}, {
        __index = function(t, k)
            t[k] = k  -- Auto-intern strings
            return k
        end
    })
}
```
