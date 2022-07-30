require("zdn_lib_moving")

local Running = false

function IsRunning()
    return Running
end

function Start()
    if Running then
        return
    end
    Running = true
    nx_execute("Listener", "addListen", nx_current(), "300144", "goToTamMaScene", -1)
    while Running do
        loopTamMa()
        nx_pause(0.1)
    end
end

function Stop()
    Running = false
    nx_execute("custom_sender", "custom_send_faculty_msg", 23)
    nx_execute("zdn_logic_common_listener", "ResolveListener", nx_current(), "on-task-stop")
    nx_execute("Listener", "removeListen", nx_current(), "300144", "goToTamMaScene")
end

function loopTamMa()
    if IsMapLoading() then
        return
    end
    if GetCurMap() == "clonetl003" then
        Stop()
        return
    end
    local form = nx_value("form_stage_main\\form_wuxue\\form_wuxue_act")
    if not nx_is_valid(form) or not form.Visible then
        nx_execute("custom_sender", "custom_send_faculty_msg", 21)
        return
    end
    nx_execute("custom_sender", "custom_send_faculty_msg", 23, nx_int(3), nx_int(1))
end

function goToTamMaScene()
    nx_execute("custom_sender", "custom_send_faculty_msg", 23)
    local obj = nx_execute("zdn_logic_base", "GetNearestObj", nx_current(), "isTamMaDan")
    if not nx_is_valid(obj) then
        nx_pause(1)
        obj = nx_execute("zdn_logic_base", "GetNearestObj", nx_current(), "isTamMaDan")
    end
    if not nx_is_valid(obj) then
        return
    end
    TalkToNpc(obj, 0)
end

function isTamMaDan(obj)
    return obj:QueryProp("ConfigID") == "npcclonetl_xmy_001"
end
