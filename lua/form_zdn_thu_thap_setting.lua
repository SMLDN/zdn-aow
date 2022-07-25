require("zdn_lib\\util_functions")
require("zdn_util")
require("zdn_form_common")
require("zdn_lib_moving")

local SHAPE_DEFINE = {
	["14"] = "Chặt cây",
	["6"] = "Đào khoáng",
	["8"] = "Câu cá"
}

function onBtnAddPositionClick()
	local map = GetCurMap()
	local obj = getTargetObj()
	if not nx_is_valid(obj) then
		return
	end
	local posX, posY, posZ = GetPlayerPosition()
	local shape = obj:QueryProp("CursorShape")
	local configId = obj:QueryProp("ConfigID")
	if isExists(configId, map, posX, posY, posZ) then
		ShowText("Đối tượng đã được thêm từ trước")
		return
	end
	addRowToPositionGridByGridIndex(Form.position_grid.RowCount, configId, shape, map, posX, posY, posZ, true)
end

function isExists(configId, map, posX, posY, posZ)
	local cnt = Form.position_grid.RowCount - 1

	for i = 0, cnt do
		local btn = Form.position_grid:GetGridControl(i, 0).btn
		if
			nx_string(btn.ZdnConfigId) == nx_string(configId) and nx_string(btn.ZdnMap) == nx_string(map) and
				math.floor(nx_number(btn.ZdnPosX)) == math.floor(posX) and
				math.floor(nx_number(btn.ZdnPosY)) == math.floor(posY) and
				math.floor(nx_number(btn.ZdnPosZ)) == math.floor(posZ)
		 then
			return true
		end
	end
	return false
end

function onFormOpen()
	local posStr = IniReadUserConfig("ThuThap", "P", "")
	if posStr ~= "" then
		local posList = util_split_string(nx_string(posStr), ";")
		for _, pos in pairs(posList) do
			local prop = util_split_string(pos, ",")
			local gridIndex = Form.position_grid.RowCount
			addRowToPositionGridByGridIndex(
				gridIndex,
				prop[2],
				prop[3],
				prop[4],
				prop[5],
				prop[6],
				prop[7],
				nx_string(prop[1]) == "1" and true or false
			)
		end
	end
end

function onBtnSaveClick()
	local cnt = Form.position_grid.RowCount - 1
	local posStr = ""
	for i = 0, cnt do
		local btn = Form.position_grid:GetGridControl(i, 0).btn
		if i > 0 then
			posStr = posStr .. ";"
		end
		posStr = posStr .. (btn.Checked and "1" or "0")
		posStr =
			posStr ..
			"," ..
				btn.ZdnConfigId ..
					"," .. btn.ZdnShape .. "," .. btn.ZdnMap .. "," .. btn.ZdnPosX .. "," .. btn.ZdnPosY .. "," .. btn.ZdnPosZ
	end
	IniWriteUserConfig("ThuThap", "P", posStr)
end

function addRowToPositionGridByGridIndex(gridIndex, configId, shape, map, posX, posY, posZ, checked)
	local cbtn = createCheckboxButton(checked, configId, shape, map, posX, posY, posZ)
	local upBtn = createUpButton()
	local downBtn = createDownButton()
	local delBtn = createDeleteButton()
	local shapeLbl = nx_widestr("-")
	if SHAPE_DEFINE[nx_string(shape)] ~= nil then
		shapeLbl = Utf8ToWstr(SHAPE_DEFINE[nx_string(shape)])
	end

	Form.position_grid:BeginUpdate()
	Form.position_grid:InsertRow(gridIndex)
	Form.position_grid:SetGridControl(gridIndex, 0, cbtn)
	Form.position_grid:SetGridText(
		gridIndex,
		1,
		util_text(map) .. nx_widestr(" ") .. nx_widestr(math.floor(posX) .. "," .. math.floor(posZ))
	)
	Form.position_grid:SetGridText(gridIndex, 2, shapeLbl)
	Form.position_grid:SetGridControl(gridIndex, 3, upBtn)
	Form.position_grid:SetGridControl(gridIndex, 4, downBtn)
	Form.position_grid:SetGridControl(gridIndex, 5, delBtn)
	Form.position_grid:EndUpdate()
end

function createCheckboxButton(checked, configId, shape, map, posX, posY, posZ)
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
	btn.Width = 145
	btn.Height = 22
	btn.BackColor = "255,192,192,192"
	btn.ForeColor = "255,255,255,255"
	btn.ShadowColor = "0,0,0,0"
	btn.TabStop = true
	btn.NoFrame = true
	btn.InSound = "MouseOn_20"
	btn.ClickSound = "ok_7"
	btn.Text = util_text(configId)
	btn.NormalImage = "gui\\common\\checkbutton\\cbtn_out_4.png"
	btn.FocusImage = "gui\\common\\checkbutton\\cbtn_on_4.png"
	btn.CheckedImage = "gui\\common\\checkbutton\\cbtn_down_4.png"
	btn.DrawMode = "ExpandH"

	btn.ZdnConfigId = configId
	btn.ZdnShape = shape
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
		local deleteGroupBox = Form.position_grid:GetGridControl(i, 5)
		local deleteBtn = deleteGroupBox.btn
		if nx_id_equal(deleteBtn, btn) then
			Form.position_grid:BeginUpdate()
			Form.position_grid:DeleteRow(i)
			Form.position_grid:EndUpdate()
			return
		end
	end
end

function getTargetObj()
	local client = nx_value("game_client")
	if not nx_is_valid(client) then
		return
	end
	local player = client:GetPlayer()
	if not nx_is_valid(player) then
		return
	end
	return client:GetSceneObj(nx_string(player:QueryProp("LastObject")))
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
	local gridIndex = getGridIndex(3, btn)
	if gridIndex == 0 then
		return
	end
	local upperBtn = Form.position_grid:GetGridControl(gridIndex - 1, 0).btn
	addRowToPositionGridByGridIndex(
		gridIndex + 1,
		upperBtn.ZdnConfigId,
		upperBtn.ZdnShape,
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
	local gridIndex = getGridIndex(4, btn)
	local cnt = Form.position_grid.RowCount - 1
	if gridIndex == cnt then
		return
	end
	local lowerBtn = Form.position_grid:GetGridControl(gridIndex + 1, 0).btn
	addRowToPositionGridByGridIndex(
		gridIndex,
		lowerBtn.ZdnConfigId,
		lowerBtn.ZdnShape,
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

function getVisualObj(obj)
	if not nx_is_valid(obj) then
		return
	end
	return nx_value("game_visual"):GetSceneObj(obj.Ident)
end
