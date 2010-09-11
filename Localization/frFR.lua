if (GetLocale() ~= "frFR") then
	return
end

local _, settings = ...

local L = {}
L["%s school is locked for %d seconds!"] = "%s school is locked for %d seconds!"
L["Physical"] = "Physical"
L["Holy"] = "Holy"
L["Fire"] = "Feu"
L["Nature"] = "Nature"
L["Frost"] = "Frost"
L["Frostfire"] = "Frostfire"
L["Shadow"] = "Shadow"
L["Arcane"] = "Arcane"

settings.L = L