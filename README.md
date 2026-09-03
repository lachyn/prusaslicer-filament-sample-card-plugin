# PrusaSlicer Filament Sample Card Generator

A Lua plugin for **PrusaSlicer 3** that dynamically generates custom 3D filament sample cards with embossed or engraved labels and stepped opacity test strips directly on the build plate.

---

## ✨ Features

- **In-Slicer Customization:** No need for external CAD or OpenSCAD. Generate custom labeled cards directly within PrusaSlicer.
- **Configurable Fields:**
  - **Manufacturer / Brand** (e.g. `PRUSAMENT`, `POLYMAKER`, `BAMBU LAB`)
  - **Filament Name / Color** (e.g. `GALAXY BLACK`, `MATTE CHARCOAL`)
  - **Material Type** (e.g. `PLA`, `PETG`, `TPU`, `ABS`, `ASA`, `PC`, `NYLON`)
- **Clean Typography:**
  - Automatic uppercase formatting.
  - Left-aligned layout for brand and filament name.
  - Bold weight with optimized line heights for sharp 3D print readability with 0.4mm and 0.25mm nozzles.
- **5-Step Light Transmission Strips:** Includes 0.2 mm, 0.4 mm, 0.6 mm, 0.8 mm, and 1.0 mm steps to test material opacity and translucency.
- **Raised or Engraved:** Option to toggle between solid raised text (flush with the card's outer rim) and engraved text (cut into the card).

---

## 📥 Installation

### Method 1: Development / Unpacked Bundle (Quickest)

1. Clone or download this repository.
2. Open **PrusaSlicer 3** (Alpha / Development build).
3. In the top menu, select **Plugins > Show User Plugins Folder**.
   *(Alternatively, copy this repository folder into your PrusaSlicer `lua/` folder manually — see paths below).*
4. Place this folder into the `lua/` directory as `com.github.filament-sample-card`.
5. In PrusaSlicer, click **Plugins > Rescan Plugins**.

#### PrusaSlicer Plugin Directories by OS:
* **macOS:** `~/Library/Application Support/PrusaSlicer3-dev/lua/` (or `~/Library/Application Support/PrusaSlicer/lua/`)
* **Linux:** `~/.config/PrusaSlicer3-dev/lua/` (or `~/.config/PrusaSlicer/lua/`)
* **Windows:** `%APPDATA%\PrusaSlicer3-dev\lua\` (or `%APPDATA%\PrusaSlicer\lua\`)

---

## 🚀 Usage

1. Open PrusaSlicer 3.
2. Navigate to **Plugins > Material Tools > Generate Sample Card**.
3. Fill in your filament details:
   - **Manufacturer / Brand:** `PRUSAMENT`
   - **Filament Name / Color:** `GALAXY BLACK`
   - **Material Type:** `PLA`
   - **Engrave Text:** `false` (Unchecked = Raised text; Checked = Engraved text)
4. Click **Run**.
5. The completed sample card will appear centered on your active build plate, ready for slicing!

---

## 📂 Bundle Structure

```text
com.github.filament-sample-card/
├── manifest.json              # Plugin manifest and metadata
├── filament_sample_card.lua   # Main Lua execution script
├── README.md                  # Documentation
├── LICENSE                    # MIT & CC-BY License
└── assets/
    └── sample_card_blank.stl  # Clean base sample card model
```

---

## 📜 Attribution & Credits

The 3D sample card base geometry is adapted from:
* **[Filament samples - 42 materials](https://www.printables.com/model/228249-filament-samples-42-materials)** by **Seemomster** on Printables.
* Original design is a remix of **"Filament sample with box"** by **Zahg**.
* Licensed under **Creative Commons Attribution 4.0 International (CC BY 4.0)**.

---

## 📄 License

* Plugin source code (`.lua`, `manifest.json`) is released under the **[MIT License](LICENSE)**.
* Base 3D model asset (`assets/sample_card_blank.stl`) is licensed under **[CC BY 4.0](https://creativecommons.org/licenses/by/4.0/)**.
