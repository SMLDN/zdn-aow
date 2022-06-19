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
    for i = 1, cnt do
        nx_execute("custom_sender", "custom_pickup_single_item", i)
    end
    nx_pause(0.2)
    nx_execute("custom_sender", "custom_close_drop_box")
end

function FindItemIndexFromVatPham(configId)
    return findItemIndexFromBag(2, configId)
end

function UseItem(viewPort, index)
    nx_execute("custom_sender", "custom_use_item", viewPort, index)
end

-- private
function loopVatPham()
    if IsDroppickShowed() then
        PickAllDropItem()
        return
    end

    for _, item in pairs(ItemList) do
        if not nx_execute("zdn_logic_skill", "HaveBuff", item.buffId) then
            local index = FindItemIndexFromVatPham(item.itemId)
            if index ~= 0 then
                UseItem(2, index)
                nx_pause(0.15)
            end
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
