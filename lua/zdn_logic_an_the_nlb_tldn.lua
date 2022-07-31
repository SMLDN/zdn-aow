require("util_functions")
require("zdn_util")
require("zdn_lib_moving")

local Running = false
local task_rec_order = 3
local QUEST_ID = "nlb_tldn"
local NPC_MAP = "school15"
local NPC_CONFIG_ID = "npc_nlb_ww56"
local NPC_KHAI_PHI_CO = "npc_nlb_ww19"
local NPC_NGOA_SAN = "npc_nlb_ww18"
local TASK_INDEX = 21321

function IsRunning()
    return Running
end

function CanRun()
    local resetTimeStr = IniReadUserConfig("AnThe", "ResetTime", "")
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
        loopAnThe()
        nx_pause(0.2)
    end
end

function Stop()
    Running = false
    StopFindPath()
    nx_execute("zdn_logic_skill", "StopAutoAttack")
    nx_execute("zdn_logic_common_listener", "ResolveListener", nx_current(), "on-task-stop")
end

-- private
function onTaskDone()
    local newResetTimeStr = QUEST_ID .. "," .. nx_execute("zdn_logic_base", "GetNextDayStartTimestamp")
    local resetTimeStr = IniReadUserConfig("AnThe", "ResetTime", "")
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
    IniWriteUserConfig("AnThe", "ResetTime", newResetTimeStr)
    Stop()
end

function loopAnThe()
    if IsMapLoading() then
        return
    end

    if GetCurMap() ~= NPC_MAP then
        TeleToSchoolHomePoint()
        return
    end

    if isReceiveQuest() then
        if nx_execute("zdn_logic_base", "CanTaskSubmit", TASK_INDEX) then
            returnToDongPhuongPhieu()
            return
        end
        doQuest()
        return
    end

    local npc = nx_execute("zdn_logic_base", "GetNearestObj", nx_current(), "isQuestNpc")
    if not nx_is_valid(npc) then
        GoToNpc(NPC_MAP, NPC_CONFIG_ID)
        return
    end

    -- trang thai npc:5 nhan Q
    if nx_find_custom(npc, "Head_Effect_Flag") and nx_string(npc.Head_Effect_Flag) == nx_string(5) then
        if GetDistanceToObj(npc) > 3 then
            GoToObj(npc)
            return
        end
        XuongNgua()
        TalkToNpc(npc, 0)
        TalkToNpc(npc, 0)
        return
    end

    -- tra Q
    if nx_find_custom(npc, "Head_Effect_Flag") and nx_string(npc.Head_Effect_Flag) == nx_string(2) then
        if GetDistanceToObj(npc) > 3 then
            GoToObj(npc)
            return
        end
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

function isReceiveQuest()
    return nx_execute("zdn_logic_base", "GetTaskInfoById", TASK_INDEX, 0) == TASK_INDEX
end

function getTaskOrder()
    return nx_execute("zdn_logic_base", "GetTaskInfoById", TASK_INDEX, task_rec_order)
end

function doQuest()
    local npc = nx_execute("zdn_logic_base", "GetNearestObj", nx_current(), "isKhaiPhiCoNpc")
    if not nx_is_valid(npc) then
        GoToNpc(NPC_MAP, NPC_KHAI_PHI_CO)
        return
    end

    if nx_find_custom(npc, "Head_Effect_Flag") and nx_string(npc.Head_Effect_Flag) == nx_string(1) then
        if GetDistanceToObj(npc) > 3 then
            GoToObj(npc)
            return
        end
        XuongNgua()
        TalkToNpc(npc, 0)
        TalkToNpc(npc, 0)
        TalkToNpc(npc, 0)
        TalkToNpc(npc, 0)
        return
    end

    attackMaNo()
end

function isQuestNpc(obj)
    return obj:QueryProp("ConfigID") == NPC_CONFIG_ID
end

function isKhaiPhiCoNpc(obj)
    return obj:QueryProp("ConfigID") == NPC_KHAI_PHI_CO
end
function isMaNo(obj)
    return obj:QueryProp("ConfigID") == "npc_nlb_ww58"
end

function attackMaNo()
    local obj = nx_execute("zdn_logic_base", "GetNearestObj", nx_current(), "isMaNo")
    if not nx_is_valid(obj) then
        return
    end
    nx_execute("zdn_logic_base", "SelectTarget", obj)
    nx_execute("zdn_logic_skill", "FlexAttack")
end

function returnToDongPhuongPhieu()
    if isInLong() then
        nx_execute("zdn_logic_skill", "StopAutoAttack")
        outLong()
        return
    end
    local npc = nx_execute("zdn_logic_base", "GetNearestObj", nx_current(), "isQuestNpc")
    if not nx_is_valid(npc) then
        GoToNpc(NPC_MAP, NPC_CONFIG_ID)
        return
    end
    if GetDistanceToObj(npc) > 3 then
        GoToObj(npc)
        return
    end
    XuongNgua()
    TalkToNpc(npc, 0)
    TalkToNpc(npc, 0)
end

function isNgoaSanNpc(obj)
    return obj:QueryProp("ConfigID") == NPC_NGOA_SAN
end

function isInLong()
    local x, _, z = GetPlayerPosition()
    return x > 2434 and x < 2452 and z > 746 and z < 761
end

function outLong()
    local npc = nx_execute("zdn_logic_base", "GetNearestObj", nx_current(), "isNgoaSanNpc")
    if not nx_is_valid(npc) then
        return
    end
    if GetDistanceToObj(npc) > 3 then
        GoToObj(npc)
        return
    end
    -- tra Q
    if nx_find_custom(npc, "Head_Effect_Flag") and nx_string(npc.Head_Effect_Flag) == nx_string(2) then
        if GetDistanceToObj(npc) > 3 then
            GoToObj(npc)
            return
        end
        TalkToNpc(npc, 0)
        TalkToNpc(npc, 0)
        onTaskDone()
        return
    end
end
