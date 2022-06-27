require("zdn_lib\\util_functions")
require("zdn_util")
require("zdn_lib_moving")
require("zdn_lib_jump")

local Running = false
local QUEST_ID = "ld"
local THROW_POS = {0.17558604478836, 20.536001205444, 12.483154296875}
local CENTER_POS = {-1.5259571075439, 21.753995895386, -24.10789680481}
local NPC_POS_FIX = {1138.9156494141, -15.235137939453, 657.68249511719}
local Level4Flg = false
local Level3Flg = false
local Level2Flg = false
local TimerWentCenter = 0

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
    Level4Flg = false
    Level3Flg = false
    Level2Flg = false
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
        -- GoToNpc(map, npcConfigId)
        GoToPosition(NPC_POS_FIX[1], NPC_POS_FIX[2], NPC_POS_FIX[3])
        return
    end

    -- trang thai npc:5 nhan Q
    if nx_find_custom(npc, "Head_Effect_Flag") and nx_string(npc.Head_Effect_Flag) == nx_string(5) then
        if GetDistanceToObj(npc) > 6 then
            -- GoToObj(npc)
            GoToPosition(NPC_POS_FIX[1], NPC_POS_FIX[2], NPC_POS_FIX[3])
            return
        end
        XuongNgua()
        TalkToNpc(npc, 0)
        TalkToNpc(npc, 0)
        TalkToNpc(npc, 0)
        return
    end

    if nx_find_custom(npc, "Head_Effect_Flag") and nx_string(npc.Head_Effect_Flag) == nx_string(3) then
        if GetDistanceToObj(npc) > 6 then
            -- GoToObj(npc)
            GoToPosition(NPC_POS_FIX[1], NPC_POS_FIX[2], NPC_POS_FIX[3])
            return
        end
        XuongNgua()
        TalkToNpc(npc, 0)
        return
    end

    if nx_find_custom(npc, "Head_Effect_Flag") and nx_string(npc.Head_Effect_Flag) == nx_string(2) then
        if GetDistanceToObj(npc) > 6 then
            -- GoToObj(npc)
            GoToPosition(NPC_POS_FIX[1], NPC_POS_FIX[2], NPC_POS_FIX[3])
            return
        end
        XuongNgua()
        TalkToNpc(npc, 0)
        TalkToNpc(npc, 0)
        onTaskDone()
        return
    end

    if nx_find_custom(npc, "Head_Effect_Flag") and nx_string(npc.Head_Effect_Flag) == nx_string(0) then
        nx_pause(3)
        if not nx_is_valid(npc) then
            return
        end
        if nx_find_custom(npc, "Head_Effect_Flag") and nx_string(npc.Head_Effect_Flag) == nx_string(0) then
            onTaskDone()
            return
        end
    end
end

function holdingStone()
    return nx_execute("zdn_logic_skill", "HaveBuffPrefix", "buf_6n_wyhs_bst")
end

function doQuest()
    if holdingStone() then
        Console("dang cam da")
        throwStone()
        return
    end
    pickStone()
end

function throwStone()
    if GetDistance(THROW_POS[1], THROW_POS[2], THROW_POS[3]) > 2 then
        WalkToPosInstantly(THROW_POS[1], THROW_POS[2], THROW_POS[3])
        return
    end
    local throwObj = nx_execute("zdn_logic_base", "GetNearestObj", nx_current(), "isThrowObj")
    if not nx_is_valid(throwObj) then
        return
    end
    if nx_execute("zdn_logic_skill", "HaveBuff", "buf_6n_wyhs_cd_01") then
        return
    end
    TalkToNpc(throwObj, 0)
end

function pickStone()
    if not Level4Flg then
        pickSpecificLvlStone(4)
        return
    end
    if not Level3Flg then
        pickSpecificLvlStone(3)
        return
    end
    if not Level2Flg then
        pickSpecificLvlStone(2)
        return
    end
    pickSpecificLvlStone(1)
end

function pickSpecificLvlStone(lvl)
    if TimerDiff(TimerWentCenter) < 5 then
        return
    end
    local checkFunc = "isLvl" .. nx_string(lvl) .. "Stone"
    if holdingStone() then
        return
    end
    local stone = nx_execute("zdn_logic_base", "GetNearestObj", nx_current(), checkFunc)
    if not nx_is_valid(stone) then
        if GetDistance(CENTER_POS[1], CENTER_POS[2], CENTER_POS[3]) > 2 then
            TimerWentCenter = TimerInit()
            WalkToPosInstantly(CENTER_POS[1], CENTER_POS[2], CENTER_POS[3])
        elseif lvl == 2 then
            Level2Flg = true
        end
        return
    end
    if GetDistanceToObj(stone) > 2 then
        WalkToObjInstantly(stone)
        return
    end
    if holdingStone() then
        return
    end
    if lvl == 4 then
        Level4Flg = true
    end
    if lvl == 3 then
        Level3Flg = true
    end
    TalkToNpc(stone, 0)
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
