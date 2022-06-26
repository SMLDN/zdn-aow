require("util_gui")
require("zdn_lib\\util_functions")
require("zdn_util")

local ListenList = {}

function addListen(file, msg, call, sleep, ...)
	refresh()
	local listen = {
		["File"] = file,
		["Msg"] = msg,
		["Time"] = TimerInit(),
		["Call"] = call,
		["Sleep"] = sleep,
		["Param"] = arg
	}

	if isListenExists(listen) then
		return
	end
	table.insert(ListenList, listen)
end

function removeListen(file, msg, call)
	for i, l in pairs(ListenList) do
		if file == l.File and msg == l.Msg and call == l.Call then
			table.remove(ListenList, i)
			return
		end
	end
end

function isListenExists(listen)
	for i, l in pairs(ListenList) do
		if listen.File == l.File and listen.Msg == l.Msg and listen.Call == l.Call then
			return true
		end
	end
	return false
end

function refresh()
	for i, listen in pairs(ListenList) do
		if listen.Sleep ~= -1 and TimerDiff(listen.Time) > listen.Sleep then
			table.remove(ListenList, i)
		end
	end
end

function Resolve(msg, ...)
	-- Console(nx_string("msg: ") .. nx_string(msg))
	refresh()
	for i, listen in pairs(ListenList) do
		if msg == listen.Msg then
			nx_execute(listen.File, listen.Call, unpack(listen.Param))
			if listen.Sleep ~= -1 then
				table.remove(ListenList, i)
			end
		end
	end

	if nx_string(msg) == "Sysinfo_qyoptalk_000" then
		nx_execute("zdn_logic_ky_ngo", "OnReceiveKyNgo", nx_string(arg[1]))
	end
end
