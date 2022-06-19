require("zdn_form_common")

local Logic = "zdn_logic_thich_quan"

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

function onTaskStop()
	updateBtnSubmitState(false)
end

function onFormClose()
	nx_execute("zdn_logic_common_listener", "Unsubscribe", Logic, "on-task-stop", nx_current())
end

function updateBtnSubmitState(isRunning)
	if isRunning then
		Form.btn_submit.Text = Utf8ToWstr("Dừng")
				Form.btn_submit.ForeColor="255,220,20,60"
		-- Form.btn_submit.ForeColor = "255,178,34,34"
	else
		Form.btn_submit.Text = Utf8ToWstr("Chạy")
		Form.btn_submit.ForeColor = "255,255,255,255"
	end
end
