require("zdn_lib_thich_quan")

local Running = false
local ThichQuanData = {}
local ThichQuan = {}
local ThichQuanFinishList = {}
local TimerCloseFormTVT = 0
local FollowMode = false

function IsRunning()
    return Running
end

function CanRun()
    return true
end

function Start()
    if Running then
        return
    end
    Running = true
    AbstructRunning = true
    loadThichQuanData()
    loadConfig()
    createTeam()
    while Running do
        loopThichQuan()
        nx_pause(0.2)
    end
end

function Stop()
    Running = false
    AbstructRunning = false
    StopFindPath()
    nx_execute("zdn_logic_skill", "StopAutoAttack")
    nx_execute("zdn_logic_common_listener", "ResolveListener", nx_current(), "on-task-stop")
    nx_execute(nx_current(), "closeTVTForm")
end

function loopThichQuan()
    if isLoading() then
        nx_pause(1)
        return
    end

    if nx_execute("zdn_logic_skill", "IsPlayerDead") then
        endGame()
        return
    end

    if isInBossScene() then
        if FollowMode then
            waitBossScene()
        else
            doBossScene()
        end
    else
        enterBossScene()
    end
end

function enterBossScene()
    if isReadyToEnterScene() then
        nx_execute("zdn_logic_skill", "StopNgoiThien")
        nx_pause(0.3)
        openThichQuan()
    else
        nx_execute("zdn_logic_skill", "NgoiThien")
    end
end

function openThichQuan()
    onOpenBossScene()
    if not updateThichQuanState() then
        return
    end
    local nextThichQuan = getNextThichQuan()
    if nextThichQuan == 0 then
        return
    end
    ThichQuan = nextThichQuan
    nx_execute("Listener", "addListen", nx_current(), "30301", "onThichQuanFinish", 2, ThichQuan.ID)

    if ThichQuan.MapId == GetCurMap() then
        if isThichQuanFormVisible() then
            startThichQuan()
            nx_execute(nx_current(), "closeTVTForm")
        else
            rollThichQuanBoss(ThichQuan.Npc, ThichQuan.BeginMenu)
        end
    else
        if isFreeTeleUsable() then
            useFreeTele(ThichQuan.ID)
        else
            GoToMapByPublicHomePoint(ThichQuan.MapId)
        end
    end
end

function isFreeTeleUsable()
    local form = nx_value("form_stage_main\\form_tvt\\form_tvt_tiguan")
    if not nx_is_valid(form) or not form.Visible then
        return true
    end
    local grid_baifu = nx_custom(form, "grid_baifu_4")
    if grid_baifu:GetItemNumber(0) ~= 1 then
        form:Close()
        return -4
    end
    return form.switch == 1
end

function useFreeTele(id)
    local game_visual = nx_value("game_visual")
    if not nx_is_valid(game_visual) then
        return
    end
    game_visual:CustomSend(nx_int(874), nx_number(id))
end

function loadConfig()
    ThichQuanData = {}
    ThichQuan = {}
    ThichQuanFinishList = {}
    -- TOdo need load from fiel
    local file = nx_resource_path() .. "zdn\\data\\thichquan\\the_luc.ini"
    local num = nx_number(IniRead(file, "the_luc_list", "total", 0))
    if num == 0 then
        return
    end
    local disableListStr = nx_string(IniReadUserConfig("ThichQuan", "DisableList", ""))
    local disableList = {}
    if disableListStr ~= "" then
        disableList = util_split_string(disableListStr, ",")
    end
    for i = 1, num do
        if not isInDisableList(i, disableList) then
            local tqId = IniRead(file, nx_string(i), "GuanID", "0")
            local title = IniRead(file, nx_string(i), "Title", "0")
            local npc_config = IniRead(file, nx_string(i), "Npc", "0")
            local map_id = IniRead(file, nx_string(i), "MapId", "0")
            local pos = IniRead(file, nx_string(i), "Pos", "0")
            pos = util_split_wstring(pos, ",")
            if #pos ~= 3 then
                return
            end
            local menu = IniRead(file, nx_string(i), "Menu", "0")
            menu = util_split_wstring(menu, ",")
            for i = 1, #menu do
                menu[i] = nx_number(menu[i])
            end

            local child = {
                ["Title"] = title,
                ["MapId"] = nx_string(map_id),
                ["ID"] = nx_number(tqId),
                ["Npc"] = {
                    ["Name"] = util_text(nx_string(npc_config)),
                    ["mapId"] = nx_string(map_id),
                    ["posX"] = nx_number(pos[1]),
                    ["posY"] = nx_number(pos[2]),
                    ["posZ"] = nx_number(pos[3]),
                    ["dClick"] = 9
                },
                ["BeginMenu"] = menu
            }
            table.insert(ThichQuanData, child)
        end
    end

    local checked = nx_string(IniReadUserConfig("ThichQuan", "FollowMode", "0"))
    FollowMode = (checked == "1")
end

function isInDisableList(index, list)
    local cnt = #list
    for i = 1, cnt do
        if index == nx_number(list[i]) then
            return true
        end
    end
    return false
end

function onThichQuanFinish(id)
    table.insert(ThichQuanFinishList, id)
end

function getNextThichQuan()
    for i, tq in pairs(ThichQuanData) do
        if not isThichQuanFinish(tq.ID) then
            local success = getTodaySuccess(tq.ID)
            if 0 <= success and success < 6 then
                return tq
            end
            if success == 6 then
                onThichQuanFinish(tq.ID)
            end
        end
    end
    if checkIsTaskDone() then
        Stop()
    end
    return 0
end

function checkIsTaskDone()
    return #ThichQuanData == #ThichQuanFinishList
end

function isThichQuanFinish(id)
    local cnt = #ThichQuanFinishList
    for i = 1, cnt do
        if ThichQuanFinishList[i] == id then
            return true
        end
    end
    return false
end

function getTodaySuccess(id)
    local form = nx_value("form_stage_main\\form_tvt\\form_tvt_tiguan")
    if not nx_is_valid(form) then
        return -1
    end
    local grid_baifu = nx_custom(form, "grid_baifu_4")
    if grid_baifu:GetItemNumber(0) ~= 1 then
        form:Close()
        return -4
    end
    local node = getGuanNode(form, id)
    if node == 0 then
        return -3
    end
    return nx_number(node.todaysucceed)
end

function getGuanNode(form, id)
    local node_tab = form.tree_guan.RootNode:GetNodeList()
    local guan_node = 0

    for i, node in pairs(node_tab) do
        if nx_number(node.guan_id) == nx_number(id) then
            return node
        end
    end
    return 0
end

function isThichQuanFormVisible()
    local form = nx_value("form_stage_main\\form_tiguan\\form_tiguan_ready")
    return nx_is_valid(form) and form.Visible
end

function startThichQuan()
    nx_execute("custom_sender", "custom_tiguan_random_npc", "1")
    LoadingTimer = TimerInit()
end

function closeTVTForm()
    if TimerDiff(TimerCloseFormTVT) < 5 then
        return
    end
    TimerCloseFormTVT = TimerInit()
    nx_pause(3)
    local form = nx_value("form_stage_main\\form_tvt\\form_tvt_tiguan")
    if nx_is_valid(form) then
        form:Close()
    end
end

function rollThichQuanBoss(npcInfo, menuInfo)
    local sock = nx_value("game_sock")
    local form = util_get_form("form_stage_main\\form_talk_movie")
    if nx_is_valid(form) and form.Visible then
        local ident = form.npcid
        for i, menu in pairs(menuInfo) do
            sock.Sender:Select(nx_string(ident), nx_int(menu))
        end
        form:Close()
        LoadingTimer = TimerInit() - 1.5
        return
    end

    if GetCurMap() == npcInfo.mapId then
        if GetDistance(npcInfo.posX, npcInfo.posY, npcInfo.posZ) < npcInfo.dClick then
            if not FollowMode then
                waitForTeamMember()
                clickNpc(npcInfo.Name)
            end
            return
        else
            GoToPosition(npcInfo.posX, npcInfo.posY, npcInfo.posZ, npcInfo.mapId)
            return
        end
    else
        GoToMapByPublicHomePoint(npcInfo.mapId)
        return
    end
end

function clickNpc(npcName)
    local npcIdent = getNpcIdentByName(npcName)
    if npcIdent == nil then
        return false
    end
    nx_execute("custom_sender", "custom_select", nx_string(npcIdent))
end

function getNpcIdentByName(npc_name)
    local game_client = nx_value("game_client")
    local game_scene = game_client:GetScene()
    if not (nx_is_valid(game_scene)) then
        return nil
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
                    return client_obj_lst[i].Ident
                end
            end
        end
    end
    return nil
end

function updateThichQuanState()
    if TimerDiff(UpdateTiguanTimer) < 10 then
        return true
    end
    local form = nx_value("form_stage_main\\form_tvt\\form_tvt_tiguan")
    if not nx_is_valid(form) or not form.Visible then
        util_show_form("form_stage_main\\form_tvt\\form_tvt_tiguan", true)
        LoadingTimer = TimerInit() + 2
        return false
    end
    UpdateTiguanTimer = TimerInit()
    return true
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
    end
end

function waitBossScene()
    local form = nx_value("form_stage_main\\form_tvt\\form_tvt_tiguan")
    if nx_is_valid(form) and form.Visible then
        nx_execute(nx_current(), "closeTVTForm")
    end
    if isComplete() then
        doComplete()
    end
end
function isMemberNear(name)
    local client = nx_value("game_client")
    if not nx_is_valid(client) then
        return false
    end
    local scene = client:GetScene()
    if not nx_is_valid(scene) then
        return false
    end
    local npc = ThichQuan.Npc
    local objList = scene:GetSceneObjList()
    for _, obj in pairs(objList) do
        if nx_widestr(name) == nx_widestr(obj:QueryProp("Name")) then
            return GetDistanceToObj(obj) < 9
        end
    end
    return false
end

function isTeamMemberReady()
    local TEAM_REC = "team_rec"
    local client = nx_value("game_client")
    if not nx_is_valid(client) then
        return false
    end
    local player = client:GetPlayer()
    if not nx_is_valid(player) then
        return false
    end
    local me = nx_widestr(player:QueryProp("Name"))
    local cnt = player:GetRecordRows(TEAM_REC)
    for r = 0, cnt - 1 do
        local name = player:QueryRecord(TEAM_REC, r, 0)
        if nx_widestr(me) ~= nx_widestr(name) then
            if not isMemberNear(name) then
                return false
            end
        end
    end
    return true
end

function waitForTeamMember()
    local timeOut = TimerInit()
    while Running and not isTeamMemberReady() and TimerDiff(timeOut) < 20 do
        nx_pause(0.1)
    end
end
