require("zdn_lib_moving")

local Running = false

function IsRunning()
    return Running
end

function CanRun()
    return true
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
        loopThuThap()
        nx_pause(0.2)
    end
end

function Stop()
    Running = false
    StopFindPath()
    nx_execute("zdn_logic_common_listener", "ResolveListener", nx_current(), "on-task-stop")
end

-- private
function loopThuThap()
    Console("thu thap")
end
