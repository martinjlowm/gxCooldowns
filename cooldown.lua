local aName, gxCooldowns = ...

local LBF, buttonGroup
local Shiner = LibStub("tekShiner")

local match = string.match
local next = next
local select = select
local split = string.split
local tinsert = table.insert
local tremove = table.remove
local unpack = unpack
local GetTime = GetTime

local GetInventoryItemCooldown = GetInventoryItemCooldown
local GetInventoryItemTexture = GetInventoryItemTexture
local GetItemCooldown = GetItemCooldown
local GetItemInfo = GetItemInfo
local GetPetActionCooldown = GetPetActionCooldown
local GetSpellCooldown = GetSpellCooldown
local GetSpellTexture = GetSpellTexture

-- We limit the schools to double schools for now. (Only frostfire is available to players atm.) http://www.wowwiki.com/API_COMBAT_LOG_EVENT
local spellSchoolColors = {
	[SCHOOL_MASK_PHYSICAL] = {1,1,0},				-- Physical		1
	[SCHOOL_MASK_HOLY] = {1,.9,.5},					-- Holy			2
	[SCHOOL_MASK_HOLY + SCHOOL_MASK_PHYSICAL] = {	-- Holystrike	3
		{1,.9,.5},
		{1,1,0}
	},
	[SCHOOL_MASK_FIRE] = {1,.5,0},					-- Fire			4
	[SCHOOL_MASK_FIRE + SCHOOL_MASK_PHYSICAL] = {	-- Flamestrike	5
		{1,.5,0},
		{1,1,0}
	},
	[SCHOOL_MASK_HOLY + SCHOOL_MASK_FIRE] = {		-- Holyfire		6
		{1,.9,.5},
		{1,.5,0}
	},
	[SCHOOL_MASK_NATURE] = {.3,1,.3},				-- Nature		8
	[SCHOOL_MASK_NATURE + SCHOOL_MASK_PHYSICAL] = {	-- Stormstrike	9
		{.3,1,.3},
		{1,1,0}
	},
	[SCHOOL_MASK_NATURE + SCHOOL_MASK_HOLY] = {		-- Holystorm	10
		{.3,1,.3},
		{1,.9,.5}
	},
	[SCHOOL_MASK_NATURE + SCHOOL_MASK_FIRE] = {		-- Firestorm	12
		{.3,1,.3},
		{1,.5,0}
	},
	[SCHOOL_MASK_FROST] = {.5,1,1},					-- Frost		16
	[SCHOOL_MASK_FROST + SCHOOL_MASK_PHYSICAL] = {	-- Froststrike	17
		{.5,1,1},
		{1,1,0}
	},
	[SCHOOL_MASK_FROST + SCHOOL_MASK_HOLY] = {		-- Holyfrost	18
		{.5,1,1},
		{1,.9,.5}
	},
	[SCHOOL_MASK_FROST + SCHOOL_MASK_FIRE] = {		-- Frostfire	20
		{.5,1,1},
		{1,.5,0}
	},
	[SCHOOL_MASK_FROST + SCHOOL_MASK_NATURE] = {	-- Froststorm	24
		{.5,1,1},
		{.3,1,.3}
	},
	[SCHOOL_MASK_SHADOW] = {.5,.5,1},				-- Shadow		32
	[SCHOOL_MASK_SHADOW + SCHOOL_MASK_PHYSICAL] = {	-- Shadowstrike	33
		{.5,.5,1},
		{1,1,0}
	},
	[SCHOOL_MASK_SHADOW + SCHOOL_MASK_HOLY] = {		-- Twilight		34
		{.5,.5,1},
		{1,.9,.5}
	},
	[SCHOOL_MASK_SHADOW + SCHOOL_MASK_FIRE] = {		-- Shadowflame	36
		{.5,.5,1},
		{1,.5,0}
	},
	[SCHOOL_MASK_SHADOW + SCHOOL_MASK_NATURE] = {	-- Plague		40
		{.5,.5,1},
		{.3,1,.3}
	},
	[SCHOOL_MASK_SHADOW + SCHOOL_MASK_FROST] = {	-- Shadowfrost	48
		{.5,.5,1},
		{.5,1,1}
	},
	[SCHOOL_MASK_ARCANE] = {1,.5,1},				-- Arcane		64
	[SCHOOL_MASK_ARCANE + SCHOOL_MASK_PHYSICAL] = {	-- Spellstrike	65
		{1,.5,1},
		{1,1,0}
	},
	[SCHOOL_MASK_ARCANE + SCHOOL_MASK_HOLY] = {		-- Divine		66
		{1,.5,1},
		{1,.9,.5}
	},
	[SCHOOL_MASK_ARCANE + SCHOOL_MASK_FIRE] = {		-- Spellfire	68
		{1,.5,1},
		{1,.5,0}
	},
	[SCHOOL_MASK_ARCANE + SCHOOL_MASK_NATURE] = {	-- Spellstorm	72
		{1,.5,1},
		{.3,1,.3}
	},
	[SCHOOL_MASK_ARCANE + SCHOOL_MASK_FROST] = {	-- Spellfrost	80
		{1,.5,1},
		{.5,1,1}
	},
	[SCHOOL_MASK_ARCANE + SCHOOL_MASK_SHADOW] = {	-- Spellshadow	80
		{1,.5,1},
		{.5,.5,1}
	},
}
local FD = 5384 -- Feign Death can't be tracked through CLEU :(
local sharedCooldowns = {
	[49376] = 16979	-- 'Feral Charge - Cat' refreshes 'Feral Charge - Bear'
}
local spellIDToSlotID = {}
local enchantTextToSpellID = {
	["Use: Detatch and throw a Cobalt Frag Bomb, inflicting 875 Fire damage and incapacitating targets for 3 sec in a 3 yard radius.  Any damage will break the effect. (6 Min Cooldown)"] = 67890, -- Frag Belt
	["Use: Fires an explosive rocket at an enemy for 1165 Fire damage. (45 Sec Cooldown)"] = 54757, -- Hand-Mounted Pyro Rocket
	["Use: Greatly increase your run speed for 5 sec. (3 Min Cooldown)"] = 55004, -- Nitro Boosts
	["Use: Increases your haste rating by 240 for 12 sec. (1 Min Cooldown)"] = 54758, -- Hyperspeed Accelerators
	["Use: Reduces your falling speed for 30 sec. (1 Min Cooldown)"] = 55001, -- Springy Arachnoweave
}
local specialOccasions = {
	[57934] = true,	-- Tricks of the Trade
	[14751] = true,	-- Chakra
	[14177] = true,	-- Cold Blood
	[11129] = true,	-- Combustion
	[16166] = true,	-- Elemental Mastery
	[89485] = true,	-- Inner Focus
	[34477] = true,	-- Misdirection
	[17116] = true,	-- Nature's Swiftness
	[12043] = true	-- Presence of Mind
}

local anchor = CreateFrame("Frame", aName .. "Anchor", UIParent)
anchor:SetClampedToScreen(true)
anchor:SetBackdrop({bgFile = [=[Interface\ChatFrame\ChatFrameBackground]=]})
anchor:SetBackdropColor(0, 0, 0, 0)
anchor:RegisterEvent("BAG_UPDATE_COOLDOWN")
anchor:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
anchor:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
anchor:RegisterEvent("PLAYER_LOGIN")
anchor:RegisterEvent("SPELL_UPDATE_COOLDOWN")
anchor:RegisterEvent("SPELL_UPDATE_USABLE")
anchor:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
anchor:RegisterEvent("PLAYER_REGEN_ENABLED")
anchor:RegisterEvent("PLAYER_REGEN_DISABLED")
anchor.active = {}
anchor.pool = {}

gxCooldowns.growthValues = {
	["Down"] = {
		point = "TOP",
		horizontal = false
	},
	["Left"] = {
		point = "RIGHT",
		horizontal = true
	},
	["Left and Right"] = {
		point = "CENTER",
		horizontal = true
	},
	["Right"] = {
		point = "LEFT",
		horizontal = true
	},
	["Up"] = {
		point = "BOTTOM",
		horizontal = false
	},
	["Up and Down"] = {
		point = "CENTER",
		horizontal = false
	}
}

local repositionFrames = function(self)
	local gap = gxCooldownsDB.gap
	
	local point, rel, anchor, x, y
	local numActive, prev = 0
	for _, frame in next, self.active do
		frame:ClearAllPoints()
		if (gxCooldowns.growthValues[gxCooldownsDB.growth].horizontal) then
			if (prev) then
				rel, anchor, x = prev, "RIGHT", gap
			else
				rel, anchor, x = self, "LEFT", 0
			end
			point, y = "LEFT", 0
		else
			if (prev) then
				rel, anchor, y = prev, "TOP", gap
			else
				rel, anchor, y = self, "BOTTOM", 0
			end
			point, x = "BOTTOM", 0
		end
		
		frame:SetPoint(point, rel, anchor, x, y)
		
		numActive = numActive + 1
		prev = frame
	end
	
	local length = numActive * (36 + gap) - gap
	if (length < 36) then
		length = 36
	end
	
	if (gxCooldowns.growthValues[gxCooldownsDB.growth].horizontal) then
		self:SetWidth(length)
	else
		self:SetHeight(length)
	end
end

do
	local cooldownHide = function(self)
		self.__owner.parent:dropCooldown(self.__owner.name)
	end
	
	local frameNum = 1
	local loadFrame = function(self)
		if (#(self.pool) > 0) then
			return tremove(self.pool, 1)
		end
		
		local name = aName .. "Icon" .. frameNum
		
		local frame = CreateFrame("Button", name, self, "ActionButtonTemplate")
		frame:EnableMouse(nil)
		frame:SetFrameStrata("LOW")
		frame:Hide()
		frame.parent = self
		
		local model = Shiner.new(frame)
		for _, sparkle in next, model.sparkles do
			sparkle:SetHeight(sparkle:GetHeight() * 3)
			sparkle:SetWidth(sparkle:GetWidth() * 3)
		end
		model:SetAllPoints(frame)
		model:Hide()
		
		frame.Cooldown = _G[name.."Cooldown"]
		frame.Cooldown.__owner = frame
		frame.Cooldown:HookScript("OnHide", cooldownHide)
		frame.Icon = _G[name.."Icon"]
		frame.Model = model
		
		if (LBF) then
			buttonGroup:AddButton(frame)
		end
		
		frameNum = frameNum + 1
		
		return frame
	end
	
	anchor.newCooldown = function(self, cooldownName, startTime, duration, tex, aType)
		local frame
		if (self.active[cooldownName]) then
			frame = self.active[cooldownName]
		else
			frame = loadFrame(self)
		end
		
		frame.start = startTime
		frame.duration = duration
		frame.max = duration
		frame.nextUpdate = .25
		
		frame.name = cooldownName
		frame.type = aType
		
		frame.Icon:SetTexture(tex)
		frame.Cooldown:SetCooldown(startTime, duration)
		frame:Show()
		
		if (self.lockdownTime) then
			frame.Model:Show()
			frame.Model.time = self.lockdownTime
			if (type(spellSchoolColors[self.spellSchoolID][1]) == "table") then
				local i = 1
				for _, sparkle in next, frame.Model.sparkles do
					sparkle:SetVertexColor(unpack(spellSchoolColors[self.spellSchoolID][i]))
					
					if (i == 1) then
						i = i + 1
					else
						i = i - 1
					end
				end
			else
				for _, sparkle in next, frame.Model.sparkles do
					sparkle:SetVertexColor(unpack(spellSchoolColors[self.spellSchoolID]))
				end
			end
			
			self.lockdownTime = nil
		end
		
		self.active[cooldownName] = frame
		
		repositionFrames(self)
	end
	
	anchor.dropCooldown = function(self, cooldownName)
		local frame = self.active[cooldownName]
		if (frame) then
			self.active[cooldownName] = nil
			tinsert(self.pool, frame)
			
			if (frame.Model:IsShown()) then
				frame.Model:Hide()
			end
			
			repositionFrames(self)
			
			frame:Hide()
		end
	end
end

gxCooldowns.updateFrames = function(growth)
	gxCooldownsDB.growth = growth
	anchor:SetHeight(36)
	anchor:SetWidth(36) -- Reset the dimensions before we engage repositionFrames
	repositionFrames(anchor)
	
	anchor:ClearAllPoints()
	anchor:SetPoint(gxCooldowns.growthValues[gxCooldownsDB.growth].point, UIParent, "CENTER", gxCooldownsDB.xOffset, gxCooldownsDB.yOffset)
end

gxCooldowns.setOutCombatAlpha = function(alpha)
	gxCooldownsDB.OOCAlpha = alpha
end

gxCooldowns.setScale = function(scale)
	gxCooldownsDB.scale = scale
	anchor:SetScale(scale)
end

gxCooldowns.setGap = function(gap)
	gxCooldownsDB.gap = gap
	repositionFrames(anchor)
end

gxCooldowns.setPosition = function(x, y)
	gxCooldownsDB.xOffset, gxCooldownsDB.yOffset = x, y
	
	anchor:ClearAllPoints()
	anchor:SetPoint(gxCooldowns.growthValues[gxCooldownsDB.growth].point, UIParent, "CENTER", gxCooldownsDB.xOffset, gxCooldownsDB.yOffset)
end

do
	local x, y
	local coords = {[1] = {}, [2] = {}, [3] = {}}
	local startMoving = function(self, button)
		if (button == "RightButton") then
			gxCooldowns.locked = true
			gxCooldowns.toggleLock()
			return
		end
		
		_, _, _, x, y = self:GetPoint()
		coords[1].x = x
		coords[1].y = y
		
		self:StartMoving()
		
		_, _, _, x, y = self:GetPoint()
		coords[2].x = x
		coords[2].y = y
	end
	
	local stopMoving = function(self, button)
		if (button == "RightButton") then
			return
		end
		
		_, _, _, x, y = self:GetPoint()
		coords[3].x = x
		coords[3].y = y
		self:StopMovingOrSizing()
		
		x = floor((coords[3].x - coords[2].x) + coords[1].x)
		y = floor((coords[3].y - coords[2].y) + coords[1].y)
		
		gxCooldownsDB.xOffset = x
		gxCooldownsDB.yOffset = y
		
		self:ClearAllPoints()
		self:SetPoint(gxCooldowns.growthValues[gxCooldownsDB.growth].point, UIParent, "CENTER", x, y)
	end
	
	gxCooldowns.toggleLock = function(callbackLock, callbackXY)
		if (gxCooldowns.locked) then
			anchor:SetBackdropColor(0, 0, 0, 0)
			anchor:EnableMouse(nil)
			anchor:SetMovable(nil)
			
			anchor:SetScript("OnMouseDown", nil)
			anchor:SetScript("OnMouseUp", nil)
		else
			anchor:SetBackdropColor(.6, .6, .6, .6)
			anchor:EnableMouse(true)
			anchor:SetMovable(true)
			
			anchor:SetScript("OnMouseDown", startMoving)
			anchor:HookScript("OnMouseDown", callbackLock)
			anchor:SetScript("OnMouseUp", stopMoving)
			anchor:HookScript("OnMouseUp", callbackXY)
		end
	end
end

do
	local scanCooldowns = function(self)
		local spellID, startTime, duration, enabled, texture
		
		for spellNum = 1, 500 do
			_, spellID = GetSpellBookItemInfo(spellNum, BOOKTYPE_SPELL)
			
			if (not spellID) then
				break
			end
			
			startTime, duration, enabled = GetSpellCooldown(spellID)
			if (enabled == 1 and duration > gxCooldownsDB.minDuration and (duration < gxCooldownsDB.maxDuration or gxCooldownsDB.maxDuration == 3600)) then
				self:newCooldown(spellID, startTime, duration, GetSpellTexture(spellID), "SPELL")
			end
		end
		
		for _, item in next, gxCooldownsDB.items do
			startTime, duration, enabled = GetItemCooldown(item)
			if (enabled == 1 and duration > gxCooldownsDB.minDuration and (duration < gxCooldownsDB.maxDuration or gxCooldownsDB.maxDuration == 3600)) then
				texture = select(10, GetItemInfo(item))
				self:newCooldown(item, startTime, duration, texture, "ITEM")
			elseif (enabled == 0 and duration > gxCooldownsDB.minDuration and (duration < gxCooldownsDB.maxDuration or gxCooldownsDB.maxDuration == 3600)) then
				self.queuedItem = self.updateItem
			end
		end
		
		for _, id in next, spellIDToSlotID do
			startTime, duration, enabled = GetInventoryItemCooldown("player", id)
			if (enabled == 1 and duration > gxCooldownsDB.minDuration and (duration < gxCooldownsDB.maxDuration or gxCooldownsDB.maxDuration == 3600)) then
				texture = GetInventoryItemTexture("player", id)
				self:newCooldown(id, startTime, duration, texture, "INVENTORY")
			end
		end
	end
	
	anchor.PLAYER_LOGIN = function(self)
		gxCooldowns.setupConfiguration()
		
		self:SetHeight(36)
		self:SetWidth(36)
		self:SetScale(gxCooldownsDB.scale)
		self:SetPoint(gxCooldowns.growthValues[gxCooldownsDB.growth].point, UIParent, "CENTER", gxCooldownsDB.xOffset, gxCooldownsDB.yOffset)
		
		LBF = LibStub("LibButtonFacade", true)
		if (LBF) then
			local skinChanged = function(self, skinName, gloss, backdrop, group, _, colors)
				gxCooldownsDB.style[1] = skinName
				gxCooldownsDB.style[2] = gloss
				gxCooldownsDB.style[3] = backdrop
				gxCooldownsDB.style[4] = colors
			end
			
			LBF:RegisterSkinCallback("gxCooldowns", skinChanged, self)
			buttonGroup = LBF:Group("gxCooldowns")
			buttonGroup:Skin(unpack(gxCooldownsDB.style))
		end
		
		local LIC = LibStub("LibInternalCooldowns-1.0", true)
		local talentProc = function(self, _, spellID, startTime, duration)
			self:newCooldown(spellID, startTime, duration, GetSpellTexture(spellID))
		end
		LIC:RegisterCallback("InternalCooldowns_TalentProc", talentProc, self)
		
		local itemProc = function(self, _, itemID, _, startTime, duration)
			local texture = select(10, GetItemInfo(itemID))
			self:newCooldown(itemID, startTime, duration, texture)
		end
		LIC:RegisterCallback("InternalCooldowns_Proc", itemProc, self)
		
		self.playerGUID = UnitGUID("player")
		
		for i = 1, 19 do
			self:PLAYER_EQUIPMENT_CHANGED(i, true)
		end
		
		scanCooldowns(self)
		
		self:UnregisterEvent("PLAYER_LOGIN")
		self.PLAYER_LOGIN = nil
	end
end

anchor.SPELL_UPDATE_COOLDOWN = function(self)
	local startTime, duration, enabled, texture
	if (self.updateNext) then
		startTime, duration, enabled = GetSpellCooldown(self.updateNext)
		if (enabled == 1 and duration > gxCooldownsDB.minDuration and (duration < gxCooldownsDB.maxDuration or gxCooldownsDB.maxDuration == 3600)) then
			texture = GetSpellTexture(self.updateNext)
			self:newCooldown(self.updateNext, startTime, duration, texture, "SPELL")
			self.updateNext = nil
		end
	end
	
	if (self.updateSpecial) then
		startTime, duration, enabled = GetSpellCooldown(self.updateSpecial)
		if (enabled == 1 and duration > gxCooldownsDB.minDuration and (duration < gxCooldownsDB.maxDuration or gxCooldownsDB.maxDuration == 3600)) then
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
	
	local unit, abilityID = split(",", self.updateAbility)
	abilityID = tonumber(abilityID)
	if (FD == abilityID) then
		self.updateNext = abilityID
		return
	end
	
	local type
	if (unit == "player") then
		type = "SPELL"
		texture = GetSpellTexture(abilityID)
		startTime, duration, enabled = GetSpellCooldown(abilityID)
	else
		local abilityName = GetSpellInfo(abilityID)
		local petAction
		for i = 1, NUM_PET_ACTION_SLOTS do
			petAction = GetPetActionInfo(i)
			if (abilityName == petAction) then
				abilityID = i
				type = "PET"
				texture = select(3, GetPetActionInfo(i))
				startTime, duration, enabled = GetPetActionCooldown(i)
				
				break
			end
		end
	end
	
	if (enabled == 1 and duration > gxCooldownsDB.minDuration and (duration < gxCooldownsDB.maxDuration or gxCooldownsDB.maxDuration == 3600)) then
		self:newCooldown(abilityID, startTime, duration, texture, type)
	elseif (enabled == 1 and self.lockdownTime) then
		self.updateNext = abilityID
	end
	
	self.updateAbility = nil
end

anchor.BAG_UPDATE_COOLDOWN = function(self)
	local startTime, duration, enabled, texture
	
	if (self.queuedItem) then	-- For items with a cooldown that doesn't start before leaving combat!
		startTime, duration, enabled = GetItemCooldown(self.queuedItem)
		if (enabled == 1 and duration > gxCooldownsDB.minDuration and (duration < gxCooldownsDB.maxDuration or gxCooldownsDB.maxDuration == 3600)) then
			texture = select(10, GetItemInfo(self.queuedItem))
			self:newCooldown(self.queuedItem, startTime, duration, texture, "ITEM")
			
			self.queuedItem = nil
		end
	end
	
	if (self.updateItem) then
		startTime, duration, enabled = GetItemCooldown(self.updateItem)
		if (enabled == 1 and duration > gxCooldownsDB.minDuration and (duration < gxCooldownsDB.maxDuration or gxCooldownsDB.maxDuration == 3600)) then
			texture = select(10, GetItemInfo(self.updateItem))
			self:newCooldown(self.updateItem, startTime, duration, texture, "ITEM")
			self.updateItem = nil
		elseif (enabled == 0 and duration > gxCooldownsDB.minDuration and (duration < gxCooldownsDB.maxDuration or gxCooldownsDB.maxDuration == 3600)) then
			self.queuedItem = self.updateItem
			self.updateItem = nil
		end
	end
	
	if (self.updateSlotID) then
		startTime, duration, enabled = GetInventoryItemCooldown("player", self.updateSlotID)
		if (enabled == 1 and duration > gxCooldownsDB.minDuration and (duration < gxCooldownsDB.maxDuration or gxCooldownsDB.maxDuration == 3600)) then
			texture = GetInventoryItemTexture("player", self.updateSlotID)
			self:newCooldown(self.updateSlotID, startTime, duration, texture, "INVENTORY")
			
			self.updateSlotID = nil
		end
	end
end

local scanner = CreateFrame("GameTooltip", "gxCooldownsScanner", UIParent, "GameTooltipTemplate")
scanner:SetOwner(UIParent, "ANCHOR_NONE")
anchor.PLAYER_EQUIPMENT_CHANGED = function(self, slotID, beingEquipped)
	if (not beingEquipped) then
		for spellID, id in next, spellIDToSlotID do
			if (id and id == slotID) then
				spellIDToSlotID[spellID] = nil
				
				break
			end
		end
		
		return
	end
	
	scanner:SetInventoryItem("player", slotID)
	local numLines = scanner:NumLines()
	local line
	for i = 1, numLines do
		line = _G["gxCooldownsScannerTextLeft" .. i]
		spellID = enchantTextToSpellID[line:GetText()]
		if (spellID) then
			spellIDToSlotID[spellID] = slotID
			break
		end
	end
end

anchor.UNIT_SPELLCAST_SUCCEEDED = function(self, unit, spellName, _, _, spellID)
	if ((unit ~= "player" and unit ~= "pet") or gxCooldownsDB.blacklist[spellID]) then
		return
	end
	
	local item = gxCooldownsDB.items[spellName]
	if (item) then
		self.updateItem = item
		
		return
	end
	
	local slotID = spellIDToSlotID[spellID]
	if (slotID) then
		self.updateSlotID = slotID
		
		return
	end
	
	if (sharedCooldowns[spellID]) then -- This should be druids only
		self.updateShared = sharedCooldowns[spellID]
	end
	
	self.updateAbility = unit..","..spellID
end

anchor.SPELL_UPDATE_USABLE = function(self)
	for name, frame in next, self.active do
		local startTime, duration
		if (frame.type == "SPELL") then
			startTime, duration = GetSpellCooldown(name)
		elseif (frame.type == "ITEM") then
			startTime, duration = GetItemCooldown(name)
		elseif (frame.type == "INVENTORY") then
			startTime, duration = GetInventoryItemCooldown("player", name)
		elseif (frame.type == "PET") then
			startTime, duration = GetPetActionCooldown(name)
		end
		
		if (frame.type) then
			if (not startTime and not duration) then -- Calling Get'Something'Cooldown right after talent swap returns a nil value
				self:dropCooldown(name)
				return
			end
			
			if (duration <= 1) then -- For abilities like Readiness, duration will be lowered to 1 or 0
				self:dropCooldown(name)
				return
			end
			
			if (frame.start > startTime or frame.duration > duration) then
				frame.start = startTime
				frame.duration = duration - (GetTime() - startTime)
				frame.max = duration
				
				frame.Cooldown:SetCooldown(startTime, duration)
			end
		end
	end
end

local lockdownTime = {
	[GetSpellInfo(34490)] = 3,	-- Silencing Shot
	[GetSpellInfo(80964)] = 5,	-- Skull Bash
	[GetSpellInfo(47528)] = 4,	-- Mind Freeze
	[GetSpellInfo(6552)] = 4,	-- Pummel
	[GetSpellInfo(72)] = 6,		-- Shield Bash
}
anchor.COMBAT_LOG_EVENT_UNFILTERED = function(self, _, event, sourceGUID, _, _, destGUID, _, _, ...)
	local spellID, spellName, _, iSpellID, _, spellSchoolID = ...
	if (event == "SPELL_AURA_REMOVED" and sourceGUID == self.playerGUID and specialOccasions[spellID] and not gxCooldownsDB.blacklist[spellID]) then
		self.updateSpecial = spellID
	elseif (event == "SPELL_INTERRUPT" and destGUID == self.playerGUID) then
		self.spellSchoolID = spellSchoolID
		self.lockdownTime = lockdownTime[spellName] or 8
		self.updateAbility = "player,"..iSpellID
	end
end

do	-- Stealth and Prowl apparently trigger SPELL_UPDATE_COOLDOWN before the aura is removed sometimes :(
	local class = select(2, UnitClass("player"))
	if (class == "ROGUE" or class == "DRUID") then
		local stealth = class == "ROGUE" and 1784 or 5215
		anchor:RegisterEvent("UPDATE_STEALTH")
		anchor.UPDATE_STEALTH = function(self)
			local startTime, duration, enabled = GetSpellCooldown(stealth)
			if (enabled == 1 and duration > gxCooldownsDB.minDuration and (duration < gxCooldownsDB.maxDuration or gxCooldownsDB.maxDuration == 3600)) then
				local texture = GetSpellTexture(stealth)
				self:newCooldown(stealth, startTime, duration, texture, "SPELL")
			end
		end
	end
end

anchor.PLAYER_REGEN_ENABLED = function()
	if (gxCooldownsDB.EnableOOCAlpha) then
		anchor:SetAlpha(gxCooldownsDB.OOCAlpha)
	end
end

anchor.PLAYER_REGEN_DISABLED = function()
	if (gxCooldownsDB.EnableOOCAlpha) then
		anchor:SetAlpha(1)
	end
end

anchor:SetScript("OnEvent", function(self, event, ...)
	if (self[event]) then
		self[event](self, ...)
	end
end)