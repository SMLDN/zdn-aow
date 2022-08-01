require("util_functions")
require("zdn_lib_moving")

local function distance2d(bx, bz, dx, dz)
    return math.sqrt((dx - bx) * (dx - bx) + (dz - bz) * (dz - bz))
end

function on_btn_zw_click(btn)
    local form = btn.ParentForm
    if on_is_jh_scene() then
        return
    end
    local form_shop = nx_value("form_stage_main\\form_shop\\form_shop")
    if nx_is_valid(form_shop) then
        nx_execute("custom_sender", "custom_open_mount_shop", 0)
        form.mountshop_opt = 0
    else
        nx_execute("custom_sender", "custom_open_mount_shop", 1)
        form.mountshop_opt = 1
    end
end

function on_bag_right_click(grid, index)
    nx_execute("form_stage_main\\form_bag_func", "on_bag_right_click", grid, index)
    local game_client = nx_value("game_client")
    local toolbox_view = game_client:GetView(nx_string(grid.typeid))
    if not nx_is_valid(toolbox_view) then
        return
    end
    local bind_index = grid:GetBindIndex(index)
    local item = toolbox_view:GetViewObj(nx_string(bind_index))
    if not nx_is_valid(item) then
        return
    end
    if item:QueryProp("ItemType") == 2657 then
        zdnGoToDaoBaoMap(item)
    end
end

function zdnGoToDaoBaoMap(item)
    local x = item:QueryProp("RoyalTreasureX")
    local z = item:QueryProp("RoyalTreasureZ")
    local sId = item:QueryProp("RoyalTreasureSceneID")
    local scenes = get_ini("share\\Rule\\scenes.ini")
    local map = ""
    if not nx_is_valid(scenes) then
        return
    end
    if scenes:FindSection(nx_string(sId)) then
        local i = scenes:FindSectionIndex(nx_string(sId))
        local c = scenes:ReadString(i, "Config", "")
        if c == "" then
            return
        end
        local t1 = util_split_string(c, "\\")
        local ss = t1[#t1]
        local m = util_split_string(ss, "_")
        map = m[1]
        if map == "" then
            return
        end
        if GetCurMap() ~= map then
            GoToMapByPublicHomePoint(map)
            return
        end
        local px, _, pz = GetPlayerPosition()
        if distance2d(px, pz, x, z) <= 1 then
            return
        end
        GoToPosition(x, -10000, z)
    end
end
