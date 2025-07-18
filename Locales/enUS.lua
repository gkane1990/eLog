-- Localization file for English (United States)
-- Get the AceLocale library and create a new locale table for our addon.
local L = LibStub("AceLocale-3.0"):NewLocale("eLog", "enUS", true)

if not L then return end

-- General
L["eLog enabled. Type /elog to configure."] = true
L["All sessions cleared."] = true
L["Available commands: ui, clear. Use '/elog' to open settings."] = true

-- Options Panel
L["eLog Settings"] = true
L["General"] = true
L["Show Timestamps in UI"] = true
L["If checked, displays a timestamp for each logged event in the UI."] = true
L["Lock UI Frame"] = true
L["If checked, the main UI frame cannot be moved."] = true
L["Max Log Entries"] = true
L["Maximum number of log entries to retain across all sessions."] = true
L["Actions"] = true
L["Toggle UI"] = true
L["Shows or hides the event log UI."] = true
L["Clear All Sessions"] = true
L["Warning: This will permanently delete all logged data."] = true
L["Export Data"] = true
L["Prints all session data to the chat window in a serialized format."] = true
L["Profiles"] = true

-- UI
L["eLog - Event Log"] = true
L["No logs available."] = true
