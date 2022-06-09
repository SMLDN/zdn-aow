require("player_state\\state_input")
require("zdn_util")

local PublicHomePointList = {}
local TimerFindPath = 0

local function isCurseLoading()
	local load = nx_value("form_stage_main\\form_main\\form_main_curseloading")
	if nx_is_valid(load) and load.Visible then
		return true
	end
	return false
end

local function getPlayer()
	local client = nx_value("game_client")
	if not nx_is_valid(client) then
		return
	end
	return client:GetPlayer()
end

local function setAngle(x, y, z)
	local role = nx_value("role")
	local scene_obj = nx_value("scene_obj")
	if not nx_is_valid(role) or not nx_is_valid(scene_obj) then
		return
	end
	scene_obj:SceneObjAdjustAngle(role, x, z)
end

local function waitToCollide(x, y, z, seconds)
	nx_pause(1)
	local role = nx_value("role")
	if not nx_is_valid(role) then
		return
	end
	emit_player_input(role, PLAYER_INPUT_LOGIC, LOGIC_SERVER_JUMP_POS, x, y, z, 0, 1)
	nx_pause(1)
	local role = nx_value("role")
	local game_visual = nx_value("game_visual")
	if not nx_is_valid(role) or not nx_is_valid(game_visual) then
		return
	end
	role.server_pos_can_accept = true
	setAngle(x, y, z)
	role.move_dest_orient = role.AngleY
	game_visual:SetRoleMoveDestX(role, x)
	game_visual:SetRoleMoveDestY(role, y)
	game_visual:SetRoleMoveDestZ(role, z)
	game_visual:SetRoleMoveDistance(role, 1)
	game_visual:SetRoleMaxMoveDistance(role, 1)
	game_visual:SwitchPlayerState(role, 1, 103)
	role.state = "zdn_jump"
end

local function jumpTo(x, y, z)
	local role = nx_value("role")
	if not nx_is_valid(role) or not nx_is_valid(nx_value("game_visual")) then
		return
	end
	StopFindPath()
	setAngle(x, y, z)
	nx_value("game_visual"):SwitchPlayerState(role, 1, 9)
	waitToCollide(x, y, z)
end

local function shortJumpCollide()
	local role = nx_value("role")
	if not nx_is_valid(role) then
		return
	end
	local angle = role.face_angle * 60 * 2 * math.pi / 360
	local x = role.PositionX + 1 * math.sin(angle)
	local y = role.PositionY + 1
	local z = role.PositionZ + 1 * math.cos(angle)
	jumpTo(x, y, z)
end

local function positionFloat(value)
	return nx_number(string.format("%.2f", value))
end

local function isStaticState()
	local role = nx_value("role")
	local client = nx_value("game_client")
	local player = client:GetPlayer()
	if not nx_is_valid(role) or not nx_is_valid(client) or not nx_is_valid(player) then
		return false
	end
	if
		role.state ~= "static" and role.state ~= "ride_stay" and role.state ~= "swim_stop" and role.state ~= "path_finding" and
			role.state ~= "slide"
	 then
		return false
	end

	local result = nx_string(player:QueryProp("State"))
	return result ~= "hurt_stun_2"
end

local function endSitCross()
	if TimerDiff(TimerEndSitcross) < 5 then
		return false
	end
	TimerEndSitcross = TimerInit()
	nx_execute("custom_sender", "custom_sitcross", 0)
end

local function getClassIndex(point)
	for i = 1, #ClassPoint do
		if ClassPoint[i].ListPoint[point] == 1 then
			return i
		end
	end
	return 0
end

local function pathFind(x, y, z)
	local pathFinding = nx_value("path_finding")
	if not nx_is_valid(pathFinding) then
		return
	end
	if GetDistance(x, y, z) > 50 then
		pathFinding:FindPathScene(GetCurMap(), x, y, z, 0)
	else
		pathFinding:FindPath(x, y, z, 0)
	end
end

local function getCanLinkPoint(src_class, dest_class)
	return ClassPoint[src_class].LinkClass[dest_class]
end

local function sendDie()
	local role = nx_value("role")
	local game_visual = nx_value("game_visual")
	if not nx_is_valid(role) or not nx_is_valid(game_visual) then
		return
	end
	local x, y, z = GetPlayerPosition()
	role.server_pos_can_accept = true
	game_visual:SetRoleMoveDestX(role, x)
	game_visual:SetRoleMoveDestY(role, y)
	game_visual:SetRoleMoveDestZ(role, z)
	game_visual:SetRoleMoveDistance(role, 1)
	game_visual:SetRoleMaxMoveDistance(role, 1)
	game_visual:SwitchPlayerState(role, 1, 103)
	role.state = "zdn_jump"
end

local function checkErrorMove()
	local role = nx_value("role")
	if not nx_is_valid(role) then
		return
	end
	if
		not nx_find_custom(role, "CheckMoveTimer") or not nx_find_custom(role, "CheckMoveX") or
			not nx_find_custom(role, "CheckMoveY") or
			not nx_find_custom(role, "CheckMoveZ") or
			not nx_find_custom(role, "MoveErrorTime")
	 then
		role.CheckMoveTimer = TimerInit()
		role.CheckMoveX = role.PositionX
		role.CheckMoveY = role.PositionY
		role.CheckMoveZ = role.PositionZ
		role.MoveErrorTime = TimerInit()
		return false
	end
	if
		TimerDiff(role.CheckMoveTimer) < 3 and role.CheckMoveX == role.PositionX and role.CheckMoveY == role.PositionY and
			role.CheckMoveZ == role.PositionZ
	 then
		role.CheckMoveTimer = TimerInit()
		if TimerDiff(role.MoveErrorTime) > 60 then
			sendDie()
		else
			return true
		end
	end
	role.CheckMoveTimer = TimerInit()
	role.CheckMoveX = role.PositionX
	role.CheckMoveY = role.PositionY
	role.CheckMoveZ = role.PositionZ
	role.MoveErrorTime = TimerInit()
end

local function distance3d(bx, by, bz, dx, dy, dz)
	return math.sqrt((dx - bx) * (dx - bx) + (dy - by) * (dy - by) + (dz - bz) * (dz - bz))
end

local function isCanLinkClass(src_class, dest_class)
	local x0, y0, z0 = 0, 0, 0
	local x1, y1, z1 = 0, 0, 0
	local map = GetCurMap()
	local path_finding = nx_value("path_finding")
	if not nx_is_valid(path_finding) then
		return false
	end
	for i, v1 in pairs(ClassPoint[src_class].NotLinkClass) do
		if i == dest_class then
			return false
		end
	end
	for i, v1 in pairs(ClassPoint[src_class].LinkClass) do
		if i == dest_class then
			return true
		end
	end
	local can_link = false
	for src_point, v1 in pairs(ClassPoint[src_class].ListPoint) do
		x0, y0, z0 = path_finding:GetPathPointPos(map, src_point)
		for dest_point, v2 in pairs(ClassPoint[dest_class].ListPoint) do
			x1, y1, z1 = path_finding:GetPathPointPos(map, dest_point)
			if distance3d(x0, y0, z0, x1, y1, z1) < 20 then
				ClassPoint[src_class].LinkClass[dest_class] = src_point
				ClassPoint[dest_class].LinkClass[src_class] = dest_point
				can_link = true
				break
			end
		end
		if can_link then
			break
		end
	end
	if can_link then
		return true
	end
	ClassPoint[src_class].NotLinkClass[dest_class] = 1
	ClassPoint[dest_class].NotLinkClass[src_class] = 1
	return false
end

local function getPosByPoint(point)
	local path_finding = nx_value("path_finding")
	local x, y, z = path_finding:GetPathPointPos(GetCurMap(), point)
	return x, y, z
end

local function isPathFinding()
	local role = nx_value("role")
	if not nx_is_valid(role) then
		return false
	end
	if not nx_find_custom(role, "state") then
		return false
	end
	local state = nx_string(role.state)
	return state == "path_finding" or state == "ride"
end

local function zdnMove(x, y, z, src_point, dest_point)
	local src_x, src_y, src_z = getPosByPoint(src_point)
	local dest_x, dest_y, dest_z = getPosByPoint(dest_point)

	if GetDistance(dest_x, dest_y, dest_z) < 1 then
		jumpTo(x, y, z)
		return
	end

	pathFind(dest_x, dest_y, dest_z)
	if isPathFinding() then
		return
	end
	pathFind(dest_x, -10000, dest_z)
	if isPathFinding() then
		return
	end

	if GetDistance(src_x, src_y, src_z) > 0.1 then
		pathFind(src_x, src_y, src_z)
		if isPathFinding() then
			return
		end
		jumpTo(src_x, src_y, src_z)
	else
		checkErrorMove()
	end
end

local function distance2d(bx, bz, dx, dz)
	return math.sqrt((dx - bx) * (dx - bx) + (dz - bz) * (dz - bz))
end

local function getNearPointList(x, y, z, dis)
	local list = {}
	local distance = {}
	local xo, yo, zo = 0, 0, 0
	local found = false
	local role = nx_value("role")
	local path_finding = nx_value("path_finding")
	if not nx_is_valid(path_finding) or not nx_is_valid(role) then
		return list
	end
	local map = GetCurMap()
	local point_count = path_finding:GetPathPointCount(map)
	if point_count == 0 then
		return list
	end
	local d = 0
	local insert_index = 1
	for i = 1, point_count do
		xo, yo, zo = path_finding:GetPathPointPos(map, i)
		d = distance2d(x, z, xo, zo)
		if d < dis then
			distance[i] = d
			insert_index = #list + 1
			for j = 1, #list do
				if d < distance[list[j]] then
					insert_index = j
					break
				end
			end
			table.insert(list, insert_index, i)
		end
	end
	return list
end

local function tryLineToPoint(point)
	local src_x, src_y, src_z = getPosByPoint(point)
	local x, y, z = GetPlayerPosition()
	local path_finding = nx_value("path_finding")
	if not nx_is_valid(path_finding) then
		return
	end
	return path_finding:TryLine(GetCurMap(), x, y, z, src_x, src_y, src_z)
end

local function isClassPointHasPoint(point)
	for i = 1, #ClassPoint do
		if ClassPoint[i].ListPoint[point] == 1 then
			return true
		end
	end
	return false
end

local function getPointList(point)
	local path_finding = nx_value("path_finding")
	if not nx_is_valid(path_finding) then
		return nil
	end
	local cur_map = GetCurMap()
	local linked_list = {}
	local find_list = {}
	local search_list = {}
	table.insert(search_list, point)
	while #search_list > 0 do
		point = search_list[1]
		table.remove(search_list, 1)
		linked_list[point] = 1
		local links = path_finding:GetLinkPoints(cur_map, point)
		for i = 1, #links do
			if linked_list[links[i]] == nil and find_list[links[i]] == nil then
				find_list[links[i]] = 1
				table.insert(search_list, links[i])
			end
		end
	end
	return linked_list
end

local function insertClassPoint(point)
	temp_class = {}
	temp_class.LinkClass = {}
	temp_class.NotLinkClass = {}
	temp_class.ListPoint = {}
	GroupPoint = {}
	CurMap = GetCurMap()
	PathFindObj = nx_value("path_finding")
	if not nx_is_valid(PathFindObj) then
		return false
	end
	local list = getPointList(point)
	if list ~= nil then
		temp_class.ListPoint = list
		table.insert(ClassPoint, temp_class)
	end
end

local function isExisPath(src_point, dest_point)
	if ClassPoint == nil or CurMap ~= GetCurMap() then
		ClassPoint = {}
		CurMap = ""
	end
	if not isClassPointHasPoint(src_point) then
		insertClassPoint(src_point)
	end
	if not isClassPointHasPoint(dest_point) then
		insertClassPoint(dest_point)
	end
	local src_class = getClassIndex(src_point)
	local dest_class = getClassIndex(dest_point)
	if src_class == 0 or dest_class == 0 then
		return false
	end
	if src_class == dest_class then
		return true
	end
	return false
end

local function zdnFindPath(x, y, z, err)
	local xo, yo, zo = GetPlayerPosition()
	local src_list = getNearPointList(xo, yo, zo, 20)
	local dest_list = getNearPointList(x, y, z, 20)
	local dest_point = 0
	local src_point = 0
	local dis = GetDistance(x, y, z)
	if dis < 10 then
		jumpTo(x, y, z)
		return
	end
	if #src_list > 0 and dis > 20 then
		xo, yo, zo = getPosByPoint(dest_list[1])
		pathFind(xo, -10000, zo)
		if isPathFinding() then
			return
		end
	end

	for i = 1, #src_list do
		for j = 1, #dest_list do
			if tryLineToPoint(src_list[i]) and isExisPath(src_list[i], dest_list[j]) then
				src_point = src_list[i]
				dest_point = dest_list[j]
				break
			end
		end
		if src_point ~= 0 then
			break
		end
	end
	if src_point == 0 then
		for i = 1, #src_list do
			for j = 1, #dest_list do
				if isExisPath(src_list[i], dest_list[j]) then
					src_point = src_list[i]
					dest_point = dest_list[j]
					break
				end
			end
			if src_point ~= 0 then
				break
			end
		end
	end
	if src_point == 0 then
		for i = 1, #src_list do
			for j = 1, #dest_list do
				if isCanLinkClass(getClassIndex(src_list[i]), getClassIndex(dest_list[j])) then
					src_point = src_list[i]
					dest_point = dest_list[j]
					break
				end
			end
			if src_point ~= 0 then
				break
			end
		end
	end

	if src_point == 0 then
		nx_execute("zdn_logic_skill", "TuSat")
		return
	else
		nx_execute("zdn_logic_skill", "DungTuSat")
	end
	local src_class = getClassIndex(src_point)
	local dest_class = getClassIndex(dest_point)

	if src_class ~= dest_class then
		dest_point = getCanLinkPoint(src_class, dest_class)
	end
	zdnMove(x, y, z, src_point, dest_point)
end

local function setFindPath(x, y, z)
	local role = nx_value("role")
	if not nx_is_valid(role) then
		return false
	end
	if role.state == "sitcross" then
		endSitCross()
		return
	elseif not isStaticState() then
		return
	end
	if nx_execute("zdn_logic_base", "GetLogicState") == 102 then
		endSitCross()
		return false
	end
	pathFind(x, y, z)
	if not isPathFinding() then
		zdnFindPath(x, y, z)
	end
	TimerCheckStuck = TimerInit()
	local role = nx_value("role")
	if not nx_is_valid(role) then
		return
	end
	role.FindPathX = x
	role.FindPathY = y
	role.FindPathZ = z
	role.FindPathMap = GetCurMap()
end

local function isFinding(x, y, z)
	if not isPathFinding() then
		return false
	end
	local role = nx_value("role")
	if not nx_is_valid(role) then
		return false
	end
	if
		not nx_find_custom(role, "FindPathX") or not nx_find_custom(role, "FindPathY") or
			not nx_find_custom(role, "FindPathZ") or
			not nx_find_custom(role, "FindPathMap") or
			role.FindPathMap ~= GetCurMap()
	 then
		return false
	end
	return distance3d(x, y, z, role.FindPathX, role.FindPathY, role.FindPathZ) < 6
end

local function isFindPathStuck()
	if not isPathFinding() then
		TimerCheckStuck = TimerInit()
		return true
	end
	if TimerDiff(TimerCheckStuck) < 1 then
		return true
	end
	TimerCheckStuck = TimerInit()
	local role = nx_value("role")
	if not nx_is_valid(role) then
		return false
	end
	if
		not nx_find_custom(role, "LastRolePositionX") or not nx_find_custom(role, "LastRolePositionY") or
			not nx_find_custom(role, "LastRolePositionZ") or
			not nx_find_custom(role, "LastRolePositionMap") or
			role.LastRolePositionMap ~= GetCurMap()
	 then
	elseif
		role.LastRolePositionX == positionFloat(role.PositionX) and role.LastRolePositionY == positionFloat(role.PositionY) and
			role.LastRolePositionZ == positionFloat(role.PositionZ)
	 then
		shortJumpCollide()
		TimerJump = TimerInit()
		return false
	end

	role.LastRolePositionMap = GetCurMap()
	role.LastRolePositionX = positionFloat(role.PositionX)
	role.LastRolePositionY = positionFloat(role.PositionY)
	role.LastRolePositionZ = positionFloat(role.PositionZ)
	return true
end

local function getVisualObj(obj)
	if not nx_is_valid(obj) then
		return
	end
	return nx_value("game_visual"):GetSceneObj(obj.Ident)
end

local function sendHomePointMsgToServer(...)
	nx_execute("form_stage_main\\form_homepoint\\home_point_data", "send_homepoint_msg_to_server", unpack(arg))
end

local function useHomePoint(homePoint)
	sendHomePointMsgToServer(1, homePoint, 0)
end

local function addHomePoint(homePoint)
	sendHomePointMsgToServer(2, homePoint)
end

local function deleteHomePointByPosition(pos)
	local c = 0
	local deletePoint = ""
	local player = nx_value("game_client"):GetPlayer()
	if not (nx_is_valid(player)) then
		return false
	end
	local nCount = player:GetRecordRows("HomePointList")
	if nx_int(nCount) <= nx_int(0) then
		return false
	end
	for i = 0, nCount - 1 do
		local homePointId = nx_string(player:QueryRecord("HomePointList", i, 0))
		local homePointType = player:QueryRecord("HomePointList", i, 1)
		if nx_int(homePointType) == nx_int(1) or nx_int(homePointType) == nx_int(0) then
			c = c + 1
			deletePoint = homePointId
		end
	end
	if c >= pos then
		sendHomePointMsgToServer(3, deletePoint)
		return true
	end
	return false
end

local function isHaveHomePoint(homePointId)
	local player = nx_value("game_client"):GetPlayer()
	if not (nx_is_valid(player)) then
		return false
	end
	local nCount = player:GetRecordRows("HomePointList")
	if nx_int(nCount) <= nx_int(0) then
		return false
	end
	for i = 0, nCount - 1 do
		local hpId = nx_string(player:QueryRecord("HomePointList", i, 0))
		if hpId == homePointId then
			return true
		end
	end
	return false
end

-- Public
function TeleToHomePoint(homePoint)
	if isCurseLoading() then
		return
	end
	StopFindPath()
	if isHaveHomePoint(homePoint) then
		useHomePoint(homePoint)
	else
		deleteHomePointByPosition(5)
		addHomePoint(homePoint)
		nx_pause(1)
		useHomePoint(homePoint)
	end
end

function GoToMapByPublicHomePoint(map)
	if GetCurMap() == map then
		return
	end
	if #PublicHomePointList == 0 then
		local list = IniLoadAllData(nx_resource_path() .. "zdn\\data\\homepoint.ini")
		for m, homePointList in pairs(list) do
			PublicHomePointList[m] = homePointList["public"]
		end
	end
	TeleToHomePoint(PublicHomePointList[map])
end

function StopFindPath()
	if not nx_is_valid(nx_value("path_finding")) then
		return
	end
	nx_value("path_finding"):StopPathFind(1)
end

function GetCurMap()
	local map = nx_value("form_stage_main\\form_map\\form_map_scene")
	if not nx_is_valid(map) then
		return "0"
	end
	return map.current_map
end

function GoToPosition(x, y, z)
	if TimerDiff(TimerFindPath) < 1 then
		return
	end
	TimerFindPath = TimerInit()
	if TimerDiff(TimerJump) < 4 then
		return
	end
	if not isFindPathStuck() or isFinding(x, y, z) then
		return
	end
	if GetDistance(x, y, z) < 1 then
		return
	end
	nx_execute("zdn_logic_skill", "StopParry")
	setFindPath(x, y, z)
end

function GoToNpc(map, npc)
	local x, y, z = -10000
	x, y, z = GetNpcPostion(map, npc)
	if x == -10000 and y == -10000 and z == -10000 then
		return false
	end
	if GetDistance(x, y, z) > 1.8 then
		GoToPosition(x, y, z)
		return false
	end
	return true
end

function GetNpcPostion(map, npc)
	return nx_execute("hyperlink_manager", "find_npc_pos", map, npc)
end

function GetDistanceToObj(obj)
	local vObj = getVisualObj(obj)
	if not nx_is_valid(vObj) then
		return 9999999999
	end
	return GetDistance(vObj.PositionX, vObj.PositionY, vObj.PositionZ)
end

function GetDistanceObjToPosition(obj, x, y, z)
	local vObj = getVisualObj(obj)
	if not nx_is_valid(vObj) then
		return 9999999999
	end
	return distance3d(vObj.PositionX, vObj.PositionY, vObj.PositionZ, x, y, z)
end

function GoToObj(obj)
	local vObj = getVisualObj(obj)
	if not nx_is_valid(vObj) then
		return
	end
	local posX = vObj.PositionX
	local posY = vObj.PositionY
	local posZ = vObj.PositionZ
	GoToPosition(vObj.PositionX, vObj.PositionY, vObj.PositionZ)
end

function GetDistance(x, y, z)
	local p = nx_value("game_visual"):GetPlayer()
	if not (nx_is_valid(p)) then
		return 9000000000
	end
	return math.pow(math.pow(p.PositionX - x, 2) + math.pow(p.PositionY - y, 2) + math.pow(p.PositionZ - z, 2), 1 / 2)
end

function XuongNgua()
	local player = getPlayer()
	if not nx_is_valid(player) then
		return
	end
	local hourseState = player:QueryProp("Mount")
	if nx_string(hourseState) ~= nx_string("") then
		nx_execute("custom_sender", "custom_send_ride_skill", nx_string("riding_dismount"))
	end
end

function GetPlayerPosition()
	local role = nx_value("role")
	if not nx_is_valid(role) then
		return 0, 0, 0
	end
	return role.PositionX, role.PositionY, role.PositionZ
end
