local MAJOR = "LibInternalCooldowns-1.0"
local MINOR = tonumber(("$Revision: 15 $"):match("%d+"))

local lib, oldminor = LibStub:NewLibrary(MAJOR, MINOR)
if not lib then return end -- No Upgrade needed.

local CallbackHandler = LibStub:GetLibrary("CallbackHandler-1.0")

local GetInventoryItemLink = _G.GetInventoryItemLink
local GetInventoryItemTexture = _G.GetInventoryItemTexture
local GetMacroInfo = _G.GetMacroInfo
local GetActionInfo = _G.GetActionInfo
local substr = _G.string.sub
local wipe = _G.wipe
local playerGUID = UnitGUID("player")
local GetTime = _G.GetTime

lib.spellToItem = lib.spellToItem or {}
lib.cooldownStartTimes = lib.cooldownStartTimes or {}
lib.cooldownDurations = lib.cooldownDurations or {}
lib.callbacks = lib.callbacks or CallbackHandler:New(lib)
lib.cooldowns = lib.cooldowns or nil
lib.hooks = lib.hooks or {}

local enchantProcTimes = {}

if not lib.eventFrame then
	lib.eventFrame = CreateFrame("Frame")
	lib.eventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	lib.eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
	lib.eventFrame:SetScript("OnEvent", function(frame, event, ...)
		frame.lib[event](frame.lib, event, ...)
	end)
end
lib.eventFrame.lib = lib

local INVALID_EVENTS = {
	SPELL_DISPEL 			= true,
	SPELL_DISPEL_FAILED 	= true,
	SPELL_STOLEN 			= true,
	SPELL_AURA_REMOVED 		= true,
	SPELL_AURA_REMOVED_DOSE = true,
	SPELL_AURA_BROKEN 		= true,
	SPELL_AURA_BROKEN_SPELL = true,
	SPELL_CAST_FAILED 		= true
}

local slots = {
	AMMOSLOT = 0,
	INVTYPE_HEAD = 1,
	INVTYPE_NECK = 2,
	INVTYPE_SHOULDER = 3,
	INVTYPE_BODY = 4,
	INVTYPE_CHEST = 5,
	INVTYPE_WAIST = 6,
	INVTYPE_LEGS = 7,
	INVTYPE_FEET = 8,
	INVTYPE_WRIST = 9,
	INVTYPE_HAND = 10,
	INVTYPE_FINGER = {11, 12},
	INVTYPE_TRINKET = {13, 14},
	INVTYPE_CLOAK = 15,
	INVTYPE_WEAPONMAINHAND = 16,
	INVTYPE_2HWEAPON = 16,
	INVTYPE_WEAPON = {16, 17},
	INVTYPE_HOLDABLE = 17,
	INVTYPE_SHIELD = 17,
	INVTYPE_WEAPONOFFHAND = 17,
	INVTYPE_RANGED = 18
}

function lib:PLAYER_ENTERING_WORLD()
	playerGUID = UnitGUID("player")	
	self:Hook("GetInventoryItemCooldown")
	self:Hook("GetActionCooldown")
	self:Hook("GetItemCooldown")
end

function lib:Hook(name)
	-- unhook if a hook existed from an older copy
	if lib.hooks[name] then
		_G[name] = lib.hooks[name]
	end
	
	-- Re-hook it now
	lib.hooks[name] = _G[name]
	_G[name] = function(...)
		return self[name](self, ...)
	end
end

local function checkSlotForEnchantID(slot, enchantID)
	local link = GetInventoryItemLink("player", slot)
	if not link then return false; end
	local itemID, enchant = link:match("item:(%d+):(%d+)")
	if tonumber(enchant or -1) == enchantID then
		return true, tonumber(itemID)
	else
		return false
	end
end

local function isEquipped(itemID)
	local _, _, _, _, _, _, _, _, equipLoc = GetItemInfo(itemID)
	local slot = slots[equipLoc]
	
	if type(slot) == "table" then
		for _, v in ipairs(slot) do
			local link = GetInventoryItemLink("player", v)
			if link and link:match(("item:%s"):format(itemID)) then
				return true
			end
		end
	else
		local link = GetInventoryItemLink("player", slot)
		if link and link:match(("item:%s"):format(itemID)) then
			return true
		end
	end
	return false
end

function lib:COMBAT_LOG_EVENT_UNFILTERED(frame, timestamp, event, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellID, spellName)
	playerGUID = playerGUID or UnitGUID("player")
	if ((destGUID == playerGUID and (sourceGUID == nil or sourceGUID == destGUID)) or sourceGUID == playerGUID) and not INVALID_EVENTS[event] and substr(event, 0, 6) == "SPELL_" then
		local itemID = lib.spellToItem[spellID]
		if itemID then
			if type(itemID) == "table" then
				for k, v in ipairs(itemID) do
					if isEquipped(v) then
						self:SetCooldownFor(v, spellID, "ITEM")
					end
				end
				return
			else
				if isEquipped(itemID) then
					self:SetCooldownFor(itemID, spellID, "ITEM")
				end
				return
			end
		end
		
		-- Tests for enchant procs 
		local enchantID = lib.enchants[spellID]
		if enchantID then
			local enchantID, slot1, slot2 = unpack(enchantID)
			local enchantPresent, itemID, first, second
			enchantPresent, itemID = checkSlotForEnchantID(slot1, enchantID)
			if enchantPresent then
				first = itemID
				if (enchantProcTimes[slot1] or 0) < GetTime() - (lib.cooldowns[spellID] or 45) then
					enchantProcTimes[slot1] = GetTime()
					self:SetCooldownFor(itemID, spellID, "ENCHANT")
					return
				end
			end

			enchantPresent, itemID = checkSlotForEnchantID(slot2, enchantID)
			if enchantPresent then
				second = itemID
				if (enchantProcTimes[slot2] or 0) < GetTime() - (lib.cooldowns[spellID] or 45) then
					enchantProcTimes[slot2] = GetTime()
					self:SetCooldownFor(itemID, spellID, "ENCHANT")
					return
				end
			end
			
			if first and second then
				if enchantProcTimes[slot1] < enchantProcTimes[slot2] then
					self:SetCooldownFor(first, spellID, "ENCHANT")
				else
					self:SetCooldownFor(second, spellID, "ENCHANT")
				end
			end
		end
		
		local metaID = lib.metas[spellID]
		if metaID then
			local link = GetInventoryItemLink("player", 1)
			if link then
				local id = tonumber(link:match("item:(%d+)") or 0)
				if id and id ~= 0 then
					self:SetCooldownFor(id, spellID, "META")
				end
			end
			return
		end
		
		local talentID = lib.talents[spellID]
		if talentID then
			self:SetCooldownFor(("%s: %s"):format(UnitClass("player"), talentID), spellID, "TALENT")
			return
		end
	end
end

function lib:SetCooldownFor(itemID, spellID, procSource)
	local duration = lib.cooldowns[spellID] or 45
	lib.cooldownStartTimes[itemID] = GetTime()
	lib.cooldownDurations[itemID] = duration
	
	-- Talents have a separate callback, so that InternalCooldowns_Proc always has an item ID.
	if procSource == "TALENT" then
		lib.callbacks:Fire("InternalCooldowns_TalentProc", spellID, GetTime(), duration, procSource)
	else
		lib.callbacks:Fire("InternalCooldowns_Proc", itemID, spellID, GetTime(), duration, procSource)
	end
end

local function cooldownReturn(id)
	if not id then return end
	local hasItem = id and lib.cooldownStartTimes[id] and lib.cooldownDurations[id]
	if hasItem then
		if lib.cooldownStartTimes[id] + lib.cooldownDurations[id] > GetTime() then
			return lib.cooldownStartTimes[id], lib.cooldownDurations[id], 1
		else
			return 0, 0, 0
		end
	else
		return nil
	end
end

function lib:IsInternalItemCooldown(itemID)
	return cooldownReturn(itemID) ~= nil
end

function lib:GetInventoryItemCooldown(unit, slot)
	local start, duration, enable = self.hooks.GetInventoryItemCooldown(unit, slot)
	if not enable or enable == 0 then
		local link = GetInventoryItemLink("player", slot)
		if link then
			local itemID = link:match("item:(%d+)")
			itemID = tonumber(itemID or 0)
			
			local start, duration, running = cooldownReturn(itemID)
			if start then return start, duration, running end
		end
	end
	return start, duration, enable
end

function lib:GetActionCooldown(slotID)
	local t, id, subtype, globalID = GetActionInfo(slotID)
	if t == "item" then
		local start, duration, running = cooldownReturn(id)
		if start then return start, duration, running end
	elseif t == "macro" then
		local _, tex = GetMacroInfo(id)
		if tex == GetInventoryItemTexture("player", 13) then
			id = tonumber(GetInventoryItemLink("player", 13):match("item:(%d+)"))
			local start, duration, running = cooldownReturn(id)
			if start then return start, duration, running end
		elseif tex == GetInventoryItemTexture("player", 14) then
			id = tonumber(GetInventoryItemLink("player", 14):match("item:(%d+)"))
			local start, duration, running = cooldownReturn(id)
			if start then return start, duration, running end
		end
	end
	return self.hooks.GetActionCooldown(slotID)
end

function lib:GetItemCooldown(param)
	local id
	local iparam = tonumber(param)
	if iparam and iparam > 0 then
		id = param
	elseif type(param) == "string" then
		local name, link = GetItemInfo(param)
		if link then
			id = link:match("item:(%d+)")
		end
	end
	
	if id then
		id = tonumber(id)
		local start, duration, running = cooldownReturn(id)
		if start then return start, duration, running end
	end
	
	return self.hooks.GetItemCooldown(param)
end
