function on_main_form_open(self)
    self.groupbox_key.Visible = true
    change_form_size()
    self.pbar_time.Maximum = 100
    self.pbar_time.Value = 0
    self.speed = nx_number(self.pbar_time.Maximum / (self.time / 0.03))
    local common_execute = nx_value("common_execute")
    if nx_is_valid(common_execute) then
        common_execute:AddExecute("TeamDance", self, nx_float(0.03), form_name)
    end
    local form_chat = util_get_form("form_stage_main\\form_main\\form_main_chat", false)
    if nx_is_valid(form_chat) then
        nx_execute("form_stage_main\\form_main\\form_main_chat", "hide_chat_edit", form_chat)
    end
    on_refresh_picture(self)
    nx_execute("custom_sender", "custom_shijia_qte", 1)
end
