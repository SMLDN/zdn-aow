require("util_functions")
require("zdn_util")
require("zdn_define\\an_the_define")

local Running = false
local TodoList = {}

function IsRunning()
    return Running
end

function CanRun()
    if not isSpecificNewSchool("newschool_xingmiao") and not isSpecificNewSchool("newschool_nianluo") then
        return false
    end
    local cnt = #TodoList
    if cnt == 0 then
        loadConfig()
        cnt = #TodoList
    end
    for i = 1, cnt do
        local logic = TodoList[i][3]
        if nx_execute(logic, "CanRun") then
            return true
        end
    end
    return false
end

function IsTaskDone()
    return not CanRun()
end

function Start()
    if Running then
        return
    end
    Running = true
    if not isSpecificNewSchool("newschool_xingmiao") and not isSpecificNewSchool("newschool_nianluo") then
        ShowText("Hiện chỉ hỗ trợ Tinh Miễu Các, Niệm La Bá")
        Stop()
        return
    end
    loadConfig()
    startAnThe()
end

function Stop()
    Running = false
    local cnt = #TodoList
    for i = 1, cnt do
        local logic = TodoList[i][3]
        nx_execute("zdn_logic_common_listener", "Unsubscribe", logic, "on-task-stop", nx_current())
        nx_execute(logic, "Stop")
    end
    nx_execute("zdn_logic_common_listener", "ResolveListener", nx_current(), "on-task-stop")
end

-- private
function isSpecificNewSchool(ns)
    local client = nx_value("game_client")
    if not nx_is_valid(client) then
        return false
    end
    local player = client:GetPlayer()
    if not nx_is_valid(player) then
        return false
    end
    return ns == nx_string(player:QueryProp("NewSchool"))
end

function checkNextTask()
    Console("Ẩn thế - Check next quest")
    stopAllTaskSilently()

    local cnt = #TodoList
    for i = 1, cnt do
        local logic = TodoList[i][3]
        if nx_execute(logic, "CanRun") then
            Console("Ẩn thế - Next quest: " .. TodoList[i][2])
            nx_execute(logic, "Start")
            return
        end
    end
    Console("Ẩn thế - All quest is done.")
    Stop()
end

function stopAllTaskSilently()
    local cnt = #TodoList
    unsubscribeAllTaskEvent()
    for i = 1, cnt do
        local logic = TodoList[i][3]
        if nx_execute(logic, "IsRunning") then
            nx_execute(logic, "Stop")
        end
    end
    subscribeAllTaskEvent()
end

function unsubscribeAllTaskEvent()
    local cnt = #TodoList
    for i = 1, cnt do
        local logic = TodoList[i][3]
        nx_execute("zdn_logic_common_listener", "Unsubscribe", logic, "on-task-stop", nx_current())
    end
end

function subscribeAllTaskEvent()
    local cnt = #TodoList
    for i = 1, cnt do
        local logic = TodoList[i][3]
        nx_execute("zdn_logic_common_listener", "Subscribe", logic, "on-task-stop", nx_current(), "onTaskStop")
    end
end

function startAnThe()
    checkNextTask()
end

function onTaskStop(logic)
    local logicName = logic
    local cnt = #TodoList
    for i = 1, cnt do
        local l = TodoList[i][3]
        if l == logic then
            logicName = TodoList[i][2]
            break
        end
    end

    Console("Ẩn thế - " .. logicName .. " stopped")
    nx_execute("zdn_logic_common_listener", "ResolveListener", nx_current(), "on-task-interrupt")
    checkNextTask()
end

function loadConfig()
    TodoList = {}
    local disableListStr = nx_string(IniReadUserConfig("AnThe", "DisableList", ""))
    if disableListStr == "" then
        TodoList = getTaskList()
        return
    end
    local disableList = util_split_string(disableListStr, ",")
    if #disableList == 0 then
        TodoList = getTaskList()
        return
    end
    local l = getTaskList()
    for i = 1, #l do
        local addFlg = true
        for j = 1, #disableList do
            if i == nx_number(disableList[j]) then
                addFlg = false
                break
            end
        end
        if addFlg then
            table.insert(TodoList, l[i])
        end
    end
end

function getTaskList()
    local client = nx_value("game_client")
    if not nx_is_valid(client) then
        return false
    end
    local player = client:GetPlayer()
    if not nx_is_valid(player) then
        return false
    end
    local ns = nx_string(player:QueryProp("NewSchool"))
    return TASK_LIST[ns]
end
