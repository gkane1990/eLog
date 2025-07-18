-- File: eLog_UI.lua
-- Purpose: Manages the creation, display, and interaction of all UI elements.

local addonName, eLog = ...
local UI = eLog:NewModule("UI", "AceEvent-3.0")

-- UI constants
local colors = {
    text = { 0.9, 0.9, 0.9, 1 },
    highlight = { 1.0, 0.82, 0.0, 1 },
    background = { 0.1, 0.1, 0.1, 0.85 },
    border = { 0.3, 0.3, 0.3, 1.0 },
}
-- Frame pool for recycling UI elements to improve performance.
local framePool = {}
local activeFrames = 0

function UI:OnInitialize()
    self:CreateMainFrame()
    -- Register for messages from other modules to keep the UI in sync.
    self:RegisterMessage("ELOG_ADDON_ENABLED", "UpdateDisplay")
    self:RegisterMessage("ELOG_ADDON_DISABLED", "Hide")
    self:RegisterMessage("ELOG_LINE_ADDED", "UpdateDisplay")
    self:RegisterMessage("ELOG_SESSIONS_TRIMMED", "UpdateDisplay")
    self:RegisterMessage("ELOG_SESSIONS_CLEARED", "UpdateDisplay")
    self:RegisterMessage("ELOG_TIMESTAMP_VISIBILITY_CHANGED", "UpdateDisplay")
    self:RegisterMessage("ELOG_FRAME_LOCK_CHANGED", "OnFrameLockChanged")
end

function UI:CreateMainFrame()
    local f = CreateFrame("Frame", "eLogFrame", UIParent, "BackdropTemplate")
    f:SetSize(450, 350)
    f:SetPoint("CENTER")
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:SetUserPlaced(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    f:SetBackdropColor(unpack(colors.background))
    f:SetBackdropBorderColor(unpack(colors.border))
    f:Hide()
    self.mainFrame = f

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -8)
    title:SetText("eLog - Event Log")

    -- Use a non-global name for the scroll frame to avoid conflicts.
    local scroll = CreateFrame("ScrollFrame", "eLogScrollFrame_Internal", f, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 10, -30)
    scroll:SetPoint("BOTTOMRIGHT", -30, 10)
    self.scrollFrame = scroll -- Store a reference to it.

    local container = CreateFrame("Frame", nil, scroll)
    container:SetSize(400, 1)
    scroll:SetScrollChild(container)
    self.container = container
end

function UI:Toggle()
    if self.mainFrame:IsShown() then
        self:Hide()
    else
        self:Show()
    end
end

function UI:Show()
    self:UpdateDisplay()
    self.mainFrame:Show()
end

function UI:Hide()
    if self.mainFrame then
        self.mainFrame:Hide()
    end
end

function UI:UpdateDisplay()
    if not self.mainFrame or not self.mainFrame:IsShown() then return end

    -- Reset scroll position using our stored reference.
    self.scrollFrame:SetVerticalScroll(0)

    -- Note: This section aggregates all lines from all sessions every update.
    -- For most use cases, this is perfectly fine. For extreme performance needs,
    -- one could implement a more complex system that only adds the newest line to the top.
    local allLines = {}
    local sessions = eLog.db.profile.sessions
    local sessionKeys = {}
    for k in pairs(sessions) do table.insert(sessionKeys, tonumber(k)) end
    table.sort(sessionKeys, function(a, b) return a > b end) -- Sort descending (newest first)

    for _, key in ipairs(sessionKeys) do
        local session = sessions[tostring(key)]
        if session and session.lines then
            for i = #session.lines, 1, -1 do
                table.insert(allLines, session.lines[i])
            end
        end
    end

    -- Hide all currently active frames before redrawing.
    for i = 1, activeFrames do
        if framePool[i] then framePool[i]:Hide() end
    end
    activeFrames = 0

    local yOffset = -10
    if #allLines == 0 then
        -- Display a "no logs" message.
        activeFrames = 1
        local frame = self:GetRecycledFrame(1)
        frame.text:SetText("No logs available.")
        frame.fullText = nil
        frame:ClearAllPoints()
        frame:SetPoint("TOPLEFT", 5, yOffset)
        frame:SetHeight(18)
        frame:Show()
        self.container:SetHeight(18)
    else
        -- Populate the view with all log lines.
        for i, entry in ipairs(allLines) do
            activeFrames = activeFrames + 1
            local frame = self:GetRecycledFrame(activeFrames)
            
            local text = eLog.db.profile.options.showTimestamps and (entry.timestamp .. " " .. entry.short) or entry.short
            frame.text:SetText(text)
            frame.fullText = entry.full

            local textHeight = frame.text:GetHeight()
            local frameHeight = textHeight + 4 -- Add some padding
            frame:SetHeight(frameHeight)

            frame:ClearAllPoints()
            frame:SetPoint("TOPLEFT", 5, yOffset)
            frame:Show()

            yOffset = yOffset - frameHeight - 2
        end
        self.container:SetHeight(math.abs(yOffset))
    end

    -- Adjust container width based on whether the scrollbar is visible.
    if self.container:GetHeight() > self.scrollFrame:GetHeight() then
        self.container:SetWidth(self.mainFrame:GetWidth() - 40) -- Space for scrollbar
    else
        self.container:SetWidth(self.mainFrame:GetWidth() - 20)
    end
end

function UI:GetRecycledFrame(index)
    if not framePool[index] then
        -- Create a new line frame if the pool is not large enough.
        local frame = CreateFrame("Button", "eLogLineFrame" .. index, self.container)
        frame:SetWidth(self.container:GetWidth() - 10)
        
        local text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        text:SetPoint("LEFT", 5, 0)
        text:SetPoint("RIGHT", -5, 0)
        text:SetJustifyH("LEFT")
        text:SetTextColor(unpack(colors.text))
        frame.text = text

        frame:SetScript("OnEnter", function(self)
            self.text:SetTextColor(unpack(colors.highlight))
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(self.fullText or "No details available.", 1, 1, 1, 1, true)
            GameTooltip:Show()
        end)
        frame:SetScript("OnLeave", function(self)
            self.text:SetTextColor(unpack(colors.text))
            GameTooltip:Hide()
        end)
        framePool[index] = frame
    end
    return framePool[index]
end

function UI:OnFrameLockChanged(event, isLocked)
    self.mainFrame:SetMovable(not isLocked)
end
