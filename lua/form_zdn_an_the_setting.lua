require("util_functions")
require("zdn_util")
require("zdn_form_common")
require("zdn_define\\an_the_define")

local resetTimeStr = ""

function onFormOpen()
    initGridView()
end

function initGridView()
    if not nx_is_valid(Form) then
        return
    end
    resetTimeStr = nx_string(IniReadUserConfig("AnThe", "ResetTime", ""))
    for i = 0, #TASK_LIST - 1 do
        local gridIndex = Form.an_the_grid.RowCount
        local cbtn = createCheckboxButton(i + 1)
        Form.an_the_grid:BeginUpdate()
        Form.an_the_grid:InsertRow(gridIndex)
        Form.an_the_grid:SetGridControl(gridIndex, 0, cbtn)

        local taskStatusTxt, foreColor = getTaskStatus(i + 1)
        Form.an_the_grid:SetGridText(gridIndex, 1, taskStatusTxt)
        Form.an_the_grid:SetGridForeColor(gridIndex, 1, foreColor)

        Form.an_the_grid:EndUpdate()
    end

    local disableListStr = nx_string(IniReadUserConfig("AnThe", "DisableList", ""))
    if disableListStr ~= "" then
        local disableList = util_split_string(disableListStr, ",")
        for i = 1, #disableList do
            local cbtn = Form.an_the_grid:GetGridControl(nx_int(disableList[i] - 1), 0)
            if nx_is_valid(cbtn) then
                local btn = cbtn.btn
                if nx_is_valid(btn) then
                    btn.Checked = false
                end
            end
        end
    end
end

function createCheckboxButton(index)
    local data = TASK_LIST[index]
    local gui = nx_value("gui")
    if not nx_is_valid(gui) then
        return 0
    end
    local groupbox = gui:Create("GroupBox")
    groupbox.BackColor = "0,0,0,0"
    groupbox.NoFrame = true
    local btn = gui:Create("CheckButton")
    groupbox:Add(btn)
    groupbox.btn = btn

    btn.Top = 0
    btn.Left = 0
    btn.Checked = checked
    btn.BoxSize = 12
    btn.NormalColor = "255,255,255,255"
    btn.FocusColor = "0,0,0,0"
    btn.PushColor = "0,0,0,0"
    btn.DisableColor = "0,0,0,0"
    btn.PushBlendColor = "255,255,255,255"
    btn.DisableBlendColor = "255,255,255,255"
    btn.Width = 240
    btn.Height = 25
    btn.BackColor = "255,192,192,192"
    btn.ForeColor = "255,255,255,255"
    btn.ShadowColor = "0,0,0,0"
    btn.TabStop = true
    btn.NoFrame = true
    btn.InSound = "MouseOn_20"
    btn.ClickSound = "ok_7"
    btn.Text = Utf8ToWstr(data[2])
    btn.NormalImage = "gui\\common\\checkbutton\\cbtn_out_4.png"
    btn.FocusImage = "gui\\common\\checkbutton\\cbtn_on_4.png"
    btn.CheckedImage = "gui\\common\\checkbutton\\cbtn_down_4.png"
    btn.DrawMode = "ExpandH"
    btn.Checked = true
    return groupbox
end

function onBtnSubmitClick()
    local disableList = ""
    local cnt = Form.an_the_grid.RowCount
    for i = 1, cnt do
        local cbtn = Form.an_the_grid:GetGridControl(i - 1, 0)
        if nx_is_valid(cbtn) then
            local btn = cbtn.btn
            if nx_is_valid(btn) and not btn.Checked then
                if disableList ~= "" then
                    disableList = disableList .. ","
                end
                disableList = disableList .. i
            end
        end
    end
    IniWriteUserConfig("AnThe", "DisableList", disableList)
end

function onHyperCheckAllClick()
    local cnt = Form.an_the_grid.RowCount
    for i = 1, cnt do
        local cbtn = Form.an_the_grid:GetGridControl(i - 1, 0)
        if nx_is_valid(cbtn) then
            local btn = cbtn.btn
            if nx_is_valid(btn) and not btn.Checked then
                btn.Checked = true
            end
        end
    end
end

function onHyperUncheckAllClick()
    local cnt = Form.an_the_grid.RowCount
    for i = 1, cnt do
        local cbtn = Form.an_the_grid:GetGridControl(i - 1, 0)
        if nx_is_valid(cbtn) then
            local btn = cbtn.btn
            if nx_is_valid(btn) and btn.Checked then
                btn.Checked = false
            end
        end
    end
end

function getTaskStatus(index)
    local logic = TASK_LIST[index][3]
    if nx_execute(logic, "IsRunning") then
        return Utf8ToWstr("Đang chạy..."), "255,255,255,255"
    end
    if resetTimeStr ~= "" then
        local resetTime = util_split_string(resetTimeStr, ";")
        for _, record in pairs(resetTime) do
            local prop = util_split_string(nx_string(record), ",")
            if
                prop[1] == nx_string(TASK_LIST[index][1]) and
                    nx_execute("zdn_logic_base", "GetCurrentDayStartTimestamp") < nx_number(prop[2])
             then
                return Utf8ToWstr("Đã xong"), "255,128,101,74"
            end
        end
    end
    return nx_widestr("-"), "255,128,101,74"
end
