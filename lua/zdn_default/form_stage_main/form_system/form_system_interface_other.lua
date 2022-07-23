require("zdn_lib\\util_functions")
require("zdn_util")

local function zdnAddPicture(form)
    local gui = nx_value("gui")
    if not nx_is_valid(gui) then
        return
    end
    if not nx_is_valid(form) or not form.Visible then
        return
    end
    local pic = gui:Create("Picture")
    form:Add(pic)
    form.zdn_mount_pic = pic

    pic.ZoomWidth = "0.232420"
    pic.ZoomHeight = "0.193359"
    pic.CenterX = "-1"
    pic.CenterY = "-1"
    pic.Left = 312
    pic.Top = 280
    pic.Width = 40
    pic.Height = 40
    pic.LineColor = "255,128,101,74"
    pic.ShadowColor = "0,0,0,0"
    pic.HintText = Utf8ToWstr("Kéo Tọa kỵ vào đây để thiết lập")

    nx_bind_script(pic, nx_current())
    nx_callback(pic, "on_left_up", "onZdnMountPicLeftClick")
    nx_callback(pic, "on_right_up", "onZdnMountPicRightClick")
end

local function zdnAddLabel(form)
    local gui = nx_value("gui")
    if not nx_is_valid(gui) then
        return
    end
    if not nx_is_valid(form) or not form.Visible then
        return
    end
    local lbl = gui:Create("Label")
    form:Add(lbl)
    form.zdn_mount_lbl = lbl

    lbl.RefCursor = "WIN_HELP"
    lbl.Left = 310
    lbl.Top = 265
    lbl.Width = 40
    lbl.Height = 13
    lbl.ForeColor = "255,128,101,74"
    lbl.ShadowColor = "0,255,0,0"
    lbl.Text = Utf8ToWstr("Tọa kỵ:")
    lbl.Font = "font_text"
end

function onZdnMountPicLeftClick(pic)
    local hand_item = zdnGetHandItem()
    if hand_item ~= nil then
        pic.Image = hand_item.Image
        pic.ZdnConfigID = hand_item.ConfigID
        pic.HintText = util_text(hand_item.ConfigID)
    end
end

function zdnGetHandItem()
    local item = {}
    local gui = nx_value("gui")
    local game_hand = gui.GameHand
    if game_hand:IsEmpty() then
        return nil
    elseif game_hand.Type == "viewitem" then
        local view_obj = zdnGetItem(game_hand.Para1, game_hand.Para2)
        item.ConfigID = view_obj:QueryProp("ConfigID")
        item.Image = game_hand.Image
    else
        game_hand:ClearHand()
        return nil
    end
    game_hand:ClearHand()
    return item
end

function zdnGetItem(view_ident, view_index)
    local game_client = nx_value("game_client")
    if not nx_is_valid(game_client) then
        return
    end
    local view = game_client:GetView(view_ident)
    if not nx_is_valid(view) then
        return
    end
    return view:GetViewObj(view_index)
end

function on_main_form_open(form)
    init_ui_content(form)
    zdnAddLabel(form)
    zdnAddPicture(form)
    zdnLoadConfig(form)
end

function onZdnMountPicRightClick(pic)
    pic.Image = ""
    pic.ZdnConfigID = ""
    pic.HintText = Utf8ToWstr("Kéo Tọa kỵ vào đây để thiết lập")
end

function on_btn_ok_click(form)
    save_to_file(form)
    zdnSaveMount(form)
end

function zdnSaveMount(form)
    local pic = form.zdn_mount_pic
    IniWriteUserConfig("Zdn", "MountConfigId", pic.ZdnConfigID)
    IniWriteUserConfig("Zdn", "MountImage", pic.Image)
    nx_execute("zdn_logic_base", "SetMount", pic.ZdnConfigID)
end

function zdnLoadConfig(form)
    local cId = nx_string(IniReadUserConfig("Zdn", "MountConfigId", ""))
    local img = nx_string(IniReadUserConfig("Zdn", "MountImage", ""))
    local pic = form.zdn_mount_pic
    pic.ZdnConfigID = cId
    pic.Image = img
    pic.HintText = util_text(cId)
end
