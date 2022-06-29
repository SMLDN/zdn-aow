require("zdn_lib\\util_functions")
require("form_stage_main\\form_task\\task_define")
require("zdn_util")
require("zdn_lib_moving")

local Running = false
local QUEST_ID = "tmc_ctnk"
local NPC_MAP = "school23"
local NPC_CONFIG_ID = "npcmp_lzy_xmg_drrc_001"
local TASK_INDEX = 74252
local CAO_TUONG_COC_TELE_POINT = "GotoDoorxmg_gujxmg01"
local PHA_BAI_DI_TICH_TELE_POINT = "GotoDoorxmg_gujxmg02"
local NPC_THOI_DONG_CONFIG_ID = "npcmp_lzy_xmg_drrc_002"
local TimerFlyingToCaoTuongCoc = 0

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
        doQuest()
        return
    elseif isOnCaoTuongCoc() then
        leaveCaoTuongCoc()
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
        if not TalkIsFuncIdAvailable(npc, 100074252) then
            onTaskDone()
            return
        end
        TalkToNpcByMenuId(npc, 100074252)
        TalkToNpc(npc, 0)
        return
    end
end

function isQuestNpc(obj)
    return obj:QueryProp("ConfigID") == NPC_CONFIG_ID
end

function doQuest()
    if TimerDiff(TimerFlyingToCaoTuongCoc) < 15 then
        return
    end
    if not isOnCaoTuongCoc() then
        local obj = nx_execute("zdn_logic_base", "GetNearestObj", nx_current(), "isCaoTuongCocTelepoint")
        if nx_is_valid(obj) and GetDistanceToObj(obj) <= 1.5 then
            TimerFlyingToCaoTuongCoc = TimerInit()
            return
        end
        GoToNpc(NPC_MAP, CAO_TUONG_COC_TELE_POINT)
        return
    end
    doCaoTuongCoc()
end

function isReceiveQuest()
    local ord = getTaskOrder()
    if nx_is_valid(ord) then
        return false
    end
    return nx_int(ord) == nx_int(1)
end

function getTaskOrder()
    return nx_execute("zdn_logic_base", "GetTaskInfoById", TASK_INDEX, task_rec_order)
end

function isOnCaoTuongCoc()
    local x, _, z = GetPlayerPosition()
    if nx_number(x) > -610 and nx_number(x) < -538 and nx_number(z) > 324 and nx_number(z) < 410 then
        return true
    end
    return false
end

function isCaoTuongCocTelepoint(obj)
    return obj:QueryProp("ConfigID") == CAO_TUONG_COC_TELE_POINT
end

function isPhaBaiDiTichTelepoint(obj)
    return obj:QueryProp("ConfigID") == PHA_BAI_DI_TICH_TELE_POINT
end

function doCaoTuongCoc()
    local npc = nx_execute("zdn_logic_base", "GetNearestObj", nx_current(), "isThoiDong")
    if not nx_is_valid(npc) then
        return
    end
    if nx_find_custom(npc, "Head_Effect_Flag") and nx_string(npc.Head_Effect_Flag) == nx_string(3) then
        if GetDistanceToObj(npc) > 3 then
            GoToObj(npc)
            return
        end
        TalkToNpc(npc, 0)
        return
    end

    if nx_find_custom(npc, "Head_Effect_Flag") and nx_string(npc.Head_Effect_Flag) == nx_string(2) then
        if GetDistanceToObj(npc) > 3 then
            GoToObj(npc)
            return
        end
        TalkToNpc(npc, 0)
        TalkToNpc(npc, 0)
        return
    end

    if nx_find_custom(npc, "Head_Effect_Flag") and nx_string(npc.Head_Effect_Flag) == nx_string(0) then
        nx_pause(3)
        if not nx_is_valid(npc) then
            return
        end
        if nx_find_custom(npc, "Head_Effect_Flag") and nx_string(npc.Head_Effect_Flag) == nx_string(0) then
            leaveCaoTuongCoc()
            return
        end
    end
end

function isThoiDong(obj)
    return obj:QueryProp("ConfigID") == NPC_THOI_DONG_CONFIG_ID
end

function leaveCaoTuongCoc()
    if TimerDiff(TimerFlyingToCaoTuongCoc) < 15 then
        return
    end
    local obj = nx_execute("zdn_logic_base", "GetNearestObj", nx_current(), "isPhaBaiDiTichTelepoint")
    if nx_is_valid(obj) and GetDistanceToObj(obj) <= 1.5 then
        TimerFlyingToCaoTuongCoc = TimerInit()
        return
    end
    GoToNpc(NPC_MAP, PHA_BAI_DI_TICH_TELE_POINT)
end
