require("zdn_util")

local function zdnAddFixEquippedItemBtn(form)
    if nx_find_custom(form, "zdn_fix_equipped_item_btn") then
        return
    end
    local gui = nx_value("gui")
    if not nx_is_valid(gui) then
        return
    end
    local btn = gui:Create("Button")
    form:Add(btn)
    form.zdn_fix_equipped_item_btn = btn

    btn.NormalImage = "gui\\common\\button\\btn_normal2_out.png"
    btn.FocusImage = "gui\\common\\button\\btn_normal2_on.png"
    btn.PushImage = "gui\\common\\button\\btn_normal2_down.png"

    btn.ForeColor = "255,255,255,255"
    btn.Font = "font_btn"
    btn.Left = 340
    btn.Top = 533
    btn.Width = 105
    btn.Height = 30
    btn.TabStop = "true"
    btn.AutoSize = "true"
    btn.DrawMode = "ExpandH"
    btn.Text = Utf8ToWstr("Sửa đồ nhanh")
    nx_bind_script(btn, nx_current())
    nx_callback(btn, "on_click", "onZdnFixEquippedItemBtnClick")
end

function on_main_form_open(self)
    local gui = nx_value("gui")
    self.AbsLeft = (gui.Width - self.Width) / 10
    self.AbsTop = (gui.Height - self.Height) / 2
    self.content_state = 1
    local rbtn_1 = self.groupbox_3:Find("rbtn_1")
    local rbtn_2 = self.groupbox_3:Find("rbtn_2")
    local rbtn_3 = self.groupbox_3:Find("rbtn_3")
    local rbtn_4 = self.groupbox_3:Find("rbtn_4")
    local rbtn_5 = self.groupbox_3:Find("rbtn_5")
    local rbtn_6 = self.groupbox_3:Find("rbtn_6")
    local rbtn_7 = self.groupbox_3:Find("rbtn_7")
    local rbtn_8 = self.groupbox_3:Find("rbtn_8")
    local rbtn_9 = self.groupbox_3:Find("rbtn_9")
    local rbtn_10 = self.groupbox_3:Find("rbtn_10")
    local rbtn_11 = self.groupbox_3:Find("rbtn_11")
    rbtn_1.ClickEvent = true
    rbtn_2.ClickEvent = true
    rbtn_3.ClickEvent = true
    rbtn_4.ClickEvent = true
    rbtn_5.ClickEvent = true
    rbtn_6.ClickEvent = true
    rbtn_7.ClickEvent = true
    rbtn_8.ClickEvent = true
    rbtn_9.ClickEvent = true
    rbtn_10.ClickEvent = true
    rbtn_11.ClickEvent = true
    self.item_index = 0
    data_bind_prop(self)
    self.rbtn_1.Checked = true
    load_form_rp_arm(self)
    load_form_shengwang(self)
    load_form_others(self)
    load_form_title(self)
    load_form_mount(self)
    load_form_onestep_equip(self)
    load_form_huwei(self)
    load_form_binglu(self)
    load_form_train_pat(self)
    load_form_sable(self)
    load_form_onestep_jingmai(self)
    local is_vip = check_vip_player()
    if nx_int(is_vip) == nx_int(1) then
        self.rbtn_6.Enabled = true
    else
        self.rbtn_6.Enabled = false
    end
    local is_body = check_body_player()
    if is_body == true then
        self.rbtn_11.Enabled = true
    else
        self.rbtn_11.Enabled = false
    end
    zdnAddFixEquippedItemBtn(self)
    return 1
end

function onZdnFixEquippedItemBtnClick()
    nx_execute("zdn_logic_vat_pham", "FixEquippedItemHardiness")
end
