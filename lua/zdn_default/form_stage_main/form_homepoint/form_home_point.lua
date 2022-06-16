function old_auto_show_hide_point_form()
    local form = nx_value(FORM_HOME_POINT)
    if nx_is_valid(form) then
      if not form.Visible then
        ShowHomePointForm()
      else
        reset_homepoint_timedown(form)
        form.pbar_timedown.Value = 0
        form.lbl_time.Text = ""
        form.Visible = false
        reset_hire_timedown(form)
        form:Close()
      end
    else
      ShowHomePointForm()
    end
  end

function auto_show_hide_point_form()
    local timerForm = nx_value("form_stage_main\\form_homepoint\\form_home_point")
    local showForm = nx_value("form_zdn_tele")
    if nx_is_valid(showForm) then
        if not showForm.Visible then
            ZdnShowHomePointForm()
        else
            showForm:Close()
            if nx_is_valid(timerForm) then
                reset_homepoint_timedown(timerForm)
                reset_hire_timedown(timerForm)
                timerForm:Close()
            end
        end
    else
        ZdnShowHomePointForm()
    end
end

function ZdnShowHomePointForm()
    send_homepoint_msg_to_server(Query_TimeDown)
    util_show_form("form_zdn_tele", true)
end

function main_form_init(form)
    form.Fixed = false
    form.Width = 0
    form.Height = 0
end

function on_main_form_open(form)
    form.Left = 0
    form.Top = 0
    form.timer_span = 1000
    form.pbar_timedown.Maximum = THIRTY_MINUTE
    form.pbar_timedown.Minimum = 0
    form.hp_grp.area_hp = ""
    form.groupbox_rep.Visible = false
    Init_homepoint_abstruct(form)
    form.btn_xunlu.Text = nx_widestr(util_text("ui_map"))
    local databinder = nx_value("data_binder")
    if nx_is_valid(databinder) then
        databinder:AddTableBind("HomePointList", form, nx_current(), "on_homepoint_rec_refresh")
        databinder:AddTableBind("DongHaiHomePointList", form, nx_current(), "on_homepoint_rec_refresh")
        databinder:AddTableBind("HireHomePointList", form, nx_current(), "on_homepoint_hire_rec_refresh")
        databinder:AddRolePropertyBind("JiangHuHomePointCount", "int", form, nx_current(), "on_homepoint_rec_refresh")
        databinder:AddRolePropertyBind("GuildHomePointCount", "int", form, nx_current(), "on_homepoint_rec_refresh")
        databinder:AddRolePropertyBind("RelivePositon", "string", form, nx_current(), "refresh_relive")
        databinder:AddRolePropertyBind("DongHaiRelivePositon", "string", form, nx_current(), "refresh_relive")
    end
    form.grp_hire.Visible = false
    form.hire_time = 0
    if nx_int(form.hire_time) <= nx_int(0) then
        form.grp_hire_time.Visible = false
        form.lbl_hire_text.Visible = true
    else
        form.grp_hire_time.Visible = true
        form.lbl_hire_text.Visible = false
    end
    form.open_by_guide = 1
end

function on_update_timedown(form)
    local realForm = nx_value("form_zdn_tele")
    if not nx_is_valid(realForm) or realForm.Visible == false then
        util_show_form("form_zdn_tele", true)
    end
    local time = form.timer_down
    if nx_int(0) >= nx_int(time) then
        if nx_is_valid(realForm) and realForm.Visible == true then
            realForm.lbl_time.ForeColor = "255,128,128,128"
            realForm.lbl_time.Text = nx_widestr(util_text("ui_timeend"))
        end
        reset_homepoint_timedown(form)
        return
    end
    if nx_is_valid(realForm) and realForm.Visible == true then
        realForm.lbl_time.ForeColor = "255,210,43,43"
        realForm.lbl_time.Text = nx_widestr(get_format_time_text(time / 1000))
    end
    form.timer_down = nx_int(time) - nx_int(PER_SECOND)
end
