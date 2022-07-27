require("util_functions")
require("zdn_util")
require("zdn_define\\task_define")
require("zdn_define\\logic_define")

local Running = false
local TodoList = {}
local currentRunningTask = ""
local TimeManager = {}
local TimerTaskInterruptCheck = 0
local StopOnDoneFlg = true

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
        if nx_find_script(currentRunningTask, "Start") then
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
    TimeManager = {}
    local taskStr = IniReadUserConfig("TroLy", "Task", "")
    if taskStr ~= "" then
        local taskList = util_split_string(nx_string(taskStr), ";")
        for _, task in pairs(taskList) do
            local prop = util_split_string(task, ",")
            if prop[3] == nil then
                prop[3] = 0
                prop[4] = 0
                prop[5] = 23
                prop[6] = 59
            end
            addToTodoList(
                nx_number(prop[2]),
                nx_string(prop[1]) == "1" and true or false,
                prop[3],
                prop[4],
                prop[5],
                prop[6]
            )
        end
    end
    local stopOnDoneStr = nx_string(IniReadUserConfig("TroLy", "StopOnDone", "1"))
    StopOnDoneFlg = stopOnDoneStr == "1" and true or false
    if #TodoList > 0 then
        return true
    end
    return false
end

function addToTodoList(i, checked, startTimeHr, startTimeMnt, endTimeHr, endTimeMnt)
    if checked then
        table.insert(TodoList, i)
        local t = {}
        t.taskIndex = i
        t.startTimeHr = nx_number(startTimeHr)
        t.startTimeMnt = nx_number(startTimeMnt)
        t.endTimeHr = nx_number(endTimeHr)
        t.endTimeMnt = nx_number(endTimeMnt)
        table.insert(TimeManager, t)
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
        local taskIndex = TodoList[i]
        if canRunTask(taskIndex) then
            local logic = TASK_LIST[taskIndex][2]
            Console("Next task: " .. TASK_LIST[taskIndex][1])
            nx_execute(logic, "Start")
            return
        end
    end

    while Running and needToWait() do
        for i = 1, cnt do
            local taskIndex = TodoList[i]
            if canRunTask(taskIndex) then
                local logic = TASK_LIST[taskIndex][2]
                Console("Next task: " .. TASK_LIST[taskIndex][1])
                nx_execute(logic, "Start")
                return
            end
        end
        nx_pause(5)
    end
    Console("All task is done.")

    if StopOnDoneFlg then
        Stop()
        return
    end

    while not anyTaskAvailable() do
        if not Running then
            return
        end
        nx_pause(5)
    end

    checkNextTask()
end

function anyTaskAvailable()
    local cnt = #TodoList
    for i = 1, cnt do
        local taskIndex = TodoList[i]
        if canRunTask(taskIndex) then
            return true
        end
    end
    return false
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
    if TimerDiff(TimerTaskInterruptCheck) < 4 then
        return
    end
    TimerTaskInterruptCheck = TimerInit()
    local cnt = #TodoList
    for i = 1, cnt do
        local taskIndex = TodoList[i]
        local logic = TASK_LIST[taskIndex][2]
        if source == logic then
            if not isInTaskTime(taskIndex) then
                nx_execute(source, "Stop")
            end
            return
        end
        if canRunTask(taskIndex) then
            Console("Task interrupted")
            nx_execute(source, "Stop")
            return
        end
    end
end

function isInTaskTime(taskIndex)
    local cnt = #TimeManager
    for i = 1, cnt do
        local t = TimeManager[i]
        if t.taskIndex == taskIndex then
            local hr = math.floor(nx_execute("zdn_logic_base", "GetCurrentHour"))
            local mnt = math.floor(nx_execute("zdn_logic_base", "GetCurrentMinute"))
            return isBetween(hr, mnt, t.startTimeHr, t.startTimeMnt, t.endTimeHr, t.endTimeMnt)
        end
    end
    return false
end

function isBetween(hr, mnt, startHr, startMnt, endHr, endMnt)
    return isBeyondStartTime(hr, mnt, startHr, startMnt) and isBelowEndTime(hr, mnt, endHr, endMnt)
end

function isBeyondStartTime(hr, mnt, startHr, startMnt)
    if hr > startHr then
        return true
    end
    if hr == startHr then
        return mnt >= startMnt
    end
    return false
end

function isBelowEndTime(hr, mnt, endHr, endMnt)
    if hr < endHr then
        return true
    end
    if hr == endHr then
        return mnt <= endMnt
    end
    return false
end

function canRunTask(taskIndex)
    local logic = TASK_LIST[taskIndex][2]
    return nx_execute(logic, "CanRun") and isInTaskTime(taskIndex)
end
