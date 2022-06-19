require("zdn_form_common")

local ZdnText = nil
local Logic = "zdn_logic_escort"

function onFormOpen()
	Form.cbx_biao_type.DropListBox:ClearString()
	for i = 1, 15 do
		Form.cbx_biao_type.DropListBox:AddString(ZdnText["escort_name_" .. nx_string(i)])
	end
	local xeTieuIdx = nx_number(IniReadUserConfig("Escort", "type", 1))
	if nx_int(xeTieuIdx) <= nx_int(0) then
		xeTieuIdx = 1
	end
	Form.cbx_biao_type.DropListBox.SelectIndex = xeTieuIdx - 1
	Form.cbx_biao_type.Text = ZdnText["escort_name_" .. nx_string(xeTieuIdx)]
	local maxTurn = nx_number(IniReadUserConfig("Escort", "max_turn", 5))
	if 150 < maxTurn or maxTurn < 1 then
		maxTurn = 5
	end
	Form.max_turn.Text = nx_widestr(maxTurn)
	updateView()
end

function onFormInit()
	ZdnText = IniReadZdnTextSection(nx_current())
end

function onBtnSubmitClick()
	if not nx_execute(Logic, "IsRunning") then
		saveFormData()
		if nx_execute(Logic, "GetCompleteTimes") >= nx_number(IniReadUserConfig("Escort", "max_turn", 5)) then
			return
		end
		nx_execute(Logic, "Start")
		nx_execute("Listener", "addListen", nx_current(), "19561", "updateView", -1)
	else
		nx_execute(Logic, "Stop")
		nx_execute("Listener", "removeListen", nx_current(), "19561", "updateView")
	end
	updateView()
end

function saveFormData()
	IniWriteUserConfig("Escort", "type", Form.cbx_biao_type.DropListBox.SelectIndex + 1)
	IniWriteUserConfig("Escort", "max_turn", Form.max_turn.Text)
end

function updateView()
	if not nx_is_valid(Form) or not Form.Visible then
		return
	end
	local times = nx_execute(Logic, "GetCompleteTimes")
	Form.lbl_times.Text = nx_widestr(times)
	if nx_execute(Logic, "IsRunning") and times < nx_number(Form.max_turn.Text) then
		Form.btn_submit.Text = nx_widestr("Stop")
	else
		Form.btn_submit.Text = nx_widestr("Start")
	end
end

function onTaskStop()
	updateView()
end
