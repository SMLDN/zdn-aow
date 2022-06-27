require("zdn_util")
require("zdn_lib_moving")
local PRIZE_FORM_PATH = "form_stage_main\\form_xmqy_detail"
local FACULTY_BACK_FORM_PATH = "form_stage_main\\form_wuxue\\form_faculty_back"
local MAIN_REQUEST_FORM_PATH = "form_stage_main\\form_main\\form_main_request"
local NOTICE_SHORTCUT_FORM_PATH = "form_stage_main\\form_main\\form_notice_shortcut"
local BATTLE_FORM_PATH = "form_stage_main\\form_battlefield\\form_battlefield_order"
local ITEM_DICH_CAN_DAN = "haiwai_yuenan_zcxiuwei_01"
local ITEM_CHAN_KHI = "zhenqi_activity_001_d"
local ITEM_TU_VI = "additem_0021"
local ITEM_HOP_CAM_1 = "box_battle_zhuangbei"
local ITEM_HOP_CAM_2 = "box_battle_zadan"

local RECEIVE_LETTER_NAME = "RecvLetterRec"
local MAIL_TYPE_SYS = 2
local LETTER_SYSTEM_POST_USER = 101
local POST_TABLE_TYPE = 2
local POST_TABLE_APPEDIXVALUE = 7
local POST_TABLE_GOLD = 5
local POST_TABLE_SILVER = 6
local POST_TABLE_SERIALNO = 10

local Running = false

local FIX_FIND_PATH_POINT = {
    {
        {1739.250366, -16.041, 1477.250122},
        {1746.9714355469, -15.401000976563, 1478.3751220703}
    },
    {
        {1829.2504882813, -7.4160003662109, 1557.2487792969},
        {1826.7957763672, -7.4160003662109, 1540.0101318359}
    },
    {
        {1819.2490234375, -7.4160003662109, 1557.2503662109},
        {1826.7957763672, -7.4160003662109, 1540.0101318359}
    },
    {
        {1759.2495117188, -9.2310009002686, 1427.2496337891},
        {1770.7218017578, -9.2310009002686, 1438.6870117188}
    },
    {
        {1749.2504882813, -15.03600025177, 1477.2497558594},
        {1777.5733642578, -12.216000556946, 1476.0433349609}
    },
    {
        {1849.2506103516, -7.4190001487732, 1387.2498779297},
        {1844.5128173828, -7.4190001487732, 1405.4642333984}
    },
    {
        {1809.2487792969, -7.6338491439819, 1387.2510986328},
        {1844.5128173828, -7.4190001487732, 1405.4642333984}
    },
    {
        {1806.2462158203, -7.4117994308472, 1397.2457275391},
        {1808.8922119141, -7.411799076843, 1399.9937744141}
    }
}

function IsRunning()
    return Running
end

function CanRun()
    local resetTimeStr = IniReadUserConfig("ChienTruong", "ResetTime", "")
    if resetTimeStr == "" then
        return true
    end
    return nx_execute("zdn_logic_base", "GetCurrentDayStartTimestamp") >= nx_number(resetTimeStr)
end

function IsTaskDone()
    return not CanRun()
end

function Start()
    if Running then
        return
    end
    Running = true
    if not CanRun() then
        Stop()
        return
    end
    nx_execute("zdn_logic_skill", "LeaveTeam")
    while Running do
        loopChienTruong()
        nx_pause(0.2)
    end
end

function Stop()
    Running = false
    nx_execute("zdn_logic_skill", "StopAutoAttack")
    nx_execute("zdn_logic_common_listener", "ResolveListener", nx_current(), "on-task-stop")
end

-- private
function loopChienTruong()
    if IsMapLoading() then
        return
    end
    if isDead(nx_execute("zdn_logic_base", "GetPlayer")) then
        if (nx_execute("zdn_logic_skill", "IsRunning")) then
            nx_execute("zdn_logic_skill", "PauseAttack")
        end
        triThuong()
        return
    end
    if GetCurMap() ~= "battle_gmp" then
        prepareBattle()
    else
        onBattle()
    end
end

function onBattle()
    if isBattleFinish() then
        leaveBattle()
        return
    end
    attackOtherPlayer()
end

function prepareBattle()
    if isBeAttack() then
        nx_execute("zdn_logic_skill", "TuSat")
        TimerProcessing = TimerInit()
    end
    if processPrizeForm() or processItem() or processMail() then
        TimerProcessing = TimerInit()
    end
    if TimerDiff(TimerProcessing) < 1 then
        return
    end
    registerBattle()
end

function triThuong()
    if GetCurMap() == "battle_gmp" then
        nx_execute("custom_sender", "custom_relive", 10)
    else
        nx_execute("custom_sender", "custom_relive", 2)
    end
end

function fixPosition(posMap)
    local role = nx_value("role")
    local pathFinding = nx_value("path_finding")
    if not nx_is_valid(role) or not nx_is_valid(pathFinding) then
        return
    end
    local x, y, z = role.PositionX, role.PositionY, role.PositionZ
    for _, data in pairs(posMap) do
        if distance3d(x, y, z, data[1][1], data[1][2], data[1][3]) < 1 then
            pathFinding:FindPathScene(GetCurMap(), data[2][1], data[2][2], data[2][3], 0)
            return true
        end
    end
    return false
end

function fixFindPath()
    if TimerDiff(TimerFixFindPath) < 3 then
        return
    end
    if fixPosition(FIX_FIND_PATH_POINT) then
        TimerFixFindPath = TimerInit()
    end
end

function goToCenter()
    if GetDistance(1819.563477, -5.249885, 1475.334106) < 10 then
        nx_execute("zdn_logic_skill", "NgoiThien")
        return
    end
    if TimerDiff(TimerGoToCenter) < 3 then
        return
    end
    TimerGoToCenter = TimerInit()
    nx_execute("Listener", "addListen", nx_current(), "13000", "fixFindPath", 5)
    GoToPosition(1819.563477, -5.249885, 1475.334106)
end

function attackOtherPlayer()
    local enemy = nx_execute("zdn_logic_base", "GetNearestObj", nx_current(), "isNotDead", "isAttackable")
    if not nx_is_valid(enemy) then
        nx_execute("zdn_logic_skill", "PauseAttack")
        goToCenter()
    else
        nx_execute("zdn_logic_skill", "StopNgoiThien")
        nx_execute("custom_sender", "custom_select", enemy.Ident)
        if GetDistanceToObj(enemy) < 2.8 then
            if (nx_execute("zdn_logic_skill", "IsRunning")) then
                StopFindPath()
                nx_execute("zdn_logic_skill", "ContinueAttack")
            else
                nx_execute("zdn_logic_skill", "AutoAttackDefaultSkillSet")
            end
        else
            nx_execute("zdn_logic_skill", "PauseAttack")
            GoToObj(enemy)
        end
    end
end

function isDead(obj)
    if not nx_is_valid(obj) then
        return true
    end
    return nx_number(obj:QueryProp("Dead")) == 1
end

function isBattleFinish()
    local battleForm = nx_execute("zdn_logic_base", "GetChildForm", BATTLE_FORM_PATH)
    if nx_is_valid(battleForm) and battleForm.Visible then
        return true
    end
    return false
end

function leaveBattle()
    StopFindPath()
    nx_execute("zdn_logic_skill", "StopAutoAttack")
    nx_pause(1)
    nx_execute("form_stage_main\\form_battlefield\\form_battlefield_join", "request_leave_battlefield")
    nx_pause(30)
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
        return true
    end
end

function isBeAttack()
    return nx_execute("zdn_logic_base", "GetLogicState") == 1
end

function processItem()
    local i = nx_execute("zdn_logic_vat_pham", "FindItemIndexFromVatPham", ITEM_DICH_CAN_DAN)
    if i ~= 0 then
        nx_execute("Listener", "addListen", nx_current(), "8014", "onTaskDone", 2)
        nx_execute("Listener", "addListen", nx_current(), "power_redeem_4", "onTaskDone", 2)
        nx_execute("zdn_logic_vat_pham", "UseItem", 2, i)
        return true
    end

    i = nx_execute("zdn_logic_vat_pham", "FindItemIndexFromVatPham", ITEM_CHAN_KHI)
    if i ~= 0 then
        nx_execute("Listener", "addListen", nx_current(), "8076", "deleteItemByConfig", 2, ITEM_CHAN_KHI)
        nx_execute("Listener", "addListen", nx_current(), "8077", "deleteItemByConfig", 2, ITEM_CHAN_KHI)
        nx_execute("zdn_logic_vat_pham", "UseItem", 2, i)
        return true
    end

    i = nx_execute("zdn_logic_vat_pham", "FindItemIndexFromVatPham", ITEM_TU_VI)
    if i ~= 0 then
        nx_execute("zdn_logic_vat_pham", "UseItem", 2, i)
        return true
    end

    local boxI = nx_execute("zdn_logic_vat_pham", "FindItemIndexFromVatPham", ITEM_HOP_CAM_1)
    if boxI == 0 then
        boxI = nx_execute("zdn_logic_vat_pham", "FindItemIndexFromVatPham", ITEM_HOP_CAM_2)
    end
    if boxI == 0 then
        boxI = nx_execute("zdn_logic_vat_pham", "FindItemIndexFromVatPham", "haiwai_yn_xyyb_01")
    end
    if boxI == 0 then
        boxI = nx_execute("zdn_logic_vat_pham", "FindItemIndexFromVatPham", "haiwai_yn_xyyb_02")
    end
    if boxI == 0 then
        boxI = nx_execute("zdn_logic_vat_pham", "FindItemIndexFromVatPham", "haiwai_yn_xyyb_03")
    end
    if boxI == 0 then
        return false
    end
    if nx_execute("zdn_logic_vat_pham", "IsDroppickShowed") then
        nx_execute("zdn_logic_vat_pham", "PickAllDropItem")
    else
        nx_execute("zdn_logic_vat_pham", "UseItem", 2, boxI)
    end
    return true
end

function getDropItemName(i)
    local client = nx_value("game_client")
    if not nx_is_valid(client) then
        return nil
    end
    local view = client:GetView(nx_string(80))
    if not nx_is_valid(view) then
        return nil
    end
    local item = view:GetViewObj(nx_string(i))
    if not nx_is_valid(item) then
        return nil
    end
    return item:QueryProp("ConfigID")
end

function processMail()
    local client = nx_value("game_client")
    local player = client:GetPlayer()
    local hasMail = false
    if not nx_is_valid(player) then
        return hasMail
    end

    local rownum = player:GetRecordRows(RECEIVE_LETTER_NAME)
    for row = rownum - 1, 0, -1 do
        local postType = nx_number(player:QueryRecord(RECEIVE_LETTER_NAME, row, POST_TABLE_TYPE))
        local silver = nx_number(player:QueryRecord(RECEIVE_LETTER_NAME, row, POST_TABLE_SILVER))
        local gold = nx_number(player:QueryRecord(RECEIVE_LETTER_NAME, row, POST_TABLE_GOLD))
        if postType == LETTER_SYSTEM_POST_USER and silver == 0 and gold == 0 then
            local serialNo = player:QueryRecord(RECEIVE_LETTER_NAME, row, POST_TABLE_SERIALNO)
            local appedix = player:QueryRecord(RECEIVE_LETTER_NAME, row, POST_TABLE_APPEDIXVALUE)
            if appedix == "" then
                deleteEmptyMail(serialNo)
                hasMail = true
            elseif string.find(appedix, ITEM_HOP_CAM_1) or string.find(appedix, ITEM_HOP_CAM_2) then
                withdrawMail(serialNo)
                hasMail = true
            end
        end
    end
    nx_pause(0.5)
    return hasMail
end

function deleteEmptyMail(serialNo)
    nx_execute("custom_sender", "custom_select_letter", 1, serialNo, 1)
    nx_execute("custom_sender", "custom_del_letter", 0, MAIL_TYPE_SYS)
end

function withdrawMail(serialNo)
    nx_execute("custom_sender", "custom_get_appendix", serialNo)
end

function registerBattle()
    if receivedBattleRequest() then
        acceptBattleRequest()
        return
    end
    goBattleQueue()
end

function acceptBattleRequest()
    nx_execute("custom_sender", "custom_request_answer", 51, nx_widestr("System"), 1)
    nx_pause(16)
end

function goBattleQueue()
    nx_execute("zdn_logic_common_listener", "ResolveListener", nx_current(), "on-task-interrupt")
    if isOnQueue() then
        return
    end
    nx_execute("custom_sender", "custom_battlefield", 1, 1, "6X6_gmp", 0, 1, 5, "group_karma_52", "group_karma_69")
    nx_pause(1)
end

function receivedBattleRequest()
    local nMax = nx_execute(MAIN_REQUEST_FORM_PATH, "get_request_prop", 0)
    for i = 1, nMax do
        if nx_execute(MAIN_REQUEST_FORM_PATH, "get_request_prop", i, 1) == 51 then
            nx_execute(MAIN_REQUEST_FORM_PATH, "remove_request", i)
            return true
        end
    end
    return false
end

function isOnQueue()
    local form = nx_value(NOTICE_SHORTCUT_FORM_PATH)
    return string.find(nx_string(form.single_notice), "23") ~= nil
end

function distance3d(bx, by, bz, dx, dy, dz)
    return math.sqrt((dx - bx) * (dx - bx) + (dy - by) * (dy - by) + (dz - bz) * (dz - bz))
end

function onTaskDone()
    IniWriteUserConfig("ChienTruong", "ResetTime", nx_execute("zdn_logic_base", "GetNextDayStartTimestamp"))
    Stop()
end

function deleteItemByConfig(config)
    local i = nx_execute("zdn_logic_vat_pham", "FindItemIndexFromVatPham", config)
    if i ~= 0 then
        nx_execute("custom_sender", "custom_delete_item", 2, i, 100)
    end
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
