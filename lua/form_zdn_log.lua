function formOpen(form)
	Form = form
	local gui = nx_value("gui")
	form.Left = gui.Width - form.Width - 10
	form.Top = 80
	if onFormOpen ~= nil then
		onFormOpen(form)
	end
end

function formInit(form)
	form.Fixed = false
	if onFormInit ~= nil then
		onFormInit(form)
	end
end

function formClose(form)
	if onFormClose ~= nil then
		onFormClose(form)
	end
	if nx_is_valid(form) then
		nx_destroy(form)
	end
end

function onBtnCloseClick(btn)
	local form = btn.Parent
	form.Visible = false
	form:Close()
end

function Log(txt)
	local content =
		nx_widestr("[") ..
		nx_widestr(nx_execute("zdn_logic_base", "GetCurrentHourHuman")) .. nx_widestr("] ") .. nx_widestr(txt)
	local index = Form.console_grid.RowCount
	local ctl = createTextControl(content)
	Form.console_grid:BeginUpdate()
	Form.console_grid:InsertRow(-1)
	Form.console_grid:SetGridControl(index, 0, ctl)
	Form.console_grid:EndUpdate()
end

function createTextControl(content)
	local gui = nx_value("gui")
	if not nx_is_valid(gui) then
		return 0
	end
	local groupbox = gui:Create("GroupBox")
	groupbox.BackColor = "0,0,0,0"
	groupbox.NoFrame = true
	local lbl = gui:Create("Label")
	groupbox:Add(lbl)
	groupbox.lbl = lbl

	lbl.Text = content
	lbl.Width = 400
	lbl.Height = 20
	lbl.ForeColor = "255,255,255,255"
	lbl.AutoSize = true
	lbl.Left = 15
	return groupbox
end

function onBtnClearClick()
	Form.console_grid:BeginUpdate()
	for i = 0, Form.console_grid.RowCount - 1 do
		Form.console_grid:DeleteRow(0)
	end
	Form.console_grid:EndUpdate()
end

function onBtnDebugClick()
	dofile("D:\\auto\\debug.lua")
end

function onBindTrigger()
	local r = nx_value("role")
	local content =
		nx_widestr("[") ..
		nx_widestr(nx_execute("zdn_logic_base", "GetCurrentHourHuman")) .. nx_widestr("] ") .. nx_widestr(r.state)
	local Form = nx_value("form_zdn_log")
	local index = Form.console_grid.RowCount
	local ctl = createTextControl(content)
	Form.console_grid:BeginUpdate()
	Form.console_grid:InsertRow(-1)
	Form.console_grid:SetGridControl(index, 0, ctl)
	Form.console_grid:EndUpdate()

	if r.state == "path_finding" then
		nx_execute("zdn_logic_vat_pham", "UseItem", 2, 69)
	end
end
