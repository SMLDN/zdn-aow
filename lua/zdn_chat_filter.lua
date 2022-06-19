require("util_gui")
require("zdn_lib\\util_functions")

function FilterCommand(chatStr)
  if nx_widestr(chatStr) == nx_widestr("/t") then
    util_show_form("form_zdn_tele", true)
    return true
  end
  if nx_widestr(chatStr) == nx_widestr("/skill") then
    util_show_form("form_zdn_skill_set", true)
    return true
  end
  if nx_widestr(chatStr) == nx_widestr("/atk") then
    util_show_form("form_zdn_attack", true)
    return true
  end
  if nx_widestr(chatStr) == nx_widestr("/vt") then
    util_show_form("form_zdn_escort", true)
    return true
  end
  if nx_widestr(chatStr) == nx_widestr("/tn") then
    util_show_form("form_zdn_thu_nghiep", true)
    return true
  end
  if nx_widestr(chatStr) == nx_widestr("/lc") then
    util_show_form("form_zdn_luyen_cong", true)
    return true
  end
  if nx_widestr(chatStr) == nx_widestr("/shop") then
    nx_execute("custom_sender", "custom_open_mount_shop", 1)
    return true
  end
  if nx_widestr(chatStr) == nx_widestr("/ct") then
    util_show_form("form_zdn_chien_truong", true)
    return true
  end
  if nx_widestr(chatStr) == nx_widestr("/hk") then
    util_show_form("form_zdn_hao_kiet", true)
    return true
  end
  if nx_widestr(chatStr) == nx_widestr("/tl") then
    util_show_form("form_zdn_task", true)
    return true
  end
  if nx_widestr(chatStr) == nx_widestr("/vp") then
    util_show_form("form_zdn_vat_pham", true)
    return true
  end
  if nx_widestr(chatStr) == nx_widestr("/thth") then
    util_show_form("form_zdn_thth", true)
    return true
  end
  if nx_widestr(chatStr) == nx_widestr("/farm") then
    util_show_form("form_zdn_farm", true)
    return true
  end
  if nx_widestr(chatStr) == nx_widestr("/n6") then
    util_show_form("form_zdn_noi6", true)
    return true
  end
  if nx_widestr(chatStr) == nx_widestr("/tt") then
    util_show_form("form_zdn_thien_the", true)
    return true
  end
  if nx_widestr(chatStr) == nx_widestr("/ltt") then
    util_show_form("form_zdn_ltt", true)
    return true
  end
  if nx_widestr(chatStr) == nx_widestr("/dan") then
    util_show_form("form_zdn_dan", true)
    return true
  end
  if nx_widestr(chatStr) == nx_widestr("/tq") then
    util_show_form("form_zdn_thich_quan", true)
    return true
  end

  -- for debug
  if nx_widestr(chatStr) == nx_widestr("/l") then
    util_show_form("form_zdn_log", true)
    return true
  end
  if nx_widestr(chatStr) == nx_widestr("/pos") then
    local visual = nx_value("game_visual")
    if not nx_is_valid(visual) then
      return true
    end
    local p = visual:GetPlayer()
    if not nx_is_valid(p) then
      return true
    end
    local pStr = p.PositionX .. ", " .. p.PositionY .. ", " .. p.PositionZ
    Console(pStr)
    nx_function("ext_copy_wstr", nx_widestr(pStr))
    return true
  end

  if nx_widestr(chatStr) == nx_widestr("/map") then
    local map = nx_value("form_stage_main\\form_map\\form_map_scene")
    if not nx_is_valid(map) then
      return true
    end
    Console(map.current_map)
    return true
  end

  if nx_widestr(chatStr) == nx_widestr("/buff") then
    local client = nx_value("game_client")
    if not nx_is_valid(client) then
      return true
    end
    local obj = client:GetPlayer()
    if not (nx_is_valid(obj)) then
      return false
    end
    local bufferList = nx_function("get_buffer_list", obj)
    local bufferCount = table.getn(bufferList) / 2
    for i = 1, bufferCount do
      Console(nx_string(bufferList[i * 2 - 1]))
    end
    return true
  end
  -- for debug

  return false
end

-- for debug
function Console(text)
  local form = nx_value("form_zdn_log")
  if nx_is_valid(form) and form.Visible then
    nx_execute("form_zdn_log", "Log", text)
  end
end
-- for debug
