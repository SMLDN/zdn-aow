require("zdn_util")

local Running = false
local TodoList = {
    {"Trầm Mặc Thả Câu", "zdn_logic_an_the_tmc_tmtc"},
    {"Tuần Tra Hòn Đảo", "zdn_logic_an_the_tmc_tthd"}
}

function IsRunning()
    return Running
end

function CanRun()
    if not isSpecificNewSchool("newschool_xingmiao") then
        ShowText("Hiện chỉ hỗ trợ Tinh Miễu Các")
        return false
    end
    local cnt = #TodoList
    for i = 1, cnt do
        local logic = TodoList[i][2]
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
    startAnThe()
end

function Stop()
    Running = false
    local cnt = #TodoList
    for i = 1, cnt do
        local logic = TodoList[i][2]
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
    Console("Check next quest")
    stopAllTaskSilently()

    local cnt = #TodoList
    for i = 1, cnt do
        local logic = TodoList[i][2]
        if nx_execute(logic, "CanRun") then
            Console("Next quest: " .. TodoList[i][1])
            nx_execute(logic, "Start")
            return
        end
    end
    Console("All quest is done.")
    Stop()
end

function stopAllTaskSilently()
    local cnt = #TodoList
    unsubscribeAllTaskEvent()
    for i = 1, cnt do
        local logic = TodoList[i][2]
        if nx_execute(logic, "IsRunning") then
            nx_execute(logic, "Stop")
        end
    end
    subscribeAllTaskEvent()
end

function unsubscribeAllTaskEvent()
    local cnt = #TodoList
    for i = 1, cnt do
        local logic = TodoList[i][2]
        nx_execute("zdn_logic_common_listener", "Unsubscribe", logic, "on-task-stop", nx_current())
    end
end

function subscribeAllTaskEvent()
    local cnt = #TodoList
    for i = 1, cnt do
        local logic = TodoList[i][2]
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
        local l = TodoList[i][2]
        if l == logic then
            logicName = TodoList[i][1]
            break
        end
    end

    Console(logicName .. " stopped")
    nx_execute("zdn_logic_common_listener", "ResolveListener", nx_current(), "on-task-interrupt")
    checkNextTask()
end
