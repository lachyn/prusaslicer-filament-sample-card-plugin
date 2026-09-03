info = {
    id = "generate_sample_card",
    type = "project.plugin",
    title = "Generate Filament Sample Card",
    menu = "Material Tools/Generate Sample Card",
    params = {
        {
            name = "manufacturer",
            label = "Manufacturer / Brand (max ~22 chars)",
            type = "string",
            default = "PRUSAMENT"
        },
        {
            name = "filament_name",
            label = "Filament Name / Color (max ~25 chars)",
            type = "string",
            default = "GALAXY BLACK"
        },
        {
            name = "material_type",
            label = "Material Type [PLA/PETG/ABS/...] (max 5-6 chars)",
            type = "string",
            default = "PLA"
        },
        {
            name = "engrave",
            label = "Engrave Text (Cut into card)",
            type = "bool",
            default = false
        }
    }
}

function execute(opts)
    -- 1. Load the clean blank sample card base model
    local base = nil
    local ok_base, loaded_base = pcall(function() return api.load_stl("assets/sample_card_blank.stl") end)
    if ok_base and loaded_base then
        base = loaded_base
    else
        base = api.load_stl("sample_card_blank.stl")
    end
    
    -- Request the thickest/boldest available font weight for high 3D print contrast
    local function get_thick_font()
        -- Unified candidate list across Linux, Windows, macOS
        local candidates = {
            "FreeSans bold",
            "FreeSans Bold",
            "Sans bold",
            "Sans Bold",
            "Arial Bold",
            "Arial-Bold",
            "Arial Black",
            "Helvetica Bold",
            "Helvetica-Bold",
            "Noto Sans bold",
            "Noto Sans heavy",
            "Liberation Sans bold",
            "DejaVu Sans bold",
            "Segoe UI Bold"
        }

        for _, name in ipairs(candidates) do
            local ok, font = pcall(function() return api.get_font(name) end)
            if ok and font then
                local font_name = nil
                pcall(function() font_name = font.name end)
                -- PrusaSlicer returns internal "Default font" when a query is not found
                if font_name and font_name ~= "Default font" then
                    return font
                end
            end
        end

        -- Direct fallback if font.name property was unavailable
        for _, name in ipairs(candidates) do
            local ok, font = pcall(function() return api.get_font(name) end)
            if ok and font then
                return font
            end
        end

        return api.get_default_font()
    end

    local thick_font = get_thick_font()
    local is_engrave = opts and opts.engrave
    local text_type = is_engrave and VolumeType.Negative or VolumeType.Solid

    local other_volumes = {}

    -- The PrusaSlicer api.emboss_text generates text meshes with a fixed extrusion thickness of 1.0 mm (Z: 0.0 to 1.0).
    -- Target visible text height / relief: exactly 0.5 mm in the Z axis.
    -- Card surface heights:
    --   - Upper label cavity floor is at Z = 1.0 mm (outer border rim is at Z = 2.2 mm).
    --   - Lower area floor is at Z = 1.2 mm.
    --
    -- For raised text (Solid):
    --   We sink the bottom of the 1.0 mm text mesh 0.5 mm below the floor:
    --   - Upper: translate Z = 1.0 - 0.5 = 0.5 mm -> mesh spans Z = 0.5 to 1.5 mm (exactly 0.5 mm above the 1.0 mm floor).
    --   - Lower: translate Z = 1.2 - 0.5 = 0.7 mm -> mesh spans Z = 0.7 to 1.7 mm (exactly 0.5 mm above the 1.2 mm floor).
    --
    -- For engraved text (Negative):
    --   We cut 0.5 mm into the card surface:
    --   - Upper: translate Z = 1.0 - 0.5 = 0.5 mm -> cuts into Z = [0.5, 1.0] mm (exactly 0.5 mm deep).
    --   - Lower: translate Z = 1.2 - 0.5 = 0.7 mm -> cuts into Z = [0.7, 1.2] mm (exactly 0.5 mm deep).
    local z_upper = 1.0 - 0.5
    local z_lower = 1.2 - 0.5

    -- Helper function to add left-aligned embossed/engraved text volume centered on target_y
    -- max_w: maximum allowable width in mm; if text exceeds max_w, line_height is scaled down automatically
    local function add_left_text(text_str, line_h, left_x, target_y, z_pos, max_w)
        if not text_str or tostring(text_str) == "" then
            return
        end

        local upper_text = string.upper(tostring(text_str))
        local text_mesh = api.emboss_text {
            font = thick_font,
            text = upper_text,
            line_height = line_h
        }

        local b = text_mesh:bounds()
        local text_w = (b and b.max_x and b.min_x) and (b.max_x - b.min_x) or 0

        -- Auto-fit: if text is wider than max_w, recalculate with scaled-down line height
        if max_w and text_w > max_w and text_w > 0 then
            local scale_factor = max_w / text_w
            local scaled_line_h = math.max(1.5, line_h * scale_factor)
            text_mesh = api.emboss_text {
                font = thick_font,
                text = upper_text,
                line_height = scaled_line_h
            }
            b = text_mesh:bounds()
        end

        local min_x_offset = (b and b.min_x) or 0
        local min_z_offset = (b and b.min_z) or 0
        -- Center the text mesh vertically around target_y
        local y_center = (b and b.min_y and b.max_y) and ((b.min_y + b.max_y) / 2.0) or 0

        table.insert(other_volumes, {
            mesh = text_mesh,
            type = text_type,
            translate = {
                x = left_x - min_x_offset,
                y = target_y - y_center,
                z = z_pos - min_z_offset
            }
        })
    end

    -- Available widths:
    -- Upper Pocket: from X = -72.0 to -9.0 -> max_w = 63.0 mm
    -- Lower Area (before sample window): from X = -72.0 to -43.0 -> max_w = 29.0 mm

    -- 2. Upper Pocket: Y range is 20.0 to 30.0 (Height = 10.0mm, Center Y = 25.0)
    -- Line 1: Manufacturer (centered at Y = 27.0, Line Height = 3.6mm, max width = 63mm)
    add_left_text(opts and opts.manufacturer, 3.6, -72.0, 27.0, z_upper, 63.0)

    -- Line 2: Filament Name (centered at Y = 23.0, Line Height = 3.2mm, max width = 63mm)
    add_left_text(opts and opts.filament_name, 3.2, -72.0, 23.0, z_upper, 63.0)

    -- 3. Lower Area: 5-step sample window Y range is 5.0 to 15.0 (Height = 10.0mm, Center Y = 10.0)
    -- Material Type (centered vertically at Y = 10.0, Line Height = 6.5mm, max width = 29mm)
    add_left_text((opts and opts.material_type) or "PLA", 6.5, -72.0, 10.0, z_lower, 29.0)

    -- 4. Add the combined sample card object to the active build plate
    api.project:add_object {
        mesh = base,
        other_volumes = other_volumes
    }
end
