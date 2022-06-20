require("zdn_lib_thich_quan")

local THTH_FORM_PATH = "form_stage_main\\form_tiguan\\form_tiguan_one"
require(THTH_FORM_PATH)

local Running = false

local CurrentLevel = 1
local LEVEL_MAX_TURN = {
    [1] = 7,
    [2] = 6,
    [3] = 4,
    [4] = 4
}
local NeedResetTurnFlg = false

function IsRunning()
    return Running
end

function Start()
    if Running then
        return
    end
    Running = true
    AbstructRunning = true
    NeedResetTurnFlg = false
    nx_execute("zdn_logic_skill", "LeaveTeam")
    nx_execute("zdn_logic_skill", "AutoAttackDefaultSkillSet")
    nx_execute("zdn_logic_skill", "PauseAttack")
    nx_execute("Listener", "addListen", nx_current(), "dttiaozhanjiemian_3", "onOutOfTime", -1)
    loadThichQuanData()
    while Running do
        loopThth()
        nx_pause(0.2)
    end
end

function Stop()
    Running = false
    AbstructRunning = false
    nx_execute("zdn_logic_skill", "StopAutoAttack")
    StopFindPath()
    nx_execute("Listener", "removeListen", nx_current(), "dttiaozhanjiemian_3", "onOutOfTime")
    nx_execute("zdn_logic_common_listener", "ResolveListener", nx_current(), "on-task-stop")
end

-- private
function loopThth()
    if isLoading() then
        return
    end

    if nx_execute("zdn_logic_skill", "IsPlayerDead") then
        endGame()
        return
    end

    checkLagSkill()

    if isInBossScene() then
        doBossScene()
    else
        enterBossScene()
    end
end

function enterBossScene()
    if isReadyToEnterScene() then
        nx_execute("zdn_logic_skill", "StopNgoiThien")
        nx_pause(0.3)
        openThth()
    else
        nx_execute("zdn_logic_skill", "NgoiThien")
    end
end

function openThth()
    onOpenBossScene()
    local form = nx_value(THTH_FORM_PATH)
    if not nx_is_valid(form) or not form.Visible or form.lbl_score.Text == nx_widestr("") then
        util_auto_show_hide_form(THTH_FORM_PATH)
        LoadingTimer = TimerInit()
        return 0
    end
    if NeedResetTurnFlg then
        NeedResetTurnFlg = false
        resetTurn()
        return 5
    end

    if openThthByLevel(1) then
        return 1
    elseif openThthByLevel(2) then
        return 2
    elseif openThthByLevel(3) then
        return 3
    elseif openThthByLevel(4) then
        return 4
    else
        resetTurn()
        return 5
    end
end

function resetTurn()
    if TimerDiff(ResetTurnTimer) < 10 then
        return
    end
    ResetTurnTimer = TimerInit()
    if kieuDungVoUsable() then
        nx_execute("custom_sender", "custom_send_danshua_tiguan_msg", 17)
        nx_pause(0.5)
    else
        local form = nx_value(THTH_FORM_PATH)
        if not nx_is_valid(form) then
            return
        end
        if form.btn_reset_start.Enabled == true then
            nx_execute("custom_sender", "custom_send_danshua_tiguan_msg", 16)
            nx_pause(0.5)
        else
            Stop()
        end
    end
end

function onOutOfTime()
    if Running then
        NeedResetTurnFlg = true
    end
end

function kieuDungVoUsable()
    local form = nx_value(THTH_FORM_PATH)
    if nx_is_valid(form) and form.btn_double_model.Enabled == true then
        return true
    end
    return false
end

function openThthByLevel(level)
    local form = nx_value(THTH_FORM_PATH)
    if not nx_is_valid(form) or not form.Visible then
        return false
    end
    selectLevel(level, form)
    nx_pause(1)
    if isLevelCompleted(level) then
        return false
    end
    nx_execute("custom_sender", "custom_send_danshua_tiguan_msg", 3, nx_number(level), 0)
    nx_pause(2)
    if not nx_is_valid(form) or not form.Visible then
        return false
    end

    if level >= 2 then
        specifyBoss(level, form)
    end

    nx_execute("custom_sender", "custom_send_danshua_tiguan_msg", 4, nx_number(level), 1)
    CurrentLevel = level
    return true
end

function specifyBoss(level, form)
    local nextGuanID, bossIndex = getNextGuan(level)
    local useFreePointFlg = 0
    if nextGuanID == 0 then
        return
    end
    local arrestIndex = getArrestBoss(nextGuanID, level)
    if arrestIndex == bossIndex then
        return
    end
    if level == 4 and form.free_appoint == 1 then
        useFreePointFlg = 1
    end
    if arrestIndex ~= 0 then
        nx_execute("custom_sender", "custom_send_danshua_tiguan_msg", 14, level, arrestIndex, useFreePointFlg)
    end
end

function getArrestBoss(guanID, level)
    local boss_id = ""
    for i = 1, 9 do
        local guan_id = nx_string(getArrestData(level, i, 1))
        if guan_id == nx_string(guanID) then
            boss_id = nx_string(getArrestData(level, i, 2))
            break
        end
    end
    if boss_id == "" then
        return 0
    end
    local boss_list = ThichQuanData[guanID].bossList
    if boss_list == nil then
        return 0
    end
    for i, boss in pairs(boss_list) do
        if nx_string(boss) == boss_id then
            return i
        end
    end
    return 0
end

function getArrestData(array_level, child_index, data_index)
    return nx_execute(THTH_FORM_PATH, "get_arrest_data", array_level, child_index, data_index)
end

function getNextGuan(level)
    for i = 1, 9 do
        local array_name = "guan" .. nx_string(level) .. "sub" .. nx_string(i)
        local record_complete = nx_number(getThthRecord(array_name, "value7"))
        if record_complete == 1 then
            local record_guan_id = nx_number(getThthRecord(array_name, "value1"))
            local record_boss_index = nx_number(getThthRecord(array_name, "value2"))
            return record_guan_id, record_boss_index
        end
    end
    return 0, 0
end

function isLevelCompleted(level)
    local cnt = 0
    for i = 1, LEVEL_MAX_TURN[level] do
        local array_name = "guan" .. nx_string(level) .. "sub" .. nx_string(i)
        local c = nx_number(getThthRecord(array_name, "value7"))
        if c == -1 then
            return false
        end
        if c == 2 then
            cnt = cnt + 1
        end
    end
    if cnt >= LEVEL_MAX_TURN[level] then
        return true
    end
    return false
end

function getThthRecord(array_name, child_name)
    local common_array = nx_value("common_array")
    if not nx_is_valid(common_array) then
        return -1
    end
    array_name = nx_string(array_name)
    child_name = nx_string(child_name)
    local is_exist = common_array:FindArray(array_name)
    if is_exist then
        local value = common_array:FindChild(array_name, child_name)
        if value ~= nil then
            return value
        end
    end
    return -1
end

function selectLevel(level, form)
    if not nx_is_valid(form) then
        return 0
    end
    form.cur_tiguan_level = level
    nx_execute("custom_sender", "custom_send_danshua_tiguan_msg", CLIENT_MSG_DS_LEVEL_INFO, nx_number(level))
    refresh_attack_boss_times()
    refresh_arrest_info()
    refresh_challenge_info()
    refresh_arrest_desc(form)
end

function checkLagSkill()
    if TimerDiff(timerCheckLag) < 3 then
        return
    end
    timerCheckLag = TimerInit()
    local tempMapID = GetCurMap()
    if tempMapID == "0" then
        return false
    end
    local curTime = nx_execute("zdn_logic_base", "GetCurrentTimestamp")
    if curTime == 0 then
        return
    end
    local tempMapDeltaTime = curTime - os.time()
    local delta = (tempMapDeltaTime - Map.deltaTime)
    if delta > -20 then
        updateMap()
        return false
    end
    waitLagTime(math.abs(delta))
    updateMap()
end

function waitLagTime(delta)
    local timer = TimerInit()
    while Running and TimerDiff(timer) < delta do
        nx_pause(1)
        leaveBossScene()
    end
end
