require("zdn_lib_moving")
require("zdn_lib_jump")
require("util_functions")

local Running = false
local CLONE_SAVE_REC = "clone_rec_save"
local BOSS_LIST = {
    {"boss_clone035_bshw", 1468.8354492188, 24.177389144897, 258.96395874023},
    {"boss_clone035_dlxw", 1404.1009521484, 23.656002044678, 184.57182312012},
    {"boss_clone035_myfr", 1507.5478515625, 23.461751937866, 153.6309967041}
}
local NEED_OPEN_ITEM = {
    "box_fc_mml_001", -- ma mon lenh
    "box_fc_mml_002", -- ma mon lenh
    "box_fc_hss_001", -- hoang thu thach
    "box_fc_hss_002", -- hoang thu thach
    "box_xmp_fc_01" -- long van cam thach
}
local BUFFER_BOSS_JUMP = {
    {},
    {1462.1048583984, 28.933506011963, 217.05558776855},
    {1466.9127197266, 31.283208847046, 148.8816986084}
}

local SAFETY_POS = {
    {{1477.5596923828, 24.186737060547, 255.86683654785}, {1450.8690185547, 24.090394973755, 266.58248901367}},
    {{1411.0574951172, 23.200632095337, 201.29350280762}, {1405.1953125, 23.200632095337, 167.31872558594}},
    {{1537.5716552734, 23.353530883789, 149.6643371582}, {1507.9750976563, 23.473001480103, 159.42253112793}}
}
local BOSS_BOX_PREFIX = "BossBox_Clone035"
local CloneMap = "clone035"
local TimerEnterClone = 0
local TimerCurseLoading = 0
local TimerOpenReward = 0
local TimerNextStep = 0
local Step = 1
local FinishTurn = 0
local MaxTurn = 1
local PickAllFlg = false

function IsRunning()
    return Running
end

function Start()
    if Running then
        return
    end
    Running = true
    initData()
    loadConfig()
    createTeam()
    while Running do
        loopTdc()
        nx_pause(0.1)
    end
end

function Stop()
    Running = false
    nx_execute("zdn_logic_skill", "StopAutoAttack")
    StopFindPath()
    nx_execute("zdn_logic_common_listener", "ResolveListener", nx_current(), "on-task-stop")
end

-- private
function loopTdc()
    if IsMapLoading() then
        return
    end
    if isCurseLoading() then
        return
    end
    if not isInClone() then
        if TimerDiff(TimerEnterClone) > 5 then
            TimerEnterClone = TimerInit()
            nx_execute("Listener", "addListen", nx_current(), "15906", "resetClone", 10)
            nx_execute("custom_sender", "custom_random_clone", nx_int(4), "ini\\scene\\clone035", nx_int(1))
            Step = 1
        end
        return
    end
    doClone()
end

function isInClone()
    return GetCurMap() == CloneMap
end

function isCurseLoading()
    local load = nx_value("form_stage_main\\form_main\\form_main_curseloading")
    if nx_is_valid(load) and load.Visible then
        TimerCurseLoading = TimerInit()
    end
    return TimerDiff(TimerCurseLoading) < 0.5
end

function doClone()
    if nx_execute("zdn_logic_skill", "IsPlayerDead") then
        nx_execute("custom_sender", "custom_relive", 2)
        Step = 1
        return
    end
    if needPickDropItem() then
        return
    end
    if needOpenReward() then
        PickAllFlg = false
        nx_execute("zdn_logic_skill", "PauseAttack")
        return
    end
    if Step > #BOSS_LIST then
        return
    end
    local obj = nx_execute("zdn_logic_base", "GetNearestObj", nx_current(), "isCurrentStepBoss")
    if not nx_is_valid(obj) then
        local b = BOSS_LIST[Step]
        if needOpenBox() then
            PickAllFlg = true
            return
        end
        if GetDistance(b[2], b[3], b[4]) <= 20 then
            local obj = nx_execute("zdn_logic_base", "GetNearestObj", nx_current(), "isAttackingMeObj")
            if nx_is_valid(obj) then
                attackObj(obj)
            else
                if isReadyToNextBoss() then
                    nx_execute("zdn_logic_skill", "StopNgoiThien")
                else
                    nx_execute("zdn_logic_skill", "NgoiThien")
                    return
                end
                if TimerDiff(TimerNextStep) < 7 then
                    return
                end
                TimerNextStep = TimerInit()
                Step = Step + 1
                if Step > #BOSS_LIST then
                    onDoneTurn()
                end
            end
            return
        end
        goToBoss(b)
        return
    end
    if GetDistanceToObj(obj) > 40 then
        nx_execute("zdn_logic_skill", "PauseAttack")
        goToBoss(BOSS_LIST[Step])
        return
    end
    attackObj(obj)
end

function isCurrentStepBoss(obj)
    if Step > #BOSS_LIST then
        return false
    end
    return obj:QueryProp("ConfigID") == BOSS_LIST[Step][1]
end

function goToBoss(boss)
    local buffer = BUFFER_BOSS_JUMP[Step]
    if buffer[1] ~= nil then
        local bufferDistance = GetDistance(buffer[1], buffer[2], buffer[3])
        if bufferDistance > 5 and GetDistance(boss[2], boss[3], boss[4]) > bufferDistance then
            FlyToPos(buffer[1], buffer[2], buffer[3])
            return
        end
    end
    FlyToPos(boss[2], boss[3], boss[4])
end

function attackObj(obj)
    if needParry(obj) then
        nx_execute("zdn_logic_skill", "PauseAttack")
        nx_execute("zdn_logic_skill", "StartParry")
        goToSafetyPos(obj)
        return
    end
    if GetDistanceToObj(obj) > 2.8 then
        nx_execute("zdn_logic_skill", "PauseAttack")
        GoToObj(obj)
        return
    end
    nx_execute("zdn_logic_base", "SelectTarget", obj)
    if nx_execute("zdn_logic_skill", "IsRunning") then
        StopFindPath()
        nx_execute("zdn_logic_skill", "ContinueAttack")
    else
        nx_execute("zdn_logic_skill", "AutoAttackDefaultSkillSet")
    end
end

function needParry(obj)
    local skillId = nx_string(obj:QueryProp("CurSkillID"))
    if skillId == "skill_clone035_myfr_02" then
        return false
    end
    if skillId ~= nx_string("") and skillId ~= nx_string("0") and skillId ~= nx_string("default_normal_skill") then
        return true
    end
    return false
end

function createTeam()
    local TEAM_REC = "team_rec"
    local client = nx_value("game_client")
    if not nx_is_valid(client) then
        Stop()
        return
    end
    local player = client:GetPlayer()
    if not nx_is_valid(player) then
        Stop()
        return
    end
    local cn = nx_widestr(player:QueryProp("TeamCaptain"))
    if cn == nx_widestr("0") or cn == nx_widestr("") then
        nx_execute("custom_sender", "custom_team_create")
        nx_pause(1)
    end
    if cn == nx_widestr(player:QueryProp("Name")) then
        nx_execute("custom_sender", "custom_set_team_allot_mode", 0)
    end
end

function needOpenReward()
    if TimerDiff(TimerOpenReward) < 3 then
        return true
    end
    if TimerDiff(TimerOpenReward) >= 3 and TimerDiff(TimerOpenReward) <= 4 then
        local form = nx_value("form_stage_main\\form_clone_col_awards")
        if nx_is_valid(form) then
            nx_execute("form_stage_main\\form_clone_col_awards", "on_main_form_close", form)
            return true
        end
    end
    local form = nx_value("form_stage_main\\form_clone_col_awards")
    if nx_is_valid(form) then
        nx_execute("custom_sender", "custom_clone_request_open_col_award")
        TimerOpenReward = TimerInit()
        return true
    end
    local bossChess = nx_execute("zdn_logic_base", "GetNearestObj", nx_current(), "isBossChess")
    if nx_is_valid(bossChess) then
        if GetDistanceToObj(bossChess) > 2 then
            GoToObj(bossChess)
            return true
        end
        nx_execute("custom_sender", "custom_select", bossChess.Ident)
        TimerOpenReward = TimerInit()
        return true
    end
    return false
end

function isBossChess(obj)
    local isClicked = nx_number(obj:QueryProp("Dead")) == 1
    local npcType = nx_number(obj:QueryProp("NpcType"))
    local isBossChess = nx_string(obj:QueryProp("RotatePara")) == "0"
    return (not isClicked) and npcType == 161 and isBossChess
end

function isAttackingMeObj(obj)
    local client = nx_value("game_client")
    if not nx_is_valid(client) then
        return false
    end
    local player = client:GetPlayer()
    if not nx_is_valid(player) then
        return false
    end
    return nx_string(obj:QueryProp("LastObject")) == nx_string(player.Ident)
end

function onDoneTurn()
    FinishTurn = FinishTurn + 1
    IniWriteUserConfig(
        "TDC",
        "FinishTurn",
        nx_string(nx_execute("zdn_logic_base", "GetCurrentWeekStartTimestamp")) .. "," .. nx_string(FinishTurn)
    )
    nx_execute("zdn_logic_common_listener", "ResolveListener", nx_current(), "on-done-turn")
    local CLIENT_SUBMSG_REQUEST_OUT_CLONE = 5
    nx_execute("custom_sender", "custom_random_clone", nx_int(CLIENT_SUBMSG_REQUEST_OUT_CLONE))
    if FinishTurn >= MaxTurn then
        Stop()
    end
end

function initData()
    Step = 1
end

function isReadyToNextBoss()
    local client = nx_value("game_client")
    local player = client:GetPlayer()
    if not nx_is_valid(player) then
        return false
    end
    local hpRatio = nx_number(player:QueryProp("HPRatio"))
    local mpRatio = nx_number(player:QueryProp("MPRatio"))
    if
        ((hpRatio >= 74 and nx_execute("zdn_logic_skill", "HaveBuff", "buf_baosd_01")) or hpRatio >= 95) and
            mpRatio >= 90
     then
        return true
    end
    return false
end

function needOpenBox()
    for i = 1, #NEED_OPEN_ITEM do
        local idx = nx_execute("zdn_logic_vat_pham", "FindItemIndexFromVatPham", NEED_OPEN_ITEM[i])
        if idx ~= 0 then
            nx_execute("zdn_logic_vat_pham", "UseItem", 2, idx)
            PickAllFlg = true
            return true
        end
    end
    return false
end

function resetClone()
    nx_execute("custom_sender", "captain_reset_save_clone", "ini\\scene\\clone035", nx_int(1))
end

function goToSafetyPos(obj)
    local s1 = SAFETY_POS[Step][1]
    local s2 = SAFETY_POS[Step][2]

    if GetDistanceObjToPosition(obj, s1[1], s1[2], s1[3]) > GetDistanceObjToPosition(obj, s2[1], s2[2], s2[3]) then
        WalkToPosInstantly(s1[1], s1[2], s1[3])
    else
        WalkToPosInstantly(s2[1], s2[2], s2[3])
    end
end

function loadConfig()
    nx_execute("zdn_logic_vat_pham", "LoadPickItemData")
    MaxTurn = nx_number(IniReadUserConfig("TDC", "MaxTurn", 1))

    local str = nx_string(IniReadUserConfig("TDC", "FinishTurn", ""))
    local cT = nx_execute("zdn_logic_base", "GetCurrentWeekStartTimestamp")
    FinishTurn = 0
    if str ~= "" then
        local prop = util_split_string(str, ",")
        local t = nx_number(prop[1])
        if t == cT then
            FinishTurn = nx_number(prop[2])
        end
    end
end

function needPickDropItem()
    if nx_execute("zdn_logic_vat_pham", "IsDroppickShowed") then
        if PickAllFlg then
            nx_execute("zdn_logic_vat_pham", "PickAllDropItem")
        else
            nx_execute("zdn_logic_vat_pham", "PickItemFromPickItemData")
        end
        return true
    end
    return false
end
