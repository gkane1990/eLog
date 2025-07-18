-- File: eLog_UI.lua
-- Purpose: Manages the creation, display, and interaction of all UI elements.

-- Correct way to get the addon object in a module file.
local eLog = LibStub("AceAddon-3.0"):GetAddon("eLog")
local UI = eLog:NewModule("UI", "AceEvent-3.0")

local colors = {
    text = { 0.9, 0.9, 0.9, 1 },
    highlight = { 1.0, 0.82, 0.0, 1 },
    background = { 0.1, 0.1, 0.1, 0.85 },
    border = { 0.3, 0.3, 0.3, 1.0 },
}
local framePool = {}
local activeFrames = 0

function UI:OnInitialize()
    self:CreateMainFrame()
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

    local scroll = CreateFrame("ScrollFrame", "eLogScrollFrame", f, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 10, -30)
    scroll:SetPoint("BOTTOMRIGHT", -30, 10)

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

    -- Reset scroll position using the correct API
    eLogScrollFrame:SetVerticalScroll(0)

    local allLines = {}
    local sessions = eLog.db.profile.sessions
    local sessionKeys = {}
    for k in pairs(sessions) do table.insert(sessionKeys, tonumber(k)) end
    table.sort(sessionKeys, function(a, b) return a > b end)

    for _, key in ipairs(sessionKeys) do
        local session = sessions[tostring(key)]
        if session and session.lines then
            for i = #session.lines, 1, -1 do
                table.insert(allLines, session.lines[i])
            end
        end
    end

	local linesCount = #allLines
    for i = 1, activeFrames do
        local frame = framePool[i]
        if frame then
            frame:Hide()
        end
    end
    activeFrames = 0

    local yOffset = -10
    if linesCount == 0 then
        activeFrames = activeFrames + 1
        local frame = self:GetRecycledFrame(activeFrames)
        frame.text:SetText("No logs available.")
        frame.fullText = nil
        frame:ClearAllPoints()
        frame:SetPoint("TOPLEFT", 5, yOffset)
        frame:SetHeight(18)
        frame:Show()
        self.container:SetHeight(18)
    else
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
	if self.container:GetHeight() > self.mainFrame:GetHeight() then
		self.container:SetWidth(self.mainFrame:GetWidth() - 30)
	else
		self.container:SetWidth(self.mainFrame:GetWidth() - 10)
	end
end

function UI:GetRecycledFrame(index)
    if not framePool[index] then
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
