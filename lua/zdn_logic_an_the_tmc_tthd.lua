require("util_functions")
require("zdn_util")
require("zdn_lib_moving")

local Running = false
local QUEST_ID = "tmc_tthd"
local NPC_POS = {-196.96806335449, 249.9920501709, 182.35424804688}
local NPC_CONFIG_ID = "npcmp_lzy_xmg_drrc_001"
local NPC_MAP = "school23"
local QUAN_TINH_DAO_TELE_POINT = "GotoDoorxmg_jch01"
local TINH_MIEU_CAC_TELE_POINT = "GotoDoorxmg_jch02"
local TASK_INDEX = 74253
local NPC_B_FIX_POS = {-327.05551147461, 211.60801696777, 678.62316894531}
local TimerQuanTinhDao = 0
local TimerLeaveQuanTinhDao = 0

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
        if not nx_execute("zdn_logic_base", "CanTaskSubmit", TASK_INDEX) then
            doQuest()
            return
        end
    elseif isOnQuanTinhDao() then
        leaveQuanTinhDao()
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
        if not TalkIsFuncIdAvailable(npc, 100074253) then
            onTaskDone()
            return
        end
        XuongNgua()
        TalkToNpcByMenuId(npc, 100074253)
        TalkToNpc(npc, 0)
        onDoingQuest = true
        return
    end

    if nx_find_custom(npc, "Head_Effect_Flag") and nx_string(npc.Head_Effect_Flag) == nx_string(3) then
        onDoingQuest = true
        return
    end

    -- tra Q
    if nx_find_custom(npc, "Head_Effect_Flag") and nx_string(npc.Head_Effect_Flag) == nx_string(2) then
        if GetDistanceToObj(npc) > 3 then
            GoToObj(npc)
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

function isQuestNpc(obj)
    return obj:QueryProp("ConfigID") == NPC_CONFIG_ID
end

function doQuest()
    local targetNpc = nx_execute("zdn_logic_base", "FilterTaskInfoById", 74253, 6, 4, nx_string(0))
    if targetNpc ~= nil and string.len(targetNpc) > 4 then
        runToNpcAndTalk(targetNpc)
    end
end

function runToNpcAndTalk(npcConfigId)
    if npcConfigId == "npcmp_lzy_xmg_drrc_001_b" then
        if not isOnQuanTinhDao() then
            goToQuanTinhDao()
            return
        else
            local x, y, z = GetNpcPostion(NPC_MAP, npcConfigId)
            if GetDistance(x, y, z) > 35 then
                GoToPosition(NPC_B_FIX_POS[1], NPC_B_FIX_POS[2], NPC_B_FIX_POS[3])
                return
            end
        end
    elseif isOnQuanTinhDao() then
        leaveQuanTinhDao()
        return
    end
    local npc = nx_execute("zdn_logic_base", "GetNearestObj", nx_current(), "is_" .. nx_string(npcConfigId))
    if not nx_is_valid(npc) then
        GoToNpc(NPC_MAP, npcConfigId)
        return
    end
    if GetDistanceToObj(npc) > 3 then
        GoToObj(npc)
        return
    end
    TalkToNpc(npc, 0)
end

function isOnQuanTinhDao()
    local x, _, z = GetPlayerPosition()
    if nx_number(z) >= 470 and nx_number(x) >= -468 then
        return true
    end
    return false
end

function isReceiveQuest()
    return nx_execute("zdn_logic_base", "GetTaskInfoById", 74253, 0) == 74253
end

function is_npcmp_lzy_xmg_drrc_001_a(obj)
    return obj:QueryProp("ConfigID") == "npcmp_lzy_xmg_drrc_001_a"
end

function is_npcmp_lzy_xmg_drrc_001_b(obj)
    return obj:QueryProp("ConfigID") == "npcmp_lzy_xmg_drrc_001_b"
end

function is_npcmp_lzy_xmg_drrc_001_c(obj)
    return obj:QueryProp("ConfigID") == "npcmp_lzy_xmg_drrc_001_c"
end

function leaveQuanTinhDao()
    if TimerDiff(TimerLeaveQuanTinhDao) < 11 then
        return
    end
    if TimerDiff(TimerLeaveQuanTinhDao) >= 11 and TimerDiff(TimerLeaveQuanTinhDao) < 13 then
        local role = nx_value("role")
        if nx_is_valid(role) and role.state == "static" then
            nx_call("player_state\\state_input", "emit_player_input", role, 9)
        end
        return
    end
    local x, y, z = GetNpcPostion(NPC_MAP, TINH_MIEU_CAC_TELE_POINT)
    if GetDistance(x, y, z) <= 1 then
        TimerLeaveQuanTinhDao = TimerInit()
        return
    end
    GoToNpc(NPC_MAP, TINH_MIEU_CAC_TELE_POINT)
end

function goToQuanTinhDao()
    if TimerDiff(TimerQuanTinhDao) < 7 then
        return
    end
    local x, y, z = GetNpcPostion(NPC_MAP, QUAN_TINH_DAO_TELE_POINT)
    if GetDistance(x, y, z) <= 1 then
        TimerQuanTinhDao = TimerInit()
        return
    end
    GoToNpc(NPC_MAP, QUAN_TINH_DAO_TELE_POINT)
end
