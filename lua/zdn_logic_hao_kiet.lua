require("zdn_lib\\util_functions")
require("share\\client_custom_define")
require("form_stage_main\\form_tvt\\define")
require("zdn_util")
require("zdn_lib_moving")

local Running = false
local Radius = 50
local Position = {}
local BlackList = {}

function IsRunning()
    return Running
end

function CanRun()
    return loadSetting()
end

function IsTaskDone()
    return not CanRun()
end

function Start()
    if Running then
        return
    end
    if not CanRun() then
        Stop()
        return
    end
    nx_execute("zdn_logic_skill", "LeaveTeam")
    nx_execute("Listener", "addListen", nx_current(), "30409", "onFullBoss", -1)
    nx_execute("Listener", "addListen", nx_current(), "30361", "onFullBoss", -1)
    Running = true
    while Running do
        loopHaoKiet()
        nx_pause(0.2)
    end
end

function Stop()
    Running = false
    nx_execute("zdn_logic_skill", "StopAutoAttack")
    StopFindPath()
    nx_execute("Listener", "removeListen", nx_current(), "30409", "onFullBoss")
    nx_execute("Listener", "removeListen", nx_current(), "30361", "onFullBoss")
    nx_execute("zdn_logic_common_listener", "ResolveListener", nx_current(), "on-task-stop")
end

-- private
function loopHaoKiet()
    if IsMapLoading() then
        return
    end
    if GetCurMap() ~= Position.Map then
        nx_execute("zdn_logic_common_listener", "ResolveListener", nx_current(), "on-task-interrupt")
        GoToMapByPublicHomePoint(Position.Map)
        return
    end
    if GetDistance(Position.PosX, Position.PosY, Position.PosZ) > Radius then
        nx_execute("zdn_logic_common_listener", "ResolveListener", nx_current(), "on-task-interrupt")
        GoToPosition(Position.PosX, Position.PosY, Position.PosZ)
        return
    end
    if isInBossScene() then
        if TimerDiff(TimerWaitBossShow) < 8 then
            nx_execute("zdn_logic_skill", "PauseAttack")
            return
        end
    else
        TimerWaitBossShow = TimerInit()
    end
    if pickDeadBossItem() then
        local boss = nx_execute("zdn_logic_base", "GetNearestObj", nx_current(), "isBoss", "isNotInBlackList")
        if not nx_is_valid(boss) then
            quitBossScene()
            nx_pause(4)
        end
        return
    end

    XuongNgua()
    local target = nx_execute("zdn_logic_base", "GetNearestObj", nx_current(), "isNotDead", "isAttackable", "isInRange")
    if not nx_is_valid(target) then
        nx_execute("zdn_logic_skill", "PauseAttack")
        if TimerDiff(TimerGoToCenter) > 3 then
            if GetDistance(Position.PosX, Position.PosY, Position.PosZ) > 8 then
                GoToPosition(Position.PosX, Position.PosY, Position.PosZ)
            end
        end
        return
    end

    TimerGoToCenter = TimerInit()
    nx_execute("zdn_logic_base", "SelectTarget", target)
    if GetDistanceToObj(target) < 2.8 then
        if (nx_execute("zdn_logic_skill", "IsRunning")) then
            StopFindPath()
            nx_execute("zdn_logic_skill", "ContinueAttack")
        else
            nx_execute("zdn_logic_skill", "AutoAttackDefaultSkillSet")
        end
    else
        nx_execute("zdn_logic_skill", "PauseAttack")
        GoToObj(target)
        nx_execute("zdn_logic_common_listener", "ResolveListener", nx_current(), "on-task-interrupt")
    end
end

function pickDeadBossItem()
    local boss = nx_execute("zdn_logic_base", "GetNearestObj", nx_current(), "isBoss", "isNotInBlackList")
    if not nx_is_valid(boss) then
        return false
    end
    if isNotDead(boss) then
        return false
    end
    nx_execute("zdn_logic_skill", "PauseAttack")
    if pickDeadBoss(boss) then
        addBlackList(boss)
    end
    return true
end

function pickDeadBoss(boss)
    if isShowPick() then
        if TimerDiff(TimerPickDeadBoss) > 2 then
            pickItem()
            nx_execute("custom_sender", "custom_close_drop_box")
            nx_pause(1)
            return true
        end
        return false
    else
        TimerPickDeadBoss = TimerInit()
    end

    if GetDistanceToObj(boss) > 1.6 then
        GoToObj(boss)
    else
        nx_execute("custom_sender", "custom_select", boss.Ident)
    end
    return false
end

function isShowPick()
    local form = nx_value("form_stage_main\\form_pick\\form_droppick")
    return nx_is_valid(form) and form.Visible
end

function pickItem()
    local client = nx_value("game_client")
    if not nx_is_valid(client) then
        return
    end
    local view = client:GetView(nx_string(80))
    if not nx_is_valid(view) then
        return
    end
    local list = view:GetViewObjList()
    for i, item in pairs(list) do
        if nx_is_valid(item) and nx_string(item:QueryProp("ConfigID")) == "item_exchange_xljs_mark" then
            nx_execute("custom_sender", "custom_pickup_single_item", i)
        end
    end
end

function addBlackList(boss)
    if isNotInBlackList(boss) then
        table.insert(BlackList, boss.Ident)
    end
end

function isBoss(obj)
    return nx_number(obj:QueryProp("NpcType")) == 1
end

function isInBossScene()
    local client = nx_value("game_client")
    local player = client:GetPlayer()
    if not nx_is_valid(player) then
        return false
    end
    local rows = player:GetRecordRows("InteractTraceRec")
    if nx_int(rows) <= nx_int(0) then
        return false
    end
    for i = 0, rows - 1 do
        local text = player:QueryRecord("InteractTraceRec", i, 2)
        local temp = util_split_string(nx_string(text), ";")
        if temp[1] ~= nil then
            local temp2 = util_split_string(temp[1], ",")
            if temp2[2] ~= nil and string.find(nx_string(temp2[2]), "ui_jhtime_round_") == 1 then
                return true
            end
        end
    end
    return false
end

function loadSetting()
    local posStr = IniReadUserConfig("HaoKiet", "Position", "")
    if posStr ~= "" then
        local posList = util_split_string(nx_string(posStr), ";")
        for _, record in pairs(posList) do
            local prop = util_split_string(record, ",")
            if isPositionValid(prop) then
                Position.Map = prop[1]
                Position.PosX = prop[2]
                Position.PosY = prop[3]
                Position.PosZ = prop[4]
                return true
            end
        end
    end
    return false
end

function isNotDead(obj)
    return nx_number(obj:QueryProp("Dead")) ~= 1
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

function isInRange(obj)
    return GetDistanceObjToPosition(obj, Position.PosX, Position.PosY, Position.PosZ) < 50
end

function isNotInBlackList(obj)
    local id = obj.Ident
    for _, ident in pairs(BlackList) do
        if ident == id then
            return false
        end
    end
    return true
end

function isDead(obj)
    return not isNotDead(obj)
end

function onFullBoss()
    if TimerDiff(TimerOnFullBoss) < 3 then
        return
    end
    TimerOnFullBoss = TimerInit()
    nx_execute("zdn_logic_skill", "PauseAttack")

    local newResetTimeStr =
        generateRecord(
        Position.Map,
        Position.PosX,
        Position.PosY,
        Position.PosZ,
        nx_execute("zdn_logic_base", "GetNextDayStartTimestamp")
    )
    local resetTimeStr = IniReadUserConfig("HaoKiet", "ResetTime", "")
    if resetTimeStr ~= "" then
        local resetTime = util_split_string(nx_string(resetTimeStr), ";")
        for _, record in pairs(resetTime) do
            local prop = util_split_string(nx_string(record), ",")
            if
                prop[1] ~= Position.Map or nx_number(prop[2]) ~= math.floor(Position.PosX) or
                    nx_number(prop[3]) ~= math.floor(Position.PosY) or
                    nx_number(prop[4]) ~= math.floor(Position.PosZ)
             then
                newResetTimeStr = nx_string(newResetTimeStr) .. ";"
                newResetTimeStr =
                    nx_string(newResetTimeStr) .. generateRecord(prop[1], prop[2], prop[3], prop[4], prop[5])
            end
        end
    end
    IniWriteUserConfig("HaoKiet", "ResetTime", newResetTimeStr)
    if not loadSetting() then
        Stop()
    end
    nx_pause(1)
end

function generateRecord(map, x, y, z, time)
    return map ..
        "," ..
            nx_string(math.floor(x)) ..
                "," .. nx_string(math.floor(y)) .. "," .. nx_string(math.floor(z)) .. "," .. time
end

function quitBossScene()
    send_server_msg(g_msg_giveup, 27)
end

function isPositionValid(prop)
    local map = prop[1]
    local x = prop[2]
    local y = prop[3]
    local z = prop[4]
    local checked = nx_string(prop[5]) == "1" and true or false
    if not checked then
        return false
    end
    local resetTimeStr = IniReadUserConfig("HaoKiet", "ResetTime", "")
    if resetTimeStr ~= "" then
        local resetTime = util_split_string(nx_string(resetTimeStr), ";")
        for _, record in pairs(resetTime) do
            local prop = util_split_string(nx_string(record), ",")
            if
                prop[1] == map and nx_number(prop[2]) == math.floor(x) and nx_number(prop[3]) == math.floor(y) and
                    nx_number(prop[4]) == math.floor(z)
             then
                return nx_execute("zdn_logic_base", "GetCurrentDayStartTimestamp") >= nx_number(prop[5])
            end
        end
    end
    return true
end
