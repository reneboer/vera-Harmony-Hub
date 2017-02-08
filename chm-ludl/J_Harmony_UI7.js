//# sourceURL=J_Harmony_UI7.js
// harmony Hub Control UI for UI7
// Written by R.Boer. 
// V2.15 7 February 2017
//
// V2.15 Changes:
//		New settings option to wait on Hub to fully complete the start of an activity or not.
//
// V2.13-1 Changes:
//		The password input now has the HTML input type password so it won't show.
// 		Some hints on poll frequency settings.
//
// V2.7 Changes:
//		User can disable plugin. Signal status on control panel.
//		No more reference to myInterface, using correct api.ui calls instead.
//
// V2.5 Changes:
//		Can define key-press duration for devices.
//		Some JQuery use. Layout improvements for native UI and ALTUI.
// 		Changed poll and acknowledge settings to drop down selections.
//		Proper JSON returns from LUA.
//
// V2.4 Changes:
//		Some optimizations in Vera api calls that now work on UI7
//
// V2.1 Changes:
//		Added selection for time out.
//
// V2.02 Changes:
//		Removed options for MaxActivity and Device Buttons. Now just fixed.
//		Removed Enable Button Feedback option. Now uses Ok Acknowledge Interval value.
//		Fixed getInfo and LUA command issue with IE.
//		Default activity and command descriptions when user does not enter them.
//		Added Default Activity selection for SetTarget action.
//		When not specifying a Description, the activity or command will be defaulted.
// V2.01 Changes:
//		getInfo query adds device ID for multiple hub support.
// V2.0 Changes:
//		Save of variables via luup action as standard save function does not work reliably remote
// V1.9 changes:
// 		Corrected serviceId for UpdateDeviceButtons action.
//		Added syslog support

var Harmony = (function (api) {

	// Constants. Keep in sync with LUA code.
    var _uuid = '12021512-0000-a0a0-b0b0-c0c030303031';
	var HAM_SID = 'urn:rboer-com:serviceId:Harmony1';
	var HAM_CHSID = 'urn:rboer-com:serviceId:HarmonyDevice1';
	var HAM_MAXBUTTONS = 25;
	var HAM_ERR_MSG = "Error : ";

	// Forward declaration.
    var myModule = {};

    function _onBeforeCpanelClose(args) {
		showBusy(false);
        //console.log('Harmony, handler for before cpanel close');
    }

    function _init() {
        // register to events...
        api.registerEventHandler('on_ui_cpanel_before_close', myModule, 'onBeforeCpanelClose');
    }
	
	// Return HTML for settings tab
	function _Settings() {
		_init();
        try {
			var deviceID = api.getCpanelDeviceId();
			var deviceObj = api.getDeviceObject(deviceID);
			var timeOuts = [{'value':'2','label':'2 Sec'},{'value':'5','label':'5 Sec (default)'},{'value':'10','label':'10 Sec'},{'value':'30','label':'30 Sec (Pi recommended)'},{'value':'60','label':'60 Sec'}];
			var timePolls = [{'value':'0','label':'No Polling'},{'value':'5','label':'5 Sec (not recommended)'},{'value':'10','label':'10 Sec (not recommended)'},{'value':'15','label':'15 Sec'},{'value':'20','label':'20 Sec'},{'value':'30','label':'30 Sec'},{'value':'45','label':'45 Sec'},{'value':'60','label':'60 Sec'},{'value':'90','label':'90 Sec'},{'value':'120','label':'120 Sec'}];
			var timeAck = [{'value':'0','label':'None'},{'value':'1','label':'1 Sec'},{'value':'2','label':'2 Sec'},{'value':'3','label':'3 Sec'}];
			var yesNo = [{'value':'0','label':'No'},{'value':'1','label':'Yes'}];
			var logLevel = [{'value':'1','label':'Error'},{'value':'2','label':'Warning'},{'value':'8','label':'Info'},{'value':'10','label':'Debug'}];
			var actSel = [{ 'value':'','label':'None'}];
			var ip = !!deviceObj.ip ? deviceObj.ip : '';
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
				html +=	htmlAddInput(deviceID, 'Harmony Hub IP Address', 20, 'IPAddress', HAM_SID, ip) + 
				htmlAddInput(deviceID, 'Harmony Hub Email', 30, 'Email') + 
				htmlAddInput(deviceID, 'Harmony Hub Password', 20, 'Password')+
				htmlAddPulldown(deviceID, 'Harmony Hub communication time out', 'CommTimeOut', timeOuts)+
				htmlAddPulldown(deviceID, 'Current Activity Poll Interval', 'PollInterval', timePolls)+
				htmlAddPulldown(deviceID, 'Ok Acknowledge Interval', 'OkInterval', timeAck)+
				htmlAddPulldown(deviceID, 'Default Activity', 'DefaultActivity', actSel)+
				htmlAddPulldown(deviceID, 'Wait on Activity start complete', 'WaitOnActivityStartComplete', yesNo)+
				htmlAddPulldown(deviceID, 'Enable HTTP Request Handler', 'HTTPServer', yesNo)+
				htmlAddPulldown(deviceID, 'Enable Remote Icon Images', 'RemoteImages', yesNo)+
				htmlAddPulldown(deviceID, 'Log level', 'LogLevel', logLevel)+
				htmlAddInput(deviceID, 'Syslog server IP Address:Port', 30, 'Syslog') + 
				htmlAddButton(deviceID, 'UpdateSettings');
			}
			html += '</div>';
			api.setCpanelContent(html);
        } catch (e) {
            Utils.logError('Error in Harmony.Settings(): ' + e);
        }
	}

	// Request HTML for activities tab
	function _Activities() {
		_init();
        try {
			var deviceID = api.getCpanelDeviceId();
			var deviceObj = api.getDeviceObject(deviceID);
			if (deviceObj.disabled === '1' || deviceObj.disabled === 1) {
				htmlSetLoadMessage(deviceID,'AC','Plugin is disabled in Attributes.',true);
				showBusy(false);
			} else {	
				htmlSetLoadMessage(deviceID,'AC','Loading activities from Harmony Hub.',false);
				getInfo(deviceID, HAM_SID, 'hamGetActivities', '', _ActivitiesHandler); 
			}	
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
			if (deviceObj.disabled === '1' || deviceObj.disabled === 1) {
				htmlSetLoadMessage(deviceID,'DH','Plugin is disabled in Attributes.',true);
				showBusy(false);
			} else {	
				htmlSetLoadMessage(deviceID,'DH','Loading devices from Harmony Hub.',false);
				getInfo(deviceID, HAM_SID, 'hamGetDevices', '', _DevicesHandler); 
			}	
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
			if (prntObj.disabled === '1' || prntObj.disabled === 1) {
				htmlSetLoadMessage(deviceID,'DS','Plugin is disabled in Parent Attributes.',true);
				showBusy(false);
			} else {	
				htmlSetLoadMessage(deviceID,'DS','Loading device commands from Harmony Hub.',false);
				var devID = varGet(deviceID,'DeviceID',HAM_CHSID);
				getInfo(deviceID, HAM_SID, 'hamGetDeviceCommands', devID, _DeviceSettingsHandler, deviceObj.id_parent); 
			}	
        } catch (e) {
            Utils.logError('Error in Harmony.DeviceSettings(): ' + e);
        }
	}

	// Build HTML for activities tab
	function _ActivitiesHandler(deviceID, result) {
		try {
			var html = '';
			// We should have received a JSON object.
			if (typeof result=="object") {
				// Parse Activity IDs to make button selections
				var actSel = [{ 'value':'','label':'None'}];
				for (var i=0; i<result.activities.length; i++) {
					actSel.push({'value':result.activities[i].ID,'label':result.activities[i].Activity});
				}
				html += '<b>Activity mappings</b>'+
					htmlAddButton(deviceID,'UpdateButtons')+
					'<div id="ham_msg">Select activities you want to be able to control and click Save Changes.<br>'+
					'The labels should fit a button, normally 7 or 8 characters max.<br>'+
					'A reload command may be performed automatically.</div>'+
					'<p>';
				for (i=1; i<=HAM_MAXBUTTONS; i++) {
					html += htmlAddMapping(deviceID, 'Button '+i+' Activity ID'+i,'ActivityID'+i,actSel,'Label','ActivityDesc'+i);
				}
			} else {
				// Report failure to user
				if (typeof result=="string") {
					html += result;
				} else {
					html += "Unknown error occurred. Try again in a minute.";
				}
			}
			$("#hamID_content_AC_"+deviceID).html(html);
        } catch (e) {
            Utils.logError('Error in Harmony.ActivitiesHandler(): ' + e);
        }
		showBusy(false);
	}

	// Build HTML for devices tab
	function _DevicesHandler(deviceID, result) {
		try {
			var yesNo = [{'value':'0','label':'No'},{'value':'1','label':'Yes'}];
			var childMsg = [];
			var html = '';
			// We should have received a JSON object.
			if (typeof result=="object") {
				for (var i=0; i<result.devices.length; i++) {
					childMsg.push({ 'value':result.devices[i].ID,'label':result.devices[i].Device });
				}
				html += '<b>Device selection</b>'+
					'<p>'+
					'<div id="ham_msg">Select device(s) you want to be able to control and click Save Changes.<br>'+
					'For each selected a child device will be created.<br>'+
					'A reload command may be performed automatically.</div>'+
					'<p>'+
					htmlAddPulldownMultiple(deviceID, 'Devices to Control', 'PluginHaveChildren', childMsg)+
					htmlAddPulldown(deviceID, 'Create child devices embedded', 'PluginEmbedChildren', yesNo)+
					htmlAddButton(deviceID,'UpdateDeviceSelections');
			} else {
				// Report failure to user
				if (typeof result=="string") {
					html = result;
				} else {
					html = "Unknown error occurred. Try again in a minute.";
				}
			}
			$("#hamID_content_DH_"+deviceID).html(html);
        } catch (e) {
            Utils.logError('Error in Harmony.DevicesHandler(): ' + e);
        }
		showBusy(false);
	}

	// Build HTML for child device settings tab
	function _DeviceSettingsHandler(deviceID, result) {
		try {
			// We should have received a JSON object.
			var html = '';
			if (typeof result=="object") {
				var actSel = [{ 'value':'','label':'None'}];
				for (var i=0; i<result.devicecommands.length; i++) {
					actSel.push({ 'value':result.devicecommands[i].Action,'label':result.devicecommands[i].Label});
				}
				html += '<b>Device Command mappings</b>'+
					htmlAddButton(deviceID,'UpdateDeviceButtons')+
					'<div id="ham_msg">Select commands you want to be able to control and click Save Changes.<br>'+
					'The labels should fit a button, normally 7 or 8 characters max.<br>'+
					'A reload command may be performed automatically.</div>'+
					'<p>';
				for (i=1; i<=HAM_MAXBUTTONS; i++) {
					html += htmlAddMapping(deviceID, 'Button '+i+' Command','Command'+i,actSel,'Label','CommandDesc'+i, HAM_CHSID);
				}
			} else {
				// Report failure to user
				if (typeof result=="string") {
					html = result;
				} else {
					html = "Unknown error occurred. Try again in a minute.";
				}
			}
			$("#hamID_content_DS_"+deviceID).html(html);
		} catch (e) {
            Utils.logError('Error in Harmony.DeviceSettingsHandler(): ' + e);
        }
		showBusy(false);
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

	function _UpdateSettings(deviceID) {
		// Save variable values so we can access them in LUA without user needing to save
		showBusy(true);
		var devicePos = api.getDeviceIndex(deviceID);
		varSet(deviceID,'Email',htmlGetElemVal(deviceID, 'Email'));
		varSet(deviceID,'Password',htmlGetElemVal(deviceID, 'Password'));
		varSet(deviceID,'CommTimeOut',htmlGetPulldownSelection(deviceID, 'CommTimeOut'));
		varSet(deviceID,'PollInterval',htmlGetElemVal(deviceID, 'PollInterval'));
		varSet(deviceID,'OkInterval',htmlGetElemVal(deviceID, 'OkInterval'));
		varSet(deviceID,'DefaultActivity',htmlGetPulldownSelection(deviceID, 'DefaultActivity'));
		varSet(deviceID,'WaitOnActivityStartComplete',htmlGetPulldownSelection(deviceID, 'WaitOnActivityStartComplete'));
		varSet(deviceID,'HTTPServer',htmlGetPulldownSelection(deviceID, 'HTTPServer'));
		varSet(deviceID,'RemoteImages',htmlGetPulldownSelection(deviceID, 'RemoteImages'));
		varSet(deviceID,'LogLevel',htmlGetPulldownSelection(deviceID, 'LogLevel'));
		varSet(deviceID,'Syslog',htmlGetElemVal(deviceID, 'Syslog'));
		var ipa = htmlGetElemVal(deviceID, 'IPAddress');
		if (Utils.isValidIp(ipa)) {
			api.setDeviceAttribute(deviceID, 'ip', ipa);
		}
		application.sendCommandSaveUserData(true);
		doReload(deviceID);
		setTimeout(function() {
			showBusy(false);
			try {
//				myInterface.showMessagePopup(Utils.getLangString("ui7_device_cpanel_details_saved_success","Device details saved successfully."),0);
				api.ui.showMessagePopup(Utils.getLangString("ui7_device_cpanel_details_saved_success","Device details saved successfully."),0);
			}
			catch (e) {
				myInterface.showMessagePopup(Utils.getLangString("ui7_device_cpanel_details_saved_success","Device details saved successfully."),0); // ALTUI
//				Utils.logError('Harmony: UpdateSettings(): ' + e);
			}
		}, 3000);	
	}
	// Update the buttons for the main device.
	function _UpdateButtons(deviceID) {
		// Save variable values so we can access them in LUA without user needing to save
		var bChanged = false;
		showBusy(true);
		for (var icnt=1; icnt <= HAM_MAXBUTTONS; icnt++) {
			var idval = htmlGetElemVal(deviceID, 'ActivityID'+icnt);
			var labval = htmlGetElemVal(deviceID, 'ActivityDesc'+icnt);
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
			if (labval != orglab) {
				varSet(deviceID,'ActivityDesc'+icnt, labval);
				bChanged=true;
			}	
		}
		// If we have changes, update buttons.
		if (bChanged) {
			application.sendCommandSaveUserData(true);
			api.performLuActionOnDevice(deviceID, HAM_SID, 'UpdateButtons', {});
			setTimeout(function() {
				showBusy(false);
				htmlSetMessage("Changes to the buttons made.<br>Now wait for reload to complete and then refresh your browser page!",false);
			}, 3000);	
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
			if (labval != orglab) {
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
			// Wait a second to send the actual action, as it may have issues not saving all data on time.
			application.sendCommandSaveUserData(true);
			api.performLuActionOnDevice(deviceID, HAM_CHSID, 'UpdateDeviceButtons', {});
			setTimeout(function() {
				showBusy(false);
				htmlSetMessage("Changes to the buttons made.<br>Now wait for reload to complete and then refresh your browser page!",false);
			}, 3000);	
		} else {
			showBusy(false);
			htmlSetMessage("You have not changed any values.<br>No changes to the buttons made.",true);
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
		selIDs = htmlGetElemVal(deviceID, 'PluginEmbedChildren');
		orgIDs = varGet(deviceID, 'PluginEmbedChildren');
		if (selIDs != orgIDs) {
			varSet(deviceID,'PluginEmbedChildren', selIDs);
		}	
		// If we have changes in child devices, reload device.
		if (bChanged) {
			application.sendCommandSaveUserData(true);
			doReload(deviceID);
			setTimeout(function() {
				htmlSetMessage("Changes to child devices made.<br>Now wait for reload to complete and then refresh your browser page!",false);
				showBusy(false);
			}, 3000);	
		} else {
			htmlSetMessage("You have not selected any other devices.<br>No changes made.",true);
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
//				myInterface.showMessagePopupError(msg);
				api.ui.showMessagePopupError(msg);
			} else {
//				myInterface.showMessagePopup(msg,0);
				api.ui.showMessagePopup(msg,0);
			}	
		}	
		catch (e) {	
			$("#ham_msg").html(msg+'<br>&nbsp;');
		}	
	}
	function htmlSetLoadMessage(deviceID,typ,msg,disabled) {
		var html = '<div class="deviceCpanelSettingsPage">'+
			'<h3>Device #'+deviceID+'&nbsp;&nbsp;&nbsp;'+api.getDisplayedDeviceName(deviceID)+'</h3>';
		html += '<div id="hamID_content_'+typ+'_'+deviceID+'">'+
			'<table width="100%" border="0" cellspacing="3" cellpadding="0">'+
			'<tr><td>&nbsp;</td></tr>'+
			'<tr><td>'+msg+'</td></tr>'+
			'<tr><td>&nbsp;</td></tr>';
		if (disabled !== true) {	
			'<tr><td align="center">Please wait...</td></tr>';
		}	
		html += '</table></div></div>';
		api.setCpanelContent(html);
		showBusy(true);
	}

	// Add label, pulldown, label, input
	function htmlAddMapping(di, lb1, vr1, values, lb2, vr2, sid) {
		try {
			var selVal = varGet(di, vr1, sid);
			var wdth = (typeof ALTUI_revision != 'undefined') ? 'style="width:160px;"' : '';  // Use on ALTUI
			var html = '<div class="clearfix labelInputContainer">'+
				'<div class="pull-left inputLabel" '+wdth+'>'+lb1+'</div>'+
				'<div class="pull-left customSelectBoxContainer" style="width:160px;">'+
				'<select id="hamID_'+vr1+di+'" class="customSelectBox" style="width:160px;">';
			for(var i=0;i<values.length;i++){
				html += '<option value="'+values[i].value+'" '+((''+values[i].value==selVal)?'selected':'')+'>'+values[i].label+'</option>';
			}
			html += '</select>'+
				'</div>';
			html += '<div class="pull-left inputLabel" style="margin-left:50px; width:40px;">'+lb2+'</div>'+
				'<div class="pull-left">'+
					'<input class="customInput" style="width:160px;" id="hamID_'+vr2+di+'" size="15" type="text" value="'+varGet(di,vr2,sid)+'">'+
				'</div>';
			// V2.5, for Devices the key-press can be longer then just a click.	
			if (typeof sid != 'undefined') {
				var timeDuration = [{'value':'0','label':'Click'},{'value':'1','label':'1 Sec'},{'value':'2','label':'2 Sec'},{'value':'3','label':'3 Sec'},{'value':'4','label':'4 Sec'},{'value':'5','label':'5 Sec'},{'value':'7','label':'7 Sec'},{'value':'10','label':'10 Sec'},{'value':'15','label':'15 Sec'}];
				var selDur = varGet(di, 'Prs'+vr1, sid);
				html += '<div class="pull-left inputLabel" style="margin-left:50px; width:60px;">Press</div>'+
				'<div class="pull-left customSelectBoxContainer" style="width:80px;">'+
				'<select id="hamID_Prs'+vr1+di+'" class="customSelectBox" style="width:80px;">';
				for(i=0;i<timeDuration.length;i++){
					html += '<option value="'+timeDuration[i].value+'" '+((''+timeDuration[i].value==selDur)?'selected':'')+'>'+timeDuration[i].label+'</option>';
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
	function htmlAddPulldown(di, lb, vr, values) {
		try {
			var selVal = varGet(di, vr);
			var html = '<div class="clearfix labelInputContainer">'+
				'<div class="pull-left inputLabel" style="width:280px;">'+lb+'</div>'+
				'<div class="pull-left customSelectBoxContainer">'+
				'<select id="hamID_'+vr+di+'" class="customSelectBox">';
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
	function htmlAddPulldownMultiple(di, lb, vr, values) {
		try {
			var selVal = varGet(di, vr);
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
	function htmlAddInput(di, lb, si, vr, sid, df) {
		var val = (typeof df != 'undefined') ? df : varGet(di,vr,sid);
		var typ = (vr.toLowerCase() == 'password') ? 'type="password"' : 'type="text"';
		var html = '<div class="clearfix labelInputContainer">'+
					'<div class="pull-left inputLabel" style="width:280px;">'+lb+'</div>'+
					'<div class="pull-left">'+
						'<input class="customInput" '+typ+' size="'+si+'" id="hamID_'+vr+di+'" value="'+val+'">'+
					'</div>'+
				   '</div>';
		if (vr.toLowerCase() == 'password') {
			html += '<div class="clearfix labelInputContainer">'+
					'<div class="pull-left inputLabel" style="width:280px;">&nbsp; </div>'+
					'<div class="pull-left">'+
						'<input class="customCheckbox" type="checkbox" id="hamID_'+vr+di+'Checkbox">'+
						'<label class="labelForCustomCheckbox" for="hamID_'+vr+di+'Checkbox">Show Password</label>'+
					'</div>'+
				   '</div>';
			html += '<script type="text/javascript">'+
					'$("#hamID_'+vr+di+'Checkbox").on("change", function() {'+
					' var typ = (this.checked) ? "text" : "password" ; '+
					' $("#hamID_'+vr+di+'").prop("type", typ);'+
					'});'+
					'</script>';
		}
		return html;
	}
	// Add a Save Settings button
	function htmlAddButton(di, cb) {
		var html = '<div class="cpanelSaveBtnContainer labelInputContainer clearfix">'+	
			'<input class="vBtn pull-right" type="button" value="Save Changes" onclick="Harmony.'+cb+'(\''+di+'\');"></input>'+
			'</div>';
		return html;
	}

	// Show/hide the interface busy indication.
	function showBusy(busy) {
		if (busy === true) {
			try {
				api.ui.showStartupModalLoading(); // version v1.7.437 and up
			} catch (e) {
				api.ui.startupShowModalLoading(); // Prior versions.
			}
		} else {
			try {
				api.ui.hideModalLoading(true);
			} catch (e) {
				myInterface.hideModalLoading(true); // For ALTUI support
			}	
		}
	}

	function getInfo(device, sid, what, devid, func, prnt_id) {
		var result;
		var devnum = (typeof prnt_id != 'undefined') ? prnt_id : device;
		var tmstmp = new Date().getTime(); // To avoid caching issues, mainly IE.
		try {
			var requestURL = api.getCommandURL(); 
		} catch (e) {
			var requestURL = command_url;
		}
		(function() {
			$.getJSON(requestURL+'/data_request', {
				id: 'lr_'+what+devnum,
				serviceId: sid,
				DeviceNum: device,
				timestamp: tmstmp,
				HID: devid,
				output_format: 'json'
			})
			.done(function(data) {
				func(device, data);
			})	
			.fail(function(data) {
				func(device, HAM_ERR_MSG+"Failed to get data from Hub.");
			});
		})();
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
		UpdateSettings: _UpdateSettings,
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

