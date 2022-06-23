require("zdn_form_common")

local Logic = "zdn_logic_thien_the"

function onFormOpen()
	loadConfig()
	if nx_execute(Logic, "IsRunning") then
		nx_execute("zdn_logic_common_listener", "Subscribe", Logic, "on-task-stop", nx_current(), "onTaskStop")
		updateBtnSubmitState(true)
	else
		updateBtnSubmitState(false)
	end
end

function onBtnSubmitClick()
	if not nx_execute(Logic, "IsRunning") then
		saveConfig()
		updateBtnSubmitState(true)
		nx_execute("zdn_logic_common_listener", "Subscribe", Logic, "on-task-stop", nx_current(), "onTaskStop")
		nx_execute(Logic, "Start")
	else
		nx_execute(Logic, "Stop")
		updateBtnSubmitState(false)
	end
end

function onTaskStop()
	updateBtnSubmitState(false)
end

function onFormClose()
	nx_execute("zdn_logic_common_listener", "Unsubscribe", Logic, "on-task-stop", nx_current())
end

function saveConfig()
	local flg = Form.instant_leave_cbtn.Checked
	IniWriteUserConfig("ThienThe", "InstantLeave", flg and "1" or "0")
end

function loadConfig()
	local str = nx_string(IniReadUserConfig("ThienThe", "InstantLeave", "0"))
	Form.instant_leave_cbtn.Checked = str == "1" and true or false
end
