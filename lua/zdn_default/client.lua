function choose_role(index)
    nx_log("flow client choose_role begin")
    local sock = nx_value("game_sock")
    local gui = nx_value("gui")
    local receiver = sock.Receiver
    if not nx_is_valid(sock) then
        nx_gen_event(nx_null(), "choose_role", "failed")
        return false
    end
    local game_config = nx_value("game_config")
    if not nx_is_valid(game_config) then
        nx_log("[choose role] game config failed.")
        return false
    end
    local receiver = sock.Receiver
    nx_pause(0)
    local role_name = receiver:GetRoleName(index)
    if nx_ws_length(role_name) == "" then
        nx_gen_event(nx_null(), "choose_role", "failed")
        nx_log("flow choose_role failed role_name = empty")
        return false
    end
    local world = nx_value("world")
    if world.land_scene_info ~= "" then
        sock.Sender:ChooseRoleAndScene(nx_widestr(role_name), nx_string(world.land_scene_info))
    else
        sock.Sender:ChooseRole(nx_widestr(role_name))
    end
    nx_log("flow Choose Role...")
    local dialog = util_get_form("form_common\\form_connect", true, false)
    dialog.Top = (gui.Desktop.Height - dialog.Height) / 2
    dialog.Left = (gui.Desktop.Width - dialog.Width) / 2
    dialog.btn_return.Visible = false
    dialog.btn_cancel.Visible = true
    dialog.info_mltbox.HtmlText = gui.TextManager:GetFormatText("ui_choose_role")
    dialog.event_name = "event_entry"
    dialog.lbl_4.Height = dialog.lbl_4.Height + dialog.lbl_6.Height
    dialog.lbl_6.Visible = false
    dialog.lbl_xian.Visible = false
    dialog:ShowModal()
    local res, code = nx_wait_event(30, receiver, "event_entry")
    local bfailed = false
    local log = ""
    local info_stringid = ""
    if res == nil then
        bfailed = true
        log = "Choose Role time out"
        info_stringid = "ui_choose_role_timeout"
        if game_config.switch_server and not game_config.rechoose_role then
            nx_log("[choose role] choose role time out.")
            game_config.rechoose_role = true
            choose_role(index)
            return false
        end
    elseif res == "failed" then
        bfailed = true
        log = "Choose Role failed"
        if code ~= nil then
            info_stringid = nx_string(code)
        else
            info_stringid = "ui_choose_role_failed"
        end
    elseif res == "cancel" then
        bfailed = true
        log = "cancel choose role"
        info_stringid = "ui_choose_role_cancel"
    end
    if bfailed then
        if not nx_is_valid(dialog) then
            return false
        end
        nx_log("flow " .. log)
        gui.TextManager:Format_SetIDName(info_stringid)
        if code ~= nil then
            gui.TextManager:Format_AddParam(nx_int(code))
        end
        local info = gui.TextManager:Format_GetText()
        dialog.info_mltbox.HtmlText = info
        dialog.btn_return.Visible = true
        dialog.btn_cancel.Visible = false
        dialog.lbl_4.Height = dialog.lbl_4.Height - dialog.lbl_6.Height
        dialog.lbl_xian.Visible = true
        dialog.lbl_6.Visible = true
        dialog.event_name = "choose_role_failed"
        zdnAddBtn(dialog)
        nx_wait_event(100000000, dialog, dialog.event_name)
        dialog:Close()
        gui:Delete(dialog)
        nx_gen_event(nx_null(), "choose_role", "failed")
        nx_log("flow choose_role failed receiver event_entry")
        if game_config.switch_server and game_config.rechoose_role then
            nx_log("[choose role] relogin.")
            nx_execute("stage", "set_current_stage", "login")
            nx_execute("client", "close_connect")
        end
        return false
    end
    nx_gen_event(nx_null(), "choose_role", "succeed")
    if nx_is_valid(dialog) then
        dialog:Close()
        gui:Delete(dialog)
    end
    nx_log("flow choose role succeed")
    return true
end

function zdnAddBtn(form)
    local gui = nx_value("gui")
    if not nx_is_valid(gui) then
        return
    end
    local btn = gui:Create("Button")
    form:Add(btn)

    btn.NormalImage = "gui\\common\\button\\btn_normal2_out.png"
    btn.FocusImage = "gui\\common\\button\\btn_normal2_on.png"
    btn.PushImage = "gui\\common\\button\\btn_normal2_down.png"

    btn.ForeColor = "255,255,255,255"
    btn.Font = "font_btn"
    btn.Left = 5
    btn.Top = 165
    btn.Width = 130
    btn.Height = 29
    btn.TabStop = "true"
    btn.AutoSize = "true"
    btn.DrawMode = "ExpandH"
    btn.Text = Utf8ToWstr("Thoát liên server")
    nx_bind_script(btn, nx_current())
    nx_callback(btn, "on_click", "onZdnOutServer")
end

function onZdnOutServer()
    nx_execute("custom_sender", "custom_egwar_trans", nx_number(9))
end
