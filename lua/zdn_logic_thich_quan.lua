require("zdn_lib_thich_quan")

local Running = false

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
    while Running do
        loopThichQuan()
        nx_pause(0.2)
    end
end

function Stop()
    Running = false
    StopFindPath()
    nx_execute("zdn_logic_skill", "StopAutoAttack")
    nx_execute("zdn_logic_common_listener", "ResolveListener", nx_current(), "on-task-stop")
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

    if IsInBossScene() then
        doBossScene()
    else
        enterBossScene()
    end
end

function enterBossScene()
end
