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
    local base = api.load_stl("assets/sample_card_blank.stl")
    
    -- Request bold font weight for high readability when printed
    local font = api.get_font("Bold") or api.get_default_font()
    local text_type = opts.engrave and VolumeType.Negative or VolumeType.Solid

    local other_volumes = {}

    -- Z height offsets for the card surfaces:
    -- Upper label cavity floor is at Z = 1.0mm (outer border rim is at Z = 2.2mm)
    -- Lower info area floor is at Z = 1.2mm
    local z_upper = opts.engrave and 0.5 or 1.0
    local z_lower = opts.engrave and 0.6 or 1.2

    -- Helper function to add left-aligned embossed/engraved text volume
    local function add_left_aligned_text(text_str, line_h, left_x, y_pos, z_pos)
        if not text_str or text_str == "" then
            return
        end

        local text_mesh = api.emboss_text {
            font = font,
            text = string.upper(text_str),
            line_height = line_h
        }

        local b = text_mesh:bounds()
        local min_x_offset = (b and b.min_x) or 0

        other_volumes[#other_volumes + 1] = {
            mesh = text_mesh,
            type = text_type,
            translate = {
                x = left_x - min_x_offset,
                y = y_pos,
                z = z_pos
            }
        }
    end

    -- Helper function to add centered text in designated bounding range
    local function add_centered_text(text_str, line_h, center_x, y_pos, z_pos, max_w, fallback_x)
        if not text_str or text_str == "" then
            return
        end

        local text_mesh = api.emboss_text {
            font = font,
            text = string.upper(text_str),
            line_height = line_h
        }

        local b = text_mesh:bounds()
        local w = (b and b.max_x and b.min_x) and (b.max_x - b.min_x) or 0
        local min_x_offset = (b and b.min_x) or 0

        local x_pos
        if w > 0 and w <= max_w then
            x_pos = center_x - (w / 2.0) - min_x_offset
        else
            x_pos = fallback_x - min_x_offset
        end

        other_volumes[#other_volumes + 1] = {
            mesh = text_mesh,
            type = text_type,
            translate = {
                x = x_pos,
                y = y_pos,
                z = z_pos
            }
        }
    end

    -- 2. Line 1: Manufacturer (ALL CAPS, Left-Aligned, Line Height = 4.4mm)
    -- Positioned in the upper label cavity at X = -72.0, Y = 25.0
    add_left_aligned_text(opts.manufacturer, 4.4, -72.0, 25.0, z_upper)

    -- 3. Line 2: Filament Name (ALL CAPS, Left-Aligned, Line Height = 3.6mm)
    -- Positioned in the upper label cavity at X = -72.0, Y = 20.6
    add_left_aligned_text(opts.filament_name, 3.6, -72.0, 20.6, z_upper)

    -- 4. Material Type Badge (ALL CAPS, Consistent Font/Size = 3.6mm)
    -- Centered in the lower-left badge box at X = -66.0, Y = 7.2
    add_centered_text(opts.material_type or "PLA", 3.6, -66.0, 7.2, z_lower, 16.0, -73.0)

    -- 5. Add the combined sample card object to the active build plate
    api.project:add_object {
        mesh = base,
        other_volumes = other_volumes
    }
end
