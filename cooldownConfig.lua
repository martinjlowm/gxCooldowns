local _, settings = ...

settings.blacklist = {
	--["Astral Recall"] = true,
}
-- Set the minimum or maximum duration of the tracked cooldowns.
settings.minDuration = 1.5
settings.maxDuration = nil	-- nil clears the limit, only works for maxDuration.

-- The spell is what triggers the cooldown, so if you add items that has the same spell effect
-- it will choose yours if you added it above the one listed.
settings.items = { 
	[42122] = true,	-- Medallion of the Horde	'PvP Trinket'
	[33448] = true,	-- Runic Mana Potion		'Restore Mana'
	[33447] = true,	-- Runic Healing Potion		'Healing Potion'
	[40093] = true,	-- Indestructible Potion	'Indestructible'
	[40211] = true,	-- Potion of Speed			'Speed'
	[40212] = true,	-- Potion of Wild Magic		'Wild Magic'
	[22044] = true	-- Mana Emerald				'Replenish Mana'
}

settings.frameSize = 34
settings.gap = 6
settings.growHorizontal = true

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