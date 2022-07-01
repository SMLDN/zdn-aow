require("zdn_lib\\util_functions")
require("zdn_util")
require("zdn_lib_moving")

local Running = false
local WORMY = 1
local DRY = 16
local WEED = 256
local PLANT = {
    ["Seed"] = {},
    ["Max"] = 9,
    ["Wormy"] = "",
    ["Weed"] = "",
    ["map"] = "",
    ["posX"] = 0,
    ["posY"] = 0,
    ["posZ"] = 0,
    ["Type"] = 2,
    ["Distance"] = 20
}

function IsRunning()
    return Running
end

function Start()
    if Running then
        return
    end
    Running = true
    loadConfig()
    while Running do
        loopFarm()
        nx_pause(0.2)
    end
end

function Stop()
    Running = false
end

-- private
function loopFarm()
    if GetCurMap() ~= PLANT.map then
        GoToMapByPublicHomePoint(PLANT.map)
        return
    end
    if GetDistance(PLANT.posX, PLANT.posY, PLANT.posZ) > (PLANT.Distance + 10) then
        GoToPosition(PLANT.posX, PLANT.posY, PLANT.posZ)
        return
    end
    if nx_execute("zdn_logic_vat_pham", "IsDroppickShowed") then
        nx_execute("zdn_logic_vat_pham", "PickAllDropItem")
        return
    end

    local sick, state = getSickPlant()
    if sick ~= nil then
        treatment(sick, state)
    else
        local ripe = getRipePlant()
        if ripe ~= nil then
            harvest(ripe)
        else
            planted()
        end
    end
end

function loadConfig()
    local game_visual = nx_value("game_visual")
    local player = game_visual:GetPlayer()
    if not nx_is_valid(player) then
        return
    end

    local posStr = IniReadUserConfig("NongPhu", "Position", "")
    if posStr == "" then
        Stop()
        return
    end
    local posProp = util_split_wstring(posStr, ",")
    PLANT.map = nx_string(posProp[1])
    PLANT.posX = nx_number(posProp[2])
    PLANT.posY = nx_number(posProp[3])
    PLANT.posZ = nx_number(posProp[4])

    local seedList = IniReadUserConfig("NongPhu", "SeedList", "")
    if seedList == "" then
        Stop()
        return
    end
    PLANT.Seed = util_split_wstring(seedList, ",")

    local radiusStr = IniReadUserConfig("NongPhu", "Radius", "20")
    local radius = tonumber(nx_string(radiusStr))
    if radius == nil then
        radius = 8
    end
    PLANT.Distance = radius

    PLANT.Wormy = util_text("nongyao10002")
    PLANT.Weed = util_text("nongyao10003")
end

function getSickPlant()
    local npcList = getMyPlantList()
    for _, obj in pairs(npcList) do
        local sick = tonumber(nx_string(obj:QueryProp("CropTempState")))
        if sick == 1 or sick == 256 then
            return obj, sick
        end
    end
    return nil, nil
end

function getMyPlantList()
    local list = {}
    local client = nx_value("game_client")
    local client_player = client:GetPlayer()
    local game_scene = client:GetScene()
    if not nx_is_valid(game_scene) or not nx_is_valid(client_player) then
        return list
    end
    local obj_lst = game_scene:GetSceneObjList()
    local playerName = client_player:QueryProp("Name")
    for i, obj in pairs(obj_lst) do
        local owner = obj:QueryProp("Owner")
        if nx_widestr(owner) == nx_widestr(playerName) then
            table.insert(list, obj)
        end
    end
    return list
end

function treatment(obj, state)
    if GetDistanceToObj(obj) < 1.5 then
        nx_execute("custom_sender", "custom_select", obj.Ident)
        if state == WORMY then
            local wo = getItemIndex(PLANT.Wormy, 123)
            if wo ~= 0 then
                nx_execute("custom_sender", "custom_use_item", 123, wo)
            end
        elseif state == WEED then
            local we = getItemIndex(PLANT.Weed, 123)
            if we ~= 0 then
                nx_execute("custom_sender", "custom_use_item", 123, we)
            end
        else
        end
    else
        GoToObj(obj)
    end
end

function getItemIndex(itemName, bag)
    local game_client = nx_value("game_client")
    local view = game_client:GetView(nx_string(bag))
    if not nx_is_valid(view) then
        return 0
    end
    for i = 1, 100 do
        local viewobj = view:GetViewObj(nx_string(i))
        if nx_is_valid(viewobj) then
            local ConfigID = viewobj:QueryProp("ConfigID")
            if util_text(nx_string(ConfigID)) == itemName then
                return i
            end
        end
    end
    return 0
end

function getRipePlant()
    local resultNpc
    local distance = 9999
    local npcList = getMyPlantList()
    for i, obj in pairs(npcList) do
        local ripe = obj:QueryProp("IsRipe")
        if nx_string(ripe) == nx_string(1) then
            local d = GetDistanceToObj(obj)
            if d < distance then
                distance = d
                resultNpc = obj
            end
        end
    end
    return resultNpc
end

function harvest(obj)
    if isCurseLoading() then
        while isCurseLoading() and Running do
            nx_pause(0.2)
        end
        return
    end
    if GetDistanceToObj(obj) < 1.5 then
        nx_execute("custom_sender", "custom_select", obj.Ident)
        nx_pause(0.6)
    else
        GoToObj(obj)
    end
end

function isCurseLoading()
    local load = nx_value("form_stage_main\\form_main\\form_main_curseloading")
    if nx_is_valid(load) and load.Visible then
        return true
    end
    return false
end

function planted()
    if GetDistance(PLANT.posX, PLANT.posY, PLANT.posZ) < PLANT.Distance then
        gieoHat()
    else
        GoToPosition(PLANT.posX, PLANT.posY, PLANT.posZ)
    end
end

function gieoHat()
    local seed = 0
    for i, child in pairs(PLANT.Seed) do
        seed = getItemIndex(child, 123)
        if seed ~= 0 then
            break
        end
    end
    if seed ~= 0 then
        nx_execute("custom_sender", "custom_use_item", 123, seed)
    end
end
