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
    local tmpStr = nx_string(nx_function("ext_utf8_to_widestr", "Hằng Nga ưng hối thâu linh dược"))
    if string.find(nx_string(text_title), tmpStr) then
        return nx_widestr(text_title) .. Utf8ToWstr(' <font color="#FF0000">(Thiên →)</font>')
    end
    tmpStr = nx_string(nx_function("ext_utf8_to_widestr", "Ánh nhật hà hoa biệt dạng hồng"))
    if string.find(nx_string(text_title), tmpStr) then
        return nx_widestr(text_title) .. Utf8ToWstr(' <font color="#FF0000">(Thiên →)</font>')
    end
    tmpStr = nx_string(nx_function("ext_utf8_to_widestr", "Lạc hà dữ cô vụ tề phi"))
    if string.find(nx_string(text_title), tmpStr) then
        return nx_widestr(text_title) .. Utf8ToWstr(' <font color="#FF0000">(Thiên →)</font>')
    end
    tmpStr = nx_string(nx_function("ext_utf8_to_widestr", "Tại thiên nguyện tác tỷ dực điểu"))
    if string.find(nx_string(text_title), tmpStr) then
        return nx_widestr(text_title) .. Utf8ToWstr(' <font color="#FF0000">(_| Địa)</font>')
    end
    tmpStr = nx_string(nx_function("ext_utf8_to_widestr", "Thương mang vạn khoảnh liên"))
    if string.find(nx_string(text_title), tmpStr) then
        return nx_widestr(text_title) .. Utf8ToWstr(' <font color="#FF0000">(_| Địa)</font>')
    end
    tmpStr = nx_string(nx_function("ext_utf8_to_widestr", "Sàng tiền minh nguyệt quang"))
    if string.find(nx_string(text_title), tmpStr) then
        return nx_widestr(text_title) .. Utf8ToWstr(' <font color="#FF0000">(_| Địa)</font>')
    end
    tmpStr = nx_string(nx_function("ext_utf8_to_widestr", "Tận thị Lưu Lang khứ hậu tài"))
    if string.find(nx_string(text_title), tmpStr) then
        return nx_widestr(text_title) .. Utf8ToWstr(' <font color="#FF0000">(Huyền |_)</font>')
    end
    tmpStr = nx_string(nx_function("ext_utf8_to_widestr", "Sái tửu khí điền ưng"))
    if string.find(nx_string(text_title), tmpStr) then
        return nx_widestr(text_title) .. Utf8ToWstr(' <font color="#FF0000">(Huyền |_)</font>')
    end
    tmpStr = nx_string(nx_function("ext_utf8_to_widestr", "Hiểu nhập hàn đồng giác"))
    if string.find(nx_string(text_title), tmpStr) then
        return nx_widestr(text_title) .. Utf8ToWstr(' <font color="#FF0000">(Huyền |_)</font>')
    end
    tmpStr = nx_string(nx_function("ext_utf8_to_widestr", "Bạch nhật Y Sơn tận"))
    if string.find(nx_string(text_title), tmpStr) then
        return nx_widestr(text_title) .. Utf8ToWstr(' <font color="#FF0000">(← Hoàng)</font>')
    end
    tmpStr = nx_string(nx_function("ext_utf8_to_widestr", "Yên hoa tam nguyệt hạ Dương Châu"))
    if string.find(nx_string(text_title), tmpStr) then
        return nx_widestr(text_title) .. Utf8ToWstr(' <font color="#FF0000">(← Hoàng)</font>')
    end
    tmpStr = nx_string(nx_function("ext_utf8_to_widestr", "Nhất phiến cô thành vạn nhẫn sơn"))
    if string.find(nx_string(text_title), tmpStr) then
        return nx_widestr(text_title) .. Utf8ToWstr(' <font color="#FF0000">(← Hoàng)</font>')
    end
    return text_title
end
