require("shortcut_game")
require("util_gui")
require("util_functions")
require("zdn_form_common")

local MAX_SET = 3
local MAX_SKILL = 8
local Selected = 1

function onBtnOkClick(btn)
	saveConfig(btn)
end

function onFormOpen()
	Form.cbx_set.DropListBox:ClearString()
	for i = 1, MAX_SET do
		Form.cbx_set.DropListBox:AddString(Utf8ToWstr("Bộ ") .. nx_widestr(i))
	end
	Form.cbx_set.DropListBox.SelectIndex = Selected - 1
	Form.cbx_set.Text = Utf8ToWstr("Bộ ") .. nx_widestr(Selected)
	loadFormData()
end

function onSkillLeftClick(self)
	if not nx_find_custom(self, "SkillStyle") then
		nx_set_custom(self, "SkillStyle", "1")
	end
	if not nx_find_custom(self, "ConfigID") then
		nx_set_custom(self, "ConfigID", "null")
	end
	local hand_item = getHandItem()
	local pic_item = getPictureItem(self)
	setHandItem(pic_item)
	setPictureItem(self, hand_item)
end

function getHandItem()
	local item = {}
	local gui = nx_value("gui")
	local game_hand = gui.GameHand
	if game_hand:IsEmpty() then
		return nil
	elseif game_hand.Type == "viewitem" and game_hand.Para1 == "40" then
		local view_obj = getItem(game_hand.Para1, game_hand.Para2)
		item.ConfigID = view_obj:QueryProp("ConfigID")
		item.Image = game_hand.Image
		item.SkillStyle = "1"
	elseif game_hand.Type == "func" and game_hand.Para2 == "normal_anqi_attack" and getAnqiSkill() ~= nil then
		item.ConfigID = getAnqiSkill()
		item.Image = game_hand.Image
		item.SkillStyle = "1"
	elseif game_hand.Type == "auto_skill_set" then
		item.ConfigID = game_hand.Para1
		item.Image = game_hand.Image
		item.SkillStyle = game_hand.Para2
	else
		game_hand:ClearHand()
		return -1
	end
	return item
end

function getItem(view_ident, view_index)
	local game_client = nx_value("game_client")
	if not nx_is_valid(game_client) then
		return
	end
	local view = game_client:GetView(view_ident)
	if not nx_is_valid(view) then
		return
	end
	return view:GetViewObj(view_index)
end

function getAnqiSkill()
	local fight = nx_value("fight")
	if not nx_is_valid(fight) then
		return nil
	end
	return fight:GetNormalAnqiAttackSkillID(false)
end

function getPictureItem(pic)
	if pic.ConfigID == "null" then
		return nil
	end
	local item = {}
	item.ConfigID = pic.ConfigID
	item.SkillStyle = pic.SkillStyle
	item.Image = pic.Image
	return item
end

function setHandItem(item)
	local gui = nx_value("gui")
	local game_hand = gui.GameHand
	if item == nil then
		game_hand:ClearHand()
		return
	end
	game_hand:SetHand("auto_skill_set", item.Image, item.ConfigID, nx_string(item.SkillStyle), "", "")
end

function setPictureItem(pic, item)
	if item == -1 then
		return
	end
	if item == nil then
		pic.ConfigID = "null"
		pic.SkillStyle = "1"
		pic.Image = ""
	else
		pic.ConfigID = item.ConfigID
		pic.SkillStyle = item.SkillStyle
		pic.Image = item.Image
	end
	updatePicture(pic)
end

function onSkillRightClick(self)
	if not nx_find_custom(self, "SkillStyle") then
		nx_set_custom(self, "SkillStyle", "1")
	end
	if not nx_find_custom(self, "ConfigID") then
		nx_set_custom(self, "ConfigID", "null")
	end
	if self.ConfigID == "null" then
		ShowText(util_text("zdn_must_place_skill"))
		return
	end
	local skillStyle = self.SkillStyle
	if skillStyle == "1" then
		skillStyle = "2"
		ShowText(util_text(self.ConfigID) .. nx_widestr(" ") .. util_text("zdn_change_to_sky"))
	elseif skillStyle == "2" then
		skillStyle = "3"
		ShowText(util_text(self.ConfigID) .. nx_widestr(" ") .. util_text("zdn_change_to_hide"))
	else
		skillStyle = "1"
		ShowText(util_text(self.ConfigID) .. nx_widestr(" ") .. util_text("zdn_change_to_normal"))
	end
	self.SkillStyle = skillStyle
	updatePicture(self)
end

function updatePicture(self)
	local skillStyle = self.SkillStyle
	if skillStyle == "2" then
		self.LineColor = "255,0,255,0"
		self.HintText = util_text("zdn_fly_skill")
	elseif skillStyle == "3" then
		self.LineColor = "255,255,0,0"
		self.HintText = util_text("zdn_hide_skill")
	else
		self.LineColor = "255,128,101,74"
		self.HintText = util_text("zdn_right_click_change")
	end
end

function onWeaponLeftClick(self)
	if not nx_find_custom(self, "UniqueID") then
		nx_set_custom(self, "UniqueID", "1")
	end
	if not nx_find_custom(self, "ConfigID") then
		nx_set_custom(self, "ConfigID", "null")
	end
	local gui = nx_value("gui")
	local game_hand = gui.GameHand
	if game_hand:IsEmpty() then
		return
	end
	if game_hand.Type == "viewitem" and game_hand.Para1 == "121" then
		if not isWeaponItem(game_hand.Para1, game_hand.Para2) then
			ShowText(util_text("zdn_must_place_weapon"))
		else
			local item = nx_execute("goods_grid", "get_view_item", game_hand.Para1, game_hand.Para2)
			if nx_is_valid(item) then
				self.UniqueID = item:QueryProp("UniqueID")
				self.ConfigID = item:QueryProp("ConfigID")
				self.Image = game_hand.Image
				self.HintText = util_text(item:QueryProp("ConfigID"))
			end
		end
	end
	game_hand:ClearHand()
end

function isWeaponItem(view_id, pos)
	local item = nx_execute("goods_grid", "get_view_item", view_id, pos)
	if not nx_is_valid(item) then
		return false
	end
	local goods_grid = nx_value("GoodsGrid")
	local list = goods_grid:GetEquipPositionList(item)
	for _, value in pairs(list) do
		if nx_number(value) == 22 or nx_number(value) == 7 or nx_number(value) == 6 then
			return true
		end
	end
	return false
end

function onWeaponRightClick(self)
	if not nx_find_custom(self, "UniqueID") then
		nx_set_custom(self, "UniqueID", "1")
	end
	if not nx_find_custom(self, "ConfigID") then
		nx_set_custom(self, "ConfigID", "null")
	end
	self.UniqueID = "1"
	self.ConfigID = "null"
	self.Image = ""
	self.HintText = util_text("zdn_drop_weapon_here")
end

function saveConfig()
	saveMasterConfig()
	saveSkillConfig()
	saveWeaponConfig()
	saveBookConfig()
end

function loadFormData()
	loadMasterConfig()
	loadSkillConfig()
	loadWeaponConfig()
	loadBookConfig()
end

function onBookLeftClick(self)
	if not nx_find_custom(self, "UniqueID") then
		nx_set_custom(self, "UniqueID", "1")
	end
	if not nx_find_custom(self, "ConfigID") then
		nx_set_custom(self, "ConfigID", "null")
	end
	local gui = nx_value("gui")
	local game_hand = gui.GameHand
	if game_hand:IsEmpty() then
		return
	end
	if game_hand.Type == "viewitem" and game_hand.Para1 == "121" then
		if not isBookItem(game_hand.Para1, game_hand.Para2) then
			ShowText(util_text("zdn_must_place_book"))
		else
			local item = nx_execute("goods_grid", "get_view_item", game_hand.Para1, game_hand.Para2)
			if nx_is_valid(item) then
				self.UniqueID = item:QueryProp("UniqueID")
				self.ConfigID = item:QueryProp("ConfigID")
				self.Image = game_hand.Image
				self.HintText = util_text(item:QueryProp("ConfigID"))
			end
		end
	end
	game_hand:ClearHand()
end

function onBookRightClick(self)
	if not nx_find_custom(self, "UniqueID") then
		nx_set_custom(self, "UniqueID", "1")
	end
	if not nx_find_custom(self, "ConfigID") then
		nx_set_custom(self, "ConfigID", "null")
	end
	self.UniqueID = "1"
	self.ConfigID = "null"
	self.Image = ""
	self.HintText = util_text("zdn_drop_book_here")
end

function isBookItem(viewId, pos)
	local item = nx_execute("goods_grid", "get_view_item", viewId, pos)
	if not nx_is_valid(item) then
		return false
	end
	local goods_grid = nx_value("GoodsGrid")
	local list = goods_grid:GetEquipPositionList(item)
	for _, value in pairs(list) do
		if nx_number(value) == 24 then
			return true
		end
	end
	return false
end

function saveMasterConfig()
	local weaStr = "null"
	if nx_find_custom(Form.pic_master_weapon, "UniqueID") and Form.pic_master_weapon.UniqueID ~= "1" then
		weaStr = Form.pic_master_weapon.UniqueID
		weaStr = weaStr .. "," .. Form.pic_master_weapon.ConfigID
		weaStr = weaStr .. "," .. Form.pic_master_weapon.Image
	end
	local rageStr = "null"
	if nx_find_custom(Form.pic_master_rage, "ConfigID") and Form.pic_master_rage.ConfigID ~= "null" then
		rageStr = Form.pic_master_rage.ConfigID
		rageStr = rageStr .. "," .. Form.pic_master_rage.SkillStyle
		rageStr = rageStr .. "," .. Form.pic_master_rage.Image
	end
	local breakStr = "null"
	if nx_find_custom(Form.pic_master_break, "ConfigID") and Form.pic_master_break.ConfigID ~= "null" then
		breakStr = Form.pic_master_break.ConfigID
		breakStr = breakStr .. "," .. Form.pic_master_break.SkillStyle
		breakStr = breakStr .. "," .. Form.pic_master_break.Image
	end
	IniWriteUserConfig("KyNang", "M" .. nx_string(Selected), weaStr .. ";" .. rageStr .. ";" .. breakStr)
end

function saveSkillConfig()
	local str = ""
	for i = 1, MAX_SKILL do
		local t = Form["pic_skill_" .. nx_string(i)]
		local s = "null"
		if nx_find_custom(t, "ConfigID") and t.ConfigID ~= "null" then
			s = t.ConfigID
			s = s .. "," .. t.SkillStyle
			s = s .. "," .. t.Image
		end
		str = str .. s
		if i < MAX_SKILL then
			str = str .. ";"
		end
	end
	IniWriteUserConfig("KyNang", "S" .. nx_string(Selected), str)
end

function saveWeaponConfig()
	local str = ""
	for i = 1, MAX_SKILL do
		local t = Form["pic_weapon_" .. nx_string(i)]
		local s = "null"
		if nx_find_custom(t, "UniqueID") and t.UniqueID ~= "1" then
			s = t.UniqueID
			s = s .. "," .. t.ConfigID
			s = s .. "," .. t.Image
		end
		str = str .. s
		if i < MAX_SKILL then
			str = str .. ";"
		end
	end
	IniWriteUserConfig("KyNang", "W" .. nx_string(Selected), str)
end

function saveBookConfig()
	local str = ""
	for i = 1, MAX_SKILL do
		local t = Form["pic_book_" .. nx_string(i)]
		local s = "null"
		if nx_find_custom(t, "UniqueID") and t.UniqueID ~= "1" then
			s = t.UniqueID
			s = s .. "," .. t.ConfigID
			s = s .. "," .. t.Image
		end
		str = str .. s
		if i < MAX_SKILL then
			str = str .. ";"
		end
	end
	IniWriteUserConfig("KyNang", "B" .. nx_string(Selected), str)
end

function loadMasterConfig()
	local str = nx_string(IniReadUserConfig("KyNang", "M" .. nx_string(Selected), "null;null;null"))
	local prop = util_split_string(str, ";")
	setPicWeaponFromStr(Form.pic_master_weapon, prop[1])
	setPicSkillFromStr(Form.pic_master_rage, prop[2])
	setPicSkillFromStr(Form.pic_master_break, prop[3])
end

function setPicWeaponFromStr(node, str)
	if str == "null" then
		node.UniqueID = "1"
		node.ConfigID = "null"
		node.Image = ""
		return
	end
	local prop = util_split_string(str, ",")
	node.UniqueID = prop[1]
	node.ConfigID = prop[2]
	node.Image = prop[3]
	node.HintText = util_text(prop[2])
end

function setPicSkillFromStr(node, str)
	if str == "null" then
		node.ConfigID = "null"
		node.SkillStyle = "1"
		node.Image = ""
		return
	end
	local prop = util_split_string(str, ",")
	node.ConfigID = prop[1]
	node.SkillStyle = prop[2]
	node.Image = prop[3]
end

function setPicBookFromStr(node, str)
	if str == "null" then
		node.UniqueID = "1"
		node.ConfigID = "null"
		node.Image = ""
		return
	end
	local prop = util_split_string(str, ",")
	node.UniqueID = prop[1]
	node.ConfigID = prop[2]
	node.Image = prop[3]
end

function loadSkillConfig()
	local str =
		nx_string(IniReadUserConfig("KyNang", "S" .. nx_string(Selected), "null;null;null;null;null;null;null;null;null"))
	local prop = util_split_string(str, ";")
	for i = 1, MAX_SKILL do
		setPicSkillFromStr(Form["pic_skill_" .. i], prop[i])
	end
end

function loadWeaponConfig()
	local str =
		nx_string(IniReadUserConfig("KyNang", "W" .. nx_string(Selected), "null;null;null;null;null;null;null;null;null"))
	local prop = util_split_string(str, ";")
	for i = 1, MAX_SKILL do
		setPicWeaponFromStr(Form["pic_weapon_" .. i], prop[i])
	end
end

function loadBookConfig()
	local str =
		nx_string(IniReadUserConfig("KyNang", "B" .. nx_string(Selected), "null;null;null;null;null;null;null;null;null"))
	local prop = util_split_string(str, ";")
	for i = 1, MAX_SKILL do
		setPicBookFromStr(Form["pic_book_" .. i], prop[i])
	end
end

function onCbxSetSelected()
	local s = Form.cbx_set.DropListBox.SelectIndex + 1
	if s == Selected then
		return
	end
	Selected = s
	loadFormData()
end
