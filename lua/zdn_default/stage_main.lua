require("zdn_util")

local MaxFps = 60
local firstLoad = false

function add_main_private_to_scene(scene)
  local world = nx_value("world")
  nx_execute("login_scene", "clear_login_scene_private", scene)
  world.MainScene = scene
  local camera = scene.camera
  camera.Fov = 51.8 * math.pi * 2 / 360
  nx_set_value("game_camera", camera)
  local game_control
  if not nx_find_custom(scene, "game_control") or not nx_is_valid(scene.game_control) then
    game_control = scene:Create("GameControl")
    nx_bind_script(game_control, "game_control", "game_control_init")
    game_control.GameVisual = nx_value("game_visual")
    game_control:Load()
    scene:AddObject(game_control, 0)
    scene.game_control = game_control
  else
    game_control = scene.game_control
  end
  if not firstLoad then
    zdnFirstLoadProcess()
  end
  game_control.MaxDisplayFPS = MaxFps
  local game_config = nx_value("game_config")
  nx_execute("game_config", "apply_misc_config", scene, game_config)
  return true
end

function ZdnUpdateMaxFps(f)
  MaxFps = f
end

function zdnFirstLoadProcess()
  MaxFps = nx_number(IniReadUserConfig("Zdn", "MaxFps", 60))
  local ZdnHandwritingGame = nx_value("HandwritingGame")
  ZdnHandwritingGame:LoadResource(nx_resource_path() .. "zdn\\default\\share\\")
  nx_log("load HandwritingGame ended")
  firstLoad = true
end
