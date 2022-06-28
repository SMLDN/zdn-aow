require("zdn_lib\\util_functions")
require("zdn_util")
require("zdn_lib_moving")

local Running = false
local QUEST_ID = "tmc_tthd"
local NPC_POS = {-196.96806335449, 249.9920501709, 182.35424804688}
local NPC_CONFIG_ID = "npcmp_lzy_xmg_drrc_001"
local NPC_MAP = "school23"
local TALK_OBJ_LIST = {
    {"npcmp_lzy_xmg_drrc_001_c", false},
    {"npcmp_lzy_xmg_drrc_001_a", false},
    {"npcmp_lzy_xmg_drrc_001_b", false}
}
local QUAN_TINH_DAO_TELE_POINT = "GotoDoorxmg_jch01"
local TINH_MIEU_CAC_TELE_POINT = "GotoDoorxmg_jch02"

local onDoingQuest = false

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
    onDoingQuest = false
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

    if onDoingQuest then
        doQuest()
        return
    elseif isOnQuanTinhDao() then
        GoToNpc(NPC_MAP, TINH_MIEU_CAC_TELE_POINT_TELE_POINT)
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
end

function isQuestNpc(obj)
    return obj:QueryProp("ConfigID") == NPC_CONFIG_ID
end

function doQuest()
    for i = 1, #TALK_OBJ_LIST do
        local state = TALK_OBJ_LIST[i][2]
        if not state then
            runToNpcAndTalk(i)
            return
        end
    end
    if isOnQuanTinhDao() then
        GoToNpc(NPC_MAP, TINH_MIEU_CAC_TELE_POINT)
        return
    end
    onDoingQuest = false
end

function runToNpcAndTalk(i)
    if i == 3 then
        if not isOnQuanTinhDao() then
            GoToNpc(NPC_MAP, QUAN_TINH_DAO_TELE_POINT)
            return
        end
    end
    local npc = nx_execute("zdn_logic_base", "GetNearestObj", nx_current(), "is" .. nx_string(i) .. "QuestTalkObj")
    if not nx_is_valid(npc) then
        GoToNpc(NPC_MAP, TALK_OBJ_LIST[i][1])
        return
    end
    if GetDistanceToObj(npc) > 3 then
        GoToObj(npc)
        return
    end
    if nx_find_custom(npc, "Head_Effect_Flag") and nx_string(npc.Head_Effect_Flag) == nx_string(0) then
        nx_pause(3)
        if not nx_is_valid(npc) then
            return
        end
        if nx_find_custom(npc, "Head_Effect_Flag") and nx_string(npc.Head_Effect_Flag) == nx_string(0) then
            TALK_OBJ_LIST[i][2] = true
            return
        end
    end

    TalkToNpc(npc, 0)
    TalkToNpc(npc, 0)
    TALK_OBJ_LIST[i][2] = true
end

function is1QuestTalkObj(obj)
    return obj:QueryProp("ConfigID") == TALK_OBJ_LIST[1][1]
end

function is2QuestTalkObj(obj)
    return obj:QueryProp("ConfigID") == TALK_OBJ_LIST[2][1]
end

function is3QuestTalkObj(obj)
    return obj:QueryProp("ConfigID") == TALK_OBJ_LIST[3][1]
end

function isOnQuanTinhDao()
    local x, _, z = GetPlayerPosition()
    if nx_number(z) >= 470 and nx_number(x) >= -468 then
        return true
    end
    return false
end
