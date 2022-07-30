require("util_gui")
require("util_functions")
require("zdn_form_common")

function onFormOpen(form)
	if nx_execute("zdn_logic_skill", "IsRunning") then
		updateBtnSubmitState(true)
	else
		updateBtnSubmitState(false)
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
		updateBtnSubmitState(true)
	else
		nx_execute("zdn_logic_skill", "StopAutoAttack")
		updateBtnSubmitState(false)
	end
end

function loadFormData(form)
	local set = nx_number(IniReadUserConfig("KyNang", "Selected", "0"))
	if set == 0 then
		IniWriteUserConfig("KyNang", "Selected", "1")
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
	local goNearFlg = nx_string(IniReadUserConfig("KyNang", "GoNear", "-1"))
	if goNearFlg == "-1" then
		IniWriteUserConfig("KyNang", "GoNear", "0")
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
	IniWriteUserConfig("KyNang", "Selected", set)
	IniWriteUserConfig("KyNang", "GoNear", form.cbtn_go_near.Checked and "1" or "0")
end

function onBtnSettingClick(btn)
	util_auto_show_hide_form("form_zdn_skill_setting")
end