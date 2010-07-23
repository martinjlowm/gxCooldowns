local _, settings = ...

local gxMedia = gxMedia or {
	buttonOverlay = [=[Interface\Buttons\UI-ActionButton-Border]=],
	edgeFile = [=[Interface\Tooltips\UI-Tooltip-Border]=]
}

local tinsert, tremove, split = table.insert, table.remove, strsplit
local GetSpellCooldown = GetSpellCooldown
local GetSpellTexture = GetSpellTexture
local GetItemCooldown = GetItemCooldown
local GetPetActionCooldown = GetPetActionCooldown

local addon = CreateFrame("Frame", nil, UIParent)
addon:RegisterEvent("PLAYER_LOGIN")
addon:RegisterEvent("SPELL_UPDATE_COOLDOWN")
addon:RegisterEvent("BAG_UPDATE_COOLDOWN")
addon:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
addon:RegisterEvent("SPELL_UPDATE_USABLE")

local loadFrame = function(self)
	if (#(self.pool) > 0) then
		return tremove(self.pool, 1)
	end
	
	local frame = CreateFrame("Frame", nil, self)
	frame:SetWidth(self.frameSize)
	frame:SetHeight(self.frameSize)
	frame:Hide()
	
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
			self:GetParent():dropCooldown(self.name)
			
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
	local numActive, prev = 0
	for _, frame in next, self.active do
		frame:ClearAllPoints()
		if (settings.growHorizontal) then
			if (prev) then
				frame:SetPoint("LEFT", prev, "RIGHT", 2, 0)
			else
				frame:SetPoint("LEFT", self, "LEFT", 0, 0)
			end
		else
			if (prev) then
				frame:SetPoint("BOTTOM", prev, "TOP", 0, 2)
			else
				frame:SetPoint("BOTTOM", self, "BOTTOM", 0, 0)
			end
		end
		
		numActive = numActive + 1
		prev = frame
	end
	
	if (settings.growHorizontal) then
		self:SetWidth(numActive * (self.frameSize + 2) - 2)
	else
		self:SetHeight(numActive * (self.frameSize + 2) - 2)
	end
end

local newCooldown = function(self, cooldownName, startTime, seconds, tex, type)
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

local dropCooldown = function(self, cooldownName)
	if (self.active[cooldownName]) then
		saveFrame(self, self.active[cooldownName])
		self.active[cooldownName] = nil
		
		repositionFrames(self)
		return true
	end
	
	return
end

addon.PLAYER_LOGIN = function(self)
	self.frameSize = settings.frameSize
	self.active = {}
	self.pool = {}
	
	self.newCooldown = newCooldown
	self.dropCooldown = dropCooldown
	
	self:SetPoint(settings.point, settings.relFrame, settings.relPoint, settings.xOffset, settings.yOffset)
	self:SetHeight(1)
	self:SetWidth(1)
	
	self:UnregisterEvent("PLAYER_LOGIN")
	self.PLAYER_LOGIN = nil
end

local specialOccasions = {
	[GetSpellInfo(14751)] = true, -- Inner Focus
	[GetSpellInfo(14177)] = true, -- Cold Blood
	[GetSpellInfo(16166)] = true, -- Elemental Mastery
	[GetSpellInfo(17116)] = true, -- Nature's Swiftness
	[GetSpellInfo(20216)] = true, -- Divine Favor
	[GetSpellInfo(12043)] = true, -- Presence of Mind
	[GetSpellInfo(5384)] = true, -- Feign Death
}
addon.SPELL_UPDATE_COOLDOWN = function(self, event)
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
	
	local unit, ability = split(",", self.updateAbility)
	
	if (specialOccasions[ability]) then
		self.updateNext = ability
		return
	end
	
	local startTime, duration, enabled
	if (unit == "player") then
		startTime, duration, enabled = GetSpellCooldown(ability)
	else
		local abilityName
		for i = 4, (NUM_PET_ACTION_SLOTS - 3) do
			abilityName = GetPetActionInfo(i)
			if (ability == abilityName) then
				startTime, duration, enabled = GetPetActionCooldown(i)
				
				break
			end
		end
	end
	
	if (enabled == 1 and duration > 1.5) then
		self:newCooldown(ability, startTime, duration, GetSpellTexture(ability), "SPELL")
	end
	
	self.updateAbility = nil
end

addon.BAG_UPDATE_COOLDOWN = function(self, event)
	local startTime, duration, enabled, texture
	for itemID in next, settings.items do
		startTime, duration, enabled = GetItemCooldown(itemID)
		_, _, _, _, _, _, _, _, _, texture = GetItemInfo(itemID)
		if (enabled == 1 and duration > 1.5) then
			self:newCooldown(itemID, startTime, duration, texture, "ITEM")
		end
	end
end

addon.UNIT_SPELLCAST_SUCCEEDED = function(self, event, unit, spellName)
	if ((unit ~= "player" and unit ~= "pet") or settings.blacklist[spellName]) then
		return
	end
	
	self.updateAbility = unit..","..spellName
end

addon.SPELL_UPDATE_USABLE = function(self, event)
	for name, frame in next, self.active do
		local startTime, dur
		if (frame.type == "SPELL") then
			start, dur = GetSpellCooldown(name)
		elseif (frame.type == "ITEM") then
			start, dur = GetItemCooldown(name)
		end
		
		if (dur <= 1 and frame.type == "SPELL") then
			self:dropCooldown(name)
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

addon:SetScript("OnEvent", function(self, event, ...)
	self[event](self, event, ...)
end)