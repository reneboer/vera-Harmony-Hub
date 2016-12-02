--[==[
	Module L_Harmony1.lua
	
	Written by R.Boer. 
	V2.11 2 December 2016
	
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

local socketLib = require("socket")
local json = require("dkjson")
if (type(json) == "string") then
	luup.log("Harmony warning dkjson missing, falling back to harmony_json", 2)
	json = require("harmony_json")
end
--local dkjson = require('harmony_json')

local Harmony -- Harmony API data object

local HData = { -- Data used by Harmony Plugin
	Version = "2.11",
	DEVICE = "",
	Description = "Harmony Control",
	SWSID = "urn:upnp-org:serviceId:SwitchPower1",
	SID = "urn:rboer-com:serviceId:Harmony1",
	CHSID = "urn:rboer-com:serviceId:HarmonyDevice1",
	ALTUI_SID = "urn:upnp-org:serviceId:altui1",
	RemoteIconURL = "http://www.reneboer.demon.nl/veraimg/",
	UI7IconURL = "",
	UI5IconURL = "icons\/",
	f_path = '/etc/cmh-ludl/',
	onOpenLuup = false,
	syslog,
	MaxButtonUI5 = 24,  -- Keep the same as HAM_MAXBUTTONS in J_Harmony.js
	MaxButtonUI7 = 25,  -- Keep the same as HAM_MAXBUTTONS in J_Harmony_UI7.js
	Plugin_Disabled = false,
	LogLevel = 3,
--	LogLevel = 10,
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
local function log(text, level) 
	local level = (level or 10)
	if (HData.LogLevel >= level) then
		if (HData.syslog) then
			local slvl
			if (level == 1) then slvl = 2 
			elseif (level == 2) then slvl = 4 
			elseif (level == 3) then slvl = 5 
			elseif (level == 4) then slvl = 5 
			elseif (level == 7) then slvl = 6 
			elseif (level == 8) then slvl = 6 
			else slvl = 7
			end
			HData.syslog:send(text,slvl) 
		else
			if (level == 10) then level = 50 end
			luup.log(HData.Description .. ": " .. text or "no text", (level or 50)) 
		end	
	end	
end 
-- Get variable value.
-- Use HData.SID and HData.DEVICE as defaults
local function varGet(name, device, service)
	local value = luup.variable_get(service or HData.SID, name, tonumber(device or HData.DEVICE))
	return (value or '')
end
-- Update variable when value is different than current.
-- Use HData.SID and HData.DEVICE as defaults
local function varSet(name, value, device, service)
	local service = service or HData.SID
	local device = tonumber(device or HData.DEVICE)
	local old = varGet(name, device, service)
	if (tostring(value) ~= tostring(old)) then 
		luup.variable_set(service, name, value, device)
	end
end
--get device Variables, creating with default value if non-existent
local function defVar(name, default, device, service)
	local service = service or HData.SID
	local device = tonumber(device or HData.DEVICE)
	local value = luup.variable_get(service, name, device) 
	if (not value) then
		value = default	or ''							-- use default value or blank
		luup.variable_set(service, name, value, device)	-- create missing variable with default value
	end
	return value
end
-- Set message in task window.
local function task(text, mode) 
	local mode = mode or TaskData.ERROR 
	if (mode ~= TaskData.SUCCESS) then 
		if (mode == TaskData.ERROR_PERM) then
			log("task: " .. (text or "no text"), 1) 
		else	
			log("task: " .. (text or "no text")) 
		end 
	end 
	TaskData.taskHandle = luup.task(text, (mode == TaskData.ERROR_PERM) and TaskData.ERROR or mode, TaskData.Description, TaskData.taskHandle) 
end 
-- Set a luup failure message
local function setluupfailure(status,devID)
	if (luup.version_major < 7) then status = status ~= 0 end        -- fix UI5 status type
	luup.set_failure(status,devID)
end
-- V2.4 Check how much memory the plug in uses
function checkMemory()
	local AppMemoryUsed =  math.floor(collectgarbage "count")         -- app's own memory usage in kB
	varSet("AppMemoryUsed", AppMemoryUsed) 
	luup.call_delay("checkMemory", 600)
end
-- Syslog server support. From Netatmo plugin by akbooer
local function syslog_server (ip_and_port, tag, hostname)
	local sock = socketLib.udp()
	local facility = 1    -- 'user'
	local emergency, alert, critical, error, warning, notice, info, debug = 0,1,2,3,4,5,6,7
	local ip, port = ip_and_port: match "^(%d+%.%d+%.%d+%.%d+):(%d+)$"
	if not ip or not port then return nil, "invalid IP or PORT" end
	local serialNo = luup.pk_accesspoint
	hostname = ("Vera-"..serialNo) or "Vera"
	if not tag or tag == '' then tag = HData.Description end
	tag = tag:gsub("[^%w]","") or "HarmonyHub"  -- only alphanumeric, no spaces or other
	local function send (self, content, severity)
		content  = tostring (content)
		severity = tonumber (severity) or info
		local priority = facility*8 + (severity%8)
		local msg = ("<%d>%s %s %s: %s\n"):format (priority, os.date "%b %d %H:%M:%S", hostname, tag, content)
		sock:send (msg) 
	end
	local ok, err = sock:setpeername(ip, port)
	if ok then ok = {send = send} end
	return ok, err
end
-- Set the status Icon
local function setStatusIcon(status, devID, sid)
	if (status == HData.Icon.OK) then
		-- When status is success, then clear after number of seconds
		local idleDelay = varGet("OkInterval")
		if (tonumber(idleDelay) > 0) then
			varSet(HData.Icon.Variable, HData.Icon.OK, devID, sid)
			luup.call_delay("idleStatusIcon", idleDelay, tostring(devID or ""), false)
		else
			varSet(HData.Icon.Variable, HData.Icon.IDLE, devID, sid)
		end
	else	
		varSet(HData.Icon.Variable, status, devID, sid)
	end
end
function idleStatusIcon(devIDstr)
	local devID
	if (devIDstr ~= "") then devID = tonumber(devIDstr) end
	local status = varGet(HData.Icon.Variable, devID)
	-- When status is success, then clear else do not change
	if (status == HData.Icon.OK) then
		varSet(HData.Icon.Variable, HData.Icon.IDLE, devID)
	end
end
-- Luup Reload function for UI5,6 and 7
local function luup_reload()
	if (luup.version_major < 6) then 
		luup.call_action("urn:micasaverde-com:serviceId:HomeAutomationGateway1", "Reload", {}, 0)
	else
		luup.reload()
	end
end
-- Create links for UI6 or UI7 image locations if missing.
local function check_images(imageTable)
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
local function HarmonyAPI(ipAddress, email, pwd, commTimeOut)
	local CommunicationPort = 5222
	local ERR_CD = { OK = "200", ERR = "503" }
	local ERR_MSG = { OK = "OK", ERR = "Unknown Harmony response" }
	local CMD_DATA = { OK = "No Data", ERR = "" }
	local PAT_ERRCODE = { PAT = "errorcode='%d-'", DEF = "errorcode='" .. ERR_CD.OK .. "'", ST = 12, EN = -2 }
	local PAT_ERRMSG = { PAT = "errorstring='.-'", DEF = "errorstring='" .. ERR_MSG.OK .. "'", ST = 14, EN = -2 }
--	local PAT_DATA = { PAT = "!%[CDATA%[.+%]%]></oa>", DEF = "![CDATA[" .. CMD_DATA.OK .. "]]></oa>", ST = 9, EN = -9}
	local PAT_DATA = { PAT = "!%[CDATA%[.+%]%]>", DEF = "![CDATA[" .. CMD_DATA.OK .. "]]>", ST = 9, EN = -4}
	local numberOfMessages = 5	-- Number of messages returned on holdAction command.
	local timestamp = 10000
	local sock
	local sessToken
	local ipa = ipAddress
	local email = email
	local pwd = pwd
	-- V2.1 Configurable time out
	local commTimeOut = (commTimeOut or 5)
	local isBusy = false
	
	-- Get the response from the Hub. The end of the return message is identified by the respClose string.
	local function GetHubResponse(respClose)
		local resp = {}
		local markLen = respClose:len()
		local mark = 1
		local marktab = {}
		local cnt
		
		for cnt = 1, markLen do
			marktab[cnt] = respClose:sub(cnt,cnt)
		end
		cnt = 1
		repeat
			s, st, par = sock:receive(1)
			if (s) then 
				resp[cnt] = s
				cnt = cnt + 1
				if (marktab[mark] == s) then
					mark = mark + 1
				else
					mark = 1
				end
			else
				break
			end
		until mark > markLen
		return table.concat(resp)
	end

	-- Open socket to Hub
	local function Connect()
		if ((ipa or "") == "") then log("Connect, no IP Address specified ",1) return false end
		sock = socketLib.connect(ipa, CommunicationPort)
		if (sock == nil) then log("Connect, failed to open socket to hub " .. ipa, 1) return false end
		-- V2.1 suggestion, data should normally come back faster than the default 60 seconds
		sock:settimeout(commTimeOut)
		return true
	end

	-- Get the token, for now user needs to enter in variable
	local function GetAuthorizationToken()
		return true
	end

	-- Get the Session Token using the Authentication token
	local function GetSessionToken(authToken)
		-- Any token seems to do at the moment, Authentication is a farce
		varSet("AuthorizationToken", "guest")
		sessToken = "guest"
		return true
	end

	-- Start communication with the Hub
	local function StartCommunication(UserName, Password)
		return true
	end

	-- Submit the command to the Hub and process response string
	-- Input command = Hub command, id = activity or device ID, devcmd = device command, msgwait if true wait for last message from harmony on startActivity
	local function SubmitCommand(command, id, devcmd, msgwait, prs)

		if (isBusy) then return ERR_CD.ERR, "BUSY", "Busy with other command" end
		isBusy = true
		local msgcnt = 0
		
		local cmdStr = '<iq id="' .. sessToken .. '" from="guest" type="get"><oa xmlns="connect.logitech.com" mime="vnd.logitech.harmony/vnd.logitech.harmony.engine?'
		-- Build the command string
		local cmd = (command or "")
		if (cmd == 'getCurrentActivity') then
			cmdStr = cmdStr .. 'getCurrentActivity" /></iq>'
		elseif (cmd == 'startactivity') then
			cmdStr = cmdStr .. 'startactivity">activityId=' .. id .. ':timestamp='..timestamp..'</oa></iq>'
			msgcnt = 1
			sock:settimeout(50)
			timestamp = timestamp + 100
		elseif (cmd == 'config') then
			cmdStr = cmdStr .. 'config"></oa></iq>'
		elseif (cmd == 'holdAction') then
			cmdStr = cmdStr .. 'holdAction">action={"command"::"' .. devcmd .. '","type"::"IRCommand","deviceId"::"' .. id .. '"}:status='..(prs or 'press')..':timestamp='..timestamp..'</oa></iq>'
			if (prs == 'press') then timestamp = timestamp + 54 else timestamp = timestamp + 100 end
		elseif (cmd == 'holdActionInt') then
			cmdStr = cmdStr .. 'holdAction">' .. devcmd .. ':status='..(prs or 'release')..':timestamp='..timestamp..'</oa></iq>'
			if (prs == 'press') then timestamp = timestamp + 54 else timestamp = timestamp + 100 end
		else	
			log("SubmitCommand, Unknown command " .. cmd,10)
			isBusy = false
			return ERR_CD.ERR, "Unknown command", cmd
		end
		if (timestamp > 90000) then timestamp = 10000 end
		local cmdResp, msgResp, errCode, errMsg
		local reply = sock:send(cmdStr)
		if (not reply) then 
			isBusy = false
			return ERR_CD.ERR, ERR_MSG.ERR, 'failed to send command '.. cmdStr 
		end
		-- At holdAction the Harmony Hub closes the connection without returning data
		local done = false
		local starttime = os.time()
		-- First look for the <iq/> confirmation from the hub. Should be fast
		local ret, status, partial = sock:receive('5')
		if ((ret or "") == '<iq/>') then 
			-- At holdAction the Harmony Hub does not return additional data
			if (cmd == 'holdAction') or (cmd == 'holdActionInt') then 
				isBusy = false
				return ERR_CD.OK, ERR_MSG.OK, CMD_DATA.OK 
			end
			-- V2.1 suggestion, rest of data may not come back as quickly especially for StartActivity, so minimum timeout of 30 secs in 
--			if (msgcnt == 1) then sock:settimeout(30) end
			repeat
				-- Check to see if we are getting a message (<me) or response (<iq)
				local ret, status, partial = sock:receive('3')
				if ((ret or "") == '<iq') then 
					-- read until we got </iq> closing tag
					local hubResp = ret .. GetHubResponse('</iq>')
					-- Get error code, error message, and response data. Use defaults if missing
					errCode = hubResp:match(PAT_ERRCODE.PAT) or PAT_ERRCODE.DEF
					errMsg = hubResp:match(PAT_ERRMSG.PAT) or PAT_ERRMSG.DEF
					cmdResp = hubResp:match(PAT_DATA.PAT) or PAT_DATA.DEF
					errCode = errCode:sub(PAT_ERRCODE.ST,PAT_ERRCODE.EN)
					errMsg = errMsg:sub(PAT_ERRMSG.ST,PAT_ERRMSG.EN)
					cmdResp = cmdResp:sub(PAT_DATA.ST,PAT_DATA.EN)
					starttime = os.time()
					-- Look for the number of messages to expect back. V2.6 improvement.
					if (cmd == 'startactivity') then 
						if (cmdResp ~= CMD_DATA.OK) then
							local dmCnt, tmCnt = 0,0
							local doneMsg = cmdResp:match("done=%d")
							local totMsg = cmdResp:match(":total=%d")
							if totMsg then tmCnt = tonumber(totMsg:match("%d")) end
							if doneMsg then dmCnt = tonumber(doneMsg:match("%d")) end
							if (dmCnt == tmCnt) then done = true end
						end
					else	
						done = true
					end	
				elseif ((ret or "") == '<me') then 
					log("Get message ",10)
					-- get message length part, then the message
					_ = GetHubResponse('/>')
					msgResp = GetHubResponse('</message>')
					if (cmd == 'startactivity') then 
						cmdResp = msgResp:match(PAT_DATA.PAT) or PAT_DATA.DEF
						cmdResp = cmdResp:sub(PAT_DATA.ST,PAT_DATA.EN)
						if (cmdResp == "activityId="..id) then done = true end
					end
					starttime = os.time()
				else
					-- Not sure what we are getting after the normal acknowledge, but return it
					log("SubmitCommand, invalid response from Hub after acknowledge |" .. (ret or "") .."|",10) 
					errCode, errMsg, cmdResp = ERR_CD.ERR, ERR_MSG.ERR, '<iq/>' .. ( ret or "") 
					done = true
				end	
				-- Check for time out
				if (done == false) and (os.difftime(os.time(), starttime) > (commTimeOut * 5)) then 
					log("SubmitCommand, time out waiting response from Hub after acknowledge : " .. ( ret or ""),10) 
					errCode, errMsg, cmdResp = ERR_CD.ERR, ERR_MSG.ERR, 'timeout' 
					done = true
				end
			until done
		else
			-- Not getting the response we are assuming
			log("SubmitCommand, invalid response from Hub instead of acknowledge : " .. ( ret or ""),10) 
			errCode, errMsg, cmdResp = ERR_CD.ERR, ERR_MSG.ERR, ( ret or "") 
		end
		-- V2.1 suggestion, data should normally come back faster than the default 60 seconds
		sock:settimeout(commTimeOut)
		isBusy = false
		return errCode, errMsg, cmdResp
	end
	
	-- Close socket to Hub
	local function Close()
		if (sock ~= nil) then sock:close() end
		sock = nil
		return true
	end

	return{ -- Methods
		Connect = Connect,
		GetAuthorizationToken = GetAuthorizationToken,
		GetSessionToken = GetSessionToken,
		StartCommunication = StartCommunication,
		SubmitCommand = SubmitCommand,
		Close = Close
	}
end
---------------------------------------------------------------------------------------------
-- Harmony Plugin functions
---------------------------------------------------------------------------------------------
-- Update the last command sent to Hub and when
local function SetLastCommand(cmd)
	varSet("LastCommand", cmd)
	varSet("LastCommandTime", os.date("%X %a, %d %b %Y"))
end

-- Send the command to the Harmony Hub.
-- Return Status true on success and return string, else false
local function Harmony_cmd(cmd, id, devCmd, prs)
	if (Harmony == nil) then 
		varSet("LinkStatus","Error")
		return false, "501", "No handler", " " 
	end
	local stat, msg, harmonyOutput
	log("Sending command cmd=" .. cmd,10)
	local stat = Harmony.Connect()
	if (stat == true) then 
		stat, msg, harmonyOutput = Harmony.SubmitCommand(HData.CMD[cmd].cmd, id, devCmd, false, prs)
		Harmony.Close()
	else
		stat = '423'
		msg = 'Failed to connect to Harmony Hub'
		harmonyOutput = ''
	end
	if (stat == '200') then
		task("Clearing...", TaskData.SUCCESS)
		varSet("LinkStatus","Ok")
		log("CMD: return value : " .. stat .. ", " .. msg .. ", " .. harmonyOutput:sub(1,50),10)
		return true, stat, msg, harmonyOutput
	else
		varSet("LinkStatus","Error")
		log("CMD: errcode="  .. stat .. ", errmsg=" .. msg,10)
		task("CMD: Failed sending command " .. cmd .. " to Harmony Hub - errorcode="  .. stat .. ", errormessage=" .. msg, TaskData.ERROR)
		return false, stat, msg, (harmonyOutput or '')
	end	
end

-- Periodically send the GetCurrentActivity command to see where we are at
-- When PollInterval is zero then do not repeat it.
function Harmony_PollCurrentActivity()
	-- See if user want to repeat polling
	local pollper = varGet("PollInterval")
	if ((pollper or "0") ~= "0") then 
		luup.call_delay("Harmony_PollCurrentActivity", tonumber(pollper), "", false)
		-- See if we are not polling too close to start activity. This can give false results
		if (not GetBusy()) and (os.difftime(os.time(), HData.StartActivityBusy) > 30) then
			local stat, actID = Harmony_GetCurrentActivtyID()
			if (stat == true) then 
				log('PollCurrentActivity found activity ID : ' .. actID,10) 
-- V2.7 Now in Harmony_GetCurrentActivtyID()
--				-- Set the target and activity so we can show off/on on Vera App
--				if (actID ~= '-1') then 
--					varSet("Target", "1", HData.DEVICE, HData.SWSID)
--					varSet("Status", "1", HData.DEVICE, HData.SWSID)
--				else 
--					varSet("Target", "0", HData.DEVICE, HData.SWSID)
--					varSet("Status", "0", HData.DEVICE, HData.SWSID)
--				end
			else 
				log('PollCurrentActivity error getting activity',10) 
			end
		else 
			log('PollCurrentActivity busy or too close to Activity change',10) 
		end
	else
		log('PollCurrentActivity stopping polling.',8)
	end	
end

-- Send Get Config command 
-- When format if JSON return JSON object, else string
function Harmony_GetConfig(cmd, id, fmt)
	local message = ''
	local dataTab = {}
	log("GetConfig",10)
	local status, cd, msg, harmonyOutput = Harmony_cmd('get_config')
	if (status == true) then
		SetLastCommand(cmd)
		local confg, pos, stat=json.decode(harmonyOutput)
		if (stat) then 
			message = "Failed to decode GetConfig to JSON received. "
			status = false
		else
			-- See what part we need to return
			if (cmd == 'list_activities') then 
				log("Activities found : " .. #confg.activity,10)
				-- List all activities supported
				dataTab.activities = {}
				for i = 1, #confg.activity do
					dataTab.activities[i] = {}
					dataTab.activities[i].ID = confg.activity[i].id
					dataTab.activities[i].Activity = confg.activity[i].label
				end
			elseif (cmd == 'list_commands') then
				log("Devices found : " .. #confg.device,10)
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
				log("Devices found : " .. #confg.device,10)
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
				log("Devices found : " .. #confg.device,10)
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
				log("Devices found : " .. #confg.device,10)
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
		end
	else
		message = " failed to send GetConfig command...  errorcode="  .. cd .. ", errormessage=" .. msg
	end
	-- If we had an error return that
	if (status == false) then 
		log("GetConfig, " .. message) 
		dataTab.status = HData.ER 
		dataTab.message = message .. (harmonyOutput or "")
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
		log("IssueDeviceCommand : Plugin disabled.",3)
		return true
	end
	local cmd = 'issue_device_command'
	local status, harmonyOutput
	local message = ''
	local dur = tonumber(devDur) or 0
	local hnd = hnd or false
	-- When not called from HTTP Request handler, set busy status
	if (hnd == false) then 
		if (GetBusy()) then
			log("IssueDeviceCommand communication is busy",10)
			return false 
		end
		SetBusy(true, true)
	end
	log("IssueDeviceCommand, devID : " .. devID .. ", devCmd : " .. devCmd .. ", devDur : " .. dur,10)
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
	if (status == false) then log("ERROR: IssueDeviceCommand, " .. message) end
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
		log("GetCurrentActivtyID : Plugin disabled.",3)
		return true, "Plugin Disabled"
	end
	local cmd = 'get_current_activity_id'
	local message = ''
	local currentActivity = ''
	local hnd = hnd or false
	-- When not called from HTTP Request handler, set busy status
	if (hnd == false) then 
		if (GetBusy()) then 
			log("GetCurrentActivtyID communication is busy",10)
			return false 
		end
		SetBusy(true, true)
	end
	log("GetCurrentActivtyID",10)
	local status, cd, msg, harmonyOutput = Harmony_cmd(cmd)
	if (status == true) then
		log("GetCurrentActivtyID : " .. (harmonyOutput or ""),10)
-- V2.10 start
--		-- Check length of reported activity, if 2 or 8
--		local ln = harmonyOutput:len()
--		if (l == 9 or ln == 15) then
--			currentActivity = harmonyOutput:match('result=(-?[0-9]*)')
		currentActivity = harmonyOutput:match('result=(-?[0-9]*)') or ''
		if (tonumber(currentActivity)) then
--V2.10 end		
			SetLastCommand(cmd)
			log("GetCurrentActivtyID found activity : " .. currentActivity,10)
			varSet("CurrentActivityID", currentActivity)
			-- Set the target and activity so we can show off/on on Vera App
			if (currentActivity ~= '-1') then 
				varSet("Target", "1", HData.DEVICE, HData.SWSID)
				varSet("Status", "1", HData.DEVICE, HData.SWSID)
			else 
				varSet("Target", "0", HData.DEVICE, HData.SWSID)
				varSet("Status", "0", HData.DEVICE, HData.SWSID)
			end
		else
			message = "failed to Get Current Activity...  errorcode="  .. cd .. ", errormessage=" .. msg
			log("GetCurrentActivtyID, ERROR " .. message .. " : " .. (harmonyOutput or "")) 
-- V2.10			currentActivity = ''
			status = false
		end
	else
		message = "failed to Get Current Activity...  errorcode="  .. cd .. ", errormessage=" .. msg
		log("GetCurrentActivtyID, ERROR " .. message ..  " : " .. (harmonyOutput or "")) 
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
			dataTab.message = message .. (harmonyOutput or "")
		end
		return status, dataTab
	end	
end

-- Send StartActivity to Harmony Hub
-- Input: actID = activity ID, hnd = true when called from HTTPhandler
-- Output: True on success, or JSON when called from HTTPhandler
function Harmony_StartActivity(actID, hnd, fmt)
	if (HData.Plugin_Disabled == true) then
		log("StartActivity : Plugin disabled.",3)
		return true
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
			log("StartActivity communication is busy",10)
			return false 
		end
		SetBusy(true, true)
	end
	log("StartActivity, newActivityID : " .. actID,10)
	if (actID ~= "") then 
		-- Start activity
		log("StartActivity, ActivityID : " .. actID,10)
		-- Set value now to give quicker user feedback on UI
-- V2.7 causes issues when failing
--		varSet("CurrentActivityID", actID)
		status, cd, msg, harmonyOutput = Harmony_cmd (cmd, actID)
		if (status == true) then
			varSet("CurrentActivityID", actID)
			-- Set the target and activity so we can show off/on on Vera App
			if (actID ~= '-1') then 
				varSet("Target", "1", HData.DEVICE, HData.SWSID)
				varSet("Status", "1", HData.DEVICE, HData.SWSID)
			else 
				varSet("Target", "0", HData.DEVICE, HData.SWSID)
				varSet("Status", "0", HData.DEVICE, HData.SWSID)
			end
			SetLastCommand(cmd)
		else
			message = "failed to start Activity... errorcode="  .. cd .. ", errormessage=" .. msg
-- V2.7 do not set if we do not know.
--			varSet("CurrentActivityID", "")
		end	
	else
		message = "no newActivityID specified... "
	end	
	if (status == false) then log("StartActivity, ERROR " .. message .. (harmonyOutput or "")) end
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
			dataTab.activity = (harmonyOutput or "")
		else 
			dataTab.status = HData.ER 
			dataTab.message = message .. (harmonyOutput or "")
			dataTab.activity = ""
		end
		return status, dataTab
	end	
end

-- , devDur = key-press duration in seconds
function Harmony_SendDeviceCommand(lul_device,devCmd,devDur)
	if (HData.Plugin_Disabled == true) then
		log("SendDeviceCommand : Plugin disabled.",3)
		return true
	end
	local cmd = (devCmd or "")
	local dur = (devDur or "0")
	local devID = varGet("DeviceID",lul_device, HData.CHSID)
	local prevCmd = varGet("LastDeviceCommand",lul_device, HData.CHSID)
	log("SendDeviceCommand "..cmd.." for device #"..lul_device.." to Harmony Device "..devID,10)
	varSet("LastDeviceCommand",cmd,lul_device, HData.CHSID)
	local starttime = os.time()
	setStatusIcon(HData.Icon.BUSY, lul_device, HData.CHSID)
	local status = Harmony_IssueDeviceCommand(devID, cmd, dur)
	-- see if user want to show the button status for a tad longer
	local idleDelay = varGet("OkInterval")
	if (tonumber(idleDelay) > 0) then
		luup.call_delay('Harmony_SendDeviceCommandEnd',tonumber(idleDelay), tostring(lul_device), false)
	else
		setStatusIcon(HData.Icon.IDLE, lul_device, HData.CHSID)
		varSet("LastDeviceCommand","",lul_device, HData.CHSID)
	end
	return status
end
-- Clear the last device command after no button has been clicked for more then OkInterval seconds
function Harmony_SendDeviceCommandEnd(devID)
	log('SendDeviceCommandEnd for child device #'..devID,10)
	if (devID == nil) then return end
	if (devID == '') then return end
	local lul_device = tonumber(devID)
	local value, tstamp = luup.variable_get(HData.CHSID, "LastDeviceCommand", lul_device)
	value = value or ""
	luup.log('LastDeviceCommand current value'..value)
	if (value ~= "") then
		local idleDelay = varGet("OkInterval")
		if (tonumber(idleDelay) > 0) then
			if (os.difftime(os.time(), tstamp) > tonumber(idleDelay)) then
				setStatusIcon(HData.Icon.IDLE, lul_device, HData.CHSID)
				varSet("LastDeviceCommand","",lul_device, HData.CHSID)
			else	
				luup.call_delay('Harmony_SendDeviceCommandEnd',1, devID)
			end
		else	
			setStatusIcon(HData.Icon.IDLE, lul_device, HData.CHSID)
			varSet("LastDeviceCommand","",lul_device, HData.CHSID)
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
	log('request is: '..tostring(lul_request),10)
	for k,v in pairs(lul_parameters) do 
		log ('parameters are: '..tostring(k)..'='..tostring(v),10) 
		k = k:lower()
		if (k == 'cmd') then cmd = v 
		elseif (k == 'format') then outFormat = v 
		elseif (k == 'cmdp1') then cmdp1 = v 
		elseif (k == 'cmdp2') then cmdp2 = v 
		elseif (k == 'cmdp3') then cmdp3 = v 
		end
	end
	log('outputformat is: '..outFormat,10)
	if (GetBusy()) then
		log('we are busy..fail... ',10)
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
		log('Busy processing other request, sleep a second.',10)
		return 'Busy processing other request. Please retry in a moment.'
--		luup.sleep(1000)
	end
	SetBusy(true,true)
	log('request is: '..tostring(lul_request),10)
	log('outputformat is: '..tostring(lul_outputformat),10)
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
		log("unsupported format")
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
	local tmpfile = '/tmp/ham'..HData.DEVICE..'_file.txt'
	os.execute('ls -A1 '..HData.f_path..'D_HarmonyDevice'..HData.DEVICE..'_*.* > '..tmpfile)
	for fname in io.lines(tmpfile) do
		local dname = string.match(fname, "D_HarmonyDevice'..HData.DEVICE..'_%d+.")
		local dnum, tmp
		if (dname ~= nil) then tmp,dnum = string.match(dname, "(%d+)_(%d+)") end
		if (dnum ~= nil) then
			-- We have a child device file, see if the number is still in list of child devices
			dname = string.match(chDev, dnum..',')
			if (dname == nil) then 
				log('Removing obsolete child file '..fname,10)
				os.execute('rm -f '..fname)
			else
				log('Child file '..fname..' still in use.',10)
			end	
		end
	end
	os.execute('rm -f '..tmpfile)
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
	str = str .. '"Display": { "Service": "'..HData.SID..'", "Variable": "'..text..'", "Top": '..top..', "Left": '..left..', "Width": '..width..', "Height": '..height..' }}'
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
local function buildJsonStateIcon(icon,var,val,sid)		
	local str
	local path = ""
	local remicons = tonumber(varGet('RemoteImages'))
	if (remicons == 1) then 
		path = HData.RemoteIconURL
	else
		if (luup.version_major >= 7) then path = HData.UI7IconURL end
	end
	if (luup.version_major >= 7) then
		str ='{ "img": "'..path..icon..'.png", "conditions": [ { "service": "'..sid..'", "variable": "'..var..'", "operator": "==","value": '..val..' } ]}'
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
		-- V2.1 Fixed 100 px Control tab button width solved in 7.04
		if (luup.version_major == 7) and (luup.version_minor < 4) then 
			cWidth = 100 
		else	
			-- V2.1 7.05 layout improvements controlling line break
			if (newRow) then str = str .. '{ "ControlGroup": 1, "ControlType": "line_break" },\n'	end
			cWidth = 65 * butWidth
		end
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
	-- V2.1 7.05 layout improvements allowing for wider buttons
	str = str .. '{ "ControlGroup": "1", "ControlType": "button", "top": '..pTop..', "left": '..pLeft..','
	if (luup.version_major >= 7) then
		if (luup.version_major >= 7) and (luup.version_minor < 4) then
			-- Not supported prior 7.05
		elseif (butWidth ~= 1) then
			str = str .. '"HorizontalMultiplier": "'..butWidth..'",'
		end
	end
	str = str .. '\n"Label": { "text": "'..btnLab..'" },\n'
	if (isChild == false) then
		str = str .. '"Display": { "Service": "'..HData.SID..'", "Variable": "CurrentActivityID", "Value": "'..btnID..'", "Top": '..cTop..', "Left": '..cLeft..', "Width": '..cWidth..', "Height": 20 },\n'
		str = str .. '"Command": { "Service": "'..HData.SID..'", "Action": "StartActivity", "Parameters": [{ "Name": "newActivityID", "Value": "'..btnID..'" }] },\n'
	else
		str = str .. '"Display": { "Service": "'..HData.CHSID..'", "Variable": "LastDeviceCommand", "Value": "'..btnID..'", "Top": '..cTop..', "Left": '..cLeft..', "Width": '..cWidth..', "Height": 20 },\n'
		str = str .. '"Command": { "Service": "'..HData.CHSID..'", "Action": "SendDeviceCommand", "Parameters": [{ "Name": "Command", "Value": "'..btnID..'"},{  "Name": "Duration", "Value": "'..btnDur..'" }] },\n'
	end
	str = str .. '"ControlCode": "ham_button'..btnNum..'"\n}'
	return str
end

-- Build the JSON file 
local function writeJsonFile(devID,outf,newDevice,isChild,childDev)
	local maxBtn, id, lab, dur, sid
	local numBtn = 0
	local buttons = {}
	if (luup.version_major >= 7) then 
		maxBtn = HData.MaxButtonUI7 
		-- V2.1 Prior 7.05 5 less buttons
		if (not HData.onOpenLuup) and (luup.version_minor < 4) then maxBtn = maxBtn - 5 end
	else 
		maxBtn = HData.MaxButtonUI5 
	end
	if (isChild == false) then sid = HData.SID else sid = HData.CHSID end
	-- If not new device we can read the variables for the buttons. 
	for i = 1, maxBtn do
		if (isChild == false) then
			id = varGet("ActivityID"..i) or ''
			lab = varGet("ActivityDesc"..i) or ''
			dur = 0
		else
			-- On first create this will be nil
			if (childDev ~= nil) then
				id = varGet("Command"..i,childDev,sid) or ''
				lab = varGet("CommandDesc"..i,childDev,sid) or ''
				dur = varGet("PrsCommand"..i,childDev,sid) or 0
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
	log('Button definitions found : ' .. numBtn,10)
	local path = ""
	local remicons = varGet('RemoteImages')
	if (remicons == "1") then 
		path = HData.RemoteIconURL
	else
		if (luup.version_major >= 7) then 
			path = HData.UI7IconURL 
		else
			path = HData.UI5IconURL 
		end
	end
	-- For main device default icon is wait so it status is more clear during all reloads.
	if (luup.version_major >= 7) then
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
	if luup.version_major < 7 then outf:write('"DisplayStatus": { "Service": "'..sid..'", "Variable": "IconSet", "MinValue": "0", "MaxValue": "4" },\n') end
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
	if luup.version_major == 7 then outf:write('"TopNavigationTab": 1,\n') end
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
			log('Adding button ' .. i .. ', label ' .. (buttons[i].Label or 'missing'),10)
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
	if (luup.version_major < 7) then 
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
	if (luup.version_major >= 7) then outf:write(',\n' .. buildJsonLabel('ui7_device_scenes','Scenes',false,tab+3,'shared.js','device_scenes')) end
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
			log('Adding event ' .. i .. ', label ' .. (buttons[i].Label or 'missing'),10)
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
			outf:write(',\n{ "id": 2, "label": { "lang_tag": "a_device_is_turned_on_off", "text": "A device is turned on or off"}, "serviceId": "'..HData.SWSID..'",')
			outf:write('"norepeat": "1","argumentList": [{ "id": 1, "dataType": "boolean", "defaultValue": "0", "allowedValueList": [')
			outf:write('{ "Off": "0", "HumanFriendlyText": { "lang_tag": "hft_device_turned_off", "text": "Whenever the _DEVICE_NAME_ is turned off" }},') 
			outf:write('{ "On": "1", "HumanFriendlyText": { "lang_tag": "hft_device_turned_on", "text": "Whenever the _DEVICE_NAME_ is turned on" }}')
			outf:write('], "name": "Status", "comparisson": "=", "prefix": { "lang_tag": "ui7_which_mode", "text": "Which mode : " }, "suffix": {} } ] }')
		end
	end	
	outf:write('],\n')
	if (isChild == false) then
		if (luup.version_major < 7) then outf:write('"DeviceType": "urn:schemas-rboer-com:device:Harmony'..devID..':1",\n') end
		outf:write('"device_type": "urn:schemas-rboer-com:device:Harmony'..devID..':1"\n}\n')
	else	
		if (luup.version_major < 7) then outf:write('"DeviceType": "urn:schemas-rboer-com:device:HarmonyDevice'..HData.DEVICE..'_'..devID..':1",\n') end
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

-- Update the Static JSON file to update button texts etc
-- Input: devID = device ID
function Harmony_UpdateButtons(devID, upgrade)
	log('Updating buttons for Harmony device ' .. devID)
	local upgrd
	if (upgrade ~= nil) then upgrd = upgrade else upgrd = false end 
	-- See if we have a device specific definition yet
	local dname = string.match(luup.devices[devID].device_type, ":Harmony%d+:")
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
		local curname = luup.attr_get("device_file",devID)
		if (curname ~= (fname..".xml")) then luup.attr_set("device_file",fname..".xml",devID) end
		if (luup.version_major >= 7) then
			curname = luup.attr_get("device_json",devID)
			if (curname ~= (fname..".json")) then luup.attr_set("device_json", fname..".json",devID) end
		end
	end	
	-- Force reload for things to get picked up if requested on UI7
	if (upgrd ~= true) then luup_reload() end
	return true
end

-- Update the Static JSON file for child devices to update button texts
-- Input: devID = device ID
function Harmony_UpdateDeviceButtons(devID, upgrade)
	local upgrd
	if (upgrade ~= nil) then upgrd = upgrade else upgrd = false end 
	-- See if this gets called with the parent device ID, if so stop now to avoid issues
	if (devID == HData.DEVICE) then
		log('UpdateDeviceButtons called with parent ID #' .. devID .. '. Aborting..',2)
		return false
	end
	-- See if this gets called for a child this device owns when not upgrading
	local prnt_id
	if (upgrd ~= true) then
		prnt_id = luup.attr_get('id_parent', devID) or ""
		if (prnt_id ~= "") then prnt_id = tonumber(prnt_id) end
		if (prnt_id ~= HData.DEVICE) then
			log('UpdateDeviceButtons called for wrong parent ID #' .. prnt_id .. '. Expected #' .. HData.DEVICE .. '. Aborting..',2)
			return false
		end
	else
		-- When upgrading, use default parent
		prnt_id = HData.DEVICE
	end
	
	-- Get Harmony Device ID as that is what we use as key
	local deviceID = varGet("DeviceID",devID,HData.CHSID)
	if (deviceID == "") then
		log('UpdateDeviceButtons called for unconfigured device. Aborting..',2)
		return false
	end
	
	log('Updating buttons of device# ' .. devID .. ' for Harmony Device ' .. deviceID)
	local dname = string.match(luup.devices[devID].device_type, ":HarmonyDevice"..prnt_id.."_%d+:")
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
		local curname = luup.attr_get("device_file",devID)
		if (curname ~= (fname..".xml")) then luup.attr_set("device_file",fname..".xml",devID) end
		if (luup.version_major >= 7) then
			curname = luup.attr_get("device_json",devID)
			if (curname ~= (fname..".json")) then luup.attr_set("device_json", fname..".json",devID) end
		end
	end	
	-- Force reload for things to get picked up if requested on UI7
	if (upgrd ~= true) then luup_reload() end
	return true
end

		
-- Harmony_CreateChildren
local function Harmony_CreateChildren()
	log("Harmony_CreateChildren for device ",10)
	local childDeviceIDs = defVar("PluginHaveChildren")
	-- See if we have obsolete child xml or json files. If so remove them
	if (HData.Plugin_Disabled == false) then removeObsoleteChildDeviceFiles(childDeviceIDs) end
	if (childDeviceIDs == '') then 
		-- Note: we must continue this routine when there are no child devices as we may have ones that need to be deleted.
		log("No child devices to create.",10)
	else
		log("Child devices to create : " ..childDeviceIDs,10)
	end
	-- Get the list of devices from the harmony when not disabled.
	local retStat, Devices_t 
	if (HData.Plugin_Disabled == false) then 
		retStat, Devices_t = Harmony_GetConfig('list_devices', "", HData.JS)
		if (#Devices_t.devices == 0) then log("No devices returned from Harmony Hub.",10) end
	else
		Devices_t = {}
		Devices_t.devices = {}
		retStat = false
	end	
	-- V2.2 Failed to get devices from HUB, determine current ones from defined plugins
	if (retStat == false) then
		log("Failed to obtain the current devices from Hub. Hub may be off. Will analyse current Child devices")
		local altidprfx = 'HAM'..HData.DEVICE..'_'
		for k, v in pairs(luup.devices) do
			if (v.id ~=luup.attr_get ('altid',HData.DEVICE)) and (string.sub(v.id,1,altidprfx:len()) == altidprfx) then
				log("Found existing child device, lets save! id " .. tostring(v.id))
				local i = #Devices_t.devices + 1
				Devices_t.devices[i] = {}
				Devices_t.devices[i].ID = string.sub(v.id,altidprfx:len()+1)
				Devices_t.devices[i].Device = string.sub(v.description,6)
			end
		end
	end
	local childDevices = luup.chdev.start(HData.DEVICE)
	local embed = (varGet("PluginEmbedChildren") == "1")
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
			log("Error! device definitions not found on Harmony Hub for ID "..deviceID,10)
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
				log('CreateChildren: Device files for '..deviceID..' exist.',10)
			else
				-- Not yet there, make them
				log('CreateChildren: Making new device files.',10)
				make_D_file(deviceID,'HarmonyDevice',HData.DEVICE)
				make_JSON_file(deviceID,'D_HarmonyDevice',false,true,nil,HData.DEVICE)
			end
			local init = "urn:micasaverde-com:serviceId:HaDevice1,HideDeleteButton=1\n"..HData.CHSID..",DeviceID=".. deviceID.."\n"..HData.CHSID..",HubName="..luup.devices[HData.DEVICE].description
			local name = "HRM: " .. string.gsub(desc, "%s%(.+%)", "")
			log("Child device id " .. altid .. " (" .. name .. "), number " .. deviceID,10)
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
	log("Harmony device #" .. HData.DEVICE .. " is starting up!",10)
	--	Start polling for status and HTTP request handler when set-up is successful
	local srv = varGet("HTTPServer")
	log("HTTPServer " .. srv,10)	
	-- Start public handler on request
	if (srv == "1") then luup.register_handler ("HTTP_Harmony", "Harmony".. HData.DEVICE) end
	luup.register_handler ("HTTP_HarmonyInt", "hamGetActivities".. HData.DEVICE)
	luup.register_handler ("HTTP_HarmonyInt", "hamGetDevices".. HData.DEVICE)
	luup.register_handler ("HTTP_HarmonyInt", "hamGetDeviceCommands".. HData.DEVICE)
	-- Generate children, new or removed ones will cause a reload
	Harmony_CreateChildren()
	SetBusy(false, false)
	-- Look for current activity to start off with
	luup.call_delay("Harmony_PollCurrentActivity", 6, "", false)
	-- If debug level, keep tap on memory usage too.
--	local ll = varGet("LogLevel")
--	if (ll == "10") then
		checkMemory()
--	else
--		varSet("AppMemoryUsed", "Nop")
--	end
	setStatusIcon(HData.Icon.IDLE)
	return true
end

function Harmony_registerWithAltUI()
	-- Register with ALTUI once it is ready
	for k, v in pairs(luup.devices) do
		if (v.device_type == "urn:schemas-upnp-org:device:altui:1") then
			if luup.is_ready(k) then
				log("Found ALTUI device "..k.." registering devices.")
				local arguments = {}
--				arguments["newDeviceType"] = "urn:schemas-rboer-com:device:Harmony"..HData.DEVICE..":1"	
				arguments["newDeviceType"] = "urn:schemas-rboer-com:device:Harmony:1"	
				arguments["newScriptFile"] = "J_ALTUI_Harmony.js"	
				arguments["newDeviceDrawFunc"] = "ALTUI_HarmonyDisplays.drawHarmony"	
				arguments["newStyleFunc"] = ""	
				arguments["newDeviceIconFunc"] = ""	
				arguments["newControlPanelFunc"] = ""	
				-- Main device
				luup.call_action(HData.ALTUI_SID, "RegisterPlugin", arguments, k)
				-- Child devices
				arguments["newDeviceDrawFunc"] = "ALTUI_HarmonyDisplays.drawHarmonyDevice"	
--				local childDeviceIDs = varGet("PluginHaveChildren") .. ","
--				for deviceID in childDeviceIDs:gmatch("(%w+),") do
--					arguments["newDeviceType"] = "urn:schemas-rboer-com:device:HarmonyDevice"..HData.DEVICE.."_"..deviceID..":1"	
					arguments["newDeviceType"] = "urn:schemas-rboer-com:device:HarmonyDevice:1"	
					luup.call_action(HData.ALTUI_SID, "RegisterPlugin", arguments, k)
--				end	
			else
				log("ALTUI plugin is not yet ready, retry in a bit..")
				luup.call_delay("Harmony_registerWithAltUI", 10, "", false)
			end
			break
		end
	end
end

-- Initialize our device
function Harmony_init(lul_device)
	HData.DEVICE = lul_device
	SetBusy(true,false)
	setStatusIcon(HData.Icon.WAIT)
	log("Harmony device #" .. HData.DEVICE .. " is initializing!",3)
	-- See if we are running on openLuup.
	if (luup.version_major == 7) and (luup.version_minor == 0) then
		HData.onOpenLuup = true
		log("We are running on openLuup!!")
	end
	-- See if user disabled plug-in 
	local isDisabled = luup.attr_get("disabled", HData.DEVICE)
	if ((isDisabled == 1) or (isDisabled == "1")) then
		log("Init: Plug-in version "..HData.Version.." - DISABLED",2)
		HData.Plugin_Disabled = true
		-- Still create any child devices so we do not loose configurations.
		Harmony_CreateChildren()
		-- Still register with ALTUI for proper drawing
		Harmony_registerWithAltUI()
		varSet("LinkStatus", "Plug-in disabled")
		varSet("LastCommand", "--")
		varSet("LastCommandTime", "--")
		-- Now we are done. Mark device as disabled
		return true, "Plug-in Disabled.", HData.Description
	end

	-- Set Alt ID on first run, may avoid issues
	local altid = luup.attr_get('altid',HData.DEVICE) or ""
	if (altid == "") then luup.attr_set('altid', 'HAM'..HData.DEVICE..'_CNTRL',HData.DEVICE) end
	-- Make sure all (advanced) parameters are there
	local email = defVar("Email")
	local pwd = defVar("Password")
	-- V2.1 configurable time out
	local commTimeOut = tonumber(defVar("CommTimeOut",5))
	local syslogInfo = defVar ("Syslog")	-- send to syslog if IP address and Port 'XXX.XX.XX.XXX:YYY' (default port 514)
	HData.LogLevel = tonumber(defVar ("LogLevel", HData.LogLevel))
	defVar("HTTPServer", 0)
	defVar("PollInterval",0)
	defVar("OkInterval",3)
	defVar("AuthorizationToken")
	defVar("PluginHaveChildren")
	defVar("PluginEmbedChildren", "0")
	defVar("DefaultActivity")
	-- V2.03, do not reset the values on restart, only default when non existent
	defVar("LinkStatus", "--")
	defVar("LastCommand", "--")
	defVar("LastCommandTime", "--")
	defVar("CurrentActivityID")
	defVar("Target", "0", HData.DEVICE, HData.SWSID)
	defVar("Status", "0", HData.DEVICE, HData.SWSID)
	local forcenewjson = false
	-- set up logging to syslog	
	if (syslogInfo ~= '') then
		log('Starting UDP syslog service...',7) 
		local err
		local syslogTag = luup.devices[HData.DEVICE].description or HData.Description 
		HData.syslog, err = syslog_server (syslogInfo, syslogTag)
		if (not HData.syslog) then log('UDP syslog service error: '..err,2) end
	else 
		HData.syslog = nil
	end
	-- Make sure icons are accessible when they should be, even works after factory reset or when single image link gets removed or added.
	if (HData.onOpenLuup == false) then check_images(HData.Images) end
	-- See if we are upgrading, if so force rewrite of JSON files.
	local version = varGet("Version")
	if (version ~= HData.Version) then forcenewjson = true end
	-- When the RemoteIcons flag changed, we must force a rewrite of the JSON files as well.
	local remicons = varGet("RemoteImages")
	local remiconsprv = varGet("RemoteImagesPrv")
	if (remicons ~= remiconsprv) then
		varSet("RemoteImagesPrv",remicons)
		forcenewjson = true
	else
		-- Default setting. It was 1 (remote) on older versions, will be 0 (local) on new.
		if (remicons == '') then
			varSet("RemoteImages",0)
			varSet("RemoteImagesPrv",0)
		end	
	end
	if (forcenewjson == true) then
		-- Bump loglevel to monitor rewrite
		luup.log("Force rewrite of JSON files for correct Vera software version and configuration.")
		-- We may have some obsolete files, remove them.
		if (HData.onOpenLuup) then
--			os.execute('rm -f '..HData.f_path ..'I_HarmonyDevice.xml')
		else
			os.execute('rm -f '..HData.f_path ..'D_HarmonyDevice.xml')
			os.execute('rm -f '..HData.f_path ..'D_Harmony.xml')
--			os.execute('rm -f '..HData.f_path ..'I_HarmonyDevice.xml.lzo')  -- Don't on last UI7 version
		end
		-- Set the category to switch if needed
		local catid = luup.attr_get('category_num',HData.DEVICE) or ""
		if (catid ~= '3') then luup.attr_set('category_num', '3',HData.DEVICE) end
		-- Rewrite JSON files for main device
		Harmony_UpdateButtons(HData.DEVICE, true)
		-- Make default JSON for child devices D_HarmonyDevice.json
		make_JSON_file('','D_HarmonyDevice',false,true)
		luup.log("Rewritten files for main device # " .. HData.DEVICE)
		-- Then for any child devices, as they are not yet set, we must look at altid we use.
		removeObsoleteChildDeviceFiles()
		local childDeviceIDs = varGet("PluginHaveChildren")
		if (childDeviceIDs ~= "") then
			for devNo, deviceID in pairs(luup.devices) do
				local altid = string.match(deviceID.id, 'HAM'..HData.DEVICE..'_%d+')
				local chdevID = varGet("DeviceID", devNo, HData.CHSID)
				if (altid ~= nil) then 
					local tmp
					tmp, altid = string.match(altid, "(%d+)_(%d+)")
					if (chdevID == altid) then
						Harmony_UpdateDeviceButtons(devNo,true)
						local catid = luup.attr_get('category_num',devNo) or ""
						if (catid ~= '3') then luup.attr_set('category_num', '3',devNo) end
						luup.log("Rewritten files for child device # " .. devNo .. " name " .. chdevID)
						-- Hide the delete button for the child devices
						defVar("HideDeleteButton", 1, devNo, "urn:micasaverde-com:serviceId:HaDevice1")
					else
						luup.log("Child device # " .. devNo .. " does not have a matching DeviceID set.")
					end	
				else
					-- See if I have older version type device that is supported by this hub
					altid = string.match(deviceID.id, 'HAM_%d+')
					if (altid ~= nil) then 
						altid = string.match(altid, "%d+")
						chdevID = varGet("DeviceID", devNo, HData.SID) 
						local suppchID = string.match(childDeviceIDs, chdevID)
						if (chdevID == altid) and (chdevID == suppchID) then
							-- Transfer values from old to new
							luup.log("Transferring settings for child device # "..devNo..", name "..chdevID.." from Harmony to HarmonyDevice")
							varSet("DeviceID", chdevID, devNo, HData.CHSID)
							for idx = 1, 24 do
								local cmdV = varGet("Command"..idx, devNo, HData.SID)
								local cmdD = varGet("CommandDesc"..idx, devNo, HData.SID)
								if (cmdV ~= "") then 
									varSet("Command"..idx, cmdV, devNo, HData.CHSID)
									varSet("Command"..idx, "", devNo, HData.SID)
								end
								if (cmdD ~= "") then 
									varSet("CommandDesc"..idx, cmdD, devNo, HData.CHSID) 
									if (idx == 1) then
										varSet("CommandDesc"..idx, "REFRESH", devNo, HData.SID) 
									elseif (idx == 2) then	
										varSet("CommandDesc"..idx, "BROWSER", devNo, HData.SID) 
									else
										varSet("CommandDesc"..idx, "", devNo, HData.SID) 
									end
								end
							end
							-- We should only do this once
							varSet("DeviceID", "", devNo, HData.SID)
							-- Now rewrite buttons, and correct alt ID and device type
							Harmony_UpdateDeviceButtons(devNo,true)
							local chd_type = luup.attr_get('device_type',devNo)
							luup.attr_set('device_type',chd_type:gsub('_'..chdevID,HData.DEVICE..'_'..chdevID),devNo)
							luup.attr_set('altid','HAM'..HData.DEVICE..'_'..chdevID,devNo)
							local catid = luup.attr_get('category_num',devNo) or ""
							if (catid ~= '3') then luup.attr_set('category_num', '3',devNo) end
							luup.log("Rewritten files for child device # " .. devNo .. " name " .. chdevID)
						end
					end
				end
			end
		else
			log("No child devices.",3)
		end
		varSet("Version", HData.Version)
		-- Sleep for 5 secs, just in case we have multiple plug in copies that try to migrate. They must all have time to finish.
		luup.sleep(5000)
		-- We must reload for new files to be picked up
		luup_reload()
	else
		varSet("Version", HData.Version)
		log("Version is current : " .. version,3)
	end
	-- Call to register with ALTUI
--	luup.call_delay("Harmony_registerWithAltUI", 10, "", false)
	Harmony_registerWithAltUI()
	
	-- Check that we have to parameters to get started
	local success = true
	local ipa = luup.devices[HData.DEVICE].ip
	local ipAddress = string.match(ipa, '^(%d%d?%d?%.%d%d?%d?%.%d%d?%d?%.%d%d?%d?)')
	-- Some cases IP gets stuck in variable and no in attribute (openLuup or ALTUI bug)
	if (ipAddress == nil) or (email == '') or (pwd == '') then
		setStatusIcon(HData.Icon.ERROR)
		SetBusy(false,false)
		setluupfailure(1, HData.DEVICE)
		return false, "Configure IP Address, email and password.", HData.Description
	end
	log("Using Harmony Hub: IP address " .. ipAddress, 3)
	Harmony = HarmonyAPI(ipAddress, email, pwd, commTimeOut)
	if (Harmony == nil) then 
		success = false 
	else
		-- Get Authorization Token
		success = Harmony.GetAuthorizationToken()
		if (success) then
			-- Get Session Token
			success = Harmony.GetSessionToken()
			if (success == false) then Harmony = nil end
		else
			Harmony = nil
		end
	end
	if (Harmony == nil) then 
		setStatusIcon(HData.Icon.ERROR)
		SetBusy(false,false)
		setluupfailure(2, HData.DEVICE)
		return false, "Hub connection set-up failed. Check IP Address, email and password.", HData.Description
	end	
	--	Schedule to finish rest of start up in a few seconds
	luup.call_delay("Harmony_Setup", 3, "", false)
	log("Harmony Hub Control: init_module completed ",10)
	setluupfailure(0, HData.DEVICE)
	return true
end

-- See if we have incoming data, should not happen
function Harmony_Incoming(lul_data)
	if (lul_data) then
		log("Incoming received : " .. tostring(lul_data),10)
	end
	return true
end

