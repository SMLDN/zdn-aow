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

-- for debug
function debug()
	dofile("D:\\auto\\debug.lua")
end
-- for debug