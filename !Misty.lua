-- Misty by Counsel
-- Version 0.1.0.0 - Build 1-3

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
MistyTbl.constants.ADDON_PREFIX_INITIAL = "Misty_i"
MistyTbl.constants.ADDON_PREFIX_REQ_META = "Misty_r_m"
MistyTbl.constants.ADDON_PREFIX_SEND_META = "Misty_s_m"
MistyTbl.constants.ADDON_PREFIX_DELETE = "Misty_d"
MistyTbl.constants.ADDON_PREFIX_EDIT = "Misty_e"
-- Set the maximum length of a post to the maximum length of a character name subtracted from the maximum length of a message
MistyTbl.constants.MAX_LETTERS = 255 - 12
MistyTbl.constants.LIST_LIMIT = 4
MistyTbl.vars = {}
-- The current page in the list of entries
MistyTbl.vars.currPage = 1
-- The total pages in the list of entries
MistyTbl.vars.totalPages = 1
-- The variable to temporarily store the ID generated when the user clicks submit for a message
MistyTbl.vars.id = ''
MistyTbl.vars.playerName, MistyTbl.vars.playerRealm, MistyTbl.vars.playerFullName = '', '', ''
MistyTbl.vars.currEdit = {}
MistyTbl.vars.editIndex = 0

-- Define the table to contain the functions for the list
MistyTbl.list = {}
-- Initialise the table to temporarily store the initial message received from another client
MistyTbl.temp = {}
MistyTbl.temp[1] = {}
-- The variable used to flag the addon as waiting for metadata for a message from another client
MistyTbl.request = false
-- Define the table to contain utility functions
MistyTbl.utils = {}

function MistyTbl.list.init(MistyUI)
	-- Load Saved Variables
	if not Misty then
		Misty = {}
		Misty.posts = {}
	end	
	
	MistyTbl.vars.playerName, MistyTbl.vars.playerRealm = UnitFullName("player")
	MistyTbl.vars.playerFullName = MistyTbl.vars.playerName..'-'..MistyTbl.vars.playerRealm
	
	MistyUI.postEntries = {}
	for i = 1, MistyTbl.constants.LIST_LIMIT do
		MistyUI.postEntries[i] = CreateFrame("Button", "MistyUI_Entry"..i, MistyUI.postList)
		MistyUI.postEntries[i]:SetWidth(341)
		MistyUI.postEntries[i]:SetHeight(110)
		MistyUI.postEntries[i].sender = MistyUI.postEntries[i]:CreateFontString(MistyUI.postEntries[i]:GetName()..'sender', "OVERLAY", "GameFontHighlight")
		MistyUI.postEntries[i].sender:SetPoint("TOPLEFT", MistyUI.postEntries[i], "TOPLEFT", 10, -7)
		MistyUI.postEntries[i].sender:SetSize(325, 10)
		MistyUI.postEntries[i].sender:SetJustifyH("LEFT")
		MistyUI.postEntries[i].message = MistyUI.postEntries[i]:CreateFontString(MistyUI.postEntries[i]:GetName()..'message', "OVERLAY", "GameFontHighlight")
		MistyUI.postEntries[i].message:SetPoint("TOPLEFT", MistyUI.postEntries[i].sender, "BOTTOMLEFT", 2, -10)
		MistyUI.postEntries[i].message:SetSize(325, 75)
		MistyUI.postEntries[i].message:SetJustifyH("LEFT")
		MistyUI.postEntries[i]:SetNormalFontObject("GameFontNormal")
		MistyUI.postEntries[i]:SetHighlightFontObject("GameFontHighlight")
		MistyUI.postEntries[i]:SetBackdrop({ 
			bgFile = "Interface/Buttons/UI-SliderBar-Background"
		})
		if i > 1 then
			MistyUI.postEntries[i]:SetPoint("TOPLEFT", MistyUI.postEntries[i - 1], "BOTTOMLEFT", 0, -2)
		else
			MistyUI.postEntries[i]:SetPoint("TOPLEFT", MistyUI.postList, "TOPLEFT", 4, -4)
		end
		MistyUI.postEntries[i].editBtn = CreateFrame("Button", "MistyUI_Entry_EditBtn"..i, MistyUI.postList, "GameMenuButtonTemplate")
		MistyUI.postEntries[i].editBtn:SetWidth(60)
		MistyUI.postEntries[i].editBtn:SetHeight(30)
		MistyUI.postEntries[i].editBtn:SetText('Edit')
		MistyUI.postEntries[i].editBtn:SetPoint("TOPLEFT", MistyUI.postEntries[i], "TOPRIGHT", 5, -20)
		MistyUI.postEntries[i].editBtn:SetNormalFontObject("GameFontNormal")
		MistyUI.postEntries[i].editBtn:SetHighlightFontObject("GameFontHighlight")
		MistyUI.postEntries[i].editBtn:SetScript("OnClick", function(self)
			MistyTbl.vars.editIndex = MistyUI.postEntries[i].postIndex
			MistyTbl.list.displayEdit(MistyUI, MistyUI.postEntries[i])
		end)
		MistyUI.postEntries[i].editBtn:Disable()
		MistyUI.postEntries[i].deleteBtn = CreateFrame("Button", "MistyUI_Entry_EditBtn"..i, MistyUI.postList, "GameMenuButtonTemplate")
		MistyUI.postEntries[i].deleteBtn:SetWidth(60)
		MistyUI.postEntries[i].deleteBtn:SetHeight(30)
		MistyUI.postEntries[i].deleteBtn:SetText('Delete')
		MistyUI.postEntries[i].deleteBtn:SetPoint("TOPLEFT", MistyUI.postEntries[i].editBtn, "BOTTOMLEFT", 0, -10)
		MistyUI.postEntries[i].deleteBtn:SetNormalFontObject("GameFontNormal")
		MistyUI.postEntries[i].deleteBtn:SetHighlightFontObject("GameFontHighlight")
		MistyUI.postEntries[i].deleteBtn:SetScript("OnClick", function(self)
			SendAddonMessage(MistyTbl.constants.ADDON_PREFIX_DELETE, MistyUI.postEntries[i].postIndex, "GUILD")
		end)
		MistyUI.postEntries[i].deleteBtn:Disable()
	end
	MistyTbl.list.UpdateEntries(MistyUI, 1)
end

function MistyTbl.utils.postSubmitHandler(MistyUI, postText)
	if postText ~= "" then
		SendAddonMessage(MistyTbl.constants.ADDON_PREFIX_INITIAL, postText, "GUILD")
		MistyTbl.vars.id = GetTime()
	else
		UIErrorsFrame:AddMessage('Warning. Empty message not sent.', 1.0, 1.0, 1.0, 5.0)
	end
end

function MistyTbl.list.addPost(MistyUI, character, sender, message, id)
	local index = #Misty.posts + 1
	Misty.posts[index] = {}
	Misty.posts[index].postIndex = index
	Misty.posts[index].character = character
	Misty.posts[index].sender = sender
	Misty.posts[index].message = message
	Misty.posts[index].id = id
	-- Check if the user is currently viewing the last page of the list
	if (MistyTbl.vars.currPage * MistyTbl.constants.LIST_LIMIT) >= #Misty.posts then
		-- If so, trigger the update of the next free button
		MistyTbl.list.UpdateEntry(MistyUI, index, character, sender, message)
	else
		MistyTbl.list.UpdateEntries(MistyUI, MistyTbl.utils.newIndex())
	end
end

function MistyTbl.list.UpdateEntry(MistyUI, index, character, sender, message)
	-- Determine the next free button by using the remainder (between 1 and the limit) as the index
	local index = #Misty.posts % MistyTbl.constants.LIST_LIMIT
	-- If the next free button is the last one, the remainder would be 0, so set the index to the last button
	if index == 0 then
		index = MistyTbl.constants.LIST_LIMIT
	end
	MistyUI.postEntries[index].postIndex = index
	MistyUI.postEntries[index].character = character
	MistyUI.postEntries[index].sender:SetText(sender)
	MistyUI.postEntries[index].message:SetText(message)
	if MistyUI.postEntries[index].character == MistyTbl.vars.playerFullName then
		MistyUI.postEntries[index].editBtn:Enable()
		MistyUI.postEntries[index].deleteBtn:Enable()
	end
	MistyTbl.list.UpdateEntries(MistyUI, MistyTbl.utils.newIndex())
end

function MistyTbl.list.UpdateEntries(MistyUI, postIndex)
	for i = 1, MistyTbl.constants.LIST_LIMIT do
		if Misty.posts[postIndex] then
			MistyUI.postEntries[i].postIndex = postIndex
			MistyUI.postEntries[i].character = Misty.posts[postIndex].character
			MistyUI.postEntries[i].sender:SetText(Misty.posts[postIndex].sender)
			MistyUI.postEntries[i].message:SetText(Misty.posts[postIndex].message)
			MistyUI.postEntries[i].id = Misty.posts[postIndex].id
			postIndex = postIndex + 1
			if MistyUI.postEntries[i].character == MistyTbl.vars.playerFullName then
				MistyUI.postEntries[i].editBtn:Enable()
				MistyUI.postEntries[i].deleteBtn:Enable()
			end
		else
			MistyUI.postEntries[i].character = ''
			MistyUI.postEntries[i].sender:SetText()
			MistyUI.postEntries[i].message:SetText()
			MistyUI.postEntries[i].id = ''
			MistyUI.postEntries[i].editBtn:Disable()
			MistyUI.postEntries[i].deleteBtn:Disable()
		end
	end
	if MistyTbl.vars.currPage == 1 then
		MistyUI.prevBtn:Disable()
	else
		MistyUI.prevBtn:Enable()
	end
	if #Misty.posts <= (MistyTbl.vars.currPage * MistyTbl.constants.LIST_LIMIT) then
		MistyUI.nextBtn:Disable()
	else
		MistyUI.nextBtn:Enable()
	end
	MistyTbl.vars.totalPages = math.max(ceil(#Misty.posts / MistyTbl.constants.LIST_LIMIT), 1)
	MistyUI.postListHeader:SetText(string.format("Page %s of %s", MistyTbl.vars.currPage, MistyTbl.vars.totalPages))
end

function MistyTbl.list.resetList(MistyUI)
	if Misty.posts[1] then
		for i = 1, MistyTbl.constants.LIST_LIMIT do
			MistyUI.postEntries[i].character = ''
			MistyUI.postEntries[i].sender:SetText()
			MistyUI.postEntries[i].message:SetText()
			MistyUI.postEntries[i].editBtn:Hide()
			MistyUI.postEntries[i].deleteBtn:Hide()
		end
	end
	Misty.posts = {}
	MistyUI.posts = {}
	MistyTbl.list.UpdateEntries(MistyUI, 1)
	MistyTbl.utils.speak('The list has been reset.')
end

function MistyTbl.list.displayEdit(MistyUI, postEntry)
	MistyTbl.vars.currEdit = postEntry
	MistyUI.postEditFrame:Show()
	MistyUI.postEditFrame.postEditTextBox:SetText(postEntry.message:GetText())
end

function MistyTbl.list.delete(MistyUI, postIndex)
	table.remove(Misty.posts, postIndex)
	if #Misty.posts == ((MistyTbl.vars.currPage - 1) * MistyTbl.constants.LIST_LIMIT) then
		MistyTbl.vars.currPage = MistyTbl.vars.currPage - 1
	end
	MistyTbl.list.UpdateEntries(MistyUI, MistyTbl.utils.newIndex())
end

function MistyTbl.list.edit(MistyUI, postIndex, newMessage)
	Misty.posts[postIndex].message = newMessage
	MistyTbl.list.UpdateEntries(MistyUI, MistyTbl.utils.newIndex())
	MistyUI.postEditFrame:Hide()
	MistyUI.postEditFrame.postEditTextBox:SetText('')
end

function MistyTbl.list.previousPage(MistyUI)
	if MistyTbl.vars.currPage > 1 then
		MistyTbl.vars.currPage = MistyTbl.vars.currPage - 1
		MistyTbl.list.UpdateEntries(MistyUI, MistyTbl.utils.newIndex())
	end
end

function MistyTbl.list.nextPage(MistyUI)
	if (#Misty.posts > (MistyTbl.vars.currPage * MistyTbl.constants.LIST_LIMIT)) then
		MistyTbl.vars.currPage = MistyTbl.vars.currPage + 1
		MistyTbl.list.UpdateEntries(MistyUI, MistyTbl.utils.newIndex())
	end
end

function MistyTbl.utils.newIndex()
	return ((MistyTbl.vars.currPage * MistyTbl.constants.LIST_LIMIT) - (MistyTbl.constants.LIST_LIMIT - 1))
end

function MistyTbl.utils.makeMovable(frame)
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
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

function MistyTbl.utils.messageHandler(MistyUI, prefix, message, channel, sender)
	if prefix == MistyTbl.constants.ADDON_PREFIX_INITIAL then
		local colouredByClass = MistyTbl.utils.classColour(Ambiguate(sender, "none"))
		if sender == MistyTbl.vars.playerFullName then
			MistyTbl.temp[1].sender = sender
			MistyTbl.temp[1].message = message
			SendAddonMessage(MistyTbl.constants.ADDON_PREFIX_REQ_META, sender, "GUILD")
			MistyUI.postBtn:Disable()
		end
	elseif prefix == MistyTbl.constants.ADDON_PREFIX_REQ_META then
		-- Respond to a request for metadata if the sender of the original message is the player
		if message == MistyTbl.vars.playerFullName then
			SendAddonMessage(MistyTbl.constants.ADDON_PREFIX_SEND_META, MistyTbl.vars.id, "GUILD")
			MistyTbl.vars.request = true
		end
	elseif prefix == MistyTbl.constants.ADDON_PREFIX_SEND_META then
		if MistyTbl.vars.request == true then
			MistyTbl.temp[1].id = message
			local colouredByClass = MistyTbl.utils.classColour(Ambiguate(MistyTbl.temp[1].sender, "none"))
			MistyTbl.list.addPost(MistyUI, MistyTbl.temp[1].sender, colouredByClass, MistyTbl.temp[1].message, MistyTbl.temp[1].id)
			MistyTbl.temp[1] = {}
			MistyTbl.vars.request = false
			MistyUI.postBtn:Enable()
		end
	elseif prefix == MistyTbl.constants.ADDON_PREFIX_DELETE then
		MistyTbl.list.delete(MistyUI, tonumber(message))
	elseif prefix == MistyTbl.constants.ADDON_PREFIX_EDIT then
		local postIndex, newMessage = strsplit("|", message, 2)
		MistyTbl.list.edit(MistyUI, tonumber(postIndex), newMessage)
	end
end

-- Define the frame table which will be used to store everything to be used in it

local MistyUI = CreateFrame("Frame", "Misty_UI_Frame", UIParent, "BasicFrameTemplateWithInset")
MistyUI:SetSize(440, 680)
MistyUI:SetPoint("TOP", UIParent, "TOP", 0, -200)
MistyUI.title = MistyUI:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
MistyUI.title:SetPoint("CENTER", MistyUI.TitleBg, "CENTER", 5, 0)
MistyUI.title:SetText(MistyTbl.constants.UI_TITLE)
MistyUI:RegisterEvent("ADDON_LOADED")
MistyUI:RegisterEvent("CHAT_MSG_ADDON")
MistyTbl.utils.makeMovable(MistyUI)
--MistyUI:SetUserPlaced(enable)
MistyUI.posts = {}

MistyUI.postTextBoxLabel = MistyUI:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
MistyUI.postTextBoxLabel:SetPoint("TOPLEFT", MistyUI.TitleBg, "BOTTOMLEFT", 10, -10)
MistyUI.postTextBoxLabel:SetSize(100, 40)
MistyUI.postTextBoxLabel:SetText("Enter Message:")

MistyUI.postTextBox = CreateFrame("EditBox", nil, MistyUI)
MistyUI.postTextBox:SetPoint("TOP", MistyUI.TitleBg, "BOTTOM", 0, -20)
MistyUI.postTextBox:SetPoint("BOTTOM", MistyUI.TitleBg, "TOP", 0, -103)
MistyUI.postTextBox:SetPoint("LEFT", MistyUI.postTextBoxLabel, "RIGHT", 10, 0)
MistyUI.postTextBox:SetPoint("RIGHT", MistyUI, "RIGHT", -20, 0)
MistyUI.postTextBox:SetAutoFocus(false)
MistyUI.postTextBox:SetMaxLetters(MistyTbl.constants.MAX_LETTERS)
MistyUI.postTextBox:SetMultiLine(true)
MistyUI.postTextBox:SetJustifyH("LEFT")
MistyUI.postTextBox:SetJustifyV("CENTER")
MistyUI.postTextBox:SetFont("Fonts\\FRIZQT__.TTF", 10)
MistyUI.postTextBox:SetBackdropBorderColor(0.3, 0.3, 0.3)
-- Left, Right, Top, Bottom
MistyUI.postTextBox:SetTextInsets(10, 10, 5, 0)
MistyUI.postTextBox:SetBackdrop({
	bgFile = "Interface/Buttons/UI-SliderBar-Background",
	edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
	edgeSize = 15,
	insets = {left = 2, right = 1, top = 1, bottom = 1},
})

MistyUI.postBtn = CreateFrame("Button", nil, MistyUI, "GameMenuButtonTemplate")
MistyUI.postBtn:SetPoint("TOPLEFT", MistyUI.postTextBox, "BOTTOMLEFT", 0, -10)
MistyUI.postBtn:SetSize(80, 25)
MistyUI.postBtn:SetText("Submit")
MistyUI.postBtn:SetNormalFontObject("GameFontNormal")
MistyUI.postBtn:SetHighlightFontObject("GameFontHighlight")
MistyUI.postBtn:SetScript("OnClick", function(self)
	MistyTbl.utils.postSubmitHandler(self:GetParent(), MistyUI.postTextBox:GetText())
end)

MistyUI.resetBtn = CreateFrame("Button", nil, MistyUI, "GameMenuButtonTemplate")
MistyUI.resetBtn:SetPoint("LEFT", MistyUI.postBtn, "RIGHT", 20, 0)
MistyUI.resetBtn:SetSize(80, 25)
MistyUI.resetBtn:SetText("Reset")
MistyUI.resetBtn:SetNormalFontObject("GameFontNormal")
MistyUI.resetBtn:SetHighlightFontObject("GameFontHighlight")
MistyUI.resetBtn:SetScript("OnClick", function(self)
	MistyTbl.list.resetList(MistyUI)
end)

MistyUI.postList = CreateFrame("Frame", "Post_List_Frame", MistyUI)
MistyUI.postList:SetWidth(350)
MistyUI.postList:SetHeight(455)
MistyUI.postList:SetPoint("TOPLEFT", MistyUI.postTextBoxLabel, "BOTTOMLEFT", 5, -95)
MistyUI.postList:SetBackdrop({ 
  bgFile = "Interface/ACHIEVEMENTFRAME/UI-Achievement-Parchment-Horizontal", 
  edgeFile = "Interface/Tooltips/UI-Tooltip-Border", tile = false, tileSize = 16, edgeSize = 16, 
  insets = { left = 4, right = 4, top = 4, bottom = 4 }
})

MistyUI.postListHeader = MistyUI:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
MistyUI.postListHeader:SetPoint("BOTTOM", MistyUI.postList, "TOP", 0, 0)
MistyUI.postListHeader:SetSize(200, 20)

MistyUI.postListOptionsHeader = MistyUI:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
MistyUI.postListOptionsHeader:SetPoint("BOTTOMLEFT", MistyUI.postList, "TOPRIGHT")
MistyUI.postListOptionsHeader:SetSize(60, 20)
MistyUI.postListOptionsHeader:SetText('Options')

MistyUI.prevBtn = CreateFrame("Button", nil, MistyUI, "GameMenuButtonTemplate")
MistyUI.prevBtn:SetPoint("TOPLEFT", MistyUI.postList , "BOTTOMLEFT", 0, -10)
MistyUI.prevBtn:SetSize(140, 30)
MistyUI.prevBtn:SetText("Previous")
MistyUI.prevBtn:SetNormalFontObject("GameFontNormal")
MistyUI.prevBtn:SetHighlightFontObject("GameFontHighlight")
MistyUI.prevBtn:SetScript("OnClick", function(self)
	MistyTbl.list.previousPage(MistyUI)
end)

MistyUI.nextBtn = CreateFrame("Button", nil, MistyUI, "GameMenuButtonTemplate")
MistyUI.nextBtn:SetPoint("LEFT", MistyUI.prevBtn, "RIGHT", 20, 0)
MistyUI.nextBtn:SetSize(140, 30)
MistyUI.nextBtn:SetText("Next")
MistyUI.nextBtn:SetNormalFontObject("GameFontNormal")
MistyUI.nextBtn:SetHighlightFontObject("GameFontHighlight")
MistyUI.nextBtn:SetScript("OnClick", function(self)
	MistyTbl.list.nextPage(MistyUI)
end)

MistyUI.postEditFrame = CreateFrame("Frame", "Misty_UI_Edit_Frame", UIParent, "BasicFrameTemplateWithInset")
MistyUI.postEditFrame:SetWidth(440)
MistyUI.postEditFrame:SetHeight(120)
MistyUI.postEditFrame:SetPoint("CENTER", UIParent, "CENTER")
MistyUI.postEditFrame:SetFrameStrata("DIALOG")
MistyUI.postEditFrame.title = MistyUI.postEditFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
MistyUI.postEditFrame.title:SetPoint("CENTER", MistyUI.postEditFrame.TitleBg, "CENTER", 5, 0)
MistyUI.postEditFrame.title:SetText('Edit box')
MistyUI.postEditFrame:Hide()
MistyTbl.utils.makeMovable(MistyUI.postEditFrame)

MistyUI.postEditFrame.postEditTextBox = CreateFrame("EditBox", nil, MistyUI.postEditFrame, "InputBoxTemplate")
MistyUI.postEditFrame.postEditTextBox:SetPoint("TOPLEFT", MistyUI.postEditFrame, "TOPLEFT", 20, -40)
MistyUI.postEditFrame.postEditTextBox:SetSize(270, 20)
MistyUI.postEditFrame.postEditTextBox:SetAutoFocus(false)
MistyUI.postEditFrame.postEditTextBox:SetFrameLevel(255)
MistyUI.postEditFrame.postEditTextBox:SetMaxLetters(MistyTbl.constants.MAX_LETTERS)

MistyUI.postEditFrame.postBtn = CreateFrame("Button", nil, MistyUI.postEditFrame, "GameMenuButtonTemplate")
MistyUI.postEditFrame.postBtn:SetPoint("TOPLEFT", MistyUI.postEditFrame.postEditTextBox, "BOTTOMLEFT", 0, -10)
MistyUI.postEditFrame.postBtn:SetSize(140, 30)
MistyUI.postEditFrame.postBtn:SetText("Submit")
MistyUI.postEditFrame.postBtn:SetNormalFontObject("GameFontNormal")
MistyUI.postEditFrame.postBtn:SetHighlightFontObject("GameFontHighlight")
MistyUI.postEditFrame.postBtn:SetScript("OnClick", function(self)
	local newMessage = MistyUI.postEditFrame.postEditTextBox:GetText()
	SendAddonMessage(MistyTbl.constants.ADDON_PREFIX_EDIT, MistyTbl.vars.editIndex..'|'..newMessage, "GUILD")
end)

MistyUI.postEditFrame.cancelBtn = CreateFrame("Button", nil, MistyUI.postEditFrame, "GameMenuButtonTemplate")
MistyUI.postEditFrame.cancelBtn:SetPoint("LEFT", MistyUI.postEditFrame.postBtn, "RIGHT", 20, 0)
MistyUI.postEditFrame.cancelBtn:SetSize(140, 30)
MistyUI.postEditFrame.cancelBtn:SetText("Cancel")
MistyUI.postEditFrame.cancelBtn:SetNormalFontObject("GameFontNormal")
MistyUI.postEditFrame.cancelBtn:SetHighlightFontObject("GameFontHighlight")
MistyUI.postEditFrame.cancelBtn:SetScript("OnClick", function(self)
	MistyUI.postEditFrame:Hide()
	MistyUI.postEditFrame.postEditTextBox:SetText('')
end)

-- Addon Event Handler
function Misty_Event_Handler(self, event, ...)
	if event == "ADDON_LOADED" and ... == "!Misty" then
		MistyTbl.list.init(MistyUI)
		MistyUI:UnregisterEvent("ADDON_LOADED")
	end
	if event == "CHAT_MSG_ADDON" then
		MistyTbl.vars.prefixReg = RegisterAddonMessagePrefix(MistyTbl.constants.ADDON_PREFIX_INITIAL)
		MistyTbl.vars.prefixReg = RegisterAddonMessagePrefix(MistyTbl.constants.ADDON_PREFIX_REQ_META)
		MistyTbl.vars.prefixReg = RegisterAddonMessagePrefix(MistyTbl.constants.ADDON_PREFIX_SEND_META)
		local prefix, message, channel, sender = ...
		MistyTbl.utils.messageHandler(MistyUI, prefix, message, channel, sender)
	end
end

MistyUI:SetScript("OnEvent", Misty_Event_Handler)
--MistyUI:Hide()