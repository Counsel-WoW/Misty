-- Misty by Counsel
-- Version 0.1.0.0 - Build 1-5

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
MistyTbl.constants.UI_TITLE = " - Version 0.1.0.0b"
MistyTbl.constants.ADDON_PREFIX_POST = "Misty_p"
MistyTbl.constants.ADDON_PREFIX_DELETE = "Misty_d"
MistyTbl.constants.ADDON_PREFIX_EDIT = "Misty_e"
MistyTbl.constants.ADDON_PREFIX_GATHER = "Misty_g"
MistyTbl.constants.ADDON_PREFIX_COLLECT = "Misty_c"
MistyTbl.constants.ADDON_PREFIX_LOGOUT = "Misty_l"
MistyTbl.constants.MAX_LETTERS = 222
MistyTbl.constants.LIST_LIMIT = 4
-- Dimension Constants
MistyTbl.constants.SMALL_BUTTON_WIDTH = 80
MistyTbl.constants.SMALL_BUTTON_HEIGHT = 25
MistyTbl.constants.LARGE_BUTTON_WIDTH = 140
MistyTbl.constants.LARGE_BUTTON_HEIGHT = 30

MistyTbl.vars = {}
-- The current page in the main list of entries
MistyTbl.vars.mainCurrPage = 1
-- The total pages in the main list of entries
MistyTbl.vars.mainTotalPages = 1
-- The current page in the user's posts list of entries
MistyTbl.vars.userCurrPage = 1
-- The total pages in the user's posts list of entries
MistyTbl.vars.userTotalPages = 1
-- Variables to hold the various versions of the user's character's name
MistyTbl.vars.playerName, MistyTbl.vars.playerRealm, MistyTbl.vars.playerFullName = '', '', ''
-- Variable to hold the index of the post being edited
MistyTbl.vars.editIndex = 0
-- Flag to track if Misty is gathering posts from a user
MistyTbl.vars.collecting = false

-- Define the table to contain the functions for the list
MistyTbl.list = {}
-- Define the table to contain utility functions
MistyTbl.utils = {}

function MistyTbl.list.init(MistyUI)
	-- Load Saved Variables
	if not Misty or not Misty.options then
		Misty = {}
		Misty.options = {}
		Misty.options.silent = true
		Misty.options.collect = false
		Misty.posts = {}
		Misty.userPosts = {}
	end
	if Misty.options.collect == nil then
		Misty.options.collect = false
	end
	if Misty.options.silent == nil then
		Misty.options.silent = false
	end
	
	if Misty.options.collect then
		MistyUI.gatherCheckBtn:SetChecked(true)
	end
	
	if Misty.options.silent then
		MistyUI.silentCheckBtn:SetChecked(true)
	end
	
	MistyTbl.vars.playerName, MistyTbl.vars.playerRealm = UnitFullName("player")
	if MistyTbl.vars.playerRealm == nil then
		MistyTbl.vars.playerRealm = GetRealmName()
	end
	MistyTbl.vars.playerFullName = MistyTbl.vars.playerName..'-'..MistyTbl.vars.playerRealm
	
	MistyUI.postEntries = {}
	MistyUI.userPostEntries = {}
	for i = 1, MistyTbl.constants.LIST_LIMIT do
		MistyUI.postEntries[i] = CreateFrame("Button", "MistyUI_Entry"..i, MistyUI.postList)
		MistyUI.postEntries[i]:SetWidth(341)
		MistyUI.postEntries[i]:SetHeight(110)
		MistyUI.postEntries[i].sender = nil
		MistyUI.postEntries[i].character = MistyUI.postEntries[i]:CreateFontString(MistyUI.postEntries[i]:GetName()..'character', "OVERLAY", "GameFontHighlight")
		MistyUI.postEntries[i].character:SetPoint("TOPLEFT", MistyUI.postEntries[i], "TOPLEFT", 10, -7)
		MistyUI.postEntries[i].character:SetSize(325, 10)
		MistyUI.postEntries[i].character:SetJustifyH("LEFT")
		MistyUI.postEntries[i].message = MistyUI.postEntries[i]:CreateFontString(MistyUI.postEntries[i]:GetName()..'message', "OVERLAY", "GameFontHighlight")
		MistyUI.postEntries[i].message:SetPoint("TOPLEFT", MistyUI.postEntries[i].character, "BOTTOMLEFT", 2, -10)
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
		
		-- User Post Entries
		
		MistyUI.userPostEntries[i] = CreateFrame("Button", "MistyUI_Entry"..i, MistyUI.userPostList)
		MistyUI.userPostEntries[i]:SetWidth(341)
		MistyUI.userPostEntries[i]:SetHeight(110)
		MistyUI.userPostEntries[i].sender = nil
		MistyUI.userPostEntries[i].character = MistyUI.userPostEntries[i]:CreateFontString(MistyUI.userPostEntries[i]:GetName()..'character', "OVERLAY", "GameFontHighlight")
		MistyUI.userPostEntries[i].character:SetPoint("TOPLEFT", MistyUI.userPostEntries[i], "TOPLEFT", 10, -7)
		MistyUI.userPostEntries[i].character:SetSize(325, 10)
		MistyUI.userPostEntries[i].character:SetJustifyH("LEFT")
		MistyUI.userPostEntries[i].message = MistyUI.userPostEntries[i]:CreateFontString(MistyUI.userPostEntries[i]:GetName()..'message', "OVERLAY", "GameFontHighlight")
		MistyUI.userPostEntries[i].message:SetPoint("TOPLEFT", MistyUI.userPostEntries[i].character, "BOTTOMLEFT", 2, -10)
		MistyUI.userPostEntries[i].message:SetSize(325, 75)
		MistyUI.userPostEntries[i].message:SetJustifyH("LEFT")
		MistyUI.userPostEntries[i]:SetNormalFontObject("GameFontNormal")
		MistyUI.userPostEntries[i]:SetHighlightFontObject("GameFontHighlight")
		MistyUI.userPostEntries[i]:SetBackdrop({ 
			bgFile = "Interface/Buttons/UI-SliderBar-Background"
		})
		if i > 1 then
			MistyUI.userPostEntries[i]:SetPoint("TOPLEFT", MistyUI.userPostEntries[i - 1], "BOTTOMLEFT", 0, -2)
		else
			MistyUI.userPostEntries[i]:SetPoint("TOPLEFT", MistyUI.userPostList, "TOPLEFT", 4, -4)
		end
		MistyUI.userPostEntries[i].editBtn = CreateFrame("Button", "MistyUI_Entry_EditBtn"..i, MistyUI.userPostList, "GameMenuButtonTemplate")
		MistyUI.userPostEntries[i].editBtn:SetWidth(60)
		MistyUI.userPostEntries[i].editBtn:SetHeight(30)
		MistyUI.userPostEntries[i].editBtn:SetText('Edit')
		MistyUI.userPostEntries[i].editBtn:SetPoint("TOPLEFT", MistyUI.userPostEntries[i], "TOPRIGHT", 5, -20)
		MistyUI.userPostEntries[i].editBtn:SetNormalFontObject("GameFontNormal")
		MistyUI.userPostEntries[i].editBtn:SetHighlightFontObject("GameFontHighlight")
		MistyUI.userPostEntries[i].editBtn:SetScript("OnClick", function(self)
			MistyTbl.vars.editIndex = MistyUI.userPostEntries[i].postIndex
			MistyTbl.list.displayEdit(MistyUI, MistyUI.userPostEntries[i])
			MistyUI.postTextBox:ClearFocus()
		end)
		MistyUI.userPostEntries[i].deleteBtn = CreateFrame("Button", "MistyUI_Entry_EditBtn"..i, MistyUI.userPostList, "GameMenuButtonTemplate")
		MistyUI.userPostEntries[i].deleteBtn:SetWidth(60)
		MistyUI.userPostEntries[i].deleteBtn:SetHeight(30)
		MistyUI.userPostEntries[i].deleteBtn:SetText('Delete')
		MistyUI.userPostEntries[i].deleteBtn:SetPoint("TOPLEFT", MistyUI.userPostEntries[i].editBtn, "BOTTOMLEFT", 0, -10)
		MistyUI.userPostEntries[i].deleteBtn:SetNormalFontObject("GameFontNormal")
		MistyUI.userPostEntries[i].deleteBtn:SetHighlightFontObject("GameFontHighlight")
		MistyUI.userPostEntries[i].deleteBtn:SetScript("OnClick", function(self)
			SendAddonMessage(MistyTbl.constants.ADDON_PREFIX_DELETE, MistyUI.userPostEntries[i].postIndex, "GUILD")
		end)
	end
	MistyTbl.list.updateMainEntries(MistyUI, MistyUI.postEntries, 1)
	if Misty.options.collect then
		--Misty.posts = {}
		Misty.userPosts = {}
		SendAddonMessage(MistyTbl.constants.ADDON_PREFIX_GATHER, MistyTbl.vars.playerName, "GUILD")
	end
end

function MistyTbl.utils.postSubmitHandler(MistyUI, postText)
	MistyUI.postBtn:Disable()
	if postText ~= "" then
		SendAddonMessage(MistyTbl.constants.ADDON_PREFIX_POST, MistyTbl.utils.addUserClass(postText), "GUILD")
	else
		UIErrorsFrame:AddMessage('Notice.\n\nEmpty message not sent.', 1.0, 1.0, 1.0, 5.0)
	end
end

function MistyTbl.utils.addUserClass(originalMessage)
	local id = time()
	local class, classFileName = UnitClass("player")
	local classText = "-"..classFileName
	local text = originalMessage..id
	local message = text..classText
	return message
end

function MistyTbl.list.addPost(MistyUI, sender, character, message, id)
	local mainIndex = #Misty.posts + 1
	Misty.posts[mainIndex] = {}
	Misty.posts[mainIndex].postIndex = mainIndex
	Misty.posts[mainIndex].sender = sender
	Misty.posts[mainIndex].character = character
	Misty.posts[mainIndex].message = message
	Misty.posts[mainIndex].id = id
	-- Check if the user is currently viewing the last page of the lists
	if MistyUI.mainFrame:IsShown() then
		if (MistyTbl.vars.mainCurrPage * MistyTbl.constants.LIST_LIMIT) >= #Misty.posts then
			-- If so, trigger the update of the next free button
			MistyTbl.list.updateEntry(MistyUI, MistyUI.postEntries, mainIndex, sender, character, message)
		else
			MistyTbl.list.updateMainEntries(MistyUI, MistyUI.postEntries, MistyTbl.utils.newIndex(MistyUI.mainFrame:IsShown()))
		end
	elseif MistyUI.userFrame:IsShown() then
		if (MistyTbl.vars.userCurrPage * MistyTbl.constants.LIST_LIMIT) >= #Misty.posts then
			-- If so, trigger the update of the next free button
			MistyTbl.list.updateEntry(MistyUI, MistyUI.userPostEntries, userIndex, sender, character, message)
		else
			MistyTbl.list.updateUserEntries(MistyUI, MistyUI.userPostEntries, MistyTbl.utils.newIndex(MistyUI.mainFrame:IsShown()))
		end
	end
end

function MistyTbl.list.updateEntry(MistyUI, postEntries, index, sender, character, message)
	-- Determine the next free button by using the remainder (between 1 and the limit) as the index
	local index = #Misty.posts % MistyTbl.constants.LIST_LIMIT
	-- If the next free button is the last one, the remainder would be 0, so set the index to the last button
	if index == 0 then
		index = MistyTbl.constants.LIST_LIMIT
	end
	postEntries[index].postIndex = index
	postEntries[index].sender = sender
	postEntries[index].character:SetText(character)
	postEntries[index].message:SetText(message)
	MistyTbl.list.updateMainEntries(MistyUI, postEntries, MistyTbl.utils.newIndex(MistyUI.mainFrame:IsShown()))
end

function MistyTbl.list.updateMainEntries(MistyUI, postEntries, postIndex)
	for i = 1, MistyTbl.constants.LIST_LIMIT do
		if Misty.posts[postIndex] then
			postEntries[i].postIndex = postIndex
			postEntries[i].sender = Misty.posts[postIndex].sender
			postEntries[i].character:SetText(Misty.posts[postIndex].character)
			postEntries[i].message:SetText(Misty.posts[postIndex].message)
			postEntries[i].id = Misty.posts[postIndex].id
			postIndex = postIndex + 1
		else
			postEntries[i].sender = ''
			postEntries[i].character:SetText()
			postEntries[i].message:SetText()
			postEntries[i].id = ''
		end
	end
	if MistyTbl.vars.mainCurrPage == 1 or postIndex == 1 then
		MistyUI.mainPrevBtn:Disable()
	else
		MistyUI.mainPrevBtn:Enable()
	end
	if #Misty.posts <= (MistyTbl.vars.mainCurrPage * MistyTbl.constants.LIST_LIMIT) or postIndex == 1 then
		MistyUI.mainNextBtn:Disable()
	else
		MistyUI.mainNextBtn:Enable()
	end
	MistyTbl.vars.mainTotalPages = math.max(ceil(#Misty.posts / MistyTbl.constants.LIST_LIMIT), 1)
	MistyUI.postListHeader:SetText(string.format("Page %s of %s", MistyTbl.vars.mainCurrPage, MistyTbl.vars.mainTotalPages))
end

function MistyTbl.list.updateUserEntries(MistyUI, postEntries)
	local postIndex = MistyTbl.utils.newIndex(MistyUI.mainFrame:IsShown())
	for i = 1, MistyTbl.constants.LIST_LIMIT do
		if Misty.userPosts[postIndex] then
			postEntries[i].postIndex = postIndex
			postEntries[i].character:SetText("You posted: ")
			postEntries[i].message:SetText(Misty.userPosts[postIndex].message)
			postEntries[i].id = Misty.userPosts[postIndex].id
			MistyUI.userPostEntries[i].editBtn:Enable()
			MistyUI.userPostEntries[i].deleteBtn:Enable()
			postIndex = postIndex + 1
		else
			postEntries[i].character:SetText()
			postEntries[i].message:SetText()
			postEntries[i].id = ''
			MistyUI.userPostEntries[i].editBtn:Disable()
			MistyUI.userPostEntries[i].deleteBtn:Disable()
		end
	end 
	if MistyTbl.vars.userCurrPage == 1 or postIndex == 1 then
		MistyUI.userPrevBtn:Disable()
	else
		MistyUI.userPrevBtn:Enable()
	end
	if #Misty.userPosts <= (MistyTbl.vars.userCurrPage * MistyTbl.constants.LIST_LIMIT) or postIndex == 1 then
		MistyUI.userNextBtn:Disable()
	else
		MistyUI.userNextBtn:Enable()
	end
	MistyTbl.vars.userTotalPages = math.max(ceil(#Misty.userPosts / MistyTbl.constants.LIST_LIMIT), 1)
	MistyUI.userPostListHeader:SetText(string.format("Page %s of %s", MistyTbl.vars.userCurrPage, MistyTbl.vars.userTotalPages))
end

function MistyTbl.list.resetList(MistyUI)
	if Misty.posts[1] then
		for i = 1, MistyTbl.constants.LIST_LIMIT do
			MistyUI.postEntries[i].sender = ''
			MistyUI.postEntries[i].character:SetText()
			MistyUI.postEntries[i].message:SetText()
		end
	end
	Misty.posts = {}
	Misty.userPosts = {}
	MistyUI.posts = {}
	if MistyUI.mainFrame:IsShown() then
		MistyTbl.vars.mainCurrPage = 1
		MistyTbl.list.updateMainEntries(MistyUI, MistyUI.postEntries, 1)
	else
		MistyTbl.vars.userCurrPage = 1
		MistyTbl.list.updateUserEntries(MistyUI, MistyUI.postEntries, 1)
	end
	if not Misty.options.silent then
		MistyTbl.utils.speak('The list has been reset.')
	end
end

function MistyTbl.list.displayEdit(MistyUI, postEntry)
	MistyUI.postEditFrame:Show()
	MistyUI.postEditFrame.postEditTextBox:SetText(postEntry.message:GetText())
end

function MistyTbl.list.deleteEntry(MistyUI, postIndex)
	-- Check if there are no more entries in the current page
	-- Remove the selected entry from the local list
	table.remove(Misty.userPosts, postIndex)
	if #Misty.posts == ((MistyTbl.vars.userCurrPage - 1) * MistyTbl.constants.LIST_LIMIT) then
		-- If so, then the UI must show the previous page or remain on the first
		MistyTbl.vars.userCurrPage = math.max((MistyTbl.vars.userCurrPage - 1), 1)
		-- Update the UI
	end
	MistyTbl.list.updateUserEntries(MistyUI, MistyUI.userPostEntries)
end

function MistyTbl.list.edit(MistyUI, postEntries, postIndex, newMessage)
	Misty.userPosts[postIndex].message = newMessage
	MistyTbl.list.updateUserEntries(MistyUI, postEntries, MistyTbl.utils.newIndex(MistyUI.mainFrame:IsShown()))
	if not Misty.options.silent then
		MistyTbl.utils.speak('Your post was successfully modified.')
	end
	MistyUI.postEditFrame:Hide()
	MistyUI.postEditFrame.postEditTextBox:SetText("")
end

function MistyTbl.list.previousPage(MistyUI)
	if MistyUI.mainFrame:IsShown() then
		if MistyTbl.vars.mainCurrPage > 1 then
			MistyTbl.vars.mainCurrPage = MistyTbl.vars.mainCurrPage - 1
			MistyTbl.list.updateMainEntries(MistyUI, MistyUI.postEntries, MistyTbl.utils.newIndex(MistyUI.mainFrame:IsShown()))
		end
	else
		if MistyTbl.vars.userCurrPage > 1 then
			MistyTbl.vars.userCurrPage = MistyTbl.vars.userCurrPage - 1
			MistyTbl.list.updateUserEntries(MistyUI, MistyUI.userPostEntries, MistyTbl.utils.newIndex(MistyUI.mainFrame:IsShown()))
		end
	end
end

function MistyTbl.list.nextPage(MistyUI)
	if MistyUI.mainFrame:IsShown() then
		if (#Misty.posts > (MistyTbl.vars.mainCurrPage * MistyTbl.constants.LIST_LIMIT)) then
			MistyTbl.vars.mainCurrPage = MistyTbl.vars.mainCurrPage + 1
			MistyTbl.list.updateMainEntries(MistyUI, MistyUI.postEntries, MistyTbl.utils.newIndex(MistyUI.mainFrame:IsShown()))
		end
	else
		if (#Misty.posts > (MistyTbl.vars.userCurrPage * MistyTbl.constants.LIST_LIMIT)) then
			MistyTbl.vars.userCurrPage = MistyTbl.vars.userCurrPage + 1
			MistyTbl.list.updateUserEntries(MistyUI, MistyUI.userPostEntries, MistyTbl.utils.newIndex(MistyUI.mainFrame:IsShown()))
		end
	end
end

function MistyTbl.utils.newIndex(mainListShown)
	if mainListShown then
		return ((MistyTbl.vars.mainCurrPage * MistyTbl.constants.LIST_LIMIT) - (MistyTbl.constants.LIST_LIMIT - 1))
	else
		return ((MistyTbl.vars.userCurrPage * MistyTbl.constants.LIST_LIMIT) - (MistyTbl.constants.LIST_LIMIT - 1))
	end
end

function MistyTbl.utils.makeMovable(frame)
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
end

function MistyTbl.utils.classColour(unit)
	local class, classFileName = UnitClass(unit)
	local colour = RAID_CLASS_COLORS[classFileName]
	local formattedClassText = '|cff'..format("%02x%02x%02x", colour.r*255, colour.g*255, colour.b*255)..unit..'|r'
	return formattedClassText
end

function MistyTbl.utils.misty()
	local colour = RAID_CLASS_COLORS["MONK"]
	local formattedText = '|cff'..format("%02x%02x%02x", colour.r*255, colour.g*255, colour.b*255)..'Misty|r'
	return formattedText
end

function MistyTbl.utils.speak(text)
	print(MistyTbl.utils.misty()..' says: '..text)
end

function MistyTbl.utils.messageHandler(MistyUI, prefix, message, channel, sender)
	if prefix == MistyTbl.constants.ADDON_PREFIX_POST then
		local extractedMessage, class = strsplit("-", message, 2)
		-- Ensure Misty only accepts other user's posts
		if sender ~= MistyTbl.vars.playerFullName then	
			local colour = RAID_CLASS_COLORS[class]
			local formattedClassText = '|cff'..format("%02x%02x%02x", colour.r*255, colour.g*255, colour.b*255)..Ambiguate(sender, "none")..'|r'
			MistyTbl.list.addPost(MistyUI, sender, formattedClassText, strsub(extractedMessage, 1, #extractedMessage-10), strsub(extractedMessage, #extractedMessage-9))
			MistyUI.toastFrame.toastMessage:SetText(formattedClassText..' posted a message!')
			UIFrameFlash(MistyUI.toastFrame, 1, 1, 10, false, 3, 0)
		end
		if sender == MistyTbl.vars.playerFullName then
			if not Misty.options.silent then
				print(MistyTbl.utils.speak("Your message was successfully sent."))
			end
			local userIndex = #Misty.userPosts + 1
			Misty.userPosts[userIndex] = {}
			Misty.userPosts[userIndex].postIndex = userIndex
			Misty.userPosts[userIndex].sender = sender
			Misty.userPosts[userIndex].character = character
			Misty.userPosts[userIndex].message = strsub(extractedMessage, 1, #extractedMessage-10)
			Misty.userPosts[userIndex].id = strsub(extractedMessage, #extractedMessage-9)
			MistyUI.postTextBox:SetText("")
			MistyUI.postBtn:Enable()
		end
	elseif prefix == MistyTbl.constants.ADDON_PREFIX_DELETE then
		MistyTbl.list.deleteEntry(MistyUI, tonumber(message))
	elseif prefix == MistyTbl.constants.ADDON_PREFIX_EDIT then
		local postIndex, newMessage = strsplit("|", message, 2)
		MistyTbl.list.edit(MistyUI, MistyUI.userPostEntries, tonumber(postIndex), newMessage)
	elseif prefix == MistyTbl.constants.ADDON_PREFIX_GATHER then
		if #Misty.posts > 0 then
			local list = {}
			local j = 1
			for i = 1, #Misty.posts do
				if Misty.posts[i].sender == sender then
					list[j] = i
					j = j + 1
				end
			end
			for i = 1, #list do
				table.remove(Misty.posts, list[i])
			end
			-- Ensure Misty only accepts other user's posts
			if sender ~= MistyTbl.vars.playerFullName then
				for i = 1, #Misty.posts do
					local message = Misty.posts[i].message..Misty.posts[i].id
					SendAddonMessage(MistyTbl.constants.ADDON_PREFIX_COLLECT, MistyTbl.utils.addUserClass(message), "GUILD")
				end
				SendAddonMessage(MistyTbl.constants.ADDON_PREFIX_COLLECT, "end", "GUILD")
			end
		end
	elseif prefix == MistyTbl.constants.ADDON_PREFIX_COLLECT then
		if not MistyTbl.vars.collecting then
			MistyTbl.vars.collecting = true
			MistyTbl.vars.collectingFrom = sender
		end
		MistyTbl.list.updateMainEntries(MistyUI, MistyUI.postEntries, MistyTbl.utils.newIndex(MistyUI.mainFrame:IsShown()))
		-- Ensure Misty only accepts other user's posts
		if (sender ~= MistyTbl.vars.playerFullName) and (sender == MistyTbl.vars.collectingFrom) and (message ~= "end") then
			local extractedMessage, class = strsplit("-", message, 2)
			local colour = RAID_CLASS_COLORS[class]
			local formattedClassText = '|cff'..format("%02x%02x%02x", colour.r*255, colour.g*255, colour.b*255)..Ambiguate(sender, "none")..'|r'
			MistyTbl.list.addPost(MistyUI, sender, formattedClassText, strsub(extractedMessage, 1, #extractedMessage-10), strsub(extractedMessage, #extractedMessage-9))
		end
	elseif prefix == MistyTbl.constants.ADDON_PREFIX_LOGOUT then
		--print(MistyTbl.utils.speak("The status of "..message.." has changed."))
	end
end


-- Define the frame table which will be used to store everything in Misty's UI

local MistyUI = CreateFrame("Frame", "Misty_UI_Frame", UIParent, "BasicFrameTemplateWithInset")
MistyUI:SetSize(440, 680)
MistyUI:SetPoint("TOP", UIParent, "TOP", 0, -200)
MistyUI.title = MistyUI:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
MistyUI.title:SetPoint("CENTER", MistyUI.TitleBg, "CENTER", 5, 0)
MistyUI.title:SetText(MistyTbl.utils.misty()..MistyTbl.constants.UI_TITLE)
MistyUI:RegisterEvent("ADDON_LOADED")
MistyUI:RegisterEvent("CHAT_MSG_ADDON")
MistyUI:RegisterEvent("PLAYER_LOGOUT")
MistyTbl.utils.makeMovable(MistyUI)
--MistyUI:SetUserPlaced(enable)
MistyUI.posts = {}

MistyUI.mainFrame = CreateFrame("Frame", "Misty_Main_Frame", MistyUI)
MistyUI.mainFrame:SetPoint("TOPLEFT", MistyUI.TitleBg, "BOTTOMLEFT")
MistyUI.mainFrame:SetPoint("TOPRIGHT", MistyUI.TitleBg, "BOTTOMRIGHT")
MistyUI.mainFrame:SetPoint("BOTTOMLEFT", MistyUI, "BOTTOMLEFT")
MistyUI.mainFrame:SetPoint("BOTTOMRIGHT", MistyUI, "BOTTOMRIGHT")

MistyUI.postTextBoxLabel = MistyUI.mainFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
MistyUI.postTextBoxLabel:SetPoint("TOPLEFT", MistyUI.mainFrame, "TOPLEFT", 12, -10)
MistyUI.postTextBoxLabel:SetSize(100, 40)
MistyUI.postTextBoxLabel:SetText("Enter Message:")

MistyUI.postTextBox = CreateFrame("EditBox", nil, MistyUI.mainFrame, "InputBoxTemplate")
MistyUI.postTextBox:SetPoint("TOP", MistyUI.TitleBg, "BOTTOM", 0, -20)
MistyUI.postTextBox:SetPoint("LEFT", MistyUI.postTextBoxLabel, "RIGHT", 10, 0)
MistyUI.postTextBox:SetAutoFocus(false)
MistyUI.postTextBox:SetMaxLetters(MistyTbl.constants.MAX_LETTERS)
MistyUI.postTextBox:SetSize(300, 20)

MistyUI.postBtn = CreateFrame("Button", nil, MistyUI.mainFrame, "GameMenuButtonTemplate")
MistyUI.postBtn:SetPoint("TOPRIGHT", MistyUI.postTextBox, "BOTTOMRIGHT", 0, -10)
MistyUI.postBtn:SetSize(MistyTbl.constants.SMALL_BUTTON_WIDTH, MistyTbl.constants.SMALL_BUTTON_HEIGHT)
MistyUI.postBtn:SetText("Submit")
MistyUI.postBtn:SetNormalFontObject("GameFontNormal")
MistyUI.postBtn:SetHighlightFontObject("GameFontHighlight")
MistyUI.postBtn:SetScript("OnClick", function(self)
	MistyTbl.utils.postSubmitHandler(MistyUI, MistyUI.postTextBox:GetText())
end)

MistyUI.postList = CreateFrame("Frame", "Post_List_Frame", MistyUI.mainFrame)
MistyUI.postList:SetWidth(350)
MistyUI.postList:SetHeight(455)
MistyUI.postList:SetPoint("TOP", MistyUI, "TOP", 0, -170)
MistyUI.postList:SetBackdrop({ 
  bgFile = "Interface/ACHIEVEMENTFRAME/UI-Achievement-Parchment-Horizontal", 
  edgeFile = "Interface/Tooltips/UI-Tooltip-Border", tile = false, tileSize = 16, edgeSize = 16, 
  insets = { left = 4, right = 4, top = 4, bottom = 4 }
})

MistyUI.postListHeader = MistyUI.mainFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
MistyUI.postListHeader:SetPoint("BOTTOM", MistyUI.postList, "TOP", 0, 0)
MistyUI.postListHeader:SetSize(200, 20)

MistyUI.userPostsBtn = CreateFrame("Button", nil, MistyUI.mainFrame, "GameMenuButtonTemplate")
MistyUI.userPostsBtn:SetPoint("BOTTOMLEFT", MistyUI.postList, "TOPLEFT", 27, 30)
MistyUI.userPostsBtn:SetSize(MistyTbl.constants.SMALL_BUTTON_WIDTH + 10, MistyTbl.constants.SMALL_BUTTON_HEIGHT)
MistyUI.userPostsBtn:SetText("Your Posts")
MistyUI.userPostsBtn:SetNormalFontObject("GameFontNormal")
MistyUI.userPostsBtn:SetHighlightFontObject("GameFontHighlight")
MistyUI.userPostsBtn:SetScript("OnClick", function(self)
	MistyUI.mainFrame:Hide()
	MistyUI.userFrame:Show()
	MistyTbl.list.updateUserEntries(MistyUI, MistyUI.userPostEntries, 1)
end)

MistyUI.optionsBtn = CreateFrame("Button", nil, MistyUI.mainFrame, "GameMenuButtonTemplate")
MistyUI.optionsBtn:SetPoint("TOPLEFT", MistyUI.userPostsBtn , "TOPRIGHT", 10, 0)
MistyUI.optionsBtn:SetSize(MistyTbl.constants.SMALL_BUTTON_WIDTH + 10, MistyTbl.constants.SMALL_BUTTON_HEIGHT)
MistyUI.optionsBtn:SetText("Options")
MistyUI.optionsBtn:SetNormalFontObject("GameFontNormal")
MistyUI.optionsBtn:SetHighlightFontObject("GameFontHighlight")
MistyUI.optionsBtn:SetScript("OnClick", function(self)
	MistyUI.mainFrame:Hide()
	MistyUI.optionsFrame:Show()
end)

MistyUI.resetBtn = CreateFrame("Button", nil, MistyUI.mainFrame, "GameMenuButtonTemplate")
MistyUI.resetBtn:SetPoint("TOPLEFT", MistyUI.optionsBtn, "TOPRIGHT", 10, 0)
MistyUI.resetBtn:SetSize(MistyTbl.constants.SMALL_BUTTON_WIDTH + 10, MistyTbl.constants.SMALL_BUTTON_HEIGHT)
MistyUI.resetBtn:SetText("Reset List")
MistyUI.resetBtn:SetNormalFontObject("GameFontNormal")
MistyUI.resetBtn:SetHighlightFontObject("GameFontHighlight")
MistyUI.resetBtn:SetScript("OnClick", function(self)
	MistyTbl.list.resetList(MistyUI)
end)

MistyUI.mainPrevBtn = CreateFrame("Button", nil, MistyUI.mainFrame, "GameMenuButtonTemplate")
MistyUI.mainPrevBtn:SetPoint("TOPLEFT", MistyUI.postList , "BOTTOMLEFT", 25, -10)
MistyUI.mainPrevBtn:SetSize(MistyTbl.constants.LARGE_BUTTON_WIDTH, MistyTbl.constants.LARGE_BUTTON_HEIGHT)
MistyUI.mainPrevBtn:SetText("Previous")
MistyUI.mainPrevBtn:SetNormalFontObject("GameFontNormal")
MistyUI.mainPrevBtn:SetHighlightFontObject("GameFontHighlight")
MistyUI.mainPrevBtn:SetScript("OnClick", function(self)
	MistyTbl.list.previousPage(MistyUI)
end)

MistyUI.mainNextBtn = CreateFrame("Button", nil, MistyUI.mainFrame, "GameMenuButtonTemplate")
MistyUI.mainNextBtn:SetPoint("LEFT", MistyUI.mainPrevBtn, "RIGHT", 20, 0)
MistyUI.mainNextBtn:SetSize(MistyTbl.constants.LARGE_BUTTON_WIDTH, MistyTbl.constants.LARGE_BUTTON_HEIGHT)
MistyUI.mainNextBtn:SetText("Next")
MistyUI.mainNextBtn:SetNormalFontObject("GameFontNormal")
MistyUI.mainNextBtn:SetHighlightFontObject("GameFontHighlight")
MistyUI.mainNextBtn:SetScript("OnClick", function(self)
	MistyTbl.list.nextPage(MistyUI)
end)


-- The User's Posts Section

MistyUI.userFrame = CreateFrame("Frame", "Misty_Main_Frame", MistyUI)
MistyUI.userFrame:SetPoint("TOPLEFT", MistyUI.TitleBg, "BOTTOMLEFT")
MistyUI.userFrame:SetPoint("TOPRIGHT", MistyUI.TitleBg, "BOTTOMRIGHT")
MistyUI.userFrame:SetPoint("BOTTOMLEFT", MistyUI, "BOTTOMLEFT")
MistyUI.userFrame:SetPoint("BOTTOMRIGHT", MistyUI, "BOTTOMRIGHT")
MistyUI.userFrame:Hide()

MistyUI.userPostHeader = MistyUI.userFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
MistyUI.userPostHeader:SetPoint("TOP", MistyUI.userFrame, "TOP", 0, -20)
MistyUI.userPostHeader:SetSize(200, 20)
MistyUI.userPostHeader:SetText("User Posts")

MistyUI.userShowMainBtn = CreateFrame("Button", nil, MistyUI.userFrame, "GameMenuButtonTemplate")
MistyUI.userShowMainBtn:SetPoint("TOP", MistyUI.userPostHeader , "BOTTOM", 0, -20)
MistyUI.userShowMainBtn:SetSize(MistyTbl.constants.LARGE_BUTTON_WIDTH, MistyTbl.constants.SMALL_BUTTON_HEIGHT)
MistyUI.userShowMainBtn:SetText("Main Window")
MistyUI.userShowMainBtn:SetNormalFontObject("GameFontNormal")
MistyUI.userShowMainBtn:SetHighlightFontObject("GameFontHighlight")
MistyUI.userShowMainBtn:SetScript("OnClick", function(self)
	MistyTbl.list.updateMainEntries(MistyUI, MistyUI.postEntries, MistyTbl.utils.newIndex(MistyUI.mainFrame:IsShown()))
	MistyUI.userFrame:Hide()
	MistyUI.mainFrame:Show()
end)

MistyUI.userPostList = CreateFrame("Frame", "User_Post_List_Frame", MistyUI.userFrame)
MistyUI.userPostList:SetWidth(350)
MistyUI.userPostList:SetHeight(455)
MistyUI.userPostList:SetPoint("TOP", MistyUI.userShowMainBtn, "BOTTOM", -20, -30)
MistyUI.userPostList:SetBackdrop({ 
  bgFile = "Interface/ACHIEVEMENTFRAME/UI-Achievement-Parchment-Horizontal", 
  edgeFile = "Interface/Tooltips/UI-Tooltip-Border", tile = false, tileSize = 16, edgeSize = 16, 
  insets = { left = 4, right = 4, top = 4, bottom = 4 }
})

MistyUI.userPostListHeader = MistyUI.userFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
MistyUI.userPostListHeader:SetPoint("BOTTOM", MistyUI.userPostList, "TOP", 0, 0)
MistyUI.userPostListHeader:SetSize(200, 20)

MistyUI.userPrevBtn = CreateFrame("Button", nil, MistyUI.userFrame, "GameMenuButtonTemplate")
MistyUI.userPrevBtn:SetPoint("TOPLEFT", MistyUI.userPostList , "BOTTOMLEFT", 25, -10)
MistyUI.userPrevBtn:SetSize(MistyTbl.constants.LARGE_BUTTON_WIDTH, MistyTbl.constants.LARGE_BUTTON_HEIGHT)
MistyUI.userPrevBtn:SetText("Previous")
MistyUI.userPrevBtn:SetNormalFontObject("GameFontNormal")
MistyUI.userPrevBtn:SetHighlightFontObject("GameFontHighlight")
MistyUI.userPrevBtn:SetScript("OnClick", function(self)
	MistyTbl.list.previousPage(MistyUI)
end)

MistyUI.userNextBtn = CreateFrame("Button", nil, MistyUI.userFrame, "GameMenuButtonTemplate")
MistyUI.userNextBtn:SetPoint("LEFT", MistyUI.userPrevBtn, "RIGHT", 20, 0)
MistyUI.userNextBtn:SetSize(MistyTbl.constants.LARGE_BUTTON_WIDTH, MistyTbl.constants.LARGE_BUTTON_HEIGHT)
MistyUI.userNextBtn:SetText("Next")
MistyUI.userNextBtn:SetNormalFontObject("GameFontNormal")
MistyUI.userNextBtn:SetHighlightFontObject("GameFontHighlight")
MistyUI.userNextBtn:SetScript("OnClick", function(self)
	MistyTbl.list.nextPage(MistyUI)
end)


-- The Options Section

MistyUI.optionsFrame = CreateFrame("Frame", "Misty_Options_Frame", MistyUI)
MistyUI.optionsFrame:SetPoint("TOPLEFT", MistyUI.TitleBg, "BOTTOMLEFT")
MistyUI.optionsFrame:SetPoint("TOPRIGHT", MistyUI.TitleBg, "BOTTOMRIGHT")
MistyUI.optionsFrame:SetPoint("BOTTOMLEFT", MistyUI, "BOTTOMLEFT")
MistyUI.optionsFrame:SetPoint("BOTTOMRIGHT", MistyUI, "BOTTOMRIGHT")
MistyUI.optionsFrame:Hide()

MistyUI.optionsHeader = MistyUI.optionsFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
MistyUI.optionsHeader:SetPoint("TOP", MistyUI.optionsFrame, "TOP", 0, -20)
MistyUI.optionsHeader:SetSize(200, 20)
MistyUI.optionsHeader:SetText("Options")

MistyUI.optionsShowMainBtn = CreateFrame("Button", nil, MistyUI.optionsFrame, "GameMenuButtonTemplate")
MistyUI.optionsShowMainBtn:SetPoint("TOP", MistyUI.optionsHeader , "BOTTOM", 0, -20)
MistyUI.optionsShowMainBtn:SetSize(MistyTbl.constants.LARGE_BUTTON_WIDTH, MistyTbl.constants.SMALL_BUTTON_HEIGHT)
MistyUI.optionsShowMainBtn:SetText("Main Window")
MistyUI.optionsShowMainBtn:SetNormalFontObject("GameFontNormal")
MistyUI.optionsShowMainBtn:SetHighlightFontObject("GameFontHighlight")
MistyUI.optionsShowMainBtn:SetScript("OnClick", function(self)
	MistyUI.optionsFrame:Hide()
	MistyUI.mainFrame:Show()
end)

MistyUI.silentCheckBtn = CreateFrame("CheckButton", nil, MistyUI.optionsFrame, "UICheckButtonTemplate")
MistyUI.silentCheckBtn:SetPoint("TOPLEFT", MistyUI.TitleBg, "BOTTOMLEFT", 10, -100)
MistyUI.silentCheckBtn.text:SetText("Prevent Misty from adding any messages to the chat frame.")
MistyUI.silentCheckBtn:SetScript("OnClick", function(self)
	if MistyUI.silentCheckBtn:GetChecked() then
		Misty.options.silent = true
	else
		Misty.options.silent = false
	end
end)

MistyUI.gatherCheckBtn = CreateFrame("CheckButton", nil, MistyUI.optionsFrame, "UICheckButtonTemplate")
MistyUI.gatherCheckBtn:SetPoint("TOPLEFT", MistyUI.silentCheckBtn , "BOTTOMLEFT", 0, -10)
MistyUI.gatherCheckBtn.text:SetText("Set Misty to gather data from other players upon login.")
MistyUI.gatherCheckBtn:SetScript("OnClick", function(self)
	if MistyUI.gatherCheckBtn:GetChecked() then
		Misty.options.collect = true
	else
		Misty.options.collect = false
	end
end)


-- The Edit Post Section

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
MistyUI.postEditFrame.postEditTextBox:SetFocus()
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


-- The Toast Section

MistyUI.toastFrame = CreateFrame("Frame", nil, UIParent)
MistyUI.toastFrame:SetSize(150, 60)
MistyUI.toastFrame:SetPoint("RIGHT", UIParent, "RIGHT", -50, 0)
MistyUI.toastFrame:SetBackdrop({
	bgFile = "Interface/Buttons/UI-SliderBar-Background",
	insets = {left = -5, right = -5, top = 0, bottom = 0},
})
MistyUI.toastFrame:Hide()

MistyUI.toastFrame.toastHeader = MistyUI.toastFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
MistyUI.toastFrame.toastHeader:SetPoint("TOP", MistyUI.toastFrame, "TOP", 0, -5)
MistyUI.toastFrame.toastHeader:SetWidth(148)
MistyUI.toastFrame.toastHeader:SetText(MistyTbl.utils.misty())

MistyUI.toastFrame.toastMessage = MistyUI.toastFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
MistyUI.toastFrame.toastMessage:SetPoint("TOP", MistyUI.toastFrame.toastHeader, "BOTTOM", 0, -10)
MistyUI.toastFrame.toastMessage:SetWidth(148)
MistyUI.toastFrame.toastMessage:SetJustifyH("left")


-- The Event Handler

function Misty_Event_Handler(self, event, ...)
	if event == "ADDON_LOADED" and ... == "!Misty" then
		MistyTbl.list.init(MistyUI)
		MistyUI:UnregisterEvent("ADDON_LOADED")
	elseif event == "CHAT_MSG_ADDON" then
		MistyTbl.vars.prefixReg = RegisterAddonMessagePrefix(MistyTbl.constants.ADDON_PREFIX_POST)
		MistyTbl.vars.prefixReg = RegisterAddonMessagePrefix(MistyTbl.constants.ADDON_PREFIX_GATHER)
		MistyTbl.vars.prefixReg = RegisterAddonMessagePrefix(MistyTbl.constants.ADDON_PREFIX_COLLECT)
		MistyTbl.vars.prefixReg = RegisterAddonMessagePrefix(MistyTbl.constants.ADDON_PREFIX_LOGOUT)
		local prefix, message, channel, sender = ...
		MistyTbl.utils.messageHandler(MistyUI, prefix, message, channel, sender)
	elseif event == "PLAYER_LOGOUT" then
		local class, classFileName = UnitClass("player")
		local colour = RAID_CLASS_COLORS[classFileName]
		local formattedClassText = '|cff'..format("%02x%02x%02x", colour.r*255, colour.g*255, colour.b*255)..MistyTbl.vars.playerName..'|r'
		SendAddonMessage(MistyTbl.constants.ADDON_PREFIX_LOGOUT, formattedClassText, "GUILD")
	end
end

MistyUI:SetScript("OnEvent", Misty_Event_Handler)
MistyUI:Hide()