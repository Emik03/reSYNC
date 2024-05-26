-- The main function
function draw()
    imgui.Begin("re:||SYNC", imgui_window_flags.AlwaysAutoResize)
    Theme()

    local ms = get("ms", 0)
    local note = get("note", true)
    local ln = get("ln", true)
    local bpm = get("bpm", true)
    local sv = get("sv", true)
    local bm = get("bm", true)

    if imgui.Button("go") then
        resync(ms, note, ln, bpm, sv, bm)
    end

    imgui.SameLine(0, 10)
    imgui.PushItemWidth(170)
    _, ms = imgui.InputFloat("ms", ms, 1, 1, "%.2f", imgui_input_text_flags.CharsScientific)
    imgui.PopItemWidth()
    imgui.Separator()

    _, note = imgui.Checkbox("include notes", note)
    _, ln = imgui.Checkbox("include ln tails", ln)
    _, bpm = imgui.Checkbox("include bpms", bpm)
    _, sv = imgui.Checkbox("include svs", sv)
    _, bm = imgui.Checkbox("include bookmarks", bm)

    state.SetValue("ms", ms)
    state.SetValue("note", note)
    state.SetValue("ln", ln)
    state.SetValue("bpm", bpm)
    state.SetValue("sv", sv)
    state.SetValue("bm", bm)

    imgui.End()
end

--- Resyncs the chart.
--- @param ms number
--- @param note boolean
--- @param bpm boolean
--- @param sv boolean
--- @param bm boolean
function resync(ms, note, ln, bpm, sv, bm)
    if ms == 0 or (not note and not bpm and not sv and not bm) then
        return
    end

    local notesToAdd = {}
    local notesToRemove = {}
    local bpmsToAdd = {}
    local bpmsToRemove = {}
    local svsToAdd = {}
    local svsToRemove = {}
    local bmsToAdd = {}
    local bmsToRemove = {}
    local min = 1 / 0
    local max = -1 / 0
    local objects = map.HitObjects
    local selected = false

    if #state.SelectedHitObjects > 0 then
        objects = state.SelectedHitObjects
        selected = true
    end

    for _, x in pairs(objects) do
        if note or ln then
            local startTime = x.StartTime
            local endTime = x.EndTime

            if note then
                startTime = startTime + ms
            end

            if ln and endTime ~= 0 then
                endTime = endTime + ms
            end

            table.insert(notesToRemove, x)
            table.insert(notesToAdd, utils.CreateHitObject(startTime, x.Lane, endTime, x.HitSound, x.EditorLayer))
        end

        min = math.min(x.StartTime, min)
        max = math.max(x.StartTime, max)
    end

    if bpm then
        for _, x in pairs(map.TimingPoints) do
            if not selected or (x.StartTime >= min and x.StartTime <= max) then
                table.insert(bpmsToRemove, x)
                table.insert(bpmsToAdd, utils.CreateTimingPoint(x.StartTime + ms, x.Bpm, x.Signature, x.Hidden))
            end
        end
    end

    if sv then
        for _, x in pairs(map.ScrollVelocities) do
            if not selected or (x.StartTime >= min and x.StartTime <= max) then
                table.insert(svsToRemove, x)
                table.insert(svsToAdd, utils.CreateScrollVelocity(x.StartTime + ms, x.Multiplier))
            end
        end
    end

    if bm then
        for _, x in pairs(map.Bookmarks) do
            if not selected or (x.StartTime >= min and x.StartTime <= max) then
                table.insert(svsToRemove, x)
                table.insert(svsToAdd, utils.CreateBookmark(x.StartTime + ms, x.note))
            end
        end
    end

    actions.PerformBatch({
        utils.CreateEditorAction(action_type.RemoveHitObjectBatch, notesToRemove),
        utils.CreateEditorAction(action_type.PlaceHitObjectBatch, notesToAdd),
        utils.CreateEditorAction(action_type.RemoveTimingPointBatch, bpmsToRemove),
        utils.CreateEditorAction(action_type.AddTimingPointBatch, bpmsToAdd),
        utils.CreateEditorAction(action_type.RemoveBookmarkBatch, bmsToRemove),
        utils.CreateEditorAction(action_type.AddBookmarkBatch, bmsToAdd)
    })
end

--- Gets the RGBA object of the provided hex value.
--- @param hex string
--- @return number
function rgb(hex)
    hex = hex:gsub("#","")

    return {
    	tonumber("0x"..hex:sub(1, 2), 16) / 255.0,
    	tonumber("0x"..hex:sub(3, 4), 16) / 255.0,
    	tonumber("0x"..hex:sub(5, 6), 16) / 255.0,
    	255
    }
end

--- Gets the value from the current state.
--- @param identifier string
--- @param defaultValue any
--- @return any
function get(identifier, defaultValue)
    local val = state.GetValue(identifier)

    if val == nil then
        return defaultValue
    end

    return val
end

--- Applies the theme.
function Theme()
    -- Accent colors are unused, but are here if you wish to change that.
    -- local green = rgb("#50FA7B")
    -- local orange = rgb("#FFB86C")
    -- local pink = rgb("#FF79C6")
    -- local purple = rgb("#BD93F9")
    -- local red = rgb("#FF5555")
    -- local yellow = rgb("#F1FA8C")

    local cyan = rgb("#8BE9FD")
    local morsels = rgb("#191A21")
    local background = rgb("#282A36")
    local current = rgb("#44475A")
    local foreground = rgb("#F8F8F2")
    local comment = rgb("#6272A4")
    local rounding = 25
    local spacing = { 10, 10 }

    imgui.PushStyleColor(imgui_col.Text, foreground)
    imgui.PushStyleColor(imgui_col.TextDisabled, comment)
    imgui.PushStyleColor(imgui_col.WindowBg, morsels)
    imgui.PushStyleColor(imgui_col.ChildBg, morsels)
    imgui.PushStyleColor(imgui_col.PopupBg, morsels)
    imgui.PushStyleColor(imgui_col.Border, background)
    imgui.PushStyleColor(imgui_col.BorderShadow, background)
    imgui.PushStyleColor(imgui_col.FrameBg, background)
    imgui.PushStyleColor(imgui_col.FrameBgHovered, current)
    imgui.PushStyleColor(imgui_col.FrameBgActive, current)
    imgui.PushStyleColor(imgui_col.TitleBg, background)
    imgui.PushStyleColor(imgui_col.TitleBgActive, current)
    imgui.PushStyleColor(imgui_col.TitleBgCollapsed, current)
    imgui.PushStyleColor(imgui_col.MenuBarBg, background)
    imgui.PushStyleColor(imgui_col.ScrollbarBg, background)
    imgui.PushStyleColor(imgui_col.ScrollbarGrab, background)
    imgui.PushStyleColor(imgui_col.ScrollbarGrabHovered, current)
    imgui.PushStyleColor(imgui_col.ScrollbarGrabActive, current)
    imgui.PushStyleColor(imgui_col.CheckMark, cyan)
    imgui.PushStyleColor(imgui_col.SliderGrab, current)
    imgui.PushStyleColor(imgui_col.SliderGrabActive, comment)
    imgui.PushStyleColor(imgui_col.Button, current)
    imgui.PushStyleColor(imgui_col.ButtonHovered, comment)
    imgui.PushStyleColor(imgui_col.ButtonActive, comment)
    imgui.PushStyleColor(imgui_col.Header, background)
    imgui.PushStyleColor(imgui_col.HeaderHovered, current)
    imgui.PushStyleColor(imgui_col.HeaderActive, current)
    imgui.PushStyleColor(imgui_col.Separator, background)
    imgui.PushStyleColor(imgui_col.SeparatorHovered, background)
    imgui.PushStyleColor(imgui_col.SeparatorActive, background)
    imgui.PushStyleColor(imgui_col.ResizeGrip, background)
    imgui.PushStyleColor(imgui_col.ResizeGripHovered, background)
    imgui.PushStyleColor(imgui_col.ResizeGripActive, background)
    imgui.PushStyleColor(imgui_col.Tab, background)
    imgui.PushStyleColor(imgui_col.TabHovered, current)
    imgui.PushStyleColor(imgui_col.TabActive, current)
    imgui.PushStyleColor(imgui_col.TabUnfocused, current)
    imgui.PushStyleColor(imgui_col.TabUnfocusedActive, current)
    imgui.PushStyleColor(imgui_col.PlotLines, cyan)
    imgui.PushStyleColor(imgui_col.PlotLinesHovered, foreground)
    imgui.PushStyleColor(imgui_col.PlotHistogram, cyan)
    imgui.PushStyleColor(imgui_col.PlotHistogramHovered, foreground)
    imgui.PushStyleColor(imgui_col.TextSelectedBg, comment)
    imgui.PushStyleColor(imgui_col.DragDropTarget, current)
    imgui.PushStyleColor(imgui_col.NavHighlight, current)
    imgui.PushStyleColor(imgui_col.NavWindowingHighlight, current)
    imgui.PushStyleColor(imgui_col.NavWindowingDimBg, current)
    imgui.PushStyleColor(imgui_col.ModalWindowDimBg, current)

    imgui.PushStyleVar(imgui_style_var.Alpha, 1)
    imgui.PushStyleVar(imgui_style_var.WindowBorderSize, 0)
    imgui.PushStyleVar(imgui_style_var.WindowMinSize, { 240, 0 })
    imgui.PushStyleVar(imgui_style_var.WindowTitleAlign, { 0, 0.4 })
    imgui.PushStyleVar(imgui_style_var.ChildRounding, rounding)
    imgui.PushStyleVar(imgui_style_var.ChildBorderSize, 0)
    imgui.PushStyleVar(imgui_style_var.PopupRounding, rounding)
    imgui.PushStyleVar(imgui_style_var.PopupBorderSize, { 0, 0 })
    imgui.PushStyleVar(imgui_style_var.FramePadding, spacing)
    imgui.PushStyleVar(imgui_style_var.FrameRounding, rounding)
    imgui.PushStyleVar(imgui_style_var.FrameBorderSize, 0)
    imgui.PushStyleVar(imgui_style_var.ItemSpacing, spacing)
    imgui.PushStyleVar(imgui_style_var.ItemInnerSpacing, spacing)
    imgui.PushStyleVar(imgui_style_var.ItemInnerSpacing, spacing)
    imgui.PushStyleVar(imgui_style_var.IndentSpacing, spacing)
    imgui.PushStyleVar(imgui_style_var.ScrollbarSize, 10)
    imgui.PushStyleVar(imgui_style_var.ScrollbarRounding, rounding)
    imgui.PushStyleVar(imgui_style_var.GrabMinSize, 0)
    imgui.PushStyleVar(imgui_style_var.GrabRounding, rounding)
    imgui.PushStyleVar(imgui_style_var.TabRounding, rounding)
    imgui.PushStyleVar(imgui_style_var.ButtonTextAlign, { 0.5, 0.5 })
end

