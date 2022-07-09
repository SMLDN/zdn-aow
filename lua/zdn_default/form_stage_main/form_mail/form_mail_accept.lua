require("zdn_util")
local Recv_rec_name = "RecvLetterRec"
local LETTER_SYSTEM_TYPE_MIN = 100
local LETTER_SYSTEM_TYPE_MAX = 199
local LETTER_USER_TYPE_MIN = 0
local LETTER_USER_TYPE_MAX = 99

function main_form_open(self)
    zdnAddBtn(self)
    local databinder = nx_value("data_binder")
    if nx_is_valid(databinder) then
        databinder:AddTableBind(
            Recv_rec_name,
            self,
            "form_stage_main\\form_mail\\form_mail_accept",
            "on_mail_manager_refresh"
        )
    end
    request_accept_firend_letter_flag(self)
    return 1
end

function zdnAddBtn(form)
    if nx_find_custom(form, "zdn_delete_empty_mail_btn") then
        return
    end
    local gui = nx_value("gui")
    if not nx_is_valid(gui) then
        return
    end
    local btn = gui:Create("Button")
    form:Add(btn)
    form.zdn_delete_empty_mail_btn = btn

    btn.NormalImage = "gui\\common\\button\\btn_normal2_out.png"
    btn.FocusImage = "gui\\common\\button\\btn_normal2_on.png"
    btn.PushImage = "gui\\common\\button\\btn_normal2_down.png"

    btn.ForeColor = "255,255,255,255"
    btn.Font = "font_btn"
    btn.Left = 228
    btn.Top = 320
    btn.Width = 105
    btn.Height = 30
    btn.TabStop = "true"
    btn.AutoSize = "true"
    btn.DrawMode = "ExpandH"
    btn.Text = Utf8ToWstr("Xóa thư trống")
    nx_bind_script(btn, nx_current())
    nx_callback(btn, "on_click", "onZdnDeleteEmptyBtnClick")
end

function onZdnDeleteEmptyBtnClick(btn)
    local client = nx_value("game_client")
    local player = client:GetPlayer()
    if not nx_is_valid(player) then
        return
    end
    local form = btn.Parent.Parent
    local mailType = form.acceptpage.mail_type

    local rownum = player:GetRecordRows(Recv_rec_name)
    for row = rownum - 1, 0, -1 do
        local postType = nx_number(player:QueryRecord(Recv_rec_name, row, 2))
        local silver = nx_number(player:QueryRecord(Recv_rec_name, row, 6))
        local gold = nx_number(player:QueryRecord(Recv_rec_name, row, 5))
        if silver == 0 and gold == 0 and isTargetedType(postType, mailType) then
            local serialNo = player:QueryRecord(Recv_rec_name, row, 10)
            local appedix = player:QueryRecord(Recv_rec_name, row, 7)
            if appedix == "" then
                nx_execute("custom_sender", "custom_select_letter", 1, serialNo, 1)
                nx_execute("custom_sender", "custom_del_letter", 0, mailType)
            end
        end
    end
end

function isTargetedType(postType, mailType)
    return (nx_int(postType) > nx_int(LETTER_SYSTEM_TYPE_MIN) and nx_int(postType) < nx_int(LETTER_SYSTEM_TYPE_MAX) and
        mailType == 2) or
        (nx_int(postType) > nx_int(LETTER_USER_TYPE_MIN) and nx_int(postType) < nx_int(LETTER_USER_TYPE_MAX) and
            mailType == 1)
end
