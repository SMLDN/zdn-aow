require("util_gui")
require("zdn_form_common")

local Logic = "zdn_logic_vat_pham"

function onFormOpen()
	if nx_execute(Logic, "IsRunning") then
		updateBtnSubmitState(true)
	else
		updateBtnSubmitState(false)
	end
end

function onBtnSubmitClick()
	if not nx_execute(Logic, "IsRunning") then
		nx_execute(Logic, "Start")
		updateBtnSubmitState(true)
	else
		nx_execute(Logic, "Stop")
		updateBtnSubmitState(false)
	end
end

function onBtnSettingClick()
	util_auto_show_hide_form("form_zdn_vat_pham_setting")
end
