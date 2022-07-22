function set_current_stage(new_stage)
    local old_stage = nx_value("stage")
    --
    local needFaculty = true
    local c = nx_value("game_client")
    if nx_is_valid(c) then
        local p = c:GetPlayer()
        if nx_is_valid(p) then
            needFaculty = p:QueryProp("FacultyStyle") ~= 1
        end
    end
    --
    nx_assert(old_stage ~= nil)
    if old_stage ~= "start" then
        nx_set_value("exit_success", false)
    else
        nx_set_value("exit_success", true)
    end
    if old_stage == "prepare" then
        nx_execute("stage_prepare", "exit_stage_prepare", new_stage)
    elseif old_stage == "login" then
        nx_execute("stage_login", "exit_stage_login", new_stage)
    elseif old_stage == "roles" then
        nx_execute("stage_roles", "exit_stage_roles", new_stage)
    elseif old_stage == "create" then
        nx_execute("stage_create", "exit_stage_create", new_stage)
    elseif old_stage == "main" then
        nx_execute("stage_main", "exit_stage_main", new_stage)
    end
    local exit_success = nx_value("exit_success")
    while not exit_success do
        nx_pause(0.1)
        exit_success = nx_value("exit_success")
    end
    nx_set_value("stage", new_stage)
    if new_stage == "prepare" then
        nx_execute("stage_prepare", "entry_stage_prepare", old_stage)
    elseif new_stage == "login" then
        nx_execute("stage_login", "entry_stage_login", old_stage)
    elseif new_stage == "roles" then
        nx_execute("stage_roles", "entry_stage_roles", old_stage)
    elseif new_stage == "create" then
        nx_execute("stage_create", "entry_stage_create", old_stage)
    elseif new_stage == "main" then
        nx_execute("stage_main", "entry_stage_main", old_stage)
    end
    if needFaculty and new_stage == "main" then
        nx_execute("zdn_logic_base", "TurnOnFaculty")
    end
    return 1
end
