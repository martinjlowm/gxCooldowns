local aName, aTable = ...

local floor = math.floor
local format = string.format
local tinsert = table.insert
local next = next
local tremove = table.remove
local select = select
local sort = table.sort
local tonumber = tonumber

local Button = LibStub("tekKonfig-Button")
local Dropdown = LibStub("tekKonfig-Dropdown")
local Group = LibStub("tekKonfig-Group")
local Heading = LibStub("tekKonfig-Heading")
local Scroll = LibStub("tekKonfig-Scroll")
local Slider = LibStub("tekKonfig-Slider")

local GetItemInfo = GetItemInfo
local GetItemSpell = GetItemSpell
local GetSpellInfo = GetSpellInfo
local GetSpellLink = GetSpellLink

local defaults = {
	blacklist = {},
	minDuration = 1.5,
	maxDuration = 3600,
	items = { 
	},
	
	style = {
		"Blizzard",	-- Skin name
		0.5,		-- Gloss alpha
		true		-- Use backdrop
	},
	
	scale = 1,
	gap = 10,
	growth = "Left and Right",
	xOffset = 0,
	yOffset = 0,
}

local addMainOptions = function(self)
	local title = Heading.new(self, "gxCooldowns")
	
	local mainGroup = Group.new(self, "Settings")
	mainGroup:SetPoint("TOP", title, "BOTTOM", 0, -20)
	mainGroup:SetPoint("BOTTOMLEFT", 16, 16)
	mainGroup:SetPoint("BOTTOMRIGHT", -16, 16)
	
	local dropdown, dText = Dropdown.new(mainGroup, "Growth", "TOPLEFT", mainGroup, "TOPLEFT", 15, -10)
	dText:SetText(gxCooldownsDB.growth)
	local OnClick = function(self)
		UIDropDownMenu_SetSelectedValue(dropdown, self.value)
		dText:SetText(self.value)
		aTable.updateFrames(self.value)
	end
	UIDropDownMenu_Initialize(dropdown, function()
		local selected, info = UIDropDownMenu_GetSelectedValue(dropdown) or gxCooldownsDB.growth, UIDropDownMenu_CreateInfo()
		
		for name in next, aTable.growthValues do
			info.text = name
			info.value = name
			info.func = OnClick
			info.checked = name == selected
			UIDropDownMenu_AddButton(info)
		end
	end)
	
	
	local scale, scaleText = Slider.new(mainGroup, format("Scale: %.2f", gxCooldownsDB.scale), 0.5, 2)
	scale:SetPoint("TOPLEFT", mainGroup, "TOPLEFT", 20, -90)
	scale:SetPoint("TOPRIGHT", mainGroup, "TOP", -15, -90)
	scale:SetValue(gxCooldownsDB.scale)
	scale:SetValueStep(.05)
	scale:SetScript("OnValueChanged", function(self)
		local scale = self:GetValue()
		scaleText:SetText(format("Scale: %.2f", scale))
		aTable.setScale(scale)
	end)
	
	local gap, gapText = Slider.new(mainGroup, "Gap: " .. gxCooldownsDB.gap, -10, 25)
	gap:SetPoint("TOPRIGHT", mainGroup, "TOPRIGHT", -20, -90)
	gap:SetPoint("TOPLEFT", mainGroup, "TOP", 15, -90)
	gap:SetValue(gxCooldownsDB.gap)
	gap:SetValueStep(1)
	gap:SetScript("OnValueChanged", function(self)
		local gap = self:GetValue()
		gapText:SetText("Gap: " .. gap)
		aTable.setGap(gap)
	end)
	
	local minDur, minDurText = Slider.new(mainGroup, "Minimum duration: " .. gxCooldownsDB.minDuration, 1.5, 10)
	minDur:SetPoint("TOPLEFT", scale, "BOTTOMLEFT", 0, -40)
	minDur:SetPoint("TOPRIGHT", scale, "BOTTOMRIGHT", 0, -40)
	minDur:SetValue(gxCooldownsDB.minDuration)
	minDur:SetValueStep(.5)
	minDur:SetScript("OnValueChanged", function(self)
		local dur = self:GetValue()
		minDurText:SetText("Minimum duration: " .. dur)
		gxCooldownsDB.minDuration = dur
	end)
	
	local maxDur, maxDurText = Slider.new(mainGroup, format("Maximum duration: %.1fm", gxCooldownsDB.maxDuration/60), 10, 60*60)
	maxDur:SetPoint("TOPLEFT", gap, "BOTTOMLEFT", 0, -40)
	maxDur:SetPoint("TOPRIGHT", gap, "BOTTOMRIGHT", 0, -40)
	maxDur:SetValue(gxCooldownsDB.maxDuration)
	maxDur:SetValueStep(5)
	maxDur:SetScript("OnValueChanged", function(self)
		local dur = self:GetValue()
		maxDurText:SetText(format("Maximum duration: %.1fm", dur/60))
		gxCooldownsDB.maxDuration = dur
	end)
	
	local x = CreateFrame("EditBox", "gxCooldownsConfigX", mainGroup, "InputBoxTemplate")
	x:SetPoint("TOPLEFT", minDur, "BOTTOMLEFT", 0, -40)
	x:SetPoint("TOPRIGHT", minDur, "BOTTOMRIGHT", 0, -40)
	x:SetHeight(30)
	x:SetAutoFocus(false)
	x:SetText(gxCooldownsDB.xOffset)
	x:SetScript("OnEscapePressed", function(self)
		self:ClearFocus()
		self:SetText(gxCooldownsDB.xOffset)
	end)
	x:SetScript("OnEnterPressed", function(self)
		self:ClearFocus()
	end)
	
	local xlabel = x:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	xlabel:SetText("X")
	xlabel:SetPoint("BOTTOMLEFT", x, "TOPLEFT")
	
	local y = CreateFrame("EditBox", "gxCooldownsConfigY", mainGroup, "InputBoxTemplate")
	y:SetPoint("TOPLEFT", maxDur, "BOTTOMLEFT", 0, -40)
	y:SetPoint("TOPRIGHT", maxDur, "BOTTOMRIGHT", 0, -40)
	y:SetHeight(30)
	y:SetAutoFocus(false)
	y:SetText(gxCooldownsDB.yOffset)
	y:SetScript("OnEscapePressed", function(self)
		self:ClearFocus()
		self:SetText(gxCooldownsDB.yOffset)
	end)
	y:SetScript("OnEnterPressed", function(self)
		self:ClearFocus()
	end)
	
	local ylabel = y:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	ylabel:SetText("Y")
	ylabel:SetPoint("BOTTOMLEFT", y, "TOPLEFT")
	
	local callbackXY = function()
		x:SetText(gxCooldownsDB.xOffset)
		y:SetText(gxCooldownsDB.yOffset)
	end
	
	local apply = Button.new(mainGroup, "TOPRIGHT", y, "BOTTOMRIGHT", 0, -5)
	apply:SetWidth(75)
	apply:SetHeight(25)
	apply.tiptext = "Click to apply the coordinates."
	apply:SetText("Apply")
	apply:SetScript("OnClick", function(self)
		local x, y = x:GetText(), y:GetText()
		if (not tonumber(x) or not tonumber(y)) then
			return
		end
		
		aTable.setPosition(x, y)
	end)
	
	local lock = Button.new(mainGroup, "TOPLEFT", x, "BOTTOMLEFT", -5, -5)
	lock:SetWidth(75)
	lock:SetHeight(25)
	lock.tiptext = "Lock/unlock the anchor."
	lock:SetText("Unlock")
	
	local callbackLock = function()
		if (aTable.locked) then
			lock:SetText("Unlock")
		end
	end
	
	lock:SetScript("OnClick", function(self)
		if (aTable.locked) then
			self:SetText("Lock")
			aTable.locked = false
		else
			self:SetText("Unlock")
			aTable.locked = true
		end
		
		aTable.toggleLock(callbackLock, callbackXY)
	end)
	aTable.locked = true
	
	self:SetScript("OnShow", nil)
end

local scanLostCache = function()
	local result = ""
	for itemSpell, itemID in next, gxCooldownsDB.items do
		if (not GetItemInfo(itemID)) then
			result = result .. itemID .. ", "
			
			gxCooldownsDB.items[itemSpell] = nil
		end
	end
	result = string.sub(result, 1, -3)
	print("|cffffaa00gx|r|cff999999Cooldowns:|r The following items are removed since they are no longer stored in your local cache: " .. result)
end

local updateItemList = function(group)
	local name, id
	
	local numItems = #(group.items)
	local maxOffset
	if (numItems > group.maxButtons) then
		maxOffset = numItems - group.maxButtons
	else
		maxOffset = 0
	end
	group.scrollbar:SetMinMaxValues(0, maxOffset)
	
	local offset = floor(group.scrollbar:GetValue())
	local i = offset + 1
	for _, button in next, group.buttons do
		if (i > (group.maxButtons + offset)) then
			break
		end
		name = group.items[i]
		if (not name) then
			button:Hide()
		else
			button:Show()
			id = group.itemNameToID[name]
			
			button.icon:SetTexture(select(10, GetItemInfo(id)))
			button.text:SetText(select(2, GetItemInfo(id)))
			
			button.itemSpellName = GetItemSpell(id)
			button.itemID = id
		end
		
		i = i + 1
	end
end

local removeItem = function(button, group)
	local name = GetItemInfo(button.itemID)
	local spell = button.itemSpellName
	button.itemID = nil
	button.icon:SetTexture(nil)
	button.text:SetText()
	for i, item in next, group.items do
		if (item == name) then
			tremove(group.items, i)
			break
		end
	end
	group.itemNameToID[name] = nil
	
	sort(group.items)
	
	updateItemList(group)
	
	gxCooldownsDB.items[spell] = nil
end

local buttonEnter = function(self)
	self.texture:Show()
end

local buttonLeave = function(self)
	self.texture:Hide()
end

local createButton = function(i, group, f)
	local button = CreateFrame("Button", nil, group)
	button:SetHeight(25)
	
	if (i ~= 1) then
		button:SetPoint("TOPLEFT", group.buttons[i - 1], "BOTTOMLEFT")
		button:SetPoint("TOPRIGHT", group.buttons[i - 1], "BOTTOMRIGHT")
	else
		button:SetPoint("TOPLEFT", group, "TOPLEFT", 4, -6)
		button:SetPoint("TOPRIGHT", group.scrollbar, "TOPLEFT", -4, -6)
	end
	
	button:RegisterForClicks("RightButtonUp")
	button:SetScript("OnClick", function(self)
		f(self, group)
	end)
	button:SetScript("OnEnter", buttonEnter)
	button:SetScript("OnLeave", buttonLeave)
	
	local icon = button:CreateTexture(nil, "ARTWORK")
	icon:SetPoint("TOPLEFT", 2, 0)
	icon:SetPoint("BOTTOMLEFT", 2, 0)
	icon:SetWidth(25)
	button.icon = icon
	
	local text = button:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	text:SetPoint("LEFT", icon, "RIGHT", 5, 0)
	button.text = text
	
	local texture = button:CreateTexture(nil, "BACKGROUND")
	texture:SetAllPoints(button)
	texture:SetTexture([=[Interface\QuestFrame\UI-QuestLogTitleHighlight]=])
	texture:SetBlendMode("ADD")
	texture:SetAlpha(.5)
	texture:Hide()
	button.texture = texture
	
	group.buttons[i] = button
end

local addItem = function(item, itemSpell, group)
	local name, link = GetItemInfo(item)
	local itemID = tonumber(string.match(link, "Hitem:(%d+)"))
	
	tinsert(group.items, name)
	group.itemNameToID[name] = itemID
	
	sort(group.items)
	
	local numButtons = #(group.buttons)
	if (numButtons < group.maxButtons) then
		createButton(numButtons + 1, group, removeItem)
	end
	updateItemList(group)
	
	gxCooldownsDB.items[itemSpell] = itemID
end

local addItemsOptions = function(self)
	local title, subtitle = Heading.new(self, "gxCooldowns - Add Items", "Here you can add whatever items which cooldowns you wish to watch. Both item ID and name are valid. You will have to use item ID to add items you don't have in your inventory.")
	
	local mainGroup = Group.new(self, "Items")
	mainGroup:SetPoint("TOP", subtitle, "BOTTOM", 0, -8)
	mainGroup:SetPoint("BOTTOMLEFT", 16, 16)
	mainGroup:SetPoint("BOTTOMRIGHT", -16, 16)
	
	local input = CreateFrame("EditBox", nil, mainGroup, "InputBoxTemplate")
	input:SetPoint("TOPLEFT", mainGroup, "TOPLEFT", 24, -16)
	input:SetHeight(30)
	input:SetWidth(250)
	input:SetAutoFocus(false)
	input:SetScript("OnEscapePressed", function(self)
		self:ClearFocus()
	end)
	input:SetScript("OnEnterPressed", function(self)
		local item = self:GetText()
		local itemSpell = GetItemSpell(item)
		if (itemSpell) then
			item = GetItemInfo(item)
			if (not self.group.itemNameToID[item]) then
				addItem(item, itemSpell, self.group)
			end
		else
			self:ClearFocus()
		end
	end)
	hooksecurefunc("ChatEdit_InsertLink", function(text)
		if (self:IsShown()) then
			input:SetText(text)
		end
	end)
	
	local add = Button.new(self, "LEFT", input, "RIGHT", 12, 0)
	add:SetWidth(75)
	add:SetHeight(25)
	add.tiptext = "Click to add this item to the list."
	add:SetText("Add item")
	add:SetScript("OnClick", function(self)
		local item = input:GetText()
		local itemSpell = GetItemSpell(item)
		if (itemSpell) then
			item = GetItemInfo(item)
			if (not self.group.itemNameToID[item]) then
				addItem(item, itemSpell, self.group)
			end
		else
			input:ClearFocus()
		end
	end)
	
	local group = Group.new(self)
	group:SetPoint("TOP", input, "BOTTOM", 0, -8)
	group:SetPoint("BOTTOMLEFT", mainGroup, 16, 16)
	group:SetPoint("BOTTOMRIGHT", mainGroup, -16, 16)
	group.buttons = {}
	group.itemNameToID = {}
	group.items = {}
	group.maxButtons = floor((group:GetHeight() - 10) / 25)
	
	add.group = group
	input.group = group
	
	local scroll = Scroll.new(group, 6, 1)
	local func = scroll:GetScript("OnValueChanged")
	scroll:SetScript("OnValueChanged", function(self, value, ...)
		updateItemList(group)
		return func(self, value, ...)
	end)
	group.scrollbar = scroll
	
	local itemName
	local i = 1
	for _, itemID in next, gxCooldownsDB.items do
		itemName = GetItemInfo(itemID)
		if (not itemName) then
			scanLostCache()
			break
		end
		group.itemNameToID[itemName] = itemID
		group.items[i] = itemName
		i = i + 1
	end
	sort(group.items)
	
	for i in next, group.items do
		if (i <= group.maxButtons) then
			createButton(i, group, removeItem)
		end
	end
	updateItemList(group)
	
	self:EnableMouseWheel()
	self:SetScript("OnMouseWheel", function(self, val)
		scroll:SetValue(scroll:GetValue() - val)
	end)
	local numItems = #(group.items)
	local maxOffset
	if (numItems > group.maxButtons) then
		maxOffset = numItems - group.maxButtons
	else
		maxOffset = 0
	end
	scroll:SetMinMaxValues(0, maxOffset)
	scroll:SetValue(0)
	
	self:SetScript("OnShow", nil)
end

local updateBlacklist = function(group)
	local name, id
	
	local numSpells = #(group.spells)
	local maxOffset
	if (numSpells > group.maxButtons) then
		maxOffset = numSpells - group.maxButtons
	else
		maxOffset = 0
	end
	group.scrollbar:SetMinMaxValues(0, maxOffset)
	
	local offset = floor(group.scrollbar:GetValue())
	local i = offset + 1
	for _, button in next, group.buttons do
		if (i > (group.maxButtons + offset)) then
			break
		end
		name = group.spells[i]
		if (not name) then
			button:Hide()
		else
			button:Show()
			id = group.spellNameToID[name]
			
			button.icon:SetTexture(select(3, GetSpellInfo(id)))
			button.text:SetText(GetSpellLink(id))
			
			button.itemID = id
		end
		
		i = i + 1
	end
end

local removeSpell = function(button, group)
	local name = GetSpellInfo(button.itemID)
	button.itemID = nil
	button.icon:SetTexture(nil)
	button.text:SetText()
	for i, spell in next, group.spells do
		if (spell == name) then
			tremove(group.spells, i)
			break
		end
	end
	group.spellNameToID[name] = nil
	
	sort(group.spells)
	
	updateBlacklist(group)
	
	gxCooldownsDB.blacklist[name] = nil
end

local addSpell = function(spellLink, group)
	local spellID = tonumber(string.match(spellLink, "Hspell:(%d+)"))
	local name = GetSpellInfo(spellID)
	
	tinsert(group.spells, name)
	group.spellNameToID[name] = spellID
	
	sort(group.spells)
	
	local numButtons = #(group.buttons)
	if (numButtons < group.maxButtons) then
		createButton(numButtons + 1, group, removeSpell)
	end
	updateBlacklist(group)
	
	gxCooldownsDB.blacklist[name] = spellID
end

local addBlacklistOptions = function(self)
	local title, subtitle = Heading.new(self, "gxCooldowns - Blacklist", "Here you can add whatever cooldowns you do not wish to watch.")
	
	local mainGroup = Group.new(self, "Blacklist")
	mainGroup:SetPoint("TOP", subtitle, "BOTTOM", 0, -8)
	mainGroup:SetPoint("BOTTOMLEFT", 16, 16)
	mainGroup:SetPoint("BOTTOMRIGHT", -16, 16)
	
	local input = CreateFrame("EditBox", nil, mainGroup, "InputBoxTemplate")
	input:SetPoint("TOPLEFT", mainGroup, "TOPLEFT", 24, -16)
	input:SetHeight(30)
	input:SetWidth(250)
	input:SetAutoFocus(false)
	input:SetScript("OnEscapePressed", function(self)
		self:ClearFocus()
	end)
	input:SetScript("OnEnterPressed", function(self)
		local name
		local spellID = tonumber(string.match(self:GetText(), "Hspell:(%d+)"))
		if (spellID) then
			name = GetSpellInfo(spellID)
		else
			name = GetSpellInfo(self:GetText())
		end
		
		if (not name) then
			self:ClearFocus()
			return
		end
		
		local spell = GetSpellLink(name)
		if (spell and not self.group.spellNameToID[name]) then
			addSpell(spell, self.group)
		end
	end)
	hooksecurefunc("ChatEdit_InsertLink", function(text)
		if (self:IsShown()) then
			input:SetText(text)
		end
	end)
	
	local add = Button.new(self, "LEFT", input, "RIGHT", 12, 0)
	add:SetWidth(75)
	add:SetHeight(25)
	add.tiptext = "Click to blacklist this spell."
	add:SetText("Add spell")
	add:SetScript("OnClick", function(self)
		local name
		local spellID = tonumber(string.match(input:GetText(), "Hspell:(%d+)"))
		if (spellID) then
			name = GetSpellInfo(spellID)
		else
			name = GetSpellInfo(input:GetText())
		end
		
		if (not name) then
			input:ClearFocus()
			return
		end
		
		local spell = GetSpellLink(name)
		if (spell and not self.group.spellNameToID[name]) then
			addSpell(spell, self.group)
		end
	end)
	
	local group = Group.new(self)
	group:SetPoint("TOP", input, "BOTTOM", 0, -8)
	group:SetPoint("BOTTOMLEFT", mainGroup, 16, 16)
	group:SetPoint("BOTTOMRIGHT", mainGroup, -16, 16)
	group.buttons = {}
	group.spells = {}
	group.spellNameToID = {}
	group.maxButtons = floor((group:GetHeight() - 10) / 25)
	
	add.group = group
	input.group = group
	
	local scroll = Scroll.new(group, 6, 1)
	local f = scroll:GetScript("OnValueChanged")
	scroll:SetScript("OnValueChanged", function(self, value, ...)
		updateBlacklist(group)
		return f(self, value, ...)
	end)
	group.scrollbar = scroll
	
	
	local i = 1
	for spellName, spellID in next, gxCooldownsDB.blacklist do
		group.spells[i] = spellName
		group.spellNameToID[spellName] = spellID
		
		i = i + 1
	end
	sort(group.spells)
	
	for i in next, group.spells do
		if (i <= group.maxButtons) then
			createButton(i, group, removeSpell)
		end
	end
	updateBlacklist(group)
	
	self:EnableMouseWheel()
	self:SetScript("OnMouseWheel", function(self, val)
		scroll:SetValue(scroll:GetValue() - val)
	end)
	local numSpells = #(group.spells)
	local maxOffset
	if (numSpells > group.maxButtons) then
		maxOffset = numSpells - group.maxButtons
	else
		maxOffset = 0
	end
	scroll:SetMinMaxValues(0, maxOffset)
	scroll:SetValue(0)
	
	self:SetScript("OnShow", nil)
end

local setup = function(self)
	gxCooldownsDB = gxCooldownsDB or {}
	for k, v in next, defaults do
		if (type(gxCooldownsDB[k]) == "nil") then
			gxCooldownsDB[k] = v
		end
	end
	defaults = nil
	
	local main = CreateFrame("Frame", "gxCooldownsConfig", InterfaceOptionsFramePanelContainer)
	main.name = "gxCooldowns"
	main:Hide()
	main:SetScript("OnShow", addMainOptions)
	InterfaceOptions_AddCategory(main)
	
	local items = CreateFrame("Frame", nil, InterfaceOptionsFramePanelContainer)
	items.name = "Add Items"
	items.parent = "gxCooldowns"
	items:Hide()
	items:SetScript("OnShow", addItemsOptions)
	InterfaceOptions_AddCategory(items)
	
	local blacklist = CreateFrame("Frame", nil, InterfaceOptionsFramePanelContainer)
	blacklist.name = "Blacklist"
	blacklist.parent = "gxCooldowns"
	blacklist:Hide()
	blacklist:SetScript("OnShow", addBlacklistOptions)
	InterfaceOptions_AddCategory(blacklist)
	
	SlashCmdList["GXCOOLDOWNS"] = function()
		InterfaceOptionsFrame_OpenToCategory("gxCooldowns")
	end
	SLASH_GXCOOLDOWNS1 = "/gxcooldowns"
	SLASH_GXCOOLDOWNS2 = "/gxcd"
end
aTable.setupConfiguration = setup