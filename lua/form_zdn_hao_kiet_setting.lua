require("util_functions")
require("zdn_form_common")
require("zdn_lib_moving")

local Radius = 50

function onBtnAddPositionClick()
	local map = GetCurMap()
	local posX, posY, posZ = GetPlayerPosition()
	addRowToPositionGridByGridIndex(Form.position_grid.RowCount, map, posX, posY, posZ, true)
end

function onFormOpen()
	local posStr = IniReadUserConfig("HaoKiet", "Position", "")
	if posStr ~= "" then
		local posList = util_split_string(nx_string(posStr), ";")
		for _, pos in pairs(posList) do
			local prop = util_split_string(pos, ",")
			local gridIndex = Form.position_grid.RowCount
			addRowToPositionGridByGridIndex(
				gridIndex,
				prop[1],
				prop[2],
				prop[3],
				prop[4],
				nx_string(prop[5]) == "1" and true or false
			)
		end
	end
end

function onBtnSaveClick()
	local cnt = Form.position_grid.RowCount - 1
	local posStr = ""
	for i = 0, cnt do
		-- local infoNode = Form.position_grid:GetGridControl(i, 4)
		local cbtn = Form.position_grid:GetGridControl(i, 0).btn
		if i > 0 then
			posStr = posStr .. ";"
		end
		posStr = posStr .. cbtn.ZdnMap .. "," .. cbtn.ZdnPosX .. "," .. cbtn.ZdnPosY .. "," .. cbtn.ZdnPosZ
		posStr = posStr .. "," .. (cbtn.Checked and "1" or "0")
	end
	IniWriteUserConfig("HaoKiet", "Position", posStr)
end

function addRowToPositionGridByGridIndex(gridIndex, map, posX, posY, posZ, checked)
	local cbtn = createCheckboxButton(checked, map, posX, posY, posZ)
	local delBtn = createDeleteButton()
	local upBtn = createUpButton()
	local downBtn = createDownButton()

	Form.position_grid:BeginUpdate()
	Form.position_grid:InsertRow(gridIndex)
	Form.position_grid:SetGridControl(gridIndex, 0, cbtn)
	Form.position_grid:SetGridText(gridIndex, 1, nx_widestr(math.floor(posX) .. "," .. math.floor(posZ)))
	Form.position_grid:SetGridControl(gridIndex, 2, upBtn)
	Form.position_grid:SetGridControl(gridIndex, 3, downBtn)
	Form.position_grid:SetGridControl(gridIndex, 4, delBtn)
	Form.position_grid:EndUpdate()
end

function createCheckboxButton(checked, map, posX, posY, posZ)
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

	btn.Top = 4
	btn.Left = 0
	btn.Checked = checked
	btn.BoxSize = 12
	btn.NormalColor = "255,255,255,255"
	btn.FocusColor = "0,0,0,0"
	btn.PushColor = "0,0,0,0"
	btn.DisableColor = "0,0,0,0"
	btn.PushBlendColor = "255,255,255,255"
	btn.DisableBlendColor = "255,255,255,255"
	btn.Width = 150
	btn.Height = 22
	btn.BackColor = "255,192,192,192"
	btn.ForeColor = "255,255,255,255"
	btn.ShadowColor = "0,0,0,0"
	btn.TabStop = true
	btn.NoFrame = true
	btn.InSound = "MouseOn_20"
	btn.ClickSound = "ok_7"
	btn.Text = util_text(map)
	btn.NormalImage = "gui\\common\\checkbutton\\cbtn_out_4.png"
	btn.FocusImage = "gui\\common\\checkbutton\\cbtn_on_4.png"
	btn.CheckedImage = "gui\\common\\checkbutton\\cbtn_down_4.png"
	btn.DrawMode = "ExpandH"

	btn.ZdnMap = map
	btn.ZdnPosX = posX
	btn.ZdnPosY = posY
	btn.ZdnPosZ = posZ
	return groupbox
end

function createDeleteButton()
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
	btn.Left = 11
	btn.Top = 6
	btn.Width = 18
	btn.Height = 18
	btn.BackColor = "255,192,192,192"
	btn.ShadowColor = "0,0,0,0"
	btn.TabStop = "true"
	btn.AutoSize = "true"
	btn.DrawMode = "FitWindow"
	btn.HintText = Utf8ToWstr("Xóa")
	nx_bind_script(btn, nx_current())
	nx_callback(btn, "on_click", "onBtnDeleteRowClick")
	return groupbox
end

function onBtnDeleteRowClick(btn)
	local cnt = Form.position_grid.RowCount - 1

	for i = 0, cnt do
		local deleteGroupBox = Form.position_grid:GetGridControl(i, 4)
		local deleteBtn = deleteGroupBox.btn
		if nx_id_equal(deleteBtn, btn) then
			Form.position_grid:BeginUpdate()
			Form.position_grid:DeleteRow(i)
			Form.position_grid:EndUpdate()
			return
		end
	end
end

function onHyperCheckAllClick()
	local cnt = Form.position_grid.RowCount
	for i = 1, cnt do
		local cbtn = Form.position_grid:GetGridControl(i - 1, 0)
		if nx_is_valid(cbtn) then
			local btn = cbtn.btn
			if nx_is_valid(btn) and not btn.Checked then
				btn.Checked = true
			end
		end
	end
end

function onHyperUncheckAllClick()
	local cnt = Form.position_grid.RowCount
	for i = 1, cnt do
		local cbtn = Form.position_grid:GetGridControl(i - 1, 0)
		if nx_is_valid(cbtn) then
			local btn = cbtn.btn
			if nx_is_valid(btn) and btn.Checked then
				btn.Checked = false
			end
		end
	end
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
	btn.Left = 0
	btn.Top = 5
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
	btn.Top = 5
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

function onBtnUpRowClick(btn)
	local gridIndex = getGridIndex(2, btn)
	if gridIndex == 0 then
		return
	end
	local upperBtn = Form.position_grid:GetGridControl(gridIndex - 1, 0).btn
	addRowToPositionGridByGridIndex(
		gridIndex + 1,
		upperBtn.ZdnMap,
		upperBtn.ZdnPosX,
		upperBtn.ZdnPosY,
		upperBtn.ZdnPosZ,
		upperBtn.Checked
	)
	Form.position_grid:BeginUpdate()
	Form.position_grid:DeleteRow(gridIndex - 1)
	Form.position_grid:EndUpdate()
end

function onBtnDownRowClick(btn)
	local gridIndex = getGridIndex(3, btn)
	local cnt = Form.position_grid.RowCount - 1
	if gridIndex == cnt then
		return
	end
	local lowerBtn = Form.position_grid:GetGridControl(gridIndex + 1, 0).btn
	addRowToPositionGridByGridIndex(
		gridIndex,
		lowerBtn.ZdnMap,
		lowerBtn.ZdnPosX,
		lowerBtn.ZdnPosY,
		lowerBtn.ZdnPosZ,
		lowerBtn.Checked
	)
	Form.position_grid:BeginUpdate()
	Form.position_grid:DeleteRow(gridIndex + 2)
	Form.position_grid:EndUpdate()
end

function getGridIndex(columnIndex, btn)
	local cnt = Form.position_grid.RowCount - 1
	for i = 0, cnt do
		local ctl = Form.position_grid:GetGridControl(i, columnIndex)
		local b = ctl.btn
		if nx_id_equal(btn, b) then
			return i
		end
	end
end
