local UserConfigFile = nil

function IniRead(file, section, key, default)
  key = nx_string(key)
  local ini = nx_create("IniDocument")
  ini.FileName = file
  if not (ini:LoadFromFile()) then
    nx_destroy(ini)
    return nx_widestr(default)
  end
  local text = ini:ReadString(section, key, default)
  if text == nil or text == "" then
    return nx_widestr(default)
  end
  nx_destroy(ini)
  return Utf8ToWstr(text)
end

function IniWrite(file, section, key, value)
  local ini = nx_create("IniDocument")
  ini.FileName = file
  if not (ini:LoadFromFile()) then
    local create_file = io.open(file, "w+")
    create_file:close()
    if not (ini:LoadFromFile()) then
      nx_destroy(ini)
      return 0
    end
  end
  ini:WriteString(section, key, WstrToUtf8(nx_widestr(value)))
  ini:SaveToFile()
  nx_destroy(ini)
  return 1
end

function IniReadUserConfig(section, key, default)
  return IniRead(getUserConfigFile(), section, key, default)
end

function IniWriteUserConfig(section, key, value)
  return IniWrite(getUserConfigFile(), section, key, value)
end

function TimerInit()
  return os.clock()
end

function TimerDiff(t)
  if t == 0 or t == nil then
    return 999999
  end
  return os.clock() - t
end

-- function ShowDialog(text)
--   local gui = nx_value("gui")
--   if not nx_is_valid(gui) then
--     return
--   end
--   local dialog = nx_execute("util_gui", "util_get_form", "form_common\\form_confirm", true, false)
--   nx_execute("form_common\\form_confirm", "show_common_text", dialog, nx_widestr(text))
--   dialog:ShowModal()
-- end

function ShowText(text)
  local SystemCenterInfo = nx_value("SystemCenterInfo")
  if not nx_is_valid(SystemCenterInfo) then
    return
  end
  SystemCenterInfo:ShowSystemCenterInfo(nx_widestr(text), 3)
end

function IniReadZdnTextSection(file)
  file = nx_resource_path() .. "zdn\\text\\" .. file .. ".ini"
  return IniReadSection(file, "text", true)
end

function IniReadSection(file, section, utf8Flg)
  local sectionText = {}
  local ini = nx_create("IniDocument")
  ini.FileName = file
  if not ini:LoadFromFile() then
    return false
  end
  local keyList = ini:GetItemList(section)
  for _, key in pairs(keyList) do
    if utf8Flg then
      sectionText[key] = Utf8ToWstr(ini:ReadString(section, key, ""))
    else
      sectionText[key] = nx_string(ini:ReadString(section, key, ""))
    end
  end
  nx_destroy(ini)
  return sectionText
end

function IniLoadAllData(file)
  local data = {}
  local ini = nx_create("IniDocument")
  ini.FileName = file
  if not ini:LoadFromFile() then
    return
  end
  local sectionList = ini:GetSectionList()
  for _, section in pairs(sectionList) do
    local keyList = ini:GetItemList(section)
    data[section] = {}
    for __, key in pairs(keyList) do
      data[section][key] = nx_string(ini:ReadString(section, key, "0"))
    end
  end
  nx_destroy(ini)
  return data
end

function IniLoadFile(file)
  local ini = nx_create("IniDocument")
  ini.FileName = file
  if not ini:LoadFromFile() then
    nx_destroy(ini)
    return nil
  end
  return ini
end

function Utf8ToWstr(content)
  return nx_function("ext_utf8_to_widestr", content)
end

function WstrToUtf8(content)
  return nx_function("ext_widestr_to_utf8", content)
end

-- for debug
function Console(text)
  local form = nx_value("form_zdn_log")
  if nx_is_valid(form) and form.Visible then
    nx_execute("form_zdn_log", "Log", text)
  end
end
-- for debug

-- private
function getUserConfigFile()
  if UserConfigFile == nil then
    local gameConfig = nx_value("game_config")
    local loginId = gameConfig.login_account
    if loginId ~= nil then
      UserConfigFile = nx_resource_path() .. "zdn\\user\\" .. loginId .. ".ini"
    end
  end
  return UserConfigFile
end
