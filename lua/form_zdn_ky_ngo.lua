require("zdn_lib\\util_functions")
require("zdn_form_common")

local KyNgoData = {}
local ChangeList = {}

function onFormOpen()
	local gui = nx_value("gui")
	Form.Left = (gui.Width - Form.Width) / 2
	loadData()
	loadConfig()
end

function loadData()
	if #KyNgoData == 0 then
		KyNgoData = IniLoadAllData(nx_resource_path() .. "zdn\\data\\kyngo.ini")
	end
	ChangeList = {}
	local str = nx_string(IniReadUserConfig("KyNgo", "ChangeList", ""))
	if str ~= "" then
		local clst = util_split_string(str, ";")
		local cnt = #clst
		for i = 1, cnt do
			table.insert(ChangeList, clst[i])
		end
	end
end

function loadConfig()
	for id, detail in pairs(KyNgoData) do
		local cnt = #ChangeList
		local changeFlg = false
		for i = 1, cnt do
			if detail.NpcID == ChangeList[i] then
				changeFlg = true
				break
			end
		end
		addToKyNgoGroupBox(detail, changeFlg)
	end
end

function addToKyNgoGroupBox(detail, changeFlg)
	local container = Form.ky_ngo_grid
	local gridIndex = container.RowCount
	local checked = detail.Default == "1" and true or false
	if changeFlg then
		checked = not checked
	end
	local cbtn = createCheckboxButton(detail, checked)
	local itemPhoto = createImageControl(detail)

	container:BeginUpdate()
	container:InsertRow(gridIndex)
	container:SetGridControl(gridIndex, 0, cbtn)
	container:SetGridControl(gridIndex, 1, itemPhoto)
	container:EndUpdate()
end

function getItemPhoto(itemId)
	local gui = nx_value("gui")
	local itemQuery = nx_value("ItemQuery")
	if not nx_is_valid(itemQuery) then
		return ""
	end
	if not itemQuery:FindItemByConfigID(nx_string(itemId)) then
		return ""
	end
	return itemQuery:GetItemPropByConfigID(nx_string(itemId), "photo")
end

function createCheckboxButton(detail, checked)
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

	btn.Top = 8
	btn.Left = 0
	btn.Checked = checked
	btn.BoxSize = 12
	btn.NormalColor = "255,255,255,255"
	btn.FocusColor = "0,0,0,0"
	btn.PushColor = "0,0,0,0"
	btn.DisableColor = "0,0,0,0"
	btn.PushBlendColor = "255,255,255,255"
	btn.DisableBlendColor = "255,255,255,255"
	btn.Width = 230
	btn.Height = 22
	btn.BackColor = "255,192,192,192"
	btn.ForeColor = "255,255,255,255"
	btn.ShadowColor = "0,0,0,0"
	btn.TabStop = true
	btn.NoFrame = true
	btn.InSound = "MouseOn_20"
	btn.ClickSound = "ok_7"
	btn.Text = util_text(detail.NpcID)
	btn.NormalImage = "gui\\common\\checkbutton\\cbtn_out_4.png"
	btn.FocusImage = "gui\\common\\checkbutton\\cbtn_on_4.png"
	btn.CheckedImage = "gui\\common\\checkbutton\\cbtn_down_4.png"
	btn.DrawMode = "ExpandH"
	btn.KyNgoNpcId = detail.NpcID
	return groupbox
end

function createImageControl(detail)
	local gui = nx_value("gui")
	if not nx_is_valid(gui) then
		return 0
	end
	local groupbox = gui:Create("GroupBox")
	groupbox.BackColor = "0,0,0,0"
	groupbox.NoFrame = true
	local pic = gui:Create("Picture")
	groupbox:Add(pic)
	groupbox.pic = pic

	pic.NoFrame = true
	pic.Left = 0
	pic.Top = 0
	pic.Image = nx_string(getItemPhoto(detail.ItemID))
	pic.Width = 40
	pic.Height = 40
	pic.CenterX = -1
	pic.CenterY = -1
	pic.ZoomWidth = 0.232420
	pic.ZoomHeight = 0.193359
	pic.LineColor = "255,128,101,74"
	pic.ShadowColor = "0,0,0,0"
	pic.HintText = util_text(detail.ItemID)
	return groupbox
end

function onBtnSaveClick()
	local cnt = Form.ky_ngo_grid.RowCount - 1
	local kyNgoStr = ""
	for i = 0, cnt do
		local cbtn = Form.ky_ngo_grid:GetGridControl(i, 0).btn
		if isKyNgoCheckedChanged(cbtn.Checked, cbtn.KyNgoNpcId) then
			if kyNgoStr ~= "" then
				kyNgoStr = kyNgoStr .. ";"
			end
			kyNgoStr = kyNgoStr .. cbtn.KyNgoNpcId
		end
	end
	IniWriteUserConfig("KyNgo", "ChangeList", kyNgoStr)
	nx_execute("zdn_logic_ky_ngo", "LoadConfig")
end

function isKyNgoCheckedChanged(checked, npcId)
	for id, detail in pairs(KyNgoData) do
		if nx_string(detail.NpcID) == nx_string(npcId) then
			if (nx_string(detail.Default) == "1" and checked) or (nx_string(detail.Default) == "0" and not checked) then
				return false
			else
				return true
			end
		end
	end
	return false
end
