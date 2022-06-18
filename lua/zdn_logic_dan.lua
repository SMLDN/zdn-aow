require("util_functions")
require("zdn_util")

local Running = false
local QinType = 1
local QinSkill = "null"
local Timer = {}
local GameStep = 1
local GameCount = 1
local GameMaxCount = 10

function IsRunning()
    return Running
end

function Start()
    if Running then
        return
    end
    initData()
    Running = true
    while Running do
        loopDan()
        nx_pause(0.2)
    end
end

function Stop()
    Running = false
    nx_execute("zdn_logic_common_listener", "ResolveListener", nx_current(), "on-task-stop")
end

function loopDan()
    if TimerDiff(Timer.StartGame) < 5 then
        return
    end
    if TimerDiff(Timer.Sleep) < 3 then
        return
    end
    Timer.Sleep = TimerInit()
    if QinSkill == "null" then
        Stop()
        return
    end
    if QinType == 1 then
        qinTrain()
    else
        qinBuff()
    end
end

function initData()
    Timer = {}
    Timer.StartGame = 0
    Timer.Sleep = 0
    GameStep = 1
    GameCount = 0

    QinSkill = "null"
    local set = nx_number(IniReadUserConfig("QinGame", "set", 1))
    local skillStr = nx_string(IniReadUserConfig("QinGame", "skill", ""))
    if skillStr ~= "" then
        local skillList = util_split_string(skillStr, ",")
        QinSkill = skillList[set]
    end

    QinType = nx_number(IniReadUserConfig("QinGame", "type", 1))
    GameMaxCount = nx_number(IniReadUserConfig("QinGame", "max_turn", 10))
end

function qinBuff()
    local form = nx_value("form_stage_main\\form_small_game\\form_mini_qingame")
    if nx_execute("zdn_logic_base", "GetRoleState") == "tanqin" or (nx_is_valid(form) and form.Visible) then
        form.t_speed = 0.01
        Timer.StartGame = TimerInit()
    else
        nx_execute("custom_sender", "custom_doqin", nx_string(QinSkill))
    end
end

function qinTrain(...)
    local form = nx_value("form_stage_main\\form_small_game\\form_qingame")
    if GameStep == 1 then
        if nx_is_valid(form) and form.Visible then
            GameStep = 2
        end
    else
        if not nx_is_valid(form) or not form.Visible then
            GameStep = 1
            GameCount = GameCount + 1
            local auto_form = nx_value("form_zdn_dan")
            if nx_is_valid(auto_form) then
                if nx_number(auto_form.max_turn.Text) > 0 then
                    auto_form.max_turn.Text = nx_widestr(nx_number(auto_form.max_turn.Text) - 1)
                end
            end
        end
    end

    if GameCount >= GameMaxCount then
        Stop()
        return
    end

    if nx_is_valid(form) and form.Visible then
        form.t_speed = 0.01
        if not form.gamestart then
            nx_execute("form_stage_main\\form_small_game\\form_qingame", "on_btn_start_game_click", form.btn_start_game)
        else
            Timer.StartGame = TimerInit()
        end
    else
        nx_execute("custom_sender", "custom_send_compose", nx_string(QinSkill), 1, 0)
    end
end
