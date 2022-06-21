require("util_gui")
require("zdn_form_common")

local Logic = "zdn_logic_task_manager"

function onFormOpen()
    if nx_execute(Logic, "IsRunning") then
		nx_execute("zdn_logic_common_listener", "Subscribe", Logic, "on-task-stop", nx_current(), "onTaskStop")
		updateBtnSubmitState(true)
    else
		updateBtnSubmitState(false)
    end
end

function onBtnSubmitClick()
	if not nx_execute(Logic, "IsRunning") then
		updateBtnSubmitState(true)
		nx_execute("zdn_logic_common_listener", "Subscribe", Logic, "on-task-stop", nx_current(), "onTaskStop")
		nx_execute(Logic, "Start")
	else
		nx_execute(Logic, "Stop")
		updateBtnSubmitState(false)
	end
end

function onBtnSettingClick()
	util_auto_show_hide_form("form_zdn_task_setting")
end

function onTaskStop()
	updateBtnSubmitState(false)
end

function onFormClose()
	nx_execute("zdn_logic_common_listener", "Unsubscribe", Logic, "on-task-stop", nx_current())
end