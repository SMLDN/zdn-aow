require("zdn_lib\\util_functions")
require("zdn_form_common")

local ItemId
local BuffDataList = {}

function onFormOpen()
	local gui = nx_value("gui")
	Form.Left = (gui.Width - Form.Width) / 2
	Form.Top = (gui.Height - Form.Height) / 2
	loadBuffList()
end

function loadBuffList()
	BuffDataList = {
		{
			["buffId"] = "zdn_buff_no_delay",
			["descId"] = "desc_zdn_buff_no_delay",
			["photo"] = "icon\\buff\\buff_hungry.png"
		}
	}
	local gameClient = nx_value("game_client")
	local player = gameClient:GetPlayer()
	if not nx_is_valid(player) then
		return
	end
	local buffList = nx_function("get_buffer_list", player)
	local cnt = #buffList / 2
	for i = cnt, 1, -1 do
		local buffId = nx_string(buffList[i * 2 - 1])
		local buffInfo = nx_function("get_buffer_info", player, buffId, player)
		if #buffInfo == 3 then
			local level = buffInfo[1]
			local data = {
				["buffId"] = buffId,
				["descId"] = "desc_" .. buffId .. "_" .. nx_string(level),
				["photo"] = getBuffPhoto(buffId)
			}
			table.insert(BuffDataList, data)
		end
	end
	showBuff()
end

function showBuff()
	local cnt = #BuffDataList
	Form.buff_list_grid:Clear()
	Form.buff_list_grid.RowNum = cnt
	for i = 1, cnt do
		local data = BuffDataList[i]
		Form.buff_list_grid:AddItem(nx_int(i - 1), nx_string(data.photo), nx_widestr(data.buffId), nx_int(1), nx_int(0))
	end
end

function getBuffPhoto(buffId)
	local IniManager = nx_value("IniManager")
	local buffDataIni = IniManager:GetIniDocument("share\\Skill\\buff_new.ini")
	if not nx_is_valid(buffDataIni) then
		return ""
	end
	local sectionIndex = buffDataIni:FindSectionIndex(buffId)
	if sectionIndex < 0 then
		return ""
	end
	local buffNumber = buffDataIni:ReadString(sectionIndex, "StaticData", "")
	if buffNumber == "" then
		return
	end
	local buffStaticIni = nx_execute("util_functions", "get_ini", "share\\Skill\\buff_static.ini")
	if not nx_is_valid(buffStaticIni) then
		return ""
	end
	local sectionIndexNumber = buffStaticIni:FindSectionIndex(buffNumber)
	if sectionIndexNumber < 0 then
		return ""
	end
	return buffStaticIni:ReadString(sectionIndexNumber, "Photo", "")
end

function SetItem(itemId)
	ItemId = itemId
end

function onBuffListGridMouseout(grid, index)
	nx_execute("tips_game", "hide_tip")
end

function onBuffListGridMousein(grid, index)
	if BuffDataList[index + 1] ~= nil then
		local gui = nx_value("gui")
		local mouse_x, mouse_z = gui:GetCursorPosition()
		nx_execute("tips_game", "show_text_tip", util_text(BuffDataList[index + 1].descId), mouse_x, mouse_z)
	end
end

function onBuffListGridSelect(grid, index)
	local data = BuffDataList[index + 1]
	if data ~= nil then
		nx_execute("form_zdn_vat_pham_setting", "DoAddItem", ItemId, data.buffId, data.descId, data.photo)
		formClose()
	end
end
