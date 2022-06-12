require("zdn_lib_moving")

local Running = false
local PRIZE_FORM_PATH = "form_stage_main\\form_xmqy_detail"
local FACULTY_BACK_FORM_PATH = "form_stage_main\\form_wuxue\\form_faculty_back"
local MAIN_REQUEST_FORM_PATH = "form_stage_main\\form_main\\form_main_request"

function IsRunning()
    return Running
end

function CanRun()
    local h = nx_execute("zdn_logic_base", "GetCurrentHour")
    if h < 14 or h >= 22 then
        return false
    end
    local resetTimeStr = IniReadUserConfig("ThienThe", "ResetTime", "")
    if resetTimeStr == "" then
        return true
    end
    return nx_execute("zdn_logic_base", "GetCurrentDayStartTimestamp") >= nx_number(resetTimeStr)
end

function Start()
    if Running then
        return
    end
    nx_execute("Listener", "addListen", nx_current(), "1000272", "onTaskDone", -1)
    Running = true
    while Running do
        loopThienThe()
        nx_pause(0.2)
    end
end

function Stop()
    Running = false
    nx_execute("Listener", "removeListen", nx_current(), "1000272", "onTaskDone")
    nx_execute("zdn_logic_skill", "StopAutoAttack")
    nx_execute("zdn_logic_common_listener", "ResolveListener", nx_current(), "on-task-stop")
end

function loopThienThe()
    if IsMapLoading() then
        return
    end
    if isInMatchScene() then
        doMatchScene()
    else
        prepareForMatch()
    end
end

function doMatchScene()
    if needSelectTaolu() then
        return
    end
    if needPressStartMatch() then
        return
    end
    local obj = nx_execute("zdn_logic_base", "GetNearestObj", nx_current(), "isAttackable")
    if not nx_is_valid(obj) then
        nx_execute("zdn_logic_skill", "PauseAttack")
        return
    end
    if GetDistanceToObj(obj) < 2.8 then
        nx_execute("zdn_logic_base", "SelectTarget", obj)
        if (nx_execute("zdn_logic_skill", "IsRunning")) then
            nx_execute("zdn_logic_skill", "ContinueAttack")
        else
            nx_execute("zdn_logic_skill", "AutoAttackDefaultSkillSet")
        end
    else
        nx_execute("zdn_logic_skill", "PauseAttack")
        nx_execute("zdn_lib_moving", "WalkToObj", obj)
    end
end

function needPressStartMatch()
    local form = nx_value("form_stage_main\\form_match\\form_war_ready")
    if nx_is_valid(form) and form.Visible == true then
        local btn = form.btn_ready
        nx_execute("form_stage_main\\form_match\\form_war_ready", "on_btn_ready_click", btn)
        return true
    end
    return false
end

function needSelectTaolu()
    local form = nx_value("form_stage_main\\form_match\\form_taolu_confirm_new")
    if nx_is_valid(form) and form.Visible == true then
        nx_pause(2)
        local btn = form.btn_submit
        nx_execute("form_stage_main\\form_match\\form_taolu_confirm_new", "on_btn_submit_click", btn)
        return true
    end
    return false
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

function prepareForMatch()
    if IsMapLoading() then
        TimerMapLoading = TimerInit()
        return
    end
    if TimerDiff(TimerMapLoading) < 6 then
        return
    end
    if processPrizeForm() then
        return
    end
    if receivedMatchRequest() then
        acceptMatchRequest()
        TimerRegisterMatch = TimerInit()
        return
    end
    if TimerDiff(TimerRegisterMatch) > 12 then
        TimerRegisterMatch = TimerInit()
        nx_execute("custom_sender", "custom_revenge_match", "2", "")
    end
end

function receivedMatchRequest()
    local nMax = nx_execute(MAIN_REQUEST_FORM_PATH, "get_request_prop", 0)
    for i = 1, nMax do
        if nx_execute(MAIN_REQUEST_FORM_PATH, "get_request_prop", i, 1) == 69 then
            nx_execute(MAIN_REQUEST_FORM_PATH, "remove_request", i)
            return true
        end
    end
    return false
end

function acceptMatchRequest()
    local egwar = nx_value("EgWarModule")
    if nx_is_valid(egwar) then
        nx_execute(
            "custom_sender",
            "custom_egwar_trans",
            1,
            egwar.CrossServerID,
            egwar.WarName,
            egwar.RuleIndex,
            egwar.WarSceneID,
            egwar.SubRound,
            egwar.StartTime
        )
    end
    nx_pause(2)
end

function isInMatchScene()
    return GetCurMap() == "fight08"
end

function processPrizeForm()
    local prizeForm = nx_execute("zdn_logic_base", "GetChildForm", PRIZE_FORM_PATH)
    if nx_is_valid(prizeForm) and prizeForm.Visible then
        nx_execute(PRIZE_FORM_PATH, "on_btn_gain_all_click", prizeForm.btn_gain)
        nx_pause(2)
        if nx_is_valid(prizeForm) then
            nx_destroy(prizeForm)
        end
        local backForm = nx_execute("zdn_logic_base", "GetChildForm", FACULTY_BACK_FORM_PATH)
        if nx_is_valid(backForm) then
            nx_destroy(backForm)
        end
        nx_pause(3)
        return true
    end
    return false
end

function onTaskDone()
    IniWriteUserConfig("ThienThe", "ResetTime", nx_execute("zdn_logic_base", "GetNextDayStartTimestamp"))
    Stop()
end
