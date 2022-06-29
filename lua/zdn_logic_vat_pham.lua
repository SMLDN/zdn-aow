require("zdn_util")
require("zdn_lib\\util_functions")

local ItemList = {}
local Running = false
local FORM_DROPPICK_PATH = "form_stage_main\\form_pick\\form_droppick"

function Start()
    if not loadConfig() then
        return
    end
    Running = true
    while Running do
        loopVatPham()
        nx_pause(0.2)
    end
end

function IsRunning()
    return Running
end

function Stop()
    Running = false
    nx_execute("zdn_logic_common_listener", "ResolveListener", nx_current(), "on-task-stop")
end

function IsDroppickShowed()
    local form = nx_value(FORM_DROPPICK_PATH)
    return nx_is_valid(form) and form.Visible
end

function PickAllDropItem()
    if not IsDroppickShowed() then
        return
    end
    local form = nx_value(FORM_DROPPICK_PATH)
    if not nx_is_valid(form) or not form.Visible then
        return
    end
    local cnt = form.nMaxIndexCount
    local timeOut = TimerInit()
    while Running and cnt == 0 and TimerDiff(timeOut) < 1.5 do
        if not nx_is_valid(form) or not form.Visible or not nx_find_custom(form, "nMaxIndexCount") then
            break
        end
        cnt = form.nMaxIndexCount
        nx_pause(0)
    end
    for i = 1, cnt do
        nx_execute("custom_sender", "custom_pickup_single_item", i)
    end
    timeOut = TimerInit()
    while Running and nx_is_valid(form) and form.Visible and cnt > 0 and TimerDiff(timeOut) < 1.5 do
        cnt = form.nMaxIndexCount
        nx_pause(0)
    end
    nx_execute("custom_sender", "custom_close_drop_box")
end

function FindItemIndexFromVatPham(configId)
    return findItemIndexFromBag(2, configId)
end

function FindItemIndexFromNhiemVu(configId)
    return findItemIndexFromBag(125, configId)
end

function UseItem(viewPort, index)
    if index ~= 0 then
        nx_execute("custom_sender", "custom_use_item", viewPort, index)
    end
end

function UseWeapon(index)
    if index ~= 0 then
        local grid = nx_value("GoodsGrid")
        if not nx_is_valid(grid) then
            return
        end
        grid:ViewUseItem(121, index, "", "")
    end
end

function FindFirstBoundItemIndexByItemType(viewPort, itemType)
    local client = nx_value("game_client")
    local view = client:GetView(nx_string(viewPort))
    if not nx_is_valid(view) then
        return 0
    end
    for i = 1, 70 do
        local obj = view:GetViewObj(nx_string(i))
        if
            nx_is_valid(obj) and nx_string(obj:QueryProp("BindStatus")) == "1" and
                nx_number(obj:QueryProp("ItemType")) == nx_number(itemType)
         then
            return i
        end
    end
    return 0
end

function GetCurrentWeapon()
    local client = nx_value("game_client")
    if not nx_is_valid(client) then
        return
    end
    local equip = client:GetView("1")
    if not nx_is_valid(equip) then
        return
    end
    return equip:GetViewObj("22")
end

-- private
function loopVatPham()
    if IsDroppickShowed() then
        PickAllDropItem()
        return
    end

    for _, item in pairs(ItemList) do
        if IsDroppickShowed() then
            PickAllDropItem()
        end
        if not nx_execute("zdn_logic_skill", "HaveBuff", item.buffId) then
            local index = FindItemIndexFromVatPham(item.itemId)
            UseItem(2, index)
            nx_pause(0.1)
        end
    end
end

function findItemIndexFromBag(viewPort, configId)
    local client = nx_value("game_client")
    local view = client:GetView(nx_string(viewPort))
    if not nx_is_valid(view) then
        return 0
    end
    for i = 1, 70 do
        local obj = view:GetViewObj(nx_string(i))
        if nx_is_valid(obj) then
            if nx_string(obj:QueryProp("ConfigID")) == configId then
                return i
            end
        end
    end
    return 0
end

function loadConfig()
    ItemList = {}
    local loaded = false
    local itemStr = IniReadUserConfig("VatPham", "List", "")
    if itemStr ~= "" then
        local itemList = util_split_string(nx_string(itemStr), ";")
        for _, item in pairs(itemList) do
            local prop = util_split_string(item, ",")
            if prop[1] == "1" then
                local item = {}
                item.itemId = prop[2]
                item.buffId = prop[3]
                table.insert(ItemList, item)
                loaded = true
            end
        end
    end
    return loaded
end
