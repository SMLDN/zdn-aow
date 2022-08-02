require("zdn_form_common")

local Logic = "zdn_logic_chat_loop"

function onBtnSubmitClick()
	nx_execute(Logic, "Stop")
	onBtnCloseClick()
end
