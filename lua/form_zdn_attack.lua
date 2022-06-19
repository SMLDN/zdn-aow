require("util_gui")
require("zdn_lib\\util_functions")
require("zdn_form_common")

function onFormOpen(form)
	if nx_execute("zdn_logic_skill", "IsRunning") then
		form.btn_submit.Text = nx_widestr("Stop")
	else
		form.btn_submit.Text = nx_widestr("Start")
	end
	loadFormData(form)
end

function onFormClose()
	nx_execute("zdn_logic_skill", "StopAutoAttack")
end

function onBtnSubmitClick(btn)
	local form = btn.Parent
	saveFormData(form)
	if not nx_execute("zdn_logic_skill", "IsRunning") then
		nx_execute("zdn_logic_skill", "AutoAttackDefaultSkillSet")
		btn.Text = nx_widestr("Stop")
	else
		nx_execute("zdn_logic_skill", "StopAutoAttack")
		btn.Text = nx_widestr("Start")
	end
end

function loadFormData(form)
	local set = nx_number(IniReadUserConfig("Skill", "skill_set", "0"))
	if set == 0 then
		IniWriteUserConfig("Skill", "skill_set", "1")
		set = 1
	end
	if set == 1 then
		form.rbtn_set_1.Checked = true
		form.rbtn_set_2.Checked = false
		form.rbtn_set_3.Checked = false
	elseif set == 2 then
		form.rbtn_set_1.Checked = false
		form.rbtn_set_2.Checked = true
		form.rbtn_set_3.Checked = false
	else
		form.rbtn_set_1.Checked = false
		form.rbtn_set_2.Checked = false
		form.rbtn_set_3.Checked = true
	end
	local goNearFlg = nx_string(IniReadUserConfig("Skill", "go_near_flg", "-1"))
	if goNearFlg == "-1" then
		IniWriteUserConfig("Skill", "go_near_flg", "0")
		goNearFlg = "0"
	end
	form.cbtn_go_near.Checked = goNearFlg == "1" and true or false
end

function saveFormData(form)
	local set = 1
	if form.rbtn_set_2.Checked then
		set = 2
	elseif form.rbtn_set_3.Checked then
		set = 3
	end
	IniWriteUserConfig("Skill", "skill_set", set)
	IniWriteUserConfig("Skill", "go_near_flg", form.cbtn_go_near.Checked and "1" or "0")
end

function onBtnSettingClick(btn)
	util_auto_show_hide_form("form_zdn_skill_set")
end