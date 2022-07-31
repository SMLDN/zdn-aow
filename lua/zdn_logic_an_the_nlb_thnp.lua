require("util_functions")
require("zdn_util")
require("zdn_lib_moving")

local Running = false
local task_rec_order = 3
local QUEST_ID = "nlb_thnp"
local NPC_MAP = "school15"
local NPC_CONFIG_ID = "npc_nlb_ww02"
local NPC_CHU_THU = "npc_nlb_ww50"
local NPC_TIEU_SU_MUOI = "npc_nlb_ww51"
local KY_HOA = "item_nlb_ww23"
local TASK_INDEX = 21254

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

    if not nx_execute("zdn_logic_base", "CanTaskSubmit", TASK_INDEX) and isReceiveQuest() then
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
    local ord = getTaskOrder()
    return nx_int(ord) == nx_int(1)
end

function getTaskOrder()
    return nx_execute("zdn_logic_base", "GetTaskInfoById", TASK_INDEX, task_rec_order)
end

function doQuest()
    local i = nx_execute("zdn_logic_vat_pham", "FindItemIndexFromNhiemVu", KY_HOA)
    if i > 0 then
        tangKyHoaChoTieuSuMuoi()
        return
    end

    local npc = nx_execute("zdn_logic_base", "GetNearestObj", nx_current(), "isChuThuNpc")
    if not nx_is_valid(npc) then
        GoToNpc(NPC_MAP, NPC_CHU_THU)
        return
    end

    -- start q
    if nx_find_custom(npc, "Head_Effect_Flag") and nx_string(npc.Head_Effect_Flag) == nx_string(1) then
        if GetDistanceToObj(npc) > 3 then
            GoToObj(npc)
            return
        end
        XuongNgua()
        TalkToNpc(npc, 0)
        return
    end
end

function isQuestNpc(obj)
    return obj:QueryProp("ConfigID") == NPC_CONFIG_ID
end

function isChuThuNpc(obj)
    return obj:QueryProp("ConfigID") == NPC_CHU_THU
end

function isTieuSuMuoiNpc(obj)
    return obj:QueryProp("ConfigID") == NPC_TIEU_SU_MUOI
end

function tangKyHoaChoTieuSuMuoi()
    local npc = nx_execute("zdn_logic_base", "GetNearestObj", nx_current(), "isTieuSuMuoiNpc")
    if not nx_is_valid(npc) then
        GoToNpc(NPC_MAP, NPC_TIEU_SU_MUOI)
        return
    end

    -- start q
    if nx_find_custom(npc, "Head_Effect_Flag") and nx_string(npc.Head_Effect_Flag) == nx_string(1) then
        if GetDistanceToObj(npc) > 3 then
            GoToObj(npc)
            return
        end
        XuongNgua()
        TalkToNpc(npc, 0)
        return
    end
end
