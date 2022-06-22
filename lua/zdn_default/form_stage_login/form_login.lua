function exit_game()
  local form = nx_value("form_stage_login\\form_login")
  if not nx_is_valid(form) then
    return
  end
  local game_config = nx_value("game_config")
  if nx_is_valid(game_config) then
    form.web_view_login:Disable()
    form.groupbox_web.Visible = false
  end
  local form_queue = nx_value("form_common\\form_queue")
  if nx_is_valid(form_queue) then
    return
  end
  local form_login_phone = nx_value("form_stage_login\\form_login_phone")
  if nx_is_valid(form_login_phone) then
    return
  end
  local form_out = nx_value("breakconnect_form_confirm")
  if nx_is_valid(form_out) then
    local timer = nx_value(GAME_TIMER)
    timer:UnRegister(nx_current(), "exit_game", form)
    return
  end
  local sdo_login_interface = nx_value("SdoLoginInterface")
  if nx_is_valid(sdo_login_interface) then
    sdo_login_interface.ShowLoginDialog = false
  end
  local dialog = nx_execute("form_common\\form_confirm", "get_new_confirm_form", "breakconnect")
  if not nx_is_valid(dialog) then
    return
  end
  local gui = nx_value("gui")
  dialog.cancel_btn.Visible = false
  dialog.ok_btn.Left = dialog.cancel_btn.Left
  dialog.mltbox_info.HtmlText = nx_widestr(gui.TextManager:GetText("ui_net_close_info"))
  dialog.ok_btn.Text = nx_function("ext_utf8_to_widestr", "Kết nối lại")
  dialog:ShowModal()
  local res = nx_wait_event(100000000, dialog, "breakconnect_confirm_return")
  nx_execute("gui", "on_sock_close")
  nx_execute("stage", "set_current_stage", "login")
end
