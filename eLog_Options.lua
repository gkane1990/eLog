-- File: eLog_Options.lua
-- Purpose: Defines and registers the addon's configuration options with AceConfig-3.0.

-- Get addon name and object from the environment. This is the standard way for module files.
local addonName, eLog = ...
local Options = eLog:NewModule("Options")

-- Get library instances.
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

function Options:OnInitialize()
    -- Define the options table for AceConfig.
    local options = {
        name = addonName,
        handler = eLog, -- The main addon object will handle getting/setting options.
        type = "group",
        args = {
            header = {
                order = 1,
                type = "header",
                name = "eLog Settings",
            },
            general = {
                order = 2,
                type = "group",
                name = "General",
                args = {
                    showTimestamps = {
                        order = 1,
                        type = "toggle",
                        name = "Show Timestamps in UI",
                        desc = "If checked, displays a timestamp for each logged event in the UI.",
                        -- Note: Using direct DB access here is simple and effective.
                        -- For larger projects, creating dedicated getter/setter functions in the core file can be a cleaner pattern.
                        get = function() return eLog.db.profile.options.showTimestamps end,
                        set = function(_, val)
                            eLog.db.profile.options.showTimestamps = val
                            eLog:SendMessage("ELOG_TIMESTAMP_VISIBILITY_CHANGED")
                        end,
                    },
                    isFrameLocked = {
                        order = 2,
                        type = "toggle",
                        name = "Lock UI Frame",
                        desc = "If checked, the main UI frame cannot be moved.",
                        get = function() return eLog.db.profile.options.isFrameLocked end,
                        set = function(_, val)
                            eLog.db.profile.options.isFrameLocked = val
                            eLog:SendMessage("ELOG_FRAME_LOCK_CHANGED", val)
                        end,
                    },
                    maxSessions = {
                        order = 3,
                        type = "range",
                        name = "Max Log Entries",
                        desc = "Maximum number of log entries to retain across all sessions.",
                        min = 50, max = 1000, step = 10,
                        get = function() return eLog.db.profile.options.maxSessions end,
                        set = function(_, val)
                            eLog.db.profile.options.maxSessions = val
                            eLog.Sessions:TrimOldSessions()
                        end,
                    },
                },
            },
            actions = {
                order = 3,
                type = "group",
                name = "Actions",
                args = {
                    toggleUI = {
                        order = 1,
                        type = "execute",
                        name = "Toggle UI",
                        desc = "Shows or hides the event log UI.",
                        func = function() eLog.UI:Toggle() end,
                    },
                    clear = {
                        order = 2,
                        type = "execute",
                        name = "Clear All Sessions",
                        desc = "Warning: This will permanently delete all logged data.",
                        func = function() eLog.Sessions:ClearAll() end,
                    },
                    export = {
                        order = 3,
                        type = "execute",
                        name = "Export Data",
                        desc = "Prints all session data to the chat window in a serialized format.",
                        func = function() eLog.Utils:ExportData() end,
                    },
                },
            },
            profiles = {
                order = 10,
                type = "group",
                name = "Profiles",
                -- Use AceDBOptions to automatically generate profile management controls.
                args = LibStub("AceDBOptions-3.0"):GetOptionsTable(eLog.db),
            },
        },
    }

    -- Register the options with AceConfig and add them to the Blizzard interface options panel.
    AceConfig:RegisterOptionsTable(addonName, options)
    AceConfigDialog:AddToBlizOptions(addonName, addonName)
end
