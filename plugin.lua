-- The main function
function draw()
    imgui.Begin("re:||SYNC")
    Theme()

    local ms = get("ms", 0)
    local note = get("note", true)
    local bpm = get("bpm", true)
    local sv = get("sv", true)
    local bm = get("bm", true)

    _, ms = imgui.InputFloat("ms", ms)

	Separator()

    _, note = imgui.Checkbox("include notes", note)
    _, bpm = imgui.Checkbox("include bpm", bpm)
    _, sv = imgui.Checkbox("include sv", sv)
    _, bm = imgui.Checkbox("include bookmark", bm)

	Separator()

    if imgui.Button("go") then
        resync(ms, note, bpm, sv, bm)
    end

    state.SetValue("ms", ms)
    state.SetValue("note", note)
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
function resync(ms, note, bpm, sv, bm)
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
        if note then
            table.insert(notesToRemove, x)
            table.insert(notesToAdd, utils.CreateHitObject(x.StartTime + ms, x.Lane, x.EndTime, x.HitSound, x.EditorLayer))
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
    -- Accent colors are unused, but are here in case if you want to change that.
    -- local cyan = rgb("#8BE9FD")
    -- local green = rgb("#50FA7B")
    -- local orange = rgb("#FFB86C")
    -- local pink = rgb("#FF79C6")
    -- local purple = rgb("#BD93F9")
    -- local red = rgb("#FF5555")
    -- local yellow = rgb("#F1FA8C")

    local morsels = rgb("#191A21")
    local background = rgb("#282A36")
    local current = rgb("#44475A")
    local foreground = rgb("#F8F8F2")
    local comment = rgb("#6272A4")
    local roundness = 16

    imgui.PushStyleColor(imgui_col.WindowBg, morsels)
    imgui.PushStyleColor(imgui_col.Border, background)
    imgui.PushStyleColor(imgui_col.FrameBg, background)
    imgui.PushStyleColor(imgui_col.FrameBgHovered, current)
    imgui.PushStyleColor(imgui_col.FrameBgActive, current)
    imgui.PushStyleColor(imgui_col.TitleBg, background)
    imgui.PushStyleColor(imgui_col.TitleBgActive, current)
    imgui.PushStyleColor(imgui_col.TitleBgCollapsed, current)
    imgui.PushStyleColor(imgui_col.CheckMark, comment)
    imgui.PushStyleColor(imgui_col.SliderGrab, current)
    imgui.PushStyleColor(imgui_col.SliderGrabActive, comment)
    imgui.PushStyleColor(imgui_col.Button, current)
    imgui.PushStyleColor(imgui_col.ButtonHovered, comment)
    imgui.PushStyleColor(imgui_col.ButtonActive, comment)
    imgui.PushStyleColor(imgui_col.Tab, background)
    imgui.PushStyleColor(imgui_col.TabHovered, current)
    imgui.PushStyleColor(imgui_col.TabActive, current)
    imgui.PushStyleColor(imgui_col.Header, background)
    imgui.PushStyleColor(imgui_col.HeaderHovered, current)
    imgui.PushStyleColor(imgui_col.HeaderActive, current)
    imgui.PushStyleColor(imgui_col.Separator, background)
    imgui.PushStyleColor(imgui_col.Text, foreground)
    imgui.PushStyleColor(imgui_col.TextSelectedBg, comment)
    imgui.PushStyleColor(imgui_col.ScrollbarGrab, background)
    imgui.PushStyleColor(imgui_col.ScrollbarGrabHovered, current)
    imgui.PushStyleColor(imgui_col.ScrollbarGrabActive, current)
    imgui.PushStyleColor(imgui_col.PlotLines, current)
    imgui.PushStyleColor(imgui_col.PlotLinesHovered, comment)
    imgui.PushStyleColor(imgui_col.PlotHistogram, current)
    imgui.PushStyleColor(imgui_col.PlotHistogramHovered, comment)

    imgui.PushStyleVar( imgui_style_var.FrameBorderSize, 0)
    imgui.PushStyleVar( imgui_style_var.WindowPadding, { 8, 8 })
    imgui.PushStyleVar( imgui_style_var.FramePadding, { 8, 8 })
    imgui.PushStyleVar( imgui_style_var.ItemSpacing, { 8, 4 })
    imgui.PushStyleVar( imgui_style_var.ItemInnerSpacing, { 8, 8 })
    imgui.PushStyleVar( imgui_style_var.WindowRounding, roundness)
    imgui.PushStyleVar( imgui_style_var.ChildRounding, roundness)
    imgui.PushStyleVar( imgui_style_var.FrameRounding, roundness)
    imgui.PushStyleVar( imgui_style_var.GrabRounding, roundness)
    imgui.PushStyleVar( imgui_style_var.ScrollbarRounding, roundness)
    imgui.PushStyleVar( imgui_style_var.TabRounding, roundness)
end

-- Creates a separator with padding.
function Separator()
    imgui.Dummy({1, 1})
    imgui.Separator()
    imgui.Dummy({1, 1})
end

