require("util_gui")
require("util_functions")
require("zdn_form_common")

local NoiTuData = {}

function onFormOpen()
	local gui = nx_value("gui")
	Form.Left = (gui.Width - Form.Width) / 2
	Form.Top = (gui.Height - Form.Height) / 2
	if #NoiTuData == 0 then
		loadNoiTuData()
	end
	loadConfig()
end

function loadConfig()
	local itemStr = IniReadUserConfig("VatPham", "List", "")
	if itemStr ~= "" then
		local itemList = util_split_string(nx_string(itemStr), ";")
		for _, item in pairs(itemList) do
			local prop = util_split_string(item, ",")
			local item = {}
			item.checked = nx_string(prop[1]) == "1" and true or false
			item.itemId = prop[2]
			item.buffId = prop[3]
			item.buffDescId = prop[4]
			item.buffPhoto = prop[5]
			addRowToItemGrid(item)
		end
	end
end

function onBtnAddItemClick()
	local itemId, viewPort = getHandItem()
	if itemId == nil then
		return
	end
	Console(itemId)
	Console(viewPort)
	if viewPort ~= "2" then
		ShowText("Chỉ được thêm vật phẩm từ ô Vật phẩm")
		return
	end
	if isItemExists(itemId) then
		ShowText("Vật phẩm này đã được thêm từ trước")
		return
	end
	if processNoiTuItem(itemId) then
		return
	end
	util_show_form("form_zdn_select_buff", true)
	nx_execute("form_zdn_select_buff", "SetItem", itemId)
end

function DoAddItem(itemId, buffId, buffDescId, buffPhoto)
	local item = {}
	item.itemId = itemId
	item.buffId = buffId
	item.buffDescId = buffDescId
	item.buffPhoto = buffPhoto
	item.checked = true
	addRowToItemGrid(item)
	saveConfig()
end

function addRowToItemGrid(item)
	local target = Form.item_grid
	local gridIndex = target.RowCount
	local cbtn = createCheckboxButton(item)
	local itemPhoto = createImageControl(item.itemId, nx_execute("zdn_logic_vat_pham", "GetItemPhoto", item.itemId))
	local buffPhoto = createImageControl(item.buffDescId, item.buffPhoto)
	local delBtn = createDeleteButton()

	target:BeginUpdate()
	target:InsertRow(gridIndex)
	target:SetGridControl(gridIndex, 0, cbtn)
	target:SetGridControl(gridIndex, 1, itemPhoto)
	target:SetGridControl(gridIndex, 2, buffPhoto)
	target:SetGridControl(gridIndex, 3, delBtn)
	target:EndUpdate()
end

function createImageControl(descId, photo)
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
	pic.Image = nx_string(photo)
	pic.Width = 40
	pic.Height = 40
	pic.CenterX = -1
	pic.CenterY = -1
	pic.ZoomWidth = 0.232420
	pic.ZoomHeight = 0.193359
	pic.LineColor = "255,128,101,74"
	pic.ShadowColor = "0,0,0,0"
	pic.HintText = util_text(descId)
	return groupbox
end

function createCheckboxButton(item)
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

	btn.Top = 9
	btn.Left = 0
	btn.Checked = item.checked
	btn.BoxSize = 12
	btn.NormalImage = "gui\\common\\checkbutton\\cbtn_2_out.png"
	btn.FocusImage = "gui\\common\\checkbutton\\cbtn_2_on.png"
	btn.CheckedImage = "gui\\common\\checkbutton\\cbtn_2_down.png"
	btn.DisableImage = "gui\\common\\checkbutton\\cbtn_2_forbid.png"
	btn.NormalColor = "255,255,255,255"
	btn.FocusColor = "255,255,255,255"
	btn.PushColor = "255,255,255,255"
	btn.DisableColor = "0,0,0,0"
	btn.PushBlendColor = "255,255,255,255"
	btn.DisableBlendColor = "255,255,255,255"
	btn.Width = 18
	btn.Height = 18
	btn.BackColor = "255,192,192,192"
	btn.ShadowColor = "0,0,0,0"
	btn.TabStop = true
	btn.AutoSize = true
	btn.InSound = "MouseOn_20"
	btn.ClickSound = "ok_7"

	btn.ItemItemId = item.itemId
	btn.ItemBuffId = item.buffId
	btn.ItemBuffDescId = item.buffDescId
	btn.ItemBuffPhoto = item.buffPhoto
	nx_bind_script(btn, nx_current())
	nx_callback(btn, "on_checked_changed", "onCheckedChange")
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
	btn.Left = 5
	btn.Top = 10
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

function getHandItem()
	local gui = nx_value("gui")
	local gameHand = gui.GameHand
	if gameHand:IsEmpty() or gameHand.Type ~= "viewitem" then
		return nil, 0
	end
	local viewPort = gameHand.Para1
	local itemIndex = gameHand.Para2
	local gameClient = nx_value("game_client")
	gameHand:ClearHand()
	if not nx_is_valid(gameClient) then
		return
	end
	local view = gameClient:GetView(viewPort)
	if not nx_is_valid(view) then
		return
	end
	local item = view:GetViewObj(itemIndex)
	if not nx_is_valid(item) then
		return nil, 0
	end
	return nx_string(item:QueryProp("ConfigID")), viewPort
end

function onBtnDeleteRowClick(btn)
	local cnt = Form.item_grid.RowCount - 1
	for i = 0, cnt do
		local gb = Form.item_grid:GetGridControl(i, 3)
		local cbtn = gb.btn
		if nx_id_equal(cbtn, btn) then
			Form.item_grid:BeginUpdate()
			Form.item_grid:DeleteRow(i)
			Form.item_grid:EndUpdate()
			break
		end
	end
	saveConfig()
end

function saveConfig()
	local cnt = Form.item_grid.RowCount - 1
	local itemStr = ""
	for i = 0, cnt do
		local cbtn = Form.item_grid:GetGridControl(i, 0).btn
		if i > 0 then
			itemStr = itemStr .. ";"
		end
		itemStr =
			itemStr ..
			(cbtn.Checked and "1" or "0") ..
				"," .. cbtn.ItemItemId .. "," .. cbtn.ItemBuffId .. "," .. cbtn.ItemBuffDescId .. "," .. cbtn.ItemBuffPhoto
	end
	IniWriteUserConfig("VatPham", "List", itemStr)
end

function onCheckedChange()
	saveConfig()
end

function isItemExists(itemId)
	local cnt = Form.item_grid.RowCount - 1
	for i = 0, cnt do
		local gb = Form.item_grid:GetGridControl(i, 0)
		local btn = gb.btn
		if itemId == btn.ItemItemId then
			return true
		end
	end
	return false
end

function loadNoiTuData()
	NoiTuData = IniLoadAllData(nx_resource_path() .. "zdn\\data\\vatpham.ini")
end

function processNoiTuItem(itemId)
	for _, detail in pairs(NoiTuData) do
		if detail.item == itemId then
			local buffId = detail.buff
			DoAddItem(itemId, buffId, buffId, nx_execute("zdn_logic_vat_pham", "GetItemPhoto", itemId))
			return true
		end
	end
	return false
end
