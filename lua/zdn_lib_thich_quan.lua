require("util_functions")
require("util_gui")
require("zdn_util")
require("zdn_lib_moving")
require("zdn_lib_jump")
require("form_stage_main\\form_main\\form_main_shortcut_extraskill")

local ThichQuanConfig = {}
local BossData = {}
local ThichQuanData = {}
local ErrorBoss = {}
local LastBossId = ""
local CanJump = false
AbstructRunning = false
Map = {}
OpenBoxFlg = false

function endGame()
    local timer = TimerInit()
    while TimerDiff(timer) < 120 and AbstructRunning do
        nx_pause(1)
        if nx_execute("zdn_logic_skill", "IsPlayerDead") then
            nx_execute("custom_sender", "custom_relive", 2, 0)
        else
            leaveBossScene()
        end
        if not isInBossScene() then
        -- local form = nx_value("form_zdn_thth")
        -- if nx_is_valid(form) then
        -- form.btn_submit.Text = nx_widestr("Dead")
        -- end
        end
    end
    StartClickTimer = 0
end

function isInBossScene()
    local form = nx_value("form_stage_main\\form_main\\form_main_shortcut_extraskill")
    if nx_is_valid(form) and form.Visible == true then
        return true
    end
    if getBossInfo() ~= nil then
        return true
    end
    return false
end

function doBossScene()
    if isComplete() then
        doComplete()
    else
        if not isInBossScene() then
            return
        end
        if CanJump then
            jumpToBoss()
        else
            findAndKillBoss()
        end
        AttackTimer = TimerInit()
    end
end

function isReadyToEnterScene()
    local client = nx_value("game_client")
    local player = client:GetPlayer()
    if not nx_is_valid(player) then
        return false
    end
    local hpRatio = nx_number(player:QueryProp("HPRatio"))
    local mpRatio = nx_number(player:QueryProp("MPRatio"))
    if
        ((hpRatio >= 74 and nx_execute("zdn_logic_skill", "HaveBuff", "buf_baosd_01")) or hpRatio >= 95) and
            mpRatio >= 95
     then
        return true
    end
    return false
end

function isComplete()
    local form = nx_value("form_stage_main\\form_tiguan\\form_tiguan_detail")
    if not nx_is_valid(form) then
        return false
    end
    return form.Visible
end

function getBossInfo()
    local tiguan_finish_cdts = nx_value("tiguan_finish_cdts")

    if not nx_is_valid(tiguan_finish_cdts) or not nx_find_custom(tiguan_finish_cdts, "cg_id") then
        return nil
    end
    local cdt_tab = tiguan_finish_cdts:GetChildList()
    local index = 1
    if #cdt_tab > 0 then
        index = cdt_tab[1].cdt_id
        LastBossId = BossData[index]
    end
    return LastBossId
end

function doComplete()
    nx_execute("zdn_logic_skill", "PauseAttack")
    if TimerDiff(AttackTimer) < 2 then
        return
    end
    if processOpenBox() then
        return
    end
    -- TODO get prize box
    leaveBossScene()
    LoadingTimer = TimerInit() + 20
end

function leaveBossScene()
    nx_execute("zdn_logic_skill", "PauseAttack")
    if isComplete() then
        nx_execute("custom_sender", "custom_tiguan_request_leave")
        return
    end
    requestLeaveViaNpc()
end

function requestLeaveViaNpc()
    local npc = findSceneNpc()
    if npc ~= nil then
        if GetDistanceToObj(npc) > 4 then
            GoToObj(npc)
        else
            TalkToNpc(npc, 0)
        end
    else
        local guanId = getCurGuanId()
        if guanId == 0 then
            return
        end
        local x = ThichQuanData[guanID].TransOutX
        local y = ThichQuanData[guanID].TransOutY
        local z = ThichQuanData[guanID].TransOutZ
        GoToPosition(x, y, z)
    end
end

function findSceneNpc()
    local client = nx_value("game_client")
    local scene = client:GetScene()
    if not nx_is_valid(scene) then
        return nil
    end
    local objList = scene:GetSceneObjList()
    for _, obj in pairs(objList) do
        if nx_number(obj:QueryProp("NpcType")) == 51 then
            return obj
        end
    end
    return nil
end

function isLoading()
    local form = nx_value("form_stage_main\\form_main\\form_main_curseloading")
    if nx_is_valid(form) and form.Visible then
        LoadingTimer = TimerInit()
    end
    form = nx_value("form_common\\form_loading")
    if nx_is_valid(form) and form.Visible then
        LoadingTimer = TimerInit() + 3
    end
    return TimerDiff(LoadingTimer) < 1
end

function findAndKillBoss()
    CurBossId = getBossInfo()
    if CurBossId == nil or CurBossId == "0" then
        return
    end

    local obj = getObjByConfig(CurBossId)
    if nx_is_valid(obj) then
        if TimerDiff(CantBeAttackTimer) < 10 then
            prepareKillBoss(obj)
        elseif not isCantBeAttack(obj) then
            doKillBoss(obj)
        end
    else
        GoToNpc(GetCurMap(), CurBossId)
    end
end

function doKillBoss(boss)
    if GetDistanceToObj(boss) > 2.8 then
        nx_execute("zdn_logic_skill", "PauseAttack")
        GoToObj(boss)
    else
        attack(boss)
    end
end

function isCantBeAttack(obj)
    local cantAttack = obj:QueryProp("CantBeAttack")
    if nx_number(cantAttack) == 1 then
        CantBeAttackTimer = TimerInit()
        return true
    end
    return false
end

function prepareKillBoss(obj)
    if not isCantBeAttack(obj) and GetDistanceToObj(obj) < 3 then
        CantBeAttackTimer = 0
        return
    end

    local index = isErrorBoss(CurBossId)
    if index > 0 then
        nx_execute("zdn_logic_skill", "PauseAttack")
        local x = ErrorBoss[index].fPos.X
        local y = ErrorBoss[index].fPos.Y
        local z = ErrorBoss[index].fPos.Z
        if GetDistance(x, y, z) > 1 then
            GoToPosition(x, y, z)
            return
        end
    end
    nx_execute("zdn_logic_skill", "StartParry")
end

function isNeedParry(obj)
    return isHaveStrongBuff(obj) or isStrongAttack(obj)
end

function isHaveStrongBuff(obj)
    local name = obj:QueryProp("ConfigID")
    if ThichQuanConfig.AutoDefData[name] == nil or ThichQuanConfig.AutoDefData[name].buff == nil then
        return false
    end
    local list = ThichQuanConfig.AutoDefData[name].buff
    for i = 1, #list do
        return nx_execute("zdn_logic_skill", "ObjHaveBuff", obj, list[i])
    end
    return false
end

function isStrongAttack(obj)
    local name = obj:QueryProp("ConfigID")
    if ThichQuanConfig.AutoDefData[name] == nil or ThichQuanConfig.AutoDefData[name].skill == nil then
        return false
    end
    local list = ThichQuanConfig.AutoDefData[name].skill
    local cur_skill_id = obj:QueryProp("CurSkillID")
    for i = 1, #list do
        if cur_skill_id == list[i] then
            return true
        end
    end
    return false
end

function attack(obj)
    if isNeedParry(obj) then
        nx_execute("zdn_logic_skill", "StartParry")
        return
    end

    nx_execute("zdn_logic_base", "SelectTarget", obj)
    if nx_execute("zdn_logic_skill", "IsRunning") then
        nx_execute("zdn_logic_skill", "ContinueAttack")
    else
        nx_execute("zdn_logic_skill", "AutoAttackDefaultSkillSet")
    end
end

function getObjByConfig(config)
    local game_client = nx_value("game_client")
    local game_scene = game_client:GetScene()
    if not nx_is_valid(game_scene) then
        return nil
    end
    local objList = game_scene:GetSceneObjList()
    for i, obj in pairs(objList) do
        if nx_string(obj:QueryProp("ConfigID")) == nx_string(config) then
            return obj
        end
    end
    return nil
end

function getCurGuanId()
    local client = nx_value("game_client")
    local player = client:GetPlayer()
    if not nx_is_valid(player) then
        return 0
    end
    return nx_number(player:QueryProp("CurGuanID"))
end

function updateMap()
    Map = {
        ["ID"] = GetCurMap(),
        ["deltaTime"] = nx_execute("zdn_logic_base", "GetCurrentTimestamp") - os.time()
    }
end

function loadThichQuanData()
    updateMap()
    BossData = {}
    ThichQuanData = {}
    ErrorBoss = {}

    loadBossData()
    loadNpcPosData()
    loadJumpData()
    loadAutoDefData()
    nx_execute("zdn_logic_vat_pham", "LoadPickItemData")
end

function loadBossData()
    local file = nx_resource_path() .. "zdn\\data\\thichquan\\boss.ini"
    local errNum = nx_number(IniRead(file, "error_boss", "total", "0"))
    for i = 1, errNum do
        local data = nx_string(IniRead(file, "error_boss", nx_string(i), "0"))
        local dataTable = util_split_string(data, ";")
        if #dataTable >= 4 then
            local cPos = util_split_string(dataTable[3], ",")
            local fPos = util_split_string(dataTable[4], ",")
            local child = {
                ["bossID"] = dataTable[1],
                ["Distance"] = nx_number(dataTable[2]),
                ["cPos"] = {
                    ["X"] = nx_number(cPos[1]),
                    ["Y"] = nx_number(cPos[2]),
                    ["Z"] = nx_number(cPos[3])
                },
                ["fPos"] = {
                    ["X"] = nx_number(fPos[1]),
                    ["Y"] = nx_number(fPos[2]),
                    ["Z"] = nx_number(fPos[3])
                }
            }
            table.insert(ErrorBoss, child)
        end
    end
    local setNum = nx_number(IniRead(file, "boss_list", "total", "0"))
    for i = 1, setNum do
        BossData[i] = nx_string(IniRead(file, "boss_list", nx_string(i), "0"))
    end
end

function loadNpcPosData()
    local file = nx_resource_path() .. "share\\War\\tiguan.ini"
    for i = 1, 32 do
        local data = {}
        local level = nx_number(IniRead(file, nx_string(i), "Level", "0"))
        local bossList = IniRead(file, nx_string(i), "BossList", "0")
        local x = nx_number(IniRead(file, nx_string(i), "TransOutX", "0"))
        local y = nx_number(IniRead(file, nx_string(i), "TransOutY", "0"))
        local z = nx_number(IniRead(file, nx_string(i), "TransOutZ", "0"))
        bossList = util_split_string(nx_string(bossList), ";")
        data = {
            ["Level"] = level,
            ["bossList"] = bossList,
            ["TransOutX"] = x,
            ["TransOutY"] = y,
            ["TransOutZ"] = z
        }
        table.insert(ThichQuanData, data)
    end
end

function loadJumpData()
    local jumpIni = nx_create("IniDocument")
    jumpIni.FileName = nx_resource_path() .. "zdn\\data\\thichquan\\jump.ini"
    if not jumpIni:LoadFromFile() then
        nx_destroy(jumpIni)
    end
    local jumpList = jumpIni:GetSectionList()
    local x, y, z = 0, 0, 0
    local pos_text = ""
    local pos_list = {}
    local data = {}
    ThichQuanConfig.JumpData = {}
    for i = 1, #jumpList do
        local point_list = jumpIni:GetItemList(jumpList[i])
        local last_x, last_y, last_z = 0, 0, 0
        ThichQuanConfig.JumpData[jumpList[i]] = {}
        for j = 1, #point_list do
            pos_text = nx_string(jumpIni:ReadString(jumpList[i], point_list[j], "0"))
            pos_list = util_split_string(pos_text, ",")
            if #pos_list ~= 3 then
                break
            end
            data = {}
            data.cur_x = last_x
            data.cur_y = last_y
            data.cur_z = last_z
            x, y, z = nx_number(pos_list[1]), nx_number(pos_list[2]), nx_number(pos_list[3])
            data.dest_x = x
            data.dest_y = y
            data.dest_z = z
            ThichQuanConfig.JumpData[jumpList[i]][j] = data
            last_x, last_y, last_z = x, y, z
        end
    end
    nx_destroy(jumpIni)
end

function loadAutoDefData()
    local autoDefIni = nx_create("IniDocument")
    autoDefIni.FileName = nx_resource_path() .. "zdn\\data\\thichquan\\boss_strong_skill.ini"
    if not autoDefIni:LoadFromFile() then
        nx_destroy(autoDefIni)
    end
    local deffList = autoDefIni:GetSectionList()
    ThichQuanConfig.AutoDefData = {}
    for i = 1, #deffList do
        ThichQuanConfig.AutoDefData[deffList[i]] = {}
        local buff = nx_string(autoDefIni:ReadString(deffList[i], "buff", "0"))
        if buff ~= "0" then
            ThichQuanConfig.AutoDefData[deffList[i]].buff = util_split_string(buff, ",")
        end
        local skill = nx_string(autoDefIni:ReadString(deffList[i], "skill", "0"))
        if skill ~= "0" then
            ThichQuanConfig.AutoDefData[deffList[i]].skill = util_split_string(skill, ",")
        end
    end
    nx_destroy(autoDefIni)
end

function jumpToBoss()
    CanJump = false
    boss_id = getBossInfo()
    if boss_id == nil or boss_id == "0" then
        return
    end
    local x, y, z = GetNpcPostion(GetCurMap(), boss_id)
    local jump_data = ThichQuanConfig.JumpData[boss_id]
    if jump_data == nil then
        return
    end
    local last_x, last_y, last_z = 0, 0, 0
    for i = 1, #jump_data do
        local pos = jump_data[i]
        flyToPos(pos.cur_x, pos.cur_y, pos.cur_z, pos.dest_x, pos.dest_y, pos.dest_z)
        last_x, last_y, last_z = pos.dest_x, pos.dest_y, pos.dest_z
    end
    local index = isErrorBoss(boss_id)
    if index > 0 then
        x = ErrorBoss[index].fPos.X
        y = ErrorBoss[index].fPos.Y
        z = ErrorBoss[index].fPos.Z
    end
    flyToPos(last_x, last_y, last_z, x, y, z)
end

function isErrorBoss(cfg)
    for i, boss in pairs(ErrorBoss) do
        if cfg == boss.bossID then
            return i
        end
    end
    return 0
end

function flyToPos(cur_x, cur_y, cur_z, x, y, z)
    if not AbstructRunning then
        return
    end
    local role = nx_value("role")
    local scene_obj = nx_value("scene_obj")
    if not nx_is_valid(scene_obj) or not nx_is_valid(role) then
        return
    end
    local dis = distance3d(role.PositionX, role.PositionY, role.PositionZ, cur_x, cur_y, cur_z)
    if not (cur_x == 0 and cur_y == 0 and cur_z == 0) and dis > 6 then
        return
    end

    SwitchPlayerStateToFly()
    nx_pause(0.2)
    y = y + 0.1
    setAngle(x, y, z)
    local temp_angle = role.AngleY
    nx_call("player_state\\state_input", "emit_player_input", role, 21, 36, x, y, z, 0, 3)
    role.state = "zdn_jump"
    nx_pause(2.8)
    role.move_dest_orient = temp_angle
    setCollide(x, y, z)
    collide()
    local out_time = TimerInit()
    while TimerDiff(out_time) < 3 and AbstructRunning do
        nx_pause(0.1)
        if not isFlying() then
            break
        end
    end
    StartClickTimer = 0
end

function collide(...)
    local game_visual = nx_value("game_visual")
    local role = nx_value("role")
    if not nx_is_valid(game_visual) or not nx_is_valid(role) then
        return
    end
    game_visual:SetRoleMoveDistance(role, 1)
    game_visual:SetRoleMaxMoveDistance(role, 1)
    game_visual:SwitchPlayerState(role, 1, 103)
    role.state = "zdn_jump"
end

function setCollide(x, y, z)
    local game_visual = nx_value("game_visual")
    local role = nx_value("role")
    if not nx_is_valid(game_visual) or not nx_is_valid(role) then
        return
    end
    game_visual:SetRoleMoveDestX(role, x)
    game_visual:SetRoleMoveDestY(role, y)
    game_visual:SetRoleMoveDestZ(role, z)
end

function setAngle(x, y, z)
    local role = nx_value("role")
    local scene_obj = nx_value("scene_obj")
    if not nx_is_valid(role) or not nx_is_valid(scene_obj) then
        return
    end
    scene_obj:SceneObjAdjustAngle(role, x, z)
end

function distance3d(bx, by, bz, dx, dy, dz)
    return math.sqrt((dx - bx) * (dx - bx) + (dy - by) * (dy - by) + (dz - bz) * (dz - bz))
end

function isFlying(...)
    local target_role = nx_value("role")
    local link_role = target_role:GetLinkObject("actor_role")
    if nx_is_valid(link_role) then
        target_role = link_role
    end
    local action_list = target_role:GetActionBlendList()
    for i, action in pairs(action_list) do
        if string.find(action, "jump") ~= nil then
            return true
        end
    end
    return false
end

function onOpenBossScene()
    CanJump = true
end

function getThichQuanBossList(guanId)
    return ThichQuanData[guanId].bossList
end

function processOpenBox()
    if not needOpenBox() then
        return false
    end
    if isCurseLoading() then
        return true
    end
    if nx_execute("zdn_logic_vat_pham", "IsDroppickShowed") then
        pickDropItem()
        return true
    end
    local box = nx_execute("zdn_logic_base", "GetNearestObj", nx_current(), "isBossChess")
    if not nx_is_valid(box) then
        return false
    end
    if GetDistanceToObj(box) > 2 then
        GoToObj(box)
        return true
    end
    StopFindPath()
    nx_execute("custom_sender", "custom_select", box.Ident)
    return true
end

function isBossChess(obj)
    local isClicked =
        nx_number(obj:QueryProp("Dead")) == 1 or
        (nx_find_custom(obj, "ZdnOpenTimer") and TimerDiff(obj.ZdnOpenTimer) > 30)
    local npcType = nx_number(obj:QueryProp("NpcType"))
    local isBossChess = nx_string(obj:QueryProp("RotatePara")) == "0"
    return (not isClicked) and npcType == 161 and isBossChess
end

function isCurseLoading()
    local load = nx_value("form_stage_main\\form_main\\form_main_curseloading")
    if nx_is_valid(load) and load.Visible then
        TimerCurseLoading = TimerInit()
    end
    return TimerDiff(TimerCurseLoading) < 1.5
end

function pickDropItem()
    nx_execute("zdn_logic_vat_pham", "PickItemFromPickItemData")
end

function needOpenBox()
    if not OpenBoxFlg then
        return false
    end
    return true
end
