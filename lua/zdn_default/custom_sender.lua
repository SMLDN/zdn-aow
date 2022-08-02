require("zdn_util")
function custom_chat(chat_type, content, ...)
  content = nx_widestr(content)
  local filter = nx_execute("zdn_chat_filter", "FilterCommand", content)
  if filter then
    return
  end
  if nx_function("ext_ws_find", content, nx_widestr("/c ")) == 0 then
    nx_execute(
      "zdn_logic_chat_loop",
      "Start",
      chat_type,
      nx_function("ext_ws_substr", content, 2, nx_ws_length(content))
    )
    return
  end
  local game_visual = nx_value("game_visual")
  if not nx_is_valid(game_visual) then
    return 0
  end
  local CheckWords = nx_value("CheckWords")
  if not nx_is_valid(CheckWords) then
    return 0
  end
  content = nx_widestr(content)
  local count = 1
  local new_word = check_word(CheckWords, content, count)
  chat_info = nx_widestr(new_word)
  local is_leader_mode = 0
  if CHATTYPE_GUILD == chat_type or CHATTYPE_SCHOOL == chat_type then
    local form_chat_main = nx_value("form_stage_main\\form_main\\form_main_chat")
    if nx_is_valid(form_chat_main) and form_chat_main.cbtn_gaoshi.Checked then
      is_leader_mode = 1
    end
  end
  local str = util_encrypt_string(chat_info)
  game_visual:CustomSend(nx_int(CLIENT_CUSTOMMSG_CHAT), nx_int(chat_type), nx_widestr(str), nx_int(is_leader_mode))
end
