require("zdn_lib\\util_functions")
require("zdn_util")
require("zdn_lib_moving")
require("zdn_lib_jump")

local Running = false
local QUEST_ID = "ld"
local THROW_POS = {0.17558604478836, 20.536001205444, 12.483154296875}
local CENTER_POS = {-1.5259571075439, 21.753995895386, -24.10789680481}

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
        nx_pause(2)
        return
    end
    if isInQuestScene() then
        doQuest()
    else
        startQuest()
    end
end

function isInQuestScene()
    return GetCurMap() == nx_string("adv126")
end

function startQuest()
    local map = "city04"
    local npcConfigId = "npc_6n_lh_wyhs_join"
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
        XuongNgua()
        TalkToNpc(npc,0)
        TalkToNpc(npc,0)
        TalkToNpc(npc,0)
        return
    end

    if nx_find_custom(npc, "Head_Effect_Flag") and nx_string(npc.Head_Effect_Flag) == nx_string(3) then
        if GetDistanceToObj(npc) > 2 then
            GoToObj(npc)
            return
        end
        XuongNgua()
        TalkToNpc(0)
        return
    end

    if nx_find_custom(npc, "Head_Effect_Flag") and nx_string(npc.Head_Effect_Flag) == nx_string(2) then
        if GetDistanceToObj(npc) > 2 then
            GoToObj(npc)
            return
        end
        XuongNgua()
        TalkToNpc(npc,0)
        TalkToNpc(npc,0)
        onTaskDone()
        return
    end

    if nx_find_custom(npc, "Head_Effect_Flag") and nx_string(npc.Head_Effect_Flag) == nx_string(0) then
        nx_pause(2)
        if nx_find_custom(npc, "Head_Effect_Flag") and nx_string(npc.Head_Effect_Flag) == nx_string(0) then
            onTaskDone()
            return
        end
    end
end

function throwStone(stone)
    if not nx_is_valid(stone) then
        return
    end
    WalkToObjInstantly(stone)
    TalkToNpc(stone, 0)
    WalkToPosInstantly(THROW_POS[1], THROW_POS[2], THROW_POS[3])
    local throwObj = nx_execute("zdn_logic_base", "GetNearestObj", nx_current(), "isThrowObj")
    while Running and not nx_is_valid(throwObj) do
        throwObj = nx_execute("zdn_logic_base", "GetNearestObj", nx_current(), "isThrowObj")
        nx_pause(0.1)
    end
    while Running and nx_execute("zdn_logic_skill", "HaveBuff", "buf_6n_wyhs_cd_01") do
        nx_pause(0.1)
    end
    if not nx_is_valid(throwObj) then
        return
    end
    TalkToNpc(throwObj, 0)
end

function doQuest()
    nx_pause(2)
    local lvl4Stone = nx_execute("zdn_logic_base", "GetNearestObj", nx_current(), "isLvl4Stone")
    throwStone(lvl4Stone)
    local lvl3Stone = nx_execute("zdn_logic_base", "GetNearestObj", nx_current(), "isLvl3Stone")
    throwStone(lvl3Stone)
    while Running and isInQuestScene() do
        local lvl2Stone = nx_execute("zdn_logic_base", "GetNearestObj", nx_current(), "isLvl2Stone")
        if not nx_is_valid(lvl2Stone) then
            WalkToPosInstantly(CENTER_POS[1], CENTER_POS[2], CENTER_POS[3])
            nx_pause(1.5)
            lvl2Stone = nx_execute("zdn_logic_base", "GetNearestObj", nx_current(), "isLvl2Stone")
            if not nx_is_valid(lvl2Stone) then
                break
            end
        end
        throwStone(lvl2Stone)
    end
    while Running and isInQuestScene() do
        local lvl1Stone = nx_execute("zdn_logic_base", "GetNearestObj", nx_current(), "isLvl1Stone")
        if not nx_is_valid(lvl1Stone) then
            WalkToPosInstantly(CENTER_POS[1], CENTER_POS[2], CENTER_POS[3])
            nx_pause(1.5)
            lvl1Stone = nx_execute("zdn_logic_base", "GetNearestObj", nx_current(), "isLvl1Stone")
            if not nx_is_valid(lvl1Stone) then
                break
            end
        end
        throwStone(lvl1Stone)
    end
end

function isLvl4Stone(obj)
    return obj:QueryProp("ConfigID") == "npc_6n_lh_wyhs_smxs04"
end

function isLvl3Stone(obj)
    return obj:QueryProp("ConfigID") == "npc_6n_lh_wyhs_smxs03"
end

function isLvl2Stone(obj)
    return obj:QueryProp("ConfigID") == "npc_6n_lh_wyhs_smxs02"
end

function isLvl1Stone(obj)
    return obj:QueryProp("ConfigID") == "npc_6n_lh_wyhs_smxs01"
end

function isThrowObj(obj)
    return obj:QueryProp("ConfigID") == "npc_6n_lh_wyhs_syc01"
end

function isFirstQuestNpc(obj)
    return obj:QueryProp("ConfigID") == "npc_6n_lh_wyhs_join"
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
