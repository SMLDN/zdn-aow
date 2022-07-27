require("zdn_form_common")
require("util_functions")

local Logic = "zdn_logic_tdc"

function onFormOpen()
	updateView()
	nx_execute("zdn_logic_common_listener", "Subscribe", Logic, "on-done-turn", nx_current(), "updateView")
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
	nx_execute("zdn_logic_common_listener", "Unsubscribe", Logic, "on-done-turn", nx_current())
end

function saveConfig()
	local turn = nx_number(Form.max_turn.Text)
	if turn < 0 then
		turn = 1
	elseif turn > 99 then
		turn = 99
	end
	IniWriteUserConfig("TDC", "MaxTurn", turn)
end

function updateView()
	local str = nx_string(IniReadUserConfig("TDC", "FinishTurn", "0,0"))
	local prop = util_split_string(str, ",")
	local cT = nx_execute("zdn_logic_base", "GetCurrentWeekStartTimestamp")
	local t = nx_number(prop[1])
	local turn = 0
	if t == cT then
		turn = nx_number(prop[2])
	end
	Form.lbl_turn.Text = nx_widestr(turn) .. nx_widestr("/")
	Form.max_turn.Text = IniReadUserConfig("TDC", "MaxTurn", nx_widestr("1"))
end
