require("zdn_util")
Form = nil

function formOpen(form)
	Form = form
	local gui = nx_value("gui")
	-- form.Left = (gui.Width - form.Width) / 2
	form.Left = 10
	form.Top = (gui.Height - form.Height) / 2
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

function formClose()
	if onFormClose ~= nil then
		onFormClose()
	end
	if nx_is_valid(Form) then
		nx_destroy(Form)
	end
end

function onBtnCloseClick()
	Form:Close()
end

function updateBtnSubmitState(isRunning)
	if isRunning then
		Form.btn_submit.Text = Utf8ToWstr("Dừng")
		Form.btn_submit.ForeColor = "255,220,20,60"
	else
		Form.btn_submit.Text = Utf8ToWstr("Chạy")
		Form.btn_submit.ForeColor = "255,255,255,255"
	end
end
