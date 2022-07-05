require("zdn_lib\\util_functions")
require("zdn_lib_moving")

local Running = false
local PositionList = {}
local nextPos = 1
local TimerObjNotValid = 0
local TimerCurseLoading = 0

function IsRunning()
    return Running
end

function CanRun()
    return true
end

function IsTaskDone()
    return not CanRun()
end

function Start()
    if Running then
        return
    end
    Running = true
    loadConfig()

    while Running do
        loopThuThap()
        nx_pause(0.2)
    end
end

function Stop()
    Running = false
    StopFindPath()
    nx_execute("zdn_logic_common_listener", "ResolveListener", nx_current(), "on-task-stop")
end

-- private
function loopThuThap()
    if IsMapLoading() then
        return
    end
    if nx_execute("zdn_logic_vat_pham", "IsDroppickShowed") then
        nx_execute("zdn_logic_vat_pham", "PickAllDropItem")
        return
    end
    if isCurseLoading() then
        return
    end
    if nextPos > #PositionList then
        nextPos = 1
    end

    local p = PositionList[nextPos]
    if GetCurMap() ~= p.map then
        GoToMapByPublicHomePoint(p.map)
        return
    end

    if GetDistance(p.x, p.y, p.z) >= 2 then
        GoToPosition(p.x, p.y, p.z)
        return
    end

    StopFindPath()
    local obj = getObjByConfigId(p.configId)
    if nx_is_valid(obj) then
        XuongNgua()
        if not nx_execute("zdn_logic_vat_pham", "IsDroppickShowed") then
            nx_execute("custom_sender", "custom_select", obj.Ident)
            TimerObjNotValid = TimerInit()
        end
    else
        waitTimeOut()
    end
end

function waitTimeOut()
    if TimerDiff(TimerObjNotValid) < 6 then
        return
    end
    if TimerDiff(TimerObjNotValid) < 7 then
        nextPos = nextPos + 1
    end
    TimerObjNotValid = TimerInit()
end

function getObjByConfigId(configId)
    local client = nx_value("game_client")
    local scene = client:GetScene()
    if not nx_is_valid(scene) then
        return
    end
    local objList = scene:GetSceneObjList()
    for _, obj in pairs(objList) do
        if nx_is_valid(obj) and nx_string(obj:QueryProp("ConfigID")) == configId then
            return obj
        end
    end
end

function loadConfig()
    PositionList = {}
    local posStr = IniReadUserConfig("ThuThap", "P", "")
    if posStr ~= "" then
        local posList = util_split_string(nx_string(posStr), ";")
        for _, pos in pairs(posList) do
            local prop = util_split_string(pos, ",")
            if nx_string(prop[1]) == "1" then
                local p = {
                    ["configId"] = prop[2],
                    ["shape"] = prop[3],
                    ["map"] = prop[4],
                    ["x"] = nx_number(prop[5]),
                    ["y"] = nx_number(prop[6]),
                    ["z"] = nx_number(prop[7])
                }
                table.insert(PositionList, p)
            end
        end
        nextPos = 1
    else
        Stop()
    end
end

function isCurseLoading()
    local load = nx_value("form_stage_main\\form_main\\form_main_curseloading")
    if nx_is_valid(load) and load.Visible then
        TimerCurseLoading = TimerInit()
    end
    return TimerDiff(TimerCurseLoading) < 1.5
end
