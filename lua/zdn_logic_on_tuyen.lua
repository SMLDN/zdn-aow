require("zdn_util")
require("zdn_lib_moving")

local Running = false
local PICKED_LIST = {}

function IsRunning()
    return Running
end

function Start()
    if Running then
        return
    end
    Running = true
    PICKED_LIST = {}
    while Running do
        loopOnTuyen()
        nx_pause(0.1)
    end
end

function Stop()
    Running = false
    nx_execute("zdn_logic_common_listener", "ResolveListener", nx_current(), "on-task-stop")
end

-- private
function loopOnTuyen()
    local obj = nx_execute("zdn_logic_base", "GetNearestObj", nx_current(), "isFlower", "canPick")
    if nx_is_valid(obj) then
        if GetDistanceToObj(obj) > 1 then
            GoToObj(obj)
            return
        end
        addToPickedList(obj)
    end
end

function isFlower(obj)
    return obj:QueryProp("ConfigID") == "hd_pwq_npc004"
end

function canPick(obj)
    for i = 1, #PICKED_LIST do
        if PICKED_LIST[i] == nx_string(obj) then
            return false
        end
    end
    return true
end

function addToPickedList(obj)
    local n = nx_string(obj)
    for i = 1, #PICKED_LIST do
        if n == PICKED_LIST[i] then
            return
        end
    end
    table.insert(PICKED_LIST, nx_string(obj))
end
