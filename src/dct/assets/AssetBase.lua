 --[[
-- SPDX-License-Identifier: LGPL-3.0
--
-- Provides the base class for Assets.
-- An Asset is a group of virtual or real objects in the game world
-- that can be interacted with.
--
Class Hierarchy:

							                       AssetBase----Airspace-----Waypoint
								                       |
		    +------------------------------------------+------------------------------------------------+
		    |										   |												|
		   Base								Static-----IAgent-----Player							  Mobile
 		    |																				  			|
FOB----- Airbase-----FARP														   				   Dispatchable
			|																																
		  Naval (to do)
		  
--]]								
--]]

require("math")
local namedclass = require("libs.namedclass")
local utils    = require("libs.utils")
local dctenum  = require("dct.enum")
local dctutils = require("dct.utils")
local Goal     = require("dct.Goal")
local Marshallable = require("dct.libs.Marshallable")
local Observable   = require("dct.libs.Observable")
local Logger   = require("dct.libs.Logger")
local settings = _G.dct.settings

local norenametype = { --NOTE: THESE ARE UNITS THAT ARE __NOT__ RENAMED
	[dctenum.assetType.PLAYERGROUP]    = true,
	[dctenum.assetType.AIRBASE]        = true,
	[dctenum.assetType.DISPATCHABLE]        = true,
}

local function generateCodename(template)
	if template.codename ~= "default codename" then
		return template.codename
	end

	local codenamedb = settings.codenamedb
	local typetbl = codenamedb[template.objtype]

	if typetbl == nil then
		typetbl = codenamedb.default
	end

	local idx = math.random(1, #typetbl)
	return typetbl[idx]
end


local function genLocationMethod()

--	
	local keytable = {}
	
    for key, value in pairs(dctenum.locationMethod) do
	--	debugLogger:debug("key 1"..key)
        keytable[#keytable+1] = key		
	--	debugLogger:debug("key 1"..keytable[#keytable])
    end
	
    randkey = keytable[math.random(1, #keytable)]
--	debugLogger:debug("index"..randkey )
--	debugLogger:debug("location method found: "..dctenum.locationMethod[randkey] )
    return dctenum.locationMethod[randkey]

end

local AssetLogger = namedclass("AssetLogger", Logger)
function AssetLogger:__init(name, cls)
	Logger.__init(self, name)
	self.cls = cls
end

function AssetLogger:error(msg)
	local l = string.format("%s(%s) - ", self.cls.__clsname, self.cls.name)
	Logger.error(self, l..msg)
end

function AssetLogger:warn(msg)
	local l = string.format("%s(%s) - ", self.cls.__clsname, self.cls.name)
	Logger.warn(self, l..msg)
end

function AssetLogger:info(msg)
	local l = string.format("%s(%s) - ", self.cls.__clsname, self.cls.name)
	Logger.info(self, l..msg)
end

function AssetLogger:debug(msg)
	local l = string.format("%s(%s) - ", self.cls.__clsname, self.cls.name)
	Logger.debug(self, l..msg)
end

--[[
AssetBase:
	attributes(public, read-only):
	- type - [number] asset type
	- briefing - [string] briefing text used when displaying the briefing
	             to players
	- owner - [number] the coalition the asset belongs to
	- rgnname - [string] the region name the asset is in
	- tplname - [string] the template name the asset was created from
	- name - [string] name of the asset
	- codename - [string] single word code name of the asset, used in
	             briefings to players
--]]

local AssetBase = namedclass("AssetBase", Marshallable, Observable)
function AssetBase:__init(template)
	if not self._eventhandlers then
		self._eventhandlers = {}
	end
	self._logger = AssetLogger("Asset", self)
	Marshallable.__init(self)
	Observable.__init(self)
	self:_addMarshalNames({
		"_spawned",
		"_dead",
		"_intel",
		"_priority",
		"type",
		"briefing",
		"owner",
		"rgnname",
		"tplname",
		"name",
		"codename",
		"cost",
		"ignore",
		"regenerate",
	})
	self._spawned    = false
	self._dead       = false
	self._targeted   = {}
	self._intel      = {}
	self._priority   = {}
	for _, side in pairs(coalition.side) do
		self._targeted[side] = false
		self._intel[side]    = 0
		self._priority[side] = {
			["region"] = 0,
			["asset"]  = 0,
		}
	end
	self._initcomplete = false
	if template ~= nil then
		self:_completeinit(template)
		self:_setup()
		self._initcomplete = true
	end
	self.defaultgoal = nil
	self.assettypes = nil
end

function AssetBase:_completeinit(template) -- NOTE: Add any new template keys here!
	self.type     = template.objtype
	
	local debugLogger = Logger.getByName("AssetBase")

	if template.regionname then
		self.rgnname  = template.regionname
	end
	
	if template.desc then	
		--debugLogger:debug("ASSETbase -- desc found: %s", template.desc)
		
		self.briefing = dctutils.interp(template.desc, {
			["LOCATIONMETHOD"] = genLocationMethod(),
		})
		--debugLogger:debug("BRIEFING MADE: "..self.briefing)
		
	else
		print(string.format("Template(%s) has nil 'desc' field",
			template.name))
	end
	
	self.regenerate = template.regenerate
	self.ignore   = template.ignore
	self.owner    = template.coalition
	self.tplname  = template.name
	self.known  = template.known
	self.cp_reward  = template.cp_reward -- command points awarded for succesful mission
	self.period  = template.period  
	self.marshal_point  = template.marshal_point  
	
	--debugLogger:debug("norenametype")
	--debugLogger:debug(tostring(norenametype))
	
	if norenametype[self.type] == true then
		self.name = self.tplname
	else
		self.name = "norename".."_"..self.owner.."_"..template.name
		if template.uniquenames == true then
			self.name = self.name.." #"..
				dct.Theater.singleton():getcntr()
		end
	end
	self.codename = generateCodename(template)

	self._intel[self.owner] = dctutils.INTELMAX
	if self.owner ~= coalition.side.NEUTRAL and template.intel then
		self._intel[dctutils.getenemy(self.owner)] = template.intel
	end
	for _, side in pairs(coalition.side) do
		self._priority[side] = {
			["region"] = template.regionprio,
			["asset"]  = template.priority,
		}
	end
end

--[[
-- Do whatever post init setup needs to be done, is also called
-- when unmarshalling an object.
--]]
function AssetBase:_setup()
end

--[[
-- Magic function used by the Marshallable class.
-- Handle the intel and priority tables special because even
-- though their keys were numbers when the state was serialized
-- in json's wisdom it decided to convert them to strings. So we
-- need to convert back so we can access the data in our lookups.
--]]
function AssetBase:_unmarshalpost(data)
	for _, tbl in ipairs({"_intel", "_priority"}) do
		self[tbl] = {}
		for k, v in pairs(data[tbl]) do
			self[tbl][tonumber(k)] = v
		end
	end
end

function AssetBase:marshal()
	assert(self._initcomplete == true,
		"runtime error: init not completed")
	if self:isDead() then
		return nil
	end
	return Marshallable.marshal(self)
end

function AssetBase:unmarshal(data)
	assert(self._initcomplete == false,
		"runtime error: init completed already")
	Marshallable.unmarshal(self, data)
	self:_setup()
	self._initcomplete = true
end

--[[
-- Called with a region is generated.
-- Params:
--   - assetmgr: reference to theater asset manager
--   - region: reference to calling region
-- Returns: none, might generate new Assets though
--]]
function AssetBase:generate(_ --[[assetmgr, region]])
end

--[[
-- Get the priority of the asset.
-- Returns: number
--]]
function AssetBase:getPriority(side)
	return ((self._priority[side].region * 65536) +
		self._priority[side].asset)
end

--[[
-- Modify the priority of the asset table, where 'side' is the
-- priority table to use and 'tbl' is the table to merge with.
-- Returns: none
--]]
function AssetBase:setPriority(side, tbl)
	utils.mergetables(self._priority[side], tbl)
end

--[[
-- Intel - an intel level of zero implies the given side has no
-- idea about the asset.
--
-- Get the intel level the specified side has on this asset.
-- Returns: number, intel level
--]]
function AssetBase:getIntel(side)
	return self._intel[side]
end

--[[
-- Set the intel level for the given side.
-- Returns: none
--]]
function AssetBase:setIntel(side, val)
	assert(type(val) == "number", "value error: must be a number")
	self._intel[side] = val
end

--[[
-- Is the specified side currently targeting the asset?
-- Returns: boolean
--]]
function AssetBase:isTargeted(side)
	return self._targeted[side]
end

--[[
-- Set the targeted state for a side for an asset.
-- Returns: none
--]]
function AssetBase:setTargeted(side, val)
	assert(type(val) == "boolean",
		"value error: argument must be of type bool")
	self._targeted[side] = val
end

--[[
-- Get the centroid location of the asset.
-- Returns: nil - if not supported otherwise a DCS Vec3
--]]
function AssetBase:getLocation()
	return self._location
end

--[[
-- Get the "status" of the asset, that being a percentage
-- completion of the death goal.
-- Returns: 0-100 value, example if there were 10 original goals
--          and 4 were complete the value returned would be '40'.
--]]
function AssetBase:getStatus()
	return 0
end

--[[
-- Is the asset considered dead yet?
-- Returns: boolean
--]]
function AssetBase:isDead()
	return self._dead
end

--[[
-- Sets if the object should be thought of as dead or not
-- Returns: none
--]]
function AssetBase:setDead(val)
	assert(type(val) == "boolean", "value error: val must be of type bool")
	local prev = self._dead
	self._dead = val
	if self._dead and prev ~= self._dead then
		self:notify(dctutils.buildevent.dead(self))
	end
end

--[[
-- Get DCS object names associated with this asset.
-- Returns: A list of DCS group names that map to this asset.
--          An empty table is valid.
--]]
function AssetBase:getObjectNames()
	return {}
end

--[[
-- Process a DCS event associated w/ this asset.
-- Returns: none
--]]
function AssetBase:onDCTEvent(event)
	local handler = self._eventhandlers[event.id]
	self._logger:debug(string.format(
		"onDCTEvent(); event.id: %d, handler: %s",
		event.id, tostring(handler)))
	if handler ~= nil then
		handler(self, event)
	end
end

--[[
-- Have the DCS objects associated with this asset been spawned?
-- Returns: boolean
--]]
function AssetBase:isSpawned()
	return self._spawned
end

--[[
-- Spawn any DCS objects associated with this asset.
-- Returns: none
--]]
function AssetBase:spawn(_ --[[ignore]])
	self._spawned = true
end

--[[
-- Remove any DCS objects associated with this asset from the game world.
-- The method used should result in no DCS events being triggered.
-- Returns: none
--]]
function AssetBase:despawn()
	self._spawned = false
end

function AssetBase.defaultgoal(static)
	local goal = {}
	goal.priority = Goal.priority.PRIMARY
	goal.goaltype = Goal.goaltype.DAMAGE
	goal.objtype  = Goal.objtype.GROUP
	goal.value    = 90

	if static then
		goal.objtype = Goal.objtype.STATIC
	end
	return goal
end

return AssetBase
