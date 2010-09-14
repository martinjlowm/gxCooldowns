local _, settings = ...
local L = settings.L

local gxMedia = gxMedia or {
	buttonOverlay = [=[Interface\Buttons\UI-Quickslot2]=],
	edgeFile = [=[Interface\Buttons\UI-EmptySlot]=],
	font = [=[Fonts\FRIZQT__.TTF]=]
}

local unpack = unpack
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
addon:SetHeight(1)
addon:SetWidth(1)
addon:SetFrameLevel(2)
addon:RegisterEvent("PLAYER_LOGIN")
addon:RegisterEvent("SPELL_UPDATE_COOLDOWN")
addon:RegisterEvent("BAG_UPDATE_COOLDOWN")
addon:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
addon:RegisterEvent("UNIT_SPELLCAST_FAILED_QUIET")
addon:RegisterEvent("SPELL_UPDATE_USABLE")
addon:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
addon:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
local style
if (IsAddOnLoaded("gxMedia")) then
	style = {
		Backdrop = {
			Texture = gxMedia.edgeFile,
		},
		Cooldown = {
			Height = 36,
			Width = 36
		},
		Icon = {
			Height = 34,
			Width = 34,
			TexCoords = {.07, .93, .07, .93}
		},
		Overlay = {
			Height = 44,
			Width = 44,
			Texture = gxMedia.buttonOverlay,
			TexCoords = {0, 1, .02, 1},
			Color = {.6, .6, .6, 1}
		}
	}
else
	style = {
		Backdrop = {
			Width = 34,
			Height = 35,
			OffsetY = -0.5,
			Texture = gxMedia.edgeFile,
			TexCoords = {0.2,0.8,0.2,0.8}
		},
		Cooldown = {
			Height = 36,
			Width = 36
		},
		Icon = {
			Height = 36,
			Width = 36
		},
		Overlay = {
			Height = 66,
			Width = 66,
			OffsetY = -1,
			Texture = gxMedia.buttonOverlay
		}
	}
end
addon.styleDB = style
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
	
	local backdrop = frame:CreateTexture(nil, "BACKGROUND")
	backdrop:SetTexture(self.styleDB.Backdrop.Texture)
	backdrop:SetVertexColor(unpack(self.styleDB.Backdrop.Color or {1,1,1,1}))
	backdrop:SetTexCoord(unpack(self.styleDB.Backdrop.TexCoords or {0,1,0,1}))
	backdrop:SetBlendMode(self.styleDB.Backdrop.BlendMode or "BLEND")
	backdrop:SetWidth((self.styleDB.Backdrop.Width or 36) * (self.styleDB.Backdrop.Scale or 1) * self.frameSize/36)
	backdrop:SetHeight((self.styleDB.Backdrop.Height or 36) * (self.styleDB.Backdrop.Scale or 1) * self.frameSize/36)
	backdrop:SetPoint("CENTER", frame, "CENTER", self.styleDB.Backdrop.OffsetX or 0, self.styleDB.Backdrop.OffsetY or 0)
	
	local icon = frame:CreateTexture(nil, "ARTWORK")
	icon:SetTexCoord(unpack(self.styleDB.Icon.TexCoords or {0,1,0,1}))
	icon:SetWidth((self.styleDB.Icon.Width or 36) * (self.styleDB.Icon.Scale or 1) * self.frameSize/36)
	icon:SetHeight((self.styleDB.Icon.Height or 36) * (self.styleDB.Icon.Scale or 1) * self.frameSize/36)
	icon:SetPoint("CENTER")
	
	local cd = CreateFrame("Cooldown", nil, frame)
	cd:SetPoint("CENTER")
	cd:SetWidth((self.styleDB.Cooldown.Width or 36) * (self.styleDB.Cooldown.Scale or 1) * self.frameSize/36)
	cd:SetHeight((self.styleDB.Cooldown.Height or 36) * (self.styleDB.Cooldown.Scale or 1) * self.frameSize/36)
	
	local overlay = frame:CreateTexture(nil, "OVERLAY")
	overlay:SetTexture(self.styleDB.Overlay.Texture)
	overlay:SetPoint("CENTER", frame, "CENTER", self.styleDB.Overlay.OffsetX or 0, self.styleDB.Overlay.OffsetY or 0)
	overlay:SetHeight((self.styleDB.Overlay.Height or 36) * (self.styleDB.Overlay.Scale or 1) * self.frameSize/36)
	overlay:SetWidth((self.styleDB.Overlay.Width or 36) * (self.styleDB.Overlay.Scale or 1) * self.frameSize/36)
	overlay:SetVertexColor(unpack(self.styleDB.Overlay.Color or {1,1,1,1}))
	
	frame:SetScript("OnUpdate", function(self, elapsed)
		if (elapsed > 3 and self.elapseFix) then -- OnUpdate runs [fps] times in a second, if elapsed is 3 the fps would be 0.33..., we assume that will never happen.
			elapsed = elapsed - floor(elapsed) -- elapsed is 5+ right when you log in, we try to reset it here because it would bug out the duration.
			self.elapseFix = nil
		end
		
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

local repositionFrames = function(self)
	local gap = settings.gap
	
	local numActive, prev = 0
	for _, frame in next, self.active do
		frame:ClearAllPoints()
		if (settings.growHorizontal) then
			if (prev) then
				frame:SetPoint("LEFT", prev, "RIGHT", gap, 0)
			else
				frame:SetPoint("LEFT", self, "LEFT")
			end
		else
			if (prev) then
				frame:SetPoint("BOTTOM", prev, "TOP", 0, gap)
			else
				frame:SetPoint("BOTTOM", self, "BOTTOM")
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

addon.newCooldown = function(self, cooldownName, startTime, seconds, tex, type, elapseFix)
	if (self.active[cooldownName]) then
		return
	end
	
	local frame = loadFrame(self)
	
	local duration = seconds - (GetTime() - startTime)
	frame.start = startTime
	frame.elapseFix = elapseFix
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
	local frame = self.active[cooldownName]
	if (frame) then
		frame:Hide()
		tinsert(self.pool, frame)
		self.active[cooldownName] = nil
		
		repositionFrames(self)
		return true
	end
	
	return
end

if (LibStub) then
	local LBF = LibStub("LibButtonFacade",true)
	if (LBF) then
		local skinTable, backdrop, cooldown, icon, normal
		local skinChanged = function(self, skinName)
			skinTable = LBF:GetSkins()
			backdrop = skinTable[skinName].Backdrop
			cooldown = skinTable[skinName].Cooldown
			icon = skinTable[skinName].Icon
			normal = skinTable[skinName].Normal
			
			self.styleDB.Backdrop = backdrop
			self.styleDB.Cooldown = cooldown
			self.styleDB.Icon = icon
			self.styleDB.Overlay = normal
			
			for _, frame in next, self.active do
				if (not backdrop.Hide) then
					frame.Backdrop:SetTexture(backdrop.Texture)
					frame.Backdrop:SetVertexColor(unpack(backdrop.Color or {1,1,1,1}))
					frame.Backdrop:SetTexCoord(unpack(backdrop.TexCoords or {0,1,0,1}))
					frame.Backdrop:SetBlendMode(backdrop.BlendMode or "BLEND")
					frame.Backdrop:SetWidth((backdrop.Width or 36) * (backdrop.Scale or 1) * self.frameSize/36)
					frame.Backdrop:SetHeight((backdrop.Height or 36) * (backdrop.Scale or 1) * self.frameSize/36)
					frame.Backdrop:ClearAllPoints()
					frame.Backdrop:SetPoint("CENTER", frame, "CENTER", backdrop.OffsetX or 0, backdrop.OffsetY or 0)
				else
					frame.Backdrop:SetTexture(nil)
				end
				
				if (not cooldown.Hide) then
					frame.Cooldown:SetHeight((cooldown.Height or 36) * (cooldown.Scale or 1) * self.frameSize/36)
					frame.Cooldown:SetWidth((cooldown.Width or 36) * (cooldown.Scale or 1) * self.frameSize/36)
				else
					frame.Cooldown:Hide()
				end
				
				frame.Icon:SetWidth((icon.Width or 36) * (icon.Scale or 1) * self.frameSize/36)
				frame.Icon:SetHeight((icon.Height or 36) * (icon.Scale or 1) * self.frameSize/36)
				frame.Icon:SetTexCoord(unpack(icon.TexCoords or {0,1,0,1}))
				
				if (not normal.Hide) then
					frame.Overlay:SetTexture(normal.Texture)
					frame.Overlay:SetPoint("CENTER", frame, "CENTER", normal.OffsetX or 0, normal.OffsetY or 0)
					frame.Overlay:SetHeight((normal.Height or 36) * (normal.Scale or 1) * self.frameSize/36)
					frame.Overlay:SetWidth((normal.Width or 36) * (normal.Scale or 1) * self.frameSize/36)
					frame.Overlay:SetVertexColor(unpack(normal.Color or {1,1,1,1}))
				else
					frame.Overlay:SetTexture(nil)
				end
			end
			
			if (#(self.pool) > 0) then
				for _, frame in next, self.pool do
					if (not backdrop.Hide) then
						frame.Backdrop:SetTexture(backdrop.Texture)
						frame.Backdrop:SetVertexColor(unpack(backdrop.Color or {1,1,1,1}))
						frame.Backdrop:SetTexCoord(unpack(backdrop.TexCoords or {0,1,0,1}))
						frame.Backdrop:SetBlendMode(backdrop.BlendMode or "BLEND")
						frame.Backdrop:SetWidth((backdrop.Width or 36) * (backdrop.Scale or 1) * self.frameSize/36)
						frame.Backdrop:SetHeight((backdrop.Height or 36) * (backdrop.Scale or 1) * self.frameSize/36)
						frame.Backdrop:ClearAllPoints()
						frame.Backdrop:SetPoint("CENTER", frame, "CENTER", backdrop.OffsetX or 0, backdrop.OffsetY or 0)
					else
						frame.Backdrop:SetTexture(nil)
					end
					
					if (not cooldown.Hide) then
						frame.Cooldown:SetHeight((cooldown.Height or 36) * (cooldown.Scale or 1) * self.frameSize/36)
						frame.Cooldown:SetWidth((cooldown.Width or 36) * (cooldown.Scale or 1) * self.frameSize/36)
					else
						frame.Cooldown:Hide()
					end
					
					frame.Icon:SetWidth((icon.Width or 36) * (icon.Scale or 1) * self.frameSize/36)
					frame.Icon:SetHeight((icon.Height or 36) * (icon.Scale or 1) * self.frameSize/36)
					frame.Icon:SetTexCoord(unpack(icon.TexCoords or {0,1,0,1}))
					
					if (not normal.Hide) then
						frame.Overlay:SetTexture(normal.Texture)
						frame.Overlay:SetPoint("CENTER", frame, "CENTER", normal.OffsetX or 0, normal.OffsetY or 0)
						frame.Overlay:SetHeight((normal.Height or 36) * (normal.Scale or 1) * self.frameSize/36)
						frame.Overlay:SetWidth((normal.Width or 36) * (normal.Scale or 1) * self.frameSize/36)
						frame.Overlay:SetVertexColor(unpack(normal.Color or {1,1,1,1}))
					else
						frame.Overlay:SetTexture(nil)
					end
				end
			end
		end
		
		LBF:RegisterSkinCallback("gxCooldowns", skinChanged, addon)
		LBF:Group("gxCooldowns")
	end
end

addon.PLAYER_LOGIN = function(self)
	self.playerGUID = UnitGUID("player")
	self.frameSize = settings.frameSize
	
	self:SetPoint(settings.point, settings.relFrame, settings.relPoint, settings.xOffset, settings.yOffset)
	
	-- Scan when we reload the UI or log in w/e
	local _, _, offset, numSpellsInTab = GetSpellTabInfo(GetNumSpellTabs())
	local numSpells = offset + numSpellsInTab
	
	local spellName, startTime, duration, enabled
	for spellNum = 1, numSpells do
		spellName = GetSpellName(spellNum, BOOKTYPE_SPELL)
		startTime, duration, enabled = GetSpellCooldown(spellName)
		if (enabled == 1 and duration > settings.minDuration) then
			self:newCooldown(spellName, startTime, duration, GetSpellTexture(spellName), "SPELL", true)
		end
	end
	
	-- Add equipped items to our enchant list, if they have enchants of our wish.
	for i = 1, 19 do
		self:PLAYER_EQUIPMENT_CHANGED(i, true)
	end
	
	self:UnregisterEvent("PLAYER_LOGIN")
	self.PLAYER_LOGIN = nil
end


local spellSchools = { -- We assume players can't use combined schools [Frostfire bolt locks both schools however!]
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
	[20] = {
		Name = L["Frostfire"],
		colorString = "|cffFF8000"
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

local FD = GetSpellInfo(5384)	-- Feign Death can't be tracked through CLEU :(
local sharedCooldowns = {
	[GetSpellInfo(49376)] = GetSpellInfo(16979)	-- 'Feral Charge - Cat' refreshes 'Feral Charge - Bear'
}
addon.SPELL_UPDATE_COOLDOWN = function(self)
	local startTime, duration, enabled, texture
	if (self.updateNext) then
		startTime, duration, enabled = GetSpellCooldown(self.updateNext)
		if (enabled == 1 and duration > settings.minDuration and (settings.maxDuration and duration < settings.maxDuration or true)) then
			texture = GetSpellTexture(self.updateNext)
			self:newCooldown(self.updateNext, startTime, duration, texture, "SPELL")
			self.updateNext = nil
		end
	end
	
	if (self.updateSpecial) then
		startTime, duration, enabled = GetSpellCooldown(self.updateSpecial)
		if (enabled == 1 and duration > settings.minDuration and (settings.maxDuration and duration < settings.maxDuration or true)) then
			texture = GetSpellTexture(self.updateSpecial)
			self:newCooldown(self.updateSpecial, startTime, duration, texture, "SPELL")
			self.updateSpecial = nil
		end
	end
	
	if (self.updateShared) then
		texture = GetSpellTexture(self.updateShared)
		startTime, duration, enabled = GetSpellCooldown(self.updateShared)
		self:newCooldown(self.updateShared, startTime, duration, texture, "SPELL")
		
		self.updateShared = nil
	end
	
	if (not self.updateAbility) then
		return
	end
	
	local unit, abilityName, interrupted = split(",", self.updateAbility)
	if (FD == abilityName) then
		self.updateNext = abilityName
		return
	end
	
	local type
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
	
	if (enabled == 1 and duration > settings.minDuration and (settings.maxDuration and duration < settings.maxDuration or true)) then
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
	
	if (self.queuedItem) then	-- For items with a cooldown that doesn't start before leaving combat!
		startTime, duration, enabled = GetItemCooldown(self.queuedItem)
		if (enabled == 1 and duration > settings.minDuration and (settings.maxDuration and duration < settings.maxDuration or true)) then
			texture = select(10, GetItemInfo(self.queuedItem))
			self:newCooldown(self.queuedItem, startTime, duration, texture, "ITEM")
			
			self.queuedItem = nil
		end
	end
	
	if (self.updateItem) then
		startTime, duration, enabled = GetItemCooldown(self.updateItem)
		if (enabled == 1 and duration > settings.minDuration and (settings.maxDuration and duration < settings.maxDuration or true)) then
			texture = select(10, GetItemInfo(self.updateItem))
			self:newCooldown(self.updateItem, startTime, duration, texture, "ITEM")
			self.updateItem = nil
		elseif (enabled == 0 and duration > settings.minDuration and (settings.maxDuration and duration < settings.maxDuration or true)) then
			self.queuedItem = self.updateItem
			self.updateItem = nil
		end
	end
	
	if (self.updateSlotID) then
		startTime, duration, enabled = GetInventoryItemCooldown("player", self.updateSlotID)
		if (enabled == 1 and duration > settings.minDuration and (settings.maxDuration and duration < settings.maxDuration or true)) then
			texture = GetInventoryItemTexture("player", self.updateSlotID)
			self:newCooldown(self.updateSlotID, startTime, duration, texture, "INVENTORY")
			
			self.updateSlotID = nil
		end
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
		enchantID = tonumber(enchantID)
		
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
	
	local item = settings.itemSpells[spellName]
	if (item) then
		self.updateItem = item
		
		return
	end
	
	local slotID = spellNameToSlotID[spellName]
	if (slotID) then
		self.updateSlotID = slotID
		
		return
	end
	
	if (sharedCooldowns[spellName]) then -- This should be druids only
		self.updateShared = sharedCooldowns[spellName]
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
		
		if (not start and not dur) then -- Calling Get'Something'Cooldown right after talent swap returns a nil value
			self:dropCooldown(name)
			return
		end
		
		if (dur <= 1 and frame.type == "SPELL") then -- For abilities like Readiness, dur will be lowered to 1 or 0
			self:dropCooldown(name)
			return
		end
		
		if (frame.start > start or frame.max > dur) then
			local duration = start - GetTime() + dur
			frame.start = start
			frame.duration = duration
			frame.max = dur
			
			frame.Cooldown:SetCooldown(start, dur)
		end
	end
end

local specialOccasions = {
	[GetSpellInfo(14177)] = true,	-- Cold Blood
	[GetSpellInfo(11129)] = true,	-- Combustion
	[GetSpellInfo(20216)] = true,	-- Divine Favor
	[GetSpellInfo(16166)] = true,	-- Elemental Mastery
	[GetSpellInfo(14751)] = true,	-- Inner Focus
	[GetSpellInfo(17116)] = true,	-- Nature's Swiftness
	[GetSpellInfo(12043)] = true	-- Presence of Mind
}
addon.COMBAT_LOG_EVENT_UNFILTERED = function(self, _, event, sourceGUID, _, _, _, _, _, ...)
	local _, spellName, spellSchoolID = ...
	if (event == "SPELL_AURA_REMOVED" and sourceGUID == self.playerGUID and specialOccasions[spellName]) then
		self.updateSpecial = spellName
	elseif (event == "SPELL_CAST_START" and sourceGUID == self.playerGUID) then
		self.spellSchoolID = spellSchoolID
	end
end

do
	local class = select(2, UnitClass("player"))
	if (class == "ROGUE" or class == "DRUID") then
		local stealth = class == "ROGUE" and GetSpellInfo(1784) or GetSpellInfo(5215)
		addon:RegisterEvent("UPDATE_STEALTH")
		addon.UPDATE_STEALTH = function(self)
			local startTime, duration, enabled = GetSpellCooldown(stealth)
			if (enabled == 1 and duration > settings.minDuration and (settings.maxDuration and duration < settings.maxDuration or true)) then
				texture = GetSpellTexture(stealth)
				self:newCooldown(stealth, startTime, duration, texture, "SPELL")
			end
		end
	end
end

addon:SetScript("OnEvent", function(self, event, ...)
	if (self[event]) then
		self[event](self, ...)
	end
end)