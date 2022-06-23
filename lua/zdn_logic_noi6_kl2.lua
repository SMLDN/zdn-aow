require("zdn_lib\\util_functions")
require("zdn_util")
require("zdn_lib_moving")
require("zdn_lib_jump")

local Running = false
local QUEST_ID = "kl2"
local PosList = {
    {1438.3466796875, 2.1942369937897, 656.18218994141},
    {1439.9655761719, 3.8760001659393, 616.54498291016},
    {1447.4327392578, -1.1019999980927, 568.77484130859},
    {1406.9519042969, 6.230583190918, 539.98095703125},
    {1405.7487792969, 3.7520000934601, 500.52453613281},
    {1409.2293701172, 10.776901245117, 467.10330200195},
    {1420.6684570313, 17.058000564575, 431.87313842773},
    {1431.0660400391, 18.256000518799, 398.4660949707},
    {1455.4047851563, 17.40484046936, 370.15502929688},
    {1477.0603027344, 15.282676696777, 342.876953125},
    {1502.2265625, 13.727027893066, 320.2326965332},
    {1523.2958984375, 15.38143157959, 310.6162109375},
    {1542.3529052734, 16.672925949097, 311.94464111328},
    {1553.4243164063, 17.444000244141, 328.41052246094}
}

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
    return GetCurMap() == nx_string("adv127")
end

function doQuest()
    local npc = nx_execute("zdn_logic_base", "GetNearestObj", nx_current(), "isSceneNpc")
    if not nx_is_valid(npc) then
        flyToQuestNpc()
        nx_pause(1)
        return
    end

    npc = nx_execute("zdn_logic_base", "GetNearestObj", nx_current(), "isSceneNpc")
    if not nx_is_valid(npc) then
        return
    end

    exitQuestScene(npc)
end

function startQuest()
    local map = "city03"
    local npcConfigId = "jddb_npc_01"
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

    -- trang thai npc:5 nhan Q
    if nx_find_custom(npc, "Head_Effect_Flag") and nx_string(npc.Head_Effect_Flag) == nx_string(5) then
        if GetDistanceToObj(npc) > 2 then
            GoToObj(npc)
            return
        end
        acceptQuest(npc)
        return
    end

    -- trang thai npc:5 Q da xong
    if nx_find_custom(npc, "Head_Effect_Flag") and nx_string(npc.Head_Effect_Flag) == nx_string(2) then
        if GetDistanceToObj(npc) > 2 then
            GoToObj(npc)
            return
        end
        finishQuest(npc)
        return
    end

    -- trang thai npc:5 dang lam Q
    if nx_find_custom(npc, "Head_Effect_Flag") and nx_string(npc.Head_Effect_Flag) == nx_string(3) then
        if GetDistanceToObj(npc) > 2 then
            GoToObj(npc)
            return
        end
        enterQuestScene(npc)
        return
    end

    if nx_find_custom(npc, "Head_Effect_Flag") and nx_string(npc.Head_Effect_Flag) == nx_string(0) then
        nx_pause(2)
        if nx_find_custom(npc, "Head_Effect_Flag") and nx_string(npc.Head_Effect_Flag) == nx_string(0) then
            onTaskDone()
        end
    end
end

function acceptQuest(npc)
    XuongNgua()
    StopFindPath()
    TalkToNpc(npc,0)
    TalkToNpc(npc,0)
    nx_pause(0.5)
end

function finishQuest(npc)
    XuongNgua()
    StopFindPath()
    TalkToNpc(npc,0)
    TalkToNpc(npc,0)
end

function enterQuestScene(npc)
    XuongNgua()
    StopFindPath()
    TalkToNpc(npc,0)
    TalkToNpc(npc,0)
    nx_pause(4)
end

function isFirstQuestNpc(obj)
    return obj:QueryProp("ConfigID") == "jddb_npc_01"
end

function isSceneNpc(obj)
    return obj:QueryProp("ConfigID") == "jddb_npc_03"
end

function flyToQuestNpc()
    for i = 1, #PosList do
        if not Running then
            return
        end
        FlyToPos(PosList[i][1], PosList[i][2], PosList[i][3])
        nx_pause(0.5)
    end
end

function exitQuestScene(npc)
    XuongNgua()
    StopFindPath()
    TalkToNpc(npc,0)
    TalkToNpc(npc,0)
    TalkToNpc(npc,0)
    nx_pause(4)
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
