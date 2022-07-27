require("zdn_util")
require("util_functions")

local ItemList = {}
local Running = false
local TimerCurseLoading = 0
local FORM_DROPPICK_PATH = "form_stage_main\\form_pick\\form_droppick"
local PickItemData = {}
local TimerFixEquippedItem = 0

function Start()
    if not loadConfig() then
        return
    end
    Running = true
    while Running do
        loopVatPham()
        nx_pause(0.1)
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
    while cnt == 0 and TimerDiff(timeOut) < 1.5 do
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
    while nx_is_valid(form) and form.Visible and cnt > 0 and TimerDiff(timeOut) < 1.5 do
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
    if index ~= 0 and not isCurseLoading() then
        nx_execute("custom_sender", "custom_use_item", viewPort, index)
        return true
    end
    return false
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
    for i = 1, 100 do
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

function FindFirstBoundItemIndexByConfigId(viewPort, configId)
    local client = nx_value("game_client")
    local view = client:GetView(nx_string(viewPort))
    if not nx_is_valid(view) then
        return 0
    end
    for i = 1, 100 do
        local obj = view:GetViewObj(nx_string(i))
        if
            nx_is_valid(obj) and nx_string(obj:QueryProp("BindStatus")) == "1" and
                nx_string(obj:QueryProp("ConfigID")) == nx_string(configId)
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

function LoadPickItemData()
    local itemStr = IniReadUserConfig("VatPham", "Pick", "")
    if itemStr ~= "" then
        local itemList = util_split_string(nx_string(itemStr), ";")
        for _, item in pairs(itemList) do
            local prop = util_split_string(item, ",")
            if prop[1] == "1" then
                table.insert(PickItemData, util_text(prop[2]))
            end
        end
    end
end

function PickItemFromPickItemData()
    if not IsDroppickShowed() then
        return
    end
    local form = nx_value(FORM_DROPPICK_PATH)
    if not nx_is_valid(form) or not form.Visible then
        return
    end
    local cnt = form.nMaxIndexCount
    local timeOut = TimerInit()
    while cnt == 0 and TimerDiff(timeOut) < 1.5 do
        if not nx_is_valid(form) or not form.Visible or not nx_find_custom(form, "nMaxIndexCount") then
            break
        end
        cnt = form.nMaxIndexCount
        nx_pause(0)
    end
    timeOut = TimerInit()
    while nx_is_valid(form) and form.Visible and TimerDiff(timeOut) < 1.5 do
        cnt = form.nMaxIndexCount
        if cnt == 0 then
            break
        end
        local i = getCanPickItemIndex()
        if i == 0 then
            break
        end
        nx_execute("custom_sender", "custom_pickup_single_item", i)
        nx_pause(0)
    end
    nx_execute("custom_sender", "custom_close_drop_box")
end

function FixEquippedItemHardiness()
    if TimerDiff(TimerFixEquippedItem) < 5 then
        ShowText("Đại hiệp xin dừng tay trong ít phút!")
        return
    end
    local client = nx_value("game_client")
    local threshhold = 50
    if not nx_is_valid(client) then
        return
    end
    local equip = client:GetView("1")
    if not nx_is_valid(equip) then
        return
    end
    TimerFixEquippedItem = TimerInit()
    for i = 1, 100 do
        local item = equip:GetViewObj(nx_string(i))
        if nx_is_valid(item) and nx_number(item:QueryProp("Hardiness")) <= threshhold then
            local fixItemIndex = getFixItemIndex()
            if fixItemIndex == 0 then
                return
            end
            nx_execute("custom_sender", "custom_use_item_on_item", 2, fixItemIndex, 1, i)
            nx_pause(0.05)
        end
    end
end

function GetItemPhoto(itemId)
    local toolItemIni = nx_execute("util_functions", "get_ini", "share\\item\\tool_item.ini")
    if not nx_is_valid(toolItemIni) then
        return ""
    end
    local sectionIndexNumber = toolItemIni:FindSectionIndex(itemId)
    if sectionIndexNumber < 0 then
        return ""
    end
    return toolItemIni:ReadString(sectionIndexNumber, "Photo", "")
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
            if not item.noiTuFlg or canUseNoiTuItem(item.buffId) then
                local index = FindItemIndexFromVatPham(item.itemId)
                if UseItem(2, index) then
                    nx_pause(0.1)
                end
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
    for i = 1, 100 do
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
                item.noiTuFlg = false
                if item.buffId == prop[4] then
                    item.noiTuFlg = true
                end
                table.insert(ItemList, item)
                loaded = true
            end
        end
    end
    return loaded
end

function isCurseLoading()
    local load = nx_value("form_stage_main\\form_main\\form_main_curseloading")
    if nx_is_valid(load) and load.Visible then
        TimerCurseLoading = TimerInit()
    end
    return TimerDiff(TimerCurseLoading) < 0.5
end

function getItemFromViewportById(viewPort, id)
    local client = nx_value("game_client")
    local view = client:GetView(nx_string(viewPort))
    if not nx_is_valid(view) then
        return
    end
    return view:GetViewObj(nx_string(id))
end

function getCanPickItemIndex()
    for i = 1, 100 do
        local obj = getItemFromViewportById(80, i)
        if nx_is_valid(obj) and isItemInPickItemData(obj:QueryProp("ConfigID")) then
            return i
        end
    end
    return 0
end

function isItemInPickItemData(configId)
    local cnt = #PickItemData
    for i = 1, cnt do
        if util_text(configId) == PickItemData[i] then
            return true
        end
    end
    return false
end

function getFixItemIndex()
    local i = FindItemIndexFromVatPham("fixitem_004")
    if i > 0 then
        return i
    end
    i = FindItemIndexFromVatPham("fixitem_003")
    if i > 0 then
        return i
    end
    return FindItemIndexFromVatPham("fixitem_002")
end

function canUseNoiTuItem(buffId)
    local game_client = nx_value("game_client")
    if not nx_is_valid(game_client) then
        return true
    end
    local client_player = game_client:GetPlayer()
    if not nx_is_valid(client_player) then
        return true
    end
    local buffer_effect = nx_value("BufferEffect")
    if not nx_is_valid(buffer_effect) then
        return true
    end
    if not client_player:FindRecord("AddWuXueFacultyBufferRec") then
        return true
    end
    local v = 0
    local rownum = client_player:GetRecordRows("AddWuXueFacultyBufferRec")
    for i = 0, rownum - 1 do
        local index = client_player:QueryRecord("AddWuXueFacultyBufferRec", i, 0)
        local b = buffer_effect:GetBufferDescIDByIndex(1, index)
        local l = util_split_wstring(util_text(b), nx_widestr(" "))
        for i = 1, #l do
            v = v + nx_number(l[i])
        end
    end
    local l2 = util_split_wstring(util_text(buffId), nx_widestr(" "))
    for i = 1, #l2 do
        v = v + nx_number(l2[i])
    end
    return v <= 1000
end
