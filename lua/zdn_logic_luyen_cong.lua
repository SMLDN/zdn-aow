require("util_gui")
require("zdn_lib\\util_functions")
require("zdn_util")
require("zdn_lib_moving")

local MEMBER_FORM_PATH = "form_stage_main\\form_wuxue\\form_team_faculty_member"
local MAIN_REQUEST_FORM_PATH = "form_stage_main\\form_main\\form_main_request"

local Running = false
local LuyenCongMap = "city05"
local posX = 661.08001269531
local posY = 27.947305679321
local posZ = 317.80374145508
-- local posX = 687.06848144531
-- local posY = 36.831802368164
-- local posZ = 260.72106933594

function IsRunning()
    return Running
end

function CanRun()
    local client = nx_value("game_client")
    if not nx_is_valid(client) then
        return false
    end
    local player = client:GetPlayer()
    if not nx_is_valid(player) then
        return false
    end
    local value = nx_number(player:QueryProp("TeamFacultyValue"))
    return value > 10
end

function IsTaskDone()
    return not CanRun()
end

function Start()
    if Running then
        return
    end
    Running = true
    while Running do
        loopLuyenCong()
        nx_pause(1)
    end
end

function Stop()
    Running = false
    StopFindPath()
    nx_execute("zdn_logic_common_listener", "ResolveListener", nx_current(), "on-task-stop")
end

function loopLuyenCong()
    if IsMapLoading() then
        return
    end
    if not CanRun() then
        Stop()
        return
    end
    local memberForm = nx_value(MEMBER_FORM_PATH)
    if (nx_is_valid(memberForm) and memberForm.Visible) then
        DanceTimer = TimerInit()
        acceptRequest(memberForm)
        return
    end

    if TimerDiff(DanceTimer) < 7 then
        return
    end

    nx_execute("zdn_logic_common_listener", "ResolveListener", nx_current(), "on-task-interrupt")
    if GetCurMap() ~= LuyenCongMap then
        GoToMapByPublicHomePoint(LuyenCongMap)
        return
    end
    if GetDistance(posX, posY, posZ) > 3 then
        GoToPosition(posX, posY, posZ)
        return
    end
    XuongNgua()
    nx_pause(0.1)

    if not hasAnyTeam() then
        createMyOwnTeam()
        return
    end
    local teamList = getTeamList()
    local name = ""
    for _, obj in pairs(teamList) do
        name = nx_widestr(obj:QueryProp("Name"))
        nx_execute("custom_sender", "custom_request", 38, nx_widestr(name))
        obj.LastJoinTime = TimerInit()
        obj.JoinTimes = obj.JoinTimes + 1
        return true
    end
end

function createMyOwnTeam()
    if TimerDiff(TimerCreateTeam) < 3 then
        return
    end
    TimerCreateTeam = TimerInit()
    nx_execute("custom_sender", "custom_team_faculty", 1, nx_string("xl_team_004"))
    nx_execute("form_stage_main\\form_helper\\form_main_helper_manager", "next_helper_form")
end

function acceptRequest(memberForm)
    if not nx_execute("zdn_logic_skill", "HaveBuff", "buf_xiulian_wait") then
        return
    end
    if memberForm.btn_begin.Visible and memberForm.group_player_10.Visible then
        nx_execute(MEMBER_FORM_PATH, "on_btn_begin_click", memberForm)
        return
    end

    local nMax = nx_execute(MAIN_REQUEST_FORM_PATH, "get_request_prop", 0)
    for i = 1, nMax do
        if nx_execute(MAIN_REQUEST_FORM_PATH, "get_request_prop", i, 1) == 38 then
            local name = nx_widestr(nx_execute(MAIN_REQUEST_FORM_PATH, "get_request_prop", i, 2))
            nx_execute(MAIN_REQUEST_FORM_PATH, "remove_request", i)
            nx_execute("custom_sender", "custom_request_answer", 38, name, 1)
            return
        end
    end
end

function hasAnyTeam()
    local objList = getObjList()
    if objList == nil then
        return false
    end
    for _, obj in pairs(objList) do
        if nx_execute("zdn_logic_skill", "ObjHaveBuff", obj, "buf_xiulian_wait") then
            return true
        end
    end
    return false
end

function getObjList()
    local client = nx_value("game_client")
    local scene = client:GetScene()
    if not nx_is_valid(scene) then
        return
    end
    return scene:GetSceneObjList()
end

function getTeamList()
    local list = {}
    local client = nx_value("game_client")
    local scene = client:GetScene()
    if not nx_is_valid(scene) then
        return {}
    end
    local objList = scene:GetSceneObjList()
    for _, obj in pairs(objList) do
        if nx_execute("zdn_logic_skill", "ObjHaveBuff", obj, "buf_xiulian_wait") then
            if not nx_find_custom(obj, "LastJoinTime") then
                obj.LastJoinTime = 0
            end
            if not nx_find_custom(obj, "JoinTimes") then
                obj.JoinTimes = 0
            end
            if obj.JoinTimes < 6 and TimerDiff(obj.LastJoinTime) > 10 then
                table.insert(list, obj)
            end
        end
    end
    return list
end
