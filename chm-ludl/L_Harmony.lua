--[==[
	Module L_Harmony1.lua
	
	Written by R.Boer. 
	V2.28 22 December 2018
	
	V2.28 Changes:
				Changes to Hub WebSocket API due to Logitech pulling the XMPP API on their 206 firmware and made it a special option in 210.
				Seperate UI and plugin version to avoid static file rewrites on upgrades if not needed.
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
local socket	= require("socket")
local mime = require("mime")
local lfs = require("lfs")
local json = require("dkjson")
if (type(json) == "string") then
	luup.log("Harmony warning dkjson missing, falling back to harmony_json", 2)
	json = require("harmony_json")
end

local bit = require('bit')
if (type(bit) == "string") then
	bit = require('bit32')
	-- lua 5.2 / bit32 library
	bit.rol = bit.lrotate
	bit.ror = bit.rrotate
end

local Harmony -- Harmony API data object
local ws_client -- Websocket API bject

local HData = { -- Data used by Harmony Plugin
	Version = "2.28",
	UIVersion = "2.20",
	DEVICE = "",
	Description = "Harmony Control",
	SIDS = {
		MODULE = "urn:rboer-com:serviceId:Harmony1",
		CHILD = "urn:rboer-com:serviceId:HarmonyDevice1",
--		ALTUI = "urn:upnp-org:serviceId:altui1",
		HA = "urn:micasaverde-com:serviceId:HaDevice1",
		SP = "urn:upnp-org:serviceId:SwitchPower1"
		},
	RemoteIconURL = "http://www.reneboer.demon.nl/veraimg/",
	UI7IconURL = "",
	UI5IconURL = "icons\\/",
	f_path = '/etc/cmh-ludl/',
	onOpenLuup = false,
	MaxButtonUI5 = 24,  -- Keep the same as HAM_MAXBUTTONS in J_Harmony.js
	MaxButtonUI7 = 25,  -- Keep the same as HAM_MAXBUTTONS in J_Harmony_UI7.js
	Plugin_Disabled = false,
	Busy = false,
	BusyChange = 0,
	StartActivityBusy = 0,
	OK = 'OK',
	ER = 'ERROR',
	MSG_OK = 'command completed',
	JS = 'json',
	PL = 'plain',
	Icon = {
		Variable = "IconSet",	-- Variable controlling the iconsVariable
		IDLE = '0',		-- No background
		OK = '1',		-- Green
		BUSY = '2',		-- Blue
		WAIT = '3',		-- Amber
		ERROR = '4'		-- Red
	},
	Images = { 'Harmony', 'Harmony_0', 'Harmony_25', 'Harmony_50', 'Harmony_75', 'Harmony_100'	},
	CMD = {
		['start_activity'] = { cmd = 'startactivity', par = '"actId": "%s"', res='', c = ''},
		['issue_device_command'] = { cmd ='holdAction', par = '"devId": "%s", "devCmd": "%s"', res='', c = '' },
		['list_activities'] = { cmd = 'config', par = '', res = '[ "%s" ]', c = '' },
		['list_devices'] = { cmd = 'config', par = '', res = '[ "%s" ]', c = '' },
		['list_commands'] = { cmd = 'config', par = '', res = '[ "%s" ]', c = '' },
		['list_device_commands'] = { cmd = 'config', par = '"devId": "%s"', res = '[ "%s" ]', c = '' },
		['get_config'] = { cmd = 'config', par = '', res = '[ "%s" ]', c = '' },
		['get_current_activity_id'] = { cmd = 'getCurrentActivity', par = '', res = '"ActivityID": "%s"', c = '' }
	}
}

local TaskData = {
	Description = "Harmony Control",
	taskHandle = -1,
	ERROR = 2,
	ERROR_PERM = -2,
	SUCCESS = 4,
	BUSY = 1
}
	
	
---------------------------------------------------------------------------------------------
-- Utility functions
---------------------------------------------------------------------------------------------
local log
local var
local utils


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
		luup.attr_set(name, value, tonumber(device or def_dev))
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
local _LLError = 1
local _LLWarning = 2
local _LLInfo = 8
local _LLDebug = 11
local def_level = _LLError
local def_prefix = ''
local def_debug = false

	local function _update(level)
		if level > 10 then
			def_debug = true
			def_level = 10
		else
			def_debug = false
			def_level = level
		end
	end	

	local function _init(prefix, level)
		_update(level)
		def_prefix = prefix
	end	

	local function _log(text, level) 
		local level = (level or 10)
		if (def_level >= level) then
			if (level == 10) then level = 50 end
			local msg = (text or "no text")
			luup.log(def_prefix .. ": " .. msg:sub(1,80), (level or 50)) 
		end	
	end	
	
	local function _debug(text)
		if def_debug then
			luup.log(def_prefix .. "_debug: " .. (text or "no text"), 50) 
		end	
	end
	
	return {
		Initialize = _init,
		LLError = _LLError,
		LLWarning = _LLWarning,
		LLInfo = _LLInfo,
		LLDebug = _LLDebug,
		Update = _update,
		Log = _log,
		Debug = _debug
	}
end 

-- API to handle some Util functions
local function utilsAPI()
local _UI5 = 5
local _UI6 = 6
local _UI7 = 7
local _UI8 = 8
local _OpenLuup = 99

	local function _init()
	end	

	-- See what system we are running on, some Vera or OpenLuup
	local function _getui()
		if (luup.attr_get("openLuup",0) ~= nil) then
			return _OpenLuup
		else
			return luup.version_major
		end
		return _UI7
	end
	
	local function _getmemoryused()
		return math.floor(collectgarbage "count")         -- app's own memory usage in kB
	end
	
	local function _setluupfailure(status,devID)
		if (luup.version_major < 7) then status = status ~= 0 end        -- fix UI5 status type
		luup.set_failure(status,devID)
	end

	-- Luup Reload function for UI5,6 and 7
	local function _luup_reload()
		if (luup.version_major < 6) then 
			luup.call_action("urn:micasaverde-com:serviceId:HomeAutomationGateway1", "Reload", {}, 0)
		else
			luup.reload()
		end
	end
	
	-- Create links for UI6 or UI7 image locations if missing.
	local function _check_images(imageTable)
		local imagePath =""
		local sourcePath = "/www/cmh/skins/default/icons/"
		if (luup.version_major >= 7) then
			imagePath = "/www/cmh/skins/default/img/devices/device_states/"
		elseif (luup.version_major == 6) then
			imagePath = "/www/cmh_ui6/skins/default/icons/"
		else
			-- Default if for UI5, no idea what applies to older versions
			imagePath = "/www/cmh/skins/default/icons/"
		end
		if (imagePath ~= sourcePath) then
			for i = 1, #imageTable do
				local source = sourcePath..imageTable[i]..".png"
				local target = imagePath..imageTable[i]..".png"
				os.execute(("[ ! -e %s ] && ln -s %s %s"):format(target, source, target))
			end
		end	
	end
	
	return {
		Initialize = _init,
		ReloadLuup = _luup_reload,
		CheckImages = _check_images,
		GetMemoryUsed = _getmemoryused,
		SetLuupFailure = _setluupfailure,
		GetUI = _getui,
		IsUI5 = _UI5,
		IsUI6 = _UI6,
		IsUI7 = _UI7,
		IsUI8 = _UI8,
		IsOpenLuup = _OpenLuup
	}
end 


local function wsAPI()
	-- Local variables used.
	local ipa = ""
	local port =  "8088"
	local state = 'CLOSED'
	local is_closing = false
	local sock

	-- First bunch of function for ecnand decoding.
	local band = bit.band
	local bxor = bit.bxor
	local bor = bit.bor
	local ssub = string.sub
	local sbyte = string.byte
	local schar = string.char
	local rshift = bit.rshift
	local lshift = bit.lshift
	local mmin = math.min
	local mfloor = math.floor
	local unpack = unpack or table.unpack
	local tinsert = table.insert
	local tconcat = table.concat
	local mrandom = math.random

	local read_n_bytes = function(str, pos, n)
		pos = pos or 1
		return pos+n, string.byte(str, pos, pos + n - 1)
	end

	local read_int8 = function(str, pos)
		return read_n_bytes(str, pos, 1)
	end

	local read_int16 = function(str, pos)
		local new_pos,a,b = read_n_bytes(str, pos, 2)
		return new_pos, lshift(a, 8) + b
	end

	local read_int32 = function(str, pos)
		local new_pos,a,b,c,d = read_n_bytes(str, pos, 4)
		return new_pos,
		lshift(a, 24) +
		lshift(b, 16) +
		lshift(c, 8 ) +
		d
	end

	local pack_bytes = string.char

	local write_int8 = pack_bytes

	local write_int16 = function(v)
		return pack_bytes(rshift(v, 8), band(v, 0xFF))
	end

	local write_int32 = function(v)
		return pack_bytes(
			band(rshift(v, 24), 0xFF),
			band(rshift(v, 16), 0xFF),
			band(rshift(v,  8), 0xFF),
			band(v, 0xFF)
		)
	end

	local base64_encode = function(data)
		return (mime.b64(data))
	end

	local generate_key = function()
		-- used for generate key random ops
		math.randomseed(os.time())
		local r1 = mrandom(0,0xfffffff)
		local r2 = mrandom(0,0xfffffff)
		local r3 = mrandom(0,0xfffffff)
		local r4 = mrandom(0,0xfffffff)
		local key = write_int32(r1)..write_int32(r2)..write_int32(r3)..write_int32(r4)
		assert(#key==16,#key)
		return base64_encode(key)
	end
  
	local bits = function(...)
		local n = 0
		for _,bitn in pairs{...} do
			n = n + 2^bitn
		end
		return n
	end

	local bit_7 = bits(7)
	local bit_0_3 = bits(0,1,2,3)
	local bit_0_6 = bits(0,1,2,3,4,5,6)

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

	local encode_header_small = function(header, payload)
		return schar(header, payload)
	end

	local encode_header_medium = function(header, payload, len)
		return schar(header, payload, band(rshift(len, 8), 0xFF), band(len, 0xFF))
	end

	local encode_header_big = function(header, payload, high, low)
		return schar(header, payload)..write_int32(high)..write_int32(low)
	end

	local encode = function(data,opcode)
		local header = opcode or 1-- TEXT is default opcode
		header = bor(header,bit_7)
		local payload = 0
		payload = bor(payload,bit_7)
		local len = #data
		local chunks = {}
		if len < 126 then
			payload = bor(payload,len)
			tinsert(chunks,encode_header_small(header,payload))
		elseif len <= 0xffff then
			payload = bor(payload,126)
			tinsert(chunks,encode_header_medium(header,payload,len))
		elseif len < 2^53 then
			local high = mfloor(len/2^32)
			local low = len - high*2^32
			payload = bor(payload,127)
			tinsert(chunks,encode_header_big(header,payload,high,low))
		end
		local m1 = mrandom(0,0xff)
		local m2 = mrandom(0,0xff)
		local m3 = mrandom(0,0xff)
		local m4 = mrandom(0,0xff)
		local mask = {m1,m2,m3,m4}
		tinsert(chunks,write_int8(m1,m2,m3,m4))
		tinsert(chunks,xor_mask(data,mask,#data))
		return tconcat(chunks)
	end

	local decode = function(encoded)
		local encoded_bak = encoded
		if #encoded < 2 then
			return nil,2-#encoded
		end
		local pos,header,payload
		pos,header = read_int8(encoded,1)
		pos,payload = read_int8(encoded,pos)
		local high,low
		encoded = ssub(encoded,pos)
		local bytes = 2
		local fin = band(header,bit_7) > 0
		local opcode = band(header,bit_0_3)
		local mask = band(payload,bit_7) > 0
		payload = band(payload,bit_0_6)
		if payload > 125 then
			if payload == 126 then
				if #encoded < 2 then
					return nil,2-#encoded
				end
				pos,payload = read_int16(encoded,1)
			elseif payload == 127 then
				if #encoded < 8 then
					return nil,8-#encoded
				end
				pos,high = read_int32(encoded,1)
				pos,low = read_int32(encoded,pos)
				payload = high*2^32 + low
				if payload < 0xffff or payload > 2^53 then
					assert(false,'INVALID PAYLOAD '..payload)
				end
			else
				assert(false,'INVALID PAYLOAD '..payload)
			end
			encoded = ssub(encoded,pos)
			bytes = bytes + pos - 1
		end
		local decoded
		if mask then
			local bytes_short = payload + 4 - #encoded
			if bytes_short > 0 then
				return nil,bytes_short
			end
			local m1,m2,m3,m4
			pos,m1 = read_int8(encoded,1)
			pos,m2 = read_int8(encoded,pos)
			pos,m3 = read_int8(encoded,pos)
			pos,m4 = read_int8(encoded,pos)
			encoded = ssub(encoded,pos)
			local mask = {
				m1,m2,m3,m4
			}
			decoded = xor_mask(encoded,mask,payload)
			bytes = bytes + 4 + payload
		else
			local bytes_short = payload - #encoded
			if bytes_short > 0 then
				return nil,bytes_short
			end
			if #encoded > payload then
				decoded = ssub(encoded,1,payload)
			else
				decoded = encoded
			end
			bytes = bytes + payload
		end
		return decoded,fin,opcode,encoded_bak:sub(bytes+1),mask
	end

	local encode_close = function(code,reason)
		if code then
			local data = write_int16(code)
			if reason then
				data = data..tostring(reason)
			end
			return data
		end
		return ''
	end

	local decode_close = function(data)
		local _,code,reason
		if data then
			if #data > 1 then
				_,code = read_int16(data,1)
			end
			if #data > 2 then
				reason = data:sub(3)
			end
		end
		return code,reason
	end

	local upgrade_request = function(req)
		local format = string.format
		local lines = {
			format('GET %s HTTP/1.1',req.uri or ''),
			format('Host: %s',req.host),
				'Upgrade: websocket',
				'Connection: Upgrade',
			format('Sec-WebSocket-Key: %s',req.key),
				'Sec-WebSocket-Version: 13',
		}
		if req.origin then
			tinsert(lines,string.format('Origin: %s',req.origin))
		end
		if req.port and req.port ~= 80 then
			lines[2] = format('Host: %s:%d',req.host,req.port)
		end
		tinsert(lines,'\r\n')
		return table.concat(lines,'\r\n')
	end

	local http_headers = function(request)
		local headers = {}
		if not request:match('.*HTTP/1%.1') then
			return headers
		end
		request = request:match('[^\r\n]+\r\n(.*)')
		local empty_line
		for line in request:gmatch('[^\r\n]*\r\n') do
			local name,val = line:match('([^%s]+)%s*:%s*([^\r\n]+)')
			if name and val then
				name = name:lower()
				if not name:match('sec%-websocket') then
					val = val:lower()
				end
				if not headers[name] then
					headers[name] = val
				else
					headers[name] = headers[name]..','..val
				end
			elseif line == '\r\n' then
				empty_line = true
			else
				assert(false,line..'('..#line..')')
			end
		end
		return headers,request:match('\r\n\r\n(.*)')
	end

	-- start of actual WS functions
	local ws_receive = function()
		if state ~= 'OPEN' and not is_closing then
			return nil,nil,false,1006,'wrong state'
		end
		local first_opcode
		local frames
		local bytes = 3
		local encoded = ''
		local clean = function(was_clean,code,reason)
		    state = 'CLOSED'
			sock:close()
			return nil,nil,was_clean,code,reason or 'closed'
		end
		while true do
			local chunk,err = sock:receive(bytes)
			if err then
				return clean(false,1006,err)
			end
			encoded = encoded..chunk
			local decoded,fin,opcode,_,masked = decode(encoded)
			if masked then
				return clean(false,1006,'Websocket receive failed: frame was not masked')
			end
			if decoded then
				if opcode == 8 then
					if not is_closing then
						local code,reason = decode_close(decoded)
						-- echo code
						local msg = encode_close(code)
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
				if not first_opcode then
					first_opcode = opcode
				end
				if not fin then
					if not frames then
						frames = {}
					elseif opcode ~= 0 then
						return clean(false,1002,'protocol error')
					end
					bytes = 3
					encoded = ''
					tinsert(frames,decoded)
				elseif not frames then
					return decoded,first_opcode
				else
					tinsert(frames,decoded)
					return tconcat(frames),first_opcode
				end
			else
				assert(type(fin) == 'number' and fin > 0)
				bytes = fin
			end
		end
		assert(false,'never reach here')
	end

	local ws_close = function(code,reason)
		if state ~= 'OPEN' then
			return false,1006,'wrong state'
		end
		local msg = encode_close(code or 1000,reason)
		local encoded = encode(msg,8)
		local n,err = sock:send(encoded)
		local was_clean = false
		local code = 1005
		local reason = ''
		if n == #encoded then
			is_closing = true
			local rmsg,opcode = ws_receive()
			if rmsg and opcode == 8 then
				code,reason = decode_close(rmsg)
				was_clean = true
			end
		else
			reason = err
		end
		sock:close()
		state = 'CLOSED'
		return was_clean,code,reason or ''
	end

	local ws_send = function(data,opcode)
		if state ~= 'OPEN' then
			return nil,false,1006,'wrong state'
		end
		local encoded = encode(data,opcode or 1)
		local n,err = sock:send(encoded)
		if n ~= #encoded then
			return nil, ws_close(1006,err)
		end
		return true
	end

	local ws_connect = function(host,port,uri)
		if state ~= 'CLOSED' then
			return nil,'wrong state',nil
		end
		sock = socket.tcp()
		local _,err = sock:connect(host,port)
		if err then
			sock:close()
			return nil,err,nil
		end
		local key = generate_key()
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
		local resp = {}
		repeat
			local line,err = sock:receive('*l')
			resp[#resp+1] = line
			if err then
				return nil,err,nil
			end
		until line == ''
		local response = table.concat(resp,'\r\n')
		local headers = http_headers(response)
		state = 'OPEN'
		return true,'',headers
	end
	
	local ws_is_connected = function()
		return state == 'OPEN', state
	end

	return {
		connect = ws_connect,
		close = ws_close,
		send = ws_send,
		receive = ws_receive,
		is_connected = ws_is_connected
	}
end

-- Set message in task window.
local function task(text, mode) 
	local mode = mode or TaskData.ERROR 
	if (mode ~= TaskData.SUCCESS) then 
		if (mode == TaskData.ERROR_PERM) then
			log.Log("task: " .. (text or "no text"), log.LLError) 
		else	
			log.Log("task: " .. (text or "no text")) 
		end 
	end 
	TaskData.taskHandle = luup.task(text, (mode == TaskData.ERROR_PERM) and TaskData.ERROR or mode, TaskData.Description, TaskData.taskHandle) 
end 

-- V2.4 Check how much memory the plug in uses
function checkMemory()
	var.Set("AppMemoryUsed", utils.GetMemoryUsed()) 
	luup.call_delay("checkMemory", 600)
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

-- Open connection socket to Harmony
-- Assuming all inputs are there, no additional checking
-- Return token connected to.
local function HarmonyAPI(ipAddress, wait)
	local CommunicationPort = 8088
	local ERR_CD = { OK = "200", ERR = "503" }
	local ERR_MSG = { OK = "ok", ERR = "Unknown Harmony response" }
	local CMD_DATA = { OK = "No Data", ERR = "" }
	local numberOfMessages = 10	-- Number of messages returned on holdAction command.
	local timestamp = 10000
	local ipa = ipAddress
	--V2.15 option to wait on Hub to fully complete the start of an activity or not.
	local WaitOnActionStartComplete = wait
	local isBusy = false
	local msg_id = 0
	local remote_id, friendly_name, email, account_id

	
	-- Get config information from hub. Needed to get HubID for web socket communications.
	local function GetHubInfo()

        -- Retrieve the harmony Hub information.
        log.Debug("Retrieving Harmony Hub information.")
        local url = 'http://'..ipa..':'..CommunicationPort..'/'
        local request_body = '{"id":1,"cmd":"connect.discoveryinfo?get","params":{}}'
        local headers = {
            ['Origin']= 'http://localhost.nebula.myharmony.com',
            ['Content-Type'] = 'application/json',
            ['Accept'] = 'application/json',
            ['Accept-Charset'] = 'utf-8',
			['Content-Length'] = string.len(request_body)
        }
		local result = {}
		local bdy,cde,hdrs,stts = http.request{
			url=url, 
			method='POST',
			sink=ltn12.sink.table(result),
			source = ltn12.source.string(request_body),
			headers = headers
		}
		if cde == 200 then
			local json_response = json.decode(table.concat(result))
			_friendly_name = json_response['data']['friendlyName']
			_remote_id = json_response['data']['remoteId']
			_email = json_response['data']['email']
			_account_id = json_response['data']['accountId']
			return _remote_id, _friendly_name, _email, _account_id
		else
			return nil, nil, nil, nil
		end
	end

	-- Wait for the response for the given message ID
	-- Max ten attempts
	local function wait_response(msgid)
		local maxcnt = numberOfMessages
		while maxcnt > 1 do
			maxcnt = maxcnt -1
			local response, op = ws_client.receive()
			if response then
--log.Debug("Received response: "..response)
				local js_res = json.decode(response)
				if js_res.id == msgid then
					return true, js_res
				else
					log.Log("response is for other message id : ",js_res.id)
				end
			end	
		end
		-- Should not come here
		return false, nil
	end

	-- Send a payload request to Harmony Hub and return json response.
	-- When resp is nil or true expect a response message
	local function send_request(command, params, wait_for_response, msgid)
		local format = string.format
		local params = params or '{"verb":"get","format":"json"}'
		local msid
		if msgid then
			msid = msgid
		else
			msg_id = msg_id+1
			if msg_id > 999999 then msg_id = 1 end
			msid = msg_id
		end
		local payload = format('{"hubId":%s,"timeout":30,"hbus":{"cmd":"%s","id":%s,"params":%s}}',remote_id,command,msid,params)
--log.Debug("Sending command : "..payload)
		if ws_client.send(payload) then
			if wait_for_response ~= false then return wait_response(msid) end
			return true, nil
		end	
		return false, nil
	end

	-- Open socket to Hub
	local function Connect()
		if ((ipa or "") == "") then log.Log("Connect, no IP Address specified ",log.LLError) return false end
		if not remote_id then
			remote_id, friendly_name, email, account_id = GetHubInfo(ipa,CommunicationPort)
			if not remote_id then 
				log.Log("Connect, failed get configuration details from hub " .. ipa, log.LLError) 
				return false 
			end
			log.Debug("Hub details : "..remote_id..", "..friendly_name..", "..email..", "..account_id)
		end	
		if ws_client.is_connected() then
			log.Debug("We should have websocket open")
			return true
		else
			local res, prot, hdrs = ws_client.connect(ipa,CommunicationPort,"/?domain=svcs.myharmony.com&hubId="..remote_id)
			if res then
				local res, _ = send_request("vnd.logitech.connect/vnd.logitech.statedigest?get")
				if res then
					return true
				else	
					log.Log("Connect, failed to get statedigest hub " .. ipa, log.LLError) 
				end
			else	
				log.Log("Connect, failed to open websocket to hub " .. ipa..", err "..prot, log.LLError) 
--log.Debug("Connect, failed to open websocket to hub " .. ipa..", err "..prot) 
			end
			ws_client.close()
		end	
		return false
	end

	-- Submit the command to the Hub and process response string
	-- Input command = Hub command, id = activity or device ID, devcmd = device command, msgwait if true wait for last message from harmony on startActivity
	local function SubmitCommand(command, id, devcmd, msgwait, prs)
		local format = string.format

		if (isBusy) then return ERR_CD.ERR, "BUSY", "Busy with other command" end
		isBusy = true
		local msgcnt = 0
		
		local cmdStr = ""
		local params = nil
		local wait_resp = true
		-- Build the command string
		local cmd = (command or "")
		if (cmd == 'getCurrentActivity') then
			cmdStr = "vnd.logitech.harmony/vnd.logitech.harmony.engine?getCurrentActivity"
		elseif (cmd == 'startactivity') then
			cmdStr = "harmony.activityengine?runactivity"
			params = format('{"async": "true","timestamp": 0,"args":{"rule":"start"},"activityId":"%s"}',id)
			timestamp = timestamp + 100
		elseif (cmd == 'config') then
			cmdStr = "vnd.logitech.harmony/vnd.logitech.harmony.engine?config"
		elseif (cmd == 'holdAction') then
			cmdStr = "vnd.logitech.harmony/vnd.logitech.harmony.engine?holdAction"
			local action = format('{\\"command\\":\\"%s\\",\\"type\\":\\"IRCommand\\",\\"deviceId\\":\\"%s\\"}', devcmd, id)
			params = format('{"status":"%s","timestamp":"%s","verb":"render","action":"%s"}',prs,timestamp,action)
			wait_resp = false
			if (prs == 'press') then timestamp = timestamp + 54 else timestamp = timestamp + 100 end
		else	
			log.Log("SubmitCommand, Unknown command " .. cmd)
			isBusy = false
			return ERR_CD.ERR, "Unknown command", cmd
		end
		if (timestamp > 90000) then timestamp = 10000 end
		local cmdResp, msgResp, errCode, errMsg
		local stat, js_res = send_request(cmdStr,params,wait_resp)
		if (not stat) then 
			isBusy = false
			return ERR_CD.ERR, ERR_MSG.ERR, 'SubmitCommand, failed to send command : '.. cmdStr 
		end
		-- At holdAction the Harmony Hub does not return additional data
		if (cmd == 'holdAction') then 
			isBusy = false
			return ERR_CD.OK, ERR_MSG.OK, CMD_DATA.OK 
		end

		-- For start activity we wait until we get confirmation it got stated
		local starttime = os.time()
		HData.LastCommandTime = starttime
		if WaitOnActionStartComplete and (cmd == 'startactivity') then 
			local maxcnt = numberOfMessages
			local done = false
			while maxcnt > 1 do
				maxcnt = maxcnt -1
				if js_res.cmd == nil then
					-- we need a command respond, get next message
				elseif js_res.cmd == 'harmony.engine?startActivityFinished' then
					-- Success response
					done = true
				elseif js_res.cmd ~= 'harmony.engine?startActivity' and js_res.cmd ~= 'harmony.engine?helpdiscretes' then
				elseif js_res.code == 200 then
					-- Success response
					done = true
				elseif js_res.code ~= 100 then
					-- Only other option is inprocess message and we are not getting that, so fail
					done = true
				end	
				if done then
					isBusy = false
					return tostring(js_res.code), js_res.msg, js_res.data
				else
					-- try to read next message
					stat, js_res = wait_response(msg_id)
				end
			end	
			-- We should not come here
			isBusy = false
			return ERR_CD.ERR, ERR_MSG.ERR, 'SubmitCommand, failed to get activity start confirmation after max retries.'
		end
		-- Other command, so just return what is received from command
		isBusy = false
		return tostring(js_res.code), js_res.msg, js_res.data
	end
	
	-- Close socket to Hub
	local function Close()
		local res, cd, reason = ws_client.close()
		if not res then
			log.Debug("Failed to close websocket, code: "..cd.." reason "..reason)
		end
		return true
	end

	return{ -- Methods
		Connect = Connect,
		SubmitCommand = SubmitCommand,
		Close = Close
	}
end
---------------------------------------------------------------------------------------------
-- Harmony Plugin functions
---------------------------------------------------------------------------------------------
-- Update the last command sent to Hub and when
local function SetLastCommand(cmd)
	var.Set("LastCommand", cmd)
	var.Set("LastCommandTime", os.date("%X %a, %d %b %Y"))
end

-- Send the command to the Harmony Hub.
-- Return Status true on success and return string, else false
local function Harmony_cmd(cmd, id, devCmd, prs)
	if (Harmony == nil) then 
		var.Set("LinkStatus","Error")
		return false, "501", "No handler", " " 
	end
	local stat, msg, harmonyOutput
	log.Debug("Sending command cmd=" .. cmd)
	local stat = Harmony.Connect()
	if (stat == true) then 
		stat, msg, harmonyOutput = Harmony.SubmitCommand(HData.CMD[cmd].cmd, id, devCmd, false, prs)
		Harmony.Close()
	else
		stat = '423'
		msg = 'Failed to connect to Harmony Hub'
		harmonyOutput = nil
	end
	if (stat == '200') then
		task("Clearing...", TaskData.SUCCESS)
		var.Set("LinkStatus","Ok")
		log.Debug("CMD: return value : " .. stat .. ", " .. msg)
		return true, stat, msg, harmonyOutput
	else
		var.Set("LinkStatus","Error")
		log.Log("CMD: errcode="  .. stat .. ", errmsg=" .. msg)
		task("CMD: Failed sending command " .. cmd .. " to Harmony Hub - errorcode="  .. stat .. ", errormessage=" .. msg, TaskData.ERROR)
		return false, stat, msg, nil
	end	
end

-- Periodically send the GetCurrentActivity command to see where we are at
-- When PollInterval is zero then do not repeat it.
function Harmony_PollCurrentActivity()
	-- See if user want to repeat polling
	local pollper = var.GetNumber("PollInterval")
	if (pollper ~= 0) then 
		luup.call_delay("Harmony_PollCurrentActivity", pollper, "", false)
		local pollho = var.GetNumber("PollHomeOnly")
		local house_mode = var.GetAttribute("Mode",0)
		local cur_act = var.GetNumber("CurrentActivityID")
		if house_mode == 1 or pollho == 0 or (pollho == 2 and cur_act ~= -1) then
			-- See if we are not polling too close to start activity. This can give false results
			if (not GetBusy()) and (os.difftime(os.time(), HData.StartActivityBusy) > 60) then
				local stat, actID = Harmony_GetCurrentActivtyID()
				if (stat == true) then 
					log.Debug('PollCurrentActivity found activity ID : ' .. actID) 
				else 
					log.Log('PollCurrentActivity error getting activity') 
				end
			else 
				log.Debug('PollCurrentActivity busy or too close to Activity change') 
			end
		else 
			log.Debug('PollCurrentActivity not at Home so skipping polling.')
		end
	else
		log.Log('PollCurrentActivity stopping polling.',log.LLInfo)
	end	
end

-- Send Get Config command 
-- When format if JSON return JSON object, else string
function Harmony_GetConfig(cmd, id, fmt)
	local message = ''
	local dataTab = {}
	log.Debug("GetConfig")
	local status, cd, msg, confg = Harmony_cmd('get_config')
	if (status == true) then
		SetLastCommand(cmd)
		-- See what part we need to return
		if (cmd == 'list_activities') then 
			log.Debug("Activities found : " .. #confg.activity)
			-- List all activities supported
			dataTab.activities = {}
			for i = 1, #confg.activity do
				dataTab.activities[i] = {}
				dataTab.activities[i].ID = confg.activity[i].id
				dataTab.activities[i].Activity = confg.activity[i].label
			end
		elseif (cmd == 'list_commands') then
			log.Debug("Devices found : " .. #confg.device)
			-- List all Commands from all Devices supported
			dataTab.commands = {}
			for i = 1, #confg.device do
				dataTab.commands[i] = {}
				dataTab.commands[i].ID = confg.device[i].id
				dataTab.commands[i].Device = confg.device[i].label
				dataTab.commands[i].Functions = {}
				for j = 1, #confg.device[i].controlGroup do
					dataTab.commands[i].Functions[j] = {}
					dataTab.commands[i].Functions[j].Function = confg.device[i].controlGroup[j].name
					dataTab.commands[i].Functions[j].Commands = {}
					for x = 1, #confg.device[i].controlGroup[j]['function'] do
						dataTab.commands[i].Functions[j].Commands[x] = {}
						dataTab.commands[i].Functions[j].Commands[x].Label = confg.device[i].controlGroup[j]['function'][x].label
						dataTab.commands[i].Functions[j].Commands[x].Name = confg.device[i].controlGroup[j]['function'][x].name
						dataTab.commands[i].Functions[j].Commands[x].Action = json.decode(confg.device[i].controlGroup[j]['function'][x].action).command
					end
				end	
			end
		elseif (cmd == 'list_devices') then 
			log.Debug("Devices found : " .. #confg.device)
			-- List all devices supported
			dataTab.devices = {}
			for i = 1, #confg.device do
				dataTab.devices[i] = {}
				dataTab.devices[i].ID = confg.device[i].id
				dataTab.devices[i].Device = confg.device[i].label
				dataTab.devices[i].Model = confg.device[i].model
				dataTab.devices[i].Manufacturer = confg.device[i].manufacturer
			end
		elseif (cmd == 'list_device_commands') then
			log.Debug("Devices found : " .. #confg.device)
			-- List all commands supported by given device grouped by function
			for i = 1, #confg.device do
				if (confg.device[i].id == id) then
					dataTab.ID = confg.device[i].id
					dataTab.Device = confg.device[i].label
					dataTab.Functions = {}
					for j = 1, #confg.device[i].controlGroup do
						dataTab.Functions[j] = {}
						dataTab.Functions[j].Function = confg.device[i].controlGroup[j].name
						dataTab.Functions[j].Commands = {}
						for x = 1, #confg.device[i].controlGroup[j]['function'] do
							dataTab.Functions[j].Commands[x] = {}
							dataTab.Functions[j].Commands[x].Label = confg.device[i].controlGroup[j]['function'][x].label
							dataTab.Functions[j].Commands[x].Name = confg.device[i].controlGroup[j]['function'][x].name
							dataTab.Functions[j].Commands[x].Action = json.decode(confg.device[i].controlGroup[j]['function'][x].action).command
						end
					end	
					break
				end	
			end
		elseif (cmd == 'list_device_commands_shrt') then
			log.Debug("Devices found : " .. #confg.device)
			-- List all commands supported by given device
			dataTab.devicecommands = {} 
			for i = 1, #confg.device do
				if (confg.device[i].id == id) then
					local iCnt = 1
					for j = 1, #confg.device[i].controlGroup do
						for x = 1, #confg.device[i].controlGroup[j]['function'] do
							dataTab.devicecommands[iCnt] = {} 
							dataTab.devicecommands[iCnt].Label = confg.device[i].controlGroup[j]['function'][x].label
							dataTab.devicecommands[iCnt].Name = confg.device[i].controlGroup[j]['function'][x].name
							dataTab.devicecommands[iCnt].Action = json.decode(confg.device[i].controlGroup[j]['function'][x].action).command
							iCnt = iCnt + 1
						end
					end
					break
				end	
			end
		elseif (cmd == 'get_config') then
			-- List full configuration
			dataTab = confg
		end
	else
		message = " failed to send GetConfig command...  errorcode="  .. cd .. ", errormessage=" .. msg
	end
	-- If we had an error return that
	if (status == false) then 
		log.Log("GetConfig, " .. message) 
		dataTab.status = HData.ER 
		dataTab.message = message
		return false, dataTab 
	else
		return true, dataTab
	end	
end

-- Send IssueDeviceCommand to Harmony Hub
-- Input: devID = device ID, devCmd = device Command, devDur = key-press duration in seconds, hnd = true when called from HTTPhandler
-- Output: True on success, or JSON when called from HTTPhandler
function Harmony_IssueDeviceCommand(devID, devCmd, devDur, hnd, fmt)
	if (HData.Plugin_Disabled == true) then
		log.Log("IssueDeviceCommand : Plugin disabled.",log.LLWarning)
		return true
	end
	local cmd = 'issue_device_command'
	local status, cd, msg, harmonyOutput
	local message = ''
	local dur = tonumber(devDur) or 0
	local hnd = hnd or false
	-- When not called from HTTP Request handler, set busy status
	if (hnd == false) then 
		if (GetBusy()) then
			log.Debug("IssueDeviceCommand communication is busy")
			return false 
		end
		SetBusy(true, true)
	end
	log.Debug("IssueDeviceCommand, devID : " .. devID .. ", devCmd : " .. devCmd .. ", devDur : " .. dur)
	if ((devID ~= "") and (devCmd ~= "")) then 
		status, cd, msg, harmonyOutput = Harmony_cmd(cmd, devID, devCmd, 'press')
		-- Send hold commands each half second if there is to be a longer key press. Max is 15 seconds.
		if (dur ~= 0) then
			local till = os.time() + dur -1
			repeat 
				luup.sleep(500)
				status, cd, msg, harmonyOutput = Harmony_cmd(cmd, devID, devCmd, 'hold')
			until (os.time() > till)
		end
		status, cd, msg, harmonyOutput = Harmony_cmd(cmd, devID, devCmd, 'release')
		if (status == true) then
			SetLastCommand(cmd)
		else
			message = "failed to Issue Device Command...  errorcode="  .. cd .. ", errormessage=" .. msg
		end	
	else
		message = "no DeviceID and/or Command specified... "
		status = false
	end	
	if (status == false) then log.Log("ERROR: IssueDeviceCommand, " .. message) end
	if (hnd == false) then
		-- When not called from HTTP Request handler, clear busy status
		SetBusy(false, true)
		return status
	else
		-- Return status object to HTTP handler.
		local dataTab = {}
		if (status == true) then 
			dataTab.status = HData.OK 
			dataTab.message = HData.MSG_OK
		else 
			dataTab.status = HData.ER 
			dataTab.message = message
		end
		return status, dataTab
	end	
end

-- Send GetCurrentActivtyID to Harmony Hub
-- Input: hnd = true when called from HTTPhandler
-- Output: Activity ID on success, or JSON when called from HTTPhandler
function Harmony_GetCurrentActivtyID(hnd, fmt)
	if (HData.Plugin_Disabled == true) then
		log.Log("GetCurrentActivtyID : Plugin disabled.",log.LLWarning)
		return true, "Plugin Disabled"
	end
	local cmd = 'get_current_activity_id'
	local message = ''
	local currentActivity = ''
	local hnd = hnd or false
	-- When not called from HTTP Request handler, set busy status
	if (hnd == false) then 
		if (GetBusy()) then 
			log.Log("GetCurrentActivtyID communication is busy")
			return false 
		end
		SetBusy(true, true)
	end
	log.Debug("GetCurrentActivtyID")
	local status, cd, msg, harmonyOutput = Harmony_cmd(cmd)
	if (status == true) then
		currentActivity = harmonyOutput.result or ''
		if (tonumber(currentActivity)) then
			SetLastCommand(cmd)
			log.Debug("GetCurrentActivtyID found activity : " .. currentActivity)
			var.Set("CurrentActivityID", currentActivity)
			-- Set the target and activity so we can show off/on on Vera App
			if (currentActivity ~= '-1') then 
				var.Set("Target", "1", HData.SIDS.SP)
				var.Set("Status", "1", HData.SIDS.SP)
			else 
				var.Set("Target", "0", HData.SIDS.SP)
				var.Set("Status", "0", HData.SIDS.SP)
			end
		else
			message = "failed to Get Current Activity...  errorcode="  .. cd .. ", errormessage=" .. msg
			log.Log("GetCurrentActivtyID, ERROR " .. message) 
			status = false
		end
	else
		message = "failed to Get Current Activity...  errorcode="  .. cd .. ", errormessage=" .. msg
		log.Log("GetCurrentActivtyID, ERROR " .. message) 
	end	
	if (hnd == false) then
		-- When not called from HTTP Request handler, clear busy status
		SetBusy(false,false)
		setStatusIcon(HData.Icon.IDLE)
		return status, currentActivity
	else
		local dataTab = {}
		dataTab.currentactivityid = currentActivity
		if (status) then 
			dataTab.status = HData.OK
			dataTab.message = HData.MSG_OK
		else 
			dataTab.status = HData.ER 
			dataTab.message = message
		end
		return status, dataTab
	end	
end

-- Send StartActivity to Harmony Hub
-- Input: actID = activity ID, hnd = true when called from HTTPhandler
-- Output: True on success, or JSON when called from HTTPhandler
function Harmony_StartActivity(actID, hnd, fmt)
	if (HData.Plugin_Disabled == true) then
		log.Log("StartActivity : Plugin disabled.",log.LLWarning)
		return true
	end
	-- 2.13, do not repeat sending if activity is already the current.
	if (var.GetNumber("PollInterval") ~= 0) then
		local curActID = var.GetNumber("CurrentActivityID")
		if (curActID == tonumber(actID)) then
			local message = "Activity "..actID.." is the same as the current one. Not resending."
			log.Debug("StartActivity : "..message)
			if (hnd == false) then
				return true
			else
				local dataTab = {}
				dataTab.status = HData.ER 
				dataTab.message = message
				dataTab.activity = actID
				return true, dataTab
			end
		end
	end
	local cmd = 'start_activity'
	local message = ''
	local harmonyOutput = ''
	local status = false
	local hnd = hnd or false
	
	-- Timer so we won't do a poll too soon after start activity complete to avoid false results
	HData.StartActivityBusy = os.time()
	-- When not called from HTTP Request handler, set busy status
	if (hnd == false) then 
		if (GetBusy()) then 
			log.Debug("StartActivity communication is busy")
			return false 
		end
		SetBusy(true, true)
	end
	log.Debug("StartActivity, newActivityID : " .. actID)
	if (actID ~= "") then 
		-- Start activity
		log.Debug("StartActivity, ActivityID : " .. actID)
		-- Set value now to give quicker user feedback on UI
		status, cd, msg, harmonyOutput = Harmony_cmd (cmd, actID)
		if (status == true) then
			var.Set("CurrentActivityID", actID)
			-- Set the target and activity so we can show off/on on Vera App
			if (actID ~= '-1') then 
				var.Set("Target", "1", HData.SIDS.SP)
				var.Set("Status", "1", HData.SIDS.SP)
			else 
				var.Set("Target", "0", HData.SIDS.SP)
				var.Set("Status", "0", HData.SIDS.SP)
			end
			SetLastCommand(cmd)
		else
			message = "failed to start Activity... errorcode="  .. cd .. ", errormessage=" .. msg
		end	
	else
		message = "no newActivityID specified... "
	end	
	if (status == false) then log.Log("StartActivity, ERROR " .. message) end
	HData.StartActivityBusy = os.time()
	if (hnd == false) then
		-- When not called from HTTP Request handler, clear busy status
		SetBusy(false,true)
		return status
	else
		local dataTab = {}
		if (status == true) then 
			dataTab.status = HData.OK 
			dataTab.message = HData.MSG_OK
			dataTab.activity = actID
		else 
			dataTab.status = HData.ER 
			dataTab.message = message
			dataTab.activity = ""
		end
		return status, dataTab
	end	
end

--  devDur = key-press duration in seconds
function Harmony_SendDeviceCommand(lul_device,devCmd,devDur)
	if (HData.Plugin_Disabled == true) then
		log.Log("SendDeviceCommand : Plugin disabled.",log.LLWarning)
		return true
	end
	local cmd = (devCmd or "")
	local dur = (devDur or "0")
	local devID = var.Get("DeviceID", HData.SIDS.CHILD, lul_device)
	local prevCmd = var.Get("LastDeviceCommand", HData.SIDS.CHILD, lul_device)
	log.Debug("SendDeviceCommand "..cmd.." for device #"..lul_device.." to Harmony Device "..devID)
	var.Set("LastDeviceCommand", cmd, HData.SIDS.CHILD, lul_device)
	local starttime = os.time()
	setStatusIcon(HData.Icon.BUSY, lul_device, HData.SIDS.CHILD)
	local status = Harmony_IssueDeviceCommand(devID, cmd, dur)
	-- see if user want to show the button status for a tad longer
	local idleDelay = var.GetNumber("OkInterval")
	if (idleDelay > 0) then
		luup.call_delay('Harmony_SendDeviceCommandEnd',idleDelay, tostring(lul_device), false)
	else
		setStatusIcon(HData.Icon.IDLE, lul_device, HData.SIDS.CHILD)
		var.Set("LastDeviceCommand", "", HData.SIDS.CHILD, lul_device)
	end
	return status
end

-- Clear the last device command after no button has been clicked for more then OkInterval seconds
function Harmony_SendDeviceCommandEnd(devID)
	log.Debug('SendDeviceCommandEnd for child device #'..devID)
	if (devID == nil) then return end
	if (devID == '') then return end
	local lul_device = tonumber(devID)
	local value, tstamp = luup.variable_get(HData.SIDS.CHILD, "LastDeviceCommand", lul_device)
	value = value or ""
	log.Log('LastDeviceCommand current value'..value)
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
-- Parameters : ?al_Harmony&cmd=command&cmdP1=Primary command parameter&cmdP2=Secondary command parameter&cmdP3=Tertiary command parameter
-- Eg:	cmd=Get_Current_Activity_ID
--		cmd=Start_Activity&cmdP1=12345678
--		cmd=Issue_Device_Command&cmdP1=23456789&cmdP2=VolumeUp&cmdP3=0
function HTTP_Harmony (lul_request, lul_parameters, lul_outputformat)
	local cmd = 'get_config'
	local outFormat = HData.PL
	local cmdp1 = ''
	local cmdp2 = ''
	local cmdp3 = ''
	log.Debug('request is: '..tostring(lul_request))
	for k,v in pairs(lul_parameters) do 
		log.Log ('parameters are: '..tostring(k)..'='..tostring(v)) 
		k = k:lower()
		if (k == 'cmd') then cmd = v 
		elseif (k == 'format') then outFormat = v 
		elseif (k == 'cmdp1') then cmdp1 = v 
		elseif (k == 'cmdp2') then cmdp2 = v 
		elseif (k == 'cmdp3') then cmdp3 = v 
		end
	end
	log.Debug('outputformat is: '..outFormat)
	if (GetBusy()) then
		log.Log('we are busy..fail... ')
		if (outFormat == HData.PL) then 
			return "ERROR: Busy performing another command, please retry in a bit"
		else
			return '{ "ERROR": "Busy performing another command, please retry in a bit" }'
		end
	end
	SetBusy(true,true)
	local function exec (cmd, outFormat, cmdp1,cmdp2,cmdp3)
		local retStat, retVal
		
		if (cmd == 'list_activities') or (cmd == 'list_commands') or (cmd == 'list_devices') or (cmd == 'list_device_commands') or (cmd == 'list_device_commands_shrt') or (cmd == 'get_config') then 
			retStat, retVal = Harmony_GetConfig(cmd, cmdp1, outFormat) 
		elseif (cmd == 'get_current_activity_id') then 
			retStat, retVal = Harmony_GetCurrentActivtyID(true, outFormat) 
		elseif (cmd == 'start_activity') then 
			retStat, retVal = Harmony_StartActivity(cmdp1, true, outFormat) 
		elseif (cmd == 'issue_device_command') then 
			retStat, retVal = Harmony_IssueDeviceCommand(cmdp1, cmdp2, cmdp3, true, outFormat) 
		else 
			retStat = false
			if (outFormat == HData.PL) then 
				retVal =  'ERROR: Unknown command ' .. cmd .. ' received.'
			else
				retVal =  '{ "ERROR": "Unknown command ' .. cmd .. ' received." }'
			end
		end
		if (retStat == false) then return (retVal or "failed") end
		-- Make nice readable format, or keep in JSON
		if (outFormat == HData.PL) then 
			retVal = json.encode(retVal, {indent = true, level = 2} ) 
			retVal = retVal:gsub('{','')
			retVal = retVal:gsub('}','')
			retVal = retVal:gsub('\\"','')
			retVal = retVal:gsub('"','')
			retVal = retVal:gsub(',\n','\n')
			retVal = retVal:gsub('%[\n','\n')
			retVal = retVal:gsub('%]\n','\n')
			retVal = retVal:gsub(']\n','\n')
			retVal = retVal:gsub('\n\n','\n')
			retVal = retVal:gsub(':',' : ')
			return retVal
		else 
			return json.encode(retVal) 
		end	
	end
	local ok, result = pcall (exec,cmd,outFormat,cmdp1,cmdp2)   -- catch any errors
	SetBusy(false,true)
	return result
end

-- Internal HTTP request handler, used by user Interface
-- Output if any is always JSON from the Harmony, no formatting on it.
function HTTP_HarmonyInt (lul_request, lul_parameters, lul_outputformat)
	if (GetBusy()) then
		log.Log('Busy processing other request, sleep a second.')
		return 'Busy processing other request. Please retry in a moment.'
	end
	SetBusy(true,true)
	log.Debug('request is: '..tostring(lul_request))
	log.Debug('outputformat is: '..tostring(lul_outputformat))
	local function exec ()
		local retStat, retVal = false, ""
		if (lul_outputformat ~= "xml") then
			if (lul_request == ("hamGetActivities"..HData.DEVICE)) then
				retStat, retVal = Harmony_GetConfig('list_activities', "", HData.JS) 
			elseif (lul_request == ("hamGetDevices"..HData.DEVICE)) then
				retStat, retVal = Harmony_GetConfig('list_devices', "", HData.JS) 
			elseif (lul_request == ("hamGetDeviceCommands"..HData.DEVICE)) then
				retStat, retVal = Harmony_GetConfig('list_device_commands_shrt', lul_parameters.HID or "", HData.JS) 
			end
			if (retStat == false) then return "" end
			return json.encode(retVal) 
		else
			log.Log("unsupported format")
			return "Unsupported format : " .. lul_outputformat
		end
	end
	local ok, result = pcall (exec)   -- catch any errors
	SetBusy(false,true)
	return result
end

----------------------------------------------------------------------------------------
-- JSON configuration functions.

-- See if we have D_HarmonyDevice*.* files that no longer map to a child device.
-- Remove them as it will cause issues when child for same device is recreated.
local function removeObsoleteChildDeviceFiles(childDevs)
	local chDev = (childDevs or '') .. ','
	for fname in lfs.dir(HData.f_path) do
		local dname = string.match(fname, "D_HarmonyDevice"..HData.DEVICE.."_%d+.")
		if (dname ~= nil) then 
			local _,dnum = string.match(dname, "(%d+)_(%d+)")
			if (dnum ~= nil) then
				-- We have a child device file, see if the number is still in list of child devices
				dname = string.match(chDev, dnum..',')
				if (dname == nil) then 
					log.Log('Removing obsolete child file '..fname,log.LLWarning)
					os.remove(HData.f_path..fname)
				else
					log.Log('Child file '..fname..' still in use.')
				end	
			end	
		end
	end
end

-- Support functions to build reoccurring JSON elements.
local function buildJsonLabelControl(text,top,left,width,height,grp,dtop,dleft)
	local str = '{ "ControlType": "label", '
	if (grp ~= nil) then str = str .. '"ControlGroup": "'..grp..'", "top": '..dtop..', "left": '..dleft..', ' end
	str = str .. '"Label": { "text": "'..text..'" }, "Display": { "Top": '..top..', "Left": '..left..', "Width": '..width..', "Height": '..height..' }}'
	return str
end
local function buildJsonVariableControl(text,top,left,width,height,grp,dtop,dleft)
	local str = '{ "ControlType": "variable", '
	if (grp ~= nil) then str = str .. '"ControlGroup": "'..grp..'", "top": '..dtop..', "left": '..dleft..', ' end
	str = str .. '"Display": { "Service": "'..HData.SIDS.MODULE..'", "Variable": "'..text..'", "Top": '..top..', "Left": '..left..', "Width": '..width..', "Height": '..height..' }}'
	return str
end
local function buildJsonLabel(tag,text,top,pos,scr,func)
	local str = '{ "Label": { "lang_tag": "'..tag..'", "text": "'..text..'" }, '
	if (luup.version_major >= 7) and (top == true) then str = str .. '"TopNavigationTab": 1, ' end
	str = str .. '"Position": "'..pos..'", "TabType": "javascript", "ScriptName": "'..scr..'", "Function": "'..func..'" }'
	return str
end
local function buildJsonEvent(id,val,text)		
	local str ='{ "value": "'..val..'", "HumanFriendlyText": { "lang_tag": "ham_act_id_ch'..id..'", "text": "'..text..'" }}'
	return str
end
local function buildJsonStateIcon(icon,vari,val,sid)		
	local str
	local path = ""
	local remicons = var.GetNumber('RemoteImages')
	if (remicons == 1) then 
		path = HData.RemoteIconURL
	else
		if (luup.version_major >= 7) then path = HData.UI7IconURL end
	end
	if (luup.version_major >= 7) then
		str ='{ "img": "'..path..icon..'.png", "conditions": [ { "service": "'..sid..'", "variable": "'..vari..'", "operator": "==","value": '..val..' } ]}'
	else
		str = '"'..path..icon..'.png"'
	end
	return str
end

-- Build the string for a button
-- Input : Button label, button ID, total number of buttons and if this is a Child device
local function buildJsonButton(btnNum,btnLab,btnID,btnDur,numBtn,isChild)
	-- Calculate top and left values.
	-- Need to calculate a pair for the dashboard pannel and device control tab
	local pTop, pLeft, cTop, cLeft, cWidth, row, col, butWidth, str, newRow
	str = ''
	newRow = false
	if (luup.version_major >= 7) then
		if (numBtn == 4) then	-- Two rows, two columns
			pTop, col = math.modf((btnNum-1) / 2)
			pLeft = col * 2
			butWidth =  2
			if (btnNum == 3) then newRow = true end
		elseif (numBtn <= 5) then	-- One row, up to five columns
			pLeft = btnNum-1
			pTop = 0
			butWidth =  1 + (5-numBtn)/3
		elseif (numBtn == 6) then	-- Two rows, three columns
			pTop, col = math.modf((btnNum-1) / 3)
			pLeft = col * 3
			butWidth = 1.66
			if (btnNum == 4) then newRow = true end
		elseif (numBtn <= 8) then	-- Two rows, four columns
			pTop, col = math.modf((btnNum-1) / 4)
			pLeft = col * 4
			butWidth = 1.33
			if (btnNum == 5) then newRow = true end
		elseif (numBtn <= 10) then	-- Two rows, five columns
			pTop, col = math.modf((btnNum-1) / 5)
			pLeft = col * 5
			butWidth = 1
			if (btnNum == 6) then newRow = true end
		elseif (numBtn <= 12) then	-- Three rows, four columns
			pTop, col = math.modf((btnNum-1) / 4)
			pLeft = col * 4
			butWidth = 1.33
			if (btnNum == 5) or (btnNum == 9) then newRow = true end
		elseif (numBtn <= 15) then	-- Three rows, five columns
			pTop, col = math.modf((btnNum-1) / 5)
			pLeft = col * 5
			butWidth = 1
			if (btnNum == 6) or (btnNum == 11) then newRow = true end
		elseif (numBtn <= 16) then	-- Four rows, four columns
			pTop, col = math.modf((btnNum-1) / 4)
			pLeft = col * 4
			butWidth = 1.33
			if (btnNum == 5) or (btnNum == 9) or (btnNum == 13) then newRow = true end
		else						-- Four or five rows, five columns
			pTop, col = math.modf((btnNum-1) / 5)
			pLeft = col * 5
			butWidth = 1
			if (btnNum == 6) or (btnNum == 11) or (btnNum == 16)  or (btnNum == 21) then newRow = true end
		end
		cTop = 45 + (pTop * 25)
		if (newRow) then str = str .. '{ "ControlGroup": 1, "ControlType": "line_break" },\n'	end
		cWidth = 65 * butWidth
		cLeft = 50 + (pLeft * (cWidth + 10))
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
		cWidth = 65
		cTop = 45 + (pTop * 25)
		cLeft = 50 + (pLeft * (cWidth + 10))
	end	
	str = str .. '{ "ControlGroup": "1", "ControlType": "button", "top": '..pTop..', "left": '..pLeft..','
	if (butWidth ~= 1) and (utils.GetUI() >= utils.IsUI7) then
		str = str .. '"HorizontalMultiplier": "'..butWidth..'",'
	end
	str = str .. '\n"Label": { "text": "'..btnLab..'" },\n'
	if (isChild == false) then
		str = str .. '"Display": { "Service": "'..HData.SIDS.MODULE..'", "Variable": "CurrentActivityID", "Value": "'..btnID..'", "Top": '..cTop..', "Left": '..cLeft..', "Width": '..cWidth..', "Height": 20 },\n'
		str = str .. '"Command": { "Service": "'..HData.SIDS.MODULE..'", "Action": "StartActivity", "Parameters": [{ "Name": "newActivityID", "Value": "'..btnID..'" }] },\n'
	else
		if btnDur == '' then btnDur = 0 end
		str = str .. '"Display": { "Service": "'..HData.SIDS.CHILD..'", "Variable": "LastDeviceCommand", "Value": "'..btnID..'", "Top": '..cTop..', "Left": '..cLeft..', "Width": '..cWidth..', "Height": 20 },\n'
		str = str .. '"Command": { "Service": "'..HData.SIDS.CHILD..'", "Action": "SendDeviceCommand", "Parameters": [{ "Name": "Command", "Value": "'..btnID..'"},{  "Name": "Duration", "Value": "'..btnDur..'" }] },\n'
	end
	str = str .. '"ControlCode": "ham_button'..btnNum..'"\n}'
	return str
end

-- Build the JSON file 
local function writeJsonFile(devID,outf,newDevice,isChild,childDev)
	local maxBtn, id, lab, dur, sid
	local numBtn = 0
	local buttons = {}
	if (utils.GetUI() >= utils.IsUI7) then 
		maxBtn = HData.MaxButtonUI7 
	else 
		maxBtn = HData.MaxButtonUI5 
	end
	if (isChild == false) then sid = HData.SIDS.MODULE else sid = HData.SIDS.CHILD end
	-- If not new device we can read the variables for the buttons. 
	for i = 1, maxBtn do
		if (isChild == false) then
			id = var.Get("ActivityID"..i) or ''
			lab = var.Get("ActivityDesc"..i) or ''
			dur = 0
		else
			-- On first create this will be nil
			if (childDev ~= nil) then
				id = var.Get("Command"..i,sid,childDev)
				lab = var.Get("CommandDesc"..i,sid,childDev)
				dur = var.GetNumber("PrsCommand"..i,sid,childDev)
			else
				id = ''
				lab = ''
				dur = 0
			end
		end
		if (id ~= '') and (lab ~= '') then 
			numBtn = numBtn + 1 
			buttons[numBtn] = {}
			buttons[numBtn].ID = id
			buttons[numBtn].Label = lab
			buttons[numBtn].Dur = dur
		end
	end	
	log.Debug('Button definitions found : ' .. numBtn)
	local path = ""
	local remicons = var.GetNumber('RemoteImages')
	if (remicons == 1) then 
		path = HData.RemoteIconURL
	else
		if (luup.version_major >= 7) then 
			path = HData.UI7IconURL 
		else
			path = HData.UI5IconURL 
		end
	end
	-- For main device default icon is wait so it status is more clear during all reloads.
	if (utils.GetUI() >= utils.IsUI7) then
		local defIcon
		if (isChild == false) then defIcon = 'Harmony_75.png' else defIcon = 'Harmony.png' end
		outf:write('{\n"default_icon": "'..path..defIcon..'",\n')
	else
		outf:write('{\n"flashicon": "'..path..'Harmony.png",\n')
	end
	outf:write('"state_icons":[ \n')
	-- Write status Icon control, skip first image as that is plug in default
	for i = 2, #HData.Images do
		outf:write(buildJsonStateIcon(HData.Images[i],'IconSet',i-2,sid))
		if (i < #HData.Images) then 
			outf:write(', ')
		else
			outf:write(' ],\n')
		end
	end	
	if (utils.GetUI() < utils.IsUI7) then outf:write('"DisplayStatus": { "Service": "'..sid..'", "Variable": "IconSet", "MinValue": "0", "MaxValue": "4" },\n') end
	-- Calculate X size of device on screen
	local x,y,top,tab
	if (numBtn > 6) then 
		x,y = math.modf((numBtn + 3) / 4)
		outf:write('"x": "'..x..'",\n"y": "4",\n') 
	else
		outf:write('"x": "2",\n"y": "4",\n') 
	end
	outf:write('"inScene": "1",\n"ToggleButton": 1,\n"Tabs": [ {\n')
	outf:write('"Label": { "lang_tag": "tabname_control", "text": "Control" },\n')
	outf:write('"Position": "0",\n"TabType": "flash",\n')
	if (utils.GetUI() >= utils.IsUI7) then outf:write('"TopNavigationTab": 1,\n') end
	outf:write('"ControlGroup": [ { "id": "1", "scenegroup": "1", "isSingle": "1" } ],\n')
	-- Calculate correct SceneGroup size. Size not used in UI7.
	if (numBtn < 5) then top = 1 else top = 0 end
	if (numBtn <= 1) then 
		x = 1 
		y = 1
	elseif (numBtn <= 8) then
		y, x = math.modf((numBtn + 1) / 2)
		x = 2
	elseif (numBtn <= 12) then
		y, x = math.modf((numBtn + 2) / 3)
		x = 3 
	else
		x,y = math.modf((numBtn + 3) / 4)
		y = 4
	end
	outf:write('"SceneGroup": [ { "id": "1", "top": "'..top..'", "left": "0", "x": "'..x..'", "y": "'..y..'"} ],\n')
	outf:write('"Control": [')
	if (numBtn > 0) then
		-- Add the buttons
		for i = 1, #buttons do
			log.Debug('Adding button ' .. i .. ', label ' .. (buttons[i].Label or 'missing'))
			outf:write(buildJsonButton(i,buttons[i].Label, buttons[i].ID, buttons[i].Dur, numBtn, isChild) .. ',\n')
		end	
	else
		if (isChild == false) then
			outf:write(buildJsonLabelControl('Configure the harmony Activities on the Activities tab to define control buttons.',50,50,300,20,1,0,0) .. ',\n')
		else
			outf:write(buildJsonLabelControl('Configure the device Command Buttons on the Settings tab to complete configuration.',50,50,300,20,1,0,0) .. ',\n')
		end	
	end
	-- Add other UI elements
	tab = 1
	-- Post UI7 we have a different JS UI file then prior versions.
	local jsFile, jsPfx
	if (utils.GetUI() < utils.IsUI7) then 
		jsFile = 'J_Harmony.js' 
		jsPfx = 'ham' 
	else
		jsFile = 'J_Harmony_UI7.js'
		jsPfx = 'Harmony.'
	end
	if (isChild == false) then
		top = 160
		if (numBtn > 6) then top = top + 25 end
		outf:write(buildJsonLabelControl('Link Status:',top,50,100,20) .. ',\n')
		outf:write(buildJsonVariableControl('LinkStatus',top,180,150,20) .. ',\n')
		top = top + 20
		outf:write(buildJsonLabelControl('Current Activity ID :',top,50,100,20) .. ',\n')
		outf:write(buildJsonVariableControl('CurrentActivityID',top,180,80,20) .. ',\n')
		top = top + 20
		outf:write(buildJsonLabelControl('Last command:',top,50,100,20) .. ',\n')
		outf:write(buildJsonVariableControl('LastCommand',top,180,80,20) .. ',\n')
		top = top + 20
		outf:write(buildJsonLabelControl('Last command time:',top,50,100,20) .. ',\n')
		outf:write(buildJsonVariableControl('LastCommandTime',top,180,80,20) .. '\n]},\n')
		outf:write(buildJsonLabel('settings','Settings',true,tab,jsFile,jsPfx..'Settings') ..',\n')
		tab = tab+1
		outf:write(buildJsonLabel('activities','Activities',true,tab,jsFile,jsPfx..'Activities') ..',\n')
		tab = tab+1
		outf:write(buildJsonLabel('devices','Devices',true,tab,jsFile,jsPfx..'Devices') ..',\n')
		tab = tab+1
	else
		top = 160
		if (numBtn > 20) then top = top + 25 end
		outf:write(buildJsonLabelControl('Controlling Hub:',top,50,100,20) .. ',\n')
		local tmpstr = buildJsonVariableControl('HubName',top,180,80,20)
		outf:write(tmpstr:gsub('Harmony1','HarmonyDevice1') .. ',\n')
		top = top + 20
		outf:write(buildJsonLabelControl('Last command:',top,50,100,20) .. ',\n')
		local tmpstr = buildJsonVariableControl('LastDeviceCommand',top,180,80,20)
		outf:write(tmpstr:gsub('Harmony1','HarmonyDevice1') .. '\n]},\n')
		outf:write(buildJsonLabel('settings','Settings',true,tab,jsFile,jsPfx..'DeviceSettings'),',\n')
		tab = tab+1
	end
	outf:write(buildJsonLabel('advanced','Advanced',false,tab,'shared.js','advanced_device') ..',\n')
	outf:write(buildJsonLabel('logs','Logs',false,tab+1,'shared.js','device_logs') ..',\n')
	outf:write(buildJsonLabel('notifications','Notifications',false,tab+2,'shared.js','device_notifications'))
	if (utils.GetUI() >= utils.IsUI7) then outf:write(',\n' .. buildJsonLabel('ui7_device_scenes','Scenes',false,tab+3,'shared.js','device_scenes')) end
	outf:write('],\n')
	outf:write('"eventList2": [ ')
	-- Add possible events if we have buttons as well.
	if (numBtn > 0) then
		outf:write('{ "id": 1, "label": { "lang_tag": "act_id_ch", "text": ')
		if (isChild == false) then
			outf:write('"Harmony Activity is changing to"}, "serviceId": "'..sid..'",\n')
		else	
			outf:write('"Device Command activated"}, "serviceId": "'..sid..'",\n')
		end
		outf:write('"norepeat": "1","argumentList": [{ "id": 1, "dataType": "string", "allowedValueList": [\n')
		local btnID = 0
		for i = 1, #buttons do
			log.Debug('Adding event ' .. i .. ', label ' .. (buttons[i].Label or 'missing'))
			local lab = buttons[i].Label or 'missing'
			local val = buttons[i].ID or 'missing'
			local str = buildJsonEvent(i,val,lab)
			if (i < #buttons) then str = str .. ',' end
			str = str .. '\n'
			outf:write(str)
		end	
		if (isChild == false) then
			outf:write('], "name": "CurrentActivityID", "comparisson": "=", "prefix": { "lang_tag": "select_event", "text": "Select activity : " }, "suffix": {} } ] }')
		else	
			outf:write('], "name": "LastDeviceCommand", "comparisson": "=", "prefix": { "lang_tag": "select_command", "text": "Select command : " }, "suffix": {} } ] }')
		end
		-- Status event of On/Off
		if (isChild == false) then
			outf:write(',\n{ "id": 2, "label": { "lang_tag": "a_device_is_turned_on_off", "text": "A device is turned on or off"}, "serviceId": "'..HData.SIDS.SP..'",')
			outf:write('"norepeat": "1","argumentList": [{ "id": 1, "dataType": "boolean", "defaultValue": "0", "allowedValueList": [')
			outf:write('{ "Off": "0", "HumanFriendlyText": { "lang_tag": "hft_device_turned_off", "text": "Whenever the _DEVICE_NAME_ is turned off" }},') 
			outf:write('{ "On": "1", "HumanFriendlyText": { "lang_tag": "hft_device_turned_on", "text": "Whenever the _DEVICE_NAME_ is turned on" }}')
			outf:write('], "name": "Status", "comparisson": "=", "prefix": { "lang_tag": "ui7_which_mode", "text": "Which mode : " }, "suffix": {} } ] }')
		end
	end	
	outf:write('],\n')
	if (isChild == false) then
		if (utils.GetUI() < utils.IsUI7) then outf:write('"DeviceType": "urn:schemas-rboer-com:device:Harmony'..devID..':1",\n') end
		outf:write('"device_type": "urn:schemas-rboer-com:device:Harmony'..devID..':1"\n}\n')
	else	
		if (utils.GetUI() < utils.IsUI7) then outf:write('"DeviceType": "urn:schemas-rboer-com:device:HarmonyDevice'..HData.DEVICE..'_'..devID..':1",\n') end
		outf:write('"device_type": "urn:schemas-rboer-com:device:HarmonyDevice'..HData.DEVICE..'_'..devID..':1"\n}\n')
	end
	return true
end

-- Create the new Static JSON and compress it unless on openLuup
local function make_JSON_file(devID,name,newDevice,isChild,childDev,prnt_id)
	local prnt
	if (prnt_id ~= nil) then prnt = prnt_id..'_' else prnt = '' end
	local jsonOut = HData.f_path..name..prnt..devID..'.json'
	local outf = io.open(jsonOut..'X', 'w')
	local ret = writeJsonFile(devID,outf,newDevice,isChild,childDev)
    outf:close()
	-- Only make new file when write was successful.
	if (HData.onOpenLuup) then 
		if (ret == true) then os.execute('cp '..jsonOut..'X '..jsonOut) end
	else	
		if (ret == true) then os.execute('pluto-lzo c '..jsonOut..'X '..jsonOut..'.lzo') end
	end	
	os.execute('rm -f '..jsonOut..'X')
end

-- Re-write the D_Harmony[Device].xml file to point to device specific Static JSON
local function make_D_file(devID,name,prnt_id)
	local prnt
	local outf
	if (prnt_id ~= nil) then prnt = prnt_id..'_' else prnt = '' end
	local inpath = HData.f_path .. 'D_'..name..'.xml'
	local outpath = HData.f_path .. 'D_'..name..prnt..devID..'.xml'
	if (HData.onOpenLuup) then 
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
	if (HData.onOpenLuup) then
		os.execute('cp '..outpath..'X '..outpath)
		os.execute('rm -f '..outpath..'X')
	else	
		os.execute('pluto-lzo c '..outpath..' '..outpath..'.lzo')
		os.execute('rm -f '..outpath)
		os.execute('rm -f '..inpath)
	end	
end

-- Create CustomModeConfiguration value for preset House mode support.
local function Harmony_CreateCustomModeConfiguration(devID, isChild)
	local maxBtn, id, lab, dur, sid, cmd, prm
	local retVal = nil
	local numBtn = 0
	local buttons = {}
	if (utils.GetUI() >= utils.IsUI7) then 
		maxBtn = HData.MaxButtonUI7 
	else 
		maxBtn = HData.MaxButtonUI5 
	end
	if (isChild == false) then 
		sid = HData.SIDS.MODULE
		cmd = "/StartActivity"
		prm = "/newActivityID="
	else 
		sid = HData.SIDS.CHILD 
		cmd = "/SendDeviceCommand"
		prm = "/Command="
	end
	-- If not new device we can read the variables for the buttons. 
	for i = 1, maxBtn do
		if (isChild == false) then
			id = var.Get("ActivityID"..i) or ''
			lab = var.Get("ActivityDesc"..i) or ''
		else
			id = var.Get("Command"..i,sid,devID) or ''
			lab = var.Get("CommandDesc"..i,sid,devID) or ''
		end
		if (id ~= '') and (lab ~= '') then 
			numBtn = numBtn + 1 
			buttons[numBtn] = {}
			buttons[numBtn].ID = id
			buttons[numBtn].Label = lab
		end
	end	
	for i = 1, #buttons do
		local lab = buttons[i].Label or 'missing'
		local val = buttons[i].ID or 'missing'
		local str = lab .. ";CMD" .. val .. ";" .. sid .. cmd .. prm .. val
		if (i < #buttons) then str = str .. '|' end
		retVal = (retVal or "") .. str
	end	
	return retVal
end

-- Update the Static JSON file to update button texts etc
-- Input: devID = device ID
function Harmony_UpdateButtons(devID, upgrade)
	log.Debug('Updating buttons for Harmony device ' .. devID)
	local upgrd
	if (upgrade ~= nil) then upgrd = upgrade else upgrd = false end 
	-- See if we have a device specific definition yet
--	local dname = string.match(luup.devices[devID].device_type, ":Harmony%d+:")
	local dname = string.match(var.GetAttribute("device_type", devID), ":Harmony%d+:")
	local dnum
	if (dname ~= nil) then dnum = string.match(dname, "%d+") end
	if (dnum ~= nil) then 
		-- If we do this for an upgrade then also do a new D_ file
		if (upgrd == true) then make_D_file(dnum,'Harmony') end
		-- Update existing device specific JSON for buttons
		make_JSON_file(dnum,'D_Harmony',false,false)
	else
		-- Create new device specific JSON for buttons
		make_D_file(devID,'Harmony')
		make_JSON_file(devID,'D_Harmony',false,false)
		local fname = "D_Harmony"..devID
		local curname = var.GetAttribute("device_file",devID)
		if (curname ~= (fname..".xml")) then var.SetAttribute("device_file",fname..".xml",devID) end
		if (utils.GetUI() >= utils.IsUI7) then
			curname = var.GetAttribute("device_json",devID)
			if (curname ~= (fname..".json")) then var.SetAttribute("device_json", fname..".json",devID) end
		end
	end	
	-- Set preset house mode options
	if (utils.GetUI() >= utils.IsUI7) then 
		local cmc = Harmony_CreateCustomModeConfiguration(devID, false)
		if (cmc) then var.Set("CustomModeConfiguration", cmc, HData.SIDS.HA, devID) end
	end	
	
	-- Force reload for things to get picked up if requested on UI7
	if (upgrd ~= true) then utils.ReloadLuup() end
	return true
end

-- Update the Static JSON file for child devices to update button texts
-- Input: devID = device ID
function Harmony_UpdateDeviceButtons(devID, upgrade)
	local upgrd
	if (upgrade ~= nil) then upgrd = upgrade else upgrd = false end 
	-- See if this gets called with the parent device ID, if so stop now to avoid issues
	if (devID == HData.DEVICE) then
		log.Log('UpdateDeviceButtons called with parent ID #' .. devID .. '. Aborting..',log.LLWarning)
		return false
	end
	-- See if this gets called for a child this device owns when not upgrading
	local prnt_id
	if (upgrd ~= true) then
		prnt_id = var.GetAttribute('id_parent', devID) or ""
		if (prnt_id ~= "") then prnt_id = tonumber(prnt_id) end
		if (prnt_id ~= HData.DEVICE) then
			log.Log('UpdateDeviceButtons called for wrong parent ID #' .. prnt_id .. '. Expected #' .. HData.DEVICE .. '. Aborting..',log.LLWarning)
			return false
		end
	else
		-- When upgrading, use default parent
		prnt_id = HData.DEVICE
	end
	
	-- Get Harmony Device ID as that is what we use as key
	local deviceID = var.Get("DeviceID",HData.SIDS.CHILD,devID)
	if (deviceID == "") then
		log.Log('UpdateDeviceButtons called for unconfigured device. Aborting..',log.LLWarning)
		return false
	end
	
	log.Debug('Updating buttons of device# ' .. devID .. ' for Harmony Device ' .. deviceID)
--	local dname = string.match(luup.devices[devID].device_type, ":HarmonyDevice"..prnt_id.."_%d+:")
	local dname = string.match(var.GetAttribute("device_type", devID), ":HarmonyDevice"..prnt_id.."_%d+:")
	local dnum, tmp
	if (dname ~= nil) then tmp, dnum = string.match(dname, "(%d+)_(%d+)") end
	if (dnum ~= nil) then 
		-- If we do this for an upgrade then also do a new D_ file
		if (upgrd == true) then make_D_file(dnum,'HarmonyDevice',prnt_id) end
		make_JSON_file(dnum,'D_HarmonyDevice',false,true,devID,prnt_id)
	else
		make_D_file(deviceID,'HarmonyDevice',prnt_id)
		make_JSON_file(deviceID,'D_HarmonyDevice',false,true,devID,prnt_id)
		local fname = "D_HarmonyDevice"..prnt_id.."_"..deviceID
		local curname = var.GetAttribute("device_file",devID)
		if (curname ~= (fname..".xml")) then var.SetAttribute("device_file",fname..".xml",devID) end
		if (utils.GetUI() >= utils.IsUI7) then
			curname = var.GetAttribute("device_json",devID)
			if (curname ~= (fname..".json")) then var.SetAttribute("device_json", fname..".json",devID) end
		end
	end	
	-- Set preset house mode options
	if (utils.GetUI() >= utils.IsUI7) then 
		local cmc = Harmony_CreateCustomModeConfiguration(devID, true)
		if (cmc) then var.Set("CustomModeConfiguration", cmc, HData.SIDS.HA, devID) end
	end
	
	-- Force reload for things to get picked up if requested on UI7
	if (upgrd ~= true) then utils.ReloadLuup() end
	return true
end
	
-- Harmony_CreateChildren
local function Harmony_CreateChildren()
	log.Debug("Harmony_CreateChildren for device ")
	local childDeviceIDs = var.Get("PluginHaveChildren")
	-- See if we have obsolete child xml or json files. If so remove them
	if (HData.Plugin_Disabled == false) then removeObsoleteChildDeviceFiles(childDeviceIDs) end
	if (childDeviceIDs == '') then 
		-- Note: we must continue this routine when there are no child devices as we may have ones that need to be deleted.
		log.Log("No child devices to create.")
	else
		log.Debug("Child devices to create : " ..childDeviceIDs)
	end
	-- Get the list of devices from the harmony when not disabled.
	local retStat, Devices_t 
	if (HData.Plugin_Disabled == false) then 
		retStat, Devices_t = Harmony_GetConfig('list_devices', "", HData.JS)
		if retStat and (#Devices_t.devices == 0) then log.Log("No devices returned from Harmony Hub.") end
	else
		Devices_t = {}
		Devices_t.devices = {}
		retStat = false
	end	
	-- Failed to get devices from HUB, determine current ones from defined plugins
	if (retStat == false) then
		log.Log("Failed to obtain the current devices from Hub. Hub may be off. Will analyse current Child devices")
		local altidprfx = 'HAM'..HData.DEVICE..'_'
		for k, v in pairs(luup.devices) do
			if (v.id ~=var.GetAttribute ('altid')) and (string.sub(v.id,1,altidprfx:len()) == altidprfx) then
				log.Debug("Found existing child device, lets save! id " .. tostring(v.id))
				local i = #Devices_t.devices + 1
				Devices_t.devices[i] = {}
				Devices_t.devices[i].ID = string.sub(v.id,altidprfx:len()+1)
				Devices_t.devices[i].Device = string.sub(v.description,6)
			end
		end
	end
	local childDevices = luup.chdev.start(HData.DEVICE)
	local embed = (var.GetNumber("PluginEmbedChildren") == 1)
	-- Loop over devices to create child for, add extra comma for gmatch to work on last device
	childDeviceIDs = childDeviceIDs .. ','
	for deviceID in childDeviceIDs:gmatch("(%w+),") do
		local desc
		local altid = 'HAM'..HData.DEVICE..'_'..deviceID
		-- Find matching Device definition
		for i = 1, #Devices_t.devices do 
			if (Devices_t.devices[i].ID == deviceID) then
				desc = Devices_t.devices[i].Device
				break
			end	
		end
		if (desc == nil) then
			log.Log("Error! device definitions not found on Harmony Hub for ID "..deviceID,log.LLWarning)
		else
			-- See if the device specific files already exist, if not copy from base and adapt
			local fname = 'D_HarmonyDevice'..HData.DEVICE..'_'..deviceID
			if (HData.onOpenLuup) then
				f=io.open(HData.f_path..fname..'.xml',"r")
			else	
				f=io.open(HData.f_path..fname..'.xml.lzo',"r")
			end	
			if f~=nil then
				-- Found, no actions needed
				io.close(f)
				log.Debug('CreateChildren: Device files for '..deviceID..' exist.')
			else
				-- Not yet there, make them
				log.Debug('CreateChildren: Making new device files.')
				make_D_file(deviceID,'HarmonyDevice',HData.DEVICE)
				make_JSON_file(deviceID,'D_HarmonyDevice',false,true,nil,HData.DEVICE)
			end
--			local init = "urn:micasaverde-com:serviceId:HaDevice1,HideDeleteButton=1\n"..HData.SIDS.CHILD..",DeviceID=".. deviceID.."\n"..HData.SIDS.CHILD..",HubName="..luup.devices[HData.DEVICE].description
			local init = "urn:micasaverde-com:serviceId:HaDevice1,HideDeleteButton=1\n"..HData.SIDS.CHILD..",DeviceID=".. deviceID.."\n"..HData.SIDS.CHILD..",HubName="..var.GetAttribute("name")
			local name = "HRM: " .. string.gsub(desc, "%s%(.+%)", "")
			log.Debug("Child device id " .. altid .. " (" .. name .. "), number " .. deviceID)
			luup.chdev.append(
		    	HData.DEVICE, 		-- parent (this device)
		    	childDevices, 		-- pointer from above "start" call
		    	altid,				-- child Alt ID
		    	name,				-- child device description 
		    	"", 				-- serviceId (keep blank for UI7 restart avoidance)
		    	fname..".xml",		-- device file for given device
		    	"",					-- Implementation file
		    	init,				-- parameters to set 
		    	embed)				-- not embedded child devices can go in any room
		end		
	end
	luup.chdev.sync(HData.DEVICE, childDevices)  -- Vera will reload here when there are new devices
end

-- Finish our setup activities that take a tad too long for system start
function Harmony_Setup()
	log.Log("Harmony device #" .. HData.DEVICE .. " is starting up!",log.LLInfo)
	--	Start polling for status and HTTP request handler when set-up is successful
	local srv = var.GetNumber("HTTPServer")
	log.Debug("HTTPServer " .. srv)	
	-- Start public handler on request
	if (srv == 1) then luup.register_handler ("HTTP_Harmony", "Harmony".. HData.DEVICE) end
	luup.register_handler ("HTTP_HarmonyInt", "hamGetActivities".. HData.DEVICE)
	luup.register_handler ("HTTP_HarmonyInt", "hamGetDevices".. HData.DEVICE)
	luup.register_handler ("HTTP_HarmonyInt", "hamGetDeviceCommands".. HData.DEVICE)
	-- Generate children, new or removed ones will cause a reload
	Harmony_CreateChildren()
	SetBusy(false, false)
	-- Look for current activity to start off with
	luup.call_delay("Harmony_PollCurrentActivity", 6, "", false)
	-- If debug level, keep tap on memory usage too.
	checkMemory()
	setStatusIcon(HData.Icon.IDLE)
	return true
end

-- Initialize our device
function Harmony_init(lul_device)
	HData.DEVICE = lul_device
	-- start Utility API's
	log = logAPI()
	var = varAPI()
	utils = utilsAPI()
	var.Initialize(HData.SIDS.MODULE, HData.DEVICE)
	
	var.Default("LogLevel", log.LLError)
	log.Initialize(HData.Description, var.GetNumber("LogLevel"))
	utils.Initialize()
	ws_client = wsAPI() -- 2.28b
	
	SetBusy(true,false)
	setStatusIcon(HData.Icon.WAIT)
	log.Log("Harmony device #" .. HData.DEVICE .. " is initializing!",log.LLInfo)
	-- See if we are running on openLuup.
	log.Log("We are running on "..utils.GetUI())
	if (utils.GetUI() == utils.IsOpenLuup) then
		HData.onOpenLuup = true
		log.Log("We are running on openLuup!!")
	end
	
	-- See if user disabled plug-in 
	local disabled = var.GetAttribute("disabled")
	if (disabled == 1) then
		log.Log("Init: Plug-in version "..HData.Version.." - DISABLED",log.LLWarning)
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
	local altid = var.GetAttribute('altid') or ""
	if (altid == "") then var.SetAttribute('altid', 'HAM'..HData.DEVICE..'_CNTRL') end
	-- Make sure all (advanced) parameters are there
--	local email = var.Default("Email")
--	local pwd = var.Default("Password")
	local commTimeOut = tonumber(var.Default("CommTimeOut",5))
	var.Default("HTTPServer", 0)
	var.Default("PollInterval",0)
	var.Default("PollHomeOnly",0)
	var.Default("OkInterval",3)
	-- V2.15, option to wait on completion of start activity
	local wait = (var.Default("WaitOnActivityStartComplete", "1") == "1")
	var.Default("AuthorizationToken")
	var.Default("PluginHaveChildren")
	var.Default("PluginEmbedChildren", "0")
	var.Default("DefaultActivity")
	-- Do not reset the values on restart, only default when non existent
	var.Default("LinkStatus", "--")
	var.Default("LastCommand", "--")
	var.Default("LastCommandTime", "--")
	var.Default("CurrentActivityID")
	var.Default("Target", "0", HData.SIDS.SP)
	var.Default("Status", "0", HData.SIDS.SP)
	var.Default("UIVersion", "2.20")
	var.Set("Version", HData.Version)
	local forcenewjson = false
	-- Make sure icons are accessible when they should be, even works after factory reset or when single image link gets removed or added.
	if (HData.onOpenLuup == false) then utils.CheckImages(HData.Images) end
	-- See if we are upgrading UI settings, if so force rewrite of JSON files.
	local version = var.Get("UIVersion")
	if (version ~= HData.UIVersion) then forcenewjson = true end
	-- When the RemoteIcons flag changed, we must force a rewrite of the JSON files as well.
	local remicons = var.Get("RemoteImages")
	local remiconsprv = var.Get("RemoteImagesPrv")
	if (remicons ~= remiconsprv) then
		var.Set("RemoteImagesPrv",remicons)
		forcenewjson = true
	else
		-- Default setting. It was 1 (remote) on older versions, will be 0 (local) on new.
		if (remicons == '') then
			var.Set("RemoteImages",0)
			var.Set("RemoteImagesPrv",0)
		end	
	end
	if (forcenewjson == true) then
		local ipa = var.GetAttribute("ip")
		var.Default("HubIPAddress", ipa)
		-- Bump loglevel to monitor rewrite
		log.Log("Force rewrite of JSON files for correct Vera software version and configuration.",log.LLWarning)
		-- Set the category to switch if needed
		local catid = var.GetAttribute('category_num') or ""
		if (catid ~= '3') then var.SetAttribute('category_num', '3') end
		-- Rewrite JSON files for main device
		Harmony_UpdateButtons(HData.DEVICE, true)
		-- Make default JSON for child devices D_HarmonyDevice.json
		make_JSON_file('','D_HarmonyDevice',false,true)
		log.Log("Rewritten files for main device # " .. HData.DEVICE)
		-- Then for any child devices, as they are not yet set, we must look at altid we use.
		removeObsoleteChildDeviceFiles()
		local childDeviceIDs = var.Get("PluginHaveChildren")
		if (childDeviceIDs ~= "") then
			for devNo, deviceID in pairs(luup.devices) do
				local altid = string.match(deviceID.id, 'HAM'..HData.DEVICE..'_%d+')
				local chdevID = var.Get("DeviceID", HData.SIDS.CHILD, devNo)
				if (altid ~= nil) then 
					local tmp
					tmp, altid = string.match(altid, "(%d+)_(%d+)")
					if (chdevID == altid) then
						Harmony_UpdateDeviceButtons(devNo,true)
						local catid = var.GetAttribute('category_num',devNo) or ""
						if (catid ~= '3') then var.SetAttribute('category_num', '3',devNo) end
						log.Log("Rewritten files for child device # " .. devNo .. " name " .. chdevID)
						-- Hide the delete button for the child devices
						var.Default("HideDeleteButton", 1, HData.SIDS.HA, devNo)
					else
						log.Log("Child device # " .. devNo .. " does not have a matching DeviceID set.")
					end	
				else
					-- See if I have older version type device that is supported by this hub
					altid = string.match(deviceID.id, 'HAM_%d+')
					if (altid ~= nil) then 
						altid = string.match(altid, "%d+")
						chdevID = var.Get("DeviceID", HData.SIDS.MODULE, devNo) 
						local suppchID = string.match(childDeviceIDs, chdevID)
						if (chdevID == altid) and (chdevID == suppchID) then
							-- Transfer values from old to new
							log.Log("Transferring settings for child device # "..devNo..", name "..chdevID.." from Harmony to HarmonyDevice")
							var.Set("DeviceID", chdevID, HData.SIDS.CHILD, devNo)
							for idx = 1, 24 do
								local cmdV = var.Get("Command"..idx, HData.SIDS.MODULE, devNo)
								local cmdD = var.Get("CommandDesc"..idx, HData.SIDS.MODULE, devNo)
								if (cmdV ~= "") then 
									var.Set("Command"..idx, cmdV, HData.SIDS.CHILD, devNo)
									var.Set("Command"..idx, "", HData.SIDS.MODULE, devNo)
								end
								if (cmdD ~= "") then 
									var.Set("CommandDesc"..idx, cmdD, HData.SIDS.CHILD, devNo)
									if (idx == 1) then
										var.Set("CommandDesc"..idx, "REFRESH", HData.SIDS.MODULE, devNo)
									elseif (idx == 2) then	
										var.Set("CommandDesc"..idx, "BROWSER", HData.SIDS.MODULE, devNo)
									else
										var.Set("CommandDesc"..idx, "", HData.SIDS.MODULE, devNo)
									end
								end
							end
							-- We should only do this once
							var.Set("DeviceID", "", HData.SIDS.MODULE, devNo)
							-- Now rewrite buttons, and correct alt ID and device type
							Harmony_UpdateDeviceButtons(devNo,true)
							local chd_type = var.GetAttribute('device_type',devNo)
							var.SetAttribute('device_type',chd_type:gsub('_'..chdevID,HData.DEVICE..'_'..chdevID),devNo)
							var.SetAttribute('altid','HAM'..HData.DEVICE..'_'..chdevID,devNo)
							local catid = var.GetAttribute('category_num',devNo) or ""
							if (catid ~= '3') then var.SetAttribute('category_num', '3',devNo) end
							log.Log("Rewritten files for child device # " .. devNo .. " name " .. chdevID)
						end
					end
				end
			end
		else
			log.Log("No child devices.",log.LLInfo)
		end
		var.Set("UIVersion", HData.UIVersion)
		-- Sleep for 5 secs, just in case we have multiple plug in copies that try to migrate. They must all have time to finish.
		luup.sleep(5000)
		-- We must reload for new files to be picked up
		utils.ReloadLuup()
	else
		log.Log("UIVersion is current : " .. version,log.LLInfo)
	end
	-- Call to register with ALTUI
--	luup.call_delay("Harmony_registerWithAltUI", 10, "", false)
--	Harmony_registerWithAltUI()
	
	-- Check that we have to parameters to get started
	local success = true
--	local ipa = luup.devices[HData.DEVICE].ip
--	local ipa = var.GetAttribute("ip")
	local ipa =	var.Default("HubIPAddress","")
	local ipAddress = string.match(ipa, '^(%d%d?%d?%.%d%d?%d?%.%d%d?%d?%.%d%d?%d?)')
	-- Some cases IP gets stuck in variable and no in attribute (openLuup or ALTUI bug)
	if (ipAddress == nil) then
		setStatusIcon(HData.Icon.ERROR)
		SetBusy(false,false)
		utils.SetLuupFailure(1, HData.DEVICE)
		return false, "Configure IP Address.", HData.Description
	end
	log.Log("Using Harmony Hub: IP address " .. ipAddress, log.LLInfo)
	Harmony = HarmonyAPI(ipAddress, wait)
	if (Harmony == nil) then 
		success = false 
	else
		-- Open connection
		success = Harmony.Connect()
		if (not success) then
			Harmony = nil
		end
	end
	if (Harmony == nil) then 
		setStatusIcon(HData.Icon.ERROR)
		SetBusy(false,false)
		utils.SetLuupFailure(2, HData.DEVICE)
		return false, "Hub connection set-up failed. Check IP Address, email and password.", HData.Description
	end	
	--	Schedule to finish rest of start up in a few seconds
	luup.call_delay("Harmony_Setup", 3, "", false)
	log.Debug("Harmony Hub Control: init_module completed ")
	utils.SetLuupFailure(0, HData.DEVICE)
	return true
end

-- See if we have incoming data, should not happen
function Harmony_Incoming(lul_data)
	if (lul_data) then
		log.Debug("Incoming received : " .. tostring(lul_data))
	end
	return true
end

