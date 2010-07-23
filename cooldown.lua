local items = {
	[42126] = true, -- Medallion of the Horde
	[33448] = true, -- Runic Mana Potion
}
local frameSize = 34

local gxMedia = gxMedia or {
	buttonOverlay = [=[Interface\Buttons\UI-ActionButton-Border]=],
	edgeFile = [=[Interface\Tooltips\UI-Tooltip-Border]=]
}

local tinsert, tremove = table.insert, table.remove
local GetSpellCooldown = GetSpellCooldown
local GetSpellTexture = GetSpellTexture
local GetItemCooldown = GetItemCooldown
local GetPetActionCooldown = GetPetActionCooldown

local addon = CreateFrame("Frame", nil, UIParent)
addon:RegisterEvent("PLAYER_LOGIN")
addon:RegisterEvent("SPELL_UPDATE_COOLDOWN")
addon:RegisterEvent("BAG_UPDATE_COOLDOWN")
addon:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")

local loadFrame = function(self)
	if (#(self.pool) > 0) then
		return table.remove(self.pool, 1)
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
	
	table.insert(self.pool, frame)
end

local repositionFrames = function(self)
	local numActive = 0
	for _ in next, self.active do
		numActive = numActive + 1
	end
	
	self:SetWidth(numActive * (self.frameSize + 2) - 2)
	
	local prev
	for _, frame in next, self.active do
		frame:ClearAllPoints()
		if (prev) then
			frame:SetPoint("LEFT", prev, "RIGHT", 2, 0)
		else
			frame:SetPoint("LEFT", self, "LEFT", 0, 0)
		end
		
		prev = frame
	end
end

local newCooldown = function(self, cooldownName, startTime, seconds, tex)
	if (self.active[cooldownName]) then
		return
	end
	
	local frame = loadFrame(self)
	
	local duration = startTime - GetTime() + seconds
	frame.duration = duration
	frame.max = seconds
	
	frame.name = cooldownName
	
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
	self.frameSize = frameSize
	self.active = {}
	self.pool = {}
	
	self.newCooldown = newCooldown
	self.dropCooldown = dropCooldown
	
	self:SetPoint("CENTER", UIParent, "CENTER", 0, -150)
	self:SetHeight(1)
	self:SetWidth(1)
	
	self:UnregisterEvent("PLAYER_LOGIN")
	self.PLAYER_LOGIN = nil
end

addon.SPELL_UPDATE_COOLDOWN = function(self, event)
	if (not self.updateAbility) then
		return
	end
	
	local unit, ability = strsplit(",", self.updateAbility)
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
		self:newCooldown(ability, startTime, duration, GetSpellTexture(ability))
	elseif (enabled == 1) then
		self:dropCooldown(ability)
	end
	
	self.updateAbility = nil
end

addon.BAG_UPDATE_COOLDOWN = function(self)
	local startTime, duration, enabled, texture
	for itemID in next, items do
		startTime, duration, enabled = GetItemCooldown(itemID)
		_, _, _, _, _, _, _, _, _, texture = GetItemInfo(itemID)
		if (enabled == 1 and duration > 1.5) then
			self:newCooldown(itemID, startTime, duration, texture)
		elseif (enabled == 1) then
			self:dropCooldown(itemID)
		end
	end
end

addon.UNIT_SPELLCAST_SUCCEEDED = function(self, event, unit, spellName)
	if (unit ~= "player" and unit ~= "pet") then
		return
	end
	
	self.updateAbility = unit..","..spellName
end

addon:SetScript("OnEvent", function(self, event, ...)
	self[event](self, event, ...)
end)