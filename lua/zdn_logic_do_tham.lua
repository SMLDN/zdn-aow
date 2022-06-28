require("form_stage_main\\form_tvt\\define")
require("util_gui")
require("zdn_lib\\util_functions")
require("zdn_util")
require("zdn_lib_moving")

local Running = false
local SPY_HOME_POINT_LIST = {}
local SPY_INFO = {}
local MY_SCHOOL = {}
local AN_THE_INFO = {}
local TASK_INDEX_LIST = {
    [578] = 1, --CYV
    [579] = 2, --CB
    [580] = 3, --QTD
    [581] = 4, --CLC
    [582] = 5, -- DM
    [583] = 6, --NM
    [584] = 7, --VD
    [585] = 8, --TL
    [1335] = 9, --MG
    [1388] = 10 -- TS
}
local curPoint = 1
local myInfo = {}
local spyMap = {}
local InstantDieFlg = false

function IsRunning()
    return Running
end

function CanRun()
    return not IsTaskDone()
end

function IsTaskDone()
    local resetTimeStr = IniReadUserConfig("DoTham", "ResetTime", "")
    if resetTimeStr == "" then
        return false
    end
    return nx_execute("zdn_logic_base", "GetCurrentDayStartTimestamp") < nx_number(resetTimeStr)
end

function Start()
    if Running then
        return
    end
    loadConfig()
    loadData()
    Running = true
    while Running do
        loopDoTham()
        nx_pause(0.2)
    end
end

function Stop()
    Running = false
    StopFindPath()
    nx_execute("zdn_logic_common_listener", "ResolveListener", nx_current(), "on-task-stop")
end

function loopDoTham()
    if IsMapLoading() then
        return
    end
    local times = nx_execute("form_stage_main\\form_tvt\\form_tvt_main", "get_tvt_times", 0)
    if nx_int(times) == nx_int(5) then
        onTaskDone()
        return
    end
    spyIndex = getTaskSpy()
    if spyIndex == 999 then
        onTaskDone()
        return
    end
    spyMap = SPY_INFO[spyIndex].mapId
    myInfo = getMyInfo()

    if getTrangThaiDoTham() ~= nil then
        if getSoTinhBao() > nx_int(0) then
            if GetCurMap() == getMySchoolMapId() then
                traNhiemVu()
            else
                veMonPhai()
            end
        else
            layTinhBao()
        end
    else
        nhanNhiemVu()
    end
end

function loadData()
    SPY_INFO = {}
    MY_SCHOOL = {}
    AN_THE_INFO = {}

    setSpyHomePointList()
    setSpyInfoList()
end

function setSpyInfoList()
    local SPY_INFO_FILE = nx_resource_path() .. "zdn\\data\\dotham.ini"
    local setNum = nx_number(IniRead(SPY_INFO_FILE, "list", "set", 0))
    local schoolCnt = nx_number(IniRead(SPY_INFO_FILE, "list", "school", 10))
    for i = 1, schoolCnt do
        local npc_noi_ung = IniRead(SPY_INFO_FILE, "npc_noi_ung", i, "0")
        local menuNoiUng = IniRead(SPY_INFO_FILE, "npc_noi_ung", "menu", "0")
        local info = IniRead(SPY_INFO_FILE, "info", i, "0")

        info = util_split_wstring(info, ";")

        npc_noi_ung = util_split_wstring(npc_noi_ung, ";")
        local npcNoiUng = npc_noi_ung[1]

        table.remove(npc_noi_ung, 1)

        local listPoint = {}
        for _, pos in pairs(npc_noi_ung) do
            local temp = util_split_wstring(pos, ",")
            local atable = {
                ["posX"] = nx_number(temp[1]),
                ["posY"] = nx_number(temp[2]),
                ["posZ"] = nx_number(temp[3])
            }
            table.insert(listPoint, atable)
        end
        SPY_INFO[i] = {
            ["mapId"] = nx_string(info[1]),
            ["spySchool"] = nx_string(info[2]),
            ["menu"] = info[3] .. nx_widestr(";") .. info[4],
            ["menuNoiUng"] = menuNoiUng,
            ["listScriptPoint"] = listPoint,
            ["npcNoiUng"] = npcNoiUng
        }
    end

    for i = 1, setNum do
        local school = IniRead(SPY_INFO_FILE, "my_school", i, "0")
        local menu_in = IniRead(SPY_INFO_FILE, "menu_in", i, "0")
        local menu_out = IniRead(SPY_INFO_FILE, "menu_out", i, "0")
        local zhangmen = IniRead(SPY_INFO_FILE, "zhangmen", i, "0")
        local npc_quest = IniRead(SPY_INFO_FILE, "npc_quest", i, "0")
        local mySchool = util_split_wstring(school, ",")

        zhangmen = util_split_wstring(zhangmen, ",")
        zhangmen[2] = nx_number(zhangmen[2])
        zhangmen[3] = nx_number(zhangmen[3])
        zhangmen[4] = nx_number(zhangmen[4])
        zhangmen[5] = nx_string(zhangmen[5])

        npc_quest = util_split_wstring(npc_quest, ",")
        npc_quest[2] = nx_number(npc_quest[2])
        npc_quest[3] = nx_number(npc_quest[3])
        npc_quest[4] = nx_number(npc_quest[4])
        npc_quest[5] = nx_string(npc_quest[5])

        MY_SCHOOL[i] = {
            ["menuInput"] = menu_in,
            ["menuOutput"] = menu_out,
            ["zhangmen"] = zhangmen,
            ["npcQuest"] = npc_quest,
            ["myHome"] = nx_string(mySchool[1]),
            ["school"] = nx_string(mySchool[1]),
            ["mapId"] = nx_string(mySchool[2])
        }
    end

    setNum = nx_number(IniRead(SPY_INFO_FILE, "list", "anthe", 0))
    for i = 1, setNum do
        local temp = IniRead(SPY_INFO_FILE, "an_the", i, "0")
        temp = util_split_wstring(temp, ",")
        local anTheNpc = IniRead(SPY_INFO_FILE, "an_the_npc", i, "0")
        local menu = IniRead(SPY_INFO_FILE, "an_the_menu", i, "0")
        anTheNpc = util_split_wstring(anTheNpc, ",")
        menu = util_split_wstring(menu, ";")
        anTheNpc[2] = nx_number(anTheNpc[2])
        anTheNpc[3] = nx_number(anTheNpc[3])
        anTheNpc[4] = nx_number(anTheNpc[4])
        anTheNpc[5] = nx_string(anTheNpc[5])
        AN_THE_INFO[i] = {
            ["homePointId"] = nx_string(temp[1]),
            ["mapId"] = nx_string(temp[2]),
            ["npc"] = anTheNpc,
            ["menu"] = menu
        }
    end
end

function setSpyHomePointList()
    HOME_POINT_FILE = nx_resource_path() .. "zdn\\data\\homepoint.ini"
    local map = nx_string(IniRead(HOME_POINT_FILE, "school", "map", "0"))
    local mapList = util_split_string(map, ";")
    SPY_HOME_POINT_LIST = {}
    for i = 1, #mapList do
        local mapInfo = util_split_string(mapList[i], ",")
        SPY_HOME_POINT_LIST[i] = {
            ["mapId"] = mapInfo[1],
            ["mapPoint"] = mapInfo[2]
        }
    end
end

function onTaskDone()
    IniWriteUserConfig("DoTham", "ResetTime", nx_execute("zdn_logic_base", "GetNextDayStartTimestamp"))
    Stop()
end

function getTaskSpy()
    local client = nx_value("game_client")
    local player = client:GetPlayer()
    if not nx_is_valid(player) then
        return 1
    end
    local rec = "Task_Record"
    local rows = player:GetRecordRows(rec)
    if nx_int(rows) <= nx_int(0) then
        return 1
    end
    local hasDoThamQuest = false
    for i = 0, rows - 1 do
        local taskIndex = player:QueryRecord(rec, i, 2)
        if nx_int(taskIndex) == nx_int(303) then
            hasDoThamQuest = true
            local taskCurNum = player:QueryRecord(rec, i, 4)
            local taskMaxNum = player:QueryRecord(rec, i, 5)
            if nx_int(taskCurNum) < nx_int(taskMaxNum) then
                local taskKey = nx_number(player:QueryRecord(rec, i, 6))
                if TASK_INDEX_LIST[taskKey] ~= nil then
                    return TASK_INDEX_LIST[taskKey]
                end
            end
        end
        if hasDoThamQuest and i == rows - 1 then
            return 999
        end
    end
    local school = player:QueryProp("School")
    if nx_string(school) == nx_string("school_jinyiwei") or getMyHome() == "HomePointborn02J" then
        return 2
    end
    return 1
end

function getMyInfo()
    local myHome = getMyHome()
    for i = 1, #MY_SCHOOL do
        if nx_string(myHome) == nx_string(MY_SCHOOL[i].myHome) then
            return MY_SCHOOL[i]
        end
    end
    return MY_SCHOOL[9]
end

function getMyHome()
    local client = nx_value("game_client")
    local player = client:GetPlayer()
    if not (nx_is_valid(player)) then
        return "HomePointborn02I"
    end
    local nCount = player:GetRecordRows("HomePointList")
    if nx_int(nCount) <= nx_int(0) then
        return "HomePointborn02I"
    end
    for i = 0, nCount - 1 do
        local hp_id = nx_string(player:QueryRecord("HomePointList", i, 0))
        local hp_type = player:QueryRecord("HomePointList", i, 1)
        if nx_int(hp_type) == nx_int(2) then
            return hp_id
        end
    end

    return "HomePointborn02I"
end

function getTrangThaiDoTham()
    local client = nx_value("game_client")
    local player = client:GetPlayer()
    if not nx_is_valid(player) then
        return
    end
    local rows = player:GetRecordRows("InteractTraceRec")
    if nx_int(rows) <= nx_int(0) then
        return
    end
    local text
    for i = 0, rows - 1 do
        text = player:QueryRecord("InteractTraceRec", i, 2)
        local temp = util_split_string(nx_string(text), ";")
        if temp[2] ~= nil then
            local temp2 = util_split_string(temp[2], ",")
            if temp2[1] == nx_string("6") then
                return temp2[2]
            end
        end
    end
    return
end

function getSoTinhBao()
    local client = nx_value("game_client")
    local player = client:GetPlayer()
    if not nx_is_valid(player) then
        return nx_int(0)
    end

    local rows = player:GetRecordRows("InteractTraceRec")
    if nx_int(rows) <= nx_int(0) then
        return nx_int(0)
    end
    local text
    for i = 0, rows - 1 do
        text = player:QueryRecord("InteractTraceRec", i, 2)
        local temp = util_split_string(nx_string(text), ";")
        if temp[3] ~= nil then
            local temp2 = util_split_string(temp[3], ",")
            if temp2[1] == nx_string("6") then
                local temp3 = util_split_string(temp2[2], "/")
                if temp3[1] ~= nil then
                    return nx_int(temp3[1])
                end
            end
        end
    end
    return nx_int(0)
end

function getMySchoolMapId()
    local myHome = getMyHome()
    for i = 1, #MY_SCHOOL do
        if nx_string(myHome) == nx_string(MY_SCHOOL[i].myHome) then
            return MY_SCHOOL[i].mapId
        end
    end
    return "0"
end

function traNhiemVu(...)
    if isDaoHoaDao() and vaoTrongDao() == false then
        return
    end
    local menu = util_split_wstring(myInfo.menuOutput, ";")
    doiThoaiNpc(
        myInfo.npcQuest[1],
        myInfo.npcQuest[2],
        myInfo.npcQuest[3],
        myInfo.npcQuest[4],
        myInfo.npcQuest[5],
        unpack(menu)
    )
end

function isDaoHoaDao()
    if getMyHome() == "HomePointschool10A" then
        return true
    end
    return false
end

function vaoTrongDao()
    if isTrongDao() then
        return true
    else
        GoToPosition(-392.949005, 46.216, 39.858002)
        return false
    end
end

function isTrongDao()
    if GetDistance(-604.713013, 66.044998, -142.761002) < 180 then
        return true
    else
        return false
    end
end

function doiThoaiNpc(npcName, posX, posY, posZ, mapId, ...)
    local npc_ident = nx_execute("zdn_logic_base", "GetNpcIdentByName", npcName)
    if npc_ident ~= nil and isTalkMovieShowed(npc_ident) then
        for i, menu in pairs(arg) do
            if selectMenuText(menu) then
                nx_pause(2)
                return i
            end
        end
        selectFirstMenu()
    end
    if GetCurMap() == mapId then
        nx_execute("zdn_logic_skill", "DungTuSat")
        if GetDistance(posX, posY, posZ) < 4 then
            clickNpc(npcName)
            return 101
        else
            GoToPosition(posX, posY, posZ)
            return 102
        end
    else
        TeleToHomePoint(getHomePoint(mapId))
        return 103
    end
end

function isTalkMovieShowed(npc_ident)
    local form = util_get_form("form_stage_main\\form_talk_movie")
    if not nx_is_valid(form) or not form.Visible then
        return false
    end
    return npc_ident == form.npcid
end

function selectMenuText(text)
    local sock = nx_value("game_sock")
    local form = util_get_form("form_stage_main\\form_talk_movie")
    if not nx_is_valid(form) or not form.Visible then
        return false
    end
    local ident = form.npcid
    local menu = form.menus
    local menu_table = util_split_wstring(nx_widestr(menu), "|")
    local menu_num = #menu_table
    local menu_sub_table = {}
    for i, m in pairs(menu_table) do
        local temp = util_split_wstring(m, "`")
        menu_sub_table[i] = {
            ["Text"] = temp[2],
            ["Key"] = nx_int(temp[1])
        }
    end

    for i, menuInfo in pairs(menu_sub_table) do
        if nx_widestr(text) == nx_widestr(menuInfo.Text) then
            sock.Sender:Select(nx_string(ident), nx_int(menuInfo.Key))
            return true
        end
    end

    return false
end

function selectFirstMenu(...)
    local sock = nx_value("game_sock")
    local form = util_get_form("form_stage_main\\form_talk_movie")

    if not nx_is_valid(form) or not form.Visible then
        return false
    end

    local ident = form.npcid
    local menu = form.menus
    local menu_table = util_split_wstring(nx_widestr(menu), "|")
    if #menu_table == 0 then
        return false
    end
    local menu_sub_table = util_split_wstring(menu_table[1], "`")
    if menu_sub_table[1] ~= nil then
        sock.Sender:Select(nx_string(ident), nx_int(menu_sub_table[1]))
    end
    return false
end

function clickNpc(npcName)
    local npcIdent = nx_execute("zdn_logic_base", "GetNpcIdentByName", npcName)
    if npcIdent == nil then
        return false
    end
    nx_execute("custom_sender", "custom_select", npcIdent)
end
function getHomePoint(mapId)
    if SPY_HOME_POINT_LIST == nil or #SPY_HOME_POINT_LIST == 0 then
        setSpyHomePointList()
    end
    for i, map in pairs(SPY_HOME_POINT_LIST) do
        if nx_string(map.mapId) == nx_string(mapId) then
            return map.mapPoint
        end
    end
    return "0"
end

function veMonPhai()
    if isDead() then
        nx_execute("custom_sender", "custom_relive", 0, 0)
        return
    end
    local anTheInfo = getAnThe(getMyHome())
    if anTheInfo ~= nil then
        veAnThe(anTheInfo)
    else
        veSuMon()
    end
end

function isDead()
    local game_client = nx_value("game_client")
    local client_player = game_client:GetPlayer()
    if not nx_is_valid(client_player) then
        return false
    end
    local dead = client_player:QueryProp("Dead")
    return dead == 1
end

function getAnThe(homePointId)
    for i, anThe in pairs(AN_THE_INFO) do
        if anThe.homePointId == homePointId then
            return anThe
        end
    end
    return nil
end

function veAnThe(anThe)
    if GetCurMap() == anThe.mapId then
        doiThoai(anThe.npc, anThe.menu)
    else
        veSuMon()
    end
end

function doiThoai(npc, menu)
    doiThoaiNpc(npc[1], npc[2], npc[3], npc[4], npc[5], unpack(menu))
end

function layTinhBao(...)
    local game_visual = nx_value("game_visual")
    local curSpyIndex = getcurSpyIndex()
    if GetCurMap() == SPY_INFO[curSpyIndex].mapId then
        local npcNoiUng = timNpcNoiUng(curSpyIndex)
        if npcNoiUng ~= nil then
            local vso = game_visual:GetSceneObj(npcNoiUng.Ident)
            if not nx_is_valid(vso) then
                return
            end
            local name = npcNoiUng:QueryProp("ConfigID")
            name = util_text(nx_string(name))
            local menu = util_split_wstring(SPY_INFO[curSpyIndex].menuNoiUng, ";")

            if GetDistanceToObj(npcNoiUng) > 4 then
                GoToObj(npcNoiUng)
            else
                doiThoaiNpc(name, vso.PositionX, vso.PositionY, vso.PositionZ, GetCurMap(), unpack(menu))
            end
        else
            goToSpyIndex(curSpyIndex)
        end
    else
        TeleToHomePoint(getHomePoint(SPY_INFO[curSpyIndex].mapId))
        nx_pause(10)
    end
end

function timNpcNoiUng(index)
    local npc = timNpc(SPY_INFO[index].npcNoiUng)
    if npc ~= nil then
        return npc
    end
    return
end

function timNpc(npc_name)
    local game_client = nx_value("game_client")
    local game_scene = game_client:GetScene()
    if not (nx_is_valid(game_scene)) then
        return
    end
    local client_obj_lst = game_scene:GetSceneObjList()
    for i = 1, #client_obj_lst do
        local obj_type = client_obj_lst[i]:QueryProp("NpcType")
        local obj_dead = client_obj_lst[i]:QueryProp("Dead")
        if obj_type ~= 0 and obj_dead ~= 1 then
            local obj_id = client_obj_lst[i]:QueryProp("ConfigID")
            if nx_string(obj_id) ~= nx_string("0") then
                local obj_name = util_text(nx_string(obj_id))
                if obj_name == npc_name then
                    return client_obj_lst[i]
                end
            end
        end
    end
    return nil
end

function goToSpyIndex(index)
    listScriptPoint = SPY_INFO[index].listScriptPoint
    if curPoint <= #listScriptPoint then
        local posX = listScriptPoint[curPoint].posX
        local posY = listScriptPoint[curPoint].posY
        local posZ = listScriptPoint[curPoint].posZ
        GoToPosition(posX, posY, posZ)
        if GetDistance(posX, posY, posZ) < 3 then
            curPoint = curPoint + 1
        end
    else
        curPoint = 1
    end
end

function nhanNhiemVu()
    nx_execute("zdn_logic_common_listener", "ResolveListener", nx_current(), "on-task-interrupt")
    if GetCurMap() == spyMap then
        curPoint = 1
        StopFindPath()
        send_server_msg(g_msg_accept, 0, 0)
    else
        if getSoLenhBai() > 0 then
            gapChuongMon()
        else
            TeleToHomePoint(getHomePoint(spyMap))
            nx_pause(10)
        end
    end
end

function getSoLenhBai()
    local x, soLenhBai = isHaveItem("citanling_item", 1)
    if soLenhBai == 0 then
        x, soLenhBai = isHaveItem("citanling_item1", 1)
    end
    if soLenhBai == 0 then
        x, soLenhBai = isHaveItem("citanling_item_1", 1)
    end
    return soLenhBai
end

function isHaveItem(item_id, amount)
    local goods_grid = nx_value("GoodsGrid")
    if not nx_is_valid(goods_grid) then
        return false, 0
    end
    local view_id = goods_grid:GetToolBoxViewport(nx_string(item_id))
    local game_client = nx_value("game_client")
    local view = game_client:GetView(nx_string(view_id))
    if not nx_is_valid(view) then
        return false, 0
    end
    local total = 0
    local viewobj_list = view:GetViewObjList()
    for i, obj in pairs(viewobj_list) do
        if nx_string(obj:QueryProp("ConfigID")) == nx_string(item_id) then
            total = total + nx_number(obj:QueryProp("Amount"))
        end
    end
    return nx_int(amount) <= nx_int(total), total
end

function gapChuongMon()
    if GetCurMap() == getMySchoolMapId() then
        if isDaoHoaDao() and vaoTrongDao() == false then
            return
        end
        local menu = SPY_INFO[spyIndex].menu .. nx_widestr(";") .. myInfo.menuInput
        local menuTable = util_split_wstring(menu, ";")
        doiThoaiNpc(
            myInfo.zhangmen[1],
            myInfo.zhangmen[2],
            myInfo.zhangmen[3],
            myInfo.zhangmen[4],
            myInfo.zhangmen[5],
            unpack(menuTable)
        )
    else
        veMonPhai()
    end
end

function getcurSpyIndex()
    local school = getTrangThaiDoTham()
    for i, info in pairs(SPY_INFO) do
        if nx_string(school) == nx_string(info.spySchool) then
            return i
        end
    end
    return 1
end

function veSuMon()
    if not isTeleOnCooldown() then
        nx_execute("zdn_logic_skill", "DungTuSat")
        nx_pause(2)
        TeleToHomePoint(getMyHome())
    else
        if InstantDieFlg then
            DieInstantly()
            return
        end
        nx_execute("zdn_logic_skill", "TuSat")
    end
end

function isTeleOnCooldown()
    nx_execute("form_stage_main\\form_homepoint\\form_home_point", "ShowHomePointForm")
    local form = nx_value("form_stage_main\\form_homepoint\\form_home_point")
    if nx_is_valid(form) then
        local cd = 600000 - form.pbar_timedown.Value
        if cd == 0 then
            return false
        end
        return true
    end
    return false
end

function loadConfig()
    local instantDieStr = nx_string(IniReadUserConfig("DoTham", "InstantDie", "0"))
    InstantDieFlg = instantDieStr == "1" and true or false
end
