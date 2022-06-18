function wait_user_exit_game()
    if nx_function("ext_is_instance_overflow") then
        zdnShowLoginDialog()
        return
    end
    local dialog = nx_execute("form_common\\form_confirm", "get_new_confirm_form", "exit_game")
    if not nx_is_valid(dialog) then
        direct_exit_game()
        return
    end
    dialog:ShowModal()
    local text = nx_widestr(util_text("ui_too_many_ins"))
    nx_execute("form_common\\form_confirm", "show_common_text", dialog, text)
    dialog.cancel_btn.Visible = false
    nx_wait_event(100000000, dialog, "exit_game_confirm_return")
    direct_exit_game()
end

function zdnShowLoginDialog()
    local GameInfoCollector = nx_value("GameInfoCollector")
    if not nx_is_valid(GameInfoCollector) then
    end
    local gui = nx_value("gui")
    GTP_set_collector_time(GTP_LUA_FUNC_LOAD_RESOURCE, false, false)
    nx_execute("gameinfo_collector", "GTP_call_func", GTP_LUA_FUNC_LOAD_RESOURCE, true)
    nx_log("entry login...")
    nx_execute("stage", "set_current_stage", "login")
    gui:CheckClientSize()
    nx_function("ext_check_window_pos")
end
