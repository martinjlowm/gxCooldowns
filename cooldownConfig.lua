local _, settings = ...

settings.blacklist = {
	--["Astral Recall"] = true,
}
-- Set the minimum or maximum duration of the tracked cooldowns.
settings.minDuration = 1.5
settings.maxDuration = nil	-- nil clears the limit, only works for maxDuration.

-- New method since 1.5. The table key is now the name of the item spell and they value is the item ID.
-- To find the item spell, look up the item on WoWHead and click on the use effect.
settings.itemSpells = { 
	[GetSpellInfo(42292)] = 42122,	-- 'PvP Trinket'			Medallion of the Horde
	[GetSpellInfo(43186)] = 33448,	-- 'Restore Mana'			Runic Mana Potion
	[GetSpellInfo(43185)] = 33447,	-- 'Healing Potion'			Runic Healing Potion
	[GetSpellInfo(53762)] = 40093,	-- 'Indestructible'			Indestructible Potion
	[GetSpellInfo(53908)] = 40211,	-- 'Speed'					Potion of Speed
	[GetSpellInfo(53909)] = 40212,	-- 'Wild Magic'				Potion of Wild Magic
	[GetSpellInfo(42987)] = 33312,	-- 'Replenish Mana'			Mana Sapphire
	[GetSpellInfo(75495)] = 54589	-- 'Eyes of Twilight'		Glowing Twilight Scale
}

settings.frameSize = 36
settings.gap = 8
settings.growHorizontal = true

-- Point:
-- Horizontal,
-- RIGHT makes the icons grow LEFT, LEFT makes the icons grow RIGHT while CENTER makes the icons grow evenly LEFT and RIGHT.
--
-- Vertical,
-- BOTTOM makes the icons grow UP, TOP makes the icons grow DOWN while CENTER makes the icons grow evenly UP and DOWN.
settings.point = "CENTER"
settings.relFrame = "UIParent"
settings.relPoint = "CENTER"
settings.xOffset = 0
settings.yOffset = -150


-- Enable / Disable school lockout output
settings.enableOutput = true

-- Possible methods: Standard, MSBT, SCT, UIErrorsFrame. If none is specified chat will be used. Not case sensitive.
settings.outputMethod = "Standard"

-- Time for the standard method to stay shown. In seconds.
settings.outputTime = 3