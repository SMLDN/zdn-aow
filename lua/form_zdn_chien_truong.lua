require("zdn_form_common")
require("zdn_util")

local Logic = "zdn_logic_chien_truong"

function onFormOpen(form)
	loadConfig()
	if nx_execute(Logic, "IsRunning") then
		nx_execute("zdn_logic_common_listener", "Subscribe", Logic, "on-task-stop", nx_current(), "onTaskStop")
		Form.btn_submit.Text = nx_widestr("Stop")
	else
		Form.btn_submit.Text = nx_widestr("Start")
	end
end

function onBtnSubmitClick()
	if not nx_execute(Logic, "IsRunning") then
		saveConfig()
		Form.btn_submit.Text = nx_widestr("Stop")
		nx_execute("zdn_logic_common_listener", "Subscribe", Logic, "on-task-stop", nx_current(), "onTaskStop")
		nx_execute(Logic, "Start")
	else
		nx_execute(Logic, "Stop")
		Form.btn_submit.Text = nx_widestr("Start")
	end
end

function onTaskStop()
	Form.btn_submit.Text = nx_widestr("Start")
end

function onFormClose()
	nx_execute("zdn_logic_common_listener", "Unsubscribe", Logic, "on-task-stop", nx_current())
end

function saveConfig()
	IniWriteUserConfig("ChienTruong", "Mode", getMode())
	IniWriteUserConfig("ChienTruong", "ProcessMailFlg", Form.cbtn_get_mail.Checked and "1" or "0")
	IniWriteUserConfig("ChienTruong", "MaxTurn", Form.input_max_turn.Text)
end

function getMode()
	if not nx_is_valid(Form) then
		return 0
	end
	return Form.rbtn_manual.Checked and 1 or 0
end

function loadConfig()
	local mode = nx_number(IniReadUserConfig("ChienTruong", "Mode", 0))
	local processMailFlg = nx_string(IniReadUserConfig("ChienTruong", "ProcessMailFlg", "1"))
	local maxTurn = IniReadUserConfig("ChienTruong", "MaxTurn", "20")
	Console(maxTurn)

	if mode == 1 then
		Form.rbtn_auto.Checked = false
		Form.rbtn_manual.Checked = true
	end

	if processMailFlg == "0" then
		Form.cbtn_get_mail.Checked = false
	end

	Form.input_max_turn.Text = maxTurn
end
