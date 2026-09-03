# PrusaSlicer Filament Sample Card Generator

A Lua plugin for **PrusaSlicer 3** that procedurally generates customizable 3D filament sample swatch cards with stepped opacity test strips (0.2–1.0 mm) and embossed or engraved labels directly on the build plate.

---

## ✨ Features

- **In-Slicer Generation:** No external CAD or OpenSCAD required.
- **Customizable:** Manufacturer / Brand, Filament Name / Color, Material Type.
- **Relief Options:** Toggle between solid raised text and engraved cutouts.
- **Auto-Fit & Bold Typography:** Dynamically scales long names; uses heavy bold fonts (FreeSans Bold on Linux) for sharp 3D legibility.
- **Transmission Strips:** 5 calibrated thickness steps (0.2 to 1.0 mm) to inspect material opacity.

---

## 📥 Installation

Symlink or copy this repository as `com.github.filament-sample-card` into your PrusaSlicer `lua` directory:

```bash
# Linux (Flatpak):
ln -s "$(pwd)" ~/.var/app/com.prusa3d.PrusaSlicer/config/PrusaSlicer3-dev/lua/com.github.filament-sample-card

# Linux (Native):
ln -s "$(pwd)" ~/.config/PrusaSlicer3-dev/lua/com.github.filament-sample-card
```

### Plugin Directories by OS:
- **Linux (Flatpak):** `~/.var/app/com.prusa3d.PrusaSlicer/config/PrusaSlicer3-dev/lua/` *(or `.../PrusaSlicer/lua/`)*
- **Linux (Native):** `~/.config/PrusaSlicer3-dev/lua/` *(or `~/.config/PrusaSlicer/lua/`)*
- **macOS:** `~/Library/Application Support/PrusaSlicer3-dev/lua/`
- **Windows:** `%APPDATA%\PrusaSlicer3-dev\lua\`

In PrusaSlicer, click **Plugins > Rescan Plugins** (or restart the application).

---

## 🚀 Usage

1. Go to **Plugins > Material Tools > Generate Sample Card**.
2. Enter your filament details and select **Engrave Text** (`false` = raised, `true` = engraved).
3. Click **Run** — the card will appear on the build plate, ready for slicing!

---

## 📜 Attribution & License

- Base 3D model adapted from [Filament samples - 42 materials](https://www.printables.com/model/228249-filament-samples-42-materials) by Seemomster ([CC BY 4.0](https://creativecommons.org/licenses/by/4.0/)).
- Plugin source code is licensed under the [MIT License](LICENSE).
