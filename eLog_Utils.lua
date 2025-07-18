-- File: eLog_Utils.lua
-- Purpose: Provides shared utility functions for formatting and common tasks.

local addonName, eLog = ...
local Utils = eLog:NewModule("Utils")

-- Color code constants for chat messages.
local COLOR_GREEN = "|cff00ff00"
local COLOR_RED = "|cffff0000"
local COLOR_RESET = "|r"

-- Formats a game time (seconds) into a readable [HH:MM:SS] string.
function Utils:FormatTimestamp(gameTime)
    if not gameTime or type(gameTime) ~= "number" then
        return "[00:00:00]"
    end
    local hours = math.floor(gameTime / 3600)
    local mins = math.floor((gameTime % 3600) / 60)
    local secs = math.floor(gameTime % 60)
    return string.format("[%02d:%02d:%02d]", hours, mins, secs)
end

-- Exports the entire sessions database to the default chat frame as a serialized string.
function Utils:ExportData()
    -- Ensure the serializer library is available.
    local AceSerializer = LibStub("AceSerializer-3.0", true)
    if not AceSerializer then
        eLog:Print(COLOR_RED .. "Error:" .. COLOR_RESET .. " AceSerializer-3.0 library not found. Cannot export data.")
        return
    end

    local success, serializedData = AceSerializer:Serialize(eLog.db.profile.sessions)

    if success then
        print(COLOR_GREEN .. "eLog Export:" .. COLOR_RESET .. " Copy the text below:")
        -- WoW chat frame message limit is 255 characters per message.
        -- We chunk the data to prevent it from being truncated.
        local chunkSize = 250
        local len = #serializedData
        if len > chunkSize then
            print("|cffffd700eLog Notice:|r Data is large and will be split into multiple messages.")
        end
        for i = 1, len, chunkSize do
            print(serializedData:sub(i, i + chunkSize - 1))
        end
    else
        eLog:Print(COLOR_RED .. "Error:" .. COLOR_RESET .. " Failed to serialize session data.")
    end
end
