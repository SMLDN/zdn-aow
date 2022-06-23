require("zdn_lib\\util_functions")
require("zdn_util")
require("zdn_lib_moving")
require("zdn_lib_jump")

local Running = false
local QUEST_ID = "tc"

function IsRunning()
    return Running
end

function CanRun()
    local resetTimeStr = IniReadUserConfig("NhiemVuNoi6", "ResetTime", "")
    if resetTimeStr ~= "" then
        local resetTime = util_split_string(nx_string(resetTimeStr), ";")
        for _, record in pairs(resetTime) do
            local prop = util_split_string(nx_string(record), ",")
            if prop[1] == nx_string(QUEST_ID) then
                return nx_execute("zdn_logic_base", "GetCurrentDayStartTimestamp") >= nx_number(prop[2])
            end
        end
    end
    return true
end

function Start()
    if Running then
        return
    end
    if not CanRun() then
        Stop()
        return
    end
    Running = true
    while Running do
        loopNoi6()
        nx_pause(0.2)
    end
end

function Stop()
    Running = false
    StopFindPath()
    nx_execute("zdn_logic_common_listener", "ResolveListener", nx_current(), "on-task-stop")
end

-- private
function loopNoi6()
    if IsMapLoading() then
        return
    end
    if isInQuestScene() then
        doQuest()
    else
        startQuest()
    end
end

function isInQuestScene()
    return GetCurMap() == nx_string("adv128")
end

function startQuest()
    local map = "city02"
    local npcConfigId = "home_mj_yd"
    if GetCurMap() ~= map then
        GoToMapByPublicHomePoint(map)
        return
    end

    -- tim npc
    local npc = nx_execute("zdn_logic_base", "GetNearestObj", nx_current(), "isFirstQuestNpc")
    if not nx_is_valid(npc) then
        GoToNpc(map, npcConfigId)
        return
    end

    if GetDistanceToObj(npc) < 10 then
        XuongNgua()
    end

    if GetDistanceToObj(npc) > 2 then
        GoToObj(npc)
        return
    end

    -- trang thai npc:5 nhan Q
    acceptQuest(npc)
end

function isFirstQuestNpc(obj)
    return obj:QueryProp("ConfigID") == "home_mj_yd"
end

function isSceneNpc(obj)
    return obj:QueryProp("ConfigID") == "home_mj_leave"
end

function onTaskDone()
    local newResetTimeStr = QUEST_ID .. "," .. nx_execute("zdn_logic_base", "GetNextDayStartTimestamp")
    local resetTimeStr = IniReadUserConfig("NhiemVuNoi6", "ResetTime", "")
    if resetTimeStr ~= "" then
        local resetTime = util_split_string(nx_string(resetTimeStr), ";")
        for _, record in pairs(resetTime) do
            local prop = util_split_string(nx_string(record), ",")
            if prop[1] ~= nx_string(QUEST_ID) then
                newResetTimeStr = nx_string(newResetTimeStr) .. ";"
                newResetTimeStr =
                    nx_string(newResetTimeStr) .. nx_string(prop[1]) .. nx_string(",") .. nx_string(prop[2])
            end
        end
    end
    IniWriteUserConfig("NhiemVuNoi6", "ResetTime", newResetTimeStr)
    Stop()
end

function acceptQuest(npc)
    StopFindPath()
    TalkToNpc(npc, 0)
    TalkToNpc(npc, 0)
    TalkToNpc(npc, 0)
end

function doQuest()
    local npc = nx_execute("zdn_logic_base", "GetNearestObj", nx_current(), "isSceneNpc")
    if not nx_is_valid(npc) then
        return
    end
    -- bat dau q
    if nx_find_custom(npc, "Head_Effect_Flag") and nx_string(npc.Head_Effect_Flag) == nx_string(5) then
        if GetDistanceToObj(npc) > 2 then
            GoToObj(npc)
            return
        end
        startSceneQuest(npc)
        return
    end

    -- dang lam Q
    if nx_find_custom(npc, "Head_Effect_Flag") and nx_string(npc.Head_Effect_Flag) == nx_string(3) then
        processSceneQuest()
        return
    end

    if nx_find_custom(npc, "Head_Effect_Flag") and nx_string(npc.Head_Effect_Flag) == nx_string(2) then
        FlyToObj(npc)
        nx_pause(1)
        finishSceneQuest(npc)
        return
    end
end

function startSceneQuest(npc)
    XuongNgua()
    StopFindPath()
    TalkToNpc(npc, 0)
    TalkToNpc(npc, 0)
    TalkToNpc(npc, 0)
end

function processSceneQuest()
    local client = nx_value("game_client")
    local scene = client:GetScene()
    local objList = scene:GetSceneObjList()
    local target = ""

    for _, obj in pairs(objList) do
        if nx_is_valid(obj) then
            local configId = nx_string(obj:QueryProp("ConfigID"))
            if string.find(configId, "home_mj_") and string.find(configId, "_ts") then
                target = configId
            end
        end
    end
    if target == "" then
        return
    end

    objList = scene:GetSceneObjList()
    for _, obj in pairs(objList) do
        if nx_is_valid(obj) then
            local configId = nx_string(obj:QueryProp("ConfigID"))
            if target ~= configId and string.find(target, configId) then
                selectObj(obj)
            end
        end
    end
    nx_pause(4)
end

function selectObj(obj)
    if not nx_is_valid(obj) then
        return
    end
    if GetDistanceToObj(obj) > 2 then
        FlyToObj(obj)
    end
    if not nx_is_valid(obj) then
        return
    end
    nx_execute("custom_sender", "custom_select", obj.Ident)
    nx_execute("custom_sender", "custom_select", obj.Ident)
    nx_pause(0.3)
end

function finishSceneQuest(npc)
    XuongNgua()
    StopFindPath()
    TalkToNpc(npc,0)
    TalkToNpc(npc,0)
    onTaskDone()
end
