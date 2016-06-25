-- Misty by Counsel
-- Version 0.1.0.0 - Build 1-1

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
MistyTbl.constants.UI_TITLE = "Misty - Version 0.1.0.0b"
MistyTbl.constants.ADDON_PREFIX = "Misty_msg"
-- Set the maximum length of a post to the maximum length of a character name subtracted from the maximum length of a message
MistyTbl.constants.MAX_LETTERS = 255 - 12
MistyTbl.constants.LIST_LIMIT = 5
MistyTbl.vars = {}
MistyTbl.vars.currPage = 1

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
	if postText ~= "" then
		SendAddonMessage(MistyTbl.constants.ADDON_PREFIX, postText, "GUILD")
	else
		UIErrorsFrame:AddMessage('Warning. Empty message not sent.', 1.0, 1.0, 1.0, 5.0)
	end
end

function MistyTbl.list.init(MistyUI)
	-- Load Saved Variables
	if not Misty then
		Misty = {}
		Misty.posts = {}
	end	
	
	MistyUI.postEntries = {}
	for i = 1, MistyTbl.constants.LIST_LIMIT do
		MistyUI.postEntries[i] = CreateFrame("Button", "MistyUI_Entry"..i, MistyUI.postList)
		MistyUI.postEntries[i]:SetWidth(346)
		MistyUI.postEntries[i]:SetHeight(60)
		MistyUI.postEntries[i]:SetNormalFontObject("GameFontNormal")
		MistyUI.postEntries[i]:SetHighlightFontObject("GameFontHighlight")
		MistyUI.postEntries[i]:SetBackdrop({ 
			bgFile = "Interface/Buttons/UI-SliderBar-Background"
		})
		if i > 1 then
			MistyUI.postEntries[i]:SetPoint("TOPLEFT", MistyUI.postEntries[i - 1], "BOTTOMLEFT")
		else
			MistyUI.postEntries[i]:SetPoint("TOPLEFT", MistyUI.postList, "TOPLEFT", 2, -1)
		end
	end
	MistyTbl.list.UpdateEntries(MistyUI, 1)
end

function MistyTbl.list.addPost(MistyUI, sender, message)
	local index = #Misty.posts + 1
	Misty.posts[index] = {}
	Misty.posts[index].sender = sender
	Misty.posts[index].message = MistyUI.postTextBox:GetText()
	-- Check if the user is currently viewing the last page of the list
	if (MistyTbl.vars.currPage * MistyTbl.constants.LIST_LIMIT) >= #Misty.posts then
		-- If so, trigger the update of the next free button
		MistyTbl.list.UpdateEntry(MistyUI, sender, message)
	end
end

function MistyTbl.list.UpdateEntry(MistyUI, sender, message)
	-- Determine the next free button by using the remainder (between 1 and the limit) as the index
	local index = #Misty.posts % MistyTbl.constants.LIST_LIMIT
	-- If the net free button is the fifth, the remainder would be 0, so set the index to 5
	if index == 0 then
		index = 5
	end
	MistyUI.postEntries[index]:SetText(sender..'\n'..message)
end

function MistyTbl.list.UpdateEntries(MistyUI, startIndex)
	for i = startIndex, MistyTbl.constants.LIST_LIMIT do
		MistyUI.postEntries[i]:SetText(Misty.posts[i].sender..'\n'..Misty.posts[i].message)
	end
end

function MistyTbl.list.resetList(MistyUI)
	if Misty.posts[1] then
		for i = 1, MistyTbl.constants.LIST_LIMIT do
			MistyUI.postEntries[i]:SetText()
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
MistyUI.title:SetText(MistyTbl.constants.UI_TITLE)
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

MistyUI.postList = CreateFrame("Frame", "Post_List_Frame", MistyUI)
MistyUI.postList:SetWidth(350)
MistyUI.postList:SetHeight(300)
MistyUI.postList:SetPoint("TOPLEFT", MistyUI.postBtn, "BOTTOMLEFT", 0, -20)
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
			local colouredByClass = MistyTbl.utils.classColour(Ambiguate(sender, "none"))
			if sender == MistyTbl.vars.playerFullName then
				MistyTbl.list.addPost(MistyUI, colouredByClass, message)
			else
				MistyTbl.utils.speak('Message successfully sent.')
			end
		end
	end
end
MistyUI:SetScript("OnEvent", Misty_Event_Handler)
--MistyUI:Hide()