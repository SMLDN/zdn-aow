require("util_gui")
require("zdn_lib\\util_functions")
require("form_stage_main\\form_homepoint\\home_point_data")
require("zdn_util")
require("zdn_form_common")
require("zdn_lib_moving")

TimerTele = 0

function onFormOpen(form)
	local gui = nx_value("gui")
	Form.Left = (gui.Width - Form.Width) / 2
	Form.Top = (gui.Height - Form.Height) / 2
	local file = nx_resource_path() .. "zdn\\data\\maplist.ini"
	local MapList = {}
	local MapSection = IniReadSection(file, "MapList", false)
	local cnt = 0
	for _, __ in pairs(MapSection) do
		cnt = cnt + 1
	end
	for i = 1, cnt do
		addMapRow(form, MapSection[nx_string(i)])
	end
	-- for debug
	-- dofile("D:\\auto\\debug.lua")
	-- for debug
end

function onBtnCloseClick()
	nx_execute("form_stage_main\\form_homepoint\\form_home_point", "auto_show_hide_point_form")
end

function addMapRow(form, map)
	local map_grid = form.mapgrid
	local control = createMapHyperlink(form)
	if not nx_is_valid(control) then
		return
	end
	control.html.HtmlText = nx_widestr('<a href="">') .. util_text(map) .. nx_widestr("</a>")
	control.Map = map
	local index = map_grid.RowCount
	map_grid:InsertRow(-1)
	map_grid:SetGridControl(index, 0, control)
end

function createMapHyperlink(form)
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
	html.Left = 0
	html.TextColor = "255,255,255,255"
	html.SelectBarColor = "0,0,0,255"
	html.MouseInBarColor = "0,255,255,0"
	html.ViewRect = "0,0,150,30"
	html.LineHeight = 15
	html.ScrollSize = 17
	html.Width = 150
	html.ShadowColor = "0,0,0,0"
	html.Font = "font_text"
	html.NoFrame = true
	nx_bind_script(html, nx_current())
	nx_callback(html, "on_click_hyperlink", "onMapHyperlinkClick")
	return groupbox
end

function createTeleHyperLink()
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
	html.Left = 5
	html.TextColor = "255,0,180,50"
	html.SelectBarColor = "0,0,0,255"
	html.MouseInBarColor = "0,255,255,0"
	html.ViewRect = "5,0,270,30"
	html.LineHeight = 12
	html.ScrollSize = 17
	html.Width = 275
	html.ShadowColor = "0,0,0,0"
	html.Font = "font_text"
	html.NoFrame = true
	nx_bind_script(html, nx_current())
	nx_callback(html, "on_click_hyperlink", "onTeleHyperlinkClick")
	return groupbox
end

function onMapHyperlinkClick(self, index, data)
	local map = self.Parent.Map
	local form = self.ParentForm
	local list = getHomePointList(map)
	local row_count = form.homegrid.RowCount
	for i = 0, row_count - 1 do
		form.homegrid:DeleteRow(0)
	end
	for i = 1, #list do
		addHomeRow(form, list[i])
	end
end

function onTeleHyperlinkClick(self, index, data)
	if TimerDiff(TimerTele) < 2 then
		return
	end
	TimerTele = TimerInit()
	local homePoint = self.Parent.HomePointId
	TeleToHomePoint(homePoint)
end

function addHomeRow(form, info)
	local home_grid = form.homegrid
	local control = createTeleHyperLink(form)
	if not nx_is_valid(control) then
		return
	end
	control.HomePointId = info.ID
	control.Name = info.Name
	control.html.HtmlText = nx_widestr('<a href="">') .. util_text(info.Name) .. nx_widestr("</a>")
	local row = home_grid.RowCount
	home_grid:InsertRow(-1)
	home_grid:SetGridControl(row, 0, control)
end

function getHomePointList(map)
	local list = {}
	local nCount = GetSceneHomePointCount()
	if nCount <= 0 then
		return list
	end
	for i = 0, nCount - 1 do
		local bRet, hp_info = GetHomePointFromIndexNo(i)
		local sceneID = get_scene_name(nx_int(hp_info[HP_SCENE_NO]))
		if sceneID == map then
			local info = {}
			info.Name = hp_info[HP_NAME]
			info.ID = hp_info[HP_ID]
			table.insert(list, info)
		end
	end
	return list
end

function onBtnOpenOriginFormClick(btn)
	local form = nx_value("form_stage_main\\form_homepoint\\form_home_point")
	form.Width = 670
    form.Height = 508
	nx_execute("form_stage_main\\form_homepoint\\form_home_point", "center_for_screen", form)
end

function onBtnSchoolHomePointClick()
end
