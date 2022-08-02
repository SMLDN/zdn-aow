require("util_gui")

local Running = false
local ContentList = {}

function Start(chatType, content)
    addToContentList(chatType, content)
    if Running then
        return
    end
    showChatForm()
    Running = true
    while Running do
        loopChat()
        nx_pause(1.5)
    end
end

function Stop()
    Running = false
    ContentList = {}
end

function loopChat()
    local cnt = #ContentList
    for i = 1, cnt do
        nx_execute("custom_sender", "custom_chat", ContentList[i][1], ContentList[i][2])
        nx_pause(0.05)
    end
end

function addToContentList(chatType, content)
    local cnt = #ContentList
    for i = 1, cnt do
        if ContentList[i][1] == chatType then
            return
        end
    end
    local c = {}
    c[1] = chatType
    c[2] = content
    table.insert(ContentList, c)
end

function showChatForm()
    util_show_form("form_zdn_chat_loop", true)
    local fc = nx_value("form_stage_main\\form_main\\form_main_chat")
    if not nx_is_valid(fc) then
        return
    end
    local f = nx_value("form_zdn_chat_loop")
    if not nx_is_valid(f) then
        return
    end
    f.Left = 328
    f.Top = fc.group_chat_input.AbsTop
end
