//# sourceURL=J_Harmony_UI5.js
/* harmony Hub Control UI json for UI5/UI6
 Written by R.Boer. 
 V4.1 17 April 2019

 V4.1 Changes:
		Support for compact device configuration
 V4.0 Changes:
		Added Activity child devices.
 V3.9 Changes:
		Clear Domain variable on IP address change.
		Fix for missing variable val in hamhtmlAddInput.
		Fix in hamDevices and hamDeviceSettings.
 V3.7 Changes:
		Clear RemoteID on IP address change.
 V3.5 Changes:
 		Removed the HTTP Server as option.
		For UI5 we now have the exception script name.
 V3.3 Changes:
		Added support for automation devices. For now Lamps only.
 V3.1 Changes:
		Fix for hamDeviceSettings
 V3.0 Changes:
		Changed to WebSockets API, no longer need for uid,pwd and polling settings.
		Activities, Devices and Commands are now in variable, no need for HTTP handler.
 V2.20 Changes:
		Removed syslog support
 V2.19 Changes:
		IP Address is now stored in normal variable, no longer in device IP attribute.
 V2.16 Changes:
		Changed call to request data from Vera Handlers.
 V2.15 Changes:
		New settings option to wait on Hub to fully complete the start of an activity or not.
 V2.13-1 Changes:
		The password input now has the HTML input type password so it won't show.
 V2.7 Changes:
		User can disable plugin. Signal status on control panel.
 V2.5 Changes:
		Can define key-press duration for devices.
		Layout improvements for native UI and ALTUI.
 		Changed poll and acknowledge settings to drop down selections.
		Proper JSON returns from LUA.
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
 V1.9 changes:
 		Corrected serviceId for UpdateDeviceButtons action.
		Added syslog support
*/

// Constants. Keep in sync with LUA code.
var HAM_SID = 'urn:rboer-com:serviceId:Harmony1';
var HAM_CHSID = 'urn:rboer-com:serviceId:HarmonyDevice1';
var HAM_MAXBUTTONS = 24;
var HAM_ERR_MSG = "Error : ";

// Return HTML for settings tab
function hamSettings(deviceID) {
	var deviceObj = get_device_obj(deviceID);
	var devicePos = get_device_index(deviceID);
	var yesNo = [{'value':'0','label':'No'},{'value':'1','label':'Yes'}];
	var timeAck = [{'value':'0','label':'None'},{'value':'1','label':'1 Sec'},{'value':'2','label':'2 Sec'},{'value':'3','label':'3 Sec'}];
	var logLevel = [{'value':'1','label':'Error'},{'value':'2','label':'Warning'},{'value':'8','label':'Info'},{'value':'11','label':'Debug'}];
	var actSel = [{ 'value':'','label':'None'}];
	for (i=1; i<=HAM_MAXBUTTONS; i++) {
		var actID = hamVarGet(deviceID,'ActivityID'+i);
		var actDesc = hamVarGet(deviceID,'ActivityDesc'+i);
		if (actID !== '' && actDesc !== '') {
			actSel.push({'value':actID,'label':actDesc});
		}
	}
	var html = '<table border="0" cellpadding="0" cellspacing="3" width="100%"><tbody>'+
		'<tr><td colspan="2"><b>Device #'+deviceID+'</b>&nbsp;&nbsp;&nbsp;'+((deviceObj.name)?deviceObj.name:'')+'</td></tr>';
	if (deviceObj.disabled === '1' || deviceObj.disabled === 1) {
		html += '<tr><td colspan="2">&nbsp;</td></tr><tr><td colspan="2">Plugin is disabled in Attributes.</td></tr>';
	} else {		
		html+= hamhtmlAddInput(deviceID, 'Harmony Hub IP Address', 30, 'HubIPAddress','UpdateSettingsCB')+
		hamhtmlAddPulldown(deviceID, 'Ok Acknowledge Interval', 'OkInterval', timeAck, true)+
		hamhtmlAddPulldown(deviceID, 'Default Activity', 'DefaultActivity', actSel, true)+
		hamhtmlAddPulldown(deviceID, 'Enable Remote Icon Images', 'RemoteImages', yesNo, true)+
		hamhtmlAddPulldown(deviceID, 'Log level', 'LogLevel', logLevel, true);
	}	
	html += '</tbody></table>';
    set_panel_html(html);
}

function hamUpdateSettingsCB(deviceID,varID,newVal) {
	switch (varID) {
	case 'HubIPAddress':
		// We cannot put this in a call_action as the initialization will fail when IP address is incorrect.
		// When we don't fail initialization we cannot flag device on openLuup.
		hamVarSet(deviceID,'HubIPAddress',newVal);
		hamVarSet(deviceID,'RemoteID','');	// Clear remote ID and other Hub details as with new IP we need to ask for it again.
		hamVarSet(deviceID,'AccountID','');	
		hamVarSet(deviceID,'Domain','');	
		hamVarSet(deviceID,'email','');	
		break;
	}
}
// Request HTML for activities tab
function hamActivities(deviceID) {
	var deviceObj = get_device_obj(deviceID);
	var html = '<div id="hamID_content_AC_'+deviceID+'">'+
		'<table width="100%" border="0"><tbody>'+
		'<tr><td class="regular"><b>Device #'+deviceID+'</b>&nbsp;&nbsp;&nbsp;'+((deviceObj.name)?deviceObj.name:'')+'</td></tr>'+
		'<tr><td>&nbsp;</td></tr>';
	if (deviceObj.disabled === '1' || deviceObj.disabled === 1) {
		html += '<tr><td>Plugin is disabled in Attributes.</td></tr>';
	} else {	
		var actjs = hamVarGet(deviceID,'Activities');
		if (actjs != '') {
			var acts = JSON.parse(actjs).activities;
			var actSel = [{ 'value':'','label':'None'}];
			for (var i=0; i<acts.length; i++) {
				actSel.push({ 'value':acts[i].ID,'label':acts[i].Activity});
			}
			html += '<table border="0" cellpadding="0" cellspacing="3" width="100%"><tbody>'+
				'<tr><td width="140"><b>Activity mappings</b></td><td colspan="3"></td></tr>'+
				hamhtmlAddButton(deviceID,'UpdateButtons',4)+
				'<tr><td colspan="4">'+
				'<div id="ham_msg">Select activities you want to be able to control and click Save Changes. <br>'+
				'The labels should fit a button, normally 7 or 8 characters max.<br>'+
				'A reload command may be performed automatically.</div>'+
				'<p></td></tr>';
			for (i=1; i<=HAM_MAXBUTTONS; i++) {
				html += hamhtmlAddMapping(deviceID, 'Activity ID button '+i,'ActivityID'+i,actSel,'Label button '+i,'ActivityDesc'+i);
			}
			html += '</tbody></table>';
		} else {
			html += '<table width="100%" border="0" cellspacing="3" cellpadding="0">'+
				'<tr><td>&nbsp;</td></tr>'+
				'<tr><td>Activities not loaded. Click the Update Configuration button.</td></tr></table>';
		}	
	}
	html += '<tr><td>&nbsp;</td></tr></tbody></table>';
	set_panel_html(html);
}

// Return HTML for devices tab
function hamDevices(deviceID) {
	var deviceObj = get_device_obj(deviceID);
	var html = '<div id="hamID_content_DH_'+deviceID+'">'+
		'<table width="100%" border="0"><tbody>'+
		'<tr><td class="regular"><b>Device #'+deviceID+'</b>&nbsp;&nbsp;&nbsp;'+((deviceObj.name)?deviceObj.name:'')+'</td></tr>'+
		'<tr><td>&nbsp;</td></tr>';
	if (deviceObj.disabled === '1' || deviceObj.disabled === 1) {
		html += '<tr><td>Plugin is disabled in Attributes.</td></tr>';
	} else {	
		var devList = [];
		var lampList = [];
		var yesNo = [{'value':'0','label':'No'},{'value':'1','label':'Yes'}];
		var devJs = hamVarGet(deviceID,'Devices');
		var lampJs = hamVarGet(deviceID,'Lamps');
		var devHtml = 'Devices not loaded. Check Hub configuration and click the Update Configuration button.';
		var lampHtml = '';
		if (devJs != '') {
			var devs = JSON.parse(devJs).devices;
			for (var i=0; i<devs.length; i++) {
				devList.push({ 'value':devs[i].ID,'label':devs[i].Device });
			}
			devHtml = hamhtmlAddPulldownMultiple(deviceID, 'Devices to Control', 'PluginHaveChildren', devList)+'<p>';
		}
		if (lampJs != '') {
			var devs = JSON.parse(lampJs).lamps;
			for (var i=0; i<devs.length; i++) {
				lampList.push({ 'value':devs[i].udn,'label':devs[i].name });
			}
			lampHtml = '<p>'+hamhtmlAddPulldownMultiple(deviceID, 'Lamps to Control', 'PluginHaveLamps', lampList)+'<p>';
		}
		html = '<table border="0" cellpadding="0" cellspacing="3" width="100%"><tbody>'+
			'<tr><td width=200><b>Device selection</b></td><td></td></tr>'+
			hamhtmlAddButton(deviceID,'UpdateDeviceSelections',2)+
			'<tr><td colspan="2">'+
			'<div id="ham_msg">Select device(s) you want to be able to control and click Save Changes.<br>'+
			'For each selected a child device will be created.<br>'+
			'A reload command may be performed automatically.</div>'+
			'</td></tr>'+devHtml+lampHtml+
			hamhtmlAddPulldown(deviceID, 'Create child devices embedded', 'PluginEmbedChildren', yesNo)+
			'</tbody></table>';
	}	
	html += '<tr><td>&nbsp;</td></tr></tbody></table>';
	set_panel_html(html);
}

// Return HTML for device settings tab
function hamDeviceSettings(deviceID) {
	var deviceObj = get_device_obj(deviceID);
	var html = '<div id="hamID_content_DS_'+deviceID+'">'+
		'<table width="100%" border="0"><tbody>'+
		'<tr><td class="regular"><b>Device #'+deviceID+'</b>&nbsp;&nbsp;&nbsp;'+((deviceObj.name)?deviceObj.name:'')+'</td></tr>'+
		'<tr><td>&nbsp;</td></tr>';
	var prntObj = get_device_obj(deviceObj.id_parent);
	if (prntObj.disabled === '1' || prntObj.disabled === 1) {
		html += '<tr><td>Plugin is disabled in Attributes.</td></tr>';
	} else {	
		var cmdjs = hamVarGet(deviceID,'DeviceCommands',HAM_CHSID);
		if (cmdjs != '') {
			var funcs = JSON.parse(cmdjs).Functions;
			var actSel = [{ 'value':'','label':'None'}];
			for (var i=0; i<funcs.length; i++) {
				for (var j=0; j<funcs[i].Commands.length; j++) {
					var act = funcs[i].Commands[j].Action;
					var lab = ((typeof(funcs[i].Commands[j].Label) == 'undefined')?act:funcs[i].Commands[j].Label);
					actSel.push({'value':act,'label':lab});
				}	
			}	
			html = '<table border="0" cellpadding="0" cellspacing="3" width="100%"><tbody>'+
				'<tr><td colspan="4" class="regular"><b>Device #'+deviceID+'</b>&nbsp;&nbsp;&nbsp;'+((deviceObj.name)?deviceObj.name:'')+'</td></tr>'+
				'<tr><td colspan="4"><div><b>Device Command mappings</b></div></td></tr>'+
				hamhtmlAddButton(deviceID,'UpdateDeviceButtons',4)+
				'<tr><td colspan="4">'+
				'<div id="ham_msg">Select commands you want to be able to control and click Save Changes.<br>'+
				'The labels should fit a button, normally 7 or 8 characters max.<br>'+
				'A reload command will be performed automatically.</div>'+
				'</td></tr>';
			for (i=1; i<=HAM_MAXBUTTONS; i++) {
				html += hamhtmlAddMapping(deviceID, 'Button '+i+' Command','Command'+i,actSel,'Label','CommandDesc'+i, HAM_CHSID);
			}
			html += '</tbody></table>';
		} else {
			html += '<table width="100%" border="0" cellspacing="3" cellpadding="0">'+
				'<tr><td>&nbsp;</td></tr>'+
				'<tr><td>Commands not loaded. Click the Update Configuration button in the main device.</td></tr></table>';
		}	
	}	
	html += '<tr><td>&nbsp;</td></tr></tbody></table>';
	set_panel_html(html);
}


function hamVarSet(deviceID, varID, newValue, sid) {
	if (typeof(sid) == 'undefined') { sid = HAM_SID; }
	set_device_state(deviceID,  sid, varID, newValue, 0);	// Save in user_data so it is there after luup reload
	set_device_state(deviceID,  sid, varID, newValue, 1); // Save in lu_status so it is directly available for others.
}

function hamVarGet(deviceID, varID, sid) {
	if (typeof(sid) == 'undefined') { sid = HAM_SID; }
	var res = get_device_state(deviceID,sid,varID);
	res = (res !== false && res !== 'false' && res !== null  && typeof(res) !== 'undefined') ? res : '';
	return res;
}

function hamUpdateButtons(deviceID) {
	// Save variable values so we can access them in LUA without user needing to save
	var bChanged = false;
	var ncArr = [];
	for (icnt=1; icnt <= HAM_MAXBUTTONS; icnt++) {
		var idval=hamhtmlGetElemVal(deviceID, 'ActivityID'+icnt);
		var labval=hamhtmlGetElemVal(deviceID, 'ActivityDesc'+icnt);
		var chldval = hamhtmlGetElemVal(deviceID, 'ActivityID'+icnt+'Child');
		var orgid = hamVarGet(deviceID, 'ActivityID'+icnt);
		var orglab = hamVarGet(deviceID, 'ActivityDesc'+icnt);
		// Check for empty Activity descriptions, and default to activity
		if (idval !== '' && labval === '') {
			var s = document.getElementById('hamID_ActivityID'+icnt+deviceID);
			labval = s.options[s.selectedIndex].text
			labval = labval.substr(0,8);
		}
		if (idval != orgid) {
			hamSaveVariable(deviceID,'ActivityID'+icnt, idval);
			bChanged=true;
		}	
		if (labval != orglab && idval != '') {
			hamSaveVariable(deviceID,'ActivityDesc'+icnt, labval);
			bChanged=true;
		}	
		if (chldval == 1 && idval != '') {
			ncArr.push(idval);
		}	
	}
	var newChilds = ncArr.join();
	if (newChilds != curChilds) { 
		hamSaveVariable(deviceID,'PluginHaveActivityChildren', newChilds);
		bChanged = true; 
	}
	// If we have changes, update buttons.
	if (bChanged) {
		hamSendAction(deviceID, 'UpdateButtons', HAM_SID);
		hamhtmlSetMessage("Changes to the buttons made.<br>Now wait for reload to complete and then refresh your browser page!<br>&nbsp;");
	} else {
		hamhtmlSetMessage("You have not changed any values.<br>No changes to the buttons made.<br>&nbsp;");
	}	
}
function hamUpdateDeviceButtons(deviceID) {
	// Save variable values so we can access them in LUA without user needing to save
	var bChanged = false;
	for (icnt=1; icnt <= HAM_MAXBUTTONS; icnt++) {
		var idval=hamhtmlGetElemVal(deviceID,'Command'+icnt);
		var labval=hamhtmlGetElemVal(deviceID,'CommandDesc'+icnt);
		var prsval=hamhtmlGetElemVal(deviceID,'PrsCommand'+icnt);
		var orgid = hamVarGet(deviceID,'Command'+icnt, HAM_CHSID);
		var orglab = hamVarGet(deviceID,'CommandDesc'+icnt, HAM_CHSID);
		var orgprs = hamVarGet(deviceID,'PrsCommand'+icnt, HAM_CHSID);
		// Check for empty Command descriptions, and default to Command
		if (idval !== '' && labval === '') {
			var s = document.getElementById('hamID_Command'+icnt+deviceID);
			labval = s.options[s.selectedIndex].text
			labval = labval.substr(0,8);
		}
		if (idval != orgid) {
			hamSaveVariable(deviceID,'Command'+icnt, idval, HAM_CHSID);
			bChanged=true;
		}	
		if (labval != orglab) {
			hamSaveVariable(deviceID,'CommandDesc'+icnt, labval, HAM_CHSID);
			bChanged=true;
		}	
		if (prsval != orgprs && idval != '') {
			hamSaveVariable(deviceID,'PrsCommand'+icnt, prsval, HAM_CHSID);
			bChanged=true;
		}	
	}
	// If we have changes, update buttons.
	if (bChanged) {
		hamSendAction(deviceID, 'UpdateDeviceButtons', HAM_CHSID);
		hamhtmlSetMessage("Changes to the buttons made.<br>Now wait for reload to complete and then refresh your browser page!<br>&nbsp;");
	} else {
		hamhtmlSetMessage("You have not changed any values.<br>No changes to the buttons made.<br>&nbsp;");
	}	
}
function hamUpdateDeviceSelections(deviceID) {
	// Get the selection from the pull down
	var bChanged = false;
	var value = [];
	var s = document.getElementById('hamID_PluginHaveChildren'+deviceID);
	for (var i = 0; i < s.options.length; i++) {
		if (s.options[i].selected === true) {
			value.push(s.options[i].value);
		}
	}
	var selIDs = value.join();
	var orgIDs = hamVarGet(deviceID,'PluginHaveChildren');
	if (selIDs != orgIDs) {
		hamSaveVariable(deviceID,'PluginHaveChildren', selIDs);
		bChanged=true;
	}	
	selIDs = hamhtmlGetElemVal(deviceID, 'PluginEmbedChildren');
	orgIDs = hamVarGet(deviceID, 'PluginEmbedChildren');
	if (selIDs != orgIDs) {
		hamSaveVariable(deviceID,'PluginEmbedChildren', selIDs);
	}	
	// If we have changes in child devices, reload.
	if (bChanged) {
		hamhtmlSetMessage("Changes to child devices made.<br>Now wait for reload to complete and then refresh your browser page!<br>&nbsp;");
		hamReload(deviceID);
	} else {
		hamhtmlSetMessage("You have not selected any other devices.<br>No changes made.<br>&nbsp;");
	}
}
function hamhtmlGetElemVal(di,elID) {
	var res;
	try {
		res=document.getElementById('hamID_'+elID+di).value;
	}
	catch (e) {	
		res = '';
	}
	return res;
}
// Standard update for  plug-in pull down variable. We can handle multiple selections.
function hamhtmlGetPulldownSelection(di, vr) {
	var value = [];
	var s = document.getElementById('hamID_'+vr+di);
	for (var i = 0; i < s.options.length; i++) {
		if (s.options[i].selected === true) {
			value.push(s.options[i].value);
		}
	}
	return value.join();
}
function hamhtmlSetMessage(msg) {
	document.getElementById ("ham_msg").innerHTML = msg;
}

// Add a label and pulldown selection
function hamhtmlAddPulldown(di, lb, vr, values, onchange) {
	var extra = '';
	onchange = (onchange === null) ? false : onchange;
	var selVal = hamVarGet(di, vr);
	if (onchange === true) {
		extra ='onChange="hamUpdatePulldown('+di+',\''+vr+'\',this.value)" ';
	}
	var html = '<tr><td>'+lb+'</td><td>'+
		'<select id="hamID_'+vr+di+'" '+extra+'class="styled">';
	for(var i=0;i<values.length;i++){
		html += '<option value="'+values[i].value+'" '+((values[i].value==selVal)?'selected':'')+'>'+values[i].label+'</option>';
	}
	html += '</select></td></tr>';
	return html;
}
function hamUpdatePulldown(di, vr) {
	var value = [];
	var s = document.getElementById('hamID_'+vr+di);
	for (var i = 0; i < s.options.length; i++) {
		if (s.options[i].selected === true) {
			value.push(s.options[i].value);
		}
	}
	hamVarSet(di, vr, value.join());
}

// Add a label and multiple selection
function hamhtmlAddPulldownMultiple(di, lb, vr, values) {
	var selVal = hamVarGet(di, vr);
	var selected = [];
	if (selVal !== '') {
		selected = selVal.split(',');
	}
	var html = '<tr><td>'+lb+'</td><td>'+
		'<select id="hamID_'+vr+di+'" multiple>';
	for(var i=0;i<values.length;i++){
		html+='<option value="'+values[i].value+'" ';
		for (var j=0;j<selected.length;j++) {
			html += ((values[i].value==selected[j])?'selected':'');
		}	
		html +=	'>'+values[i].label+'</option>';
	}
	html += '</select></td></tr>';
	return html;
}

function hamhtmlAddInput(di, lb, si, vr, cb) {
	var onch = (typeof cb != 'undefined') ? ' onchange="ham'+cb+'(\''+di+'\',\''+vr+'\',this.value);" ' : ' ';
	var val = hamVarGet(di,vr);
	var typ = 'type="text"';
	var html = '<tr><td>'+lb+'</td><td><input '+typ+' size="'+si+'" id="hamID_'+vr+di+'" value="'+val+'"'+onch+'></td></tr>';
	return html;
}

// Add label, pulldown, label, input
function hamhtmlAddMapping(di, lb1, vr1, values, lb2, vr2, sid) {
	var selVal = hamVarGet(di, vr1, sid);
	var html = '<tr>'+
		'<td>'+lb1+'</td>'+
		'<td><select id="hamID_'+vr1+di+'">';
	for(var i=0;i<values.length;i++){
		html += '<option value="'+values[i].value+'" '+((values[i].value==selVal)?'selected':'')+'>'+values[i].label+'</option>';
	}
	html += '</select></td>'+
		'<td>'+lb2+'</td>'+
		'<td><input id="hamID_'+vr2+di+'" size="10" type="text" value="'+hamVarGet(di,vr2,sid)+'"></td>';
	// V2.5, for Devices the key-press can be longer then just a click.	
	if (typeof sid != 'undefined') {
		var timeDuration = [{'value':'0','label':'Click'},{'value':'1','label':'1 Sec'},{'value':'2','label':'2 Sec'},{'value':'3','label':'3 Sec'},{'value':'4','label':'4 Sec'},{'value':'5','label':'5 Sec'},{'value':'7','label':'7 Sec'},{'value':'10','label':'10 Sec'},{'value':'15','label':'15 Sec'}];
		var selDur = hamVarGet(di, 'Prs'+vr1, sid);
		html += '<td>Press</td>'+
			'<td>'+
			'<select id="hamID_Prs'+vr1+di+'">';
		for(i=0;i<timeDuration.length;i++){
			html += '<option value="'+timeDuration[i].value+'" '+((''+timeDuration[i].value==selDur)?'selected':'')+'>'+timeDuration[i].label+'</option>';
		}
		html += '</select>'+
			'</td>';
	} else {
		// Activity settings, see if activity ID already in PluginHaveActivityChildren to flag selected
		var noYes = [{'value':'0','label':'No'},{'value':'1','label':'Yes'}];
		var curChild = hamVarGet(di, 'PluginHaveActivityChildren');
		var curVal = 0;
		if (selVal != '') {
			var ccArr = curChild.split(',');
			curVal = (ccArr.includes(selVal)?1:0);
		}	
		html += '<td">Activity Child Device</td>'+
		'<td>'+
		'<select id="hamID_'+vr1+'Child'+di+'">';
		for(i=0;i<noYes.length;i++){
			html += '<option value="'+noYes[i].value+'" '+((''+noYes[i].value==curVal)?'selected':'')+'>'+noYes[i].label+'</option>';
		}
		html += '</select>'+
			'</td>';
	}
	html += '</tr>';
	return html;
}

// Add a Save Settings button
function hamhtmlAddButton(di,cb,cs) {
	html = '<tr><td align="right" colspan="'+cs+'"><input class="btn" type="button" value="Save Changes" onclick="ham'+cb+'(\''+di+'\');"></input></td></tr>';
	return html;
}

function hamReload(deviceID) {
	requestURL = data_request_url + 'id=lu_action';
	requestURL += '&serviceId=urn:micasaverde-com:serviceId:HomeAutomationGateway1&timestamp='+new Date().getTime()+'&action=Reload';
	var xmlHttp = new XMLHttpRequest();
	xmlHttp.open("GET", requestURL, false);
	xmlHttp.send(null);
}

function hamSaveVariable(deviceID, vari, val, sid) {
	if (typeof(sid) == 'undefined') { sid = HAM_SID; }
	var cmd = 'luup.variable_set("'+sid+'","'+vari+'","'+val+'",'+deviceID+')';
	requestURL = data_request_url + 'id=lu_action';
	requestURL += '&serviceId=urn:micasaverde-com:serviceId:HomeAutomationGateway1&timestamp='+new Date().getTime()+'&action=RunLua&Code='+cmd;
	var xmlHttp = new XMLHttpRequest();
	xmlHttp.open("GET", requestURL, false);
	xmlHttp.send(null);
}
function hamSendAction(device, action, sid) {
	var requestURL = data_request_url + 'id=lu_action&DeviceNum=' + device + '&serviceId=' + sid + '&timestamp=' + new Date().getTime() + '&action=' + action;
	var xmlHttp = new XMLHttpRequest();
	xmlHttp.open("GET", requestURL, false);
	xmlHttp.send(null);
}
