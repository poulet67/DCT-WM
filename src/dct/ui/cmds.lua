--[[
-- SPDX-License-Identifier: LGPL-3.0
--
-- UI Commands
--]]

require("os")
local class    = require("libs.class")
local utils    = require("libs.utils")
local enum     = require("dct.enum")
local dctutils = require("dct.utils")
local human    = require("dct.ui.human")
local Command  = require("dct.Command")
local Logger   = dct.Logger.getByName("UI")
local loadout  = require("dct.systems.loadouts")
local AssetManager= require("dct.assets.AssetManager")

local UICmd = class(Command)
function UICmd:__init(theater, data)
	assert(theater ~= nil, "value error: theater required")
	assert(data ~= nil, "value error: data required")
	local asset = theater:getAssetMgr():getAsset(data.name)
	assert(asset, "runtime error: asset was nil, "..data.name)

	Command.__init(self, "UICmd", self.uicmd, self)

	self.prio         = Command.PRIORITY.UI
	self.theater      = theater
	self.asset        = asset
	self.type         = data.type
	self.displaytime  = 30
	self.displayclear = true
end

function UICmd:isAlive()
	return dctutils.isalive(self.asset.name)
end

function UICmd:uicmd(time)
	-- only process commands from live players unless they are abort
	-- commands
	if not self:isAlive() and
	   self.type ~= enum.uiRequestType.MISSIONABORT then
		Logger:debug("UICmd thinks player is dead, ignore cmd; "..
			debug.traceback())
		self.asset.cmdpending = false
		return nil
	end

	local cmdr = self.theater:getCommander(self.asset.owner)
	local msg  = self:_execute(time, cmdr)
	assert(msg ~= nil and type(msg) == "string", "msg must be a string")
	trigger.action.outTextForGroup(self.asset.groupId, msg,
		self.displaytime, self.displayclear)
	self.asset.cmdpending = false
	return nil
end

local ScratchPadDisplay = class(UICmd)
function ScratchPadDisplay:__init(theater, data)
	UICmd.__init(self, theater, data)
	self.name = "ScratchPadDisplay:"..data.name
end

function ScratchPadDisplay:_execute(_, _)
	local msg = string.format("Scratch Pad: '%s'",
		tostring(self.asset.scratchpad))
	return msg
end

local ScratchPadSet = class(UICmd)
function ScratchPadSet:__init(theater, data)
	UICmd.__init(self, theater, data)
	self.name = "ScratchPadSet:"..data.name
end

function ScratchPadSet:_execute(_, _)
	local mrkid = human.getMarkID()
	local pos   = Group.getByName(self.asset.name):getUnit(1):getPoint()
	local title = "SCRATCHPAD "..tostring(self.asset.groupId)

	self.theater:getSystem("dct.ui.scratchpad"):set(mrkid, self.asset.name)
	trigger.action.markToGroup(mrkid, "edit me", pos,
		self.asset.groupId, false)
	local msg = 
		"Look on F10 MAP for marker ontop of you \n"..
		"Edit text with your mission ID or command. "..
		"Click off the mark when finished. "..
		"The mark will automatically be deleted."
	return msg
end

local TheaterUpdateCmd = class(UICmd)
function TheaterUpdateCmd:__init(theater, data)
	UICmd.__init(self, theater, data)
	self.name = "TheaterUpdateCmd:"..data.name
end

local ShowMissionTypeInfo = class(UICmd)
function ShowMissionTypeInfo:__init(theater, data)
	UICmd.__init(self, theater, data)
	self.name = "TheaterUpdateCmd:"..data.name
end

local ShowMissionBoard = class(UICmd)
function ShowMissionBoard:__init(theater, data)
	UICmd.__init(self, theater, data)
	self.displaytime  = 60
	self.name = "ShowMissionBoard:"..data.name
end

function TheaterUpdateCmd:_execute(_, cmdr)
	local update = cmdr:getTheaterUpdate()
	local msg =
		string.format("== Theater Status ==\n")..		
		string.format("Enemy losses: %s\n", update.enemy_losses)..
		string.format("Friendly losses: %s\n", update.friendly_losses)..
		string.format("Friendly regions controlled: %s\n", update.nregions_friendly)..
		string.format("Enemy regions controlled: %s\n", update.nregions_enemy)..		
		string.format("Friendly Command Points: %s\n", update.friendly_CP)..		
		string.format("Victory condition: %s\n", update.victory_condition_readable)..
		string.format("===================\n")	
		--string.format("  Sea:    %s\n", human.threat(update.enemy.sea)) ..
		--string.format("  Air:    %s\n", human.airthreat(update.enemy.air)) ..
		--string.format("  ELINT:  %s\n", human.threat(update.enemy.elint))..
		--string.format("  SAM:    %s\n", human.threat(update.enemy.sam)) ..
		--string.format("\n== Friendly Force Info ==\n")..
		--string.format("  Force Str: %s\n",
		--	human.strength(update.friendly.str))..
		
	return msg
	
end

function ShowMissionTypeInfo:_execute()

	local msg =
		string.format("========== MISSION TYPES: =========\n")..
		string.format("CAS: Close Air Support - Air to Ground\n")..
		string.format("CAP: Combat Air Patrol - Air to Air \n")..
		string.format("STRIKE: Air Strike - Air to Ground \n")..
		string.format("SEAD: Suppression of Enemy Air Defences - Air to Ground \n")..
		string.format("BAI: Battlefield Air Interdiction - Air to Ground \n")..
		string.format("OCA: Offensive Counter Air - Air to Ground \n")..
		string.format("RECON: Reconnaisance - No target \n")..
		string.format("TRANSPORT: Transportation - No target \n")..
		string.format("ASuW: Anti Surface Warfare - Anti-ship \n")..
		string.format("ESCORT: Escort assets - Air to Air or Air to Ground \n")..
		string.format("INTERCEPT: Interception - Air to Air\n")..
		string.format("CONVOY RAID: Convoy Raid - Air to Ground\n")..
		string.format("LOGISTICS: Logistics - No target \n")..
		string.format("CSAR: Combat Search and Rescue - No target \n")
		
	return msg
	
end

function ShowMissionBoard:_execute(_, cmdr)

	local missiontable = cmdr:getMissionBoard()
	
	--todo: Have the commander generate this when new missions are added.
	
	--assigned = string.format("%d/%d", mb)
	
	console_width = 65 -- changes based on resolution TODO: make this a setting
	
	titlestr = dctutils.printTabular("Current Active Air Missions", console_width, "=").."\n"

	headertable = {
				"ID",
				"TYPE",
				"# ASSGN.",
				"PRIORITY",
				}
	
	headerstring = string.rep("%s",console_width).."\n" -- Spaces, lines -, _ or . are also a good candidate
	
	headerstring = dctutils.printTabular(headertable, console_width, " ")
	
	local msg =	titlestr..headerstring.."\n"
		
	if next(missiontable) ~= nil then
	
		for k,v in pairs(missiontable) do
			outtable = {
						 tostring(k),
						 tostring(utils.getkey(enum.missionType, v.type)),
						 tostring(#v.assigned),
						 tostring(v.priority)
						}
						
			bodystring = dctutils.printTabular(outtable, console_width, " ")
			
			msg = msg .. bodystring .. "\n"
		end
		
		msg = msg .."\n\n\n"
		
	else
		msg = msg .. "  No Active Missions\n"
	end	
		
	return msg
	
end

local CheckPayloadCmd = class(UICmd)
function CheckPayloadCmd:__init(theater, data)
	UICmd.__init(self, theater, data)
	self.name = "CheckPayloadCmd:"..data.name
end

function CheckPayloadCmd:_execute(_ --[[time]], _ --[[cmdr]])
	local msg
	local ok, costs = loadout.check(self.asset)
	if ok then
		msg = "Valid loadout, you may depart. Good luck!"
	else
		msg = "You are over budget! Re-arm before departing, or "..
			"you will be kicked to spectator!"
	end

	-- print cost summary
	msg = msg.."\n== Loadout Summary:"
	for cat, val in pairs(enum.weaponCategory) do
		msg = msg ..string.format("\n%s cost: %d / %d",
			cat, costs[val].current, costs[val].max)
	end

	return msg
end


local MissionCmd = class(UICmd)
function MissionCmd:__init(theater, data)
	UICmd.__init(self, theater, data)
	self.erequest = true
end

function MissionCmd:_execute(time, cmdr)
	local msg
	local msn = cmdr:getAssigned(self.asset)
	if msn == nil then
		msg = "You do not have a mission assigned"
		if self.erequest == true then
			msg = msg .. ", use the F10 menu to request one first."
		end
		return msg
	end
	msg = self:_mission(time, cmdr, msn)
	return msg
end


local function composeBriefing(_, tgt, start_time)
	local briefing = tgt.briefing
	local interptbl = {
		["TOT"] = os.date("%F %Rz",
			dctutils.zulutime(start_time + MISSION_LIMIT * 0.6)),
	}
	return dctutils.interp(briefing, interptbl)
end


local function briefingmsg(msn, asset)
	local start_time = msn.starttime
	local divider = "\n"..string.rep('-',60).."\n"
	local tgtinfo = msn:getTargetInfo()
	local packagecomms = "UHF: "..msn.packagecomms["UHF"].."/ VHF: "..msn.packagecomms["VHF"].." / FM: " .. msn.packagecomms["FM"]
		
	local msg = divider..
				"Package:\n"..			
				string.format("#%s", msn:getID()).."\n"..
				divider..
				"IFF Codes: \n"..
				string.format("M1(%02o), M3(%04o)", msn.iffcodes.m1, msn.iffcodes.m3).."\n"..
				divider..
				"Package Comms: \n"..
				packagecomms.."\n"..
				divider
			
	if(msn.marshal_point) then
	
		msg = msg .. "Marshal Point\n"..
					 string.format("%s", dctutils.fmtposition(msn.marshal_point, 1)).."\n"..
					 divider
		
	end
	
	if(msn.period > 0) then
	
		 msg = msg .. "Start Time:\n"..
					   string.format("%s", os.date("%F %Rz", dctutils.zulutime(start_time + msn.period))).."\n".. -- yeah I don't know why it's off by an hour (DST issues have occured)
					   divider
	end
	
	msg = msg .. 	string.format("%s: \n %s (%s)", human.locationhdr(msn.type), dctutils.fmtposition(tgtinfo.location, tgtinfo.intellvl, asset.gridfmt),	tgtinfo.callsign) ..
					"\n"..
					divider ..
					"Briefing:\n" .. 
					msn:getDescription(asset.gridfmt).."\n"..
					divider
	
	return msg
end

local MissionJoinCmd = class(MissionCmd)
function MissionJoinCmd:__init(theater, data)
	MissionCmd.__init(self, theater, data)
	self.name = "MissionJoinCmd:"..data.name
end

function MissionJoinCmd:_execute(_, cmdr)
	local missioncode = self.asset.scratchpad or 0
	local msn = cmdr:getAssigned(self.asset)
	local msg

	if msn then
		msg = string.format("You have mission %s already assigned, "..
			"use the F10 Menu to abort first.", msn:getID())
		return msg
	end

	msn = cmdr:getMission(missioncode)
	if msn == nil then
		msg = string.format("No mission of ID(%s) available, use"..
			" scratch pad to set ID of mission you'd wish to join.", tostring(missioncode))
	else
		msn:addAssigned(self.asset)
		msg = string.format("Mission %s assigned, use F10 menu "..
			"to see this briefing again\n", msn:getID())
		msg = msg..briefingmsg(msn, self.asset)
		human.drawTargetIntel(msn, self.asset.groupId, false)
	end
	return msg
end


-- DCT-GroundWar0.67 change:
-- No more requesting of missions

-- A mission board is available showing all available missions. They are assigned a priority 1 - 10 (1 being highest priority)
-- Player-Commander (or AI-commander, in a future release) can modify these values at will to communicate which should be completed. 
-- They will have default values depending on the mission type

-- Missions are created as the Commander 'learns' or 'discovers' or 'spots' the asset. This is done using the Recon systems
-- Some mission sets are always available:

-- Air Recon
-- Recon Transport
-- Logistics
-- CAP

-- Recon works like a grid over the region's geographical area:

--		0---0---0---0---0---0---0---0---0
--		0---0---0---0---0---0---0---0---0-
--		0---0---0---0---0---0---0---0---0
--		0---0---0---0---0---0---0---0---0-
--
--	It is defined from the center outward.
--	
--  When a recon team is placed X distance from a node, the node will be active. A recon team has a configurable detection radius. Any units in that range are garunteed to be spotted.
--	As well, the number of active recon nodes in a region will increase the region Recon Level. This increases the chance for an enemy unit in the region to be detected for a given y period of time.
--  When a unit is detected a corresponding mission (Strike for infrastructure, BAI for others) will be created.
--
--
--	
--
--
--


--[[
local MissionRqstCmd = class(MissionCmd)
function MissionRqstCmd:__init(theater, data)
	MissionCmd.__init(self, theater, data)
	self.name = "MissionRqstCmd:"..data.name
	self.missiontype = data.value
	self.displaytime = 120
end

function MissionRqstCmd:_execute(_, cmdr)
	local msn = cmdr:getAssigned(self.asset)
	local msg

	if msn then -- already assigned
		msg = string.format("You have mission %s already assigned, "..
			"use the F10 Menu to abort first.", msn:getID())
		return msg
	end
	
	if enum.availableMissions[self.missiontype] then --Is this mission type available?	
		
		if enum.periodicMissions[self.missiontype] then --if this is a periodic or triggered mission
		
			msg = string.format("Please join public mission from theater update")
			return msg
		
		end
			
		msn = cmdr:requestMission(self.asset.name, self.missiontype)
		
		if msn == nil then
			msg = string.format("No %s missions available.",
				human.missiontype(self.missiontype))
		else
			msg = string.format("Mission %s assigned, use F10 menu "..
				"to see this briefing again\n", msn:getID())
			msg = msg..briefingmsg(msn, self.asset)
			human.drawTargetIntel(msn, self.asset.groupId, false)
		end
		
		return msg
	
	else
		
		msg = string.format("No %s missions available.",
		human.missiontype(self.missiontype))
		return msg
	
	
	end
	
end

--]]

local MissionBriefCmd = class(MissionCmd)
function MissionBriefCmd:__init(theater, data)
	MissionCmd.__init(self, theater, data)
	self.name = "MissionBriefCmd:"..data.name
	self.displaytime = 120
end

function MissionBriefCmd:_mission(_, _, msn)
	return briefingmsg(msn, self.asset)
end


local MissionStatusCmd = class(MissionCmd)
function MissionStatusCmd:__init(theater, data)
	MissionCmd.__init(self, theater, data)
	self.name = "MissionStatusCmd:"..data.name
end

function MissionStatusCmd:_mission(_, _, msn)
	local msg
	local missiontime = timer.getAbsTime()
	local tgtinfo     = msn:getTargetInfo()
	local timeout     = msn:getTimeout()
	local minsleft    = (timeout - missiontime)
	if minsleft < 0 then
		minsleft = 0
	end
	minsleft = minsleft / 60

	msg = string.format("Mission State: %s\n", msn:getStateName())..
		string.format("Package: %s\n", msn:getID())..
		string.format("Timeout: %s (in %d mins)\n",
			os.date("%F %Rz", dctutils.zulutime(timeout)),
			minsleft)..
		string.format("BDA: %d%% complete\n", tgtinfo.status)

	return msg
end


local MissionAbortCmd = class(MissionCmd)
function MissionAbortCmd:__init(theater, data)
	MissionCmd.__init(self, theater, data)
	self.name = "MissionAbortCmd:"..data.name
	self.erequest = false
	self.reason   = data.value
end

function MissionAbortCmd:_mission(_ --[[time]], _, msn)
	local msgs = {
		[enum.missionAbortType.ABORT] =
			"aborted",
		[enum.missionAbortType.COMPLETE] =
			"completed",
		[enum.missionAbortType.TIMEOUT] =
			"timed out",
	}
	local msg = msgs[self.reason]
	if msg == nil then
		msg = "aborted - unknown reason"
	end
	return string.format("Mission %s %s",
		msn:abort(self.asset),
		msg)
end


local MissionRolexCmd = class(MissionCmd)
function MissionRolexCmd:__init(theater, data)
	MissionCmd.__init(self, theater, data)
	self.name = "MissionRolexCmd:"..data.name
	self.rolextime = data.value
end

function MissionRolexCmd:_mission(_, _, msn)
	return string.format("+%d mins added to mission timeout",
		msn:addTime(self.rolextime)/60)
end


local MissionCheckinCmd = class(MissionCmd)
function MissionCheckinCmd:__init(theater, data)
	self.name = "MissionCheckinCmd:"..data.name
	MissionCmd.__init(self, theater, data)
end

function MissionCheckinCmd:_mission(time, _, msn)
	msn:checkin(time)
	return string.format("on-station received")
end


local MissionCheckoutCmd = class(MissionCmd)
function MissionCheckoutCmd:__init(theater, data)
	MissionCmd.__init(self, theater, data)
	self.name = "MissionCheckoutCmd:"..data.name
end

function MissionCheckoutCmd:_mission(time, _, msn)
	return string.format("off-station received, vul time: %d",
		msn:checkout(time))
end

local SpawnCmd = class(UICmd)
function SpawnCmd:__init(theater, data)
	UICmd.__init(self, theater, data)
	self.name = "SpawnCmd:"..data.name
	self.spawningAsset = theater:getAssetMgr():getAsset(data.value)

	Logger:debug("------ SPAWN INIT --------------")
	Logger:debug(tostring(self.spawningAsset))

	
end

function SpawnCmd:_execute(_ --[[time]], _ --[[cmdr]])
	local msg
	
	msg = "SPAWN EXECUTE"
	
	Logger:debug("------ SPAWN EXECUTE --------------")
	
	self.spawningAsset:spawn()	

	return msg
	
end

local cmds = {
	[enum.uiRequestType.THEATERSTATUS]   = TheaterUpdateCmd,
	[enum.uiRequestType.MISSIONBRIEF]    = MissionBriefCmd,
	[enum.uiRequestType.MISSIONSTATUS]   = MissionStatusCmd,
	[enum.uiRequestType.MISSIONABORT]    = MissionAbortCmd,
	[enum.uiRequestType.MISSIONCHECKIN]  = MissionCheckinCmd,
	[enum.uiRequestType.MISSIONCHECKOUT] = MissionCheckoutCmd,
	[enum.uiRequestType.MISSIONBOARD]   = ShowMissionBoard,
	[enum.uiRequestType.MISSIONTYPEINFO]   = ShowMissionTypeInfo,
	[enum.uiRequestType.SCRATCHPADGET]   = ScratchPadDisplay,
	[enum.uiRequestType.SCRATCHPADSET]   = ScratchPadSet,
	[enum.uiRequestType.CHECKPAYLOAD]    = CheckPayloadCmd,
	[enum.uiRequestType.MISSIONJOIN]     = MissionJoinCmd,
	[enum.uiRequestType.SPAWN]     = SpawnCmd,
}

return cmds
