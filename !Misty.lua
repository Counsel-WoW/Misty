-- Misty by Counsel
-- Version 0.0.4.0 - Release 9a

-- Short reload slash command
SLASH_RELOADUI1 = "/rl"
SlashCmdList.RELOADUI = ReloadUI

-- short frame stack slash command
SLASH_FRAMESTK1 = "/fs"
SlashCmdList.FRAMESTK = function()
	LoadAddOn('Blizzard_DebugTools')
	FrameStackTooltip_Toggle()
end

-- Addon slash commands
SLASH_MISTY1, SLASH_MISTY2 = "/misty", "/mm"

-- Slash command handler
SlashCmdList["MISTY"] = function(arg)
	if not Misty_UI_Frame:IsShown() then
		Misty_UI_Frame:Show()
	else
		Misty_UI_Frame:Hide()
	end
end

-- Define master object for the addon
local MistyTbl = {}

-- Define string constants
MistyTbl.constants = {}
MistyTbl.constants.ADDON_PREFIX = "Misty_msg"
MistyTbl.constants.MAX_ENTRIES = 4
-- Set the maximum length of a post to the maximum length of a character name subtracted from the maximum length of a message
MistyTbl.constants.MAX_LETTERS = 255 - 12
MistyTbl.vars = {}

-- Define the table to contain the functions for the list
MistyTbl.list = {}
-- Define the table to contain utility functions
MistyTbl.utils = {}

function MistyTbl.utils.makeMovable(frame)
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
end

function MistyTbl.utils.postSubmitHandler(MistyUI, postText)
	SendAddonMessage(MistyTbl.constants.ADDON_PREFIX, postText, "GUILD")
end

function MistyTbl.list.init(MistyUI)
	-- Load Saved Variables
	if not Misty then
		Misty = {}
		Misty.posts = {}
	end

	do
		local entry = CreateFrame("Button", "Misty_postListEntry1", MistyUI.postList, "Misty_postListEntry")
		entry:SetID(1)
		entry:SetPoint("TOPLEFT", 4, 0)
		for i = 2, MistyTbl.constants.MAX_ENTRIES do
			local entry = CreateFrame("Button", "Misty_postListEntry"..i, MistyUI.postList, "Misty_postListEntry")
			entry:SetID(i)
			entry:SetPoint("TOP", "Misty_postListEntry"..(i - 1), "BOTTOM")
		end
	end
	MistyTbl.list.UpdateEntries(MistyUI)
end

function MistyTbl.list.addPost(MistyUI, sender)
	local index = #Misty.posts + 1
	Misty.posts[index] = {}
	Misty.posts[index].sender = sender
	Misty.posts[index].info = MistyUI.postTextBox:GetText()
	MistyTbl.list.UpdateEntries(MistyUI)
end

function MistyTbl.list.UpdateEntries(MistyUI)
	for i = 1, MistyTbl.constants.MAX_ENTRIES do
		local entry = Misty.posts[i]
		local frame = getglobal("Misty_postListEntry"..i)
		if entry then
			getglobal(frame:GetName().."Sender"):SetText(entry.sender)
			getglobal(frame:GetName().."Info"):SetText(entry.info)
			frame:Show()
		else
			frame:Hide()
		end
	end
end

function MistyTbl.list.resetList(MistyUI)
	if Misty.posts[1] then
		for i = 1, MistyTbl.constants.MAX_ENTRIES do
			local frame = getglobal("Misty_postListEntry"..i)
			getglobal(frame:GetName().."Sender"):SetText()
			getglobal(frame:GetName().."Info"):SetText()
			frame:Hide()
		end
	end
	Misty.posts = {}
	MistyUI.posts = {}
	MistyTbl.utils.speak('The list has been reset.')
end

function MistyTbl.utils.classColour(unit)
	local class, classFileName = UnitClass(Ambiguate(unit, "none"))
	local colour = RAID_CLASS_COLORS[classFileName]
	local formattedClassText = '|cff'..format("%02x%02x%02x", colour.r*255, colour.g*255, colour.b*255)..unit..'|r'
	return formattedClassText
end

function MistyTbl.utils.speak(text)
	local colour = RAID_CLASS_COLORS["MONK"]
	local formattedText = '|cff'..format("%02x%02x%02x", colour.r*255, colour.g*255, colour.b*255)..'Misty|r'
	print(formattedText..' says: '..text)
end

-- Define the frame table which will be used to store everything to be used in it

local MistyUI = CreateFrame("Frame", "Misty_UI_Frame", UIParent, "BasicFrameTemplateWithInset")
MistyUI:SetSize(400, 600)
MistyUI:SetPoint("CENTER", UIParent, "CENTER")
MistyUI.title = MistyUI:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
MistyUI.title:SetPoint("CENTER", MistyUI.TitleBg, "CENTER", 5, 0)
MistyUI.title:SetText("Misty UI")
MistyUI:RegisterEvent("ADDON_LOADED")
MistyUI:RegisterEvent("CHAT_MSG_ADDON")
MistyTbl.utils.makeMovable(MistyUI)
MistyUI.posts = {}

MistyUI.postTextBoxLabel = MistyUI:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
MistyUI.postTextBoxLabel:SetPoint("TOPLEFT", MistyUI.TitleBg, "BOTTOMLEFT", 17, -10)
MistyUI.postTextBoxLabel:SetSize(70, 40)
MistyUI.postTextBoxLabel:SetText("Enter Post:")

MistyUI.postTextBox = CreateFrame("EditBox", nil, MistyUI, "InputBoxTemplate")
MistyUI.postTextBox:SetPoint("LEFT", MistyUI.postTextBoxLabel, "RIGHT", 20, 0)
MistyUI.postTextBox:SetSize(270, 20)
MistyUI.postTextBox:SetAutoFocus(false)
MistyUI.postTextBox:SetMaxLetters(MistyTbl.constants.MAX_LETTERS)

MistyUI.postBtn = CreateFrame("Button", nil, MistyUI, "GameMenuButtonTemplate")
MistyUI.postBtn:SetPoint("TOPLEFT", MistyUI.postTextBoxLabel, "BOTTOMLEFT", 0, -10)
MistyUI.postBtn:SetSize(140, 30)
MistyUI.postBtn:SetText("Submit")
MistyUI.postBtn:SetNormalFontObject("GameFontNormal")
MistyUI.postBtn:SetHighlightFontObject("GameFontHighlight")
MistyUI.postBtn:SetScript("OnClick", function(self)
	MistyTbl.utils.postSubmitHandler(self:GetParent(), MistyUI.postTextBox:GetText())
end)

MistyUI.resetBtn = CreateFrame("Button", nil, MistyUI, "GameMenuButtonTemplate")
MistyUI.resetBtn:SetPoint("LEFT", MistyUI.postBtn, "RIGHT", 20, 0)
MistyUI.resetBtn:SetSize(140, 30)
MistyUI.resetBtn:SetText("Reset")
MistyUI.resetBtn:SetNormalFontObject("GameFontNormal")
MistyUI.resetBtn:SetHighlightFontObject("GameFontHighlight")
MistyUI.resetBtn:SetScript("OnClick", function(self)
	MistyTbl.list.resetList(MistyUI)
end)

MistyUI.postList = CreateFrame("Frame", nil, MistyUI)
MistyUI.postList:SetPoint("TOPLEFT", MistyUI.postListScroll, "TOPLEFT", 0, 0)
MistyUI.postList:SetPoint('TOPLEFT', MistyUI.postBtn, 'BOTTOMLEFT', 0, -20)
MistyUI.postList:SetPoint('BOTTOMRIGHT', MistyUI, 'BOTTOMRIGHT', -20, 90)
MistyUI.postList:SetBackdrop({ 
  bgFile = "Interface/ACHIEVEMENTFRAME/UI-Achievement-Parchment-Horizontal", 
  edgeFile = "Interface/Tooltips/UI-Tooltip-Border", tile = false, tileSize = 16, edgeSize = 16, 
  insets = { left = 4, right = 4, top = 4, bottom = 4 }
})

-- Addon Event Handler
function Misty_Event_Handler(self, event, ...)
	if event == "ADDON_LOADED" and ... == "!Misty" then
		MistyTbl.list.init(MistyUI)
		MistyUI:UnregisterEvent("ADDON_LOADED")
	end
	if event == "CHAT_MSG_ADDON" then
		MistyTbl.vars.prefixReg = RegisterAddonMessagePrefix(MistyTbl.constants.ADDON_PREFIX)
		local prefix, message, channel, sender = ...
		MistyTbl.vars.playerName, MistyTbl.vars.playerRealm = UnitFullName("player")
		MistyTbl.vars.playerFullName = MistyTbl.vars.playerName..'-'..MistyTbl.vars.playerRealm
		if prefix == MistyTbl.constants.ADDON_PREFIX then
			local colouredClass = MistyTbl.utils.classColour(Ambiguate(sender, "none"))
			if sender ~= MistyTbl.vars.playerFullName then
				MistyTbl.list.addPost(MistyUI, colouredClass)
			else
				MistyTbl.utils.speak('Message successfully sent.')
			end
		end
	end
end
MistyUI:SetScript("OnEvent", Misty_Event_Handler)
MistyUI:Hide()