require("zdn_lib_moving")

local Running = false
local CENTER_POS = {2208.6975097656, 25.381448745728, 1563.9770507813}

function IsRunning()
    return Running
end

function Start()
    if Running then
        return
    end
    Running = true
    while Running do
        loopBatTho()
        nx_pause(0.1)
    end
end

function Stop()
    Running = false
    nx_execute("zdn_logic_common_listener", "ResolveListener", nx_current(), "on-task-stop")
end

-- private
function loopBatTho()
    local itemForm = nx_value("form_stage_main\\form_give_item")
    if nx_is_valid(itemForm) and itemForm.Visible and nx_find_custom(itemForm, "btn_mail") then
        local btn = itemForm.btn_mail
        nx_execute("form_stage_main\\form_give_item", "on_btn_mail_click", btn)
        return
    end
    if GetDistance(CENTER_POS[1], CENTER_POS[2], CENTER_POS[3]) > 100 then
        GoToPosition(CENTER_POS[1], CENTER_POS[2], CENTER_POS[3])
        return
    end
    local obj = nx_execute("zdn_logic_base", "GetNearestObj", nx_current(), "isThoRung")
    if nx_is_valid(obj) then
        if GetDistanceToObj(obj) > 3 then
            GoToObj(obj)
            return
        end
        local fight = nx_value("fight")
        if not nx_is_valid(fight) then
            return
        end
        nx_execute("zdn_logic_base", "SelectTarget", obj)
        XuongNgua()
        fight:TraceUseSkill("cfslguj_skill_01", false, false)
    end
end

function isThoRung(obj)
    return obj:QueryProp("ConfigID") == "gujcfsl_tuzi_1"
end
