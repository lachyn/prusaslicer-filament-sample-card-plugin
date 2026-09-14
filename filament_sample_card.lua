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
            name = "font_name",
            label = "Custom Font Name (blank = Auto-Bold)",
            type = "string",
            default = ""
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

-- Helper function to trim whitespace
local function trim(s)
    if not s then return "" end
    return (tostring(s):gsub("^%s*(.-)%s*$", "%1"))
end

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
            -- macOS / Windows heavy weights (highest 3D print contrast & thick stroke perimeters)
            "Arial Black",
            "Arial-Black",
            "Impact",
            "Segoe UI Black",
            "Arial Rounded MT Bold",
            "Trebuchet MS bold",
            "Trebuchet MS:style=Bold",
            "Trebuchet MS Bold",
            "Verdana bold",
            "Verdana:style=Bold",
            "Verdana Bold",
            "Segoe UI:style=Bold",
            "Segoe UI Bold",
            "Helvetica-Bold",
            "Helvetica Bold",
            "Arial-BoldMT",
            "Arial Bold",
            "Arial:style=Bold",
            "DIN Alternate Bold",
            "DINAlternate-Bold",
            "SF Pro Display Bold",
            "SF Pro Text Bold",
            -- Linux heavy weights
            "FreeSans:style=Bold",
            "FreeSans bold",
            "FreeSans Bold",
            "Liberation Sans:style=Bold",
            "Liberation Sans bold",
            "Liberation Sans Bold",
            "DejaVu Sans:style=Bold",
            "DejaVu Sans bold",
            "DejaVu Sans Bold",
            "Ubuntu:style=Bold",
            "Ubuntu Bold",
            "Noto Sans:style=Bold",
            "Noto Sans bold",
            "Noto Sans Bold",
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

        -- Check user-specified custom font first if provided
        if opts and opts.font_name and trim(opts.font_name) ~= "" then
            local user_cand = trim(opts.font_name)
            local ok_u, user_f = pcall(function() return api.get_font(user_cand) end)
            if ok_u and user_f then
                local fn = nil
                pcall(function() fn = user_f.name end)
                if not fn or not is_fallback(fn) then
                    return user_f
                end
            end
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
    -- Target visible text relief for raised text: 0.8 mm in Z (4 solid printed layers at 0.20 mm).
    -- Target engraved text depth: 0.5 mm in Z (cuts 0.5 mm into floor).
    -- Card surface heights:
    --   - Upper label cavity floor is at Z = 1.0 mm (outer border rim is at Z = 2.2 mm).
    --   - Lower area floor is at Z = 1.2 mm.
    --
    -- For raised text (Solid):
    --   - Upper: translate Z = 1.0 - 0.2 = 0.8 mm -> mesh spans Z = [0.8, 1.8] mm (0.8 mm relief, 0.4 mm below outer rim).
    --   - Lower: translate Z = 1.2 - 0.2 = 1.0 mm -> mesh spans Z = [1.0, 2.0] mm (0.8 mm relief, 0.2 mm below outer rim).
    --
    -- For engraved text (Negative):
    --   - Upper: translate Z = 1.0 - 0.5 = 0.5 mm -> cuts into Z = [0.5, 1.0] mm (0.5 mm deep into floor).
    --   - Lower: translate Z = 1.2 - 0.5 = 0.7 mm -> cuts into Z = [0.7, 1.2] mm (0.5 mm deep into floor).
    local z_upper = is_engrave and (1.0 - 0.5) or (1.0 - 0.2)
    local z_lower = is_engrave and (1.2 - 0.5) or (1.2 - 0.2)

    -- Helper function to add left-aligned embossed/engraved text volume centered on target_y
    local function add_left_text(text_str, line_h, left_x, target_y, z_pos)
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

    -- 2. Upper Pocket: Y range is 20.0 to 30.0 (Height = 10.0mm, Center Y = 25.0)
    local has_manufacturer = (trim(opts and opts.manufacturer) ~= "")
    local has_filament = (trim(opts and opts.filament_name) ~= "")

    if has_manufacturer and has_filament then
        -- Line 1: Manufacturer (centered at Y = 27.2, Line Height = 4.0mm)
        add_left_text(opts.manufacturer, 4.0, -72.0, 27.2, z_upper)
        -- Line 2: Filament Name (centered at Y = 22.8, Line Height = 3.8mm)
        add_left_text(opts.filament_name, 3.8, -72.0, 22.8, z_upper)
    elseif has_filament then
        -- Single-line layout for filament name (centered at Y = 25.0, Line Height = 5.2mm)
        add_left_text(opts.filament_name, 5.2, -72.0, 25.0, z_upper)
    elseif has_manufacturer then
        -- Single-line layout for brand name (centered at Y = 25.0, Line Height = 5.2mm)
        add_left_text(opts.manufacturer, 5.2, -72.0, 25.0, z_upper)
    end

    -- 3. Lower Area: 5-step sample window Y range is 5.0 to 15.0 (Height = 10.0mm, Center Y = 10.0)
    -- Material Type (centered vertically at Y = 10.0, Line Height = 6.5mm)
    add_left_text((opts and opts.material_type) or "PLA", 6.5, -72.0, 10.0, z_lower)

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
                    small_perimeter_speed = 15
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
