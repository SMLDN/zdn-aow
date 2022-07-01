require("zdn_lib\\util_functions")
require("zdn_util")
require("zdn_define\\noi6_define")

local Running = false
local TodoList = {}

function IsRunning()
    return Running
end

function CanRun()
    local cnt = #TodoList
    if cnt == 0 then
        loadConfig()
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
    loadConfig()
    startNoi6()
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

function checkNextTask()
    Console("Nội 6 - Check next quest")
    stopAllTaskSilently()

    local cnt = #TodoList
    for i = 1, cnt do
        local logic = TodoList[i][3]
        if nx_execute(logic, "CanRun") then
            Console("Nội 6 -  Next quest: " .. TodoList[i][2])
            nx_execute(logic, "Start")
            return
        end
    end
    Console("Nội 6 - All quest is done.")
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

function startNoi6()
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

    Console("Nội 6 - " .. logicName .. " stopped")
    nx_execute("zdn_logic_common_listener", "ResolveListener", nx_current(), "on-task-interrupt")
    checkNextTask()
end

function loadConfig()
    TodoList = {}
    local disableListStr = nx_string(IniReadUserConfig("NhiemVuNoi6", "DisableList", ""))
    if disableListStr == "" then
        TodoList = TASK_LIST
        return
    end
    local disableList = util_split_string(disableListStr, ",")
    if #disableList == 0 then
        TodoList = TASK_LIST
        return
    end

    for i = 1, #TASK_LIST do
        local addFlg = true
        for j = 1, #disableList do
            if i == nx_number(disableList[j]) then
                addFlg = false
                break
            end
        end
        if addFlg then
            table.insert(TodoList, TASK_LIST[i])
        end
    end
end
