function add_title(text_title)
    local form = nx_value("form_stage_main\\form_talk_movie")
    if not nx_is_valid(form) then
        return
    end
    text_title = ZdnChangeTitle(text_title)
    form.mltbox_title:Clear()
    form.mltbox_title.HtmlText =
        nx_widestr('<center><font color="#FFFFFF"></font>') .. nx_widestr(text_title) .. nx_widestr("</center>")
    fresh_title_control(form)
end

function Utf8ToWstr(content)
    return nx_function("ext_utf8_to_widestr", content)
end

function ZdnChangeTitle(text_title)
    local tmpStr = nx_function("ext_utf8_to_widestr", "Hằng Nga ưng hối thâu linh dược")
    if nx_function("ext_ws_find", text_title, tmpStr) > -1 then
        return nx_widestr(text_title) .. Utf8ToWstr(' <font color="#FF0000">(Thiên →)</font>')
    end
    tmpStr = nx_function("ext_utf8_to_widestr", "Ánh nhật hà hoa biệt dạng hồng")
    if nx_function("ext_ws_find", text_title, tmpStr) > -1 then
        return nx_widestr(text_title) .. Utf8ToWstr(' <font color="#FF0000">(Thiên →)</font>')
    end
    tmpStr = nx_function("ext_utf8_to_widestr", "Lạc hà dữ cô vụ tề phi")
    if nx_function("ext_ws_find", text_title, tmpStr) > -1 then
        return nx_widestr(text_title) .. Utf8ToWstr(' <font color="#FF0000">(Thiên →)</font>')
    end
    tmpStr = nx_function("ext_utf8_to_widestr", "Tại thiên nguyện tác tỷ dực điểu")
    if nx_function("ext_ws_find", text_title, tmpStr) > -1 then
        return nx_widestr(text_title) .. Utf8ToWstr(' <font color="#FF0000">(_| Địa)</font>')
    end
    tmpStr = nx_function("ext_utf8_to_widestr", "Thương mang vạn khoảnh liên")
    if nx_function("ext_ws_find", text_title, tmpStr) > -1 then
        return nx_widestr(text_title) .. Utf8ToWstr(' <font color="#FF0000">(_| Địa)</font>')
    end
    tmpStr = nx_function("ext_utf8_to_widestr", "Sàng tiền minh nguyệt quang")
    if nx_function("ext_ws_find", text_title, tmpStr) > -1 then
        return nx_widestr(text_title) .. Utf8ToWstr(' <font color="#FF0000">(_| Địa)</font>')
    end
    tmpStr = nx_function("ext_utf8_to_widestr", "Tận thị Lưu Lang khứ hậu tài")
    if nx_function("ext_ws_find", text_title, tmpStr) > -1 then
        return nx_widestr(text_title) .. Utf8ToWstr(' <font color="#FF0000">(Huyền |_)</font>')
    end
    tmpStr = nx_function("ext_utf8_to_widestr", "Sái tửu khí điền ưng")
    if nx_function("ext_ws_find", text_title, tmpStr) > -1 then
        return nx_widestr(text_title) .. Utf8ToWstr(' <font color="#FF0000">(Huyền |_)</font>')
    end
    tmpStr = nx_function("ext_utf8_to_widestr", "Hiểu nhập hàn đồng giác")
    if nx_function("ext_ws_find", text_title, tmpStr) > -1 then
        return nx_widestr(text_title) .. Utf8ToWstr(' <font color="#FF0000">(Huyền |_)</font>')
    end
    tmpStr = nx_function("ext_utf8_to_widestr", "Bạch nhật Y Sơn tận")
    if nx_function("ext_ws_find", text_title, tmpStr) > -1 then
        return nx_widestr(text_title) .. Utf8ToWstr(' <font color="#FF0000">(← Hoàng)</font>')
    end
    tmpStr = nx_function("ext_utf8_to_widestr", "Yên hoa tam nguyệt hạ Dương Châu")
    if nx_function("ext_ws_find", text_title, tmpStr) > -1 then
        return nx_widestr(text_title) .. Utf8ToWstr(' <font color="#FF0000">(← Hoàng)</font>')
    end
    tmpStr = nx_function("ext_utf8_to_widestr", "Nhất phiến cô thành vạn nhẫn sơn")
    if nx_function("ext_ws_find", text_title, tmpStr) > -1 then
        return nx_widestr(text_title) .. Utf8ToWstr(' <font color="#FF0000">(← Hoàng)</font>')
    end
    return text_title
end
