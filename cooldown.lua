local _, settings = ...
local L = settings.L

local gxMedia = gxMedia or {
	buttonOverlay = [=[Interface\Buttons\UI-ActionButton-Border]=],
	edgeFile = [=[Interface\Tooltips\UI-Tooltip-Border]=],
	font = [=[Fonts\FRIZQT__.TTF]=]
}

local tinsert = table.insert
local tremove = table.remove
local split = strsplit
local find = string.find
local format = string.format
local lower = string.lower
local match = string.match
local select = select
local GetSpellCooldown = GetSpellCooldown
local GetSpellTexture = GetSpellTexture
local GetItemCooldown = GetItemCooldown
local GetPetActionCooldown = GetPetActionCooldown

local addon = CreateFrame("Frame", nil, UIParent)
addon:SetFrameLevel(2)
addon:RegisterEvent("PLAYER_LOGIN")
addon:RegisterEvent("SPELL_UPDATE_COOLDOWN")
addon:RegisterEvent("BAG_UPDATE_COOLDOWN")
addon:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
addon:RegisterEvent("UNIT_SPELLCAST_FAILED_QUIET")
addon:RegisterEvent("SPELL_UPDATE_USABLE")
addon:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
addon:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
addon.active = {}
addon.pool = {}

local createOutput = function(self)
	local output = self:CreateFontString(nil, "OVERLAY")
	output:SetFont(gxMedia.font, 30, "OUTLINE")
	output:SetPoint("BOTTOM", self, "TOP")
	self.output = output
	
	return output
end

addon.print = function(self, message)
	local IsAddOnLoaded = IsAddOnLoaded
	local method = lower(settings.outputMethod)
	
	if (method == "uierrorsframe") then
		UIErrorsFrame:AddMessage(message)
	elseif (method == "sct" and IsAddOnLoaded("sct") and SCT) then
		SCT:DisplayMessage(message, {r = 1, g = 1, b = 1})
	elseif (method == "msbt" and IsAddOnLoaded("MikScrollingBattleText") and MikSBT) then
		MikSBT.DisplayMessage(message)
	elseif (method == "standard") then
		local output = self.output or createOutput(self)
		output:SetText(message)
		output:SetAlpha(1)
		self.duration = settings.outputTime
		self:SetScript("OnUpdate", function(self, elapsed)
			local duration = self.duration - elapsed
			if (duration <= 0) then
				self.output:SetText()
				self.output:SetPoint("CENTER")
				self:SetScript("OnUpdate", nil)
			elseif (duration >= 0) then
				local alpha = duration / settings.outputTime
				self.output:SetAlpha(alpha)
				self.output:ClearAllPoints()
				self.output:SetPoint("BOTTOM", self, "TOP", 0, -25 * duration + 100)
			end
			
			self.duration = duration
		end)
	else
		print("|cffffaa00gx|r|cff999999Cooldowns:|r", message)
	end
end

local loadFrame = function(self)
	if (#(self.pool) > 0) then
		return tremove(self.pool, 1)
	end
	
	local frame = CreateFrame("Frame", nil, self)
	frame:SetWidth(self.frameSize)
	frame:SetHeight(self.frameSize)
	frame:SetFrameLevel(self:GetFrameLevel() - 2)
	frame:Hide()
	frame.parent = self
	
	local backdrop = CreateFrame("Frame", nil, frame)
	backdrop:SetPoint("TOPLEFT", frame, -4, 4)
	backdrop:SetPoint("BOTTOMRIGHT", frame, 4, -4)
	backdrop:SetFrameStrata("BACKGROUND")
	backdrop:SetBackdrop({
		edgeFile = gxMedia.edgeFile,
		edgeSize = 5,
		insets = {
			left = 3,
			right = 3,
			top = 3,
			bottom = 3
		}
	})
	backdrop:SetBackdropColor(0, 0, 0, 0)
	backdrop:SetBackdropBorderColor(0, 0, 0)
	
	local icon = frame:CreateTexture(nil, "ARTWORK")
	icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
	icon:SetAllPoints(frame)
	
	local cd = CreateFrame("Cooldown", nil, frame)
	cd:SetPoint("TOPLEFT", 2, -2)
	cd:SetPoint("BOTTOMRIGHT", -2, 2)
	
	local overlay = frame:CreateTexture(nil, "OVERLAY")
	overlay:SetTexture(gxMedia.buttonOverlay)
	overlay:SetPoint("TOPLEFT", frame, -2, 2)
	overlay:SetPoint("BOTTOMRIGHT", frame, 2, -2)
	overlay:SetVertexColor(.6,.6,.6)
	overlay:SetTexCoord(0, 1, 0.02, 1)
	
	frame:SetScript("OnUpdate", function(self, elapsed)
		local duration = self.duration - elapsed
		if (duration <= 0) then
			self.parent:dropCooldown(self.name)
			
			return
		end
		
		self.duration = duration
	end)
	
	frame.Cooldown = cd
	frame.Icon = icon
	frame.Overlay = overlay
	frame.Backdrop = backdrop
	
	return frame
end

local saveFrame = function(self, frame)
	frame:Hide()
	
	tinsert(self.pool, frame)
end

local repositionFrames = function(self)
	local gap = settings.gap
	
	local numActive, prev = 0
	for _, frame in next, self.active do
		frame:ClearAllPoints()
		if (settings.growHorizontal) then
			if (prev) then
				frame:SetPoint("LEFT", prev, "RIGHT", gap, 0)
			else
				frame:SetPoint("LEFT", self, "LEFT", 0, 0)
			end
		else
			if (prev) then
				frame:SetPoint("BOTTOM", prev, "TOP", 0, gap)
			else
				frame:SetPoint("BOTTOM", self, "BOTTOM", 0, 0)
			end
		end
		
		numActive = numActive + 1
		prev = frame
	end
	
	if (settings.growHorizontal) then
		self:SetWidth(numActive * (self.frameSize + gap) - gap)
	else
		self:SetHeight(numActive * (self.frameSize + gap) - gap)
	end
end

addon.newCooldown = function(self, cooldownName, startTime, seconds, tex, type)
	if (self.active[cooldownName]) then
		return
	end
	
	local frame = loadFrame(self)
	
	local duration = startTime - GetTime() + seconds
	frame.start = startTime
	frame.duration = duration
	frame.max = seconds
	
	frame.name = cooldownName
	frame.type = type
	
	frame.Icon:SetTexture(tex)
	frame.Cooldown:SetCooldown(startTime, seconds)
	frame:Show()
	
	self.active[cooldownName] = frame
	
	repositionFrames(self)
end

addon.dropCooldown = function(self, cooldownName)
	if (self.active[cooldownName]) then
		saveFrame(self, self.active[cooldownName])
		self.active[cooldownName] = nil
		
		repositionFrames(self)
		return true
	end
	
	return
end

addon.PLAYER_LOGIN = function(self)
	self.playerGUID = UnitGUID("player")
	self.frameSize = settings.frameSize
	
	self:SetPoint(settings.point, settings.relFrame, settings.relPoint, settings.xOffset, settings.yOffset)
	self:SetHeight(1) -- We need to set some dimension to the frame to make it show.
	
	-- Scan when we reload the UI or log in w/e
	local _, _, offset, numSpellsInTab = GetSpellTabInfo(GetNumSpellTabs())
	local numSpells = offset + numSpellsInTab
	
	local spellName, duration, enabled
	for spellNum = 1, numSpells do
		spellName = GetSpellName(spellNum, BOOKTYPE_SPELL)
		startTime, duration, enabled = GetSpellCooldown(spellName)
		if (enabled == 1 and duration > 1.5) then
			self:newCooldown(spellName, startTime, duration, GetSpellTexture(spellName), "SPELL")
		end
	end
	
	-- Add equipped items to our enchant list, if they have enchants of our wish.
	for i = 1, 19 do
		self:PLAYER_EQUIPMENT_CHANGED(i, true)
	end
	
	self:UnregisterEvent("PLAYER_LOGIN")
	self.PLAYER_LOGIN = nil
end

local spellSchools = { -- We assume players can't use combined schools
	[1] = {
		Name = L["Physical"],
		colorString = "|cffFFFF00"
	},
	[2] = {
		Name = L["Holy"],
		colorString = "|cffFFE680"
	},
	[4] = {
		Name = L["Fire"],
		colorString = "|cffFF8000"
	},
	[8] = {
		Name = L["Nature"],
		colorString = "|cff4DFF4D"
	},
	[16] = {
		Name = L["Frost"],
		colorString = "|cff80FFFF"
	},
	[32] = {
		Name = L["Shadow"],
		colorString = "|cff8080FF"
	},
	[64] = {
		Name = L["Arcane"],
		colorString = "|cffFF80FF"
	}
}
local specialOccasions = {
	[GetSpellInfo(14177)] = true,	-- Cold Blood
	[GetSpellInfo(20216)] = true,	-- Divine Favor
	[GetSpellInfo(16166)] = true,	-- Elemental Mastery
	[GetSpellInfo(5384)] = true,	-- Feign Death
	[GetSpellInfo(14751)] = true,	-- Inner Focus
	[GetSpellInfo(17116)] = true,	-- Nature's Swiftness
	[GetSpellInfo(12043)] = true,	-- Presence of Mind
	[GetSpellInfo(5215)] = true,	-- Prowl
	[GetSpellInfo(1784)] = true		-- Stealth
}
addon.SPELL_UPDATE_COOLDOWN = function(self)
	if (self.updateNext) then
		local sStartTime, sDuration, sEnabled = GetSpellCooldown(self.updateNext)
		if (sEnabled == 1 and sDuration > 1.5) then
			self:newCooldown(self.updateNext, sStartTime, sDuration, GetSpellTexture(self.updateNext), "SPELL")
			self.updateNext = nil
		end
	end
	
	if (not self.updateAbility) then
		return
	end
	
	local unit, abilityName, interrupted = split(",", self.updateAbility)
	
	if (specialOccasions[abilityName]) then
		self.updateNext = abilityName
		return
	end
	
	local startTime, duration, enabled, texture, type
	if (unit == "player") then
		type = "SPELL"
		texture = GetSpellTexture(abilityName)
		startTime, duration, enabled = GetSpellCooldown(abilityName)
	else
		local petAction
		for i = 1, NUM_PET_ACTION_SLOTS do
			petAction = GetPetActionInfo(i)
			if (abilityName == petAction) then
				abilityName = i
				type = "PET"
				texture = select(3, GetPetActionInfo(i))
				startTime, duration, enabled = GetPetActionCooldown(i)
				
				break
			end
		end
	end
	
	if (enabled == 1 and duration > 1.5) then
		self:newCooldown(abilityName, startTime, duration, texture, type)
		if (interrupted and settings.enableOutput) then
			local schoolName = spellSchools[self.spellSchoolID].Name
			local colorString = spellSchools[self.spellSchoolID].colorString
			local result = colorString .. format(L["%s school is locked for %d seconds!"], schoolName, duration) .. "|r"
			
			self:print(result)
		end
	end
	
	self.updateAbility = nil
end

addon.BAG_UPDATE_COOLDOWN = function(self)
	local startTime, duration, enabled, texture
	if (self.updateItem) then
		startTime, duration = GetItemCooldown(self.updateItem)
		if (startTime > 0 and duration > 1.5) then
			texture = select(10, GetItemInfo(self.updateItem))
			self:newCooldown(self.updateItem, startTime, duration, texture, "ITEM")
		end
		
		self.updateItem = nil
	end
	
	if (self.updateSlotID) then
		startTime, duration, enabled = GetInventoryItemCooldown("player", self.updateSlotID)
		if (enabled == 1 and duration > 1.5) then
			texture = GetInventoryItemTexture("player", self.updateSlotID)
			self:newCooldown(self.updateSlotID, startTime, duration, texture, "INVENTORY")
		end
		
		self.updateSlotID = nil
	end
end

local spellNameToSlotID = {}
local enchantIDToSpellName = {
	[3601] = GetSpellInfo(54793),	-- Frag Belt
	[3603] = GetSpellInfo(54998),	-- Hand-Mounted Pyro Rocket
	[3604] = GetSpellInfo(54999),	-- Hyperspeed Accelerators
	[3606] = GetSpellInfo(55016),	-- Nitro Boosts
	[3859] = GetSpellInfo(63765)	-- Springy Arachnoweave
}

addon.PLAYER_EQUIPMENT_CHANGED = function(self, slotID, beingEquipped)
	if (not beingEquipped) then
		for spellName, id in next, spellNameToSlotID do
			if (id and id == slotID) then
				spellNameToSlotID[spellName] = nil
				
				break
			end
		end
		
		return
	end
	
	local itemLink = GetInventoryItemLink("player", slotID)
	if (itemLink) then
		local _, enchantID = match(itemLink, "Hitem:(%d+):(%d+)")
		if (enchantIDToSpellName[enchantID]) then
			local spellName = enchantIDToSpellName[enchantID]
			spellNameToSlotID[spellName] = slotID
		end
	end
end

addon.UNIT_SPELLCAST_SUCCEEDED = function(self, unit, spellName)
	if ((unit ~= "player" and unit ~= "pet") or settings.blacklist[spellName]) then
		return
	end
	
	local itemSpell
	for item in next, settings.items do
		itemSpell = GetItemSpell(item)
		if (itemSpell == spellName) then
			self.updateItem = item
			
			return
		end
	end
	
	local slotID = spellNameToSlotID[spellName]
	if (slotID) then
		self.updateSlotID = slotID
		
		return
	end
	
	self.updateAbility = unit..","..spellName
end

addon.UNIT_SPELLCAST_FAILED_QUIET = function(self, unit, spellName)
	if (unit ~= "player") then
		return
	end
	
	self.updateAbility = unit..","..spellName..",true" -- interrupted
end

addon.SPELL_UPDATE_USABLE = function(self)
	for name, frame in next, self.active do
		local startTime, dur
		if (frame.type == "SPELL") then
			start, dur = GetSpellCooldown(name)
		elseif (frame.type == "ITEM") then
			start, dur = GetItemCooldown(name)
		elseif (frame.type == "INVENTORY") then
			start, dur = GetInventoryItemCooldown("player", name)
		elseif (frame.type == "PET") then
			start, dur = GetPetActionCooldown(name)
		end
		
		if (not start and not dur) then -- Calling Get'Something'Cooldown right after talent swap returns nil values
			self:dropCooldown(name)
			return
		end
		
		if (dur <= 1 and frame.type == "SPELL") then -- For abilities like Readiness, dur will be lowered to 1 or 0
			self:dropCooldown(name)
			return
		end
		
		if (frame.start > start) then
			local duration = start - GetTime() + dur
			frame.start = start
			frame.duration = duration
			frame.max = dur
			
			frame.Cooldown:SetCooldown(start, dur)
		end
	end
end

addon.COMBAT_LOG_EVENT_UNFILTERED = function(self, _, event, sourceGUID, _, _, _, _, _, ...)
	if (event ~= "SPELL_CAST_START" or sourceGUID ~= self.playerGUID) then
		return
	end
	
	local _, _, spellSchoolID = ...
	self.spellSchoolID = spellSchoolID
end

addon:SetScript("OnEvent", function(self, event, ...)
	if (self[event]) then
		self[event](self, ...)
	end
end)