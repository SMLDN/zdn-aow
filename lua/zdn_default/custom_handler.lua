local old_custom_sysinfo_dump = string.dump(custom_sysinfo)
local old_custom_sysinfo = loadstring(old_custom_sysinfo_dump)

function custom_sysinfo(chander, arg_num, msg_type, tips_type, string_id, ...)
  nx_execute("Listener", "Resolve", string_id, unpack(arg))
  old_custom_sysinfo(chander, arg_num, msg_type, tips_type, string_id, unpack(arg))
end

function custom_start_movie(chander, arg_num, msg_type, npc_id, movie_id, movie_mode, ...)
  nx_execute("custom_sender", "custom_movie_end", movie_id)
  nx_execute("freshman_help", "movie_end_callback")
  nx_execute("stage_main", "show_continue_obj")
end
