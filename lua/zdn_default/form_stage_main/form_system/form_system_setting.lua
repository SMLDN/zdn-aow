require("zdn_util")

local function zdnSaveMaxFps(form)
    local maxFps = nx_number(form.zdn_max_fps_input.Text)
    if maxFps < 10 then
        maxFps = 10
    end
    if maxFps > 999 then
        maxFps = 999
    end
    nx_execute("stage_main", "ZdnUpdateMaxFps", maxFps)
    IniWriteUserConfig("Zdn", "MaxFps", maxFps)
    local scene = nx_value("scene")
    if not nx_is_valid(scene) then
        return
    end
    scene.game_control.MaxDisplayFPS = maxFps
end

local function zdnAddInput(form)
    local gui = nx_value("gui")
    if not nx_is_valid(gui) then
        return
    end
    if not nx_is_valid(form) or not form.Visible then
        return
    end
    local maxFps = nx_number(IniReadUserConfig("Zdn", "MaxFps", 60))
    local input = gui:Create("Edit")
    form:Add(input)
    form.zdn_max_fps_input = input

    input.Left = 424
    input.Top = 225
    input.Width = 50
    input.Height = 23
    input.DragStep = "1.000000"
    input.OnlyDigit = true
    input.ChangedEvent = true
    input.MaxLength = 3
    input.MaxDigit = 999
    input.TextOffsetX = "2"
    input.Align = "Center"
    input.SelectBackColor = "190,190,190,190"
    input.Caret = "Default"
    input.ForeColor = "255,255,255,255"
    input.ShadowColor = "0,0,0,0"
    input.Font = "font_main"
    input.Cursor = "WIN_IBEAM"
    input.TabStop = "true"
    input.DrawMode = "ExpandH"
    input.BackImage = "gui\\common\\form_line\\ibox_1.png"
    input.Text = nx_widestr(maxFps)
end

local function zdnAddLabel(form)
    local gui = nx_value("gui")
    if not nx_is_valid(gui) then
        return
    end
    if not nx_is_valid(form) or not form.Visible then
        return
    end
    local lbl = gui:Create("Label")
    form:Add(lbl)
    form.zdn_max_fps_lbl = lbl

    lbl.RefCursor = "WIN_HELP"
    lbl.Left = 345
    lbl.Top = 230
    lbl.Width = 40
    lbl.Height = 13
    lbl.ForeColor = "255,128,101,74"
    lbl.ShadowColor = "0,255,0,0"
    lbl.Text = Utf8ToWstr("FPS tối đa:")
    lbl.Font = "font_text"
end

function main_form_open(self)
    local gui = nx_value("gui")
    local world = nx_value("world")
    local device_caps = nx_value("device_caps")
    self.init_samescene = false
    self.Left = (gui.Width - self.Width) / 2
    self.Top = (gui.Height - self.Height) / 2
    local game_config = nx_value("game_config")
    local left, top, width, height, maximized = world:GetWindowPos()
    if maximized then
        local screen_width, screen_height = nx_function("ext_get_screen_size")
        game_config.win_left = 0
        game_config.win_top = 0
        game_config.win_width = screen_width
        game_config.win_height = screen_height
    else
        game_config.win_left = left
        game_config.win_top = top
    end
    game_config.win_maximized = maximized
    nx_execute("game_config", "backup_game_config", game_config)
    self.multisample_combo.DropListBox:ClearString()
    self.multisample_combo.DropListBox:AddString(nx_widestr(0))
    local ms_table = {2, 4}
    for _, ms in pairs(ms_table) do
        local multisample_type = nx_string(ms) .. "_SAMPLES"
        local support =
            device_caps:CheckMultiSampleType(
            world.RenderName,
            world.ColorFormat,
            world.DepthFormat,
            world.Windowed,
            multisample_type
        )
        if support then
            self.multisample_combo.DropListBox:AddString(nx_widestr(ms))
        end
        if multisample_type == nx_string(game_config.multisample) then
            self.multisample_combo.Text = nx_widestr(ms)
        end
    end
    self.screen_size_combo.DropListBox:ClearString()
    refresh_screen_size_list(self)
    self.screen_size_combo.Text =
        nx_widestr(nx_string(game_config.win_width) .. "x" .. nx_string(game_config.win_height))
    self.first_open = true
    show_game_config(self, game_config, false)
    nx_execute(nx_current(), "show_fps", self)
    if 0 < self.shadow_quality_track.Value then
        self.cbtn_nolight.Checked = false
        self.cbtn_nolight.Enabled = false
    else
        self.cbtn_nolight.Enabled = true
    end
    self.tbar_samescene.Visible = false
    init_samescene_obj(self)
    --
    zdnAddInput(self)
    zdnAddLabel(self)
    self.lbl_36.Height = 65
    self.lbl_36.Width = 140
    --
    return 1
end

function on_ok_btn_click(self)
    local form = self.ParentForm
    local game_config = nx_value("game_config")
    local game_config_info = nx_value("game_config_info")
    local game_config_backup = nx_value("game_config_backup")
    zdnSaveMaxFps(form)
    if
        form.average_fps < 20 and game_config.level ~= "supersimple" and game_config.level ~= "simple" and
            game_config.level ~= "low"
     then
        local gui = nx_value("gui")
        local dialog = nx_execute("util_gui", "util_get_form", "form_common\\form_confirm", true, false)
        nx_execute(
            "form_common\\form_confirm",
            "show_common_text",
            dialog,
            gui.TextManager:GetText("ui_frame_info_hint")
        )
        dialog:ShowModal()
        dialog.Left = (gui.Width - dialog.Width) / 2
        dialog.Top = (gui.Height - dialog.Height) / 2
        local res = nx_wait_event(100000000, dialog, "confirm_return")
        if res == "cancel" then
            return 0
        end
    end
    local ms_support, ms_value = nx_call("game_config", "validate_multisample", game_config.multisample)
    if not ms_support then
        game_config.multisample = ms_value
    end
    if
        game_config_backup.win_width ~= game_config.win_width or game_config_backup.win_height ~= game_config.win_height or
            game_config_backup.windowed ~= game_config.windowed
     then
        nx_execute("game_config", "set_display", game_config)
    end
    if
        game_config.win_width == 800 and game_config.win_height == 600 or
            game_config.win_width == 960 and game_config.win_height == 600 or
            game_config.win_width == 1024 and game_config.win_height == 768
     then
        game_config_info.ui_scale_enable = 1
        game_config_info.ui_scale_value = 100
        local form = util_get_form("form_stage_main\\form_system\\form_system_Fight_info_Setting", false)
        if nx_is_valid(form) then
            nx_execute("form_stage_main\\form_system\\form_system_Fight_info_Setting", "show_to_form", form)
        end
    end
    nx_execute("game_config", "save_game_config", game_config, "system_set.ini", "main")
    nx_execute("game_config", "save_game_config", game_config_info, "systeminfo.ini", "Config")
    nx_execute("form_stage_main\\form_camera\\form_movie_save", "Save_movie_config", true)
    close_form(self.ParentForm)
    local world = nx_value("world")
    world:ClearRenderResource()
    local weather_manager = nx_value("weather_manager")
    if not nx_is_valid(weather_manager) then
        return 0
    end
    local IsLua = weather_manager:IsLua()
    if not IsLua then
        weather_manager:UpdateWeatherSystem()
    elseif game_config.weather_enable then
        local weather_set_data = nx_value("weather_set_data")
        if not nx_is_valid(weather_set_data) then
            nx_execute("terrain\\weather_set", "initialize_weather_data")
        end
    else
        local weather_set_data = nx_value("weather_set_data")
        if nx_is_valid(weather_set_data) then
            nx_call("terrain\\weather_set", "delete_weather_data")
            local scene = world.MainScene
            local terrain = scene.terrain
            nx_execute("terrain\\weather_set", "resume_weather_state", scene, terrain.FilePath, game_config)
        end
    end
    return 1
end
