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
            name = "uppercase",
            label = "Convert Text to UPPERCASE",
            type = "bool",
            default = true
        },
        {
            name = "engrave",
            label = "Engrave Text (Cut into card)",
            type = "bool",
            default = false
        },
        {
            name = "optimize_print_params",
            label = "Optimize Print Settings for Swatch (100% infill, 1 perimeter, slow text)",
            type = "bool",
            default = true
        },
        {
            name = "text_extruder",
            label = "Text Extruder [0 = Default, 2, 3...] (MMU/Multi-color)",
            type = "int",
            default = 0
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
        local candidate_names = {
            -- macOS / Windows heavy weights
            "Arial Black",
            "Arial-Black",
            "Arial Rounded MT Bold",
            "Trebuchet MS bold",
            "Verdana bold",
            "Impact",
            "Helvetica-Bold",
            "Helvetica Bold",
            "Arial-BoldMT",
            "Arial Bold",
            "DIN Alternate Bold",
            "DINAlternate-Bold",
            "SF Pro Display Bold",
            "SF Pro Text Bold",
            -- Linux heavy weights
            "FreeSans bold",
            "FreeSans Bold",
            "Liberation Sans bold",
            "DejaVu Sans bold",
            "Noto Sans bold",
            "Noto Sans heavy",
            "Helvetica",
            "Arial"
        }

        local default_name = nil
        local ok_def, default_font = pcall(function() return api.get_default_font() end)
        if ok_def and default_font then
            pcall(function() default_name = default_font.name end)
        end

        local probe_name = nil
        local ok_probe, probe_font = pcall(function() return api.get_font("__nonexistent_probe_font__") end)
        if ok_probe and probe_font then
            pcall(function() probe_name = probe_font.name end)
        end

        local function is_fallback(fn)
            if not fn then return true end
            if fn == "NORMAL" or fn == "Default font" then return true end
            if default_name and fn == default_name then return true end
            if probe_name and fn == probe_name then return true end
            return false
        end

        -- 1. First pass: find a candidate that actually resolved and did not return the fallback font
        for _, name in ipairs(candidate_names) do
            local ok, font = pcall(function() return api.get_font(name) end)
            if ok and font then
                local fn = nil
                pcall(function() fn = font.name end)
                if fn and not is_fallback(fn) then
                    return font
                end
            end
        end

        -- 2. Safety pass: if font.name property was unavailable, return the first candidate directly
        for _, name in ipairs(candidate_names) do
            local ok, font = pcall(function() return api.get_font(name) end)
            if ok and font then
                return font
            end
        end

        return default_font or api.get_default_font()
    end

    local thick_font = get_thick_font()
    local is_engrave = opts and opts.engrave
    local is_uppercase = true
    if opts and opts.uppercase ~= nil then
        is_uppercase = opts.uppercase
    end
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

    -- Helper function to trim whitespace
    local function trim(s)
        if not s then return "" end
        return (tostring(s):gsub("^%s*(.-)%s*$", "%1"))
    end

    -- Helper function to add left-aligned embossed/engraved text volume centered on target_y
    -- max_w: maximum allowable width in mm; if text exceeds max_w, line_height is scaled down automatically
    local function add_left_text(text_str, line_h, left_x, target_y, z_pos, max_w)
        local cleaned = trim(text_str)
        if cleaned == "" then
            return
        end

        local final_text = is_uppercase and string.upper(cleaned) or cleaned
        local text_mesh = api.emboss_text {
            font = thick_font,
            text = final_text,
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
                text = final_text,
                line_height = scaled_line_h
            }
            b = text_mesh:bounds()
        end

        local min_x_offset = (b and b.min_x) or 0
        local min_z_offset = (b and b.min_z) or 0
        -- Center the text mesh vertically around target_y
        local y_center = (b and b.min_y and b.max_y) and ((b.min_y + b.max_y) / 2.0) or 0

        local vol = {
            mesh = text_mesh,
            type = text_type,
            translate = {
                x = left_x - min_x_offset,
                y = target_y - y_center,
                z = z_pos - min_z_offset
            }
        }

        -- Multi-material: assign text volume to specific extruder if requested
        if opts and opts.text_extruder and opts.text_extruder > 0 and text_type == VolumeType.Solid then
            vol.params = { extruder = opts.text_extruder }
        end

        table.insert(other_volumes, vol)
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

    -- 4. Apply optimized print parameters if requested
    if opts and opts.optimize_print_params ~= false then
        local ok_bed, bed = pcall(function() return api.project:current_bed() end)
        if ok_bed and bed then
            local ok_presets, presets = pcall(function() return bed:print_presets() end)
            if ok_presets and presets then
                local print_settings = {
                    fill_density = "100%",
                    top_one_perimeter_type = "top",
                    top_fill_pattern = "monotonic",
                    bottom_fill_pattern = "monotonic",
                    small_perimeter_speed = 25
                }
                for k, v in pairs(print_settings) do
                    pcall(function() presets:set(k, v) end)
                end

                -- only_one_perimeter_first_layer and gap_fill_enabled are NOT set here.
                -- Both are bool options and set_param's visitor handles only double, int,
                -- Percentage, FloatOrPercentage and Enum - bool falls into the catch-all
                -- and is silently ignored, whatever value form is passed ("1", 1, true and
                -- "true" all behave identically. The old retry loop was 16 no-op calls).
                -- They need a bool case added upstream in ProjectApi.cpp; until then tick
                -- them by hand in Print Settings.
            end
        end
    end

    -- 5. Add the combined sample card object to the active build plate
    -- Provide object-level parameter overrides if supported by the slicer
    local function try_add_object(extra_params)
        local opts_to_add = {
            mesh = base,
            other_volumes = other_volumes
        }
        if extra_params then
            opts_to_add.object_params = extra_params
        end
        return pcall(function() api.project:add_object(opts_to_add) end)
    end

    if opts and opts.optimize_print_params ~= false then
        -- NOTE: only_one_perimeter_first_layer must NOT be passed here. set_param has no
        -- bool branch, so the value is never written - but it still runs
        -- overrides.enable(name) afterwards. The option is overridable at Object level and
        -- defaults to false, so passing it activates an object-level override pinned to
        -- FALSE, which outranks the print preset and disables the setting for this object.
        local ok = try_add_object({
            fill_density = "100%"
        })
        if not ok then
            ok = try_add_object({
                fill_density = "100%"
            })
        end
        if not ok then
            ok = try_add_object({
                fill_density = "100%"
            })
        end
        if not ok then
            api.project:add_object {
                mesh = base,
                other_volumes = other_volumes
            }
        end
    else
        api.project:add_object {
            mesh = base,
            other_volumes = other_volumes
        }
    end
end
