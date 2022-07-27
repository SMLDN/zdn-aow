require("util_functions")
require("zdn_form_common")
require("zdn_lib_moving")

local Logic = "zdn_logic_farm"

function onFormOpen()
    loadConfig()
    if nx_execute(Logic, "IsRunning") then
        nx_execute("zdn_logic_common_listener", "Subscribe", Logic, "on-task-stop", nx_current(), "onTaskStop")
        updateBtnSubmitState(true)
    else
        updateBtnSubmitState(false)
    end
end

function onBtnSubmitClick()
    if not nx_execute(Logic, "IsRunning") then
        updateBtnSubmitState(true)
        nx_execute(Logic, "Start")
    else
        nx_execute(Logic, "Stop")
        updateBtnSubmitState(false)
    end
end

function onTaskStop()
    updateBtnSubmitState(false)
end

function onBtnAddItemClick()
    local text = nx_widestr("")
    local client = nx_value("game_client")
    local view = client:GetView(nx_string(123))
    if not nx_is_valid(view) then
        return 0
    end
    for i = 1, 100 do
        local viewobj = view:GetViewObj(nx_string(i))
        if nx_is_valid(viewobj) then
            local ConfigID = viewobj:QueryProp("ConfigID")
            if string.find(nx_string(ConfigID), "seed") ~= nil then
                if text == nx_widestr("") then
                    text = util_text(nx_string(ConfigID))
                else
                    text = text .. nx_widestr(",") .. util_text(nx_string(ConfigID))
                end
            end
        end
    end
    Form.input_seed.Text = text
end

function loadConfig()
    local seedList = IniReadUserConfig("NongPhu", "SeedList", "")
    if seedList == "" then
        return
    end
    Form.input_seed.Text = seedList
    local radiusStr = IniReadUserConfig("NongPhu", "Radius", "8")
    Form.input_radius.Text = radiusStr
end

function onBtnSaveClick()
    local x, y, z = GetPlayerPosition()
    local posStr = GetCurMap() .. "," .. x .. "," .. y .. "," .. z
    IniWriteUserConfig("NongPhu", "Position", posStr)
    IniWriteUserConfig("NongPhu", "SeedList", Form.input_seed.Text)
    IniWriteUserConfig("NongPhu", "Radius", Form.input_radius.Text)
end
