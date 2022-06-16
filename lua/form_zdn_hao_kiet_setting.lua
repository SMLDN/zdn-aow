require("zdn_lib\\util_functions")
require("zdn_util")
require("zdn_form_common")
require("zdn_lib_moving")

local Radius = 50

function onBtnAddPositionClick()
	local map = GetCurMap()
	local posX, posY, posZ = GetPlayerPosition()
	addRowToPositionGrid(map, posX, posY, posZ, true)
end

function onFormOpen()
	local posStr = IniReadUserConfig("HaoKiet", "Position", "")
	if posStr ~= "" then
		local posList = util_split_string(nx_string(posStr), ";")
		for _, pos in pairs(posList) do
			local prop = util_split_string(pos, ",")
			addRowToPositionGrid(prop[1], prop[2], prop[3], prop[4], nx_string(prop[5]) == "1" and true or false)
		end
	end
end

function onBtnSaveClick()
	local cnt = Form.position_grid.RowCount - 1
	local posStr = ""
	for i = 0, cnt do
		local infoNode = Form.position_grid:GetGridControl(i, 4)
		local cbtn = Form.position_grid:GetGridControl(i, 0).cbtn
		if i > 0 then
			posStr = posStr .. ";"
		end
		posStr = posStr .. infoNode.Map .. "," .. infoNode.PosX .. "," .. infoNode.PosY .. "," .. infoNode.PosZ
		posStr = posStr .. "," .. (cbtn.Checked and "1" or "0")
	end
	IniWriteUserConfig("HaoKiet", "Position", posStr)
end

function addRowToPositionGrid(map, posX, posY, posZ, checked)
	local index = Form.position_grid.RowCount
	local cbtn = createCheckboxButton(index, checked)
	local delBtn = createDeleteButton(index)

	Form.position_grid:BeginUpdate()
	Form.position_grid:InsertRow(-1)
	Form.position_grid:SetGridControl(index, 0, cbtn)
	Form.position_grid:SetGridText(index, 1, util_text(map))
	Form.position_grid:SetGridText(index, 2, nx_widestr(math.floor(posX) .. "," .. math.floor(posZ)))
	Form.position_grid:SetGridText(index, 3, nx_widestr(Radius))
	Form.position_grid:SetGridControl(index, 4, delBtn)
	Form.position_grid:EndUpdate()

	delBtn.Map = map
	delBtn.PosX = posX
	delBtn.PosY = posY
	delBtn.PosZ = posZ
end

function createCheckboxButton(index, checked)
	local gui = nx_value("gui")
	if not nx_is_valid(gui) then
		return 0
	end
	local groupbox = gui:Create("GroupBox")
	groupbox.BackColor = "0,0,0,0"
	groupbox.NoFrame = true
	local cbtn = gui:Create("CheckButton")
	groupbox:Add(cbtn)
	groupbox.cbtn = cbtn

	cbtn.Top = 8
	cbtn.Left = 0
	cbtn.Checked = checked
	cbtn.BoxSize = 12
	cbtn.NormalImage = "gui\\common\\checkbutton\\cbtn_2_out.png"
	cbtn.FocusImage = "gui\\common\\checkbutton\\cbtn_2_on.png"
	cbtn.CheckedImage = "gui\\common\\checkbutton\\cbtn_2_down.png"
	cbtn.DisableImage = "gui\\common\\checkbutton\\cbtn_2_forbid.png"
	cbtn.NormalColor = "255,255,255,255"
	cbtn.FocusColor = "255,255,255,255"
	cbtn.PushColor = "255,255,255,255"
	cbtn.DisableColor = "0,0,0,0"
	cbtn.PushBlendColor = "255,255,255,255"
	cbtn.DisableBlendColor = "255,255,255,255"
	cbtn.Width = 16
	cbtn.Height = 16
	cbtn.BackColor = "255,192,192,192"
	cbtn.ShadowColor = "0,0,0,0"
	cbtn.TabStop = true
	cbtn.AutoSize = true
	cbtn.InSound = "MouseOn_20"
	cbtn.ClickSound = "ok_7"
	return groupbox
end

function createDeleteButton(index)
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
