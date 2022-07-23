require("zdn_lib\\util_functions")
require("zdn_util")
require("zdn_lib_moving")

local TimerRide = 0
local MountConfigId = ""
local MountLoaded = false

local function getCurrentDayOfWeek()
    local msgDelay = nx_value("MessageDelay")
    local currentDateTime = msgDelay:GetServerDateTime()
    local year, month, day, hour, mins, sec = nx_function("ext_decode_date", nx_double(currentDateTime))
    return nx_function("ext_get_day_of_week", year, month, day) - 1
end

local function getMount()
    if not MountLoaded then
        MountConfigId = nx_string(IniReadUserConfig("Zdn", "MountConfigId", ""))
    end
    return MountConfigId
end

function GetLogicState()
    local role = nx_value("role")
    if not nx_is_valid(role) then
        return 1
    end
    local visual = nx_value("game_visual")
    if not nx_is_valid(visual) then
        return 1
    end
    return visual:QueryRoleLogicState(role)
end

function GetRoleState()
    local role = nx_value("role")
    if not nx_is_valid(role) then
        return 0
    end
    if not nx_find_custom(role, "state") then
        return 0
    end
    return role.state
end

function GetChildForm(formPath)
    local gui = nx_value("gui")
    local childlist = gui.Desktop:GetChildControlList()
    for i = 1, table.maxn(childlist) do
        local control = childlist[i]
        if nx_is_valid(control) and nx_script_name(control) == formPath then
            return control
        end
    end
end

function GetPlayer()
    local client = nx_value("game_client")
    if not nx_is_valid(client) then
        return
    end
    return client:GetPlayer()
end

function GetCurrentHour()
    local timeStamp = GetCurrentTimestamp()
    return (timeStamp % 86400 / 3600 + 7) % 24
end

function GetCurrentMinute()
    local timeStamp = GetCurrentTimestamp()
    return (timeStamp % 86400) % 3600 / 60
end

function GetCurrentHourHuman()
    local timeStamp = GetCurrentTimestamp()
    local hour = nx_int((nx_int(timeStamp % 86400 / 3600) + 7) % 24)
    local minute = nx_int(((timeStamp % 86400) % 3600) / 60)
    local hourStr = nx_string(hour)
    local minuteStr = nx_string(minute)
    if hour < nx_int(10) then
        hourStr = "0" .. hourStr
    end
    if minute < nx_int(10) then
        minuteStr = "0" .. minuteStr
    end
    return hourStr .. ":" .. minuteStr
end

function GetCurrentFullDayHuman()
    local msgDelay = nx_value("MessageDelay")
    local currentDateTime = msgDelay:GetServerDateTime()
    local year, month, day, hour, mins, sec = nx_function("ext_decode_date", nx_double(currentDateTime))
    if nx_int(day) < nx_int(10) then
        day = "0" .. nx_string(day)
    end
    if nx_int(month) < nx_int(10) then
        month = "0" .. nx_string(month)
    end
    return nx_string(day) .. "-" .. nx_string(month) .. "-" .. nx_string(year) .. "_" .. GetCurrentHourHuman()
end

function GetNextDayStartTimestamp()
    return GetCurrentDayStartTimestamp() + 86400
end

function GetCurrentDayStartTimestamp()
    local timeStamp = GetCurrentTimestamp()
    local hour = timeStamp % 86400 / 3600
    local r = timeStamp - (timeStamp % 86400) + (7 * 3600)
    if hour >= 17 then
        r = r + 86400
    end
    return r
end

function GetCurrentTimestamp()
    local msgDelay = nx_value("MessageDelay")
    if not (nx_is_valid(msgDelay)) then
        return 0
    end
    return msgDelay:GetServerSecond()
end

function GetCurrentWeekStartTimestamp()
    local dow = getCurrentDayOfWeek()
    local d = GetCurrentDayStartTimestamp()
    return d - (dow * 86400)
end

function GetNextWeekStartTimestamp()
    return GetCurrentWeekStartTimestamp() + 604800
end

function GetNearestObj(...)
    local client = nx_value("game_client")
    local scene = client:GetScene()
    if not nx_is_valid(scene) then
        return nil
    end
    local target = 0
    local shortestDistance = 200
    local objList = scene:GetSceneObjList()
    local argCnt = #arg
    for _, obj in pairs(objList) do
        if nx_is_valid(obj) then
            local validTarget = true
            if argCnt > 1 then
                for i = 2, argCnt do
                    if not nx_execute(nx_string(arg[1]), nx_string(arg[i]), obj) then
                        validTarget = false
                        i = cnt
                    end
                end
            end
            if validTarget then
                local d = GetDistanceToObj(obj)
                if d < shortestDistance then
                    shortestDistance = d
                    target = obj
                end
            end
        end
    end
    return target
end

function SelectTarget(obj)
    local client = nx_value("game_client")
    local player = client:GetPlayer()
    if not nx_is_valid(player) then
        return
    end
    local t = client:GetSceneObj(nx_string(player:QueryProp("LastObject")))
    if nx_id_equal(t, obj) then
        return
    end
    nx_execute("custom_sender", "custom_select", obj.Ident)
end

function GetNpcIdentByName(npcName)
    local client = nx_value("game_client")
    local scene = client:GetScene()
    if not (nx_is_valid(scene)) then
        return nil
    end
    local client_obj_lst = scene:GetSceneObjList()
    for i = 1, #client_obj_lst do
        local obj_type = client_obj_lst[i]:QueryProp("NpcType")
        local obj_dead = client_obj_lst[i]:QueryProp("Dead")
        if obj_type ~= 0 and obj_dead ~= 1 then
            local obj_id = client_obj_lst[i]:QueryProp("ConfigID")
            if nx_string(obj_id) ~= nx_string("0") then
                local obj_name = util_text(nx_string(obj_id))
                if obj_name == nx_widestr(npcName) then
                    return client_obj_lst[i].Ident
                end
            end
        end
    end
    return nil
end

function GetTaskInfoById(id, task_rec_key)
    local client = nx_value("game_client")
    local player = client:GetPlayer()
    if not nx_is_valid(player) then
        return
    end
    local rec = "Task_Record"
    local rows = player:GetRecordRows(rec)
    if nx_int(rows) <= nx_int(0) then
        return
    end
    for i = 0, rows - 1 do
        local taskIndex = player:QueryRecord(rec, i, 0)
        if nx_int(taskIndex) == nx_int(id) then
            return player:QueryRecord(rec, i, task_rec_key)
        end
    end
end

function FilterTaskInfoById(id, task_rec_key, conditionKey, condition)
    local client = nx_value("game_client")
    local player = client:GetPlayer()
    if not nx_is_valid(player) then
        return
    end
    local rec = "Task_Record"
    local rows = player:GetRecordRows(rec)
    if nx_int(rows) <= nx_int(0) then
        return
    end
    for i = 0, rows - 1 do
        local taskIndex = player:QueryRecord(rec, i, 0)
        if
            nx_int(taskIndex) == nx_int(id) and
                nx_string(player:QueryRecord(rec, i, conditionKey)) == nx_string(condition)
         then
            return player:QueryRecord(rec, i, task_rec_key)
        end
    end
end

function CanTaskSubmit(id)
    local client = nx_value("game_client")
    local player = client:GetPlayer()
    if not nx_is_valid(player) then
        return false
    end
    local row = player:FindRecordRow("Task_Accepted", 0, nx_int(id), 0)
    if row > -1 then
        local flg = player:QueryRecord("Task_Accepted", row, 6)
        return nx_int(flg) == nx_int(2)
    end
    return false
end

function TurnOnFaculty()
    local cnt = 0
    while nx_value("loading") do
        if cnt > 150 then
            break
        end
        cnt = cnt + 1
        nx_pause(0.1)
    end
    nx_execute("custom_sender", "custom_send_faculty_msg", 11)
end

function RideZdnConfigMount()
    if TimerDiff(TimerRide) < 2 then
        return
    end
    local r = nx_value("role")
    if not nx_is_valid(r) then
        return
    end
    local mount = getMount()
    if mount == "" then
        return
    end
    if r.state == "path_finding" and GetLogicState() ~= 1 then
        TimerRide = TimerInit()
        local i = nx_execute("zdn_logic_vat_pham", "FindFirstBoundItemIndexByConfigId", 2, mount)
        nx_execute("zdn_logic_vat_pham", "UseItem", 2, i)
    end
end

function SetMount(configId)
    MountConfigId = configId
end
