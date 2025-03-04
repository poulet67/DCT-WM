--[[
-- SPDX-License-Identifier: LGPL-3.0
--
-- Name lists for various asset types
--]]

local enum = require("dct.enum")

local samsite = {
	"ALFA",
	"BENTLEY",
	"BUICK",
	"CADDY",
	"CHEVY",
	"DODGE",
	"FORD",
	"JAGUAR",
	"JEEP",
	--"KIA",
	"LEXUS",
	"LOLA",
	"LOTUS",
	"MAZDA",
	"NISSAN",
	"NOBLE",
	"OPEL",
	"PONTIAC",
	"PORSCHE",
	"SAAB",
	"SEAT",
	"SUBARU",
	"TESLA",
	"TRIUMPH",
}

local port = {
	"CHAPMAN",
	"CHARVEL",
	"CORT",
	"ERNIE",
	"FENDER",
	"GIBSON",
	"GODIN",
	"GRETSCH",
	"GUILD",
	"IBANEZ",
	"JACKSON",
	"KIESEL",
	"KRAMER",
	"MARTIN",
	"SCHECTER",
	"SQUIER",
	"STRANDBERG",
	"SUHR",
	"TAYLOR",
	"VOX",
	"WASHBURN",
	"YAMAHA",
}

local oca = {
	"AIRBUS",
	"AVRO",
	"BELL",
	"BOEING",
	"CURTISS",
	"DOUGLAS",
	"FOKKER",
	"GRUMMAN",
	"HAWKER",
	"JUNKER",
	"LOCKHEED",
	"PIPER",
	"ROLLS",
	"SAFRAN",
	"SUKHOI",
	"VICKERS",
	"VOUGHT",
}

local missilesite = {
	"AVON",
	"BRIDGESTONE",
	"DUNLOP",
	"FIRESTONE",
	"GOODYEAR",
	"HANKOOK",
	"KUMHO",
	"MICHELIN",
	"PIRELLI",
	"STARCO",
	"TOYO",
	"YOKOHAMA",
}

local bunker = {
	"ARGON",
	"BRASS",
	"BRONZE",
	"CARBON",
	"CHROME",
	"COBALT",
	"COPPER",
	"GOLD",
	"IRON",
	"KRYPTON",
	"LEAD",
	"NEON",
	"NICKEL",
	"PEWTER",
	"RADON",
	"SILVER",
	"STEEL",
	"TUNGSTEN",
	"XENON",
	"ZINC",
}

local c2 = {
	"BARON",
	"BISHOP",
	"CAESAR",
	"CALIPH",
	"DESPOT",
	"DON",
	"DUKE",
	"EARL",
	"KHAN",
	"KING",
	"MAGNATE",
	"MOGUL",
	"MONARCH",
	"PRINCE",
	"REX",
	"SULTAN",
	"TYCOON",
}

local default = {
	"ATHENS",
	"BEIJING",
	"BERLIN",
	"BOSTON",
	"CAIRO",
	"DALLAS",
	"DELHI",
	"DETROIT",
	"HAMBURG",
	"HANOI",
	"HOUSTON",
	"LAGOS",
	"LISBON",
	"LONDON",
	"MADRID",
	"MELBOURNE",
	"MEMPHIS",
	"MESA",
	"MILAN",
	"MOSCOW",
	"MUMBAI",
	"MUNICH",
	"PARIS",
	"PHOENIX",
	"PRAGUE",
	"RIO",
	"ROME",
	"SEOUL",
	"SHANGHAI",
	"SYDNEY",
	"TAMPA",
	"TOKYO",
	"TULSA",
	"VIENNA",
	"WARSAW",
}




local codenamedb = {
	[enum.assetType.SAM]     = samsite,
	[enum.assetType.PORT]    = port,
	[enum.assetType.OCA]     = oca,
	[enum.assetType.MISSILE] = missilesite,
	[enum.assetType.BUNKER]  = bunker,
	[enum.assetType.C2]      = c2,
	["default"]              = default,
}

return codenamedb
