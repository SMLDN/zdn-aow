require("util_functions")
require("zdn_form_common")

local Logic = "zdn_logic_dan"

function onFormOpen()
	loadFormData()
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

function loadFormData()
	local form = Form
	ListSkillPic = {
		form.pic_skill_1,
		form.pic_skill_2,
		form.pic_skill_3,
		form.pic_skill_4,
		form.pic_skill_5
	}

	ListSetButton = {
		form.rbtn_set_1,
		form.rbtn_set_2,
		form.rbtn_set_3,
		form.rbtn_set_4,
		form.rbtn_set_5
	}

	for i = 1, 5 do
		ListSkillPic[i].SkillID = "null"
		ListSkillPic[i].RatioButton = ListSetButton[i]
		ListSkillPic[i].HintText = nx_widestr("")
		ListSkillPic[i].Image = ""
	end

	local text = nx_string(IniReadUserConfig("QinGame", "skill", "0"))
	if text == "0" then
		text = "null,null,null,null,null"
		IniWriteUserConfig("QinGame", "skill", text)
	end
	local skill_list = util_split_string(text, ",")
	if #skill_list == 5 then
		for i = 1, 5 do
			if skill_list[i] ~= "null" then
				ListSkillPic[i].SkillID = skill_list[i]
				local item = get_qin_data(skill_list[i])
				if item ~= nil then
					ListSkillPic[i].HintText = util_text(item.Name)
					ListSkillPic[i].Image = item.Image
				end
			end
		end
	end

	local set = nx_number(IniReadUserConfig("QinGame", "set", "0"))
	if set <= 0 or set > 5 then
		set = 1
		IniWriteUserConfig("QinGame", "set", set)
	end
	ListSetButton[set].Checked = true
	local _type = nx_number(IniReadUserConfig("QinGame", "type", "0"))
	if _type == 1 then
		form.rbtn_train.Checked = true
	else
		form.rbtn_buff.Checked = true
	end
	form.max_turn.Text = IniReadUserConfig("QinGame", "max_turn", 10)
end

function get_qin_data(formula_id)
	local lol_msg = nx_execute("util_functions", "get_ini", "share\\Item\\life_formula.ini")
	if not nx_is_valid(lol_msg) then
		return nil
	end
	local sec_index = lol_msg:FindSectionIndex(nx_string(formula_id))
	if sec_index < 0 then
		return nil
	end
	local item = {}
	item.Name = lol_msg:ReadString(sec_index, "ComposeResult", "")
	item.Image = get_item_info(item.Name, "photo")
	return item
end

function on_pic_skill_left_click(self)
	if not nx_find_custom(self, "SkillID") then
		nx_set_custom(self, "SkillID", "null")
	end
	local item = getHandItem()
	if item ~= nil then
		self.Image = item.Image
		self.SkillID = item.SkillID
		local qin = get_qin_data(item.SkillID)
		if qin ~= nil then
			self.HintText = util_text(qin.Name)
		end
	elseif self.SkillID ~= "null" then
		for _, btn in pairs(ListSetButton) do
			btn.Checked = false
		end
		self.RatioButton.Checked = true
	end
end

function getHandItem(...)
	local item = {}
	local gui = nx_value("gui")
	local game_hand = gui.GameHand
	if game_hand:IsEmpty() then
		return nil
	elseif game_hand.Type == "qin" and game_hand.Para1 == "qin" then
		item.SkillID = game_hand.Para2
		item.Image = game_hand.Image
	end
	game_hand:ClearHand()
	return item
end

function on_pic_skill_right_click(self)
	self.Image = ""
	self.SkillID = "null"
	self.HintText = nx_widestr("")
end

function get_item_info(configid, prop)
	local gui = nx_value("gui")
	local ItemQuery = nx_value("ItemQuery")
	if not nx_is_valid(ItemQuery) then
		return ""
	end
	if not ItemQuery:FindItemByConfigID(nx_string(configid)) then
		return ""
	end
	return ItemQuery:GetItemPropByConfigID(nx_string(configid), nx_string(prop))
end

function saveConfig()
	local text = ListSkillPic[1].SkillID
	for i = 2, 5 do
		text = text .. "," .. ListSkillPic[i].SkillID
	end
	IniWriteUserConfig("QinGame", "skill", text)
	local set = 1
	for i = 2, 5 do
		if ListSetButton[i].Checked then
			set = i
			break
		end
	end
	IniWriteUserConfig("QinGame", "set", set)
	local _type = 1
	if Form.rbtn_buff.Checked then
		_type = 2
	end
	IniWriteUserConfig("QinGame", "type", _type)
	IniWriteUserConfig("QinGame", "max_turn", Form.max_turn.Text)
end
