# PrusaSlicer Filament Sample Card Generator

A Lua plugin for **PrusaSlicer 3** that procedurally generates customizable 3D filament sample swatch cards with stepped opacity test strips (0.2–1.0 mm) and embossed or engraved labels directly on the build plate.

---

## ✨ Features

- **In-Slicer Generation:** No external CAD or OpenSCAD required.
- **Customizable:** Manufacturer / Brand, Filament Name / Color, Material Type.
- **Relief Options:** Toggle between solid raised text (0.8 mm relief, 4 solid layers at 0.20 mm) and engraved cutouts (0.5 mm depth).
- **Cross-Platform Bold Typography & Custom Fonts:** Users can specify any font installed on their system (e.g. `Impact`, `Arial Black`, `DejaVu Sans Bold`), or leave blank to automatically cascade through the boldest available system fonts (`Arial Black`, `Impact` on macOS & Windows, `DejaVu Sans Bold` / `Liberation Sans bold` / `FreeSans bold` on Linux).
- **Crisp Text Sizing:** Emits text at full, uncompressed line heights for maximum clarity and perimeter fill without blurry downscaling.
- **Adaptive Pocket Layout:** Automatically formats dual-line labels (Brand: 4.0 mm, Filament: 3.8 mm) or expands single-line entries into large, centered text (5.2 mm line height).
- **Transmission Strips:** 5 calibrated thickness steps (0.2 to 1.0 mm) to inspect material opacity.
- **Automatic Swatch Slicing Optimizations:**
  - 100% solid infill (no internal grid pattern showing through translucent materials).
  - 1 perimeter on all top surfaces (`top_one_perimeter_type = "top"`) for clean, flat transmission steps.
  - Monotonic infill on top and bottom for smooth, consistent sheen.
  - Slower perimeter speed on small text (`small_perimeter_speed = 15 mm/s`) for crisp, precise letter edges.
- **Multi-Material / MMU Ready:** Optionally assign text to another extruder (`text_extruder`) for instant 2-color swatches.

---

## 📥 Installation

Symlink or copy this repository as `com.github.filament-sample-card` into your PrusaSlicer `lua` directory:

```bash
# macOS:
ln -s "$(pwd)" ~/Library/Application\ Support/PrusaSlicer3-dev/lua/com.github.filament-sample-card

# Linux (Flatpak):
ln -s "$(pwd)" ~/.var/app/com.prusa3d.PrusaSlicer/config/PrusaSlicer3-dev/lua/com.github.filament-sample-card

# Linux (Native):
ln -s "$(pwd)" ~/.config/PrusaSlicer3-dev/lua/com.github.filament-sample-card
```

### Plugin Directories by OS:
- **macOS:** `~/Library/Application Support/PrusaSlicer3-dev/lua/` *(or `.../PrusaSlicer/lua/`)*
- **Linux (Flatpak):** `~/.var/app/com.prusa3d.PrusaSlicer/config/PrusaSlicer3-dev/lua/` *(or `.../PrusaSlicer/lua/`)*
- **Linux (Native):** `~/.config/PrusaSlicer3-dev/lua/` *(or `~/.config/PrusaSlicer/lua/`)*
- **Windows:** `%APPDATA%\PrusaSlicer3-dev\lua\`

In PrusaSlicer, click **Plugins > Rescan Plugins** (or restart the application).

---

## 🚀 Usage

1. Go to **Plugins > Material Tools > Generate Sample Card**.
2. Configure parameters:
   - **Manufacturer / Brand:** e.g. `PRUSAMENT` (optional, leave blank for large single-line layout)
   - **Filament Name / Color:** e.g. `GALAXY BLACK`
   - **Material Type:** e.g. `PLA`
   - **Custom Font Name:** Optional. Specify any font installed on your system (e.g. `Impact`, `Arial Black`, `Segoe UI Bold`, `DejaVu Sans Bold`). Leave blank to automatically use the best bold font.
   - **Convert Text to UPPERCASE:** `true` (default) to force uniform all-caps, or `false` to preserve entered casing.
   - **Engrave Text:** `false` for raised text, `true` for engraved cutouts into card surface.
   - **Optimize Print Settings for Swatch:** `true` (recommended) to automatically configure 100% infill, single perimeter on steps/surfaces, and clean slow text speeds.
   - **Text Extruder:** `0` for single material, or `2, 3...` to automatically assign text to a second extruder on MMU / multi-tool printers.
3. Click **Run** — the optimized card will appear on the build plate, ready for slicing!

> [!TIP]
> **Tips for Crisp 3D Printed Text:**
> - **Font Selection:** Leave *Custom Font Name* blank to automatically use extra-heavy bold fonts (`Arial Black`, `Impact`), or enter any bold/black typeface installed on your OS.
> - **4-Layer Contrast:** Raised text extends $0.8\text{ mm}$ above the pocket floor, slicing into 4 solid layers at standard $0.20\text{ mm}$ layer height for rich, opaque contrast.
> - **Clean Perimeters:** Keep *Optimize Print Settings* enabled to automatically reduce small perimeter speed to $15\text{ mm/s}$ for sharp, crisp letter corners.

---

## 📜 Attribution & License

- Base 3D model adapted from [Filament samples - 42 materials](https://www.printables.com/model/228249-filament-samples-42-materials) by Seemomster ([CC BY 4.0](https://creativecommons.org/licenses/by/4.0/)).
- Plugin source code is licensed under the [MIT License](LICENSE).
