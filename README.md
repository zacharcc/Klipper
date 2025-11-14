<p align="center" width="100%">
<img align="center" width="1024px" alt="About the Sandworm and Fremen" title="👁 The desert whispers. Step as the Fremen step . . . Flow like the dunes, silent and unseen. Only then will the Sandworm ignore your call." src="images/The_Fremen_said.png"><br>
</p>

<details> <summary>About the Sandworm (Click to view Fremen plain text ☰)</summary>
<br>
<p align="center" width="100%"><i><strong>(*Sandworm in Galach language of the Imperium, read: [Sændʉwo:ɹm])</strong></i><br></p>
 
<i>"He who controls the Sandworms, controls the rhythm of Arrakis."<br>
— Ancient Fremen Proverb</i><br>

◊ The **Sandworms** — the great **Shai-Hulud** — are not merely creatures of Arrakis.<br> 
&nbsp;&nbsp; They are revered, honored, and feared by the Fremen. Drawn by the subtlest tremors,<br> 
&nbsp;&nbsp; the deepest beats hidden in the sands, they awaken and come.<br>

◊ In your journey to tame and install the perfect **vibrations** that attract the true spirit of **Shai-Hulud**,<br> 
&nbsp;&nbsp; follow this guide carefully. Each step of this README.md will lead you closer <br> 
&nbsp;&nbsp; to aligning your machine’s heart with the timeless rhythms of the desert.<br>

◊ Prepare yourself. The Sandworm hears... and answers.

</details>

<br>

# Sandworm 3D Printer - Klipper Macros

```
Author: Zachar Čuřík
Launch Date: Q4 2025
Code Name: Sandworm Nov1 Y2025 GS556
Version: game_save=556, level=03, game_over="unknown"
Project by: Urobotos Coding
```

<br>

> [!NOTE]
> These **Klipper macros** are part of the setup instructions for the **Sandworm 3D printer**,  
> continued on [**Printables.com/Sandworm**](https://www.printables.com/model/976901-sandworm-3d-printer),  
> where you can also find all **3D printable parts and detailed build guides** for this printer.

<br>

### 📂 Copy & Paste Config Files (Manual alternative):
- If you prefer a manual install, copy all contents from the `Sandworm/config` folder into your printer’s configuration directory:
  - Example path: `home/biqu/printer_data/config/`
  - Choose Yes if prompted to overwrite default `printer.cfg`.

- Restart your printer to launch **Sandworm** for the first time. Then follow the rest of this README to complete the setup.
 
<br>

### ♻️ Automatic Install & Updates for Sandworm Configuration (Automatic alternative):
To install and enable automatic updates of Sandworm configuration macros, run the following command in an SSH terminal:
```
git clone https://github.com/Urobotos/Sandworm.git ~/Sandworm && bash ~/Sandworm/install.sh
```
<p align="left" width="100%">
<img align="left" width="165px" src="images/git_clone_cmd.png">
<img align="right" width="175px" src="https://github.com/Urobotos/Sandworm/actions/workflows/validate-install.yml/badge.svg"><br><br>
⮜⮜ <b>Optional:</b> SSH command in QR code (For reference or sharing).<br><br><br><br><br>
</p>

**This command will:** 
- Clone the Sandworm repository into the `~/Sandworm` folder. <br>
- Run the installation script `install.sh`, which: <br>
   - Creates a backup of your current configuration at: `~/Sandworm/backup/backup_config_date+time/`
   - Copies new macro files from: `~/Sandworm/config/` to your printer’s config directory: `~/printer_data/config/`
   - Adds `[update_manager Sandworm]` config block to: `moonraker.conf`
   - Adds `[power printer]` config block to: `moonraker.conf`
   - Creates a Git post-merge script at: `~/Sandworm/.git/hooks/post-merge` to enable future automatic updates.
   - Sets the introductory message and selected language in the `variables.cfg` file.
   - Restarts Moonraker to apply changes.

After this initial setup, future updates can be managed via the **Update Manager** in Mainsail/Fluidd. <br>
Just like the initial installation, each update automatically backs up your entire `~/printer_data/config/` before applying any changes. <br><br>

**❌🗑️ To uninstall Sandworm macros:** <br>
To completely uninstall Sandworm from your printer and restore previous settings, run the following command in an SSH terminal:
```
bash ~/Sandworm/uninstall.sh
```
**This uninstall command will:** 
- Restores backed up configuration files.
- Removes Sandworm from `moonraker.conf`
- Creates a `~Sandworm_backups` preserve folder and stores your existing macro backups into it.
- Deletes the `~/Sandworm` folder.

<br>

### 🔌 Remote Power Control via Relay:
> **Note:** If you have used the `♻️ Automatic installer` via command line, you **do not need** to manually add the `[power printer]` block below (It has already been installed into your `moonraker.conf`).<br>
> • In that case, you can skip this section and continue with the rest of the setup.

To enable relay-based power control, add the following to your `moonraker.conf` file:<br>

```
[power printer]
type: gpio
pin: gpiochip0/gpio72               # Can be reversed with "!", (Bigtreetech PI V1.2 GPIO pin PC8)
initial_state: off
off_when_shutdown: True             # Turn off power on shutdown/error
locked_while_printing: True         # Prevent power-off during a print
restart_klipper_when_powered: True
restart_delay: 1
bound_service: klipper              # Ensures Klipper service starts/restarts with power toggle
```
**User management of printer ON-OFF:**
The printer power ON/OFF itself is controlled via the Mainsail interface. <br>
The included **Auto Power Off** macro serves as a safe temperature shutdown of the printer at the end of printing, <br>
It is controlled using two macro buttons: `ACTIVATE_POWER_OFF` and `DEACTIVATE_POWER_OFF` during printing, <br> 
or by direct writing `ACTIVATE_POWER_OFF` to `end_gcode`. <br>
(The power off buttons will be set up later in this guide, along with the other macro buttons).

> **Note:** A complete setup guide with multiple wiring options for **auto power off** macros <br>
> can be found on `Tinntbg's` Github repository: [Auto Power Off Klipper](https://github.com/tinntbg/auto-power-off-klipper) <br>

<br>

### 🎞️ Filament Runout Sensor & `runout_distance` Macro:
- **Description**: A configurable distance delay before `PAUSE` is triggered when the filament sensor is activated.
- **Purpose**: Saves filament by allowing extra material to be used before pausing.
- **Setup Instructions**: Measure your PTFE tube length (From filament sensor to extruder gear, <br>
    include a ~100mm buffer for manual filament removal from extruder gear).<br>
  
- **To set the measured value (Two option):**
  - **In the LCD menu:** `Menu → Setup → Filament sens. → Where you can choose:`
      - **Extension:** `ON/OFF`  
          Where ON = Pause with extension, OFF = Pause will be performed immediately when the Filament Runout is triggered.
      - **Distance:** `930`mm — Adjust `Distance` to: `Your_measured_value_in_mm` <br>
          (Default 930mm, adjustment 10 mm per step, with auto-save function on select).
         
  - **Or directly by editing the variables.cfg file:**  
      - In `variablas.cfg → runout_distance = 930`, change `930` to: Your measured value in mm.

<br>

- The macro contains a **Countdown** in mm for the LCD display and a **Progress Bar** (every 20%) for the Mainsail console:
<p align="center" width="100%">
    <img width="47%" src="images/lcd_countdown.jpg">
    <img width="47%" src="images/progress_bar2.jpg">
</p>
<br>

### 🌐 Language Selection:
> **Note:** If you have used the `♻️ Automatic installer`, the language was **already set** during the initial setup.<br>
> • If you want to change the language manually later, use the options below:

The LCD menu and user-defined macros support multiple languages (not included in Klipper native macros).<br>
To change the language (Two option):
- **In the LCD Menu**: `Menu → Setup → Language → Choose: English, Cestina, Deutsch`
   
- **Or in the Mainsail console using a g-code macro:**
   - **English:**
     ```
     SET_MENU_LANGUAGE LANGUAGE=1
     ```
   - **Czech:**
     ```
     SET_MENU_LANGUAGE LANGUAGE=2
     ```
   - **German:**
     ```
     SET_MENU_LANGUAGE LANGUAGE=3
     ```
<br>

### 🖱️ Custom Macro Buttons in Mainsail:
**To add buttons, in the web interface, select:** `⚙️ Settings` → `<> Macros` → `Add a group:` <br>
Choose group name (For example, Movement), enter the group, and then search for the names below in the macro list.

- **Control (Hidden during prints)**:
  - `Park_Toolhead`
  - `steppers_off`
  - `FAKE_POSITION`

- **Filament (Hidden during prints)**:
  - `FILAMENT_LOAD`  *(Customizable temperature button, default: 200°C for PLA)*
  - `FILAMENT_UNLOAD` *(Customizable temperature button, default: 200°C for PLA)*
  - `M600`
  - `Nozzle_Clean` *(Uses brush)*
  - `e_stepper_off`

- **Chamber Lights (Always visible)**:
  - `lights_ON_OFF` *(Toggle ON/OFF button based on previous state)*
  - `lights_max` *(Sets the chamber lighting to maximum brightness)*
  - `Extruder_LED_ON_OFF` *(Toggle ON/OFF button based on previous state)*
  - `Display_LED_ON_OFF` *(Toggle ON/OFF button based on previous state)*

- **Calibration (Hidden during prints & pauses)**:
  - `Z_ENDSTOP_CALIBRATE_01`
  - `BL_TOUCH_CALIBRATE_02`
  - `Z_TILT_ADJUST_03`
  - `BED_MESH_CALIBRATE_04`

- **Print adjustment (Hidden during standby/ready)**:
  - `ACTIVATE_POWER_OFF`
  - `DEACTIVATE_POWER_OFF`
  - `SET_PAUSE_AT_LAYER`
  - `SET_PAUSE_NEXT_LAYER`

<br>

### 🏁 PrusaSlicer - START & END G-codes:
In **PrusaSlicer**, insert the following G-code snippets into the `Start G-codes` and `End G-codes` sections: <br>
(Settings for other Slicers can be found directly in the `start_end_gcodes.cfg` file)

#### 🟢 Start G-codes:
```gcode
SET_PRINT_STATS_INFO TOTAL_LAYER=[total_layer_count]
print_msg_info SETTINGS="[print_settings_id]" FILAMENT=[filament_type] EXT_TMP=[temperature] BED_TMP=[bed_temperature] CHAMBER_MIN_TMP=[chamber_minimal_temperature]
start_gcode BED_TMP=[first_layer_bed_temperature] EXT_TMP=[first_layer_temperature] CHAMBER_COOLING=[chamber_temperature] CHAMBER_MIN_TMP=[chamber_minimal_temperature]
```

#### 🔴 End G-codes:
```gcode
end_gcode
```

#### About `CHAMBER_TMP` and `CHAMBER_MIN_TMP` Parameters:
These two parameters are also set using **PrusaSlicer**:
- **`CHAMBER_TMP:`** Sets the automatic chamber temperature at which the **Cooling/Filtration Exhaust fans** activate (useful for heat-sensitive filaments like PLA).
- **`CHAMBER_MIN_TMP:`** Ensures the chamber temperature is above a minimum threshold before starting the print. If the temperature is too low, the printer **pauses** and uses the **heated bed at 100°C** to warm the chamber until it reaches the required value (especially useful for filaments prone to warping, such as ABS, PETG, etc.).

**Where to find these parameters for editing in PrusaSlicer:**
- **For automatic cooling/filtration:** `Filament Profile → Temperature → Chamber → Nominal: YOUR_VALUE °C`
- **To preheat the chamber before printing:** `Filament Profile → Temperature → Chamber → Minimum: YOUR_VALUE °C`

>📌 **Tip:** You can set different values for different filaments or completely disable temperature automation for a specific filament by `0`
<br>

> [!NOTE]
> **Sandworm uses a PTC heater (230V, 300W, with fan) to heat the chamber:** <br>
> Always set the minimum chamber temperature (via `M191`) with respect to the type of heater and the materials used inside the chamber.
> When using passive heating via the bed, some temperatures may be unreachable — in contrast, the **PTC heater** can reliably reach up to 50–60 °C.
> For safety, the macro enforces a maximum **limit of 60 °C**, especially to protect PETG parts located inside the printer.<br>
> **Example of chamber temperatures on Sandworm printer:** <br>
> 
> **After ~1 hour of printing (only Bed heating):**
> - Bed: 60°C | Ambient: 25°C | Chamber: 41°C
> - Bed: 95°C | Ambient: 20°C | Chamber: 46°C
> - Bed: 50°C | Ambient: 12°C | Chamber: 28°C
>
> **PTC chamber heater, heating power (With Bed heating at 90°C):**
> - Chamber: 18°C | Minute: 00
> - Chamber: 30°C | Minute: 01
> - Chamber: 40°C | Minute: 05
> - Chamber: 45°C | Minute: 10
> - Chamber: 50°C | Minute: 18

<br>

### 📡 Proximity Inductive Probe SN-04 PNP and Z Homing:
This section briefly explains how Z-homing works on the Sandworm printer, as it slightly differs from typical setups due to the use of a bed-mounted proximity sensor that directly detects (from below) the metal nozzle.

**In default on Sandworm:** <br>
- Z-homing is automated on the printer by `G28.1 rename` macro. <br>
- You don’t need to manually clean the nozzle or worry about filament residue. But if necessary, you can use the built-in brush on the bed to clean the nozzle, using the `Nozzle_Clean` macro.
- **Just slice and print** — the printer, combined with Proximity and BL-Touch probes, handles everything behind the scenes, such as:
    - Check if the nozzle is preheated for the proximity Z-homing.
    - Adjusting the bed tilt (`Z_TILT_ADJUST`)
    - Taking an impression of the bed surface (`BED_MESH_CALIBRATE`) <br>
    
&nbsp;&nbsp;&nbsp;<i>— All points together will lead to the creation of a perfect first layer.</i> <br>

**Differences from standard printer setups:** <br>
If you're performing manual Z-homing, it's a good idea to preheat the nozzle first.
Preheating softens any filament residue (after a print, for example), allowing it to deform harmlessly when it contacts the probe — resulting in clean and accurate homing. <br>

- To prevent this, the Sandworm printer automatically preheats the nozzle when any `G28 Z` homing is called.

**Fallback mode without preheating Z-homing:** <br>
If you still need homing with a cold nozzle (e.g. due to a thermistor error), use `G28 Z` with the `SKIP=1` parameter,<br>
for example: `G28 SKIP=1`, `G28 Z SKIP=1`, etc...
  
**Technical Details: SN-04 Probe Behavior:** <br>
The SN-04 inductive probe detects the brass nozzle at approximately Z ≈ 0.6 – 0.7 mm above the PEI bed surface.
- The nozzle tip sits about 1 mm away from the probe’s recessed sensing face.
- Using non-brass nozzles (e.g., carbide or hardened steel) may cause the probe to trigger slightly earlier (further away from the bed),
due to differing electromagnetic properties — this may affect the trigger height and require a Z offset recalibration.
- Height sensing using a proximity probe is for orientation purposes for non-printing movements (3D-Touch is used to sense precise height for printing). <br><br>

### ♘ Sandworm (Non-Print) Movements:
The Sandworm printer in the macros uses a **Chess Knight Movement Style** for non-printing movements (no diagonal movements), 
which is optimal for Core XY printers and in which both core XY motors are engaged and produces less noise.<br><br>


### 💡 RGB Lights Adjustment and SET_LED rename Macro:
The Sandworm printer brings a custom-made `SET_LED rename` macro, its main advantage is:<br>
Persistent SAVING of all configured lights, ensuring that their states are restored after a printer restart.<br>

The `SET_LED rename` macro introduces also a new RGB(W) memory feature:<br>
You can adjust the R, G, B, (W) values for a specific neopixel light individually, without resetting the other colors.<br>

*You can skip saving LED states by calling `SET_LED` with parameter `SKIP=1`* <br><br>

### ✂️ A modified `mainsail.cfg` file called `mainsail_custom.cfg` is used:
The Sandworm printer uses a modified `mainsail.cfg` file called `mainsail_custom.cfg`, the redirected include is listed in `printer.cfg`, so no manual edits are needed. This is provided for information only.

**Modifications include:**
- **Fan Control**: The part cooling fan turns off during `PAUSE` and then resumes to its previous speed when `RESUME` is triggered.<br>
   - Benefit: The fan does not run unnecessarily during a pause, which can be extended when using a filament sensor for runout detection.<br>

- **Nozzle Priming After Pause**: The `point_unretract` macro is executed when printing resumes after a pause.<br>
   - How it works: The print head returns to the paused position and performs a small filament extrusion to refill the nozzle.<br>
   - Benefit: Prevents gaps in the print caused by filament leakage during the pause.<br><br>


### 📜 A List (Tree) of All Macro Names:
With a short description can be found here: [Tree of Macros.md](./Tree_of_Macros.md)<br><br>


### Others:
### 🛠️ Klipper Adaptive Meshing Purging (KAMP):
A great feature by `Kyleisah` to calibrate only the printed area: [Klipper Adaptive Meshing Purging](https://github.com/kyleisah/Klipper-Adaptive-Meshing-Purging)

### 🤝 Contributing
Contributions are welcome! If you'd like to contribute, follow the [CONTRIBUTING.md](./CONTRIBUTING.md) guidelines.<br><br><br>

<hr>

### That's it, your journey has come to an end!
<p align="left" width="100%"><img align="left" width="20px" src="images/victory_emoji.png">
Thank you for your patience and for following the guide up to this point. And remember, in the Urobotos lair,<br>
every ending is the beginning of a whole new journey... enjoy printing, the game has begun!<br><br></p>

<p align="center" width="100%">
    <img width="35%" src="images/Urobotos_BPixelArt.png">
</p>


