info = {
    id = "generate_sample_card",
    type = "project.plugin",
    title = "Generate Filament Sample Card",
    menu = "Material Tools/Generate Sample Card",
    params = {
        {
            name = "manufacturer",
            label = "Manufacturer / Brand",
            type = "string",
            default = "PRUSAMENT"
        },
        {
            name = "filament_name",
            label = "Filament Name / Color",
            type = "string",
            default = "GALAXY BLACK"
        },
        {
            name = "material_type",
            label = "Material Type (e.g. PLA, PETG, TPU, ABS)",
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
        local candidate_names = {
            "Arial Black",
            "Arial-Black",
            "Impact",
            "Helvetica-Bold",
            "Helvetica Bold",
            "Arial-BoldMT",
            "Arial Bold",
            "DIN Alternate Bold",
            "DINAlternate-Bold",
            "SF Pro Display Bold",
            "SF Pro Text Bold",
            "Helvetica",
            "Arial"
        }
        for _, name in ipairs(candidate_names) do
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

    -- Text height in Z axis (exactly 0.5 mm)
    local text_depth = 0.5

    -- Z height offsets for the card surfaces:
    -- Upper label cavity floor is at Z = 1.0mm (outer border rim is at Z = 2.2mm)
    -- Lower info area floor is at Z = 1.2mm
    local z_upper = is_engrave and (1.0 - text_depth) or 1.0
    local z_lower = is_engrave and (1.2 - text_depth) or 1.2

    -- Helper function to add left-aligned embossed/engraved text volume
    local function add_left_text(text_str, line_h, left_x, y_pos, z_pos)
        if not text_str or tostring(text_str) == "" then
            return
        end

        local text_mesh = api.emboss_text {
            font = thick_font,
            text = string.upper(tostring(text_str)),
            line_height = line_h,
            depth = text_depth
        }

        local b = text_mesh:bounds()
        local min_x_offset = (b and b.min_x) or 0

        table.insert(other_volumes, {
            mesh = text_mesh,
            type = text_type,
            translate = {
                x = left_x - min_x_offset,
                y = y_pos,
                z = z_pos
            }
        })
    end

    -- 2. Line 1: Manufacturer (ALL CAPS, Left-aligned at X = -72.0, Y = 25.0, Line Height = 4.2mm)
    add_left_text(opts and opts.manufacturer, 4.2, -72.0, 25.0, z_upper)

    -- 3. Line 2: Filament Name (ALL CAPS, Left-aligned at X = -72.0, Y = 20.8, Line Height = 3.4mm)
    add_left_text(opts and opts.filament_name, 3.4, -72.0, 20.8, z_upper)

    -- 4. Line 3: Material Type (ALL CAPS, Left-aligned at X = -72.0, Y = 6.2, Line Height = 7.0mm)
    -- Aligned left with upper text and centered vertically with the 5-step test frame on its right (Y: 5.0 to 15.0)
    add_left_text((opts and opts.material_type) or "PLA", 7.0, -72.0, 6.2, z_lower)

    -- 5. Add the combined sample card object to the active build plate
    api.project:add_object {
        mesh = base,
        other_volumes = other_volumes
    }
end
