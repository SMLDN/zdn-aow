require("util_functions")
require("zdn_util")
require("zdn_lib_moving")
require("zdn_lib_jump")
local Running = false
local QUEST_ID = "kl1"
local PILES = {}

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
    initConfig()
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

function initConfig()
    piles = {}
end

function startQuest()
    local map = "city03"
    local npc1ConfigId = "npc_6n_cc_sxsl_007"
    local npc2ConfigId = "npc_6n_cc_sxsl_004"
    if GetCurMap() ~= map then
        TeleToHomePoint("HomePointcity03C")
        return
    end

    -- tim npc
    local npc1 = nx_execute("zdn_logic_base", "GetNearestObj", nx_current(), "isFirstQuestNpc")
    if not nx_is_valid(npc1) then
        GoToNpc(map, npc1ConfigId)
        return
    end

    -- trang thai npc:5 nhan Q
    if nx_find_custom(npc1, "Head_Effect_Flag") and nx_string(npc1.Head_Effect_Flag) == nx_string(5) then
        -- den gan npc
        if GetDistanceToObj(npc1) > 2 then
            GoToObj(npc1)
            return
        end
        XuongNgua()
        TalkToNpc(npc1, 0)
        TalkToNpc(npc1, 0)
        return
    end

    if nx_find_custom(npc1, "Head_Effect_Flag") and nx_string(npc1.Head_Effect_Flag) == nx_string(2) then
        if GetDistanceToObj(npc1) > 2 then
            GoToObj(npc1)
            return
        end
        TalkToNpc(npc1, 0)
        TalkToNpc(npc1, 0)
        Stop()
        return
    end

    if nx_find_custom(npc1, "Head_Effect_Flag") and nx_string(npc1.Head_Effect_Flag) == nx_string(0) then
        nx_pause(3)
        if not nx_is_valid(npc1) then
            return
        end
        if nx_find_custom(npc1, "Head_Effect_Flag") and nx_string(npc1.Head_Effect_Flag) == nx_string(0) then
            onTaskDone()
            return
        end
    end

    local npc2 = nx_execute("zdn_logic_base", "GetNearestObj", nx_current(), "isSecondQuestNpc")
    if not nx_is_valid(npc2) then
        GoToNpc(map, npc2ConfigId)
        return
    end

    if GetDistanceToObj(npc2) > 2 then
        GoToObj(npc2)
        return
    end

    XuongNgua()
    TalkToNpc(npc2, 0)
    TalkToNpc(npc2, 0)
    nx_pause(4)
end

function doQuest()
    if not isBossShowed() then
        showBoss()
        nx_pause(3)
        return
    end

    if not isPilesShowed() then
        showPiles()
        return
    end

    if not isAllPilesShowed() then
        return
    end

    if needGetPilesBuffInfo() then
        return
    end

    getBuffAndReturnToBoss()
end

function showBoss()
    showStep(0)
end

function isFirstSceneNpc(obj)
    return obj:QueryProp("ConfigID") == "npc_6n_cc_sxsl_001"
end

function isSecondSceneNpc(obj)
    return obj:QueryProp("ConfigID") == "npc_6n_cc_sxsl_005"
end

function isSceneBossNpc(obj)
    return obj:QueryProp("ConfigID") == "npc_6n_cc_sxsl_boss"
end

function isFirstQuestNpc(obj)
    return obj:QueryProp("ConfigID") == "npc_6n_cc_sxsl_007"
end

function isSecondQuestNpc(obj)
    return obj:QueryProp("ConfigID") == "npc_6n_cc_sxsl_004"
end

function isInQuestScene()
    return GetCurMap() == nx_string("adv121")
end

function returnBuffToBoss(boss)
    if GetDistanceToObj(boss) > 2 then
        GoToObj(boss)
        return
    end
end

function isPileNpc(obj)
    return obj:QueryProp("ConfigID") == "npc_6n_cc_sxsl_npc_001"
end

function needGetPilesBuffInfo()
    if PILES[1] ~= nil then
        return false
    end

    local client = nx_value("game_client")
    local scene = client:GetScene()
    if not nx_is_valid(scene) then
        return false
    end
    local objList = scene:GetSceneObjList()
    for _, obj in pairs(objList) do
        if obj:QueryProp("ConfigID") == "npc_6n_cc_sxsl_npc_001" then
            local pile = {}
            local bList = util_split_string(obj:QueryProp("BufferInfo1"), ",")
            pile.buff = bList[1]
            pile.obj = obj
            if pile.buff == "" then
                return false
            end
            table.insert(PILES, pile)
        end
    end

    return true
end

function isPilesShowed()
    local piles = nx_execute("zdn_logic_base", "GetNearestObj", nx_current(), "isPileNpc")
    if nx_is_valid(piles) then
        return true
    end
    return false
end

function isBossShowed()
    local boss = nx_execute("zdn_logic_base", "GetNearestObj", nx_current(), "isSceneBossNpc")
    if nx_is_valid(boss) then
        return true
    end
    return false
end

function showPiles()
    showStep(1)
end

function showStep(step)
    local npc = nx_execute("zdn_logic_base", "GetNearestObj", nx_current(), "isFirstSceneNpc")
    if not nx_is_valid(npc) then
        return
    end

    if GetDistanceToObj(npc) > 2 then
        FlyToObj(npc)
        return
    end
    TalkToNpc(npc, 0)
    TalkToNpc(npc, step)
    TalkToNpc(npc, 0)
end

function getBuffAndReturnToBoss()
    if not nx_execute("zdn_logic_skill", "HaveBuffPrefix", "buf_6n_cc_sxsl_one_") then
        getBuffFromPiles()
        return
    end

    local boss = nx_execute("zdn_logic_base", "GetNearestObj", nx_current(), "isSceneBossNpc")
    if not nx_is_valid(boss) then
        return
    end
    if GetDistanceToObj(boss) > 2 then
        FlyToObj(boss)
        return
    end
    TalkToNpc(boss, 0)
    TalkToNpc(boss, 0)
    exitQuestScene()
end

function exitQuestScene()
    local npc = nx_execute("zdn_logic_base", "GetNearestObj", nx_current(), "isSecondSceneNpc")
    if not nx_is_valid(npc) then
        return
    end
    if GetDistanceToObj(npc) > 2 then
        FlyToObj(npc)
        nx_pause(0.2)
    end
    TalkToNpc(npc, 0)
    TalkToNpc(npc, 0)
    nx_pause(4)
end

function getBuffFromPiles()
    local boss = nx_execute("zdn_logic_base", "GetNearestObj", nx_current(), "isSceneBossNpc")
    if not nx_is_valid(boss) then
        return
    end
    local bufferList = nx_function("get_buffer_list", boss)
    local bufferCount = table.getn(bufferList) / 2
    for i = 1, bufferCount do
        for j = 1, #PILES do
            if isBuffMatched(PILES[j].buff, bufferList[i * 2 - 1]) then
                takeBuff(PILES[j].obj)
                break
            end
        end
    end
end

function takeBuff(obj)
    if GetDistanceToObj(obj) > 2 then
        FlyToObj(obj)
    end
    nx_execute("custom_sender", "custom_select", obj.Ident)
    nx_pause(0.1)
end

function isBuffMatched(pileBuff, bossBuff)
    local p = util_split_string(pileBuff, "_")
    local b = util_split_string(bossBuff, "_")
    return p[#p] == b[#b]
end

function isAllPilesShowed()
    local client = nx_value("game_client")
    local scene = client:GetScene()
    local cnt = 0
    if not nx_is_valid(scene) then
        return false
    end
    local objList = scene:GetSceneObjList()
    for _, obj in pairs(objList) do
        if obj:QueryProp("ConfigID") == "npc_6n_cc_sxsl_npc_001" then
            cnt = cnt + 1
        end
    end
    return cnt == 9
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
