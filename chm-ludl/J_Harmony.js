//# sourceURL=J_Harmony.js
/* harmony Hub Control UI
 Written by R.Boer. 
 V4.00 12 April 2019

 V4.00 Changes:
		Added Activity child devices.
 V3.11 Changes:
		Fix for Save changes in _UpdateDeviceSettings.
 V3.9 Changes:
		Clear Domain variable on IP address change.
 V3.7 Changes:
		Clear RemoteID variable on IP address change.
 V3.5 Changes:
 		Removed the HTTP Server as option.
		Removed remote images option for openLuup as ALTUI handles images properly.
		Changed Settings panel to no longer need a Save button and minimize reloads.
		Default js is now for UI7 and openLuup.
 V3.3 Changes:
		Added support for automation devices. For now Lamps only.
 V3.0 Changes:
		Changed to WebSockets API, no longer need for uid,pwd and polling settings.
		Activities, Devices and Commands are now in variable, no need for HTTP handler.
 V2.22 Changes:
		Fix for ALTUI on saving settings.
 V2.21 Changes:
		Suspend Poll when away has added option to only stop when CurrentActivityID is -1 (all off).
 V2.20 Changes:
		Support for Home poll only option.
		Removed syslog support
		Nicer look on ALTUI
 V2.19 Changes:
		IP Address is now stored in normal variable, no longer in device IP attribute.
 V2.16 Changes:
		Changed call to request data from Vera Handlers.
 V2.15 Changes:
		New settings option to wait on Hub to fully complete the start of an activity or not.
 V2.13-1 Changes:
		The password input now has the HTML input type password so it won't show.
 		Some hints on poll frequency settings.
 V2.7 Changes:
		User can disable plugin. Signal status on control panel.
		No more reference to myInterface, using correct api.ui calls instead.
 V2.5 Changes:
		Can define key-press duration for devices.
		Some JQuery use. Layout improvements for native UI and ALTUI.
 		Changed poll and acknowledge settings to drop down selections.
		Proper JSON returns from LUA.
 V2.4 Changes:
		Some optimizations in Vera api calls that now work on UI7
 V2.1 Changes:
		Added selection for time out.
 V2.02 Changes:
		Removed options for MaxActivity and Device Buttons. Now just fixed.
		Removed Enable Button Feedback option. Now uses Ok Acknowledge Interval value.
		Fixed getInfo and LUA command issue with IE.
		Default activity and command descriptions when user does not enter them.
		Added Default Activity selection for SetTarget action.
		When not specifying a Description, the activity or command will be defaulted.
 V2.01 Changes:
		getInfo query adds device ID for multiple hub support.
 V2.0 Changes:
		Save of variables via luup action as standard save function does not work reliably remote
 V1.9 changes:
 		Corrected serviceId for UpdateDeviceButtons action.
		Added syslog support
*/

var Harmony = (function (api) {

	// Constants. Keep in sync with LUA code.
    var _uuid = '12021512-0000-a0a0-b0b0-c0c030303031';
	var HAM_SID = 'urn:rboer-com:serviceId:Harmony1';
	var HAM_CHSID = 'urn:rboer-com:serviceId:HarmonyDevice1';
	var VB_SID = 'urn:akbooer-com:serviceId:VeraBridge1';
	var HAM_MAXBUTTONS = 25;
	var HAM_ERR_MSG = "Error : ";
	var bOnALTUI = false;
	var bControllerIsVera;

	// Forward declaration.
    var myModule = {};
	
	// Check the controller we are talking to. Return true if it is Vera.
	function getTargetControllerType(deviceObj) {
		if (typeof(bControllerIsVera) === 'undefined') {
			var bCtv = true;
			if (bOnALTUI) {
				var udObj = api.getUserData();	
				// We are running on openLuup locally, see if the top level device is zero; I.e. local.
				if (udObj.BuildVersion === '*1.7.0*' && deviceObj.id_parent != 0) {
					// Not local, ask VeraBridge handing the device what it is talking to. Only latest version has RemotePort that can be for other OpenLuup.
					var vp = varGet(deviceObj.id_parent,'RemotePort',VB_SID);
					bCtv = Boolean(vp !== ':3480');
				}
			}
			bControllerIsVera = bCtv;
		} 
		return bControllerIsVera;
	}

    function _onBeforeCpanelClose(args) {
		showBusy(false);
        //console.log('Harmony, handler for before cpanel close');
    }

    function _init() {
        // register to events...
        api.registerEventHandler('on_ui_cpanel_before_close', myModule, 'onBeforeCpanelClose');
		// See if we are on ALTUI
		if (typeof ALTUI_revision=="string") {
			bOnALTUI = true;
		}
    }
	
	// Return HTML for settings tab
	function _Settings() {
		_init();
        try {
			var deviceID = api.getCpanelDeviceId();
			var deviceObj = api.getDeviceObject(deviceID);
			var timeAck = [{'value':'0','label':'None'},{'value':'1','label':'1 Sec'},{'value':'2','label':'2 Sec'},{'value':'3','label':'3 Sec'}];
			var yesNo = [{'value':'0','label':'No'},{'value':'1','label':'Yes'}];
			var logLevel = [{'value':'1','label':'Error'},{'value':'2','label':'Warning'},{'value':'8','label':'Info'},{'value':'11','label':'Debug'}];
			var actSel = [{ 'value':'','label':'None'}];
			for (var i=1; i<=HAM_MAXBUTTONS; i++) {
				var actID = varGet(deviceID,'ActivityID'+i);
				var actDesc = varGet(deviceID,'ActivityDesc'+i);
				if (actID !== '' && actDesc !== '') {
					actSel.push({'value':actID,'label':actDesc});
				}
			}
			var html = '<div class="deviceCpanelSettingsPage">'+
				'<h3>Device #'+deviceID+'&nbsp;&nbsp;&nbsp;'+api.getDisplayedDeviceName(deviceID)+'</h3>';
			if (deviceObj.disabled === '1' || deviceObj.disabled === 1) {
				html += '<br>Plugin is disabled in Attributes.';
			} else {
				html +=	htmlAddInput(deviceID, 'Harmony Hub IP Address', 20, 'HubIPAddress','UpdateSettingsCB') + 
				htmlAddPulldown(deviceID, 'Ok Acknowledge Interval', 'OkInterval', timeAck,'UpdateSettingsCB')+
				htmlAddPulldown(deviceID, 'Default Activity', 'DefaultActivity', actSel,'UpdateSettingsCB');
				if (getTargetControllerType(deviceObj)) {
					html +=	htmlAddPulldown(deviceID, 'Enable Remote Icon Images', 'RemoteImages', yesNo,'UpdateSettingsCB');
				}
				html +=	htmlAddPulldown(deviceID, 'Log level', 'LogLevel', logLevel,'UpdateSettingsCB');
			}
			html += '</div>';
			api.setCpanelContent(html);
        } catch (e) {
            Utils.logError('Error in Harmony.Settings(): ' + e);
        }
	}
	
	// Call back on settings change
	function _UpdateSettingsCB(deviceID,varID) {
		showBusy(true);
		var notifyMsg = "";
		var triggerReload = false;
		var val = htmlGetElemVal(deviceID, varID);
		switch (varID) {
		case 'HubIPAddress':
			// We cannot put this in a call_action as the initialization will fail when IP address is incorrect.
			// When we don't fail initialization we cannot flag device on openLuup.
			varSet(deviceID,'HubIPAddress',val);
			varSet(deviceID,'RemoteID','');	// Clear remote ID and other Hub details as with new IP we need to ask for it again.
			varSet(deviceID,'Domain','');	
			varSet(deviceID,'AccountID','');	
			varSet(deviceID,'email','');	
			// varSet(deviceID,'FriendlyName','');	// No longer available in hub V4.15.250
			notifyMsg = "Setting updated and Vera reload in progress. Refresh your browser when done.";
			triggerReload = true;
			break;
		case 'OkInterval':
			varSet(deviceID,'OkInterval',val);
			break;
		case 'DefaultActivity':
			varSet(deviceID,'DefaultActivity',val);
			break;
		case 'RemoteImages':
			api.performLuActionOnDevice(deviceID, HAM_SID, 'SetRemoteImages',  { actionArguments: { newImageRemote: val }});
			notifyMsg = "Setting updated and Vera reload in progress. Refresh your browser when done.";
			break;
		case 'LogLevel':
			api.performLuActionOnDevice(deviceID, HAM_SID, 'SetLogLevel',  { actionArguments: { newLogLevel: val }});
			break;
		}
		application.sendCommandSaveUserData(true);
		if (notifyMsg !== "") {
			setTimeout(function() {
				if (triggerReload) {
					doReload(deviceID);
				}	
				showBusy(false);
				try {
					api.ui.showMessagePopup(notifyMsg,0);
				}
				catch (e) {
					myInterface.showMessagePopup(notifyMsg,0); // ALTUI
				}
			}, 3000);	
		} else {
			showBusy(false);
		}
	}


	// Request HTML for activities tab
	function _Activities() {
		_init();
        try {
			var deviceID = api.getCpanelDeviceId();
			var deviceObj = api.getDeviceObject(deviceID);
			var html = '<div class="deviceCpanelSettingsPage">'+
				'<h3>Device #'+deviceID+'&nbsp;&nbsp;&nbsp;'+api.getDisplayedDeviceName(deviceID)+'</h3>'+
				'<div id="hamID_content_AC_'+deviceID+'">';
			if (deviceObj.disabled === '1' || deviceObj.disabled === 1) {
				html += '<table width="100%" border="0" cellspacing="3" cellpadding="0">'+
					'<tr><td>&nbsp;</td></tr>'+
					'<tr><td>Plugin is disabled in Attributes.</td></tr></table>';
			} else {	
				// Parse Activity IDs to make button selections
				var actjs = varGet(deviceID,'Activities');
				if (actjs != '') {
					var acts = JSON.parse(actjs).activities;
					var actSel = [{ 'value':'','label':'None'}];
					for (var i=0; i<acts.length; i++) {
						actSel.push({'value':acts[i].ID,'label':acts[i].Activity});
					}
					html += '<b>Activity mappings</b>'+
						htmlAddButton(deviceID,'UpdateButtons')+
						'<div id="ham_msg">Select activities you want to be able to control and click Save Changes.<br>'+
						'The labels should fit a button, normally 7 or 8 characters max.';
					if (getTargetControllerType(deviceObj)) {
						html += '<br>A reload command may be performed automatically.';
					}	
					html += '</div><p>';
					for (i=1; i<=HAM_MAXBUTTONS; i++) {
						html += htmlAddMapping(deviceID, 'Button '+i+'&nbsp;&nbsp;Activity ID', 'ActivityID'+i, actSel, 'Label', 'ActivityDesc'+i);
					}
				} else {
					html += '<table width="100%" border="0" cellspacing="3" cellpadding="0">'+
						'<tr><td>&nbsp;</td></tr>'+
						'<tr><td>Activities not loaded. Click the Update Configuration button.</td></tr></table>';
				}	
				html += '</div></div>';
			}
			api.setCpanelContent(html);			
        } catch (e) {
            Utils.logError('Error in Harmony.Activities(): ' + e);
        }
	}

	// Return HTML for devices tab
	function _Devices() {
		_init();
        try {
			var deviceID = api.getCpanelDeviceId();
			var deviceObj = api.getDeviceObject(deviceID);
			var html = '<div class="deviceCpanelSettingsPage">'+
				'<h3>Device #'+deviceID+'&nbsp;&nbsp;&nbsp;'+api.getDisplayedDeviceName(deviceID)+'</h3>'+
				'<div id="hamID_content_DH_'+deviceID+'">';
			if (deviceObj.disabled === '1' || deviceObj.disabled === 1) {
				html += '<table width="100%" border="0" cellspacing="3" cellpadding="0">'+
					'<tr><td>&nbsp;</td></tr>'+
					'<tr><td>Plugin is disabled in Attributes.</td></tr></table>';
			} else {	
				var yesNo = [{'value':'0','label':'No'},{'value':'1','label':'Yes'}];
				var devList = [];
				var lampList = [];
				var devJs = varGet(deviceID,'Devices');
				var lampJs = varGet(deviceID,'Lamps');
				var devHtml = 'Devices not loaded. Check Hub configuration and click the Update Configuration button.';
				var lampHtml = '';
				if (devJs != '') {
					var devs = JSON.parse(devJs).devices;
					for (var i=0; i<devs.length; i++) {
						devList.push({ 'value':devs[i].ID,'label':devs[i].Device });
					}
					devHtml = htmlAddPulldownMultiple(deviceID, 'Devices to Control', 'PluginHaveChildren', devList)+'<p>';
				}
				if (lampJs != '') {
					var devs = JSON.parse(lampJs).lamps;
					for (var i=0; i<devs.length; i++) {
						lampList.push({ 'value':devs[i].udn,'label':devs[i].name });
					}
					lampHtml = '<p>'+htmlAddPulldownMultiple(deviceID, 'Lamps to Control', 'PluginHaveLamps', lampList)+'<p>';
				}
				html += '<b>Device selection</b>'+
					'<p>'+
					'<div id="ham_msg">Select device(s) and/or Lamp(s) you want to be able to control and click Save Changes.<br>'+
					'For each selected a child device will be created.<br>'+
					'A reload command may be performed automatically.</div>'+
					'<p>'+
					devHtml+lampHtml+
					'<p>'+
					htmlAddPulldown(deviceID, 'Create child devices embedded', 'PluginEmbedChildren', yesNo)+
					htmlAddButton(deviceID,'UpdateDeviceSelections')+
					'</div></div>';
			}
			api.setCpanelContent(html);			
        } catch (e) {
            Utils.logError('Error in Harmony.Devices(): ' + e);
        }
	}

	// Return HTML for device settings tab
	function _DeviceSettings() {
		_init();
        try {
			var deviceID = api.getCpanelDeviceId();
			var deviceObj = api.getDeviceObject(deviceID);
			var prntObj = api.getDeviceObject(deviceObj.id_parent);
			var html = '<div class="deviceCpanelSettingsPage">'+
				'<h3>Device #'+deviceID+'&nbsp;&nbsp;&nbsp;'+api.getDisplayedDeviceName(deviceID)+'</h3>'+
				'<div id="hamID_content_DS_'+deviceID+'">';
			if (prntObj.disabled === '1' || prntObj.disabled === 1) {
				html += '<table width="100%" border="0" cellspacing="3" cellpadding="0">'+
					'<tr><td>&nbsp;</td></tr>'+
					'<tr><td>Plugin is disabled in Attributes.</td></tr></table>';
			} else {	
				var cmdjs = varGet(deviceID,'DeviceCommands',HAM_CHSID);
				if (cmdjs != '') {
					var funcs = JSON.parse(cmdjs).Functions;
					var actSel = [{ 'value':'','label':'None'}];
					for (var i=0; i<funcs.length; i++) {
						for (var j=0; j<funcs[i].Commands.length; j++) {
							actSel.push({ 'value':funcs[i].Commands[j].Action,'label':funcs[i].Commands[j].Label});
						}	
					}
					html += '<b>Device Command mappings</b>'+
						htmlAddButton(deviceID,'UpdateDeviceButtons')+
						'<div id="ham_msg">Select commands you want to be able to control and click Save Changes.<br>'+
						'The labels should fit a button, normally 7 or 8 characters max.<br>'+
						'A reload command may be performed automatically.</div>'+
						'<p>';
					for (i=1; i<=HAM_MAXBUTTONS; i++) {
						html += htmlAddMapping(deviceID, 'Button '+i+' Command', 'Command'+i, actSel, 'Label', 'CommandDesc'+i, HAM_CHSID);
					}
				} else {
					html += '<table width="100%" border="0" cellspacing="3" cellpadding="0">'+
						'<tr><td>&nbsp;</td></tr>'+
						'<tr><td>Commands not loaded. Click the Update Configuration button in the main device.</td></tr></table>';
				}	
				html += '</div></div>';
			}
			api.setCpanelContent(html);			
        } catch (e) {
            Utils.logError('Error in Harmony.DeviceSettings(): ' + e);
        }
	}

	// Update variable in user_data and lu_status
	function varSet(deviceID, varID, varVal, sid) {
		if (typeof(sid) == 'undefined') { sid = HAM_SID; }
		api.setDeviceStateVariablePersistent(deviceID, sid, varID, varVal);
	}
	// Get variable value. When variable is not defined, this new api returns false not null.
	function varGet(deviceID, varID, sid) {
		try {
			if (typeof(sid) == 'undefined') { sid = HAM_SID; }
			var res = api.getDeviceState(deviceID, sid, varID);
			if (res !== false && res !== null && res !== 'null' && typeof(res) !== 'undefined') {
				return res;
			} else {
				return '';
			}	
        } catch (e) {
            return '';
        }
	}

	// Update the buttons for the main device.
	function _UpdateButtons(deviceID) {
		// Save variable values so we can access them in LUA without user needing to save
		var bChanged = false;
		showBusy(true);
		var curChilds = varGet(deviceID, 'PluginHaveActivityChildren');
		var ncArr = [];
		for (var icnt=1; icnt <= HAM_MAXBUTTONS; icnt++) {
			var idval = htmlGetElemVal(deviceID, 'ActivityID'+icnt);
			var labval = htmlGetElemVal(deviceID, 'ActivityDesc'+icnt);
			var chldval = htmlGetElemVal(deviceID, 'ActivityID'+icnt+'Child');
			var orgid = varGet(deviceID,'ActivityID'+icnt);
			var orglab = varGet(deviceID,'ActivityDesc'+icnt);
			// Check for empty Activity descriptions, and default to activity
			if (idval !== '' && labval === '') {
				var s = document.getElementById('hamID_ActivityID'+icnt+deviceID);
				labval = s.options[s.selectedIndex].text;
				labval = labval.substr(0,8);
			}
			if (idval != orgid) {
				varSet(deviceID,'ActivityID'+icnt, idval);
				bChanged=true;
			}	
			if (labval != orglab && idval != '') {
				varSet(deviceID,'ActivityDesc'+icnt, labval);
				bChanged=true;
			}	
			if (chldval == 1 && idval != '') {
				ncArr.push(idval);
			}	
		}
		var newChilds = ncArr.join();
		if (newChilds != curChilds) { 
			varSet(deviceID,'PluginHaveActivityChildren', newChilds);
			bChanged = true; 
		}

		// If we have changes, update buttons.
		if (bChanged) {
//			application.sendCommandSaveUserData(true);
			// On Vera Wait a second to send the actual action, as it may have issues not saving all data on time.
			var deviceObj = api.getDeviceObject(deviceID);
			if (getTargetControllerType(deviceObj)) {
				setTimeout(function() {
					api.performLuActionOnDevice(deviceID, HAM_SID, 'UpdateButtons', {});
					// Vera requires static JSON rewrite and reload.
					setTimeout(function() {
						showBusy(false);
						htmlSetMessage("Changes to the buttons made.<br>Now wait for reload to complete and then refresh your browser page!",false);
					}, 5000);
				}, 1000);
			} else {
				api.performLuActionOnDevice(deviceID, HAM_SID, 'UpdateButtons', {});
				showBusy(false);
				htmlSetMessage("Changes to the buttons made.<br>Refresh your browser page!",false);
			}	
		} else {
			showBusy(false);
			htmlSetMessage("You have not changed any values.<br>No changes to the buttons made.",true);
		}	
	}
	
	// Update the buttons for the child devices.
	function _UpdateDeviceButtons(deviceID) {
		// Save variable values so we can access them in LUA without user needing to save
		var bChanged = false;
		showBusy(true);
		for (var icnt=1; icnt <= HAM_MAXBUTTONS; icnt++) {
			var idval = htmlGetElemVal(deviceID, 'Command'+icnt);
			var labval = htmlGetElemVal(deviceID, 'CommandDesc'+icnt);
			var prsval = htmlGetElemVal(deviceID, 'PrsCommand'+icnt);
			var orgid = varGet(deviceID,'Command'+icnt, HAM_CHSID);
			var orglab = varGet(deviceID,'CommandDesc'+icnt, HAM_CHSID);
			var orgprs = varGet(deviceID,'PrsCommand'+icnt, HAM_CHSID);
			// Check for empty command descriptions, and default to command
			if (idval !== '' && labval === '') {
				var s = document.getElementById('hamID_Command'+icnt+deviceID);
				labval = s.options[s.selectedIndex].text;
				labval = labval.substr(0,8);
			}
			if (idval != orgid) {
				varSet(deviceID,'Command'+icnt, idval, HAM_CHSID);
				bChanged=true;
			}
			if (labval != orglab && idval != '') {
				varSet(deviceID,'CommandDesc'+icnt, labval, HAM_CHSID);
				bChanged=true;
			}	
			if (prsval != orgprs && idval != '') {
				varSet(deviceID,'PrsCommand'+icnt, prsval, HAM_CHSID);
				bChanged=true;
			}	
		}
		// If we have changes, update buttons.
		if (bChanged) {
//			application.sendCommandSaveUserData(true);
			// Wait a second to send the actual action, as it may have issues not saving all data on time.
			var deviceObj = api.getDeviceObject(deviceID);
			if (getTargetControllerType(deviceObj)) {
				setTimeout(function() {
					api.performLuActionOnDevice(deviceID, HAM_CHSID, 'UpdateDeviceButtons', {});
					// Vera requires static JSON rewrite and reload.
					setTimeout(function() {
						showBusy(false);
						htmlSetMessage("Changes to the buttons made.<br>Now wait for reload to complete and then refresh your browser page!",false);
					}, 5000);	
				}, 1000);
			} else {
				api.performLuActionOnDevice(deviceID, HAM_CHSID, 'UpdateDeviceButtons', {});
				showBusy(false);
				htmlSetMessage("Changes to the buttons made.<br>Refresh your browser page!",false);
			}	
		} else {
			showBusy(false);
			htmlSetMessage("You have not made any changes.<br>No changes to the buttons made.",true);
		}	
	}
	
	function _UpdateDeviceSelections(deviceID) {
		// Get the selection from the pull down
		var bChanged = false;
		showBusy(true);
		var selIDs = htmlGetPulldownSelection(deviceID,'PluginHaveChildren');
		var orgIDs = varGet(deviceID,'PluginHaveChildren');
		if (selIDs != orgIDs) {
			varSet(deviceID,'PluginHaveChildren', selIDs);
			bChanged=true;
		}	
		selIDs = htmlGetPulldownSelection(deviceID,'PluginHaveLamps');
		orgIDs = varGet(deviceID,'PluginHaveLamps');
		if (selIDs != orgIDs) {
			varSet(deviceID,'PluginHaveLamps', selIDs);
			bChanged=true;
		}	
		selIDs = htmlGetElemVal(deviceID, 'PluginEmbedChildren');
		orgIDs = varGet(deviceID, 'PluginEmbedChildren');
		if (selIDs != orgIDs) {
			varSet(deviceID,'PluginEmbedChildren', selIDs);
			bChanged=true;
		}	
		// If we have changes in child devices, reload device.
		if (bChanged) {
			application.sendCommandSaveUserData(true);
			setTimeout(function() {
				doReload(deviceID);
				htmlSetMessage("Changes to configuration made.<br>Now wait for reload to complete and then refresh your browser page!<p>New device(s) will be in the No Room section.",false);
				showBusy(false);
			}, 3000);	
		} else {
			showBusy(false);
			htmlSetMessage("You have not made any changes.<br>No changes made.",true);
		}
	}
	
	// Standard update for  plug-in pull down variable. We can handle multiple selections.
	function htmlGetPulldownSelection(di, vr) {
		var value = $('#hamID_'+vr+di).val() || [];
		return (typeof value === 'object')?value.join():value;
	}

	// Get the value of an HTML input field
	function htmlGetElemVal(di,elID) {
		var res;
		try {
			res=$('#hamID_'+elID+di).val();
		}
		catch (e) {	
			res = '';
		}
		return res;
	}

	function htmlSetMessage(msg,error) {
		try {
			if (error === true) {
				api.ui.showMessagePopupError(msg);
			} else {
				api.ui.showMessagePopup(msg,0);
			}	
		}	
		catch (e) {	
			$("#ham_msg").html(msg+'<br>&nbsp;');
		}	
	}

	// Add label, pulldown, label, input
	function htmlAddMapping(di, lb1, vr1, values, lb2, vr2, sid) {
		try {
			var selVal = varGet(di, vr1, sid);
//			var wdth = (bOnALTUI) ? 'style="width:140px;"' : '';  // Use on ALTUI
			var html = '<div class="clearfix labelInputContainer">'+
				'<div class="pull-left inputLabel '+((bOnALTUI) ? 'form-control form-control-sm form-control-plaintext' : '')+'" style="width:140px;">'+lb1+'</div>'+
				'<div class="pull-left customSelectBoxContainer" style="width:140px;">'+
				'<select id="hamID_'+vr1+di+'" class="customSelectBox '+((bOnALTUI) ? 'form-control form-control-sm' : '')+'" style="width:140px;">';
			for(var i=0;i<values.length;i++){
				html += '<option value="'+values[i].value+'" '+((''+values[i].value==selVal)?'selected':'')+'>'+values[i].label+'</option>';
			}
			html += '</select>'+
				'</div>';
			html += '<div class="pull-left inputLabel '+((bOnALTUI) ? 'form-control form-control-sm form-control-plaintext' : '')+'" style="margin-left:30px; width:40px;">'+lb2+'</div>'+
				'<div class="pull-left">'+
					'<input class="customInput '+((bOnALTUI) ? 'altui-ui-input form-control form-control-sm' : '')+'" style="width:140px;" id="hamID_'+vr2+di+'" size="15" type="text" value="'+varGet(di,vr2,sid)+'">'+
				'</div>';
			if (typeof sid != 'undefined') {
				// Device Settings
				var timeDuration = [{'value':'0','label':'Click'},{'value':'1','label':'1 Sec'},{'value':'2','label':'2 Sec'},{'value':'3','label':'3 Sec'},{'value':'4','label':'4 Sec'},{'value':'5','label':'5 Sec'}];
				var selDur = varGet(di, 'Prs'+vr1, sid);
				if (selDur == '') { selDur = 0; }
				html += '<div class="pull-left inputLabel '+((bOnALTUI) ? 'form-control form-control-sm form-control-plaintext' : '')+'" style="margin-left:30px; width:60px;">Press</div>'+
				'<div class="pull-left customSelectBoxContainer" style="width:70px;">'+
				'<select id="hamID_Prs'+vr1+di+'" class="customSelectBox '+((bOnALTUI) ? 'form-control form-control-sm' : '')+'" style="width:70px;">';
				for(i=0;i<timeDuration.length;i++){
					html += '<option value="'+timeDuration[i].value+'" '+((''+timeDuration[i].value==selDur)?'selected':'')+'>'+timeDuration[i].label+'</option>';
				}
				html += '</select>'+
					'</div>';
			} else {
				// Activity settings, see if activity ID already in PluginHaveActivityChildren to flag selected
				var noYes = [{'value':'0','label':'No'},{'value':'1','label':'Yes'}];
				var curChild = varGet(di, 'PluginHaveActivityChildren');
				var curVal = 0;
				if (selVal != '') {
					var ccArr = curChild.split(',');
					curVal = (ccArr.includes(selVal)?1:0);
				}	
				html += '<div class="pull-left inputLabel '+((bOnALTUI) ? 'form-control form-control-sm form-control-plaintext' : '')+'" style="margin-left:30px; width:140px;">Activity Child Device</div>'+
				'<div class="pull-left customSelectBoxContainer" style="width:70px;">'+
				'<select id="hamID_'+vr1+'Child'+di+'" class="customSelectBox '+((bOnALTUI) ? 'form-control form-control-sm' : '')+'" style="width:70px;">';
				for(i=0;i<noYes.length;i++){
					html += '<option value="'+noYes[i].value+'" '+((''+noYes[i].value==curVal)?'selected':'')+'>'+noYes[i].label+'</option>';
				}
				html += '</select>'+
					'</div>';
			}
			html += '</div>';
			return html;
		} catch (e) {
			Utils.logError('Harmony: htmlAddMapping(): ' + e);
		}
	}

	// Add a label and pulldown selection
	function htmlAddPulldown(di, lb, vr, values, cb) {
		try {
			var selVal = varGet(di, vr);
			var onch = (typeof cb != 'undefined') ? ' onchange=Harmony.'+cb+'(\''+di+'\',\''+vr+'\'); ' : ' ';
			var html = '<div class="clearfix labelInputContainer">'+
				'<div class="pull-left inputLabel '+((bOnALTUI) ? 'form-control form-control-sm form-control-plaintext' : '')+'" style="width:280px;">'+lb+'</div>'+
				'<div class="pull-left customSelectBoxContainer">'+
				'<select '+onch+'id="hamID_'+vr+di+'" class="customSelectBox '+((bOnALTUI) ? 'form-control form-control-sm' : '')+'" style="width:200px;">';
			for(var i=0;i<values.length;i++){
				html += '<option value="'+values[i].value+'" '+((values[i].value==selVal)?'selected':'')+'>'+values[i].label+'</option>';
			}
			html += '</select>'+
				'</div>'+
				'</div>';
			return html;
		} catch (e) {
			Utils.logError('Harmony: htmlAddPulldown(): ' + e);
		}
	}
	// Add a label and multiple selection
	function htmlAddPulldownMultiple(di, lb, vr, values, cb) {
		try {
			var selVal = varGet(di, vr);
			var onch = (typeof cb != 'undefined') ? ' onchange=Harmony.'+cb+'(\''+di+'\',\''+vr+'\'); ' : ' ';
			var selected = [];
			if (selVal !== '') {
				selected = selVal.split(',');
			}
			var html = '<div class="clearfix labelInputContainer">'+
				'<div class="pull-left inputLabel" style="width:280px;">'+lb+'</div>'+
				'<div class="pull-left">'+
				'<select id="hamID_'+vr+di+'" multiple>';
			for(var i=0;i<values.length;i++){
				html+='<option value="'+values[i].value+'" ';
				for (var j=0;j<selected.length;j++) {
					html += ((values[i].value==selected[j])?'selected':'');
				}	
				html +=	'>'+values[i].label+'</option>';
			}
			html += '</select>'+
				'</div>'+
				'</div>';
			return html;
		} catch (e) {
			Utils.logError('Harmony: htmlAddPulldownMultiple(): ' + e);
		}
	}

	// Add a standard input for a plug-in variable.
	function htmlAddInput(di, lb, si, vr, cb, sid, df) {
		var val = (typeof df != 'undefined') ? df : varGet(di,vr,sid);
		var onch = (typeof cb != 'undefined') ? ' onchange=Harmony.'+cb+'(\''+di+'\',\''+vr+'\'); ' : ' ';
//		var typ = (vr.toLowerCase() == 'password') ? 'type="password"' : 'type="text"';
		var typ = 'type="text"';
		var html = '<div class="clearfix labelInputContainer">'+
					'<div class="pull-left inputLabel '+((bOnALTUI) ? 'form-control form-control-sm form-control-plaintext' : '')+'" style="width:280px;">'+lb+'</div>'+
					'<div class="pull-left">'+
						'<input class="customInput '+((bOnALTUI) ? 'altui-ui-input form-control form-control-sm' : '')+'" '+onch+'style="width:200px;" '+typ+' size="'+si+'" id="hamID_'+vr+di+'" value="'+val+'">'+
					'</div>'+
				   '</div>';
/* pwd support no longer needed for WebSocket API.
		if (vr.toLowerCase() == 'password') {
			html += '<div class="clearfix labelInputContainer '+((bOnALTUI) ? 'form-control form-control-sm form-control-plaintext' : '')+'">'+
					'<div class="pull-left inputLabel" style="width:280px;">&nbsp; </div>'+
					'<div class="pull-left '+((bOnALTUI) ? 'form-check' : '')+'" style="width:200px;">'+
						'<input class="pull-left customCheckbox '+((bOnALTUI) ? 'form-check-input' : '')+'" type="checkbox" id="hamID_'+vr+di+'Checkbox">'+
						'<label class="labelForCustomCheckbox '+((bOnALTUI) ? 'form-check-label' : '')+'" for="hamID_'+vr+di+'Checkbox">Show Password</label>'+
					'</div>'+
				   '</div>';
			html += '<script type="text/javascript">'+
					'$("#hamID_'+vr+di+'Checkbox").on("change", function() {'+
					' var typ = (this.checked) ? "text" : "password" ; '+
					' $("#hamID_'+vr+di+'").prop("type", typ);'+
					'});'+
					'</script>';
		}
*/		
		return html;
	}
	// Add a Save Settings button
	function htmlAddButton(di, cb) {
		var html = '<div class="cpanelSaveBtnContainer labelInputContainer clearfix">'+	
			'<input class="vBtn pull-right btn" type="button" value="Save Changes" onclick="Harmony.'+cb+'(\''+di+'\');"></input>'+
			'</div>';
		return html;
	}

	// Show/hide the interface busy indication.
	function showBusy(busy) {
		if (busy === true) {
			try {
				api.ui.showStartupModalLoading(); // version v1.7.437 and up
			} catch (e) {
				myInterface.showStartupModalLoading(); // For ALTUI support.
			}
		} else {
			try {
				api.ui.hideModalLoading(true);
			} catch (e) {
				myInterface.hideModalLoading(true); // For ALTUI support
			}	
		}
	}

	function doReload(deviceID) {
		api.performLuActionOnDevice(0, "urn:micasaverde-com:serviceId:HomeAutomationGateway1", "Reload", {});
	}

	// Expose interface functions
    myModule = {
		// Internal for panels
        uuid: _uuid,
        init: _init,
        onBeforeCpanelClose: _onBeforeCpanelClose,
		UpdateSettingsCB: _UpdateSettingsCB,
		UpdateButtons: _UpdateButtons,
		UpdateDeviceButtons: _UpdateDeviceButtons,
		UpdateDeviceSelections: _UpdateDeviceSelections,
		
		// For JSON calls
        Settings: _Settings,
        Activities: _Activities,
        Devices: _Devices,
        DeviceSettings: _DeviceSettings
		
    };
    return myModule;
})(api);

