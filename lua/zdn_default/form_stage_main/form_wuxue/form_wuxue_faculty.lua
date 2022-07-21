require("zdn_util")
--
function auto_uplvl()
  nx_pause(5)
  nx_execute("custom_sender", "custom_send_faculty_msg", 11)
end
function on_msg_level_up()
  nx_execute("form_stage_main\\form_wuxue\\form_wuxue_faculty", "auto_uplvl")
  nx_execute("custom_sender", "custom_send_faculty_msg", 11)
  --
  local gui = nx_value("gui")
  local dialog = nx_execute("form_common\\form_confirm", "get_new_confirm_form", "wuxue_lvlup")
  local text = nx_widestr(util_text("ui_normal_faculty_level_up"))
  dialog.ok_btn.Text = gui.TextManager:GetText(nx_string("ui_continue_faculty"))
  dialog.cancel_btn.Text = gui.TextManager:GetText(nx_string("ui_reset_faculty"))
  local game_client = nx_value("game_client")
  local client_player = game_client:GetPlayer()
  local text = ""
  local wuxue_name = client_player:QueryProp("FacultyName")
  if nx_string(wuxue_name) == "" or nx_string(wuxue_name) == nil then
    dialog.ok_btn.Enabled = false
    text = nx_widestr(util_text("ui_normal_faculty_max_level"))
  else
    local wuxue_level = client_player:QueryProp("CurLevel")
    text =
      gui.TextManager:GetFormatText(nx_string("ui_normal_faculty_level_up"), nx_string(wuxue_name), nx_int(wuxue_level))
  end
  nx_execute("form_common\\form_confirm", "show_common_text", dialog, text)
  dialog:Show()
  local form_load = nx_value("form_common\\form_loading")
  if nx_is_valid(form_load) then
    gui.Desktop:ToBack(dialog)
  else
    gui.Desktop:ToFront(dialog)
  end
  dialog.AbsLeft = (gui.Width - dialog.Width) / 10 * 9
  dialog.AbsTop = (gui.Height - dialog.Height) / 2
  local res = nx_wait_event(100000000, dialog, "wuxue_lvlup_confirm_return")
  if res == "ok" then
    nx_execute("custom_sender", "custom_send_faculty_msg", SUB_CLIENT_NORMAL_BEGIN)
  elseif res == "cancel" then
    nx_execute("form_stage_main\\form_wuxue\\form_wuxue_util", "auto_show_hide_wuxue")
  end
end
