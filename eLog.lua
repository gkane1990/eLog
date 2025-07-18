-- File: eLog.lua
-- Purpose: Main addon initialization, module management, and event handling core.

-- Get the addon object and name from the environment.
local addonName, _ = ...
-- Embed AceLocale-3.0 for localization support.
local eLog = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0", "AceLocale-3.0")

-- Central database defaults.
local defaults = {
    profile = {
        sessions = {},
        options = {
            showTimestamps = true,
            maxSessions = 100,
            isFrameLocked = false,
        },
    },
}

-- Called once when the addon is first loaded.
function eLog:OnInitialize()
    -- Initialize the database.
    self.db = LibStub("AceDB-3.0"):New("eLogDB", defaults, true)

    -- Register the slash command.
    self:RegisterChatCommand("elog", "ChatCommand")
end

-- Called every time the addon is enabled.
function eLog:OnEnable()
    -- Acquire module instances now that we know all files are loaded.
    self.Utils    = self:GetModule("Utils")
    self.Sessions = self:GetModule("Sessions")
    self.Options  = self:GetModule("Options")
    self.UI       = self:GetModule("UI")

    -- Register for game events.
    self:RegisterEvent("PLAYER_LOGIN", "OnPlayerLogin")
    self:RegisterEvent("CHAT_MSG_SYSTEM", "LogEvent")
    self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", "OnCombatLogEvent")

    -- Inform modules that the addon is enabled.
    self:SendMessage("ELOG_ADDON_ENABLED")
    self:Print("eLog enabled. Type /elog to configure.")
end

-- Called when the addon is disabled.
function eLog:OnDisable()
    self:UnregisterAllEvents()
    self:CancelAllTimers()
    self:SendMessage("ELOG_ADDON_DISABLED")
end

-- Handler for the /elog slash command.
function eLog:ChatCommand(input)
    input = strtrim(input)
    if input == "ui" then
        self.UI:Toggle()
    elseif input == "clear" then
        self.Sessions:ClearAll()
        self:Print("All sessions cleared.")
    elseif input == "help" then
        self:Print("Available commands: ui, clear. Use '/elog' to open settings.")
    else
        -- Open the main options panel if no specific command is given.
        LibStub("AceConfigDialog-3.0"):Open(addonName)
    end
end

-- Fired on player login to establish a new logging session.
function eLog:OnPlayerLogin()
    -- A short delay ensures all other addons and systems are fully loaded.
    self:ScheduleTimer(function()
        self.Sessions:CreateSession()
    end, 2)
end

-- Generic event logger for simple events.
function eLog:LogEvent(event, message, ...)
    if not message or message == "" then return end
    local entry = {
        timestamp = self.Utils:FormatTimestamp(GetTime()),
        eventType = event,
        short = message,
        full = string.format("Event: %s\nTime: %s\n\n%s", event, self.Utils:FormatTimestamp(GetTime()), message),
    }
    -- The Sessions module might not be ready on very early events, so check for it.
    if self.Sessions and self.Sessions.AddLine then
        self.Sessions:AddLine(entry)
    end
end

-- Handler for combat log events to detect unit deaths.
function eLog:OnCombatLogEvent()
    local _, subEvent, _, _, sourceName, _, _, _, destName, _, _, spellId = CombatLogGetCurrentEventInfo()
    if subEvent == "UNIT_DIED" then
        if destName and destName ~= "" then
            local entry = {
                timestamp = self.Utils:FormatTimestamp(GetTime()),
                eventType = subEvent,
                short = string.format("%s |cffff0000died|r.", destName),
                full = string.format("Event: %s\nUnit: %s\nTime: %s", subEvent, destName, date("%c")),
            }
            if self.Sessions and self.Sessions.AddLine then
                self.Sessions:AddLine(entry)
            end
        else
            -- Optionally log or handle the case where destName is nil or empty
            self:Print("Warning: UNIT_DIED event with no valid destName.")
        end
    end
end
