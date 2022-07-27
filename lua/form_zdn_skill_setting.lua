require("shortcut_game")
require("util_gui")
require("util_functions")
require("zdn_form_common")

local MAX_SET = 3
local PictureList = {}
local ZdnText = nil

function onFormInit()
	initTextData()
end

function onBtnOkClick(btn)
	saveSetting(btn)
end

function onFormOpen(form)
	PictureList[1] = {
		form.pic_skill_1_1,
		form.pic_skill_1_2,
		form.pic_skill_1_3,
		form.pic_skill_1_4,
		form.pic_skill_1_5,
		form.pic_skill_1_6,
		form.pic_skill_1_7,
		form.pic_skill_1_8,
		form.pic_skill_1_9,
		form.pic_vk_1
	}
	PictureList[2] = {
		form.pic_skill_2_1,
		form.pic_skill_2_2,
		form.pic_skill_2_3,
		form.pic_skill_2_4,
		form.pic_skill_2_5,
		form.pic_skill_2_6,
		form.pic_skill_2_7,
		form.pic_skill_2_8,
		form.pic_skill_2_9,
		form.pic_vk_2
	}
	PictureList[3] = {
		form.pic_skill_3_1,
		form.pic_skill_3_2,
		form.pic_skill_3_3,
		form.pic_skill_3_4,
		form.pic_skill_3_5,
		form.pic_skill_3_6,
		form.pic_skill_3_7,
		form.pic_skill_3_8,
		form.pic_skill_3_9,
		form.pic_vk_3
	}
	for i = 1, MAX_SET do
		for j, pic in pairs(PictureList[i]) do
			pic.Image = ""
			pic.ConfigID = "null"
		end
	end
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
		pic.Image = ""
		pic.ConfigID = "null"
		pic.SkillStyle = "1"
	else
		pic.Image = item.Image
		pic.ConfigID = item.ConfigID
		pic.SkillStyle = item.SkillStyle
	end
	updatePicture(pic)
end

function onSkillRightClick(self)
	initTextData()
	if not nx_find_custom(self, "SkillStyle") then
		nx_set_custom(self, "SkillStyle", "1")
	end
	if not nx_find_custom(self, "ConfigID") then
		nx_set_custom(self, "ConfigID", "null")
	end
	if self.ConfigID == "null" then
		ShowText(ZdnText["must_place_skill"])
		return
	end
	local skillStyle = self.SkillStyle
	if skillStyle == "1" then
		skillStyle = "2"
		ShowText(util_text(self.ConfigID) .. nx_widestr(" ") .. ZdnText["change_to_sky"])
	elseif skillStyle == "2" then
		skillStyle = "3"
		ShowText(util_text(self.ConfigID) .. nx_widestr(" ") .. ZdnText["change_to_hide"])
	else
		skillStyle = "1"
		ShowText(util_text(self.ConfigID) .. nx_widestr(" ") .. ZdnText["change_to_normal"])
	end
	self.SkillStyle = skillStyle
	updatePicture(self)
end

function initTextData()
	if ZdnText == nil then
		ZdnText = IniReadZdnTextSection(nx_current())
	end
end

function updatePicture(self)
	initTextData()
	local skillStyle = self.SkillStyle
	if skillStyle == "2" then
		self.LineColor = "255,0,255,0"
		self.HintText = ZdnText["fly_skill"]
	elseif skillStyle == "3" then
		self.LineColor = "255,255,0,0"
		self.HintText = ZdnText["hide_skill"]
	else
		self.LineColor = "255,128,101,74"
		self.HintText = ZdnText["right_click_change"]
	end
end

function onWeaponLeftClick(self)
	initTextData()
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
			ShowText(ZdnText["must_place_weapon"])
		else
			local item = nx_execute("goods_grid", "get_view_item", game_hand.Para1, game_hand.Para2)
			if nx_is_valid(item) then
				self.UniqueID = item:QueryProp("UniqueID")
				self.ConfigID = item:QueryProp("ConfigID")
				self.Image = game_hand.Image
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
		if nx_number(value) == 22 then
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
end

function saveSetting(btn)
	for i = 1, MAX_SET do
		local text = ""
		for j = 1, 9 do
			local pic = PictureList[i][j]
			if not nx_find_custom(pic, "SkillStyle") then
				nx_set_custom(pic, "SkillStyle", "1")
			end
			if not nx_find_custom(pic, "ConfigID") then
				nx_set_custom(pic, "ConfigID", "null")
			end
			text = text .. nx_string(pic.ConfigID) .. "," .. nx_string(pic.SkillStyle) .. "," .. nx_string(pic.Image) .. ";"
		end
		if not nx_find_custom(PictureList[i][10], "UniqueID") then
			nx_set_custom(PictureList[i][10], "UniqueID", "1")
		end
		if not nx_find_custom(PictureList[i][10], "ConfigID") then
			nx_set_custom(PictureList[i][10], "ConfigID", "null")
		end
		text =
			text ..
			nx_string(PictureList[i][10].ConfigID) ..
				"," .. nx_string(PictureList[i][10].UniqueID) .. "," .. nx_string(PictureList[i][10].Image)
		IniWriteUserConfig("Skill", "set_" .. nx_string(i), text)
	end
end

function loadFormData()
	for i = 1, MAX_SET do
		local text = nx_string(IniReadUserConfig("Skill", "set_" .. nx_string(i), "0"))
		if text == "0" then
			return
		end
		local list = util_split_string(text, ";")
		if #list ~= 10 then
			return
		end
		for j = 1, 9 do
			local pic = PictureList[i][j]
			if not nx_find_custom(pic, "SkillStyle") then
				nx_set_custom(pic, "SkillStyle", "1")
			end
			if not nx_find_custom(pic, "ConfigID") then
				nx_set_custom(pic, "ConfigID", "null")
			end
			local data = util_split_string(list[j], ",")
			if #data ~= 3 then
				return
			end
			pic.ConfigID = data[1]
			pic.SkillStyle = data[2]
			pic.Image = data[3]
			updatePicture(pic)
		end
		if not nx_find_custom(PictureList[i][10], "UniqueID") then
			nx_set_custom(PictureList[i][10], "UniqueID", "1")
		end
		if not nx_find_custom(PictureList[i][10], "ConfigID") then
			nx_set_custom(PictureList[i][10], "ConfigID", "null")
		end
		local data = util_split_string(list[10], ",")
		if #data ~= 3 then
			return
		end
		PictureList[i][10].ConfigID = data[1]
		PictureList[i][10].UniqueID = data[2]
		PictureList[i][10].Image = data[3]
	end
end
