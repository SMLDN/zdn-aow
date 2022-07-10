require("zdn_lib_moving")
require("zdn_form_common")
require("zdn_lib\\util_functions")
require("form_stage_main\\form_chat_system\\chat_util_define")

local Running = false
local MenPaiJobList = {
    ["lx_009_022"] = 1,
    ["lx_009_021"] = 1,
    ["lx_009_023"] = 1,
    ["lx_008_019"] = 1,
    ["lx_008_020"] = 1,
    ["lx_008_021"] = 1,
    ["lx_007_018"] = 1,
    ["lx_007_019"] = 1,
    ["lx_007_020"] = 1,
    ["lx_006_018"] = 1,
    ["lx_006_019"] = 1,
    ["lx_006_020"] = 1,
    ["lx_005_019"] = 1,
    ["lx_005_020"] = 1,
    ["lx_005_021"] = 1,
    ["lx_010_019"] = 1,
    ["lx_010_020"] = 1,
    ["lx_010_021"] = 1,
    ["lx_011_020"] = 1,
    ["lx_011_021"] = 1,
    ["lx_011_022"] = 1,
    ["lx_012_015"] = 1,
    ["lx_012_016"] = 1,
    ["lx_012_017"] = 1,
    ["lx_832_001"] = 1,
    ["lx_832_004"] = 1,
    ["lx_832_005"] = 1,
    ["lx_769_001"] = 1,
    ["lx_769_006"] = 1,
    ["lx_769_007"] = 1
}
local CanKidnapList = {}
local NormalList = {}
local RelationList = {}
local IgnoreList = {}

function onFormOpen()
    if Running then
        return
    end
    Running = true
    IgnoreList = {}
    while Running do
        loopCoc()
        nx_pause(0.5)
    end
end

function onFormClose()
    stop()
end

function loopCoc()
    if not nx_is_valid(Form) then
        stop()
        return
    end
    if not Form.Visible then
        return
    end
    if IsMapLoading() then
        return
    end
    --
    local client = nx_value("game_client")
    if not nx_is_valid(client) then
        return
    end
    local scene = client:GetScene()
    if not nx_is_valid(scene) then
        return
    end
    local objList = scene:GetSceneObjList()
    for i, obj in pairs(objList) do
        local isOffline = nx_string(obj:QueryProp("OfflineTypeTvT")) == "0"
        local isOfflineWorking = nx_string(obj:QueryProp("OfflineJobStep")) ~= "0"
        local jobId = nx_string(obj:QueryProp("OfflineJobId"))
        local canKidnap = nx_number(obj:QueryProp("IsAbducted")) == 1
        if not isMenPaiJob(jobId) and isOffline and isOfflineWorking then
            addToList(obj, canKidnap)
        end
    end
    refreshAllList()
end

function stop()
    Running = false
end

function isMenPaiJob(jobId)
    return MenPaiJobList[string.lower(jobId)] == 1
end

function addToList(obj, canKidnap)
    local name = obj:QueryProp("Name")
    if isInList(name) then
        return
    end
    if existsInIgnoreList(name) then
        return
    end
    local msg_delay = nx_value("MessageDelay")
    if not (nx_is_valid(msg_delay)) then
        return
    end
    local x, y, z = getObjPosition(obj)
    local buffEndTime = getWorkingBuffEndTime(obj)
    local map = GetCurMap()
    local item = {}
    item.name = name
    item.map = map
    item.buffEndTime = buffEndTime
    item.PosX = x
    item.PosY = y
    item.PosZ = z
    item.startHourHuman = nx_execute("zdn_logic_base", "GetCurrentHourHuman")
    if canKidnap then
        table.insert(CanKidnapList, item)
    else
        table.insert(NormalList, item)
    end
end

function updateGrid()
    local g = Form.coc_grid
    g:BeginUpdate()
    for i = 0, g.RowCount - 1 do
        g:DeleteRow(0)
    end

    local cnt = #CanKidnapList
    for i = 1, cnt do
        addToGrid(CanKidnapList[i], true)
    end

    cnt = #NormalList
    for i = 1, cnt do
        addToGrid(CanKidnapList[i], false)
    end
    g:EndUpdate()
end

function addToGrid(item, canKidnap)
    local g = Form.coc_grid
    local gridIndex = g.RowCount
    local delBtn = createDeleteButton(item)
    local posCtl = createPosControl(item, canKidnap)
    g:InsertRow(gridIndex)
    g:SetGridText(gridIndex, 0, nx_widestr(item.startHourHuman))
    g:SetGridText(gridIndex, 1, item.name)
    g:SetGridText(gridIndex, 2, nx_widestr(calculateBuffElapseTime(item.buffEndTime)) .. Utf8ToWstr(" phút"))
    g:SetGridControl(gridIndex, 3, posCtl)
    g:SetGridText(gridIndex, 4, util_text(item.map))
    g:SetGridControl(gridIndex, 5, delBtn)
end

function calculateBuffElapseTime(endTime)
    if endTime == -1 then
        return 999
    end
    local msg_delay = nx_value("MessageDelay")
    if not (nx_is_valid(msg_delay)) then
        return 999
    end
    local curTime = msg_delay:GetServerNowTime()
    local elapse = (nx_int64(endTime) - nx_int64(curTime)) / 60000
    if elapse < 0 then
        return 0
    end
    return math.ceil(elapse)
end

function isInList(name)
    local cnt = #CanKidnapList
    for i = 1, cnt do
        if CanKidnapList[i].name == name then
            return true
        end
    end
    cnt = #NormalList
    for i = 1, cnt do
        if NormalList[i].name == name then
            return true
        end
    end
    return false
end

function getObjPosition(obj)
    if not nx_is_valid(obj) then
        return 0, 0, 0
    end
    local visual = nx_value("game_visual")
    if not nx_is_valid(visual) then
        return 0, 0, 0
    end
    local v = visual:GetSceneObj(obj.Ident)
    return v.PositionX, v.PositionY, v.PositionZ
end

function getWorkingBuffEndTime(obj)
    local buff = "buf_abducted"
    if nx_execute("zdn_logic_skill", "ObjHaveBuff", obj, buff) then
        local l = nx_function("get_buffer_info", obj, buff, obj)
        if #l ~= 3 then
            return -1
        end
        return nx_number(l[2])
    end
    return -1
end

function createDeleteButton(item)
    local gui = nx_value("gui")
    if not nx_is_valid(gui) then
        return 0
    end
    local groupbox = gui:Create("GroupBox")
    groupbox.BackColor = "0,0,0,0"
    groupbox.NoFrame = true
    local btn = gui:Create("Button")
    groupbox:Add(btn)
    groupbox.btn = btn

    btn.NormalImage = "gui\\common\\button\\btn_del_out.png"
    btn.FocusImage = "gui\\common\\button\\btn_del_on.png"
    btn.PushImage = "gui\\common\\button\\btn_del_down.png"
    btn.FocusBlendColor = "255,255,255,255"
    btn.PushBlendColor = "255,255,255,255"
    btn.DisableBlendColor = "255,255,255,255"
    btn.NormalColor = "0,0,0,0"
    btn.FocusColor = "0,0,0,0"
    btn.PushColor = "0,0,0,0"
    btn.DisableColor = "0,0,0,0"
    btn.Left = 5
    btn.Top = 5
    btn.Width = 18
    btn.Height = 18
    btn.BackColor = "255,192,192,192"
    btn.ShadowColor = "0,0,0,0"
    btn.TabStop = "true"
    btn.AutoSize = "true"
    btn.DrawMode = "FitWindow"
    btn.HintText = Utf8ToWstr("Xóa")
    btn.ZdnName = item.name
    nx_bind_script(btn, nx_current())
    nx_callback(btn, "on_click", "onBtnDeleteRowClick")
    return groupbox
end

function onBtnDeleteRowClick(btn)
    local g = Form.coc_grid
    local cnt = g.RowCount - 1
    for i = 0, cnt do
        local deleteGroupBox = g:GetGridControl(i, 5)
        local deleteBtn = deleteGroupBox.btn
        if nx_id_equal(deleteBtn, btn) then
            removeFromList(deleteBtn.ZdnName)
            refreshAllList()
            return
        end
    end
end

function removeFromList(name)
    addToIgnoreList(name)
    local tmp = {}
    local cnt = #CanKidnapList
    local cntUp = 0
    for i = 1, cnt do
        if name ~= CanKidnapList[i].name then
            cntUp = cntUp + 1
            tmp[cntUp] = CanKidnapList[i]
        end
    end
    CanKidnapList = tmp

    tmp = {}
    cnt = #NormalList
    cntUp = 0
    for i = 1, cnt do
        if name ~= NormalList[i].name then
            cntUp = cntUp + 1
            tmp[cntUp] = NormalList[i]
        end
    end
    NormalList = tmp
end

function refreshAllList()
    RelationList = {}
    RelationList[1] = get_attention_table()
    RelationList[2] = get_friend_table()
    RelationList[3] = get_buddy_table()
    RelationList[4] = get_enemy_table()
    RelationList[5] = get_blood_table()
    RelationList[6] = get_filter_table()
    RelationList[7] = get_pupil_table()
    RelationList[8] = get_sworn_table()
    local delLst = {}
    for j, record in pairs(RelationList[1]) do
        if not isInList(record.player_name) then
            table.insert(delLst, record.player_name)
        end
        if nx_string(record.online) ~= nx_string(106) then
            table.insert(delLst, record.player_name)
            removeFromList(record.player_name)
        end
        if existsInIgnoreList(record.player_name) then
            table.insert(delLst, record.player_name)
        end
    end
    for i = 1, #delLst do
        nx_execute("custom_sender", "custom_add_relation", 9, delLst[i], 5, -1)
    end
    --
    local nMax1 = #CanKidnapList
    if nMax1 > 20 then
        nMax1 = 20
    end
    for i = 1, nMax1 do
        addAttention(CanKidnapList[i].name)
    end
    local nMax2 = #NormalList
    if nMax2 > 40 - nMax1 then
        nMax2 = 40 - nMax1
    end
    for i = 1, nMax2 do
        addAttention(NormalList[i].name)
    end
    updateGrid()
end

function addAttention(name)
    if foundRelation(name) then
        return
    end
    nx_execute("custom_sender", "custom_add_relation", 8, name, 5, -1)
end

function foundRelation(name)
    for i = 1, 8 do
        for j, record in pairs(RelationList[i]) do
            if record.player_name == name then
                return true
            end
        end
    end
    return false
end

function addToIgnoreList(name)
    if not existsInIgnoreList(name) then
        table.insert(IgnoreList, name)
    end
end

function existsInIgnoreList(name)
    local cnt = #IgnoreList
    for i = 1, cnt do
        if IgnoreList[i] == name then
            return true
        end
    end
    return false
end

function createPosControl(item, canKidnap)
    local gui = nx_value("gui")
    if not nx_is_valid(gui) then
        return 0
    end
    local groupbox = gui:Create("GroupBox")
    groupbox.BackColor = "0,0,0,0"
    groupbox.NoFrame = true
    local html = gui:Create("MultiTextBox")
    groupbox:Add(html)
    groupbox.html = html
    html.Top = 7
    html.Left = 20
    html.TextColor = "255,255,255,255"
    if calculateBuffElapseTime(item.buffEndTime) == 0 then
        html.TextColor = "255,0,180,50"
    end
    html.SelectBarColor = "0,0,0,255"
    html.MouseInBarColor = "0,255,255,0"
    html.ViewRect = "0,0,100,30"
    html.LineHeight = 12
    html.HtmlText =
        nx_widestr(
        "<a href=''>" .. nx_string(math.floor(item.PosX)) .. "," .. nx_string(math.floor(item.PosZ)) .. "</a>"
    )
    html.ScrollSize = 17
    html.Width = 100
    html.ShadowColor = "0,0,0,0"
    html.Font = "font_text"
    html.NoFrame = true
    html.ZdnPosX = item.PosX
    html.ZdnPosY = item.PosY
    html.ZdnPosZ = item.PosZ
    html.ZdnMap = item.map
    nx_bind_script(html, nx_current())
    nx_callback(html, "on_click_hyperlink", "onBtnPosClick")
    return groupbox
end

function onBtnPosClick(btn)
    local ctl = btn.Parent.html
    if GetCurMap() ~= ctl.ZdnMap then
        GoToMapByPublicHomePoint(ctl.ZdnMap)
        return
    end
    GoToPosition(ctl.ZdnPosX, ctl.ZdnPosY, ctl.ZdnPosZ)
end
