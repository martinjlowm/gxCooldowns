local _, settings = ...

settings.blacklist = {
	--["Astral Recall"] = true,
}

settings.items = {
	[42126] = true, -- Medallion of the Horde
	[33448] = true, -- Runic Mana Potion
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