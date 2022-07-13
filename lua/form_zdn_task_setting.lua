require("util_gui")
require("zdn_lib\\util_functions")
require("zdn_form_common")
require("zdn_define\\task_define")

function onFormOpen()
	local cnt = #TASK_LIST
	Form.cbx_task_list.DropListBox:ClearString()
	for i = 1, cnt do
		Form.cbx_task_list.DropListBox:AddString(Utf8ToWstr(TASK_LIST[i][1]))
	end
	Form.cbx_task_list.DropListBox.SelectIndex = 0
	Form.cbx_task_list.Text = Utf8ToWstr(TASK_LIST[1][1])
	loadConfig()
end

function loadConfig()
	local taskStr = IniReadUserConfig("TroLy", "Task", "")
	if taskStr ~= "" then
		local taskList = util_split_string(nx_string(taskStr), ";")
		for _, task in pairs(taskList) do
			local prop = util_split_string(task, ",")
			addRowToTaskGrid(nx_number(prop[2]), nx_string(prop[1]) == "1" and true or false)
		end
	end
end

function onBtnSaveClick()
	local cnt = Form.task_grid.RowCount - 1
	local taskStr = ""
	for i = 0, cnt do
		local cbtn = Form.task_grid:GetGridControl(i, 0).btn
		local infoNode = Form.task_grid:GetGridControl(i, 8).btn
		if i > 0 then
			taskStr = taskStr .. ";"
		end
		taskStr = taskStr .. (cbtn.Checked and "1" or "0") .. "," .. infoNode.TaskListIndex
	end
	IniWriteUserConfig("TroLy", "Task", taskStr)
end

function onBtnAddTaskClick()
	local i = Form.cbx_task_list.DropListBox.SelectIndex + 1
	addRowToTaskGrid(i, true)
end

function addRowToTaskGrid(i, checked)
	if taskExists(i) then
		ShowText("Tác vụ này đã được thêm từ trước")
		return
	end
	addRowToPositionGridByGridIndex(Form.task_grid.RowCount, i, checked)
end

function addRowToPositionGridByGridIndex(gridIndex, taskListIndex, checked)
	local cbtn = createCheckboxButton(checked, Utf8ToWstr(TASK_LIST[taskListIndex][1]))
	local upBtn = createUpButton()
	local downBtn = createDownButton()
	local settingBtn = createSettingButton(taskListIndex)
	local startTime = createTimeInput()
	local endTime = createTimeInput()
	local delBtn = createDeleteButton(taskListIndex)

	Form.task_grid:BeginUpdate()
	Form.task_grid:InsertRow(gridIndex)
	Form.task_grid:SetGridControl(gridIndex, 0, cbtn)
	Form.task_grid:SetGridControl(gridIndex, 1, upBtn)
	Form.task_grid:SetGridControl(gridIndex, 2, downBtn)
	Form.task_grid:SetGridControl(gridIndex, 3, settingBtn)
	Form.task_grid:SetGridText(gridIndex, 4, getTaskStatus(taskListIndex))
	Form.task_grid:SetGridControl(gridIndex, 5, startTime)
	Form.task_grid:SetGridText(gridIndex, 6, nx_widestr("~"))
	Form.task_grid:SetGridControl(gridIndex, 7, endTime)
	Form.task_grid:SetGridControl(gridIndex, 8, delBtn)
	Form.task_grid:EndUpdate()
end

function createCheckboxButton(checked, txt)
	local gui = nx_value("gui")
	if not nx_is_valid(gui) then
		return 0
	end
	local groupbox = gui:Create("GroupBox")
	groupbox.BackColor = "0,0,0,0"
	groupbox.NoFrame = true
	local btn = gui:Create("CheckButton")
	groupbox:Add(btn)
	groupbox.btn = btn

	btn.Top = 7
	btn.Left = 0
	btn.Checked = checked
	btn.BoxSize = 12
	btn.NormalColor = "255,255,255,255"
	btn.FocusColor = "0,0,0,0"
	btn.PushColor = "0,0,0,0"
	btn.DisableColor = "0,0,0,0"
	btn.PushBlendColor = "255,255,255,255"
	btn.DisableBlendColor = "255,255,255,255"
	btn.Width = 170
	btn.Height = 22
	btn.BackColor = "255,192,192,192"
	btn.ForeColor = "255,255,255,255"
	btn.ShadowColor = "0,0,0,0"
	btn.TabStop = true
	btn.NoFrame = true
	btn.InSound = "MouseOn_20"
	btn.ClickSound = "ok_7"
	btn.Text = txt
	btn.NormalImage = "gui\\common\\checkbutton\\cbtn_out_4.png"
	btn.FocusImage = "gui\\common\\checkbutton\\cbtn_on_4.png"
	btn.CheckedImage = "gui\\common\\checkbutton\\cbtn_down_4.png"
	btn.DrawMode = "ExpandH"
	return groupbox
end

function createDeleteButton(taskListIndex)
	local gui = nx_value("gui")
	if not nx_is_valid(gui) then
		return
	end
	local groupbox = gui:Create("GroupBox")
	groupbox.BackColor = "0,0,0,0"
	groupbox.NoFrame = true
	local btn = gui:Create("Button")
	groupbox:Add(btn)
	groupbox.btn = btn

	btn.NormalImage = "gui\\common\\button\\btn_del_out.png"
	btn.FocusImage = "gui\\common\\button\\btn_del_on.png"
	btn.PushImage = "gui\\common\\button\\btn_del_down.png"
	btn.FocusBlendColor = "255,255,255,255"
	btn.PushBlendColor = "255,255,255,255"
	btn.DisableBlendColor = "255,255,255,255"
	btn.NormalColor = "0,0,0,0"
	btn.FocusColor = "0,0,0,0"
	btn.PushColor = "0,0,0,0"
	btn.DisableColor = "0,0,0,0"
	btn.Left = 5
	btn.Top = 9
	btn.Width = 18
	btn.Height = 18
	btn.BackColor = "255,192,192,192"
	btn.ShadowColor = "0,0,0,0"
	btn.TabStop = "true"
	btn.AutoSize = "true"
	btn.DrawMode = "FitWindow"
	btn.HintText = Utf8ToWstr("Xóa")
	btn.TaskListIndex = taskListIndex
	nx_bind_script(btn, nx_current())
	nx_callback(btn, "on_click", "onBtnDeleteRowClick")
	return groupbox
end

function createSettingButton(taskListIndex)
	local gui = nx_value("gui")
	if not nx_is_valid(gui) then
		return 0
	end
	local groupbox = gui:Create("GroupBox")
	groupbox.BackColor = "0,0,0,0"
	groupbox.NoFrame = true
	local btn = gui:Create("Button")
	groupbox:Add(btn)
	groupbox.btn = btn

	btn.NormalImage = "gui\\common\\button\\btn_set_out.png"
	btn.FocusImage = "gui\\common\\button\\btn_set_on.png"
	btn.PushImage = "gui\\common\\button\\btn_set_down.png"
	btn.FocusBlendColor = "255,255,255,255"
	btn.PushBlendColor = "255,255,255,255"
	btn.DisableBlendColor = "255,255,255,255"
	btn.NormalColor = "0,0,0,0"
	btn.FocusColor = "0,0,0,0"
	btn.PushColor = "0,0,0,0"
	btn.DisableColor = "0,0,0,0"
	btn.Left = 0
	btn.Top = 9
	btn.Width = 18
	btn.Height = 18
	btn.BackColor = "255,192,192,192"
	btn.ShadowColor = "0,0,0,0"
	btn.TabStop = "true"
	btn.AutoSize = "true"
	btn.DrawMode = "FitWindow"
	btn.HintText = Utf8ToWstr("Thiết lập")
	nx_bind_script(btn, nx_current())
	nx_callback(btn, "on_click", "onBtnSettingRowClick")
	return groupbox
end

function createUpButton()
	local gui = nx_value("gui")
	if not nx_is_valid(gui) then
		return 0
	end
	local groupbox = gui:Create("GroupBox")
	groupbox.BackColor = "0,0,0,0"
	groupbox.NoFrame = true
	local btn = gui:Create("Button")
	groupbox:Add(btn)
	groupbox.btn = btn

	btn.NormalImage = "gui\\common\\scrollbar\\button_1\\btn_up_out_3.png"
	btn.FocusImage = "gui\\common\\scrollbar\\button_1\\btn_up_on_3.png"
	btn.PushImage = "gui\\common\\scrollbar\\button_1\\btn_up_down_3.png"
	btn.FocusBlendColor = "255,255,255,255"
	btn.PushBlendColor = "255,255,255,255"
	btn.DisableBlendColor = "255,255,255,255"
	btn.NormalColor = "0,0,0,0"
	btn.FocusColor = "0,0,0,0"
	btn.PushColor = "0,0,0,0"
	btn.DisableColor = "0,0,0,0"
	btn.Left = 3
	btn.Top = 9
	btn.Width = 18
	btn.Height = 18
	btn.BackColor = "255,192,192,192"
	btn.ShadowColor = "0,0,0,0"
	btn.TabStop = "true"
	btn.AutoSize = "true"
	btn.DrawMode = "FitWindow"
	btn.HintText = Utf8ToWstr("Lên trên")
	nx_bind_script(btn, nx_current())
	nx_callback(btn, "on_click", "onBtnUpRowClick")
	return groupbox
end

function createDownButton()
	local gui = nx_value("gui")
	if not nx_is_valid(gui) then
		return 0
	end
	local groupbox = gui:Create("GroupBox")
	groupbox.BackColor = "0,0,0,0"
	groupbox.NoFrame = true
	local btn = gui:Create("Button")
	groupbox:Add(btn)
	groupbox.btn = btn

	btn.NormalImage = "gui\\common\\scrollbar\\button_1\\btn_down_out_3.png"
	btn.FocusImage = "gui\\common\\scrollbar\\button_1\\btn_down_on_3.png"
	btn.PushImage = "gui\\common\\scrollbar\\button_1\\btn_down_down_3.png"
	btn.FocusBlendColor = "255,255,255,255"
	btn.PushBlendColor = "255,255,255,255"
	btn.DisableBlendColor = "255,255,255,255"
	btn.NormalColor = "0,0,0,0"
	btn.FocusColor = "0,0,0,0"
	btn.PushColor = "0,0,0,0"
	btn.DisableColor = "0,0,0,0"
	btn.Left = 0
	btn.Top = 9
	btn.Width = 18
	btn.Height = 18
	btn.BackColor = "255,192,192,192"
	btn.ShadowColor = "0,0,0,0"
	btn.TabStop = "true"
	btn.AutoSize = "true"
	btn.DrawMode = "FitWindow"
	btn.HintText = Utf8ToWstr("Xuống dưới")
	nx_bind_script(btn, nx_current())
	nx_callback(btn, "on_click", "onBtnDownRowClick")
	return groupbox
end

function onBtnDeleteRowClick(btn)
	local cnt = Form.task_grid.RowCount - 1
	for i = 0, cnt do
		local deleteGroupBox = Form.task_grid:GetGridControl(i, 8)
		local deleteBtn = deleteGroupBox.btn
		if nx_id_equal(deleteBtn, btn) then
			Form.task_grid:BeginUpdate()
			Form.task_grid:DeleteRow(i)
			Form.task_grid:EndUpdate()
			return
		end
	end
end

function onBtnSettingRowClick(btn)
	local gridIndex = getGridIndex(3, btn)
	local taskListIndex = Form.task_grid:GetGridControl(gridIndex, 8).btn.TaskListIndex
	local form = TASK_LIST[taskListIndex][3]
	if form ~= nil then
		util_show_form(form, true)
	end
end

function onBtnUpRowClick(btn)
	local gridIndex = getGridIndex(1, btn)
	if gridIndex == 0 then
		return
	end
	local upperTaskListIndex = Form.task_grid:GetGridControl(gridIndex - 1, 8).btn.TaskListIndex
	local upperChecked = Form.task_grid:GetGridControl(gridIndex - 1, 0).btn.Checked
	addRowToPositionGridByGridIndex(gridIndex + 1, upperTaskListIndex, upperChecked)
	Form.task_grid:BeginUpdate()
	Form.task_grid:DeleteRow(gridIndex - 1)
	Form.task_grid:EndUpdate()
end

function onBtnDownRowClick(btn)
	local gridIndex = getGridIndex(2, btn)
	local cnt = Form.task_grid.RowCount - 1
	if gridIndex == cnt then
		return
	end
	local lowerTaskListIndex = Form.task_grid:GetGridControl(gridIndex + 1, 8).btn.TaskListIndex
	local lowerChecked = Form.task_grid:GetGridControl(gridIndex + 1, 0).btn.Checked
	addRowToPositionGridByGridIndex(gridIndex, lowerTaskListIndex, lowerChecked)
	Form.task_grid:BeginUpdate()
	Form.task_grid:DeleteRow(gridIndex + 2)
	Form.task_grid:EndUpdate()
end

function taskExists(index)
	local cnt = Form.task_grid.RowCount - 1
	for i = 0, cnt do
		local control = Form.task_grid:GetGridControl(i, 8)
		if control.btn.TaskListIndex == index then
			return true
		end
	end
	return false
end

function getGridIndex(columnIndex, btn)
	local cnt = Form.task_grid.RowCount - 1
	for i = 0, cnt do
		local ctl = Form.task_grid:GetGridControl(i, columnIndex)
		local b = ctl.btn
		if nx_id_equal(btn, b) then
			return i
		end
	end
end

function getTaskStatus(index)
	local logic = TASK_LIST[index][2]
	if nx_execute(logic, "IsRunning") then
		return Utf8ToWstr("Đang chạy...")
	end
	if nx_execute(logic, "IsTaskDone") then
		return Utf8ToWstr("Đã xong")
	end
	return nx_widestr("-")
end

function onHyperCheckAllClick()
	local cnt = Form.task_grid.RowCount
	for i = 1, cnt do
		local cbtn = Form.task_grid:GetGridControl(i - 1, 0)
		if nx_is_valid(cbtn) then
			local btn = cbtn.btn
			if nx_is_valid(btn) and not btn.Checked then
				btn.Checked = true
			end
		end
	end
end

function onHyperUncheckAllClick()
	local cnt = Form.task_grid.RowCount
	for i = 1, cnt do
		local cbtn = Form.task_grid:GetGridControl(i - 1, 0)
		if nx_is_valid(cbtn) then
			local btn = cbtn.btn
			if nx_is_valid(btn) and btn.Checked then
				btn.Checked = false
			end
		end
	end
end

function createTimeInput()
	local gui = nx_value("gui")
	if not nx_is_valid(gui) then
		return
	end
	local groupbox = gui:Create("GroupBox")
	groupbox.BackColor = "0,0,0,0"
	groupbox.NoFrame = true
	local inputHr = gui:Create("Float_Edit")
	groupbox:Add(inputHr)
	groupbox.input_hour = inputHr

	-- hr
	inputHr.Top = 7
	inputHr.Width = 35
	inputHr.Height = 22
	inputHr.Format = "%.0f"
	inputHr.DragStep = "1.000000"
	inputHr.Max = "24.000000"
	inputHr.OnlyDigit = "true"
	inputHr.ChangedEvent = "true"
	inputHr.TextOffsetX = "2"
	inputHr.Align = "Center"
	inputHr.SelectBackColor = "190,190,190,190"
	inputHr.Caret = "Default"
	inputHr.ForeColor = "255,255,255,255"
	inputHr.ShadowColor = "0,0,0,0"
	inputHr.Font = "font_main"
	inputHr.Cursor = "WIN_IBEAM"
	inputHr.TabStop = "true"
	inputHr.DrawMode = "ExpandH"
	inputHr.BackImage = "gui\\common\\form_line\\ibox_1.png"
	inputHr.Text = nx_widestr("00")

	local inputMnt = gui:Create("Float_Edit")
	groupbox:Add(inputMnt)
	groupbox.input_minute = inputMnt
	-- mnt
	inputMnt.Top = 7
	inputMnt.Left = 40
	inputMnt.Width = 35
	inputMnt.Height = 22
	inputMnt.Format = "%.0f"
	inputMnt.DragStep = "1.000000"
	inputMnt.Max = "24.000000"
	inputMnt.OnlyDigit = "true"
	inputMnt.ChangedEvent = "true"
	inputMnt.TextOffsetX = "2"
	inputMnt.Align = "Center"
	inputMnt.SelectBackColor = "190,190,190,190"
	inputMnt.Caret = "Default"
	inputMnt.ForeColor = "255,255,255,255"
	inputMnt.ShadowColor = "0,0,0,0"
	inputMnt.Font = "font_main"
	inputMnt.Cursor = "WIN_IBEAM"
	inputMnt.TabStop = "true"
	inputMnt.DrawMode = "ExpandH"
	inputMnt.BackImage = "gui\\common\\form_line\\ibox_1.png"
	inputMnt.Text = nx_widestr("00")

	return groupbox
end

