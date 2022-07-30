require("util_functions")
require("define\\team_rec_define")
require("zdn_util")
require("zdn_lib_moving")

local Running = false
local Config = {}

LOGIC_STATE_SITCROSS = 102

function Start()
    if Running then
        return
    end
    Running = true
    initData()
    while Running do
        loopEscort()
        nx_pause(0.2)
    end
end

function Stop()
    if not Running then
        return
    end
    Running = false
    StopFindPath()
    nx_execute("zdn_logic_skill", "StopAutoAttack")
    nx_execute("zdn_logic_common_listener", "ResolveListener", nx_current(), "on-task-stop")
end

function IsRunning()
    return Running
end

function CanRun()
    if Config.MaxTurn == nil then
        initData()
    end
    if GetCompleteTimes() < Config.MaxTurn then
        return true
    end
    return false
end

function IsTaskDone()
    return not CanRun()
end

function GetCompleteTimes()
    local c = nx_value("game_client")
    if nx_is_valid(c) then
        local p = c:GetPlayer()
        if nx_is_valid(p) then
            local rec_row = p:FindRecordRow("ActivityCompliteRec", 0, nx_int(9), 0)
            if rec_row < 0 then
                return 0
            end
        end
    end
    local mgr = nx_value("InteractManager")
    if not nx_is_valid(mgr) then
        return 0
    end
    return nx_number(mgr:GetInteractTime(5))
end

-- private
function initData()
    Config.Map = "city05"
    Config.BeginX = 0
    Config.BeginY = 0
    Config.BeginZ = 0
    Config.EscortName = ""
    Config.EscortID = ""
    Config.EscortPath = {}
    Config.MaxTurn = 5
    Config.EscortType = 1
    Config.Scene = ""
    Config.CurPosIndex = 1
    loadEscortData()
end

function loadEscortData()
    Config.MaxTurn = nx_number(IniReadUserConfig("Escort", "max_turn", 5))
    Config.EscortType = nx_number(IniReadUserConfig("Escort", "type", 1))
    if 1 > Config.EscortType or Config.EscortType > 15 then
        Config.EscortType = 1
        IniWriteUserConfig("Escort", "type", 1)
    end
    if 1 > Config.MaxTurn or Config.MaxTurn > 150 then
        Config.MaxTurn = 5
        IniWriteUserConfig("Escort", "max_turn", 5)
    end
    local escortInfo = nx_resource_path() .. "zdn\\data\\escort_info.ini"
    local listPoint = nx_string(IniRead(escortInfo, nx_string(Config.EscortType), "ListPoint", "0"))
    if listPoint == "0" then
        return
    end
    local list = util_split_string(listPoint, ";")
    for i, pos in pairs(list) do
        local data = util_split_string(pos, ",")
        if #data == 3 then
            local info = {}
            info.X = nx_number(data[1])
            info.Y = nx_number(data[2])
            info.Z = nx_number(data[3])
            table.insert(Config.EscortPath, info)
        end
    end

    Config.Map = nx_string(IniRead(escortInfo, nx_string(Config.EscortType), "MapID", "city05"))
    Config.Scene =
        nx_string(IniRead(escortInfo, nx_string(Config.EscortType), "MapConfig", "ini\\scene\\city05_ChengDu"))
    local npc =
        nx_string(
        IniRead(
            escortInfo,
            nx_string(Config.EscortType),
            "Escort",
            "EscortAcceptNpc001;251;720.793274,24.021803,517.246094"
        )
    )
    list = util_split_string(npc, ";")
    if #list ~= 3 then
        return
    end
    Config.EscortName = list[1]
    Config.EscortID = list[2]
    list = util_split_string(list[3], ",")
    if #list ~= 3 then
        return
    end
    Config.BeginX = nx_number(list[1])
    Config.BeginY = nx_number(list[2])
    Config.BeginZ = nx_number(list[3])
end

function getPlayer()
    local client = nx_value("game_client")
    if not nx_is_valid(client) then
        return
    end
    return client:GetPlayer()
end

function isShipping()
    return nx_execute("zdn_logic_skill", "HaveBuff", "buff_yunbiao_escortbuff")
end

function loopEscort()
    if not checkLoop() then
        return
    end
    if nx_execute("zdn_logic_skill", "IsPlayerDead") then
        nx_execute("custom_sender", "custom_relive", 2)
        return
    end
    if GetCurMap() ~= Config.Map then
        nx_execute("zdn_logic_common_listener", "ResolveListener", nx_current(), "on-task-interrupt")
        GoToMapByPublicHomePoint(Config.Map)
        return
    end
    if isShipping() then
        doShip()
    else
        nx_execute("zdn_logic_common_listener", "ResolveListener", nx_current(), "on-task-interrupt")
        nhanTieu()
    end
end

function checkLoop()
    if not CanRun() then
        Stop()
        return false
    end
    if TimerDiff(TimerSend) < 1 then
        return false
    end
    if IsMapLoading() then
        return false
    end
    return true
end

function kickoutFromTeam(name)
    if not Running then
        return
    end
    nx_execute("custom_sender", "custom_kickout_team", nx_widestr(name))
end

function checkTeam()
    local TEAM_REC = "team_rec"
    local player = getPlayer()
    if not nx_is_valid(player) then
        return false
    end
    local player_name = nx_widestr(player:QueryProp("Name"))
    local captain_name = nx_widestr(player:QueryProp("TeamCaptain"))
    if captain_name == nx_widestr("0") or captain_name == nx_widestr("") then
        nx_execute("custom_sender", "custom_team_create")
        nx_execute("custom_sender", "custom_change_team_type", nx_int(1))
        return false
    elseif player_name ~= captain_name then
        nx_execute("custom_sender", "custom_leave_team")
        return false
    end
    local row_count = player:GetRecordRows(TEAM_REC)
    for row = 0, row_count - 1 do
        local name = nx_widestr(player:QueryRecord(TEAM_REC, row, TEAM_REC_COL_NAME))
        local scene = nx_string(player:QueryRecord(TEAM_REC, row, TEAM_REC_COL_SCENE))
        local offlineState = nx_number(player:QueryRecord(TEAM_REC, row, TEAM_REC_COL_ISOFFLINE))
        if scene ~= Config.Scene or offlineState ~= 0 then
            kickoutFromTeam(name)
        end
    end
    return true
end

function checkMana()
    local player = getPlayer()
    if not nx_is_valid(player) then
        return false
    end
    local mp = nx_number(player:QueryProp("MPRatio"))
    local hp = nx_number(player:QueryProp("HPRatio"))
    local state = getPlayerState()
    if mp < 70 or hp < 50 then
        if state ~= LOGIC_STATE_SITCROSS then
            XuongNgua()
            nx_execute("custom_sender", "custom_sitcross", 1)
        end
        return false
    else
        if state == LOGIC_STATE_SITCROSS then
            nx_execute("custom_sender", "custom_sitcross", 0)
            return false
        end
    end
    return true
end

function nhanTieu()
    if GetDistance(Config.BeginX, Config.BeginY, Config.BeginZ) < 2 then
        if not checkTeam() or not checkMana() then
            return
        end
        nx_execute("custom_sender", "custom_request_start_escort", Config.EscortName, Config.EscortID, 0)
        nx_pause(3)
        Config.CurPosIndex = 1
    else
        GoToPosition(Config.BeginX, Config.BeginY, Config.BeginZ)
    end
end

function getXeTieu()
    local client = nx_value("game_client")
    local scene = client:GetScene()
    if not (nx_is_valid(scene)) then
        return nil
    end
    local objList = scene:GetSceneObjList()
    local player = client:GetPlayer()
    local playerName = player:QueryProp("Name")
    for i, obj in pairs(objList) do
        local npcType = nx_number(obj:QueryProp("NpcType"))
        local dead = nx_number(obj:QueryProp("Dead"))
        if npcType == 213 and dead ~= 1 then
            local name = nx_widestr(obj:QueryProp("EscortName"))
            if name == playerName then
                return obj
            end
        end
    end
    return nil
end

function findXeTieu()
    if #Config.EscortPath == 0 then
        return
    end
    if Config.CurPosIndex > #Config.EscortPath then
        Config.CurPosIndex = 1
    end
    local currentIdx = Config.CurPosIndex
    local x = Config.EscortPath[currentIdx].X
    local y = Config.EscortPath[currentIdx].Y
    local z = Config.EscortPath[currentIdx].Z
    if GetDistance(x, y, z) < 5 then
        Config.CurPosIndex = Config.CurPosIndex % #Config.EscortPath + 1
    else
        GoToPosition(x, y, z)
    end
end

function beAttacking()
    return nx_execute("zdn_logic_skill", "HaveBuffPrefix", "buf_guild_biaoche_shp")
end

function doShip()
    local xe = getXeTieu()
    if not nx_is_valid(xe) then
        findXeTieu()
        return
    end

    if not beAttacking() then
        nx_execute("zdn_logic_skill", "StopAutoAttack")
        followXeTieu(xe)
        return
    end

    local attacker = getNpcAttacker()
    if nx_is_valid(attacker) then
        if GetDistanceToObj(attacker) > 2.8 then
            GoToObj(attacker)
            return
        end
        attackNpcAttacker(attacker)
    end
end

function attackNpcAttacker(target)
    if not nx_find_custom(target, "TaoluTimer") then
        target.TaoluTimer = 0
        target.LastSkillID = ""
    end
    local currentSkill = target:QueryProp("CurSkillID")
    if currentSkill ~= target.LastSkillID then
        target.TaoluTimer = TimerInit()
        target.LastSkillID = currentSkill
    end
    if currentSkill == "skill_guild_biaoche_boss_002" then
        nx_execute("zdn_logic_skill", "StartParry")
    elseif currentSkill == "skill_guild_biaoche_boss_001" then
        if TimerDiff(target.TaoluTimer) > 2 then
            nx_execute("zdn_logic_skill", "Fly")
            nx_execute("zdn_logic_skill", "StartParry")
        end
    else
        nx_execute("zdn_logic_skill", "StopParry")
        doAttack(target)
    end
end

function getTargetObj()
    local client = nx_value("game_client")
    if not nx_is_valid(client) then
        return
    end
    local player = client:GetPlayer()
    if not nx_is_valid(player) then
        return
    end
    return client:GetSceneObj(nx_string(player:QueryProp("LastObject")))
end

function isTarget(obj)
    local target = getTargetObj()
    if not nx_is_valid(target) then
        return false
    end
    return nx_id_equal(target, obj)
end

function doAttack(target)
    if not nx_is_valid(target) then
        return
    end
    if not isTarget(target) then
        XuongNgua()
        if not nx_is_valid(target) then
            return
        end
        nx_execute("custom_sender", "custom_select", target.Ident)
        return
    end
    nx_execute("zdn_logic_skill", "FlexAttack")
end

function getVisualObj(obj)
    if not nx_is_valid(obj) then
        return
    end
    local visual = nx_value("game_visual")
    return visual:GetSceneObj(obj.Ident)
end

function getObjState(obj)
    local visual = getVisualObj(obj)
    if not nx_is_valid(visual) then
        return ""
    end
    return nx_string(visual.state)
end

function followXeTieu(obj)
    if getObjState(obj) == "be_stop" and GetDistanceToObj(obj) < 4 then
        nx_execute("custom_sender", "custom_request_escort_control", nx_object(obj.Ident), 2)
        TimerSend = TimerInit()
    end
    StopFindPath()
    if GetDistanceToObj(obj) > 4 then
        GoToObj(obj)
    end
end

function getNpcAttacker()
    local client = nx_value("game_client")
    local fight = nx_value("fight")
    if not nx_is_valid(client) or not nx_is_valid(fight) then
        return nil
    end
    local scene = client:GetScene()
    local player = client:GetPlayer()
    if not nx_is_valid(scene) or not nx_is_valid(player) then
        return nil
    end
    local playerName = player:QueryProp("Name")
    local list = scene:GetSceneObjList()
    local owner = ""
    for i, obj in pairs(list) do
        owner = obj:QueryProp("OwnerName")
        if owner == playerName and fight:CanAttackNpc(player, obj) then
            return obj
        end
    end
    return nil
end

function getPlayerState()
    local role = nx_value("role")
    if not nx_is_valid(role) then
        return
    end
    if not nx_find_custom(role, "state") then
        return
    end
    return nx_string(role.state)
end
