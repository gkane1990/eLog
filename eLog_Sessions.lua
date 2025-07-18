-- File: eLog_Sessions.lua
-- Purpose: Manages session data, including creation, storage, and trimming.

local addonName, eLog = ...
local Sessions = eLog:NewModule("Sessions")

local currentSessionKey = nil

-- Creates a new, empty session, using the current time as a unique key.
function Sessions:CreateSession()
    local sessionKey = tostring(GetTime())
    currentSessionKey = sessionKey

    local profile = eLog.db.profile
    profile.sessions[sessionKey] = {
        startTime = date("%c"),
        lines = {},
    }
    self:TrimOldSessions()
    eLog:SendMessage("ELOG_SESSION_CREATED", sessionKey)
end

-- Adds a new log entry to the current session.
function Sessions:AddLine(entry)
    if not currentSessionKey or not eLog.db.profile.sessions[currentSessionKey] then
        -- If for some reason there is no active session, create one.
        self:CreateSession()
    end

    table.insert(eLog.db.profile.sessions[currentSessionKey].lines, entry)
    eLog:SendMessage("ELOG_LINE_ADDED", currentSessionKey, entry)
end

-- Enforces the maxSessions limit by removing the oldest sessions.
function Sessions:TrimOldSessions()
    local profile = eLog.db.profile
    local sessions = profile.sessions
    local max = profile.options.maxSessions

    local keys = {}
    for k in pairs(sessions) do
        -- Ensure keys are numbers before inserting for a reliable sort.
        local numKey = tonumber(k)
        if numKey then
            table.insert(keys, numKey)
        end
    end

    if #keys > max then
        table.sort(keys) -- Sort keys ascending (oldest first)
        local numToRemove = #keys - max
        for i = 1, numToRemove do
            sessions[tostring(keys[i])] = nil
        end
        eLog:SendMessage("ELOG_SESSIONS_TRIMMED")
    end
end

-- Deletes all stored session data.
function Sessions:ClearAll()
    eLog.db.profile.sessions = {}
    currentSessionKey = nil
    eLog:SendMessage("ELOG_SESSIONS_CLEARED")
    -- The UI module listens for the message above and will update itself.
    -- No need for a direct call like eLog.UI:UpdateDisplay(), which improves decoupling.
end
