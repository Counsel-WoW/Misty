-- Misty by Counsel
-- Version 0.0.1.1 - Release 5a

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
MistyTbl.vars = {}
MistyTbl.vars.playerName, MistyTbl.vars.playerRealm = UnitFullName("player")
MistyTbl.vars.playerFullName = MistyTbl.vars.playerName.."-"..MistyTbl.vars.playerRealm

-- Define utility functions
MistyTbl.utils = {}

function MistyTbl.utils.makeMovable(frame)
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
end

function MistyTbl.utils.buildList(MistyUI)
	-- Get the text in each text box
	local postText, postListText, text = MistyUI.postTextBox:GetText(), MistyUI.postListTextBox:GetText()
	-- Determine if the list box is empty to correctly handle new lines
	if postListText == "" then
		text = postText
	else
		text = postListText.."\n"..sender..": "..postText
	end
	return text
end

function MistyTbl.utils.postSubmitHandler(MistyUI, postText)
	print('Message sent. Content:', postText)
	SendAddonMessage(MistyTbl.constants.ADDON_PREFIX, postText, "GUILD")
end	

-- Load Saved Variables
if not Misty then
	Misty = {}
end


for i = 1, NUM_CHAT_WINDOWS do
	_G["ChatFrame"..i.."EditBox"]:SetAltArrowKeyMode(false)
end



-- Define the frame table which will be used to store everything to be used in it

-- Define the frame table which will be used to store everything to be used in it

local MistyUI = CreateFrame("Frame", "Misty_UI_Frame", UIParent, "BasicFrameTemplateWithInset")
MistyUI:SetSize(400, 500)
MistyUI:SetPoint("CENTER", UIParent, "CENTER")
MistyUI.title = MistyUI:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
MistyUI.title:SetPoint("CENTER", MistyUI.TitleBg, "CENTER", 5, 0)
MistyUI.title:SetText("Misty UI")
MistyUI:RegisterEvent("ADDON_LOADED")
MistyUI:RegisterEvent("CHAT_MSG_ADDON")
MistyTbl.utils.makeMovable(MistyUI)

MistyUI.postTextBoxLabel = MistyUI:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
MistyUI.postTextBoxLabel:SetPoint("LEFT", MistyUI.TitleBg, "BOTTOMLEFT", 0, -40)
MistyUI.postTextBoxLabel:SetSize(100, 40)
MistyUI.postTextBoxLabel:SetText("Enter Post:")

MistyUI.postTextBox = CreateFrame("EditBox", nil, MistyUI, "InputBoxTemplate")
MistyUI.postTextBox:SetPoint("RIGHT", MistyUI.TitleBg, "BOTTOMRIGHT", 0, -40)
MistyUI.postTextBox:SetSize(220, 20)
MistyUI.postTextBox:SetAutoFocus(false)

MistyUI.postBtn = CreateFrame("Button", nil, MistyUI, "GameMenuButtonTemplate")
MistyUI.postBtn:SetPoint("TOPLEFT", MistyUI.postTextBoxLabel, "BOTTOMLEFT", 15, -10)
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
	MistyUI.postListTextBox:SetText("")
	Misty.savedList = ""
end)

MistyUI.postListTextBox = CreateFrame("EditBox", nil, MistyUI)
MistyUI.postListTextBox:SetPoint("TOPLEFT", MistyUI.postBtn, "BOTTOMLEFT", 0, -20)
MistyUI.postListTextBox:SetSize(360, 300)
MistyUI.postListTextBox:SetAutoFocus(false)
MistyUI.postListTextBox:SetMultiLine(true)
MistyUI.postListTextBox:SetFontObject("GameFontHighlight")
MistyUI.postListTextBox:SetTextInsets(10, 10, 10, 10)
MistyUI.postListTextBox:SetBackdrop({ 
  bgFile = "Interface/ACHIEVEMENTFRAME/UI-Achievement-Parchment-Horizontal", 
  edgeFile = "Interface/Tooltips/UI-Tooltip-Border", tile = false, tileSize = 16, edgeSize = 16, 
  insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
MistyUI.postListTextBox:Disable()

MistyUI.postListScroll = CreateFrame('ScrollFrame', nil, MistyUI, 'UIPanelScrollFrameTemplate')
MistyUI.postListScroll:SetPoint('TOPLEFT', MistyUI.postBtn, 'BOTTOMLEFT', 0, -20)
MistyUI.postListScroll:SetPoint('BOTTOMRIGHT', MistyUI, 'BOTTOMRIGHT', 0, 50)
MistyUI.postListScroll:SetScrollChild(MistyUI.postListTextBox)

-- Addon Event Handler
function Misty_Event_Handler(self, event, ...)
	if event == "ADDON_LOADED" and ... == "Misty" then
		MistyUI.postListTextBox:SetText(Misty.savedList)
		MistyUI:UnregisterEvent("ADDON_LOADED")
	end
	if event == "CHAT_MSG_ADDON" then
		MistyTbl.vars.prefixReg = RegisterAddonMessagePrefix(MistyTbl.constants.ADDON_PREFIX)
		local prefix, message, channel, sender = ...
		if prefix == MistyTbl.constants.ADDON_PREFIX and sender ~= MistyTbl.vars.playerFullName then
			MistyUI.postListTextBox:SetText(MistyTbl.utils.buildList(MistyUI))
			Misty.savedList = MistyUI.postListTextBox:GetText()
		end
	end
end
MistyUI:SetScript("OnEvent", Misty_Event_Handler)