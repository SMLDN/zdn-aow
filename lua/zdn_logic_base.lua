require("zdn_lib\\util_functions")
require("zdn_util")
require("zdn_lib_moving")

local function getCurrentDayOfWeek()
    local msgDelay = nx_value("MessageDelay")
    local currentDateTime = msgDelay:GetServerDateTime()
    local year, month, day, hour, mins, sec = nx_function("ext_decode_date", nx_double(currentDateTime))
    return nx_function("ext_get_day_of_week", year, month, day) - 1
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
    return timeStamp % 86400 / 3600 + 7
end

function GetCurrentHourHuman()
    local timeStamp = GetCurrentTimestamp()
    local hour = nx_int(nx_int(timeStamp % 86400 / 3600) + 7)
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
    local timeStamp = GetCurrentTimestamp()
    return timeStamp - (timeStamp % 86400) + (7 * 3600) + 86400
end

function GetCurrentDayStartTimestamp()
    local timeStamp = GetCurrentTimestamp()
    return timeStamp - (timeStamp % 86400) + (7 * 3600)
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

function GetMovieTalkList(...)
    local list = {}
    list.npc_id = ""
    local form = nx_value("form_stage_main\\form_talk_movie")
    if not nx_is_valid(form) then
        return list
    end
    local npc_id = form.npcid
    list.npc_id = npc_id
    if npc_id == "" or (arg[1] ~= nil and arg[1] ~= npc_id) then
        return list
    end
    local menus = form.menus
    local line_data = {}
    menus = util_split_wstring(menus, "|")
    for _, line in pairs(menus) do
        line_data = util_split_wstring(line, "`")
        if #line_data == 2 then
            local data = {}
            data.func_id = nx_number(line_data[1])
            data.text = line_data[2]
            table.insert(list, data)
        end
    end
    return list
end

function TalkToNpcByMenuId(npc_ident, menu_id)
    local sock = nx_value("game_sock")
    if not nx_is_valid(sock) then
        return
    end
    sock.Sender:Select(nx_string(npc_ident), nx_int(menu_id))
    return
end
