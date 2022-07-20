require("zdn_lib_moving")
require("zdn_form_common")

local RETURN_MAP = "city05"
local RETURN_POS = {300.73034667969, 78.078170776367, 854.36932373047}

function onBtnTeleClick(self)
  local target = self.Name
  if target == "monday" then
    if GetCurMap() ~= "city03" then
      TeleToHomePoint("HomePointcity03E")
      return
    end
    GoToPosition(383.25039672852, 55.382320404053, 403.24996948242)
  elseif target == "tuesday" then
    if GetCurMap() ~= "scene08" then
      TeleToHomePoint("HomePointscene08D")
      return
    end
    GoToPosition(1349.2469482422, 4.1016254425049, 276.25003051758)
  elseif target == "wednesday" then
    if GetCurMap() ~= "city04" then
      TeleToHomePoint("HomePointcity04E")
      return
    end
    GoToPosition(728.99761962891, -27.31739616394, 1168.9582519531)
  elseif target == "thursday" then
    if GetCurMap() ~= "city01" then
      TeleToHomePoint("HomePointcity01D")
      return
    end
    GoToPosition(827.25024414063, -87.16349029541, -200.75)
  elseif target == "friday" then
    if GetCurMap() ~= "city02" then
      TeleToHomePoint("HomePointcity02E")
      return
    end
    GoToPosition(300.42974853516, 12.754096031189, 876.72863769531)
  end
end

function onBtnReturnClick()
  local pathFinding = nx_value("path_finding")
  if not nx_is_valid(pathFinding) then
    return
  end
  pathFinding:FindPathScene(RETURN_MAP, RETURN_POS[1], RETURN_POS[2], RETURN_POS[3], 0)
end
