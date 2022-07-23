function on_pic_map_left_up(pic_map, x, y)
    local form = pic_map.ParentForm
    if not nx_is_valid(form) then
        return
    end
    local game_client = nx_value("game_client")
    if not nx_is_valid(game_client) then
        return
    end
    local client_player = game_client:GetPlayer()
    if not nx_is_valid(client_player) then
        return
    end
    if client_player:FindProp("LogicState") then
        local offline_state = client_player:QueryProp("LogicState")
        if nx_int(offline_state) == nx_int(LS_OFFLINEJOB) then
            return
        end
    end
    local sx = -(pic_map.Width / 2 - x)
    local sz = pic_map.Height / 2 - y
    local map_x = pic_map.ImageWidth - pic_map.CenterX - sx / pic_map.ZoomWidth
    local map_z = pic_map.CenterY - sz / pic_map.ZoomHeight
    local pos_x, pos_z =
        trans_image_pos_to_scene(
        map_x,
        map_z,
        pic_map.ImageWidth,
        pic_map.ImageHeight,
        pic_map.TerrainStartX,
        pic_map.TerrainStartZ,
        pic_map.TerrainWidth,
        pic_map.TerrainHeight
    )
    local role = nx_value("role")
    if nx_is_valid(role) and nx_find_custom(role, "find_path_limit") and role.find_path_limit == true then
        return
    end
    local path_finding = nx_value("path_finding")
    local trace_flag = path_finding.AutoTraceFlag
    set_trace_npc_id(nil, pos_x, -10000, pos_z, form.current_map, true)
    if trace_flag == 1 or trace_flag == 2 then
        path_finding:FindPathScene(nx_string(form.current_map), pos_x, -10000, pos_z, 0)
    end
    nx_execute("zdn_logic_base", "RideZdnConfigMount")
end

function on_lbl_click(lbl)
    local form = nx_value("form_stage_main\\form_map\\form_map_scene")
    if not nx_is_valid(form) then
        return
    end
    if not nx_is_valid(lbl) then
        return
    end
    if nx_find_custom(lbl, "id") then
        local id = lbl.id
        local target_scene = form.map_query:GetTransNpcScene(nx_string(id))
        if "" ~= target_scene and nil ~= target_scene then
            turn_to_scene_map(form, nx_string(target_scene))
            return
        end
    end
    local path_finding = nx_value("path_finding")
    local trace_flag = path_finding.AutoTraceFlag
    if lbl.npc_type == 0 then
        if trace_flag == 1 or trace_flag == 2 then
            path_finding:FindPath(lbl.x, lbl.y, lbl.z, 0)
        end
    elseif
        lbl.npc_type == 240 or lbl.npc_type == 241 or lbl.npc_type == 242 or lbl.npc_type == 243 or lbl.npc_type == 244
     then
        local game_visual = nx_value("game_visual")
        if not nx_is_valid(game_visual) then
            return 0
        end
        game_visual:CustomSend(nx_int(CLIENT_CUSTOMMSG_CLONE_STRONGPOINT_MSG), nx_int(lbl.npc_type))
    else
        local form = nx_value("form_stage_main\\form_map\\form_map_scene")
        if trace_flag == 1 or trace_flag == 2 then
            path_finding:TraceTargetByID(form.current_map, lbl.x, lbl.y, lbl.z, 1.8, lbl.npc_id)
        end
    end
    nx_execute("zdn_logic_base", "RideZdnConfigMount")
end

function on_btn_trace_click(self)
    local form = self.ParentForm
    local map_query = form.map_query
    if not nx_find_custom(map_query, "x") or map_query.x == nil then
        return
    end
    if not nx_find_custom(map_query, "y") or map_query.y == nil then
        return
    end
    if not nx_find_custom(map_query, "z") or map_query.z == nil then
        return
    end
    if not nx_find_custom(map_query, "scene_id") or map_query.scene_id == nil then
        return
    end
    local npc_id
    if nx_find_custom(map_query, "npc_id") and map_query.npc_id ~= nil then
        npc_id = map_query.npc_id
    end
    local path_finding = nx_value("path_finding")
    local trace_flag = path_finding.AutoTraceFlag
    if trace_flag == 3 then
        return
    end
    if npc_id == nil then
        path_finding:FindPathScene(map_query.scene_id, map_query.x, map_query.y, map_query.z, 0)
    else
        path_finding:TraceTargetByID(map_query.scene_id, map_query.x, map_query.y, map_query.z, 1.8, map_query.npc_id)
    end
    nx_execute("zdn_logic_base", "RideZdnConfigMount")
end
