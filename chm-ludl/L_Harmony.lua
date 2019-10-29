--[==[
	Module L_Harmony.lua
	
	Written by R.Boer. 
	V3.14 28 October 2019
	
	V3.14 Changes:
				CustomModeConfiguration has been corrected in 7.30, adapting for change
	V3.13 Changes:
				Prepare for 7.30 release where icons can only be in /www/cmh/skins/default/icons/. Change in device json is backward compatible.
	V3.12 Changes:
				Fix for http request list_device_commands
	V3.11 Changes:
				Added IssueSequenceCommand to start a sequence.
				Added GetSequences, FindSequenceByName, FindSequenceByID commands.
				Fix for Hue RGB lights control.
				Child device attributes now set at device creation, not after and at each startup. Requires latest development branch for openLuup.
	V3.10 Changes:
				Parameter type correction for Harmony_SetHubPolling to fix openLuup issue.
	V3.9 Changes:
				Using domain from provision info to open socket.
	V3.8 Changes:
				Fix of non fatal error in case no Hue lamps are present.
	V3.7 Changes:
				Only obtain Hub remote ID on setup or IP address change.
				Increased socket timeout from 10 to 30 seconds to allow load large Hub configs.
				Better busy check and call_actions will now return proper job status when busy.
	V3.6 Changes:
				Fix for generating Sonos specific JSON.
				Fix for changed Hub discovery options with Hub verison 4.15.250 released Feb 19 2019. Not sure how long it will work. May brake on next Harmony release.
	V3.5 Changes:
				On OpenLuup no JSON rewrite is needed as panels are dynamic. Avoids new (dummy) device on upgrade.
				Corrected button width setting by not fixing the number of buttons per row (UI7 only).
				Fix to avoid config reload attempts when no lamp devices are present.
				Fix for restarting while HubPolling is disabled. We can now restart with Hub off.
				HTTP handler is now enabled by default.
				J_Harmony.js is now for UI7 and openLuup. J_Harmony_UI5.js for old systems.
				Added action to change log level without reload
				Added action to change Remote Images settings in LUA.
				When device manufacturer is Sonos then the playing Album and last known Volume are shown.
				Some more ConfigFilesAPI rewrites.
				Better screen message handling incase of errors or incomplete configurations.
	V3.4 Changes:
				Setting catagory_num and subcategory_num for Lights. 
				Setting lamp model and manufacturer in attribute rather than variable.
				Fix for StartingActivityID.
	V3.3 Changes:
				Added support for automation devices. For now Lamps only.
				Changed call back handling to allow of internal processing.
				Hardened logAPI.
	V3.2 Changes:
				Added StartingActivityStep variable to indicate progress of starting activity. Will hold three numbers: d,n,m. When d is the device, n is the current step and m the total number of steps.
				Setting child device Album and Volume variables as reported by Hub. Used by Sonos devices.
	V3.1 Changes:
				Rounding the json positioning calculations.
	V3.0 Changes:
				Allow activity names instead of activity ID to start activities. Add CurrentActivity variable to reflect.
				Allow device names instead of device ID to send commands to a device.
				Added change channel command.
				Added PowerOff command. (= StartActivity with activity ID -1)
				Added SetPolling command to close & re-open connection to Hub as required.
				(to do) update documentation that for openLuup the LUA bit libary is required. (apt-get install lua-bitop)
				Keep connection to Hub open using ws ping, rather then close after each command to keep receiving status data from Hub.
				Optimized winsocket code for just Hub use and minimized code.
				Store activities and devices config. Device commands with device instance. Only send getconfig if unknown or statedigest reports new config.
				Corrections for scenes advanced editor actions.
				Fixes for implemented actions.
				Changes to ALTUI_plugins.js for new lines added to config and fix for Command duration. (to do)Inform amg0.
	V2.29 Changes:
				Bug fix for new hub instances.
				More complete websocket client connect function.
	V2.28 Changes:
				Changes to Hub WebSocket API
				Seperate UI and plugin version to avoid static file rewrites on upgrades if not needed.
	V2.22 Changes:
				Test to see if we can combine with Incomming to listen to activity changes rather than polling.
	V2.21 Changes:
				Suspend Poll when away has added option to only stop when CurrentActivityID is -1 (all off). Usefull if away/night/vacation trigger to turn all Off.
	V2.20 Changes:
				Support for Home poll only option.
				Updated for my now standard Var and Log modules.
				Small optimizations.
				Removed special handling for UI 7.0.4 and older UI7 versions.
	V2.19 Changes:
				IP Address is now stored in normal variable, no longer in device IP attribute.
				On upgrade the value from IP attribute is used as default.
	V2.18 Changes:
				Make sure Duration value does not get written as empty string as Windows App does not like that.
	V2.17 Changes:
				Native ALTUI support.
	V2.16 Changes:
				Use luup.attr_get rather than accesing luup.devices directly where possible.
	V2.15 Changes:
				Option to wait on Hub to fully complete the start of an activity or not.
				Fix for error message on starting an activity with more than 9 steps.
	V2.14 Changes:
				Minor fix on create child devices when no response from the Harmony Hub device.
	V2.13 Changes:
				When polling is configured do not send a start activity command to the Hub when it is the same as the current activity.
	V2.12 Changes:
				Support for preset house mode settings.
	V2.11 Changes:
				Fix for repeats of startActivity with same value.
	V2.10 Changes:
				Fix for support on activities other then 8 digits long.
	V2.9 Changes:
				Child devices no longer show the delete button when newly created.
				When the SetTarget newTarget is current Target then no action. Before newTarget=1 would always change to default activity.
	V2.8 Changes:
				Child devices no longer show the delete button.
				Extra check on length of returned activity ID. Seems scambled after a failed poll (openLuup issue only?)
	V2.7 Changes: 
				Fix for UI5 and other systems not having dkjson lib installed.
				Fix for possible double scene triggers.
				Support for disable attribute so you can disable the plugin without deinstallation.				
	V2.6.1 Changes:
				Fix for openLuup support and proper definition of parent and child Device and Implementation files.
	V2.6 Changes:
				openLuup support
				handle harmony Hub response when new and current activty are the some one.
 				Minor enhancements for ALTUI drawing after first install
	V2.5 Changes:
				Can define key-press duration for devices.
				Layout improvements for native UI and ALTUI.
 				Changed poll and acknowledge settings to drop down selections.
				Proper JSON returns from LUA.
				Fixed issue with multiple notifications.
	V2.4 Changes:
				AppMemoryUsed updated once per ten minutes and in debug mode only reducing CPU.
				Set functions to local.
				First stab at ALTUI support.
				Fix on time out for starting an activity that creates multiple changes of CurrentActivityID variable.
				Minor fix on StartActivite action.
				Some JS Vera api optimizations for UI7.
	V2.3 Changes:
				Added AppMemoryUsed.
	V2.2 Changes:
				Fix for LUUP restart while there is no connection to the Hub.
	V2.1 Changes:
				Lowered time out as suggested by Starcruiser1229.
				Added time out selection
				Optimizations for UI7.05
				On UI6 & UI7 the image links to correct location is done in LUA. No more install script.
				Button text can be longer when less than five columns are needed.
				Allow for maximum of 25 buttons in UI7.
	V2.03 Changes:
				Check for Busy status and reset to Idle if busy for more then a minute. Should avoid any deadlock situations.
 				No longer resetting the CurrentActivityID on a restart to avoid scenes to be re-triggered on reload.
	V2.02 Changes:
				Can show on/off status on Vera mobile app.
				Added SetTarget 0/1 function to turn on default activity.
				Removed options for MaxActivity and Device Buttons. Now just fixed.
				Removed Enable Button Feedback option. Now uses Ok Acknowledge Interval value.
				Added function to reload luup on UI5
	V2.0 Changes:
				Supports multiple instances of Hub and Device controllers
				Includes migration from v1.7 & v1.8 to new provided there is one hub
				Auto link to correct icon locations using harmony_install.sh
	V1.9 Changes:
				Added syslog server support and log level settings.
	V1.7.1 Changes:
				Fixed issue with JSON file writing
	V1.7 Changes:
				Added support Scene triggers for Child Devices
				Added option to set local or remote icons
				Added option for clear UI visual feedback on child device button click
				Icons of child devices show busy status as well
				Fixed Scene trigger
				Fixed commands handling by sending status release after status press
				Improved start-up handling

Control the harmony Hub
	See forum topic http://forum.micasaverde.com/index.php/topic,14928.0.html
	It seems that none of the elaborate authentication is used in the Hub version I have. So only SubmitCommand is implemented.
--]==]

local ltn12 	= require("ltn12")
local http		= require("socket.http")
local url 		= require("socket.url")
local socket	= require("socket")
local mime 		= require("mime")
local lfs 		= require("lfs")
local json 		= require("dkjson")
if (type(json) == "string") then
	luup.log("Harmony warning dkjson missing, falling back to harmony_json", 2)
	json 		= require("harmony_json")
end
local bit 		= require('bit')
if (type(bit) == "string") then
	bit 		= require('bit32')
end

local Harmony -- Harmony API data object

local HData = { -- Data used by Harmony Plugin
	Version = "3.14",
	UIVersion = "3.5",
	DEVICE = "",
	Description = "Harmony Control",
	SIDS = {
		MODULE = "urn:rboer-com:serviceId:Harmony1",
		CHILD = "urn:rboer-com:serviceId:HarmonyDevice1",
		HA = "urn:micasaverde-com:serviceId:HaDevice1",
		EM = "urn:micasaverde-com:serviceId:EnergyMetering1",
		SP = "urn:upnp-org:serviceId:SwitchPower1",
		DIM = "urn:upnp-org:serviceId:Dimming1",
		COL = "urn:micasaverde-com:serviceId:Color1"
	},
	RemoteIconURL = "https://raw.githubusercontent.com/reneboer/vera-Harmony-Hub/master/icons/",
	UI7IconURL = "../../../icons/",
	UI5IconURL = "icons\\/",
	f_path = '/etc/cmh-ludl/',
	onOpenLuup = false,
	MaxButtonUI5 = 24,  -- Keep the same as HAM_MAXBUTTONS in J_Harmony.js
	MaxButtonUI7 = 25,  -- Keep the same as HAM_MAXBUTTONS in J_Harmony_UI7.js
	Plugin_Disabled = false,
	Busy = false,
	BusyChange = 0,
	OK = 'OK',
	ER = 'ERROR',
	Icon = {
		Variable = "IconSet",	-- Variable controlling the iconsVariable
		IDLE = '0',		-- No background
		OK = '1',		-- Green
		BUSY = '2',		-- Blue
		WAIT = '3',		-- Amber
		ERROR = '4'		-- Red
	},
	Images = { 'Harmony', 'Harmony_0', 'Harmony_25', 'Harmony_50', 'Harmony_75', 'Harmony_100'	},
	HueWatts = {["LLC011"] = 8, 
				["LLC010"] = 10, 
				["LCT007"] = 7,
				["LWB006"] = 9
				} -- Wattage for known models, so we can report approx. energy usage. Used to default UserSuppliedWattage.
}

-- LUA Job Status. Use for handlers
local JobStatus = {
	NO_JOB = -1, -- No job, i.e. job doesn't exist.
	WAITING_TO_START = 0, -- Job waiting to start.
	IN_PROGRESS = 1, -- Job in progress.
	ERROR = 2, -- Job error.
	ABORTED = 3, -- Job aborted.
	DONE = 4, -- Job done.
	WAITING_CALLBACK = 5, -- Job waiting for callback. Used in special cases.
	REQUEUE = 6, -- Job requeue. If the job was aborted and needs to be started, use this special value.
	PENDING_DATA = 7, -- Job in progress with pending data. This means the job is waiting for data, but can't take it now. 
}


---------------------------------------------------------------------------------------------
-- Utility functions
---------------------------------------------------------------------------------------------
local log
local var
local utils
local cnfgFile


-- API getting and setting variables and attributes from Vera more efficient.
local function varAPI()
	local def_sid, def_dev = '', 0
	
	local function _init(sid,dev)
		def_sid = sid
		def_dev = dev
	end
	
	-- Get variable value
	local function _get(name, sid, device)
		local value = luup.variable_get(sid or def_sid, name, tonumber(device or def_dev))
		return (value or '')
	end

	-- Get variable value as number type
	local function _getnum(name, sid, device)
		local value = luup.variable_get(sid or def_sid, name, tonumber(device or def_dev))
		local num = tonumber(value,10)
		return (num or 0)
	end
	
	-- Set variable value
	local function _set(name, value, sid, device)
		local sid = sid or def_sid
		local device = tonumber(device or def_dev)
		local old = luup.variable_get(sid, name, device)
		if (tostring(value) ~= tostring(old or '')) then 
			luup.variable_set(sid, name, value, device)
		end
	end

	-- create missing variable with default value or return existing
	local function _default(name, default, sid, device)
		local sid = sid or def_sid
		local device = tonumber(device or def_dev)
		local value = luup.variable_get(sid, name, device) 
		if (not value) then
			value = default	or ''
			luup.variable_set(sid, name, value, device)	
		end
		return value
	end
	
	-- Get an attribute value, try to return as number value if applicable
	local function _getattr(name, device)
		local value = luup.attr_get(name, tonumber(device or def_dev))
		local nv = tonumber(value,10)
		return (nv or value)
	end

	-- Set an attribute
	local function _setattr(name, value, device)
		local val = _getattr(name, device)
		if val ~= value then 
			luup.attr_set(name, value, tonumber(device or def_dev))
		end	
	end
	
	return {
		Get = _get,
		Set = _set,
		GetNumber = _getnum,
		Default = _default,
		GetAttribute = _getattr,
		SetAttribute = _setattr,
		Initialize = _init
	}
end

-- API to handle basic logging and debug messaging
local function logAPI()
local def_level = 1
local def_prefix = ''
local def_debug = false
local def_file = false
local max_length = 100
local onOpenLuup = false
local taskHandle = -1

	local function _update(level)
		if level > 100 then
			def_file = true
			def_debug = true
			def_level = 10
		elseif level > 10 then
			def_debug = true
			def_file = false
			def_level = 10
		else
			def_file = false
			def_debug = false
			def_level = level
		end
	end	

	local function _init(prefix, level,onol)
		_update(level)
		def_prefix = prefix
		onOpenLuup = onol
	end	
	
	-- Build logging string safely up to given length. If only one string given, then do not format because of length limitations.
	local function prot_format(ln,str,...)
		local msg = ""
		if arg[1] then 
			_, msg = pcall(string.format, str, unpack(arg))
		else 
			msg = str or "no text"
		end 
		if ln > 0 then
			return msg:sub(1,ln)
		else
			return msg
		end	
	end	
	
	local function _log(...) 
		if (def_level >= 10) then
			luup.log(def_prefix .. ": " .. prot_format(max_length,...), 50) 
		end	
	end	
	
	local function _info(...) 
		if (def_level >= 8) then
			luup.log(def_prefix .. "_info: " .. prot_format(max_length,...), 8) 
		end	
	end	

	local function _warning(...) 
		if (def_level >= 2) then
			luup.log(def_prefix .. "_warning: " .. prot_format(max_length,...), 2) 
		end	
	end	

	local function _error(...) 
		if (def_level >= 1) then
			luup.log(def_prefix .. "_error: " .. prot_format(max_length,...), 1) 
		end	
	end	

	local function _debug(...)
		if def_debug then
			luup.log(def_prefix .. "_debug: " .. prot_format(-1,...), 50) 
		end	
	end
	
	-- Write to file for detailed analisys
	local function _logfile(...)
		if def_file then
			local fh = io.open("/tmp/harmony.log","a")
			local msg = os.date("%d/%m/%Y %X") .. ": " .. prot_format(-1,...)
			fh:write(msg)
			fh:write("\n")
			fh:close()
		end	
	end
	
	local function _devmessage(devID, isError, timeout, ...)
		local message =  prot_format(60,...)
		local status = isError and 2 or 4
		-- Standard device message cannot be erased. Need to do a reload if message w/o timeout need to be removed. Rely on caller to trigger that.
		if onOpenLuup then
			taskHandle = luup.task(message, status, def_prefix, taskHandle)
			if timeout ~= 0 then
				luup.call_delay("logAPI_clearTask", timeout, "", false)
			else
				taskHandle = -1
			end
		else
			luup.device_message(devID, status, message, timeout, def_prefix)
		end	
	end
	
	local function logAPI_clearTask()
		luup.task("", 4, def_prefix, taskHandle)
		taskHandle = -1
	end
	_G.logAPI_clearTask = logAPI_clearTask
	
	
	return {
		Initialize = _init,
		Error = _error,
		Warning = _warning,
		Info = _info,
		Log = _log,
		Debug = _debug,
		Update = _update,
		LogFile = _logfile,
		DeviceMessage = _devmessage
	}
end 

-- API to handle some Util functions
local function utilsAPI()
local floor = math.floor
local _UI5 = 5
local _UI6 = 6
local _UI7 = 7
local _UI8 = 8
local _OpenLuup = 99

	local function _init()
	end	

	local function enforceByte(r)
		if r<0 then 
			r=0 
		elseif r>255 then 
			r=255 
		end
		return r
	end

	-- See what system we are running on, some Vera or OpenLuup
	local function _getui()
		if luup.attr_get("openLuup",0) ~= nil then
			return _OpenLuup
		else
			return luup.version_major
		end
		return _UI7
	end
	
	local function _getmemoryused()
		return floor(collectgarbage "count")         -- app's own memory usage in kB
	end
	
	local function _setluupfailure(status,devID)
		if luup.version_major < 7 then status = status ~= 0 end        -- fix UI5 status type
		luup.set_failure(status,devID)
	end

	-- Luup Reload function for UI5,6 and 7
	local function _luup_reload()
		if luup.version_major < 6 then 
			luup.call_action("urn:micasaverde-com:serviceId:HomeAutomationGateway1", "Reload", {}, 0)
		else
			luup.reload()
		end
	end
	
	-- Round up or down to whole number.
	local function _round(n)
		return floor((floor(n*2) + 1)/2)
	end

	local function _split(source, deli)
		local del = deli or ","
		local elements = {}
		local pattern = '([^'..del..']+)'
		string.gsub(source, pattern, function(value) elements[#elements + 1] = value end)
		return elements
	end
  
	local function _join(tab, deli)
		local del = deli or ","
		return table.concat(tab, del)
	end
	
	local function _rgb_to_cie(red, green, blue) -- Thanks to amg0
		-- Apply a gamma correction to the RGB values, which makes the color more vivid and more the like the color displayed on the screen of your device
		red = tonumber(red)
		green = tonumber(green)
		blue = tonumber(blue)
		red 	= (red > 0.04045) and ((red + 0.055) / (1.0 + 0.055))^2.4 or (red / 12.92)
		green 	= (green > 0.04045) and ((green + 0.055) / (1.0 + 0.055))^2.4 or (green / 12.92)
		blue 	= (blue > 0.04045) and ((blue + 0.055) / (1.0 + 0.055))^2.4 or (blue / 12.92)

		-- //RGB values to XYZ using the Wide RGB D65 conversion formula
		local X = red * 0.664511 + green * 0.154324 + blue * 0.162028
		local Y = red * 0.283881 + green * 0.668433 + blue * 0.047685
		local Z = red * 0.000088 + green * 0.072310 + blue * 0.986039

		-- //Calculate the xy values from the XYZ values
		local x1 = floor( 10000 * (X / (X + Y + Z)) )/10000  --.toFixed(4);
		local y1 = floor( 10000 * (Y / (X + Y + Z)) )/10000  --.toFixed(4);
		return x1, y1
	end	

	local function _cie_to_rgb(x, y, brightness) -- Thanks amg0
		-- //Set to maximum brightness if no custom value was given (Not the slick ECMAScript 6 way for compatibility reasons)
		-- debug(string.format("cie_to_rgb(%s,%s,%s)",x, y, brightness or ''))
		x = tonumber(x)
		y = tonumber(y)
		brightness = tonumber(brightness)
	
		if (brightness == nil) then brightness = 254 end

		local z = 1.0 - x - y
		local Y = floor( 100 * (brightness / 254)) /100	-- .toFixed(2);
		local X = (Y / y) * x
		local Z = (Y / y) * z

		-- //Convert to RGB using Wide RGB D65 conversion
		local red 	=  X * 1.656492 - Y * 0.354851 - Z * 0.255038
		local green	= -X * 0.707196 + Y * 1.655397 + Z * 0.036152
		local blue 	=  X * 0.051713 - Y * 0.121364 + Z * 1.011530

		-- //If red, green or blue is larger than 1.0 set it back to the maximum of 1.0
		if (red > blue) and (red > green) and (red > 1.0) then
			green = green / red
			blue = blue / red
			red = 1.0
		elseif (green > blue) and (green > red) and (green > 1.0) then
			red = red / green
			blue = blue / green
			green = 1.0
		elseif (blue > red) and (blue > green) and (blue > 1.0) then
			red = red / blue
			green = green / blue
			blue = 1.0
		end

		-- //Reverse gamma correction
		red 	= (red <= 0.0031308) and (12.92 * red) or (1.0 + 0.055) * (red^(1.0 / 2.4)) - 0.055
		green 	= (green <= 0.0031308) and (12.92 * green) or (1.0 + 0.055) * (green^(1.0 / 2.4)) - 0.055
		blue 	= (blue <= 0.0031308) and (12.92 * blue) or (1.0 + 0.055) * (blue^(1.0 / 2.4)) - 0.055

		-- //Convert normalized decimal to decimal
		red 	= _round(red * 255)
		green 	= _round(green * 255)
		blue 	= _round(blue * 255)
		return enforceByte(red), enforceByte(green), enforceByte(blue)
	end

	local function _hsb_to_rgb(h, s, v) -- Thanks amg0
		h = tonumber(h or 0) / 65535
		s = tonumber(s or 0) / 254
		v = tonumber(v or 0) / 254
		local r, g, b, i, f, p, q, t
		i = floor(h * 6)
		f = h * 6 - i
		p = v * (1 - s)
		q = v * (1 - f * s)
		t = v * (1 - (1 - f) * s)
		if i==0 then
			r = v
			g = t
			b = p
		elseif i==1 then
			r = q
			g = v
			b = p
		elseif i==2 then
			r = p
			g = v
			b = t
		elseif i==3 then
			r = p
			g = q
			b = v
		elseif i==4 then
			r = t
			g = p
			b = v
		elseif i==5 then
			r = v
			g = p
			b = q
		end
		return _round(r * 255), _round(g * 255), _round(b * 255)
	end

	return {
		Initialize = _init,
		ReloadLuup = _luup_reload,
		Round = _round,
		GetMemoryUsed = _getmemoryused,
		SetLuupFailure = _setluupfailure,
		Split = _split,
		Join = _join,
		RgbToCie = _rgb_to_cie,
		CieToRgb = _cie_to_rgb,
		HsbToRgb = _hsb_to_rgb,
		GetUI = _getui,
		IsUI5 = _UI5,
		IsUI6 = _UI6,
		IsUI7 = _UI7,
		IsUI8 = _UI8,
		IsOpenLuup = _OpenLuup
	}
end 



--[[
	Minimal WebSocket client API. Taken from lua-websockets library http://lipp.github.io/lua-websockets/
	Limited to Harmony Hub only support. Messages less than 4MB, only with FIN bit set, Send is masked, receive is never.
]]
local function wsAPI()
	-- Local variables used.
	local sv = { CLOSED = 0, OPEN = 1, IS_CLOSING = 2, ERROR = -1 }
	local ipa = ""
	local port =  "8088"
	local state = sv.CLOSED
	local sock

	-- First bunch of function for en- and decoding.
	local band = bit.band
	local bxor = bit.bxor
	local bor = bit.bor
	local rshift = bit.rshift
	local sbyte = string.byte
	local schar = string.char
	local format = string.format
	local mmin = math.min
	local mrandom = math.random
	local unpack = unpack or table.unpack
	local tinsert = table.insert
	local tconcat = table.concat
	
	local xor_mask = function(encoded,mask,payload)
		local transformed,transformed_arr = {},{}
		for p=1,payload,2000 do
			local last = mmin(p+1999,payload)
			local original = {sbyte(encoded,p,last)}
			for i=1,#original do
				local j = (i-1) % 4 + 1
				transformed[i] = bxor(original[i],mask[j])
			end
			local xored = schar(unpack(transformed,1,#original))
			tinsert(transformed_arr,xored)
		end
		return tconcat(transformed_arr)
	end

	local encode = function(data,opcode)
		local header = (opcode or 1) + 128 -- TEXT is default opcode, we always send with FIN bit set
		local payload = 128  -- We always send with mask bit set.
		local len = #data
		local chunks = {}
		if len < 126 then
			payload = bor(payload,len)
			tinsert(chunks,schar(header,payload))
		elseif len <= 0xffff then
			payload = bor(payload,126)
			tinsert(chunks,schar(header, payload, band(rshift(len, 8), 0xFF), band(len, 0xFF)))
		elseif len < 2^53 then
			-- We never send messages this big
		end
		local m1 = mrandom(0,0xff)
		local m2 = mrandom(0,0xff)
		local m3 = mrandom(0,0xff)
		local m4 = mrandom(0,0xff)
		local mask = {m1,m2,m3,m4}
		tinsert(chunks,schar(m1,m2,m3,m4))
		tinsert(chunks,xor_mask(data,mask,#data))
		return tconcat(chunks)
	end

	local decode_close = function(data)
		local code,reason = 1005, ''
		if data then
			if #data > 1 then
				local lb2, lb1 = data:byte(1,2)
				code = lb2*0x100 + lb1
			end
			if #data > 2 then
				reason = data:sub(3)
			end
		end
		return code,reason
	end

	local upgrade_request = function(req)
		local lines = {
			format('GET %s HTTP/1.1',req.uri or ''),
			format('Host: %s',req.host),
				'Upgrade: websocket',
				'Connection: Upgrade',
			format('Sec-WebSocket-Key: %s',req.key),
				'Sec-WebSocket-Version: 13',
		}
		if req.origin then
			tinsert(lines,format('Origin: %s',req.origin))
		end
		if req.port and req.port ~= 80 then
			lines[2] = format('Host: %s:%d',req.host,req.port)
		end
		tinsert(lines,'\r\n')
		return tconcat(lines,'\r\n')
	end

	local ws_message_waiting = function(timeout)
		if state ~= sv.OPEN then
			return nil,false,1006,'wrong state'
		end
		local tm = 0
		if timeout then tm = timeout end
		local list = {sock}
		local rlist, slist, stat = socket.select (list, nil, tm)
		return stat ~= 'timeout'
	end

	-- start of actual WS functions
	local ws_receive = function(pong)
		if state ~= sv.OPEN and state ~= sv.IS_CLOSING then
			return nil,nil,false,1006,'wrong state'
		end
		local clean = function(was_clean,code,reason)
		    state = sv.CLOSED
			sock:close()
			return nil,nil,was_clean,code,reason or 'closed'
		end
		local chunk,err = sock:receive(2)
		if err == 'timeout' then
			return nil, nil, true, 1000, err
		elseif err then
			return clean(false,1006,err)
		end
		local opcode,pllen = chunk:byte(1,2)
		-- Fin bit always set, so just substract 128 to get opcode
		opcode = opcode - 128
		-- Mask bit never set on response from hub, so just get length
		if pllen == 126 then
			-- read extended length bytes
			local chunk,err = sock:receive(2)
			local lb2,lb1 = chunk:byte(1,2)
			pllen = lb2*0x100 + lb1
		elseif pllen == 127 then
			-- We never get more than 16MB from hub, so we can ignore high 5 bytes
			local chunk,err = sock:receive(8)
			local lb3,lb2,lb1 = chunk:byte(6,8)
			pllen= lb3*0x10000 + lb2*0x100 + lb1
		end
		-- read payload bytes, never masked so plain text from Hub
		local decoded,err = "",nil
		if pllen > 0 then
			decoded,err = sock:receive(pllen)
			if err == 'timeout' then
				return nil, nil, true, 1000, err
			elseif err then
				return clean(false,1006,err)
			end
		end	
		-- Check for closing
		if opcode == 8 then
			if state ~= sv.IS_CLOSING then
				local code,reason = decode_close(decoded)
				-- echo code
				local msg = schar(rshift(code, 8), band(code, 0xFF))
				local encoded = encode(msg,8)
				local n,err = sock:send(encoded)
				if n == #encoded then
					return clean(true,code,reason)
				else
					return clean(false,code,err)
				end
			else
				return decoded,opcode
			end
		end
		return decoded,opcode
	end
	
	local ws_close = function(code)
log.LogFile("Calling ws_close.")
		if state ~= sv.OPEN then
			return false,1006,'wrong state'
		end
		local code = (code or 1000)
		local msg = schar(rshift(code, 8), band(code, 0xFF))
		local encoded = encode(msg,8)
		local n,err = sock:send(encoded)
		local was_clean = false
		local code = 1005
		local reason = ''
		if n == #encoded then
			state = sv.IS_CLOSING
			local rmsg,opcode = ws_receive()
			if rmsg and opcode == 8 then
				code,reason = decode_close(rmsg)
				was_clean = true
			end
		else
			reason = err
		end
		sock:close()
		state = sv.CLOSED
		return was_clean,code,reason or ''
	end

	local ws_send = function(data,opcode)
		if state ~= sv.OPEN then
			return nil,false,1006,'wrong state'
		end
		local encoded = encode(data,opcode or 1)
		local n,err = sock:send(encoded)		
		if n ~= #encoded then
			return nil, ws_close(1006,err)
		end
		return true
	end
	
	local ws_ping = function()
		local res, stat, err, msg = ws_send("",9)
		if res then
			local rsp, op, was_clean,code,reason = ws_receive(true)
			if op == 10 then
				return true
			else
				return false, was_clean,code,reason
			end
		else
			return nil, stat, err, msg
		end
	end
	
	local function ws_connect (host,port,uri)
		ipa = host
		port = port
		if state ~= sv.CLOSED then
			return nil,'wrong state',nil
		end
log.LogFile("Calling ws_connect.")
		sock = socket.tcp()
		local _,err = sock:connect(host,port)
		if err then
			sock:close()
			return nil,err,nil
		end
		sock:settimeout(30)
		local key = "IVEs+XMFJmzMFU/4qqJEqw=="  -- We use a fixed key
		local req = upgrade_request
			{
				key = key,
				host = host,
				port = port,
				uri = uri
			}
		local n,err = sock:send(req)
		if n ~= #req then
			return nil,err,nil
		end
		local hdr_ok = false
		repeat
			local line,err = sock:receive('*l')
			if err then
				return nil,err,nil
			end
			-- if we receive HTTP/1.1 101 Switching Protocols then assume connect is ok.
			if line == "HTTP/1.1 101 Switching Protocols" then hdr_ok = true end
		until line == ''
		if not hdr_ok then
			return nil,'Websocket Handshake failed'
		end
		state = sv.OPEN
		return true
	end

	local ws_is_connected = function()
		return state == sv.OPEN, state
	end

	return {
		connect = ws_connect,
		close = ws_close,
		ping = ws_ping,
		send = ws_send,
		receive = ws_receive,
		is_connected = ws_is_connected,
		message_waiting = ws_message_waiting
	}
end

--[[ 
	API to communicate all command to the Harmony Hub using WebSockets.
]]
local function HarmonyAPI()
	local prsMap = { press = 'press', hold = 'hold', release = 'release' } 
	local numberOfMessages = 20	-- Number of messages to wait on expected one before returning timeout.
	local msg_id = 1
	local last_command_ts = 0
	local last_ping_success = 0
	local ws_client
	local message_prefix = ""
	local hub_data = { remote_id = "", friendly_name = "", email = "", account_id = "", domain = "" }
	local callBacks = {}
	local jobStat = JobStatus.NO_JOB
	local polling_enabled = false
	local cbFunction = nil				-- Can register callback function for acync messages and messages not handled by default flow
	local format = string.format
	local slen = string.len
	local tconcat = table.concat
	local tinsert = table.insert
	local tremove = table.remove

	-- Open web-socket to Hub and kick-off message loop if polling is active.
	local Connect = function()
log.LogFile("Calling Connect.")
		if ((ipa or "") == "") then 
			log.Error("Connect, no IP Address specified ") 
			return nil, nil, 400, "IP address missing" 
		end
		if hub_data.remote_id == "" then
			log.Error("Connect, failed remote ID unknown. ") 
			return nil, nil, 400, "remote ID unknown"
		end	
		if ws_client.is_connected() then
			log.Debug("We should have web-socket open.")
log.LogFile("Connect: We should have web-socket open.")
-- Assume this polling still is active
--			if polling_enabled then
--				-- Kick-off the ping and message loop to keep the connection active and to handle async messages 
--				luup.call_delay("HH_ping_loop",30)
--				luup.call_delay("HH_message_loop",1)
--			end
			return true, 200
		else
--			local res, prot, hdrs = ws_client.connect(ipa,port,"/?domain=svcs.myharmony.com&hubId="..hub_data.remote_id)
			local res, prot, hdrs = ws_client.connect(ipa,port,format("/?domain=%s&hubId=%s",hub_data.domain,hub_data.remote_id))
			if res then
log.LogFile("Connect:We opened web-socket.")
				log.Debug("Web-socket to Hub is opened...")
				last_command_ts = os.time()
				if polling_enabled then
					-- Kick-off the ping and message loop to keep the connection active and to handle async messages 
log.LogFile("Connect:Kick-off polling loops")
					luup.call_delay("HH_ping_loop",30)
					luup.call_delay("HH_message_loop",1)
				end
				return true, 200
			else	
log.LogFile("Connect:failed to open web-socket to hub %s, err %s.",ipa,prot or "")
				log.Error("Connect, failed to open web-socket to hub %s, err %s.",ipa,prot or "")
			end
log.LogFile("Connect:Closing socket, should not get here!!")
			ws_client.close()
		end	
		return nil, nil, 503, "Unable to connect."
	end

	-- Close socket to Hub
	local Close = function()
		ws_client.close()
		return true, 200
	end

	-- Process message and call registered call back handlers
	local HH_HandleCallBack = function(resp)
		local cmd = resp.type or resp.cmd
		local func = callBacks[cmd]
		if func then
			-- Call the registered handler
			local stat, msg = pcall(func, cmd, resp.data)
			if not stat then
				log.Error("Error in call back for command %s, msg %s",cmd,msg)
			end
		else
			-- No call back
			log.Debug("No call back for command %s.",cmd)
			log.Debug(json.encode(resp))
		end	
		if cmd == "harmony.engine?startActivityFinished" then
			-- An activity has started, make job as done. Close connection if not polling.
			if not polling_enabled then Close() end
			jobStat = JobStatus.NO_JOB
		end
		return true
	end

	-- Check for waiting messages from the Hub and process them.
	local HH_message_loop = function()
		if polling_enabled then
			while ws_client.message_waiting() do
				local response, op = ws_client.receive()
				if response then
log.LogFile("MSG Loop: response from hub ".. response)				
					local data, _, errMsg = json.decode(response)
					if data then
						HH_HandleCallBack(data)
					else
						log.Debug("message_loop: Failed to decode hub response %s.",errMsg)
					end
				end	
			end
			-- Schedule to check again in one second
			luup.call_delay("HH_message_loop",1)
		end
	end

	-- To keep the connection to the Hub open send a ping each 45 seconds or 45 seconds after the last command.
	--	  When polling is disabled, then close the connection to the Hub.
	local HH_ping_loop = function()
		if polling_enabled then
			local next_poll = os.difftime(os.time(),last_command_ts)
if next_poll == 0 then
log.LogFile("PingLoop:last ping was zero (%d) seconds ago, is it double?", next_poll)
end			
			if next_poll < 45 then 
				next_poll = 45 - next_poll
			else
				next_poll = 45 
			end
log.LogFile("PingLoop:Scheduling next ping loop call in %d seconds.", next_poll)
			luup.call_delay("HH_ping_loop",next_poll)
			if next_poll >= 45 then
				log.Debug("Keep hub connection open")
				if ws_client.ping() then
					last_command_ts = os.time()
					last_ping_success = last_command_ts
				else
					if os.difftime(os.time(),last_ping_success) > 600 then
						log.Debug("Failed to ping hub for more than five minutes, trying to re-open connection.")
log.LogFile("PingLoop:Failed to ping hub for more than five minutes, trying to re-open connection.")
						Close()
						Connect()
					else	
						log.Debug("Failed to ping hub.")
log.LogFile("PingLoop:Failed to ping hub.")
					end	
				end	
			end	
		else
log.LogFile("PingLoop:End of polling, closed connection to Hub.")
			-- End of polling, close connection to Hub
			Close()
			log.Debug("End of polling, closed connection to Hub.")
		end
	end	

	-- Wait for the response for the given message ID
	-- Max attempts to avoid dead lock.
	local wait_response = function(msgid)
		local maxcnt = numberOfMessages
		while maxcnt > 1 do
			maxcnt = maxcnt -1
			local response, op, was_clean, code, reason = ws_client.receive()
			if response then
--log.Debug("ws_client.receive response: "..(response:sub(1,1000) or ""))
				last_command_ts = os.time()
				local data, _, errMsg = json.decode(response)
				if data then
					if data.id == message_prefix.."#"..msgid then
						return true, data
					else
--log.Debug("response is for other message id : "..(response:sub(1,100) or ""))
						HH_HandleCallBack(data)
					end
				else
					log.Debug("wait_response: Failed to decode hub response %s.", (errMsg or ""))
					return nil, nil, 500, "Failed to decode hub response"
				end
			else
				log.Debug("ws_client.receive error %s, %d, %s ",tostring(was_clean),code,reason)
				maxcnt = 0
			end	
		end
		-- Should not come here
		return nil, nil, 500, "Error waiting for response."
	end

	-- Send a payload request to Harmony Hub and return json response.
	-- When resp is nil or true expect a response message
	local function send_request(command, params, msgid, wait_for_response)
		local params = params or '{"verb":"get","format":"json"}'
		local msid
		if msgid then
			msid = msgid
		else
			msg_id = msg_id+1
			if msg_id > 999999 then msg_id = 1 end
			msid = msg_id
		end
		local payload = format('{"hbus":{"cmd":"%s","id":"%s#%s","params":%s}}',command,message_prefix,msid,params)
		local res, stat, err, msg = ws_client.send(payload) 
		if res then
--log.Debug("send_request, sent payload %s",payload)
			if wait_for_response ~= false then return wait_response(msid) end
			last_command_ts = os.time()
			return true
		else
			log.Debug("ws_client.send failed : %s, %s, %s. Retrying once.",tostring(stat),tostring(err),msg)
			-- Try to reconnect and resend command once so we can keep going
			if err == 1006 then
--				local res = ws_client.connect(ipa,port,"/?domain=svcs.myharmony.com&hubId="..hub_data.remote_id)
				local res = ws_client.connect(ipa,port,format("/?domain=%s&hubId=%s",hub_data.domain,hub_data.remote_id))
				if res then
					local res, stat, err, msg = ws_client.send(payload) 
					if res then
						if wait_for_response ~= false then return wait_response(msid) end
						last_command_ts = os.time()
						return true
					end
				end	
			end	
		end	
		return nil, nil, 408, "Send failed after retry."
	end

	-- Return current Job Status	
	local GetJobStatus = function()
		return true, jobStat or JobStatus.NO_JOB
	end	
	
	-- Return the details about the Hub. Get from Hub if not yet known. This is done before the Web-socket is opened.
	local GetHubDetails = function()
		if hub_data.remote_id ~= "" and hub_data.domain ~= "" then
			return true, hub_data
		else
			log.Debug("Retrieving Harmony Hub information.")
			local uri = format('http://%s:%s/',ipa,port)
--			local request_body = '{"id":1,"cmd":"connect.discoveryinfo?get","params":{}}'	-- 	pre Hub V4.15.250
			local request_body = '{"id":1,"cmd":"setup.account?getProvisionInfo"}'			-- 	ub V4.15.250
			local headers = {
--				['Origin']= 'http://localhost.nebula.myharmony.com', 						-- 	pre Hub V4.15.250
				['Origin']= 'http://sl.dhg.myharmony.com',									-- 	Hub V4.15.250
				['Content-Type'] = 'application/json',
				['Accept'] = 'application/json',
				['Accept-Charset'] = 'utf-8',
				['Content-Length'] = slen(request_body)
			}
			local result = {}
			local bdy,cde,hdrs,stts = http.request{
				url=uri, 
				method='POST',
				sink=ltn12.sink.table(result),
				source = ltn12.source.string(request_body),
				headers = headers
			}
			if cde == 200 then
				local json_response = json.decode(tconcat(result))
--				hub_data.friendly_name = json_response['data']['friendlyName'] or "" 		-- 	pre Hub V4.15.250
--				hub_data.remote_id = json_response['data']['remoteId'] or ""				-- 	pre Hub V4.15.250
				hub_data.remote_id = json_response['data']['activeRemoteId'] or ""			-- 	Hub V4.15.250
				hub_data.email = json_response['data']['email'] or ""
				hub_data.account_id = json_response['data']['accountId'] or ""
				local pu = url.parse(json_response['data']['discoveryServer'])
				hub_data.domain = pu.host or "svcs.myharmony.com"
				log.Debug("Hub details : %s, %s, %s.",hub_data.remote_id,hub_data.account_id,hub_data.email)
				return true, hub_data
			else
				log.Error("Connect, failed geting details. Err %s, %s", cde or 500, msg or "unknown") 
				return nil, nil, cde or 400, stts or "discover failed."
			end
		end	
	end
	
	--[[ Request the current activity from Hub
			Return true and current activity ID on success.
			On error return error code and message.
	--]]
	local GetCurrentActivtyID = function(noclose)
		jobStat = JobStatus.IN_PROGRESS
		if not polling_enabled then Connect() end
		local res, data, cde, msg = send_request("vnd.logitech.harmony\\/vnd.logitech.harmony.engine?getCurrentActivity")
		if (not polling_enabled) and (noclose ~= true) then Close() end
		if res then 
			if data.code == 200 then
				res = true
				data = data.data.result
			else	
				cde = data.code or 400
				msg = data.msg or "unknown error"
				data = nil
			end	
		else
			cde = 503
			msg = "No response from hub."
		end
		jobStat = JobStatus.NO_JOB
		return res, data, cde, msg
	end

	--[[ Send start activity command to hub if not current activity.
			Params : activity ID to start, if wait is false, return without waiting for message started confirmation from hub.
			Return true on success, false with error code and message if not.
	--]]
	local StartActivity = function(actID,wait)
		local aid = actID or ""
		if aid ~= "" then
			-- Get current activity, make and keep connection open.
			local res, data, cde, msg = GetCurrentActivtyID(true)
			if not res then
				-- Log error and data is now nil so always try to start
				log.Error("Failed getting current activity. %s, %s",cde, msg)
			end	
			-- Only send if it is a different activity.
			if data ~= aid then
				jobStat = JobStatus.IN_PROGRESS
				local res1, data1, cde1, msg1 = send_request("harmony.activityengine?runactivity", format('{"async": "true","timestamp": 10000 ,"args":{"rule":"start"},"activityId":"%s"}',aid))
				if res1 then 
					-- Not waiting on reply
					res = true
					data = aid
				else
					res = nil
					data = nil
					cde = cde1 or 503
					msg = msg1 or "No response from hub."
					if not polling_enabled then Close() end
					jobStat = JobStatus.NO_JOB
				end
				return res, data, cde, msg
			else
				-- We are already running this activity. Do nothing.
				return true, aid
			end
		else
			return nil, nil, 400, "Missing parameter, activityID"
		end
	end
	
	--[[ Send change channel command to hub
			Params : channel to select.
			Return true on success, error code and message if not.
	--]]
	local ChangeChannel = function(channel)
		local chnl = channel or ""
		if chnl ~= "" then
			jobStat = JobStatus.IN_PROGRESS
			if not polling_enabled then Connect() end
			local res, data, cde, msg = send_request("harmony.engine?changeChannel", format('{"timestamp":10000,"channel":%s}',chnl))
			if not polling_enabled then Close() end
			jobStat = JobStatus.NO_JOB
			return res, data, cde, msg
		else
			return nil, nil, 400, "Missing parameter, Channel"
		end
	end

	--[[ Send a sequence command.
			Params: sequence ID to send
	--]]
	local IssueSequenceCommand = function(sequenceId)
		local res, data, cde, msg = nil, nil, 400, ""
		local id = sequenceId or ""
		local prs = prsMap.press .. prsMap.release
		if id ~= "" then
			log.Debug("Sending Sequence Command %s.", id)
			local action = format('{\\"sequenceId\\":\\"%s\\"}', id)
			local params = format('{"status":"%s","timestamp":0,"verb":"render","action":"%s"}',prs,action)
			-- First key-press down command
			jobStat = JobStatus.IN_PROGRESS
			if not polling_enabled then Connect() end
			-- For Hold action sequesce we must use the same message ID. Lets use HoldAction with command.
			-- Depends on device if we get a response. Assume none.
			local res1, data1, cde1, msg1 = send_request("vnd.logitech.harmony\\/vnd.logitech.harmony.engine?holdAction", params, "HOLD", false)
			if res1 then 
				res = true
				data = 200
			else	
				res = nil
				data = nil
				cde = cde1 or 503
				msg = msg1 or "No response from hub."
			end
			jobStat = JobStatus.NO_JOB
			if not polling_enabled then Close() end
		else
			msg = "Missing parameters, Sequence ID"
		end
		return res, data, cde, msg
	end

	--[[ Send start hold action command. 
			Params : device ID to send to, command to send, duration to hold the key-press, key-press action.
			Return true on success, false with error code and message if not.
			
		Send HoldAction commands every 0.5 seconds for the time of the duration. Called from IssueDeviceCommand only.
	--]]
	local IssueDeviceCommand = function(deviceID,command,duration,press)
		local res, data, cde, msg = nil, nil, 400, ""
		local id = deviceID or ""
		local cmd = command or ""
		local dur = duration or 0
		local prs = press or prsMap.press
		if id ~= "" and cmd ~= "" then
			local timestamp = 10000 -- It seems we need to restart the timestamp for each sequence, else next will not work.
			log.Debug("Sending holdAction Command %s, %s, %s, %s.", id, cmd, dur, prs)
			local action = format('{\\"command\\":\\"%s\\",\\"type\\":\\"IRCommand\\",\\"deviceId\\":\\"%s\\"}', cmd, id)
			local params = format('{"status":"%s","timestamp":%s,"verb":"render","action":"%s"}',prs,timestamp,action)
			-- First key-press down command
			jobStat = JobStatus.IN_PROGRESS
			if not polling_enabled then Connect() end
			-- For Hold action sequesce we must use the same message ID. Lets use HoldAction with command.
			-- Depends on device if we get a response. Assume none.
			local res1, data1, cde1, msg1 = send_request("vnd.logitech.harmony\\/vnd.logitech.harmony.engine?holdAction", params, "HOLD", false)
			timestamp = timestamp + 254 
			if res1 then 
				if dur > 0 then
					-- If we have a duration then send a hold each 500ms end with a release. First schedule on 1 sec from now
					local params = format('{"action":"%s","status":"%s","timestamp":%s}',action,prsMap.hold,timestamp)
					for i = 1, (dur*5)-1 do
						timestamp = timestamp + 254 
						-- Sleep 200ms seconds between holds.
						luup.sleep(200)
						send_request("vnd.logitech.harmony\\/vnd.logitech.harmony.engine?holdAction", params, "HOLD", false)
					end	
					luup.sleep(100)
				end	
				local params = format('{"action":"%s","status":"%s","timestamp":%s}',action,prsMap.release,timestamp)
				send_request("vnd.logitech.harmony\\/vnd.logitech.harmony.engine?holdAction", params, "HOLD", false)
				res = true
				data = 200
			else	
				res = nil
				data = nil
				cde = cde1 or 503
				msg = msg1 or "No response from hub."
			end
			jobStat = JobStatus.NO_JOB
			if not polling_enabled then Close() end
		else
			msg = "Missing parameters, Device ID, Command"
		end
		return res, data, cde, msg
	end

	--[[ Return full Hub configuration
	--]]
	local GetConfig = function()
		log.Debug("Retrieve the config from Hub.")
		jobStat = JobStatus.IN_PROGRESS
		if not polling_enabled then Connect() end
		local res, data, cde, msg = send_request("vnd.logitech.harmony\\/vnd.logitech.harmony.engine?config")
		if not polling_enabled then Close() end
		jobStat = JobStatus.NO_JOB
		return res, data, cde, msg
	end
	
	--[[ Return full Hub automation configuration. This includes Hue lights, maybe more.
	--]]
	local GetAutomationConfig = function()
		log.Debug("Retrieve the automation config from Hub.")
		jobStat = JobStatus.IN_PROGRESS
		if not polling_enabled then Connect() end
		local res, data, cde, msg = send_request("proxy.resource?get", '{"uri":"dynamite://HomeAutomationService/Config/"}')
		if not polling_enabled then Close() end
		jobStat = JobStatus.NO_JOB
		return res, data, cde, msg
	end
	
	-- Get automation state
	local GetAutomationState = function(pars)
		log.Debug("GetAutomationState from Hub.")
		jobStat = JobStatus.IN_PROGRESS
		if not polling_enabled then Connect() end
		local res, data, cde, msg = send_request("harmony.automation?getState", pars or "{}")
		if not polling_enabled then Close() end
		jobStat = JobStatus.NO_JOB
		return res, data, cde, msg
	end

	-- Set automation state
	local SetAutomationState = function(params)
		log.Debug("SetAutomationState.")
		jobStat = JobStatus.IN_PROGRESS
		if not polling_enabled then Connect() end
		local res, data, cde, msg = send_request("harmony.automation?setState", params)
		if not polling_enabled then Close() end
		jobStat = JobStatus.NO_JOB
		return res, data, cde, msg
	end

	--[[ Get State Digest from hub to get config details
			Return true and data on success, false with error code and message if not.
	--]]
	local GetStateDigest = function()
		jobStat = JobStatus.IN_PROGRESS
		if not polling_enabled then Connect() end
		local res, data, cde, msg = send_request("vnd.logitech.connect\\/vnd.logitech.statedigest?get")
		if not polling_enabled then Close() end
		if res then 
			-- The user callback may also want process state digest details.
			HH_HandleCallBack(data)
		end
		jobStat = JobStatus.NO_JOB
		return res, data, cde, msg
	end
	
	-- When called with true then the connection to the Hub will be kept open
	-- Can be toggled at any time.
	local SetHubPolling = function(poll)
--log.LogFile("Entering SetHubPolling with value %s.", tostring(poll))
		if polling_enabled == poll then return true, 200 end
		polling_enabled = poll
		if poll then
--log.LogFile("Polling is started again")
			-- re-open the connection
			local res, data, cde, msg = Connect()
			if res then
-- Moved to Connect			
--				-- Initiate polling again
--				luup.call_delay("HH_ping_loop",30)
--				HH_message_loop()
			else
				log.Error("SetPolling, could not reconnect to Hub. Err : %s, %s", cde, msg)
			end
			return res, data, cde, msg
		end	
		return true, 200
	end
	-- Return current polling status.
	local GetHubPolling = function()
		return polling_enabled
	end	
	
	-- Add a callback for a given command on top of internal handing
	local RegisterCallBack = function(cmdtype, cbFunction)
		if (type(cbFunction) == 'function') then
			callBacks[cmdtype] = cbFunction 
			return true
		end
		return nil, nil, 1006, "Not a function"
	end

	--[[ Initialize module. If called second time it can be used to change the configuration and connect to a different IP address.
			params: IP address, non-default port to connect to the Hub, last known RemoteID, message prefix and poll flag.
	--]]
	local Initialize = function(_ipa, _port, _rem_id, _domain, _msg_prf, _poll)
		ipa = _ipa or ""
		port = _port or 8088
		message_prefix = _msg_prf
		polling_enabled = _poll
		hub_data.remote_id = _rem_id
		hub_data.domain = _domain
		-- Need to make this global for luup.call_delay use. 
		_G.HH_send_hold_command = HH_send_hold_command
		_G.HH_message_loop = HH_message_loop
		_G.HH_ping_loop = HH_ping_loop
		-- Connect to ws_client, when done prior, Close open connection to Hub and re-open with new details
		if not ws_client then 
			ws_client = wsAPI() 
		else
			Close()
			-- Reset remote ID as we may have a different IP address.
--			hub_data.remote_id = ""
		end
-- Moved to Connect
--		local res, data, cde, msg
--		if polling_enabled then
--			res, data, cde, msg = Connect()
--			if res then
--				-- Kick-off the ping and message loop to keep the connection active and to handle async messages 
--				luup.call_delay("HH_ping_loop",30)
--				HH_message_loop()
--			end
--		else
			res = true
--		end
		return res, data, cde, msg
	end
	
	return{ -- Methods exposed by API
		Initialize = Initialize,
		Connect = Connect,
		Close = Close,
		GetJobStatus = GetJobStatus,
		GetHubDetails = GetHubDetails,
		GetStateDigest = GetStateDigest,
		GetCurrentActivtyID = GetCurrentActivtyID,
		StartActivity = StartActivity,
		ChangeChannel = ChangeChannel,
		IssueSequenceCommand = IssueSequenceCommand,
		IssueDeviceCommand = IssueDeviceCommand,
		SetHubPolling = SetHubPolling,
		GetHubPolling = GetHubPolling,
		RegisterCallBack = RegisterCallBack,
		GetConfig = GetConfig,
		GetAutomationConfig = GetAutomationConfig,
		GetAutomationState = GetAutomationState,
		SetAutomationState = SetAutomationState
	}
end

--[[--------------------------------------------------------------------------------------
 Vera static config files creation functions for JSON and Device definition files.
 Parameters:
	FilePath: Path of config files.
	IsUI7: true is Vera UI is UI7 or ALTUI.
	IsOpenLuup: true is running on openLuup.
	maxBtn: Maximum number of buttons.
	remIconURI: remote Icons URI.
	locIconURI: Local Icons URI.
  Dependencies: logAPI module	
]]
local function ConfigFilesAPI()
	local format = string.format
	local FilePath,IsUI7,IsOpenLuup,maxBtn,remIconURI,locIconURI, iconImages, Dev, Sid, ChSid

	local function _init(_path,_IsUI7,_IsOpenLuup,_maxBtn,_remIconURI,_locIconURI,_iconImages, _Dev, _Sid, _ChSid)
		FilePath = _path
		IsUI7 = _IsUI7
		IsOpenLuup = _IsOpenLuup
		maxBtn = _maxBtn
		remIconURI = _remIconURI
		locIconURI = _locIconURI
		iconImages = _iconImages
		Dev = _Dev
		Sid = _Sid
		ChSid = _ChSid
	end

	-- See if we have D_HarmonyDevice*.* files that no longer map to a child device.
	-- Remove them as it will cause issues when child for same device is recreated.
	local function _removeObsoleteChildDeviceFiles(childDevs)
		local lfs = require("lfs")

		local chDev = (childDevs or '') .. ','
		for fname in lfs.dir(FilePath) do
			local dname = string.match(fname, "D_HarmonyDevice"..Dev.."_%d+.")
			if dname then 
				local _,dnum = string.match(dname, "(%d+)_(%d+)")
				if dnum then
					-- We have a child device file, see if the number is still in list of child devices
					dname = string.match(chDev, dnum..',')
					if dname then 
						log.Log('Child file %s still in use.',fname)
					else
						log.Warning('Removing obsolete child file %s.',fname)
						os.remove(FilePath..fname)
					end	
				end	
			end
		end
	end

	-- Remove the Device file for the current device. Only used on openLuup for upgrade to 3.2.
	local function _removeObsoleteDeviceFiles()
		local lfs = require("lfs")

		for fname in lfs.dir(FilePath) do
			local dname = string.match(fname, "D_Harmony"..Dev..".")
			if dname then 
				local dnum = string.match(dname, "(%d+)")
				if dnum then
					-- We have a device file, see if the number is still in list of child devices
					log.Warning('Removing obsolete file %s.',fname)
					os.remove(FilePath..fname)
				end	
			end
		end
	end

	-- Support functions to build reoccurring JSON elements.
	local function _buildJsonLabelControl(text,top,left,width,height,grp,dtop,dleft)
		local str = '{ "ControlType": "label", '
		if grp then str = str .. format('"ControlGroup": "%s", "top": %d, "left": %d, ',grp,dtop,dleft) end
		str = str .. format('"Label": { "text": "%s" }, "Display": { "Top": %d, "Left": %d, "Width": %d, "Height": %d }}',text,top,left,width,height)
		return str
	end
	local function _buildJsonVariableControl(text,top,left,width,height,grp,dtop,dleft)
		local str = '{ "ControlType": "variable", '
		if grp then str = str .. format('"ControlGroup": "%s", "top": %d, "left": %d, ',grp,dtop,dleft) end
		str = str .. format('"Display": { "Service": "%s", "Variable": "%s", "Top": %d, "Left": %d, "Width": %d, "Height": %d }}',Sid,text,top,left,width,height)
		return str
	end
	local function _buildJsonInputControl(text,top,left,width,height,grp,dtop,dleft)
		local str = '{ "ControlType": "input", '
		if text then str = str .. format('"ID": "ID%s", ',text) end
		if grp then str = str .. format('"ControlGroup": "%s", "top": %d, "left": %d, ',grp,dtop,dleft) end
		str = str .. format('"Display": { "Top": %d, "Left": %d, "Width": %d }}',top,left,width)
		return str
	end
	local function _buildJsonButtonControl(text,act,prm,top,left,width,height,grp,dtop,dleft)
		local str = format('{ "ControlType": "button", "Label": { "text":"%s"}, ',text)
		if grp then str = str .. format('"ControlGroup": "%s", "top": %d, "left": %d, ',grp,dtop,dleft) end
		str = str .. format('"Display": { "Top": %d, "Left": %d, "Width": %d },',top,left,width)
		str = str .. format('"Command": { "Service":"%s","Action":"%s"',Sid,act)
		if prm then str = str .. format(', "Parameters":[{ "Name":"%s","ID":"ID%s" }]',prm,text) end
		str = str .. '}}'
		return str
	end
	local function _buildJsonLabel(tag,text,top,pos,scr,func)
		local str = format('{ "Label": { "lang_tag": "%s", "text": "%s" }, ',tag,text)
		if IsUI7 and top then str = str .. '"TopNavigationTab": 1, ' end
		str = str .. format('"Position": "%s", "TabType": "javascript", "ScriptName": "%s", "Function": "%s" }',pos,scr,func)
		return str
	end
	local function _buildJsonEvent(id,val,text)		
		local str = format('{ "value": "%s", "HumanFriendlyText": { "lang_tag": "ham_act_id_ch%s", "text": "%s" }}',val,id,text)
		return str
	end
	local function _buildJsonStateIcon(icon,vari,val,sid,path)		
		local str
		if IsUI7 then
			str = format('{ "img": "%s%s.png", "conditions": [ { "service": "%s", "variable": "%s", "operator": "==","value": %s } ]}',path,icon,sid,vari,val)
		else
			str = format('"%s%s.png"',path,icon)
		end
		return str
	end
	local function _buildJsonButton(btnNum,btnLab,btnID,btnDur,numBtn,isChild)
		-- Input : Button label, button ID, total number of buttons and if this is a Child device
		-- Calculate top and left values.
		-- Need to calculate a pair for the dashboard pannel and device control tab
		local pTop, pLeft, cTop, cLeft, cWidth, row, col, butWidth, str
		str = ''
		if IsUI7 then
			if numBtn == 4 then	-- Two rows, two columns
				pTop, col = math.modf((btnNum-1) / 2)
				pLeft = col * 2
				butWidth =  2
			elseif numBtn <= 5 then	-- One row, up to five columns
				pLeft = btnNum-1
				pTop = 0
				butWidth =  1 + (5-numBtn)/3
			elseif numBtn == 6 then	-- Two rows, three columns
				pTop, col = math.modf((btnNum-1) / 3)
				pLeft = col * 3
				butWidth = 1.66
			elseif numBtn <= 8 then	-- Two rows, four columns
				pTop, col = math.modf((btnNum-1) / 4)
				pLeft = col * 4
				butWidth = 1.33
			elseif numBtn <= 1 then	-- Two rows, five columns
				pTop, col = math.modf((btnNum-1) / 5)
				pLeft = col * 5
				butWidth = 1
			elseif numBtn <= 12 then	-- Three rows, four columns
				pTop, col = math.modf((btnNum-1) / 4)
				pLeft = col * 4
				butWidth = 1.33
			elseif numBtn <= 15 then	-- Three rows, five columns
				pTop, col = math.modf((btnNum-1) / 5)
				pLeft = col * 5
				butWidth = 1
			elseif numBtn <= 16 then	-- Four rows, four columns
				pTop, col = math.modf((btnNum-1) / 4)
				pLeft = col * 4
				butWidth = 1.33
			else						-- Four or five rows, five columns
				pTop, col = math.modf((btnNum-1) / 5)
				pLeft = col * 5
				butWidth = 1
			end
			pTop = utils.Round(pTop)
			pLeft = utils.Round(pLeft)
			cTop = utils.Round(45 + (pTop * 25))
			cWidth = utils.Round(65 * butWidth)
			cLeft = utils.Round(50 + (pLeft * (cWidth + 10)))
		else
			if (numBtn <= 8) then		-- Two columns
				pTop, col = math.modf((btnNum-1) / 2)
				pLeft = col * 2
			elseif (numBtn <= 12) then	-- Three columns
				pTop, col = math.modf((btnNum-1) / 3)
				pLeft = col * 3
			elseif (numBtn <= 16) then	-- Four columns
				pTop, col = math.modf((btnNum-1) / 4)
				pLeft = col * 4
			elseif (numBtn <= 20) then	-- Five columns
				pTop, col = math.modf((btnNum-1) / 5)
				pLeft = col * 5
			else						-- Six columns
				pTop, col = math.modf((btnNum-1) / 6)
				pLeft = col * 6
			end
			pTop = utils.Round(pTop)
			pLeft = utils.Round(pLeft)
			cWidth = 65
			cTop = utils.Round(45 + (pTop * 25))
			cLeft = utils.Round(50 + (pLeft * (cWidth + 10)))
		end	
		str = str .. format('{ "ControlGroup": "1", "ControlType": "button", "top": %d, "left": %d,',pTop,pLeft)
		if butWidth ~= 1 and IsUI7 then
			str = str .. format('"HorizontalMultiplier": "%s",',butWidth)
		end
		str = str .. format('\n"Label": { "text": "%s" },\n',btnLab)
		if isChild then
			if btnDur == '' then btnDur = 0 end
			str = str .. format('"Display": { "Service": "%s", "Variable": "LastDeviceCommand", "Value": "%s", "Top": %d, "Left": %d, "Width": %d, "Height": 20 },\n',ChSid,btnID,cTop,cLeft,cWidth)
			str = str .. format('"Command": { "Service": "%s", "Action": "SendDeviceCommand", "Parameters": [{ "Name": "Command", "Value": "%s"},{ "Name": "Duration", "Value": "%s" }] },\n',ChSid,btnID,btnDur)
		else
			str = str .. format('"Display": { "Service": "%s", "Variable": "CurrentActivityID", "Value": "%s", "Top": %d, "Left": %d, "Width": %d, "Height": 20 },\n',Sid,btnID,cTop,cLeft,cWidth)
			str = str .. format('"Command": { "Service": "%s", "Action": "StartActivity", "Parameters": [{ "Name": "newActivityID", "Value": "%s" }] },\n',Sid,btnID)
		end
		str = str .. format('"ControlCode": "ham_button%s"\n}',btnNum)
		return str
	end

	-- Build the JSON file 
	local function _writeJsonFile(devID,outf,iconPath,isChild,buttons,childDev,isSonos)
--		local id, lab, dur, sid
		local id, lab, dur
		local numBtn = #buttons
--		if not isChild then sid = Sid else sid = ChSid end
		local sid = isChild and ChSid or Sid
		-- For main device default icon is wait so it status is more clear during all reloads.
		if IsUI7 then
			local defIcon = isChild and 'Harmony.png' or 'Harmony_75.png'
--			if (isChild == false) then defIcon = 'Harmony_75.png' else defIcon = 'Harmony.png' end
			outf:write(format('{\n"default_icon": "%s%s",\n',iconPath,defIcon))
		else
			outf:write(format('{\n"flashicon": "%sHarmony.png",\n',iconPath))
		end
		outf:write('"state_icons":[ \n')
		-- Write status Icon control, skip first image as that is plug in default
		for i = 2, #iconImages do
			outf:write(_buildJsonStateIcon(iconImages[i],'IconSet',i-2,sid,iconPath))
			if i < #iconImages then 
				outf:write(', ')
			else
				outf:write(' ],\n')
			end
		end	
		if IsUI7 then 
			outf:write(format('"DisplayStatus": { "Service": "%s", "Variable": "IconSet", "MinValue": "0", "MaxValue": "4" },\n',sid)) 
		end
		-- Calculate X size of device on screen
		local x,y,top,tab
		if numBtn > 6 then 
			x,y = math.modf((numBtn + 3) / 4)
			outf:write(format('"x": "%d",\n"y": "4",\n',utils.Round(x))) 
		else
			outf:write('"x": "2",\n"y": "4",\n') 
		end
		outf:write('"inScene": "1",\n"ToggleButton": 1,\n"Tabs": [ {\n')
		outf:write('"Label": { "lang_tag": "tabname_control", "text": "Control" },\n')
		outf:write('"Position": "0",\n"TabType": "flash",\n')
		if IsUI7 then outf:write('"TopNavigationTab": 1,\n') end
		outf:write('"ControlGroup": [ { "id": "1", "scenegroup": "1", "isSingle": "1" } ],\n')
		-- Calculate correct SceneGroup size. Size not used in UI7.
--		if numBtn < 5 then top = 1 else top = 0 end
		top = (numBtn < 5) and 1 or 0 
		if numBtn <= 1 then 
			x = 1 
			y = 1
		elseif numBtn <= 8 then
			y, x = math.modf((numBtn + 1) / 2)
			x = 2
		elseif numBtn <= 12 then
			y, x = math.modf((numBtn + 2) / 3)
			x = 3 
		else
			x,y = math.modf((numBtn + 3) / 4)
			y = 4
		end
		outf:write(format('"SceneGroup": [ { "id": "1", "top": "%d", "left": "0", "x": "%d", "y": "%d"} ],\n',top,utils.Round(x),utils.Round(y)))
		outf:write('"Control": [')
		if numBtn > 0 then
			-- Add the buttons
			for i = 1, #buttons do
				log.Debug('Adding button %d, label %s' ,i,(buttons[i].Label or 'missing'))
				outf:write(_buildJsonButton(i,buttons[i].Label, buttons[i].ID, buttons[i].Dur, numBtn, isChild) .. ',\n')
			end	
		else
			if isChild then
				outf:write(_buildJsonLabelControl('Configure the device Command Buttons on the Settings tab to complete configuration.',50,50,300,20,1,0,0) .. ',\n')
			else
				outf:write(_buildJsonLabelControl('Configure the harmony Activities on the Activities tab to define control buttons.',50,50,300,20,1,0,0) .. ',\n')
			end	
		end
		-- Add other UI elements
		tab = 1
		-- For UI5/6 we have a different JS UI file than later versions.
		local jsFile, jsPfx
		if IsUI7 then 
			jsFile = 'J_Harmony.js'
			jsPfx = 'Harmony.'
		else
			jsFile = 'J_Harmony_UI5.js' 
			jsPfx = 'ham' 
		end
		if isChild then
			top = 160
			if numBtn > 20 then top = top + 25 end
			outf:write(_buildJsonLabelControl('Controlling Hub:',top,50,100,20) .. ',\n')
			local tmpstr = _buildJsonVariableControl('HubName',top,200,80,20)
			outf:write(tmpstr:gsub('Harmony1','HarmonyDevice1') .. ',\n')
			top = top + 20
			outf:write(_buildJsonLabelControl('Last command:',top,50,100,20) .. ',\n')
			local tmpstr = _buildJsonVariableControl('LastDeviceCommand',top,200,80,20)
			outf:write(tmpstr:gsub('Harmony1','HarmonyDevice1') .. '')
			if isSonos then
				-- For Sonos player show album that is playing and current volume.
				outf:write(',\n')
				top = top + 30
				outf:write(_buildJsonLabelControl('Sonos',top,50,100,20) .. ',\n')
				top = top + 20
				outf:write(_buildJsonLabelControl('Status:',top,70,100,20) .. ',\n')
				local tmpstr = _buildJsonVariableControl('Status',top,200,100,20)
				outf:write(tmpstr:gsub('Harmony1','HarmonyDevice1') .. ',\n')
				top = top + 20
				outf:write(_buildJsonLabelControl('Volume:',top,70,100,20) .. ',\n')
				local tmpstr = _buildJsonVariableControl('Volume',top,200,100,20)
				outf:write(tmpstr:gsub('Harmony1','HarmonyDevice1') .. ',\n')
				top = top + 20
				outf:write(_buildJsonLabelControl('Artist:',top,70,100,20) .. ',\n')
				local tmpstr = _buildJsonVariableControl('Artist',top,200,100,20)
				outf:write(tmpstr:gsub('Harmony1','HarmonyDevice1') .. ',\n')
				top = top + 20
				outf:write(_buildJsonLabelControl('Title:',top,70,100,20) .. ',\n')
				local tmpstr = _buildJsonVariableControl('Title',top,200,100,20)
				outf:write(tmpstr:gsub('Harmony1','HarmonyDevice1') .. ',\n')
				top = top + 20
				outf:write(_buildJsonLabelControl('Album:',top,70,100,20) .. ',\n')
				local tmpstr = _buildJsonVariableControl('Album',top,200,100,20)
				outf:write(tmpstr:gsub('Harmony1','HarmonyDevice1') .. '')
			end
			outf:write('\n]},\n')
			outf:write(_buildJsonLabel('settings','Settings',true,tab,jsFile,jsPfx..'DeviceSettings'),',\n')
			tab = tab+1
		else
			top = 150
			if numBtn > 6 then top = top + 25 end
			outf:write(_buildJsonLabelControl('Change Channel:',top,50,100,20) .. ',\n')
			outf:write(_buildJsonInputControl('Change',top,200,30,20) .. ',\n')
			outf:write(_buildJsonButtonControl('Change','ChangeChannel','newChannel',top,250,80,20) .. ',\n')
			top = top + 30
			outf:write(_buildJsonLabelControl('Update Configuration:',top,50,100,20) .. ',\n')
			outf:write(_buildJsonButtonControl('Update','ForceUpdateConfiguration',nil,top,250,80,20) .. ',\n')
			top = top + 50
			outf:write(_buildJsonLabelControl('Hub name:',top,50,100,20) .. ',\n')
			outf:write(_buildJsonVariableControl('FriendlyName',top,200,150,20) .. ',\n')
			top = top + 20
			outf:write(_buildJsonLabelControl('Link Status:',top,50,100,20) .. ',\n')
			outf:write(_buildJsonVariableControl('LinkStatus',top,200,150,20) .. ',\n')
			top = top + 20
			outf:write(_buildJsonLabelControl('Current Activity ID :',top,50,100,20) .. ',\n')
			outf:write(_buildJsonVariableControl('CurrentActivityID',top,200,80,20) .. ',\n')
			top = top + 20
			outf:write(_buildJsonLabelControl('Last command:',top,50,100,20) .. ',\n')
			outf:write(_buildJsonVariableControl('LastCommand',top,200,80,20) .. ',\n')
			top = top + 20
			outf:write(_buildJsonLabelControl('Last command time:',top,50,100,20) .. ',\n')
			outf:write(_buildJsonVariableControl('LastCommandTime',top,200,80,20) .. ',\n')
			top = top + 20
			outf:write(_buildJsonLabelControl('Hub configuration version:',top,50,100,20) .. ',\n')
			outf:write(_buildJsonVariableControl('HubConfigVersion',top,200,80,20) .. ',\n')
			top = top + 20
			outf:write(_buildJsonLabelControl('Hub software version:',top,50,100,20) .. ',\n')
			outf:write(_buildJsonVariableControl('hubSwVersion',top,200,80,20) .. '\n')
			outf:write(']},\n')
			outf:write(_buildJsonLabel('settings','Settings',true,tab,jsFile,jsPfx..'Settings') ..',\n')
			tab = tab+1
			outf:write(_buildJsonLabel('activities','Activities',true,tab,jsFile,jsPfx..'Activities') ..',\n')
			tab = tab+1
			outf:write(_buildJsonLabel('devices','Devices',true,tab,jsFile,jsPfx..'Devices') ..',\n')
			tab = tab+1
		end
		outf:write(_buildJsonLabel('advanced','Advanced',false,tab,'shared.js','advanced_device') ..',\n')
		outf:write(_buildJsonLabel('logs','Logs',false,tab+1,'shared.js','device_logs') ..',\n')
		outf:write(_buildJsonLabel('notifications','Notifications',false,tab+2,'shared.js','device_notifications'))
		if IsUI7 then outf:write(',\n' .. _buildJsonLabel('ui7_device_scenes','Scenes',false,tab+3,'shared.js','device_scenes')) end
		outf:write('],\n')
		outf:write('"eventList2": [ \n')
		-- Add possible events if we have buttons as well.
		if numBtn > 0 then
			outf:write('{ "id": 1, "label": { "lang_tag": "act_id_ch", "text": ')
			if isChild then
				outf:write(format('"Device Command activated"}, "serviceId": "%s",\n',sid))
			else	
				outf:write(format('"Harmony Activity is changed to"}, "serviceId": "%s",\n',sid))
			end
			outf:write('"norepeat": "1","argumentList": [{ "id": 1, "dataType": "string", "allowedValueList": [\n')
			for i = 1, #buttons do
				log.Debug('Adding event %d, label %s' ,i,(buttons[i].Label or 'missing'))
				local lab = buttons[i].Label or 'missing'
				local val = buttons[i].ID or 'missing'
				local str = _buildJsonEvent(i,val,lab)
				if i < #buttons then str = str .. ',' end
				str = str .. '\n'
				outf:write(str)
			end	
			if isChild then
				outf:write('], "name": "LastDeviceCommand", "comparisson": "=", "prefix": { "lang_tag": "select_command", "text": "Select command : " }, "suffix": {} } ] }\n')
			else
				outf:write('], "name": "CurrentActivityID", "comparisson": "=", "prefix": { "lang_tag": "select_event", "text": "Select activity : " }, "suffix": {} } ] },\n')
				-- Event for starting activity. Precedes current activity
				outf:write(format('{ "id": 2, "label": { "lang_tag": "act_id_start", "text": "Harmony is starting Activity"}, "serviceId": "%s",\n',sid))
				outf:write('"norepeat": "1","argumentList": [{ "id": 1, "dataType": "string", "allowedValueList": [\n')
				for i = 1, #buttons do
					log.Debug('Adding event %d, label %s' ,i,(buttons[i].Label or 'missing'))
					local lab = buttons[i].Label or 'missing'
					local val = buttons[i].ID or 'missing'
					local str = _buildJsonEvent(i,val,lab)
					if i < #buttons then str = str .. ',' end
					str = str .. '\n'
					outf:write(str)
				end	
				outf:write('], "name": "StartingActivityID", "comparisson": "=", "prefix": { "lang_tag": "select_start_event", "text": "Select activity : " }, "suffix": {} } ] },\n')
				-- Event on activityStatus change
				outf:write(format('{ "id": 3, "label": { "lang_tag": "hub_status_change", "text": "The Hub status is changing"}, "serviceId": "%s",',sid))
				outf:write('"norepeat": "1","argumentList": [{ "id": 1, "dataType": "ui1", "defaultValue": "0", "allowedValueList": [')
				outf:write('{ "Off": "0", "HumanFriendlyText": { "text": "Whenever the _DEVICE_NAME_ is turned off" }},') 
				outf:write('{ "Starting": "1", "HumanFriendlyText": { "text": "Whenever an Activity is starting on _DEVICE_NAME_" }},')
				outf:write('{ "On": "2", "HumanFriendlyText": { "text": "Whenever an Activity is active on _DEVICE_NAME_" }},')
				outf:write('{ "Stopping": "3", "HumanFriendlyText": { "text": "Whenever the _DEVICE_NAME_ is turning off" }}')
				outf:write('], "name": "activityStatus", "comparisson": "=", "prefix": { "text": "Which status : " }, "suffix": {} } ] },\n')

				-- Event on SwitchPower Status
				outf:write('{ "id": 4, "label": { "lang_tag": "a_device_is_turned_on_off", "text": "A device is turned on or off"}, "serviceId": "urn:upnp-org:serviceId:SwitchPower1",')
				outf:write('"norepeat": "1","argumentList": [{ "id": 1, "dataType": "boolean", "defaultValue": "0", "allowedValueList": [')
				outf:write('{ "Off": "0", "HumanFriendlyText": { "lang_tag": "hft_device_turned_off", "text": "Whenever the _DEVICE_NAME_ is turned off" }},') 
				outf:write('{ "On": "1", "HumanFriendlyText": { "lang_tag": "hft_device_turned_on", "text": "Whenever the _DEVICE_NAME_ is turned on" }}')
				outf:write('], "name": "Status", "comparisson": "=", "prefix": { "lang_tag": "ui7_which_mode", "text": "Which mode : " }, "suffix": {} } ] }')
			end
		end	
		outf:write('],\n')
		if isChild then
			if IsUI7 then outf:write(format('"DeviceType": "urn:schemas-rboer-com:device:HarmonyDevice%s_%s:1",\n',Dev,devID)) end
			outf:write(format('"device_type": "urn:schemas-rboer-com:device:HarmonyDevice%s_%s:1"\n}\n',Dev,devID))
		else	
			if IsUI7 then outf:write(format('"DeviceType": "urn:schemas-rboer-com:device:Harmony%s:1",\n',devID)) end
			outf:write(format('"device_type": "urn:schemas-rboer-com:device:Harmony%s:1"\n}\n',devID))
		end
		return true
	end

	-- Create the new Static JSON and compress it unless on openLuup
	local function _create_JSON_file(devID,name,isChild,buttons,remicons,childDev,prnt_id,isSonos)
		local prnt
		if prnt_id then prnt = prnt_id..'_' else prnt = '' end
		local iconPath = locIconURI
		if remicons then iconPath = remIconURI end
		local jsonOut = FilePath..name..prnt..devID..'.json'
		local outf = io.open(jsonOut..'X', 'w')
		local ret = _writeJsonFile(devID,outf,iconPath,isChild,buttons,childDev,isSonos)
		outf:close()
		-- Only make new file when write was successful.
		if IsOpenLuup then 
			if ret then os.execute('cp '..jsonOut..'X '..jsonOut) end
		else	
			if ret then os.execute('pluto-lzo c '..jsonOut..'X '..jsonOut..'.lzo') end
		end	
		os.execute('rm -f '..jsonOut..'X')
	end

	-- Re-write the D_Harmony[Device].xml file to point to device specific Static JSON
	local function _create_D_file(devID,name,prnt_id)
		local prnt
		local outf
		if prnt_id then prnt = prnt_id..'_' else prnt = '' end
		local inpath = FilePath .. 'D_'..name..'.xml'
		local outpath = FilePath .. 'D_'..name..prnt..devID..'.xml'
		if IsOpenLuup then 
			outf = io.open(outpath..'X', 'w' )
		else	
			os.execute('pluto-lzo d '..inpath..'.lzo '..inpath)
			os.execute('rm -f '..outpath..'.lzo')
			outf = io.open(outpath, 'w' )
		end
		for l in io.lines(inpath) do
			l = string.gsub(l, '\r', '' )
			l = string.gsub(l, ':device:'..name..':', ':device:'..name..prnt..devID..':')
			l = string.gsub(l, 'D_'..name..'.json', 'D_'..name..prnt..devID..'.json')
			outf:write(l..'\n')
		end
		outf:close()
		if IsOpenLuup then
			os.execute('cp '..outpath..'X '..outpath)
			os.execute('rm -f '..outpath..'X')
		else	
			os.execute('pluto-lzo c '..outpath..' '..outpath..'.lzo')
			os.execute('rm -f '..outpath)
			os.execute('rm -f '..inpath)
		end	
	end

	-- Create CustomModeConfiguration value for preset House mode support.
	local function _createCustomModeConfiguration(devID, isChild, buttons)
		local id, lab, dur, sid, cmd, prm
		local retVal = nil
		if isChild then 
			sid = ChSid
			cmd = "/SendDeviceCommand"
			prm = "/Command="
		else 
			sid = Sid
			cmd = "/StartActivity"
			prm = "/newActivityID="
		end
		for i = 1, #buttons do
			local lab = buttons[i].Label or 'missing'
			local val = buttons[i].ID or 'missing'
			local str = ";" .. sid .. cmd .. prm .. val
			if luup.short_version then
				-- luup.short_version is new in UI7.30 and up so is good check
				-- 7.30 and up have lable and command as documented in wiki
				str = "CMD" .. val .. ";".. lab .. str
			else	
				str = lab .. ";CMD" .. val .. str
			end
			if i < #buttons then str = str .. '|' end
			retVal = (retVal or "") .. str
		end	
		return retVal
	end
	
	return {
		Initialize = _init,
		CreateDeviceFile = _create_D_file,
		CreateJSONFile = _create_JSON_file,
		RemoveObsoleteChildDeviceFiles = _removeObsoleteChildDeviceFiles,
		RemoveObsoleteDeviceFiles = _removeObsoleteDeviceFiles,
		CreateCustomModeConfiguration = _createCustomModeConfiguration
	}
end


---------------------------------------------------------------------------------------------
-- Harmony Plugin functions
---------------------------------------------------------------------------------------------
-- Check how much memory the plugin uses, and see if we should start/stop polling
function checkMemory()
	luup.call_delay("checkMemory", 600)
	var.Set("AppMemoryUsed", utils.GetMemoryUsed())
end

-- Set the status Icon
local function setStatusIcon(status, devID, sid)
	if (status == HData.Icon.OK) then
		-- When status is success, then clear after number of seconds
		local idleDelay = var.Get("OkInterval")
		if (tonumber(idleDelay) > 0) then
			var.Set(HData.Icon.Variable, HData.Icon.OK, sid, devID)
			luup.call_delay("idleStatusIcon", idleDelay, tostring(devID or ""), false)
		else
			var.Set(HData.Icon.Variable, HData.Icon.IDLE, sid, devID)
		end
	else	
		var.Set(HData.Icon.Variable, status, sid, devID)
	end
end
function idleStatusIcon(devIDstr)
	local devID
	if (devIDstr ~= "") then devID = tonumber(devIDstr) end
	local status = var.Get(HData.Icon.Variable, devID)
	-- When status is success, then clear else do not change
	if (status == HData.Icon.OK) then
		var.Set(HData.Icon.Variable, HData.Icon.IDLE, HData.SIDS.MODULE, devID)
	end
end
-- Set or clear Busy status.
local function SetBusy(status, setIcon)
	HData.Busy = status
	HData.BusyChange = os.time()
	if (status) then 
		if (setIcon) then setStatusIcon(HData.Icon.BUSY) end
		luup.call_delay("ClearBusy", 60, "", false)
	else
		if (setIcon) then setStatusIcon(HData.Icon.OK) end
	end
end
local function GetBusy()
	-- We are not waiting for all bits of the StartActivity command to return.
	-- So make sure we do not have any current jobs before we give the all clear.
	local res, stat = Harmony.GetJobStatus()
	if stat == JobStatus.IN_PROGRESS then 
--		log.Debug("GetBusy job IN_PROGRESS")
		return true, true 
	end
	return HData.Busy
end
-- See if Busy status has not changed for more than a minute. If so clear it as something went wrong.
function ClearBusy()
	if (HData.Busy) then
		if (os.difftime(os.time(), HData.BusyChange) > 60) then 
			SetBusy(false,true) 
		else
			luup.call_delay("ClearBusy", 30, "", false)
		end	
	end	
end
-- Find the Child device ID for the Harmony DeviceID
local function Harmony_FindDevice(deviceID)
	for k, v in pairs(luup.devices) do
		if var.GetAttribute('id_parent', k) == HData.DEVICE then
			local dev = var.GetNumber("DeviceID",HData.SIDS.CHILD,k)
			if dev == deviceID then return k end
		end
	end
	return nil
end
-- Find the Child device ID for the Harmony Lamp UDN
local function Harmony_FindLamp(udn)
	for k, v in pairs(luup.devices) do
		if var.GetAttribute('id_parent', k) == HData.DEVICE then
			local dev = var.Get("UDN",HData.SIDS.CHILD,k)
			if dev == udn then return k end
		end
	end
	return nil
end


-- Update the last command sent to Hub and when. If cmd is nil then signal an error.
local function SetLastCommand(cmd)
	if cmd then
		var.Set("LinkStatus","Ok")
		var.Set("LastCommand", cmd)
		var.Set("LastCommandTime", os.date("%X %a, %d %b %Y"))
	else
		var.Set("LinkStatus","Error")
	end
end

-- Update the plugin activity parameters just started
local function UpdateCurrentActivity(actID)
	var.Set("CurrentActivityID", actID)
	-- Set the target and status so we can show off/on on Vera App
	if (tonumber(actID) ~= -1) then 
		var.Set("Target", "1", HData.SIDS.SP)
		var.Set("Status", "1", HData.SIDS.SP)
	else 
		var.Set("Target", "0", HData.SIDS.SP)
		var.Set("Status", "0", HData.SIDS.SP)
	end
end

-- Find the activity with the name and return the matching actibity ID
function Harmony_FindActivityByName(name)
	if name then
		-- If we get a number, then assume it is an ID already
		if tonumber(name,10) then 
			var.Set("findResult", name)  -- Need variable to have return value in call_action
			return true, name 
		end
		local data = json.decode(var.Get("Activities"))
		for i=1,#data.activities do
			if data.activities[i].Activity == name then
				var.Set("findResult", data.activities[i].ID)  -- Need variable to have return value in call_action
				return true, data.activities[i].ID
			end
		end 
	end	
	var.Set("findResult", "")  -- Need variable to have return value in call_action
	return false, ""
end

-- Find the activity with the id and return the matching activity name
function Harmony_FindActivityByID(id)
	if id then
		local data = json.decode(var.Get("Activities"))
		for i=1,#data.activities do
			if data.activities[i].ID == id then
				var.Set("findResult", data.activities[i].Activity)  -- Need variable to have return value in call_action
				return true, data.activities[i].Activity
			end
		end 
	end	
	var.Set("findResult", "")  -- Need variable to have return value in call_action
	return false, ""
end

-- Find the device with the name and return the matching device ID
function Harmony_FindDeviceByName(name)
	if name then
		-- If we get a number, then assume it is an ID already
		if tonumber(name,10) then 
			var.Set("findResult", name)  -- Need variable to have return value in call_action
			return true, name 
		end
		local data = json.decode(var.Get("Devices"))
		for i=1,#data.devices do
			if data.devices[i].Device == name then
				var.Set("findResult", data.devices[i].ID)  -- Need variable to have return value in call_action
				return true, data.devices[i].ID
			end
		end 
	end	
	var.Set("findResult", "")  -- Need variable to have return value in call_action
	return false, ""
end

-- Find the device with the id and return the matching device name
function Harmony_FindDeviceByID(id)
	if id then
		local data = json.decode(var.Get("Devices"))
		for i=1,#data.devices do
			if data.devices[i].ID == id then
				var.Set("findResult", data.devices[i].Device)  -- Need variable to have return value in call_action
				return true, data.devices[i].Device
			end
		end 
	end	
	var.Set("findResult", "")  -- Need variable to have return value in call_action
	return false, ""
end

-- Find the sequecene with the name and return the matching sequecene ID
function Harmony_FindSequenceByName(name)
	if name then
		-- If we get a number, then assume it is an ID already
		if tonumber(name,10) then 
			var.Set("findResult", name)  -- Need variable to have return value in call_action
			return true, name 
		end
		local data = json.decode(var.Get("Sequences"))
		for i=1,#data.sequences do
			if data.sequences[i].Name == name then
				var.Set("findResult", data.sequences[i].ID)  -- Need variable to have return value in call_action
				return true, data.sequences[i].ID
			end
		end 
	end	
	var.Set("findResult", "")  -- Need variable to have return value in call_action
	return false, ""
end

-- Find the sequecene with the id and return the matching sequecene name
function Harmony_FindSequenceByID(id)
	if id then
		local data = json.decode(var.Get("Sequences"))
		for i=1,#data.sequences do
			if data.sequences[i].ID == id then
				var.Set("findResult", data.sequences[i].Name)  -- Need variable to have return value in call_action
				return true, data.sequences[i].Name
			end
		end 
	end	
	var.Set("findResult", "")  -- Need variable to have return value in call_action
	return false, ""
end

-- Update the log level.
function Harmony_SetLogLevel(logLevel)
	local level = tonumber(logLevel,10) or 10
	var.Set("LogLevel", level)
	log.Update(level)
end

-- Update the Remote Images setting. When changed force a reload.
function Harmony_SetRemoteImages(remoteImages)
	local ri = tonumber(remoteImages,10) or 0
	local remicons = var.GetNumber("RemoteImages")
	if ri ~= remicons then
		var.Set("RemoteImages", ri)
		var.Set("LinkStatus","Restarting...")
		Harmony.Close()
		utils.ReloadLuup()
	end
end

-- Update the polling flag. If called with "1" then the connection with the Hub will be kept open, else it will close after each command.
-- If Polling is on and turned off, wait for the hub to be off (current activity == -1)
function Harmony_SetHubPolling(poll_flg)
	local pf = tonumber(poll_flg,10) or 0
--log.LogFile("Entering Harmony_SetHubPolling with value %s.",tostring(pf))
	local change_poll = true
	pf = (pf == 1)
	if (not pf) and Harmony.GetHubPolling() then
		-- Want turn off polling, make sure all is powerd off.
		local actid = var.GetNumber("CurrentActivityID")
		if actid ~= -1 then
			change_poll = false
			-- retry in a minute
			luup.call_delay("Harmony_SetHubPolling", 60, "0")
			log.Debug("Hub still on, so post pone polling stop.")
		end	
	end
	if change_poll then
--log.LogFile("Changing polling to value %s.",tostring(pf))
		Harmony.SetHubPolling(pf)
		if pf then
			log.Debug("Turning on polling")
			var.Set("HubPolling", 1)
		else	
			log.Debug("Turning off polling")
			var.Set("HubPolling", 0)
		end	
	end	
end

-- Get the latest configuration from the Hub and update our internals
function Harmony_UpdateConfigurations()
	if (GetBusy()) then 
		log.Warning("UpdateConfigurations communication is busy")
		return nil, nil, 307,"Communication is busy."
	end
	SetBusy(true, true)
	local res, data, cde, msg = Harmony.GetConfig()
	if res then
		local data = data.data
		local dataTab = {}
		-- Get activities
		dataTab.activities = {}
		log.Debug("Number of activities found : %d.",#data.activity)
		for i = 1, #data.activity do
			dataTab.activities[i] = {}
			dataTab.activities[i].ID = data.activity[i].id
			dataTab.activities[i].Activity = data.activity[i].label
		end
		var.Set("Activities", json.encode(dataTab))
		dataTab = nil

		-- Get devices 
		dataTab = {}
		dataTab.devices = {}
		log.Debug("Number of devices found : %d.",#data.device)
		for i = 1, #data.device do
			dataTab.devices[i] = {}
			dataTab.devices[i].ID = data.device[i].id
			dataTab.devices[i].Device = data.device[i].label
			dataTab.devices[i].Model = data.device[i].model
			dataTab.devices[i].Manufacturer = data.device[i].manufacturer
		end
		var.Set("Devices", json.encode(dataTab))
		dataTab = nil
		-- Get commands for child devices
		for k, v in pairs(luup.devices) do
			if var.GetAttribute ('id_parent', k ) == HData.DEVICE then
				local devID = var.Get("DeviceID", HData.SIDS.CHILD, k)
				log.Debug("Found child device with id %s, get commands...",devID)
				dataTab = {}
				dataTab.Functions = {}
				-- List all commands supported by given device grouped by function
				for i = 1, #data.device do
					if (data.device[i].id == devID) then
						dataTab.ID = data.device[i].id
						dataTab.Device = data.device[i].label
						-- Store URI for DigitalMediaServer (= Sonos)
-- to do Sonos channel desciptions						
--						if data.device[i].['type'] == "DigitalMusicServer" then
--							dataTab.deviceProfileUri = data.device[i].deviceProfileUri
--						end
						dataTab.Functions = {}
						for j = 1, #data.device[i].controlGroup do
							dataTab.Functions[j] = {}
							dataTab.Functions[j].Function = data.device[i].controlGroup[j].name
							dataTab.Functions[j].Commands = {}
							for x = 1, #data.device[i].controlGroup[j]['function'] do
								dataTab.Functions[j].Commands[x] = {}
								dataTab.Functions[j].Commands[x].Label = data.device[i].controlGroup[j]['function'][x].label
								dataTab.Functions[j].Commands[x].Name = data.device[i].controlGroup[j]['function'][x].name
								dataTab.Functions[j].Commands[x].Action = json.decode(data.device[i].controlGroup[j]['function'][x].action).command
							end
						end	
						var.Set("DeviceCommands", json.encode(dataTab),HData.SIDS.CHILD, k )
						break
					end	
				end
			end
		end	
		dataTab = nil
		-- Get sequences
		dataTab = {}
		dataTab.sequences = {}
		log.Debug("Number of sequences found : %d.",#data.sequence)
		for i = 1, #data.sequence do
			dataTab.sequences[i] = {}
			dataTab.sequences[i].ID = data.sequence[i].id
			dataTab.sequences[i].Name = data.sequence[i].name
		end
		var.Set("Sequences", json.encode(dataTab))
		dataTab = nil
		-- Content, used for cmd proxy.resource?get
		if data.content.householdUserProfileUri then
			var.Set("householdUserProfileUri", data.content.householdUserProfileUri)
		end
	else
		log.Error("Failed to get new configuration from Hub. Error : %d, %s.",cde, msg or "")
	end
	-- See if we have automation devices, we can support Hue lights
	local res, data, cde, msg = Harmony.GetAutomationConfig()
	local lamps = "-"
	if res then
		local rsrc = data.data.resource
		if rsrc then
			-- Get lamp devices.
			local dataTab = {}
			dataTab.lamps = {}
			for id, dt in pairs(rsrc.devices) do
				if dt.type == "lamp" then
					-- Get lamp devices
					log.Debug("Found lamp : %s, %s.",id,dt.name)
					local i = #dataTab.lamps+1
					dataTab.lamps[i] = {}
					dataTab.lamps[i].udn = id
					dataTab.lamps[i].name = dt.name
					dataTab.lamps[i].model = dt.model
					dataTab.lamps[i].manufacturer = dt.manufacturer
					dataTab.lamps[i].capabilities = dt.capabilities
				end
			end
			lamps = json.encode(dataTab)
			if #dataTab.lamps == 0 then
				log.Log("Did not find any lamp resources.")
			end
		else	
			log.Log("Did not find any automation resources.")
		end
	else
		log.Error("Failed to get new automation configuration from Hub. Error : %d, %s.",cde, msg or "")
	end
	var.Set("Lamps", lamps)
	SetBusy(false, true)
	if res then
		SetLastCommand("GetConfig")
	else
		SetLastCommand()
	end
	return res, "", cde, msg
end

-- Get Config stored, refresh is needed
function Harmony_GetConfig(cmd, id, devID)
	log.Debug("GetConfig "..cmd)
	
	if (HData.Plugin_Disabled == true) then
		log.Warning("GetConfig : Plugin disabled.")
		return nil, nil, 503, "Plugin disabled."
	end
	-- See what part we need to return
	if (cmd == 'list_activities') then 
		-- See if we have the activities
		local activities = var.Get("Activities")
		if activities == "" then 
			-- Nope update them, update will store in variable
			local res, data, cde, msg = Harmony_UpdateConfigurations()
			if res then 
				activities = var.Get("Activities")
			end
		end
		if activities ~= "" then 
			return true, json.decode(activities)
		else
			return nil, nil, 404, "No activities found."
		end	
	elseif (cmd == 'list_devices') then 
		local devices = var.Get("Devices")
		if devices == "" then
			-- Nope update them, update will store in variable
			local res, data, cde, msg = Harmony_UpdateConfigurations()
			if res then 
				devices = var.Get("Devices")
			end
		end	
		if devices ~= "" then
			return true, json.decode(devices)
		else
			return nil, nil, 404, "No devices found."
		end	
	elseif (cmd == 'list_lamps') then 
		local lamps = var.Get("Lamps")
		if lamps == "" or lamps == "-" then
			-- Nope update them, update will store in variable
			local res, data, cde, msg = Harmony_UpdateConfigurations()
			if res then 
				lamps = var.Get("Lamps")
			end
		end	
		if lamps ~= "" and lamps ~= "-" then
			return true, json.decode(lamps)
		else
			return nil, nil, 404, "No lamps found."
		end	
	elseif (cmd == 'list_device_commands') then
		-- if we do net get the vera device ID but Hub device ID then search for vera one.
		if not devID then
			local altid = 'HAM'..HData.DEVICE..'_'..id
			for k, v in pairs(luup.devices) do
				if v.id == altid then
					devID = k
					break
				end
			end
			log.Debug("Looked up missing devID for %s, found %s",tostring(id),tostring(devID or "nil"))
		end
		local commands = ""
		if not devID then
			log.Debug("No child device found, getting full config for device %s",tostring(id))
			-- Not a child device, do direct request and lookup.
			-- Is dup of part of Harmony_UpdateConfigurations
			local res, data, cde, msg = Harmony.GetConfig()
			if res then
				local data = data.data
				local dataTab = nil
				SetLastCommand("GetConfig")
				dataTab = {}
				dataTab.Functions = {}
				-- List all commands supported by given device grouped by function
				for i = 1, #data.device do
					if (data.device[i].id == id) then
						dataTab.ID = data.device[i].id
						dataTab.Device = data.device[i].label
						-- Store URI for DigitalMediaServer (= Sonos)
-- to do Sonos channel desciptions						
--						if data.device[i].['type'] == "DigitalMusicServer" then
--							dataTab.deviceProfileUri = data.device[i].deviceProfileUri
--						end
						dataTab.Functions = {}
						for j = 1, #data.device[i].controlGroup do
							dataTab.Functions[j] = {}
							dataTab.Functions[j].Function = data.device[i].controlGroup[j].name
							dataTab.Functions[j].Commands = {}
							for x = 1, #data.device[i].controlGroup[j]['function'] do
								dataTab.Functions[j].Commands[x] = {}
								dataTab.Functions[j].Commands[x].Label = data.device[i].controlGroup[j]['function'][x].label
								dataTab.Functions[j].Commands[x].Name = data.device[i].controlGroup[j]['function'][x].name
								dataTab.Functions[j].Commands[x].Action = json.decode(data.device[i].controlGroup[j]['function'][x].action).command
							end
						end	
						commands = json.encode(dataTab)
						break
					end
				end
			end
		else
			-- See if child device has the current config
			commands = var.Get("DeviceCommands",HData.SIDS.CHILD,devID)
			if commands == "" then
				-- Nope update them, update will store in variable
				local res, data, cde, msg = Harmony_UpdateConfigurations()
				if res then 
					commands = var.Get("DeviceCommands",HData.SIDS.CHILD,devID)
				end
			end	
		end	
		if commands ~= "" then
			return true, json.decode(commands)
		else
			return nil, nil, 404, "No commands found."
		end	
	elseif (cmd == 'get_config') then
		-- List full configuration, we do not store it, so no known version.
		SetLastCommand("GetConfig")
		local res, data, cde, msg = Harmony.GetConfig()
		if not res then 
			SetLastCommand() 
		end
		return res, data, cde, msg
	end
end

-- Send IssueSequenceCommand to Harmony Hub
-- Input: sequenceID = sequence ID
-- Output: True on success
function Harmony_IssueSequenceCommand(seq)
	if (HData.Plugin_Disabled == true) then
		log.Warning("IssueSequenceCommand : Plugin disabled.")
		return nil, nil, 503,"Plugin disabled."
	end
	if (GetBusy()) then 
		log.Warning("IssueSequenceCommand communication is busy")
		return nil, nil, 307,"Communication is busy."
	end
	local dur = tonumber(devDur) or 0
	if (seq ~= "") then 
		SetBusy(true, true)
		local res1, sequenceId = Harmony_FindSequenceByName(seq)
		local res, data, cde, msg = nil, nil, 404, ""
		log.Debug("IssueSequenceCommand, sequenceID : %s.",sequenceId)
		if res1 then
			res, data, cde, msg = Harmony.IssueSequenceCommand(sequenceId)
			if res then
				SetLastCommand("IssueSequenceCommand")
			end	
		else
			cde = 404
			msg = "not a valid sequenceID: "..(seq or "missing")
		end
		SetBusy(false, true)
		return res, data, cde, msg
	else
		return nil, nil, 404, "no SequenceID specified"
	end	
end

-- Send IssueDeviceCommand to Harmony Hub
-- Input: devID = device ID, devCmd = device Command, devDur = key-press duration in seconds
-- Output: True on success
function Harmony_IssueDeviceCommand(dev, devCmd, devDur)
	if (HData.Plugin_Disabled == true) then
		log.Warning("IssueDeviceCommand : Plugin disabled.")
		return nil, nil, 503,"Plugin disabled."
	end
	if (GetBusy()) then 
		log.Warning("IssueDeviceCommand communication is busy")
		return nil, nil, 307,"Communication is busy."
	end
	local dur = tonumber(devDur) or 0
	if ((dev ~= "") and (devCmd ~= "")) then 
		SetBusy(true, true)
		local res1, devID = Harmony_FindDeviceByName(dev)
		local res, data, cde, msg = nil, nil, 404, ""
		if res1 then
			log.Debug("IssueDeviceCommand, devID : %s, Cmd %s, Dur %s.",devID,devCmd,dur)
			res, data, cde, msg = Harmony.IssueDeviceCommand(devID, devCmd, dur, 'press')
			if res then
				SetLastCommand("IssueDeviceCommand")
			end	
		else
			cde = 404
			msg = "not a valid device: "..(dev or "missing")
		end
		SetBusy(false, true)
		return res, data, cde, msg
	else
		return nil, nil, 404, "no DeviceID and/or Command specified"
	end	
end

-- Send GetCurrentActivtyID to Harmony Hub
-- Output: Activity ID on success
function Harmony_GetCurrentActivtyID()
	if (HData.Plugin_Disabled == true) then
		log.Warning("GetCurrentActivtyID : Plugin disabled.")
		return nil, nil, 503,"Plugin disabled."
	end
	if (GetBusy()) then 
		log.Warning("GetCurrentActivity communication is busy")
		return nil, nil, 307,"Communication is busy."
	end
	log.Debug("GetCurrentActivtyID: Start")
	SetBusy(true, true)
	local res, data, cde, msg = Harmony.GetCurrentActivtyID()
	if res then
		if (tonumber(data)) then
			log.Debug("GetCurrentActivtyID found activity : %s.",data)
			UpdateCurrentActivity(data)
			local dataTab = {}
			dataTab.status = HData.OK
			dataTab.currentActivityID = data
			local res1, act = Harmony_FindActivityByID(data)
			if res1 then
				dataTab.currentActivityLabel = act
			else
				dataTab.currentActivityLabel = ""
			end
			SetLastCommand("GetCurrentActivtyID")
		else
			res = nil
			data = nil
			msg = "Returned Activity is not a number."
			cde = 500
		end	
	else
		log.Error("GetCurrentActivtyID failed, %d, %s.",cde,msg) 
	end
	SetBusy(false, true)
	return res, data, cde, msg
end

-- Send GetStateDigest to Harmony Hub
-- Output: Activity ID on success
function Harmony_GetStateDigest()
	if (HData.Plugin_Disabled == true) then
		log.Warning("GetStateDigest : Plugin disabled.")
		return nil, nil, 503,"Plugin disabled."
	end
	if (GetBusy()) then 
		log.Warning("GetStateDigest communication is busy")
		return nil, nil, 307,"Communication is busy."
	end
	log.Debug("GetStateDigest: Start")
	SetBusy(true, true)
	local res, data, cde, msg = Harmony.GetStateDigest()
	if res then
	else
		log.Error("GetCurrentActivtyID failed, %d, %s.",cde,msg) 
	end
	SetBusy(false, true)
	return res, data, cde, msg
end

-- Send StartActivity to Harmony Hub
-- Input: actID = activity ID
-- Output: True on success, on failure with data on details
function Harmony_StartActivity(act)
	if (HData.Plugin_Disabled == true) then
		log.Warning("StartActivity : Plugin disabled.")
		return nil, nil, 503,"Plugin disabled."
	end
	if (GetBusy()) then 
		log.Warning("StartActivity communication is busy")
		return nil, nil, 307,"Communication is busy."
	end
	local act = act or ""
	log.Debug("StartActivity, newActivityID : %s.",act)
	if (act ~= "") then 
		local res, data, cde, msg = nil, nil, 404, ""
		SetBusy(true, true)
		local res1, aid = Harmony_FindActivityByName(act)
		if not res1 then
			message = "not a valid Activity " .. act
		else
			res, data, cde, msg = Harmony.StartActivity(aid)
			if res then
				UpdateCurrentActivity(aid)
				SetLastCommand("StartActivity")
			else
				log.Error("StartActivity, ERROR %d, %s.",cde,msg)
			end	
		end	
		SetBusy(false,true)
		return res, data, cde, msg
	else
		return nil, nil, 404, "no newActivityID specified"
	end	
end

-- Send Activity -1 (PowerOff) to Harmony Hub
-- Output: True on success, on failure with data on details
function Harmony_PowerOff()
	if (HData.Plugin_Disabled == true) then
		log.Warning("PowerOff : Plugin disabled.")
		return nil, nil, 503,"Plugin disabled."
	end
	if (GetBusy()) then 
		log.Warning("PowerOff, communication is busy")
		return nil, nil, 307,"Communication is busy."
	end
	SetBusy(true, true)
	local res, data, cde, msg = Harmony.StartActivity(-1)
	if res then
		UpdateCurrentActivity(-1)
		SetLastCommand("PowerOff")
	else
		log.Error("PowerOff, ERROR %d, %s.",cde,msg)
	end	
	SetBusy(false,true)
	return res, data, cde, msg
end

-- Update the Vera status based on status report from Hub.
local function Harmony_UpdateLampStatus(chdev, data)
	-- Set current status
	local dv = data
	if dv then
		log.Debug("UpdateLampStatus; device %d, %s", chdev, json.encode(dv))
		local status = (dv.on == true) and 1 or 0
		local bri = math.ceil(100*(dv.brightness or 0)/255)
		if (not dv.on) then bri = 0 end
		var.Set("Target", status, HData.SIDS.SP, chdev)
		var.Set("Status", status, HData.SIDS.SP, chdev)
		if (dv.on) then var.Set("LoadLevelLast", bri, HData.SIDS.DIM, chdev) end
		var.Set("LoadLevelTarget", bri, HData.SIDS.DIM, chdev)
		var.Set("LoadLevelStatus", bri, HData.SIDS.DIM, chdev)
		local usw = var.GetNumber("UserSuppliedWattage", HData.SIDS.EM, chdev)
		if usw > 0 then var.Set("Watts", (usw * bri) / 100, HData.SIDS.EM, chdev) end
		if dv.color then
			local w,d,r,g,b=0,0,0,0,0
			if dv.color.mode == "xy" then
				r,g,b = utils.CieToRgb(dv.color.xy.x,dv.color.xy.y,(dv.on and dv.brightness) or nil)
			elseif dv.color.mode == "hs" then
				r,g,b = utils.HsbToRgb(dv.color.hueSat.hue,dv.color.hueSat.sat,dv.brightness)
			elseif dv.color.mode == "ct" then
				log.Warning("LampGetState unknown color mode %s.",json.encode(dv.color))
				w = -1
			else
				log.Warning("LampGetState unknown color mode %s.",json.encode(dv.color))
				w = -1
			end
			if w ~= -1 then
				var.Set("CurrentColor", string.format("0=%s,1=%s,2=%s,3=%s,4=%s",w,d,r,g,b), HData.SIDS.COL, chdev)
			end	
		end
	else
		log.Warning("UpdateLampStatus; No data.")
	end
end

-- Find lamp details, and send command
local function Harmony_LampSetState(chdev, pars)
	local udn = var.Get("UDN", HData.SIDS.CHILD, chdev)
	local params = string.format('{"state":{"%s":%s}}',udn,pars)
	return Harmony.SetAutomationState(params)
end

-- Request current state from the configured Lamp devices and update Child devices details.
local function Harmony_LampGetStates()
	-- Build configured UDN list
	local childLampUdns = var.Get("PluginHaveLamps")
	if childLampUdns ~= "" then
		local udnList = ""
		childLampUdns = childLampUdns..','
		for udn in childLampUdns:gmatch("([^,]*),") do
			udnList = udnList..',"'..udn..'"'
		end
		local params = string.format('{"deviceIds":[%s],"forceUpdate":true}',udnList:sub(2))
		local res, data, cde, msg = Harmony.GetAutomationState(params)
		if res then
			local dv = data.data
			if dv then
				log.Debug("LampGetState %s", json.encode(dv))
				for udn, dt in pairs(dv) do
					local chdev = Harmony_FindLamp(udn)
					if chdev then
						Harmony_UpdateLampStatus(chdev,dt)
					else
						log.Log("LampGetState unconfigured automation device %s.",udn)
					end
				end		
			else
				log.Warning("LampGetState no data in response %s",tostring(data))
			end
		else
			log.Warning("LampGetState error in response %d, %s",cde,msg)
		end
	else
		log.Log("LampGetState; no Lamps configured.")
	end	
end

-- Send Lamp SetTarget to Harmony Hub. Thanks amg0.
function Harmony_LampSetTarget(chdev,newTarget)
	if (HData.Plugin_Disabled == true) then
		log.Warning("SetTarget : Plugin disabled.")
		return nil, nil, 503,"Plugin disabled."
	end
	if (GetBusy()) then 
		log.Warning("SetTarget communication is busy")
		return nil, nil, 307,"Communication is busy."
	end
	newTarget = tonumber(newTarget) or 0
	log.Debug("SetTarget for %s, newTarget %s",chdev,newTarget)
	SetBusy(true, true)
	local res, data, cde, msg
	if (luup.devices[chdev].device_type == "urn:schemas-upnp-org:device:BinaryLight:1") then
		if newTarget ~= 0 then newTarget = 1 end
		if not Harmony.GetHubPolling() then
			-- If polling is active, the callback handler wil do this
			var.Set("Target", newTarget, HData.SIDS.SP, chdev)
			var.Set("Status", newTarget, HData.SIDS.SP, chdev)
		end	
		res, data, cde, msg = Harmony_LampSetState(chdev,string.format('{"on": %s}',tostring(newTarget > 0)))
		if res then
			SetLastCommand("SetTarget")
		else
			log.Error("SetTarget, ERROR %d, %s.",cde,msg)
		end	
		SetBusy(false,true)
	else
		-- See if we have a last target, if not, go to 100%
		local newLoadLevelTarget = var.GetNumber("LoadLevelLast", HData.SIDS.DIM, chdev)
		if newLoadLevelTarget == 0 then newLoadLevelTarget = 100 end
		res, data, cde, msg = Harmony_LampSetLoadLevelTarget(chdev, (newTarget>0) and newLoadLevelTarget or 0,true)
	end
	return true
end

-- Send Lamp SetLoadLevelTarget to Harmony Hub. Thanks amg0.
-- Note that Vera might send on/off to here directly for dimmer device types.
function Harmony_LampSetLoadLevelTarget(chdev,newLoadLevelTarget,chainedCall)
	if not chainedCall then
		if (HData.Plugin_Disabled == true) then
			log.Warning("SetLoadLevelTarget : Plugin disabled.")
			return nil, nil, 503,"Plugin disabled."
		end
		if (GetBusy()) then 
			log.Warning("SetLoadLevelTarget communication is busy")
			return nil, nil, 307,"Communication is busy."
		end
		SetBusy(true, true)
	end	
	log.Debug("SetLoadLevelTarget for %s, newLoadLevelTarget %s",chdev,newLoadLevelTarget)
	newLoadLevelTarget = tonumber(newLoadLevelTarget)
	local res, data, cde, msg
	local status = var.GetNumber("LoadLevelStatus", HData.SIDS.DIM, chdev)
	if (status ~= newLoadLevelTarget) then
		local bri = math.floor(255*newLoadLevelTarget/100)
		if (bri == 0)  then
			res, data, cde, msg = Harmony_LampSetState(chdev,'{"on":false}')
		else
			local val = (newLoadLevelTarget ~= 0) 
			if not Harmony.GetHubPolling() then
				-- If polling is active, the callback handler wil do this
				var.Set("LoadLevelLast", newLoadLevelTarget, HData.SIDS.DIM, chdev)
				var.Set("LoadLevelTarget", newLoadLevelTarget, HData.SIDS.DIM, chdev)
				var.Set("LoadLevelStatus", newLoadLevelTarget, HData.SIDS.DIM, chdev)
				var.Set("Target", val and "1" or "0", HData.SIDS.SP, chdev)
				var.Set("Status", val and "1" or "0", HData.SIDS.SP, chdev)
			end	
			res, data, cde, msg = Harmony_LampSetState(chdev,string.format('{"on":%s,"brightness":%d}',tostring(val),bri))
		end
		if res then
			SetLastCommand("SetLoadLevelTarget")
		else
			log.Error("SetLoadLevelTarget, ERROR %d, %s.",cde,msg)
		end	
	else
		-- No changes
		log.Debug("SetLoadLevelTarget no change")
	end
	SetBusy(false,true)
	return true
end

-- Send Lamp SetColorRGB to Harmony Hub. Thanks amg0.
function Harmony_LampSetColorRGB(chdev,newRGBColor)
	if (HData.Plugin_Disabled == true) then
		log.Warning("SetColorRGB : Plugin disabled.")
		return nil, nil, 503,"Plugin disabled."
	end
	if (GetBusy()) then 
		log.Warning("SetColorRGB communication is busy")
		return nil, nil, 307,"Communication is busy."
	end
	SetBusy(true, true)
	local parts = utils.Split(newRGBColor)
	local x,y = utils.RgbToCie(parts[1], parts[2], parts[3])
	local on = (var.GetNumber("Status", HData.SIDS.SP, chdev) == 1)
	log.Debug("SetColorRGB for %s, newRGBColor %s => x:%s y:%s",chdev,newRGBColor, tostring(x), tostring(y))
	local newValue = var.Get("LoadLevelStatus", HData.SIDS.DIM, chdev)
	local bri = math.floor(255*newValue/100)
	local params = string.format('{"color":{"xy":{"x":%1.4f,"y":%1.4f},"mode":"xy"}}',x,y)
	local res, data, cde, msg = Harmony_LampSetState(chdev,params)
	if res then
		SetLastCommand("SetColorRGB")
	else
		log.Error("SetColorRGB, ERROR %d, %s.",cde,msg)
	end	
	SetBusy(false,true)
	return res, data, cde, msg
end

-- Send Lamp SetColor to Harmony Hub. Thanks amg0.
function Harmony_LampSetColor(chdev,newColor)
	if (HData.Plugin_Disabled == true) then
		log.Warning("SetColor : Plugin disabled.")
		return nil, nil, 503,"Plugin disabled."
	end
	if (GetBusy()) then 
		log.Warning("SetColor communication is busy")
		return nil, nil, 307,"Communication is busy."
	end
	log.Debug("SetColor for %s, newColor %s",chdev,newColor)
	SetBusy(true, true)
	local on = (var.GetNumber("Status", HData.SIDS.SP, chdev) == 1)
	local warmcool = string.sub(newColor, 1, 1)
	local value = tonumber(string.sub(newColor, 2))
	local kelvin = math.floor((value*3500/255)) + ((warmcool=="D") and 5500 or 2000)
	local mired = math.floor(1000000/kelvin)
	local newValue = var.Get("LoadLevelStatus", HData.SIDS.DIM, chdev)
	local bri = math.floor(255*newValue/100)
	log.Debug("UserSetColor target: %s => bri:%s ct:%s",newColorTarget,bri,mired)
	local res, data, cde, msg = Harmony_LampSetState(chdev,string.format('{"ct":%s}', mired))
	if res then
		SetLastCommand("SetColor")
	else
		log.Error("SetColor, ERROR %d, %s.",cde,msg)
	end	
	SetBusy(false,true)
	return res, data, cde, msg
end

-- Send ChangeChannel to Harmony Hub
-- Input: newChannel = new Channel number to select
-- Output: True on success, or JSON when called from HTTPhandler
function Harmony_ChangeChannel(newChannel)
	if (HData.Plugin_Disabled == true) then
		log.Warning("ChangeChannel : Plugin disabled.")
		return nil, nil, 503,"Plugin disabled."
	end
	if (GetBusy()) then 
		log.Warning("ChangeChannel communication is busy")
		return nil, nil, 307,"Communication is busy."
	end
	local chnl = newChannel or ""
	log.Debug("ChangeChannel, newChannel : %s.",chnl)
	if (chnl ~= "") then 
		SetBusy(true, true)
		-- Set value now to give quicker user feedback on UI
		local res, data, cde, msg = Harmony.ChangeChannel(chnl)
		if res then
			SetLastCommand("ChangeChannel")
		else
			log.Error("ChangeChannel, ERROR %d, %s.",cde,msg)
		end	
		SetBusy(false,true)
		return res, data, cde, msg
	else
		return nil, nil, 404, "no newChannel specified"
	end	
end

-- Send a key-press comamnd from a child device that maps to a Hub device.
--  devDur = key-press duration in seconds
function Harmony_SendDeviceCommand(lul_device,devCmd,devDur)
	if (HData.Plugin_Disabled == true) then
		log.Warning("SendDeviceCommand : Plugin disabled.")
		return nil, nil, 503,"Plugin disabled."
	end
	local cmd = (devCmd or "")
	local dur = (devDur or "0")
	local devID = var.Get("DeviceID", HData.SIDS.CHILD, lul_device)
	local prevCmd = var.Get("LastDeviceCommand", HData.SIDS.CHILD, lul_device)
	log.Debug("SendDeviceCommand "..cmd.." for device #"..lul_device.." to Harmony Device "..devID.." holding down for "..dur)
	var.Set("LastDeviceCommand", cmd, HData.SIDS.CHILD, lul_device)
	local starttime = os.time()
	setStatusIcon(HData.Icon.BUSY, lul_device, HData.SIDS.CHILD)
	local res, data, cde, msg = Harmony_IssueDeviceCommand(devID, cmd, dur)
	if res then
		-- see if user want to show the button status for a tad longer
		local idleDelay = var.GetNumber("OkInterval")
		if (idleDelay > 0) then
			luup.call_delay('Harmony_SendDeviceCommandEnd',idleDelay, tostring(lul_device))
		else
			setStatusIcon(HData.Icon.IDLE, lul_device, HData.SIDS.CHILD)
			var.Set("LastDeviceCommand", "", HData.SIDS.CHILD, lul_device)
		end
	else
		log.Error("IssuingDeviceCommand ERROR %d, %s.",cde,msg)
		setStatusIcon(HData.Icon.IDLE, lul_device, HData.SIDS.CHILD)
		var.Set("LastDeviceCommand", "", HData.SIDS.CHILD, lul_device)
	end	
	return res, data, cde, msg
end

-- Clear the last device command after no button has been clicked for more then OkInterval seconds
function Harmony_SendDeviceCommandEnd(devID)
	if (devID == nil) then return end
	if (devID == '') then return end
	log.Debug('SendDeviceCommandEnd for child device #%s.',devID)
	local lul_device = tonumber(devID)
	local value, tstamp = luup.variable_get(HData.SIDS.CHILD, "LastDeviceCommand", lul_device)
	value = value or ""
	log.Log('LastDeviceCommand current value %s.',value)
	if (value ~= "") then
		local idleDelay = var.GetNumber("OkInterval")
		if (idleDelay > 0) then
			if (os.difftime(os.time(), tstamp) > idleDelay) then
				setStatusIcon(HData.Icon.IDLE, lul_device, HData.SIDS.CHILD)
				var.Set("LastDeviceCommand", "", HData.SIDS.CHILD, lul_device)
			else	
				luup.call_delay('Harmony_SendDeviceCommandEnd',1, devID)
			end
		else	
			setStatusIcon(HData.Icon.IDLE, lul_device, HData.SIDS.CHILD)
			var.Set("LastDeviceCommand", "", HData.SIDS.CHILD, lul_device)
		end	
	end	
end

-- Public HTTP request handler
-- Parameters : ?lr_Harmony&cmd=command&cmdP1=Primary command parameter&cmdP2=Secondary command parameter&cmdP3=Tertiary command parameter
-- Eg:	cmd=Get_Current_Activity_ID
--		cmd=Start_Activity&cmdP1=12345678
--		cmd=Issue_Device_Command&cmdP1=23456789&cmdP2=VolumeUp&cmdP3=0
function HTTP_Harmony (lul_request, lul_parameters)
	local cmd = ''
	local cmdp1 = ''
	local cmdp2 = ''
	local cmdp3 = ''
	log.Debug('HTTP request is: %s.',tostring(lul_request))
	for k,v in pairs(lul_parameters) do 
		log.Log('Parameters : %s=%s.',tostring(k),tostring(v)) 
		k = k:lower()
		if (k == 'cmd') then cmd = v 
		elseif (k == 'cmdp1') then cmdp1 = v:gsub('"', '')
		elseif (k == 'cmdp2') then cmdp2 = v:gsub('"', '')
		elseif (k == 'cmdp3') then cmdp3 = v 
		end
	end
	local function exec (cmd, cmdp1,cmdp2,cmdp3)
		local res, data, cde, msg
		if (cmd == 'list_activities') or (cmd == 'list_devices') or (cmd == 'list_lamps') or (cmd == 'list_device_commands') or (cmd == 'get_config') then 
			res, data, cde, msg = Harmony_GetConfig(cmd, cmdp1) 
		elseif (cmd == 'update_config') then 
			res, data, cde, msg = Harmony_UpdateConfigurations() 
		elseif (cmd == 'get_current_activity_id') then 
			res, data, cde, msg = Harmony_GetCurrentActivtyID() 
		elseif (cmd == 'power_off') then 
			res, data, cde, msg = Harmony_PowerOff() 
		elseif (cmd == 'start_activity') then 
			res, data, cde, msg = Harmony_StartActivity(cmdp1) 
		elseif (cmd == 'change_channel') then 
			res, data, cde, msg = Harmony_ChangeChannel(cmdp1) 
		elseif (cmd == 'find_activity_by_name') then 
			res, data = Harmony_FindActivityByName(cmdp1) 
		elseif (cmd == 'find_activity_by_id') then 
			res, data = Harmony_FindActivityByID(cmdp1) 
		elseif (cmd == 'find_device_by_name') then 
			res, data = Harmony_FindDeviceByName(cmdp1) 
		elseif (cmd == 'find_device_by_id') then 
			res, data = Harmony_FindDeviceByID(cmdp1) 
		elseif (cmd == 'find_sequence_by_name') then 
			res, data = Harmony_FindSequenceByName(cmdp1) 
		elseif (cmd == 'find_sequence_by_id') then 
			res, data = Harmony_FindSequenceByID(cmdp1) 
		elseif (cmd == 'issue_device_command') then 
			res, data, cde, msg = Harmony_IssueDeviceCommand(cmdp1, cmdp2, cmdp3) 
		else 
			res = false
			cde = 501
			msg =  "Unknown command " .. cmd .. " received."
		end
		local ret_struct = {}
		if res then
			ret_struct.status = "OK"
			ret_struct.code = 200
			ret_struct.msg = "OK"
			ret_struct.data = data
		else
			ret_struct.status = "ERROR"
			ret_struct.code = cde
			ret_struct.msg = msg
			ret_struct.data = {}
		end
		return json.encode(ret_struct) 
	end
	local ok, result = pcall(exec,cmd,cmdp1,cmdp2,cmdp3)   -- catch any errors
	return result
end

-- Read the variables for the buttons from main or child device. 
-- Return array with buttons config found.
local function Harmony_GetButtonData(devID,sid,isChild)
	local id, lab, dur = '','',0
	local maxBtn = HData.MaxButtonUI7
	local buttons = {}
	if (utils.GetUI() < utils.IsUI7) then maxBtn = HData.MaxButtonUI5 end
	for i = 1, maxBtn do
		if (isChild == false) then
			id = var.Get("ActivityID"..i,sid,devID) or ''
			lab = var.Get("ActivityDesc"..i,sid,devID) or ''
		else
			id = var.Get("Command"..i,sid,devID) or ''
			lab = var.Get("CommandDesc"..i,sid,devID) or ''
			dur = var.GetNumber("PrsCommand"..i,sid,devID)
		end
		if (id ~= '') and (lab ~= '') then 
			local numBtn = #buttons + 1
			buttons[numBtn] = {}
			buttons[numBtn].ID = id
			buttons[numBtn].Label = lab
			buttons[numBtn].Dur = dur
		end
	end	
	log.Debug('Button definitions found : ' .. #buttons)
	return buttons
end

-- Update the Static JSON file to update button texts etc
-- Input: devID = device ID
function Harmony_UpdateButtons(devID, upgrade)
	log.Debug('Updating buttons for Harmony device %s.',devID)
	if HData.onOpenLuup then 
		-- Not required for openLuup as static JSON definitions not used.
		log.Debug('UpdateButtons called for OpenLuup and is not required. Aborting..')
		return true
	end	

	local upgrd = false
	if (upgrade ~= nil) then upgrd = upgrade end 
	-- See if we have a device specific definition yet
	local dname = string.match(var.GetAttribute("device_type", devID), ":Harmony%d+:")
	local dnum
	if (dname ~= nil) then dnum = string.match(dname, "%d+") end
	local buttons = Harmony_GetButtonData(devID, HData.SIDS.MODULE, false)
	local remicons = (var.GetNumber('RemoteImages') == 1)
	if (dnum ~= nil) then 
		-- If we do this for an upgrade then also do a new D_ file
		if (upgrd == true) then cnfgFile.CreateDeviceFile(devID,'Harmony') end
		-- Update existing device specific JSON for buttons
		cnfgFile.CreateJSONFile(devID,'D_Harmony',false,buttons,remicons)
	else
		-- Create new device specific JSON for buttons
		cnfgFile.CreateDeviceFile(devID,'Harmony')
		cnfgFile.CreateJSONFile(devID,'D_Harmony',false,buttons,remicons)
		local fname = "D_Harmony"..devID
		var.SetAttribute("device_file",fname..".xml",devID)
		if (utils.GetUI() >= utils.IsUI7) then
			var.SetAttribute("device_json", fname..".json",devID)
		end
	end	
	-- Set preset house mode options
	if utils.GetUI() >= utils.IsUI7 then 
		local cmc = cnfgFile.CreateCustomModeConfiguration(devID, false, buttons)
		if cmc then var.Set("CustomModeConfiguration", cmc, HData.SIDS.HA, devID) end
	end	
	
	-- Force reload for things to get picked up if requested on UI7
	if (upgrd ~= true) then utils.ReloadLuup() end
	return true
end

-- Update the Static JSON file for child devices to update button texts
-- Input: devID = device ID
function Harmony_UpdateDeviceButtons(devID, upgrade)
	local upgrd
	if HData.onOpenLuup then
		-- Not required for openLuup as static JSON definitions not used.
		log.Debug('UpdateDeviceButtons called for OpenLuup and is not required. Aborting..')
		return true
	end	
	if (upgrade ~= nil) then upgrd = upgrade else upgrd = false end 
	-- See if this gets called with the parent device ID, if so stop now to avoid issues
	if devID == HData.DEVICE then
		log.Warning('UpdateDeviceButtons called with parent ID #%s. Aborting..',devID)
		return false
	end
	-- See if this gets called for a child this device owns when not upgrading
	local prnt_id
	if upgrd ~= true then
		prnt_id = var.GetAttribute('id_parent', devID) or ""
		if prnt_id ~= "" then prnt_id = tonumber(prnt_id) end
		if prnt_id ~= HData.DEVICE then
			log.Warning('UpdateDeviceButtons called for wrong parent ID #%s. Expected #%s. Aborting..',prnt_id,HData.DEVICE)
			return false
		end
	else
		-- When upgrading, use default parent
		prnt_id = HData.DEVICE
	end
	
	-- Get Harmony Device ID as that is what we use as key
	local deviceID = var.Get("DeviceID",HData.SIDS.CHILD,devID)
	if deviceID == "" then
		log.Warning('UpdateDeviceButtons called for unconfigured device. Aborting..')
		return false
	end
	
	log.Debug('Updating buttons of device# %s for Harmony Device %s.',devID, deviceID)
	local dname = string.match(var.GetAttribute("device_type", devID), ":HarmonyDevice"..prnt_id.."_%d+:")
	local dnum, tmp
	if dname then tmp, dnum = string.match(dname, "(%d+)_(%d+)") end
	local buttons = Harmony_GetButtonData(devID, HData.SIDS.CHILD, true)
	local remicons = (var.GetNumber('RemoteImages') == 1)
	local manu = var.GetAttribute("manufacturer",devID)
	if dnum then 
		-- If we do this for an upgrade then also do a new D_ file
		if upgrd then cnfgFile.CreateDeviceFile(dnum,'HarmonyDevice',prnt_id) end
		cnfgFile.CreateJSONFile(dnum,'D_HarmonyDevice',true,buttons,remicons,devID,prnt_id,manu=="Sonos")
	else
		cnfgFile.CreateDeviceFile(deviceID,'HarmonyDevice',prnt_id)
		cnfgFile.CreateJSONFile(deviceID,'D_HarmonyDevice',true,buttons,remicons,devID,prnt_id,manu=="Sonos")
		local fname = "D_HarmonyDevice"..prnt_id.."_"..deviceID
		var.SetAttribute("device_file",fname..".xml",devID)
		if utils.GetUI() >= utils.IsUI7 then
			var.SetAttribute("device_json", fname..".json",devID)
		end
	end	
	-- Set preset house mode options
	if utils.GetUI() >= utils.IsUI7 then 
		local cmc = cnfgFile.CreateCustomModeConfiguration(devID, true, buttons)
		if cmc then var.Set("CustomModeConfiguration", cmc, HData.SIDS.HA, devID) end
	end
	
	-- Force reload for things to get picked up if requested on UI7
	if upgrd ~= true then utils.ReloadLuup() end
	return true
end

-- Create child devices for devices user want on GUI 
local function Harmony_SyncDevices(childDevices)
	local childDeviceIDs = var.Get("PluginHaveChildren")
	-- See if we have obsolete child xml or json files. If so remove them
	if (not HData.Plugin_Disabled) and (not HData.onOpenLuup) then 
		cnfgFile.RemoveObsoleteChildDeviceFiles(childDeviceIDs) 
	end
	if childDeviceIDs == "" then 
		-- Note: we must continue this routine when there are no child devices as we may have ones that need to be deleted.
		log.Info("No child devices to create.")
	else
		log.Debug("Child devices to create : %s.",childDeviceIDs)
	end
	-- Get the list of configured devices.
	local devConfigs = var.Get("Devices")
	-- If nothing defined, we never could pull anything from the Hub. Just stop.
	if devConfigs == "" then
		log.Warning("No devices configuration known. All will be removed.")
		return false
	end
	local Devices_t = json.decode(devConfigs)
	local embed = (var.GetNumber("PluginEmbedChildren") == 1)
	local remicons = (var.GetNumber('RemoteImages') == 1)
	childDeviceIDs = childDeviceIDs .. ','
	for deviceID in childDeviceIDs:gmatch("([^,]*),") do
		if deviceID ~= "" then
			local device = nil
			local altid = 'HAM'..HData.DEVICE..'_'..deviceID
			-- Find matching Device definition
			for i = 1, #Devices_t.devices do 
				if (Devices_t.devices[i].ID == deviceID) then
					device = Devices_t.devices[i]
					break
				end	
			end
			if device then
				-- See if the device specific files already exist, if not copy from base and adapt. No longer needed on openLuup.
				local fname = 'D_HarmonyDevice'
				if not HData.onOpenLuup then
					fname = fname..HData.DEVICE..'_'..deviceID
					f=io.open(HData.f_path..fname..'.xml.lzo',"r")
					if f then
						-- Found, no actions needed
						io.close(f)
						log.Debug('CreateChildren: Device files for %s exist.',deviceID)
					else
						-- Not yet there, make them
						log.Debug('CreateChildren: Making new device files.')
						cnfgFile.CreateDeviceFile(deviceID,'HarmonyDevice',HData.DEVICE)
						cnfgFile.CreateJSONFile(deviceID,'D_HarmonyDevice',true,{},remicons,nil,HData.DEVICE)
					end
				end
				local vartable = {
					HData.SIDS.HA..",HideDeleteButton=1",
					HData.SIDS.CHILD..",DeviceID="..deviceID,
					HData.SIDS.CHILD..",HubName="..var.GetAttribute("name"),
					HData.SIDS.CHILD..",DeviceCommands=",
				}
				if device.Model then vartable[#vartable+1] = ",model="..device.Model end
				if device.Manufacturer then  vartable[#vartable+1] = ",manufacturer="..device.Manufacturer end
			
				local name = "HRM: " .. string.gsub(device.Device, "%s%(.+%)", "")
				log.Debug("Child device id " .. altid .. " (" .. name .. "), number " .. deviceID)
				luup.chdev.append(
					HData.DEVICE, 				-- parent (this device)
					childDevices, 				-- pointer from above "start" call
					altid,						-- child Alt ID
					name,						-- child device description 
					"", 						-- serviceId (keep blank for UI7 restart avoidance)
					fname..".xml",				-- device file for given device
					"",							-- Implementation file
					utils.Join(vartable, "\n"),	-- parameters to set 
					embed,						-- child devices can go in any room or not
					false)						-- child devices is not hidden
			else
				log.Warning("Device definitions not found on Harmony Hub for ID %s.",deviceID)
			end		
		end
	end
end

-- Create Lamp devices user wants on GUI
local function Harmony_SyncLamps(childDevices)
	-- Look for Lamp devices to create
	local childLampUdns = var.Get("PluginHaveLamps")
	if childLampUdns == "" then 
		log.Info("No lamp devices to create.")
		return
	end	
	log.Debug("Lamp devices to create : %s.",childLampUdns)
	-- Get the list of configured lamps.
	local lampConfigs = var.Get("Lamps")
	-- If nothing defined, we never could pull anything from the Hub. Just stop.
	if lampConfigs == "" or lampConfigs == "-" then
		log.Warning("No devices configuration known. All will be removed.")
		return false
	end
	local Devices_t = json.decode(lampConfigs)
	local embed = (var.GetNumber("PluginEmbedChildren") == 1)
	local remicons = (var.GetNumber('RemoteImages') == 1)
	childLampUdns = childLampUdns .. ','
	for udn in childLampUdns:gmatch("([^,]*),") do
		local lamp = nil
		-- Find matching Lamp definition
		for i = 1, #Devices_t.lamps do 
			if Devices_t.lamps[i].udn == udn then
				lamp = Devices_t.lamps[i]
				break
			end	
		end
		if lamp then
			log.Debug("Adding lamp %s",lamp.name)
			local altid = udn
			local vartable = {
				HData.SIDS.HA..",HideDeleteButton=1",
				HData.SIDS.CHILD..",UDN="..udn,
				HData.SIDS.CHILD..",name="..lamp.name,
				HData.SIDS.CHILD..",capabilities="..json.encode(lamp.capabilities),
				",model="..(lamp.model or "unknown"),
				",manufacturer="..(lamp.manufacturer or "unknown"),
				",category_num=2",
				",subcategory_num="..((lamp.capabilities.xy or lamp.capabilities.hueSat) and 4 or 1), -- RGB or Bulb
				HData.SIDS.SP..",Status=0",
				HData.SIDS.SP..",Target=0"
			}
			-- See is we know wattage. Must create own logic to set Watts when turned on.
			vartable[#vartable+1] = HData.SIDS.EM..",ActualUsage=1"
			vartable[#vartable+1] = HData.SIDS.EM..",Watts=0"
			local usw = HData.HueWatts[lamp.model] or 0
			vartable[#vartable+1] = HData.SIDS.EM..",UserSuppliedWattage="..usw

			-- See if lamp is a binary or dimming light
			local fname = "D_BinaryLight1"
			local dtype="urn:schemas-upnp-org:device:BinaryLight:1"
			if lamp.capabilities.dimLevel or lamp.capabilities.temp then
				vartable[#vartable+1] = HData.SIDS.DIM..",LoadLevelStatus=0"
				vartable[#vartable+1] = HData.SIDS.DIM..",LoadLevelTarget=0"
				vartable[#vartable+1] = HData.SIDS.DIM..",LoadLevelLast=0"
				fname = "D_DimmableLight1"
				dtype="urn:schemas-upnp-org:device:DimmableLight:1"
			end
			-- See if lamp is a monochrome or Color light
			if lamp.capabilities.xy or lamp.capabilities.hueSat then
				vartable[#vartable+1] = HData.SIDS.COL..",CurrentColor='0=0,1=0,2=0,3=0,4=0'"
				vartable[#vartable+1] = ",device_json=D_DimmableRGBOnlyLight1.json"
				fname = "D_DimmableRGBLight1"
				dtype="urn:schemas-upnp-org:device:DimmableRGBLight:1"
			end
			local name = "HRM: " .. lamp.name
			log.Debug("Child device id " .. altid .. " (" .. name .. "), UDN " .. udn)
			luup.chdev.append(
		    	HData.DEVICE, 				-- parent (this device)
		    	childDevices, 				-- pointer from above "start" call
		    	altid,						-- child Alt ID
		    	name,						-- child device description 
		    	dtype, 						-- serviceId (keep blank for UI7 restart avoidance)
		    	fname..".xml",				-- device file for given device
		    	"",							-- Implementation file
		    	utils.Join(vartable, "\n"),	-- parameters to set 
		    	embed)						-- child devices can go in any room or not
		else
			log.Warning("Lamps definitions not found on Harmony Hub for UDN %s.",udn)
		end	
	end
end
	
-- Harmony_CreateChildren
local function Harmony_CreateChildren()
	log.Debug("Harmony_CreateChildren start")
	local childDevices = luup.chdev.start(HData.DEVICE)
	Harmony_SyncDevices(childDevices)
	Harmony_SyncLamps(childDevices)
	luup.chdev.sync(HData.DEVICE, childDevices)  -- Vera will reload here when there are new devices
	
	-- See if any device, does not have the Commands data loaded.
	local childDeviceIDs = var.Get("PluginHaveChildren")
	-- If nothing defined, we never could pull anything from the Hub. Just stop.
	if childDeviceIDs ~= "" then
		childDeviceIDs = childDeviceIDs .. ','
		for deviceID in childDeviceIDs:gmatch("([^,]*),") do
			local chdev = Harmony_FindDevice(tonumber(deviceID))
			if chdev then
				local cnf = var.Get("DeviceCommands",HData.SIDS.CHILD,chdev)
				if cnf == "" then 
					-- Force load from config so any new devices get populated with configuration.
					Harmony_UpdateConfigurations()
				end	
				-- See if devices are setup.
				local buttons = Harmony_GetButtonData(chdev, HData.SIDS.CHILD, true)
				if #buttons == 0 then
					log.Debug("No Commands configured. Put up message.")
					if not HData.onOpenLuup then
						log.DeviceMessage(chdev, true, 0, "No Commands configured.")
					end	
				end	
			end
		end
	else
		log.Log("No devices configuration known. Existing devices may not get initialized.")
	end
	
	-- Configure Lamp devices
	local childLampUdns = var.Get("PluginHaveLamps")
	local lampConfigs = var.Get("Lamps")
	if childLampUdns ~= "" and lampConfigs ~= "" and lampConfigs ~= "-" then 
		-- Get status of configured lamps.
		Harmony_LampGetStates()
	end
end

-- In the call back we can conclude a new config from the Hub needs to be requested. This cannot be done from the callback.
-- Schedule it until succesful.
function Harmony_ScheduleConfigUpdate(configVersion)
	-- If busy, try again in a second
	log.Debug("Harmony_ScheduleConfigUpdate %s.",configVersion)
	if (GetBusy()) then 
		luup.call_delay("Harmony_ScheduleConfigUpdate", 1,configVersion)
	else	
		local res, data, cde, msg = Harmony_UpdateConfigurations()
		if res then
			var.Set("HubConfigVersion", configVersion)
		else
			log.Error("Failed to retrieve new configuration: %d, %s.",cde,msg)
		end
	end
end

-- Our Callback handlers.
local function Harmony_CB_MetadataNotify(cmd, data)
	log.Debug("Harmony_CB_MetadataNotify start.")
	if data.musicMeta then
		-- {"musicMeta":{"album":"","title":"538","imageUrl":"http://192.168.178.115:1400/getaa?s=1&u=x-sonosapi-stream%3as6712%3fsid%3d254%26flags%3d8224%26sn%3d0","status":"pause","favId":"Sonos-538nnn","artist":"De Coen & Sander Show","deviceId":"42314994"}}
		local device = tonumber(data.musicMeta.deviceId or "0")
		if device ~= 0 then
			local ch_dev = Harmony_FindDevice(device)
			if ch_dev then 
				local status = data.musicMeta.status
				local album = data.musicMeta.album
				local volume = data.musicMeta.volumeLevel
				local title = data.musicMeta.title
				local artist = data.musicMeta.artist
				if status then var.Set("Status", status, HData.SIDS.CHILD, ch_dev) end
				if title then var.Set("Title", title, HData.SIDS.CHILD, ch_dev) end
				if artist then var.Set("Artist", artist, HData.SIDS.CHILD, ch_dev) end
				if album then var.Set("Album", album, HData.SIDS.CHILD, ch_dev) end
				if volume then var.Set("Volume", volume, HData.SIDS.CHILD, ch_dev) end
			end	
		end
	end	
--	log.Debug(json.encode(data))
	return "OK"
end

local function Harmony_CB_StateDigestNotify(cmd,data)
	log.Debug("Harmony_CB_StateDigestNotify start.")
	local dv = data
	if dv then
		-- Get details from state Digest
		--[[ These are known data elements.
			dv.sleepTimerId
			dv.runningZoneList
			dv.sequence
			dv.activityId
			dv.errorCode
			dv.syncStatus
			dv.time
			dv.stateVersion
			dv.tzOffset
			dv.mode
			dv.hubSwVersion
			dv.deviceSetupState
			dv.tzoffset
			dv.isSetupComplete
			dv.discoveryServer
			dv.configVersion
			dv.discoveryServerCF
			dv.runningActivityList
			dv.activityStatus
			dv.wifiStatus
			dv.tz
			dv.activitySetupState
			dv.updates
			dv.hubUpdate
			dv.contentVersion
			dv.accountId
		]]
		var.Set("hubSwVersion",dv.hubSwVersion)
--		The activityStatus represents the following states: 
--			0 = Hub is off, 1 = Activity is starting, 2 = Activity is started, 3 = Hub is turning off) 
		var.Set("activityStatus", dv.activityStatus)
		if dv.activityStatus == 0 then
			UpdateCurrentActivity(-1)
		elseif dv.activityStatus == 1 then
			var.Set("StartingActivityID", dv.activityId)
		elseif dv.activityStatus == 2 then
			local actID = dv.activityId
			if (tonumber(actID)) then
				log.Debug("connect.stateDigest?notify activity : %s.",actID)
				UpdateCurrentActivity(actID)
			end
		elseif dv.activityStatus == 3 then
			var.Set("StartingActivityID", -1)
		end
		-- If activities or devices config have been changed, schedule an update.
		local curcnf = var.GetNumber("HubConfigVersion")
		if curcnf ~= dv.configVersion then
			luup.call_delay("Harmony_ScheduleConfigUpdate", 1, dv.configVersion)
		end
		return "OK"
	else
		return "No data"
	end
end
local function Harmony_CB_StartActivity(cmd,data)
	log.Debug("Harmony_CB_StartActivity start.")
	local dv = data
	if dv and dv.deviceId and dv.done and dv.total then
		log.Debug("Start activity device %s, step %d of %d.", dv.deviceId, dv.done, dv.total)
		var.Set("StartingActivityStep", string.format("%s,%d,%d",dv.deviceId, dv.done, dv.total))
		return "OK"
	else
		return "No data"
	end
end
local function Harmony_CB_StartActivityFinished(cmd,data)
	log.Debug("Harmony_CB_StartActivityFinished start.")
	local dv = data
	if dv then
		local actID = dv.activityId
		if (tonumber(actID)) then
			log.Debug("harmony.engine?startActivityFinished activity : %s.",actID)
			UpdateCurrentActivity(actID)
		end
		return "OK"
	else
		return "No data"
	end
end
local function Harmony_CB_SequenceFinished(cmd,data)
	log.Debug("harmony.engine?sequenceFinished.")
	return "OK"
end
local function Harmony_CB_AutomationStateNotify(cmd,data)
	log.Debug("Harmony_CB_AutomationStateNotify start.")
	local dv = data
	if dv then
		for udn, dt in pairs(dv) do
			local chdev = Harmony_FindLamp(udn)
			if chdev then
				log.Debug("automation.state?notify: device %s, udn %s.",chdev,udn)
				log.Debug("automation.state?notify: %s",json.encode(dt))
				Harmony_UpdateLampStatus(chdev,dt)
			else
				log.Log("AutomationStateNotify; Unconfigured automation device %s.",udn)
			end
		end	
		return "OK"
	else
		return "No data"
	end
end

-- Finish our setup activities that take a tad too long for system start
function Harmony_Setup()
	log.Info("Harmony device #%s is finishing start up!",HData.DEVICE)
	--	Start polling for status and HTTP request handler when set-up is successful
	luup.register_handler ("HTTP_Harmony", "Harmony".. HData.DEVICE)
	SetBusy(false, false)
	-- Make sure we have a configuration loaded
	local acts = var.Get("Activities")	
	local devs = var.Get("Devices")	
	local lamps = var.Get("Lamps")	
	if acts == "" or devs == "" or lamps == "" then
		-- Get all of the above
		Harmony_UpdateConfigurations()
	end

	-- Generate children, new or removed ones will cause a reload
	Harmony_CreateChildren()
	-- Get the latest status from Hub
	Harmony_GetStateDigest()
	
	-- If debug level, keep tap on memory usage too.
	--checkMemory()
	setStatusIcon(HData.Icon.IDLE)
	var.Set("LinkStatus","Ok")
	return true
end

-- Initialize our device
function Harmony_init(lul_device)
	HData.DEVICE = lul_device
	-- start Utility API's
	log = logAPI()
	var = varAPI()
	utils = utilsAPI()
	cnfgFile = ConfigFilesAPI()
	Harmony = HarmonyAPI()
	var.Initialize(HData.SIDS.MODULE, HData.DEVICE)
	var.Default("LogLevel", 1)
	log.Initialize(HData.Description, var.GetNumber("LogLevel") + 100)
	utils.Initialize()

	SetBusy(true,false)
	var.Set("LinkStatus","Starting...")
	setStatusIcon(HData.Icon.WAIT)
	log.Log("Harmony device #%s is initializing!",HData.DEVICE)
	-- See if we are running on openLuup.
	if (utils.GetUI() == utils.IsOpenLuup) then
		log.Log("We are running on openLuup.")
		HData.onOpenLuup = true
	else	
		log.Log("We are running on Vera UI%s.",utils.GetUI())
	end
	local locIconURI = HData.UI7IconURL
	local maxBtn = HData.MaxButtonUI7
	local isUI7 = true
	if (utils.GetUI() < utils.IsUI7) then 
		locIconURI = HData.UI5IconURL 
		maxBtn = HData.MaxButtonUI5
		isUI7 = false
	end
	
	cnfgFile.Initialize(HData.f_path, isUI7, HData.onOpenLuup, maxBtn, HData.RemoteIconURL, locIconURI, HData.Images, HData.DEVICE, HData.SIDS.MODULE, HData.SIDS.CHILD)
	
	-- See if user disabled plug-in 
	local disabled = var.GetAttribute("disabled")
	if (disabled == 1) then
		log.Warning("Init: Plug-in version %s - DISABLED",HData.Version)
		HData.Plugin_Disabled = true
		-- Still create any child devices so we do not loose configurations.
		Harmony_CreateChildren()
		var.Set("LinkStatus", "Plug-in disabled")
		var.Set("LastCommand", "--")
		var.Set("LastCommandTime", "--")
		-- Now we are done. Mark device as disabled
		return true, "Plug-in Disabled.", HData.Description
	end

	-- Set Alt ID on first run, may avoid issues
	var.SetAttribute('altid', 'HAM'..HData.DEVICE..'_CNTRL')
	-- Make sure all (advanced) parameters are there
	var.Default("OkInterval",1)
	var.Default("PluginHaveChildren")
	var.Default("PluginEmbedChildren", "0")
	var.Default("DefaultActivity")
	var.Default("LinkStatus", "--")
	var.Default("LastCommand", "--")
	var.Default("LastCommandTime", "--")
	var.Default("RemoteID", "")	
	var.Default("AccountID", "")	
	var.Default("Domain", "")	
	var.Default("FriendlyName", "")	
	var.Default("hubSwVersion")
	var.Default("HubConfigVersion", "--")	
	var.Default("householdUserProfileUri")	
	var.Default("Sequences")	
	var.Default("Activities")	
	var.Default("Devices")	
	var.Default("Lamps")	
	var.Default("PluginHaveLamps")
	var.Default("CurrentActivityID")
	var.Default("StartingActivityID")
	var.Default("Target", "0", HData.SIDS.SP)
	var.Default("Status", "0", HData.SIDS.SP)
	var.Default("UIVersion", "0")
	var.Default("findResult")
	var.Default("StartingActivityStep", "-1,0,0")
	var.Default("HubPolling", 1)
	var.Set("Version", HData.Version)
	if HData.onOpenLuup then 
		-- On OpenLuup the button definitions are not taken from static JSONs. We changed this with UIVerison 3.2.
		local version = var.GetNumber("UIVersion")
		if version ~= 0 and version < 3.2 then
			-- Restore the JSON files attributes to standard
			log.Log("Restore device_file and device_json for device # %s.", HData.DEVICE)
			var.SetAttribute("device_type" ,"urn:schemas-rboer-com:device:Harmony:1",HData.DEVICE)
			var.SetAttribute("device_file", "D_Harmony.xml",HData.DEVICE)
			var.SetAttribute("device_json", "D_Harmony.json",HData.DEVICE)
			var.Set("CustomModeConfiguration", "", HData.SIDS.HA, HData.DEVICE)
			local childDeviceIDs = var.Get("PluginHaveChildren")
			if childDeviceIDs ~= "" then
				for devNo, deviceID in pairs(luup.devices) do
					local altid = string.match(deviceID.id, 'HAM'..HData.DEVICE..'_%d+')
					local chdevID = var.Get("DeviceID", HData.SIDS.CHILD, devNo)
					if altid then 
						local tmp, aid = string.match(altid, "(%d+)_(%d+)")
						if chdevID == aid then
							log.Log("Restore device_file and device_json for child device # %s.", devNo)
							var.SetAttribute("device_type" ,"urn:schemas-rboer-com:device:HarmonyDevice:1",devNo)
							var.SetAttribute("device_file","D_HarmonyDevice.xml",devNo)
							var.SetAttribute("device_json", "D_HarmonyDevice.json",devNo)
							var.Set("CustomModeConfiguration", "", HData.SIDS.HA, devNo)
						else
							log.Log("Child device #%s does not have a matching DeviceID set.",devNo)
						end	
					end
				end
			end	

			-- Remove no longer needed device static JSONs and XMLs.
			cnfgFile.RemoveObsoleteDeviceFiles() 
			cnfgFile.RemoveObsoleteChildDeviceFiles() 
			var.Set("UIVersion", HData.UIVersion)
			-- Sleep for 5 secs, just in case we have multiple plug in copies that try to migrate. They must all have time to finish.
			luup.sleep(5000)
			-- We must reload for new files to be picked up
			utils.ReloadLuup()
		end
	else
		-- See if a rewrite of teh static JSON files is needed.
		local forcenewjson = false
		-- See if we are upgrading UI settings, if so force rewrite of JSON files. V2.28
		local version = var.Get("UIVersion")
		if version ~= HData.UIVersion then forcenewjson = true end
		-- When the RemoteIcons flag changed, we must force a rewrite of the JSON files as well.
		local remicons = var.Get("RemoteImages")
		local remiconsprv = var.Get("RemoteImagesPrv")
		if remicons ~= remiconsprv then
			var.Set("RemoteImagesPrv",remicons)
			forcenewjson = true
		else
			-- Default setting. It was 1 (remote) on older versions, will be 0 (local) on new.
			if remicons == '' then
				var.Set("RemoteImages",0)
				var.Set("RemoteImagesPrv",0)
			end	
		end	
		remicons = (var.GetNumber('RemoteImages') == 1)
		if forcenewjson then
			log.Warning("Force rewrite of JSON files for correct Vera software version and configuration.")
			-- Set the category to switch if needed
			var.SetAttribute('category_num', 3)
			-- Rewrite JSON files for main device
			Harmony_UpdateButtons(HData.DEVICE, true)
			-- Make default JSON for child devices D_HarmonyDevice.json
			cnfgFile.CreateJSONFile('','D_HarmonyDevice',true,{},remicons)
			log.Log("Rewritten files for main device # %s.",HData.DEVICE)
			-- Then for any child devices, as they are not yet set, we must look at altid we use.
			cnfgFile.RemoveObsoleteChildDeviceFiles()
			local childDeviceIDs = var.Get("PluginHaveChildren")
			local devConfigs = var.Get("Devices")
			if childDeviceIDs ~= "" then
				for devNo, deviceID in pairs(luup.devices) do
					local altid = string.match(deviceID.id, 'HAM'..HData.DEVICE..'_%d+')
					local chdevID = var.Get("DeviceID", HData.SIDS.CHILD, devNo)
					if altid then 
						local tmp, aid = string.match(altid, "(%d+)_(%d+)")
						if chdevID == aid then
							-- Set attributes before we recreate device configs.
							-- If nothing defined, we never could pull anything from the Hub. Just stop.
							if devConfigs ~= "" then
								local Devices_t = json.decode(devConfigs)
								local device = nil
								-- Find matching device definition
								for i = 1, #Devices_t.devices do 
									if Devices_t.devices[i].ID == chdevID then
										device = Devices_t.devices[i]
										break
									end	
								end
								if device then
									-- Set attributes
									if device.Model then var.SetAttribute("model",device.Model,devNo) end
									if device.Manufacturer then var.SetAttribute("manufacturer",device.Manufacturer,devNo) end
								end	
							end
							Harmony_UpdateDeviceButtons(devNo,true)
							var.SetAttribute('category_num', 3,devNo)
							log.Log("Rewritten files for child device # %s name %s.",devNo,chdevID)
							-- Hide the delete button for the child devices
							var.Default("HideDeleteButton", 1, HData.SIDS.HA, devNo)
						else
							log.Log("Child device #%s does not have a matching DeviceID set.",devNo)
						end	
					end
				end
			else
				log.Info("No child devices.")
			end
			var.Set("UIVersion", HData.UIVersion)
			-- Sleep for 5 secs, just in case we have multiple plug in copies that try to migrate. They must all have time to finish.
			luup.sleep(5000)
			-- We must reload for new files to be picked up
			utils.ReloadLuup()
		else
			var.Set("UIVersion", HData.UIVersion)
			log.Info("UIVersion is current : %s.",version)
		end
	end

	-- Check that we have to parameters to get started
	local ipa =	var.Default("HubIPAddress","")
	local ipAddress = string.match(ipa, '^(%d%d?%d?%.%d%d?%d?%.%d%d?%d?%.%d%d?%d?)')
	-- Set the IP address and connect to Hub.
	if ipAddress == nil then
		setStatusIcon(HData.Icon.ERROR)
		log.Error("Initialize, %s is not a valid IP address.", ipa)
		var.Set("LinkStatus","Hub connection failed. Check IP Address.")
		utils.SetLuupFailure(2, HData.DEVICE)
		return false, "Hub connection set-up failed. Check IP Address.", HData.Description
	end
	log.Info("Changing Harmony Hub: IP address %s.",ipAddress)
	-- If starting with polling disabled, no connection is made with the Hub until the first command is send or polling gets enabled again.
	local poll = (var.GetNumber("HubPolling") == 1)
	local remoteID = var.Get("RemoteID")  -- Pass any known remote ID.
	local remoteDomain = var.Get("Domain")  -- Pass any known remote Domain.
	if not Harmony.Initialize(ipAddress, port, remoteID, remoteDomain, "HH"..HData.DEVICE.."#rboer", poll) then 
		setStatusIcon(HData.Icon.ERROR)
		log.Error("Initialize, unable to reconnect on IP address %s.", ipAddress)
		var.Set("LinkStatus","Hub connection failed. Check IP Address.")
		utils.SetLuupFailure(2, HData.DEVICE)
		return false, "Hub connection set-up failed. Check IP Address.", HData.Description
	end

	-- Populate details from the Hub V3.0, First startup is never with polling disabled, so should be ok.
	if (remoteID == "" or remoteDomain == "") and poll then
		local res, data, cde, msg = Harmony.GetHubDetails()
		if res then
			remoteID = data.remote_id or ""
			remoteDomain = data.domain or ""
			var.Set("RemoteID", data.remote_id)	
			var.Set("AccountID", data.account_id)	
			var.Set("Domain", data.domain)	
			var.Set("email", data.email)	
--			var.Set("FriendlyName", data.friendly_name)	not available in Harmony Hub version 4.15.250
		else
			setStatusIcon(HData.Icon.ERROR)
			log.Error("Initialize, The Hub Remote ID could not be retrieved.")
			var.Set("LinkStatus","Hub connection failed. Remote ID could not be retrieved, check IP address.")
			utils.SetLuupFailure(2, HData.DEVICE)
			return false, "Hub connection set-up failed. Remote ID could not be retrieved, check IP address.", HData.Description
		end	
	end

	-- Now we know the remote ID, connect to the hub
	if remoteID ~= "" then
		if poll then
			-- When polling is active, open the connection with the Hub so we start to listen.
			if not Harmony.Connect() then
				setStatusIcon(HData.Icon.ERROR)
				log.Error("Initialize, unable to reconnect on IP address %s.", ipAddress)
				var.Set("LinkStatus","Hub connection failed. Check IP Address.")
				utils.SetLuupFailure(2, HData.DEVICE)
				return false, "Hub connection set-up failed. Check IP Address.", HData.Description
			end
		end
	else
		setStatusIcon(HData.Icon.ERROR)
		log.Error("Initialize, The Hub Remote ID could not be retrieved.")
		var.Set("LinkStatus","Hub connection failed. Remote ID unknown, check IP address.")
		utils.SetLuupFailure(2, HData.DEVICE)
		return false, "Hub connection set-up failed. Remote ID unknown, check IP address.", HData.Description
	end

	-- Register call back handlers for messages from the Hub.
	Harmony.RegisterCallBack("harmonyengine.metadata?notify", Harmony_CB_MetadataNotify)
	Harmony.RegisterCallBack("connect.stateDigest?notify", Harmony_CB_StateDigestNotify)
	Harmony.RegisterCallBack("vnd.logitech.connect/vnd.logitech.statedigest?get", Harmony_CB_StateDigestNotify)
	Harmony.RegisterCallBack("harmony.engine?startActivity", Harmony_CB_StartActivity)
	Harmony.RegisterCallBack("harmony.engine?startActivityFinished", Harmony_CB_StartActivityFinished)
	Harmony.RegisterCallBack("vnd.logitech.harmony/vnd.logitech.harmony.engine?sequenceFinished", Harmony_CB_SequenceFinished)
	Harmony.RegisterCallBack("automation.state?notify", Harmony_CB_AutomationStateNotify)
	
	-- Don't do this on openLuup as there is no reload needed after changing button config, so message won't go away.
	if not HData.onOpenLuup then
		-- See if activities are setup. Post message is not.
		local buttons = Harmony_GetButtonData(devID, HData.SIDS.MODULE, false)
		if #buttons == 0 then
			log.DeviceMessage(HData.DEVICE, true, 0, "No activities configured.")
		end	
	end
	
	--	Schedule to finish rest of start up in a few seconds
	luup.call_delay("Harmony_Setup", 3, "", false)
	log.Debug("Harmony Hub Control: init_module completed.")
	utils.SetLuupFailure(0, HData.DEVICE)
	return true
end

-- See if we have incoming data. Buffer each XML section between <>. Call handler on full section.
-- Note does not allow for < or > characters in CDATA section at the moment.
function Harmony_Incoming(lul_data)
    if (luup.is_ready(lul_device) == false or HData.Plugin_Disabled == true) then
        return
    end
	-- Log data from Harmony to see what we get
	if (lul_data) then
--		log.Debug("Incoming received : " .. tostring(lul_data) .. "|"..string.byte(lul_data,1) .. "|")
	end
	return true
end
