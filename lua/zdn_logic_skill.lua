require("util_functions")
require("util_static_data")
require("zdn_util")
require("zdn_lib_moving")

local Data = {}
local UseMaster = {}
local UseSkillList = {}
local UseWeaponList = {}
local UseBookList = {}
local UseSkillProp = {}
local Running = false
local Paused = false
local TimerWeaponUseItem = 0
local LastWeaponItemIndex = 0
local TimerBookUseItem = 0
local LastBookItemIndex = 0

local MAX_SKILL = 8
local CHANGE_ATTRIBUTE_POINT_SKILL = {
    ["CS_change_1"] = "buf_CS_change_1",
    ["CS_change_2"] = "buf_CS_change_2",
    ["CS_change_3"] = "buf_CS_change_3",
    ["CS_change_4"] = "buf_CS_change_4",
    ["CS_change_258"] = "buf_CS_change_258",
    ["CS_change_259"] = "buf_CS_change_259",
    ["CS_change_515"] = "buf_CS_change_515",
    ["CS_change_260"] = "buf_CS_change_260"
}

function LoadSkillSet(set)
    initLoadSkill()

    loadUseMaster(set)
    loadUseSkillList(set)
    loadUseWeaponList(set)
    loadUseBookList(set)

    UseSkillProp.GoNearFlg = nx_string(IniReadUserConfig("KyNang", "GoNear", "0")) == "1" and true or false
    loadShortcut()
end

function AutoAttackDefaultSkillSet()
    if Running then
        return
    end
    Paused = false
    Running = true
    LoadSkillSet(getDefaultSkillSet())
    doAutoAttack()
end

function AutoAttack(set)
    if Running then
        return
    end
    Paused = false
    Running = true
    LoadSkillSet(set)
    doAutoAttack()
end

function FlexAttack()
    if Running then
        Paused = false
    else
        AutoAttackDefaultSkillSet()
    end
end

function StopAutoAttack()
    Running = false
end

function IsRunning()
    return Running == true
end

function TuSat()
    local player = nx_value("game_client"):GetPlayer()
    if not nx_is_valid(player) then
        return false
    end
    local hourseState = player:QueryProp("Mount")
    if nx_string(hourseState) ~= nx_string("") then
        nx_execute("custom_sender", "custom_send_ride_skill", nx_string("riding_dismount")) -- Xuống ngựa
        nx_pause(1)
    end
    local dangTuSat = HaveBuff("buf_CS_jh_tmjt06")
    if not dangTuSat then
        useSkillById("CS_jh_tmjt06")
    end
end

function DungTuSat()
    if HaveBuff("buf_CS_jh_tmjt06") then
        useSkillById("CS_jh_tmjt06")
    end
end

function IsPlayerDead()
    local state = getPlayerState()
    if state == "dead" or state == "swim_dead" then
        return true
    end
    return false
end

function StopParry()
    if isParry() then
        if nx_is_valid(nx_value("game_visual")) then
            Paused = false
            nx_value("game_visual"):CustomSend(nx_int(218), 0)
        end
    end
end

function StartParry()
    if not isParry() then
        local v = nx_value("game_visual")
        if nx_is_valid(v) then
            Paused = true
            v:CustomSend(nx_int(218), 1)
        end
    end
end

function Fly()
    if not isFlying() then
        SwitchPlayerStateToFly()
    end
end

function HaveBuff(buffId)
    local game_client = nx_value("game_client")
    if not nx_is_valid(game_client) then
        return false
    end
    local client_player = game_client:GetPlayer()
    if not nx_is_valid(client_player) then
        return false
    end
    if ObjHaveBuff(client_player, buffId) then
        return true
    end
    -- noi tu
    local buffer_effect = nx_value("BufferEffect")
    if not nx_is_valid(buffer_effect) then
        return false
    end
    if client_player:FindRecord("AddWuXueFacultyBufferRec") then
        local rownum = client_player:GetRecordRows("AddWuXueFacultyBufferRec")
        for i = 0, rownum - 1 do
            local index = client_player:QueryRecord("AddWuXueFacultyBufferRec", i, 0)
            local b = buffer_effect:GetBufferDescIDByIndex(1, index)
            if b == buffId then
                return true
            end
        end
    end
    -- lich luyen
    if client_player:FindRecord("LivePointChangeBufferRec") then
        local rownum = client_player:GetRecordRows("LivePointChangeBufferRec")
        for i = 0, rownum - 1 do
            local index = client_player:QueryRecord("LivePointChangeBufferRec", i, 0)
            local b = buffer_effect:GetBufferDescIDByIndex(2, index)
            if b == buffId then
                return true
            end
        end
    end
    return false
end

function ObjHaveBuff(obj, buffId)
    if not (nx_is_valid(obj)) then
        return false
    end
    local bufferList = nx_function("get_buffer_list", obj)
    local bufferCount = table.getn(bufferList) / 2
    for i = 1, bufferCount do
        if nx_string(bufferList[i * 2 - 1]) == nx_string(buffId) then
            return true
        end
    end
    return false
end

function HaveBuffPrefix(prefix)
    local obj = nx_value("game_client"):GetPlayer()
    if not (nx_is_valid(obj)) then
        return false
    end
    local bufferList = nx_function("get_buffer_list", obj)
    local bufferCount = table.getn(bufferList) / 2
    local tmp = ""
    for i = 1, bufferCount do
        tmp = nx_string(bufferList[i * 2 - 1])
        if string.find(tmp, prefix) ~= nil then
            return true
        end
    end
    return false
end

function LeaveTeam()
    if not isInTeam() then
        return
    end
    nx_execute("custom_sender", "custom_leave_team")
end

function NgoiThien()
    StopFindPath()
    XuongNgua()
    if nx_execute("zdn_logic_base", "GetLogicState") == 102 or isSwimming() then
        return
    end
    nx_execute("custom_sender", "custom_sitcross", 1)
end

function StopNgoiThien()
    if nx_execute("zdn_logic_base", "GetRoleState") == "sitcross" then
        nx_execute("custom_sender", "custom_sitcross", 0)
    end
end

function PauseAttack()
    if Running then
        Paused = true
    end
end

function ContinueAttack()
    if Running then
        Paused = false
    end
end

function GetSkillCoolDownType(config)
    return skill_static_query_by_id(config, "CoolDownCategory")
end

-- private
function initLoadSkill()
    if TimerUseSkill == nil then
        TimerUseSkill = {}
        TimerUseSkill.CheckDistance = 0
        TimerUseSkill.UseSkill = 0
    end
    UseMaster = {}
    UseMaster.WeaponUniqueID = "1"
    UseMaster.RageSkill = {}
    UseMaster.BreakSkill = {}

    for i = 1, MAX_SKILL do
        UseSkillList[i] = {}
        UseSkillList[i].ConfigID = "null"
        UseSkillList[i].SkillStyle = "1"
        UseSkillList[i].TargetType = "1"
        UseSkillList[i].CoolType = "1"
    end
    for i = 1, MAX_SKILL do
        UseWeaponList[i] = {}
        UseWeaponList[i].UniqueID = "1"
        UseWeaponList[i].ConfigID = "null"
    end
    for i = 1, MAX_SKILL do
        UseBookList[i] = {}
        UseBookList[i].UniqueID = "1"
        UseBookList[i].ConfigID = "null"
    end
    UseSkillProp.GoNearFlg = false
    TargetTypeList = {}
end

function loadUseSkillList(set)
    local text = nx_string(IniReadUserConfig("KyNang", "S" .. nx_string(set), ""))
    if text == "" then
        return
    end
    local list = util_split_string(text, ";")
    for i = 1, MAX_SKILL do
        local data = util_split_string(list[i], ",")
        if #data ~= 3 then
            return
        end
        UseSkillList[i] = loadOneSkill(data[1], data[2])
        if UseSkillList[i].ConfigID ~= "null" then
            nx_execute("custom_sender", "custom_set_shortcut", 190 + i - 1, "skill", UseSkillList[i].ConfigID)
        end
    end
end

function isSkillExists(config)
    local fight = nx_value("fight")
    if not nx_is_valid(fight) then
        return false
    end
    return nx_is_valid(fight:FindSkill(config))
end

function getSkillTargetType(config)
    return skill_static_query_by_id(config, "TargetType")
end

function loadUseWeaponList(set)
    local text = nx_string(IniReadUserConfig("KyNang", "W" .. nx_string(set), ""))
    if text == "" then
        return
    end
    local list = util_split_string(text, ";")
    for i = 1, MAX_SKILL do
        if list[i] ~= "null" then
            local data = util_split_string(list[i], ",")
            UseWeaponList[i].UniqueID = data[1]
        else
            UseWeaponList[i].UniqueID = UseMaster.WeaponUniqueID
        end
    end
end

function loadUseBookList(set)
    local text = nx_string(IniReadUserConfig("KyNang", "B" .. nx_string(set), ""))
    if text == "" then
        return
    end
    local list = util_split_string(text, ";")
    for i = 1, MAX_SKILL do
        local data = util_split_string(list[i], ",")
        if list[i] ~= "null" then
            local data = util_split_string(list[i], ",")
            UseBookList[i].UniqueID = data[1]
        else
            UseBookList[i].UniqueID = "1"
        end
    end
end

function loadShortcut()
    local form = nx_value("form_stage_main\\form_main\\form_main_shortcut")
    if not nx_is_valid(form) or form.grid_shortcut_main == nil then
        return
    end
    local grid = form.grid_shortcut_main
    local current = grid.page
    grid.page = 19
    nx_execute("form_stage_main\\form_main\\form_main_shortcut", "on_shortcut_record_change", grid)
    nx_pause(1)
    grid.page = current
    nx_execute("form_stage_main\\form_main\\form_main_shortcut", "on_shortcut_record_change", grid)
    for i = 0, MAX_SKILL + 1 do -- them no chieu
        nx_execute("custom_sender", "custom_remove_shortcut", 190 + i)
    end
end

function getDefaultSkillSet()
    return nx_number(IniReadUserConfig("KyNang", "Selected", "1"))
end

function doAutoAttack()
    useMasterWeapon()
    while Running do
        if not Paused then
            if checkNearTarget() then
                loopAttack()
            end
        end
        nx_pause(0.05)
    end
end

function checkNearTarget()
    if not UseSkillProp.GoNearFlg then
        return true
    end

    local o = getTargetObj()
    if nx_is_valid(o) and not isDead(o) then
        if GetDistanceToObj(o) > 2.8 then
            if not nx_execute("zdn_logic_thien_the", "IsRunning") and not nx_execute("zdn_logic_ltt", "IsRunning") then
                GoToObj(o)
            end
            return false
        end
    end
    return true
end

function isDead(obj)
    if not nx_is_valid(obj) then
        return true
    end
    return nx_number(obj:QueryProp("Dead")) == 1
end

function getRage()
    local player = nx_value("game_client"):GetPlayer()
    if not nx_is_valid(player) then
        return 0
    end
    local sp = player:QueryProp("SP")
    return tonumber(sp)
end

function loopAttack()
    if HaveBuff("buf_hurt_1") then
        return
    end
    checkWeapon()
    checkBook()
    local obj = getTargetObj()
    if nx_is_valid(obj) and isObjParry(obj) and UseMaster.BreakSkill.ConfigID ~= "null" then
        if not isSkillOnCooldown(UseMaster.BreakSkill) then
            local fight = nx_value("fight")
            if nx_is_valid(fight) then
                fight:StopUseSkill()
            end
            useSkill(UseMaster.BreakSkill)
            return
        end
    end
    if
        getRage() > 50 and not HaveBuff("buf_" .. UseMaster.RageSkill.ConfigID) and
            UseMaster.RageSkill.ConfigID ~= "null" and
            useSkill(UseMaster.RageSkill)
     then
        return
    end
    for i = 1, MAX_SKILL do
        if useSkill(UseSkillList[i]) then
            return
        end
    end
end

function isSkillOnCooldown(skill)
    local normalSkillType = skill.CoolType
    local gui = nx_value("gui")
    local onCooldown = gui.CoolManager:IsCooling(nx_int(normalSkillType), nx_int(-1))
    if onCooldown then
        return true
    end
    if skill.HasVoKyFlg then
        local normalSkill = skill.ConfigID
        local voKySkill = GetSkillCoolDownType("wuji_" .. normalSkill)
        return gui.CoolManager:IsCooling(nx_int(voKySkill), nx_int(-1))
    end
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

function useSkill(skill)
    if skill.ConfigID == "null" then
        return false
    end
    if isSkillOnCooldown(skill) then
        return false
    end
    local buff = CHANGE_ATTRIBUTE_POINT_SKILL[skill.ConfigID]
    if buff ~= nil then
        if HaveBuff(buff) then
            return false
        end
    end
    local playerState = getPlayerState()
    if playerState == "motion" or playerState == "locked" or playerState == "tanqin" then
        return true
    end
    if nx_number(skill.TargetType) == 4 then
        local targetObj = getTargetObj()
        if not nx_is_valid(targetObj) or isDead(targetObj) then
            return false
        end
    end

    local player = nx_value("game_client"):GetPlayer()
    if not nx_is_valid(player) then
        return
    end
    local horseState = player:QueryProp("Mount")
    if nx_string(horseState) ~= nx_string("") then
        nx_execute("custom_sender", "custom_send_ride_skill", nx_string("riding_dismount"))
    end

    if skill.SkillStyle == "2" and not isFlying() then
        Fly()
        return true
    end
    useSkillById(skill.ConfigID)
    return true
end

function isFlying()
    local state = getPlayerState()
    return state == "jump_fall" or state == "jump" or state == "jump_second" or state == "jump_third"
end

function checkWeapon()
    local client = nx_value("game_client")
    if not nx_is_valid(client) then
        return
    end
    local p = client:GetPlayer()
    if not nx_is_valid(p) then
        return
    end
    local sId = nx_string(p:QueryProp("CurSkillID"))
    if sId == "" or sId == "0" then
        return
    end

    local w = UseMaster.WeaponUniqueID
    for i = 1, MAX_SKILL do
        if UseSkillList[i].ConfigID == sId or "wuji_" .. UseSkillList[i].ConfigID == sId then
            w = UseWeaponList[i].UniqueID
            break
        end
    end
    if w == "1" then
        return
    end
    local equip = client:GetView("1")
    local bag = client:GetView("121")
    if not nx_is_valid(equip) or not nx_is_valid(bag) then
        return
    end
    local currentWeapon = equip:GetViewObj("22")
    if nx_is_valid(currentWeapon) and nx_string(currentWeapon:QueryProp("UniqueID")) == w then
        return
    end
    for i = 1, 100 do
        local item = bag:GetViewObj(nx_string(i))
        if nx_is_valid(item) and nx_string(item:QueryProp("UniqueID")) == w then
            if TimerDiff(TimerWeaponUseItem) < 0.2 and LastWeaponItemIndex == i then
                return
            end
            local grid = nx_value("GoodsGrid")
            if not nx_is_valid(grid) then
                return
            end
            TimerWeaponUseItem = TimerInit()
            LastWeaponItemIndex = i
            grid:ViewUseItem(121, i, "", "")
            return
        end
    end
end

function checkBook()
    local client = nx_value("game_client")
    if not nx_is_valid(client) then
        return
    end
    local p = client:GetPlayer()
    if not nx_is_valid(p) then
        return
    end
    local sId = nx_string(p:QueryProp("CurSkillID"))
    if sId == "" or sId == "0" then
        return
    end

    local b = "null"
    for i = 1, MAX_SKILL do
        if UseSkillList[i].ConfigID == sId or "wuji_" .. UseSkillList[i].ConfigID == sId then
            b = UseBookList[i].UniqueID
            break
        end
    end
    if b == "null" then
        return
    end
    local equip = client:GetView("1")
    local bag = client:GetView("121")
    if not nx_is_valid(equip) or not nx_is_valid(bag) then
        return
    end
    local currentBook = equip:GetViewObj("24")
    if nx_is_valid(currentBook) and nx_string(currentBook:QueryProp("UniqueID")) == b then
        return
    end
    for i = 1, 100 do
        local item = bag:GetViewObj(nx_string(i))
        if nx_is_valid(item) and nx_string(item:QueryProp("UniqueID")) == b then
            if TimerDiff(TimerBookUseItem) < 0.2 and LastBookItemIndex == i then
                return
            end
            local grid = nx_value("GoodsGrid")
            if not nx_is_valid(grid) then
                return
            end
            TimerBookUseItem = TimerInit()
            LastBookItemIndex = i
            grid:ViewUseItem(121, i, "", "")
            return
        end
    end
end

function createDecal()
    nx_execute("game_effect", "add_ground_pick_decal", "map\\tex\\Target_area_G.dds", 1, 20)
end

function findDecal()
    return nx_is_valid(nx_value("ground_pick_decal"))
end

function setDecalPos(x, y, z)
    local decal = nx_value("ground_pick_decal")
    if not nx_is_valid(decal) then
        createDecal()
    end
    decal = nx_value("ground_pick_decal")
    if not nx_is_valid(decal) then
        return
    end
    decal.PosX, decal.PosY, decal.PosZ = x, y, z
end

function setDecal()
    if not findDecal() then
        createDecal()
    end
    local x, y, z = getPlayerPos()
    local o = getTargetObj()
    if nx_is_valid(o) and not isDead(o) then
        local visual = getVisualObj(o)
        if nx_is_valid(visual) then
            x, y, z = visual.PositionX, visual.PositionY, visual.PositionZ
        end
    end
    setDecalPos(x, y, z)
end

function getPlayerPos()
    local role = nx_value("role")
    if not nx_is_valid(role) then
        return 0, 0, 0
    end
    return role.PositionX, role.PositionY, role.PositionZ
end

function getVisualObj(obj)
    if not nx_is_valid(obj) then
        return
    end
    return nx_value("game_visual"):GetSceneObj(obj.Ident)
end

function useSkillById(skillId)
    local fight = nx_value("fight")
    if not nx_is_valid(fight) then
        return false
    end
    if TargetTypeList == nil then
        TargetTypeList = {}
    end
    if TargetTypeList[skillId] == nil then
        TargetTypeList[skillId] = getSkillTargetType(skillId)
    end
    if nx_number(TargetTypeList[skillId]) == nx_number(1) then
        setDecal()
    end
    fight:TraceUseSkill(skillId, false, false)
    nx_execute("game_effect", "del_ground_pick_decal")
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

function isParry()
    local player = nx_value("game_client"):GetPlayer()
    return isObjParry(player)
end

function isObjParry(obj)
    if not nx_is_valid(obj) then
        return false
    end
    local bufferList = nx_function("get_buffer_list", obj)
    local bufferCount = table.getn(bufferList) / 2
    for i = 1, bufferCount do
        if nx_string(bufferList[i * 2 - 1]) == nx_string("BuffInParry") then
            return true
        end
    end
    return false
end

function isInTeam()
    local player = nx_value("game_client"):GetPlayer()
    if not (nx_is_valid(player)) then
        return false
    end
    local teamCaptian = player:QueryProp("TeamCaptain")
    if nx_widestr(teamCaptian) ~= nx_widestr(0) and nx_widestr(teamCaptian) ~= nx_widestr("") then
        return true
    end
    return false
end

function isSwimming()
    local state = nx_execute("zdn_logic_base", "GetRoleState")
    return string.find(state, "swim") ~= nil
end

function loadUseMaster(set)
    local text = nx_string(IniReadUserConfig("KyNang", "M" .. nx_string(set), ""))
    if text == "" then
        return
    end
    local list = util_split_string(text, ";")
    if #list ~= 3 then
        return
    end

    local p = util_split_string(list[1], ",")
    UseMaster.WeaponUniqueID = p[1]

    p = util_split_string(list[2], ",")
    UseMaster.RageSkill = loadOneSkill(p[1], p[2])
    if UseMaster.RageSkill.ConfigID ~= "null" then
        nx_execute("custom_sender", "custom_set_shortcut", 190 + MAX_SKILL, "skill", UseMaster.RageSkill.ConfigID)
    end

    p = util_split_string(list[3], ",")
    UseMaster.BreakSkill = loadOneSkill(p[1], p[2])
    if UseMaster.BreakSkill.ConfigID ~= "null" then
        nx_execute("custom_sender", "custom_set_shortcut", 190 + MAX_SKILL + 1, "skill", UseMaster.BreakSkill.ConfigID)
    end
end

function loadOneSkill(cId, sStyle)
    if sStyle == "2" then
        if isSkillExists(cId .. "_sky") then
            cId = cId .. "_sky"
        end
    elseif sStyle == "3" then
        if isSkillExists(cId .. "_hide") then
            cId = cId .. "_hide"
        elseif cId == "CS_jh_lhbwq03" then
            cId = "CS_jh_lhbwq08"
        end
    end

    local skill = {}
    skill.ConfigID = cId
    skill.SkillStyle = sStyle
    skill.TargetType = getSkillTargetType(cId)
    skill.CoolType = GetSkillCoolDownType(cId)
    if isSkillExists("wuji_" .. cId) then
        -- neu co skill vo ky
        skill.HasVoKyFlg = true
    else
        skill.HasVoKyFlg = false
    end
    return skill
end

function useMasterWeapon()
    local client = nx_value("game_client")
    if not nx_is_valid(client) then
        return
    end
    local w = UseMaster.WeaponUniqueID
    if w == "1" then
        return
    end
    local equip = client:GetView("1")
    local bag = client:GetView("121")
    if not nx_is_valid(equip) or not nx_is_valid(bag) then
        return
    end
    local currentWeapon = equip:GetViewObj("22")
    if not nx_is_valid(currentWeapon) or nx_string(currentWeapon:QueryProp("UniqueID")) == w then
        return
    end
    for i = 1, 100 do
        local item = bag:GetViewObj(nx_string(i))
        if nx_is_valid(item) and nx_string(item:QueryProp("UniqueID")) == w then
            local grid = nx_value("GoodsGrid")
            if not nx_is_valid(grid) then
                return
            end
            TimerWeaponUseItem = TimerInit()
            LastWeaponItemIndex = i
            grid:ViewUseItem(121, i, "", "")
            return
        end
    end
end
