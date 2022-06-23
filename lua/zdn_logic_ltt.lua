require("zdn_lib_moving")
require("zdn_lib_jump")

local Running = false
local LADDER_POS = {535.17767333984, 116.4740447998, 188.96406555176}
local LADDER_UPPER_POS_Y = 135.82707214355
local UPPER_POS = {540.52563476563, 145.79000854492, 188.92681884766}
local LTT_SCENE_NPC_POS_Y_THRESHOLD = 145
local schoolIndex = 0

function IsRunning()
    return Running
end

function CanRun()
    return not IsTaskDone()
end

function IsTaskDone()
    local resetTimeStr = IniReadUserConfig("LangTieuThanh", "ResetTime", "")
    if resetTimeStr == "" then
        return false
    end
    return nx_execute("zdn_logic_base", "GetCurrentWeekStartTimestamp") < nx_number(resetTimeStr)
end

function Start()
    if Running then
        return
    end
    Running = true
    schoolIndex = 0
    while Running do
        loopLtt()
        nx_pause(0.1)
    end
end

function Stop()
    Running = false
    nx_execute("Listener", "removeListen", nx_current(), "newworld_lingxia_biwunpc_002_talk_043", "nextSchool")
    nx_execute("zdn_logic_skill", "StopAutoAttack")
    StopFindPath()
    nx_execute("zdn_logic_common_listener", "ResolveListener", nx_current(), "on-task-stop")
end

function loopLtt()
    if not CanRun() then
        Stop()
        return
    end
    if IsMapLoading() then
        return
    end
    if isInBossScene() then
        doBossScene()
    elseif isInLttScene() then
        doLttScene()
    else
        goToLttScene()
    end
end

function isOnLadder()
    local role = nx_value("role")
    if not nx_is_valid(role) then
        return false
    end
    return role.state == "link_stop"
end

function goToLadder()
    if GetDistance(LADDER_POS[1], LADDER_POS[2], LADDER_POS[3]) < 10 then
        XuongNgua()
    end
    local x, y, z = GetPlayerPosition()
    if (LADDER_UPPER_POS_Y - y < 1 and LADDER_UPPER_POS_Y - y > 0) or LADDER_UPPER_POS_Y - y < -1 then
        HighJumpToPos(UPPER_POS[1], UPPER_POS[2], UPPER_POS[3])
        return
    end
    if isOnLadder() then
        return
    end
    if GetDistance(LADDER_POS[1], LADDER_POS[2], LADDER_POS[3]) > 1 then
        GoToPosition(LADDER_POS[1], LADDER_POS[2], LADDER_POS[3])
        return
    end
    StopFindPath()
    local role = nx_value("role")
    if not nx_is_valid(role) or role.state ~= "static" then
        return
    end
    nx_call("player_state\\state_input", "emit_player_input", role, 9)
end

function doLttScene()
    local itemForm = nx_value("form_stage_main\\form_give_item")
    if nx_is_valid(itemForm) and itemForm.Visible and nx_find_custom(itemForm, "btn_mail") then
        local btn = itemForm.btn_mail
        nx_execute("form_stage_main\\form_give_item", "on_btn_mail_click", btn)
        return
    end
    local map = "scene25"
    local npcConfigId = "newworld_lingxia_biwunpc_001"
    local npc = nx_execute("zdn_logic_base", "GetNearestObj", nx_current(), "isLttScenceNpc")
    nx_execute("zdn_logic_skill", "PauseAttack")
    local x, y, z = GetPlayerPosition()
    if y < LTT_SCENE_NPC_POS_Y_THRESHOLD then
        goToLadder()
    else
        goToLttSceneNpc()
    end
end

function goToLttSceneNpc()
    local map = "scene25"
    local npcConfigId = "newworld_lingxia_biwunpc_001"
    local npc = nx_execute("zdn_logic_base", "GetNearestObj", nx_current(), "isLttScenceNpc")
    nx_execute("zdn_logic_skill", "PauseAttack")
    if not nx_is_valid(npc) or GetDistanceToObj(npc) > 3 then
        GoToNpc(map, npcConfigId)
    else
        TalkToNpc(npc, 0)
    end
end

function isLttScenceNpc(obj)
    return obj:QueryProp("ConfigID") == "newworld_lingxia_biwunpc_001"
end

function isInLttScene()
    return GetCurMap() == "scene25"
end

function isInBossScene()
    local npc = nx_execute("zdn_logic_base", "GetNearestObj", nx_current(), "isBossSceneNpc")
    if nx_is_valid(npc) then
        return true
    end
    nx_pause(2)
    npc = nx_execute("zdn_logic_base", "GetNearestObj", nx_current(), "isBossSceneNpc")
    if nx_is_valid(npc) then
        return true
    end
    return false
end

function isBossSceneNpc(obj)
    return obj:QueryProp("ConfigID") == "newworld_lingxia_biwunpc_002"
end

function goToLttScene()
    local map = "city02"
    local transNpcConfigId = "NPC_lx_trans_02"
    if GetCurMap() ~= map then
        GoToMapByPublicHomePoint(map)
        return
    end
    local npc = nx_execute("zdn_logic_base", "GetNearestObj", nx_current(), "isTransNpc")
    if not nx_is_valid(npc) or GetDistanceToObj(npc) > 3 then
        GoToNpc(map, transNpcConfigId)
        return
    end
    TalkToNpc(npc, 0)
    TalkToNpc(npc, 0)
end

function isTransNpc(obj)
    return obj:QueryProp("ConfigID") == "NPC_lx_trans_02"
end

function doBossScene()
    local attackNpc = nx_execute("zdn_logic_base", "GetNearestObj", nx_current(), "isBossSceneAttackNpc")
    if not nx_is_valid(attackNpc) then
        nx_pause(5)
        attackNpc = nx_execute("zdn_logic_base", "GetNearestObj", nx_current(), "isBossSceneAttackNpc")
    end
    if nx_is_valid(attackNpc) then
        doAttackNpc(attackNpc)
        return
    end
    nx_execute("zdn_logic_skill", "PauseAttack")
    if TimerDiff(TimerWaitForTalk) > 4 then
        selectCurrentSchoolIndex()
    end
end

function isWaitingForTalkResult()
    return
end

function nextSchool()
    if not Running then
        return
    end
    schoolIndex = schoolIndex + 1
    if schoolIndex >= 9 then
        onTaskDone()
        return
    end
    selectCurrentSchoolIndex()
end

function selectCurrentSchoolIndex()
    local handlerNpc = nx_execute("zdn_logic_base", "GetNearestObj", nx_current(), "isBossSceneNpc")
    if not nx_is_valid(handlerNpc) then
        return
    end
    if GetDistanceToObj(handlerNpc) > 3 then
        WalkToObjInstantly(handlerNpc)
    end
    TimerWaitForTalk = TimerInit()
    TalkToNpc(handlerNpc, 0)
    nx_execute("Listener", "addListen", nx_current(), "newworld_lingxia_biwunpc_002_talk_043", "nextSchool", 4)
    TalkToNpc(handlerNpc, schoolIndex)
end

function isBossSceneAttackNpc(obj)
    local configId = obj:QueryProp("ConfigID")
    if string.find(configId, "JH_lingxiaocheng_attack_") ~= nil then
        return true
    end
    return false
end

function checkHpAndMp()
    local client = nx_value("game_client")
    local player = client:GetPlayer()
    if not nx_is_valid(player) then
        return false
    end
    if nx_string(player:QueryProp("LogicState")) == nx_string("1") then
        return true
    end
    local hpRatio = nx_number(player:QueryProp("HPRatio"))
    local mpRatio = nx_number(player:QueryProp("MPRatio"))
    if hpRatio < 95 or mpRatio < 95 then
        nx_execute("zdn_logic_skill", "NgoiThien")
        return false
    else
        nx_execute("zdn_logic_skill", "StopNgoiThien")
        return true
    end
end

function doAttackNpc(npc)
    if not isAttackable(npc) then
        nx_execute("zdn_logic_skill", "PauseAttack")
        local handlerNpc = nx_execute("zdn_logic_base", "GetNearestObj", nx_current(), "isBossSceneNpc")
        if nx_is_valid(handlerNpc) then
            WalkToObjInstantly(handlerNpc)
        end
        checkHpAndMp()
        return
    end
    if not checkHpAndMp() then
        return
    end
    nx_execute("zdn_logic_base", "SelectTarget", npc)
    if GetDistanceToObj(npc) > 2.8 then
        nx_execute("zdn_logic_skill", "PauseAttack")
        WalkToObj(npc)
    end
    if nx_execute("zdn_logic_skill", "IsRunning") then
        nx_execute("zdn_logic_skill", "ContinueAttack")
    else
        nx_execute("zdn_logic_skill", "AutoAttackDefaultSkillSet")
    end
end

function isAttackable(obj)
    local fight = nx_value("fight")
    local client = nx_value("game_client")
    local player = client:GetPlayer()
    if not nx_is_valid(fight) or not nx_is_valid(player) then
        return false
    end
    return fight:CanAttackTarget(player, obj)
end

function onTaskDone()
    IniWriteUserConfig("LangTieuThanh", "ResetTime", nx_execute("zdn_logic_base", "GetNextWeekStartTimestamp"))
    Stop()
end
