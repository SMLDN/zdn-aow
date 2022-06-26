require("zdn_lib\\util_functions")
require("zdn_util")
require("zdn_define\\task_define")
require("zdn_define\\logic_define")

local Running = false
local TodoList = {}
local currentRunningTask = ""

function IsRunning()
    return Running
end

function Start()
    if Running then
        return
    end
    if loadConfig() then
        Running = true
        startTaskManager()
    else
        Stop()
    end
end

function Stop()
    Running = false
    local cnt = #TodoList
    for i = 1, cnt do
        local logic = TASK_LIST[TodoList[i]][2]
        nx_execute("zdn_logic_common_listener", "Unsubscribe", logic, "on-task-stop", nx_current())
        nx_execute("zdn_logic_common_listener", "Unsubscribe", logic, "on-task-interrupt", nx_current())
        nx_execute(logic, "Stop")
    end
    nx_execute("zdn_logic_common_listener", "ResolveListener", nx_current(), "on-task-stop")
end

function ContinueGlobalTask()
    if currentRunningTask ~= "" then
        if nx_find_script(CAN_RUN_LOGIC_LIST[i], "Start") then
            nx_execute(currentRunningTask, "Start")
        end
    end
end

function StopGlobalTask()
    if Running then
        currentRunningTask = nx_current()
        Stop()
        return
    end
    local cnt = #CAN_RUN_LOGIC_LIST
    for i = 1, cnt do
        if nx_find_script(CAN_RUN_LOGIC_LIST[i], "IsRunning") then
            if nx_execute(CAN_RUN_LOGIC_LIST[i], "IsRunning") then
                currentRunningTask = CAN_RUN_LOGIC_LIST[i]
                nx_execute(CAN_RUN_LOGIC_LIST[i], "Stop")
                Console("Stop " .. CAN_RUN_LOGIC_LIST[i])
                return
            end
        end
    end
    currentRunningTask = ""
end

--private
function loadConfig()
    TodoList = {}
    local taskStr = IniReadUserConfig("TroLy", "Task", "")
    if taskStr ~= "" then
        local taskList = util_split_string(nx_string(taskStr), ";")
        for _, task in pairs(taskList) do
            local prop = util_split_string(task, ",")
            addToTodoList(nx_number(prop[2]), nx_string(prop[1]) == "1" and true or false)
        end
    end
    if #TodoList > 0 then
        return true
    end
    return false
end

function addToTodoList(i, checked)
    if checked then
        table.insert(TodoList, i)
    end
end

function startTaskManager()
    checkNextTask()
end

function onTaskStop(logic)
    local logicName = logic
    local cnt = #TodoList
    for i = 1, cnt do
        local l = TASK_LIST[TodoList[i]][2]
        if l == logic then
            logicName = TASK_LIST[TodoList[i]][1]
            break
        end
    end
    Console(logicName .. " stopped")
    checkNextTask()
end

function checkNextTask()
    Console("Check next task")
    stopAllTaskSilently()

    local cnt = #TodoList
    for i = 1, cnt do
        local logic = TASK_LIST[TodoList[i]][2]
        if nx_execute(logic, "CanRun") then
            Console("Next task: " .. TASK_LIST[TodoList[i]][1])
            nx_execute(logic, "Start")
            return
        end
    end

    while Running and needToWait() do
        for i = 1, cnt do
            local logic = TASK_LIST[TodoList[i]][2]
            if nx_execute(logic, "CanRun") then
                Console("Next task: " .. TASK_LIST[TodoList[i]][1])
                nx_execute(logic, "Start")
                return
            end
        end
        nx_pause(5)
    end
    Console("All task is done.")
    Stop()
end

function stopAllTaskSilently()
    local cnt = #TodoList
    unsubscribeAllTaskEvent()
    for i = 1, cnt do
        local logic = TASK_LIST[TodoList[i]][2]
        if nx_execute(logic, "IsRunning") then
            nx_execute(logic, "Stop")
        end
    end
    subscribeAllTaskEvent()
end

function unsubscribeAllTaskEvent()
    local cnt = #TodoList
    for i = 1, cnt do
        local logic = TASK_LIST[TodoList[i]][2]
        nx_execute("zdn_logic_common_listener", "Unsubscribe", logic, "on-task-stop", nx_current())
        nx_execute("zdn_logic_common_listener", "Unsubscribe", logic, "on-task-interrupt", nx_current())
    end
end

function subscribeAllTaskEvent()
    local cnt = #TodoList
    for i = 1, cnt do
        local logic = TASK_LIST[TodoList[i]][2]
        nx_execute("zdn_logic_common_listener", "Subscribe", logic, "on-task-stop", nx_current(), "onTaskStop")
        nx_execute(
            "zdn_logic_common_listener",
            "Subscribe",
            logic,
            "on-task-interrupt",
            nx_current(),
            "onTaskInterrupt"
        )
    end
end

function needToWait()
    local cnt = #TodoList
    for i = 1, cnt do
        local logic = TASK_LIST[TodoList[i]][2]
        if not nx_execute(logic, "IsTaskDone") then
            return true
        end
    end
    return false
end

function onTaskInterrupt(source)
    if not Running then
        return
    end
    local cnt = #TodoList
    for i = 1, cnt do
        local logic = TASK_LIST[TodoList[i]][2]
        if source == logic then
            return
        end
        if nx_execute(logic, "CanRun") then
            Console("Task interrupted")
            nx_execute(source, "Stop")
            return
        end
    end
end
