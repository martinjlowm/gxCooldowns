local lib, oldminor = LibStub:GetLibrary("LibInternalCooldowns-1.0")

-- Format is spellID = itemID | {itemID, itemID, ... itemID}
local spellToItem = {
	[64411] = 46017,					-- Val'anyr, Hammer of Ancient Kings
	
	[60065] = {44914, 40684, 49074},	-- Anvil of the Titans, Mirror of Truth, Coren's Chromium Coaster
	[60488] = 40373,					-- Extract of Necromatic Power
	[64713] = 45518,					-- Flare of the Heavens
	[60064] = {44912, 40682, 49706},	-- Flow of Knowledge, Sundial of the Exiled, Mithril Pocketwatch

	[67703]	= {47303, 47115},			-- Death's Choice, Death's Verdict (AGI)
	[67708]	= {47303, 47115},			-- Death's Choice, Death's Verdict (STR)
	[67772] = {47464, 47131},			-- Death's Choice, Death's Verdict (Heroic) (AGI)
	[67773] = {47464, 47131},			-- Death's Choice, Death's Verdict (Heroic) (STR)

	-- ICC epix
	-- Rep rings
	[72416] = {50398, 50397},
	[72412] = {50402, 50401},
	[72418] = {50399, 50400},
	[72414] = {50404, 50403},

	-- Deathbringer's Will (Non-heroic)	
	[71485] = 50362,
	[71492] = 50362,
	[71486] = 50362,
	[71484] = 50362,
	[71491] = 50362,
	[71487] = 50362,

	-- Deathbringer's Will (Heroic)
	[71556] = 50363,
	[71560] = 50363,
	[71558] = 50363,
	[71561] = 50363,
	[71559] = 50363,
	[71557] = 50363,	
	
	[71403] = 50198,			-- Needle-Encrusted Scorpion
	[71610] = 50359,			-- Althor's Abacus
	[71633] = 50352,			-- Corpse-tongue coin
	[71601] = 50353,			-- Dislodged Foreign Object
	[71584] = 50358,			-- Purified Lunar Dust
	[71401] = 50342,			-- Whispering Fanged Skull
	
	-- Heroic ICC trinkets
	[71541] = 50343,			-- Whispering Fanged Skull
	[71641] = 50366,			-- Althor's Abacus
	[71639] = 50349,			-- Corpse-tongue coin
	[71644] = 50348,			-- Dislodged Foreign Object
	
	-- DK T9 2pc. WTF.
	[67117] = {48501, 48502, 48503, 48504, 48505, 48472, 48474, 48476, 48478, 48480, 48491, 48492, 48493, 48494, 48495, 48496, 48497, 48498, 48499, 48500, 48486, 48487, 48488, 48489, 48490, 48481, 48482, 48483, 48484, 48485},
	
	-- WotLK Epix
	[67671] = 47214,			-- Banner of Victory
	[67669] = 47213, 			-- Abyssal Rune 
	[64772] = 45609, 			-- Comet's Trail
	[65024] = 46038, 			-- Dark Matter
	[60443] = 40371,			-- Bandit's Insignia
	[64790] = 45522,			-- Blood of the Old God
	[60203] = 42990,			-- Darkmoon Card: Death
	[60494] = 40255,			-- Dying Curse
	[65004] = 65005,			-- Elemental Focus Stone
	[60492] = 39229,			-- Embrace of the Spider
	[60530] = 40258,			-- Forethought Talisman
	[60437] = 40256,			-- Grim Toll
	[49623] = 37835, 			-- Je'Tze's Bell
	[65019] = 45931, 			-- Mjolnir Runestone
	[64741] = 45490,			-- Pandora's Plea
	[65014] = 45286,			-- Pyrite Infuser
	[65003] = 45929, 			-- Sif's Remembrance
	[60538] = 40382,			-- Soul of the Dead
	[58904] = 43573,			-- Tears of Bitter Anguish
	[60062] = {40685, 49078},	-- The Egg of Mortal Essence, Ancient Pickled Egg
	[64765] = 45507, 			-- The General's Heart
	
	-- WotLK Blues
	[51353]	= 38358,			-- Arcane Revitalizer
	[60218] = 37220,			-- Essence of Gossamer
	[60479] = 37660,			-- Forge Ember
	[51348] = 38359,			-- Goblin Repetition Reducer
	[63250] = 45131,			-- Jouster's Fury
	[63250] = 45219,			-- Jouster's Fury
	[60302] = 37390,			-- Meteorite Whetstone
	[54808] = 40865, 			-- Noise Machine
	[60483] = 37264, 			-- Pendulum of Telluric Currents
	[52424] = 38675, 			-- Signet of the Dark Brotherhood
	[55018] = 40767,			-- Sonic Booster
	[52419] = 38674,			-- Soul Harvester's Charm
	-- [18350] = 37111,			-- Soul Preserver, no internal cooldown
	[60520] = 37657,			-- Spark of Life
	[60307] = 37064,			-- Vestige of Haldor
	
	-- Greatness cards
	[60233] = {44253, 44254, 44255, 42987},		-- Greatness, AGI
	[60235] = {44253, 44254, 44255, 42987},		-- Greatness, SPI
	[60229] = {44253, 44254, 44255, 42987},		-- Greatness, INT
	[60234] = {44253, 44254, 44255, 42987},		-- Greatness, STR
	
	-- Burning Crusade trinkets
	-- None yet.
	
	-- Vanilla Epix
	[23684] = 19288,			-- Darkmoon Card: Blue Dragon
}

-- spell ID = {enchant ID, slot1[, slot2]}
local enchants = {
	-- [59620] = {3789, 16, 17},		-- Berserking, no ICD via testing.
	-- [28093] = {2673, 16, 17},		-- Mongoose
	-- [13907] = {912, 16, 17},			-- Demonslaying
	[55637] = {3722, 15},			-- Lightweave
	[55775] = {3730, 15},			-- Swordguard
	[55767] = {3728, 15},			-- Darkglow
	[59626] = {3790, 16}, 			-- Black Magic ?
	[59625] = {3790, 16}, 			-- Black Magic ? 	
}


-- ICDs on metas assumed to be 45 sec. Needs testing.
local metas = {	
	-- I've commented these two out, because there aren't really any tactical decisions you could make based on them
	-- [55382] = 41401,				-- Insightful Earthsiege Diamond			
	-- [32848] = 25901,				-- Insightful Earthstorm Diamond
	
	[23454] = 25899,				-- Brutal Earthstorm Diamond
	[55341] = 41385, 				-- Invigorating Earthsiege Diamond
	[18803] = 25893,				-- Mystical Skyfire Diamond
	[32845]	= 25898,				-- Tenacious Earthstorm Diamond
	[39959] = 32410,				-- Thundering Skyfire Diamond
	[55379] = 41400					-- Thundering Skyflare Diamond
}

-- Spell ID => cooldown, in seconds
-- If an item isn't in here, 45 sec is assumed.
local cooldowns = {
	-- ICC rep rings
	[72416] = 60,
	[72412] = 60,
	[72418] = 60,
	[72414] = 60,

	[60488] = 15,
	[51348] = 10,
	[51353] = 10,
	[54808] = 60,
	[55018] = 60,
	[52419] = 30,
	[59620] = 90,
	
	[55382] = 15,
	[32848] = 15,
	[55341] = 90,		-- Invigorating Earthsiege, based on WowHead comments (lol?)
	
	[48517] = 30,
	[48518] = 30,
	
	[47755] = 12,
	
	-- Deathbringer's Will, XI from #elitistjerks says it's 105 sec so if it's wrong yell at him.
	[71485] = 105,
	[71492] = 105,
	[71486] = 105,
	[71484] = 105,
	[71491] = 105,
	[71487] = 105,

	-- Deathbringer's Will (Heroic)
	[71556] = 105,
	[71560] = 105,
	[71558] = 105,
	[71561] = 105,
	[71559] = 105,
	[71557] = 105,
	
	-- Black Magic
	[59626] = 35,
	[59625] = 35, 	
}


-- Procced spell effect ID = unique name
-- The name doesn't matter, as long as it's non-numeric and unique to the ICD.
local talents = {
	-- Druid
	[48517] = "Eclipse",
	[48518] = "Eclipse",
	
	-- Hunter
	[56453] = "Lock and Load",
	
	-- Death Knight
	[52286] = "Will of the Necropolis",
	
	-- Priest
	[47755] = "Rapture"
}
-----------------------------------------------------------------------
-- Don't edit past this line									--
-----------------------------------------------------------------------

------------------------------------
-- Upgrade this data into the lib
------------------------------------

lib.spellToItem = lib.spellToItem or {}
lib.cooldowns = lib.cooldowns or {}
lib.enchants = lib.enchants or {}
lib.metas = lib.metas or {}
lib.talents = lib.talents or {}

local tt, tts = {}, {}
local function merge(t1, t2)
	wipe(tts)
	for _, v in ipairs(t1) do
		tts[v] = true
	end
	for _, v in ipairs(t2) do
		if not tts[v] then
			tinsert(t1, v)
		end
	end
end

for k, v in pairs(spellToItem) do
	local e = lib.spellToItem[k]
	if e and e ~= v then
		if type(e) == "table" then
			if type(v) ~= "table" then
				wipe(tt)
				tinsert(tt, v)
			end
			merge(e, tt)
		else
			lib.spellToItem[k] = {e, v}
		end
	else
		lib.spellToItem[k] = v
	end
end

for k, v in pairs(cooldowns) do
	lib.cooldowns[k] = v
end

for k, v in pairs(enchants) do
	lib.enchants[k] = v
end

for k, v in pairs(metas) do
	lib.metas[k] = v
end

for k, v in pairs(talents) do
	lib.talents[k] = v
end
