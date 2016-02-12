//# sourceURL=J_ALTUI_harmony.js
"use strict";

// harmony Hub Control UI for UI7
// Written by R.Boer. 
// V2.5 22 September 2015
//
// V2.5 Changes:
//		Added buttons on the UI

var ALTUI_HarmonyDisplays = ( function( window, undefined ) {  
	
	// Constants. Keep in sync with LUA code.
	var HAM_SID = 'urn:rboer-com:serviceId:Harmony1';
	var HAM_CHSID = 'urn:rboer-com:serviceId:HarmonyDevice1';
	var HAM_SWSID = "urn:upnp-org:serviceId:SwitchPower1";
	var HAM_MAXBUTTONS = 25;

	//---------------------------------------------------------
	// PRIVATE functions
	//---------------------------------------------------------
	
	// return the html string inside the .panel-body of the .altui-device#id panel
	function _drawHarmony(device) {
		var html = "";
		try {
			var activity  = parseInt(MultiBox.getStatus(device, HAM_SID, 'CurrentActivityID')); 
			var actBtns = [];
			for (var i=1; i<=HAM_MAXBUTTONS; i++) {
				var actID = parseInt(MultiBox.getStatus(device, HAM_SID, 'ActivityID'+i));
				var actDesc = MultiBox.getStatus(device, HAM_SID, 'ActivityDesc'+i);
				if (actID !== '' && actDesc !== '' && actID !== null && actDesc !== null) {
					actBtns.push({'value':actID,'label':actDesc});
				}
			}	
			if (actBtns.length === 0) {
				html += "<span>No activities defined yet.</span>";
			}	
			else {	if (actBtns.length <= 6) {
				var btnid = 0;
				var colCls = 'col-xs-4';
				var colMax = 3;
				if (actBtns.length <= 2) {
					colCls = 'col-xs-12';
					colMax = 1;
				} else if (actBtns.length <= 4) {
					colCls = 'col-xs-6';
					colMax = 2;
				}
				html += "<div class='altui-multiswitch-container pull-right' style='left:70px;'>";
				for (var line=0; line<2 ; line++) {
					html += "<div class='row'>";
					for (var col=0; col<colMax; col++) {
						if (actBtns[btnid] !== undefined) {
							html += "<div class='{0}' style='padding-left:3px; padding-right:3px;'>".format(colCls);
							html+= "<button id='{0}' type='button' class='altui-harmony-act-{3} btn btn-default btn-xs {2}' style='overflow:hidden; text-overflow:ellipsis; width:100%'>{1}</button>".format(actBtns[btnid].value, actBtns[btnid].label,(actBtns[btnid].value==activity) ? 'btn-info' : '',device.altuiid);
							html += "</div>";
							btnid ++;
						}	
					}
					html += "</div>";
				}
				html += "</div>";
				html += "<script type='text/javascript'>";
				html += " $('button.altui-harmony-act-{0}').on('click', function() {".format(device.altuiid);
				html += " var btnCmd = $(this).prop('id'); ";
				html += " var action = 'StartActivity'; ";
				html += " var params = {}; params['newActivityID']=btnCmd; ";
				html += " MultiBox.runActionByAltuiID('{0}', '{1}', action, params);".format(device.altuiid, HAM_SID);
				html += "});";
				html += "</script>";
			} else {
				var status = parseInt(MultiBox.getStatus(device, HAM_SWSID, 'Status')); 
				html += ALTUI_PluginDisplays.createOnOffButton(status,"altui-onoffbtn-"+device.altuiid, _T("OFF,ON") , "pull-right");
				for (i=0; i<actBtns.length; i++) {
					if (actBtns[i].value === activity) {
						html += "<div>Activity : "+actBtns[i].label+"</div>";
						break;
					}	
				}
				html += "<div class='altui-multiswitch-container pull-right' style='left:70px;'>";
				html += "<div id='altui-harmony-act-group-{0}' class='btn-group'>".format(device.altuiid);
				html += "<button aria-expanded='false' data-toggle='dropdown' type='button' class='btn btn-default btn-xs dropdown-toggle'>";
				html += "Select Activity <span class='caret'></span></button>";
				html += "<ul role='menu' class='dropdown-menu'>";
				for (i=0; i<actBtns.length; i++) {
					html += "<li><a href='#' class='' id='{0}'>{1}</a></li>".format(actBtns[i].value, actBtns[i].label);
				}
				html += "</ul></div>";
				html += "</div>";
				html += "<script type='text/javascript'>";
				html += " $('#altui-harmony-act-group-{0} a').click( function() {".format(device.altuiid);
				html += " var body = $('html, body');"
				html += " var scrPos = body.scrollTop();";
				html += " var btnCmd = $(this).prop('id'); ";
				html += " var action = 'StartActivity'; ";
				html += " var params = {}; params['newActivityID']=btnCmd; ";
				html += " MultiBox.runActionByAltuiID('{0}', '{1}', action, params);".format(device.altuiid, HAM_SID);
				html += " body.animate({scrollTop:scrPos}, '1000', 'swing'); ";
				html += "});";
				html += " $('div#altui-onoffbtn-{0}').on('click touchend', function() { ALTUI_PluginDisplays.toggleOnOffButton('{0}','div#altui-onoffbtn-{0}'); } );".format(device.altuiid);
				html += "</script>";
			}
			}
		} catch (e) {
			html += "<span>Error, sorry</span>";
		}
		return html;
	}
	
	
	// return the html string inside the .panel-body of the .altui-device#id panel
	function _drawHarmonyDevice(device) {
		var html = "";
		try {
			var actBtns = [];
			html += "<div class='altui-multiswitch-container pull-right' style='left:70px;'>";
			for (var i=1; i<=HAM_MAXBUTTONS; i++) {
				var cmd = MultiBox.getStatus(device, HAM_CHSID,'Command'+i);
				var cmdDesc = MultiBox.getStatus(device, HAM_CHSID,'CommandDesc'+i);
				if (cmd !== '' && cmdDesc !== '' && cmd !== null && cmdDesc !== null) {
					actBtns.push({'value':cmd,'label':cmdDesc});
				}
			}
			if (actBtns.length === 0) {
				html += "<span>No commands defined yet.</span>";
			}	
			else { if (actBtns.length <= 6) {
				var btnid = 0;
				var colCls = 'col-xs-4';
				var colMax = 3;
				if (actBtns.length <= 2) {
					colCls = 'col-xs-12';
					colMax = 1;
				} else if (actBtns.length <= 4) {
					colCls = 'col-xs-6';
					colMax = 2;
				}
				for (var line=0; line<2 ; line++) {
					html += "<div class='row'>";
					for (var col=0; col<colMax; col++) {
						if (actBtns[btnid] !== undefined) {
							html += "<div class='{0}' style='padding-left:3px; padding-right:3px;'>".format(colCls);
							html+= "<button id='{0}' type='button' class='altui-harmonydevice-cmd-{2} btn btn-default btn-xs' style='overflow:hidden; text-overflow:ellipsis; width:100%'>{1}</button>".format(actBtns[btnid].value, actBtns[btnid].label, device.altuiid);
							html += "</div>";
							btnid ++;
						}	
					}
					html += "</div>";
				}
				html += "</div>";
				html += "<script type='text/javascript'>";
				html += " $('button.altui-harmonydevice-cmd-{0}').on('click', function() {".format(device.altuiid);
				html += " var btnCmd = $(this).prop('id'); ";
				html += " var action = 'SendDeviceCommand'; ";
				html += " var params = {}; params['Command']=btnCmd; ";
				html += " MultiBox.runActionByAltuiID('{0}', '{1}', action, params);".format(device.altuiid, HAM_CHSID);
				html += "});";
				html += "</script>";
			} else {
				html += "<div id='altui-harmonydevice-cmd-group-{0}' class='btn-group'>".format(device.altuiid);
				html += "<button aria-expanded='false' data-toggle='dropdown' type='button' class='btn btn-default btn-xs dropdown-toggle'>";
				html += "Select Command <span class='caret'></span></button>";
				html += "<ul role='menu' class='dropdown-menu'>";
				for (var i=0; i<actBtns.length; i++) {
					html += "<li><a href='#' class='' id='{0}'>{1}</a></li>".format(actBtns[i].value, actBtns[i].label);
				}
				html += "</ul></div>";
				html += "</div>";
				html += "<script type='text/javascript'>";
				html += " $('#altui-harmonydevice-cmd-group-{0} a').click( function() {".format(device.altuiid);
				html += " var body = $('html, body');"
				html += " var scrPos = body.scrollTop();";
				html += " var btnCmd = $(this).prop('id'); ";
				html += " var action = 'SendDeviceCommand'; ";
				html += " var params = {}; params['Command']=btnCmd; ";
				html += " MultiBox.runActionByAltuiID('{0}', '{1}', action, params);".format(device.altuiid, HAM_CHSID);
				html += " body.animate({scrollTop:scrPos}, '1000', 'swing'); ";
				html += "});";
				html += "</script>";
			}
			}
		} catch (e) {
			html += "<span>Error, sorry</span>";
		}
		return html;
	}
	
  // explicitly return public methods when this object is instantiated
  return {
	//---------------------------------------------------------
	// PUBLIC  functions
	//---------------------------------------------------------
	drawHarmony          : _drawHarmony,
	drawHarmonyDevice    : _drawHarmonyDevice
  };
})( window );
	