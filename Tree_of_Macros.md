
### Jump Navigation:

- 📜 [macros.cfg](#-macroscfg)
- 💡 [lights_chamber.cfg](#-lights_chambercfg)
- 🌪️ [fans_and_chamber_heating.cfg](#%EF%B8%8F-fans_and_chamber_heatingcfg)
- ⚙️ [mainsail_custom.cfg](#%EF%B8%8F-mainsail_customcfg)
- 🚦 [start_end_gcodes.cfg](#-start_end_gcodescfg)
- 📭 [messages_on_startup.cfg](#-messages_on_startupcfg)
- 🖥️ [display.cfg](#%EF%B8%8F-displaycfg)
- 📱 [display.cfg - Offer structure (English version only):](#-displaycfg---offer-structure-english-version-only)

	
### 📜 macros.cfg:
	
  - **[Z_ENDSTOP_CALIBRATE_01]** <br>
    *Z Endstop Calibrate for Mainsail macro button.*
	
  - **[BL-TOUCH_CALIBRATE_02]** <br>
    *Probe Calibrate for Mainsail macro button.*

  - **[Z_TILT_ADJUST_03]** <br>
    *Z Tilt Adjust for Mainsail macro button.*

  - **[BED_MESH_CALIBRATE_04]** <br>
    *Bed Mesh Calibrate for Mainsail macro button.*

  - **[gcode_macro G28]** and **[delayed_gcode temp_homing]** <br>
    *G28 Rename - Z Homing with preheated nozzle*  
    *(With quick execution when temperature is reached).*
    
  - **[runout_distance]** and **[delayed_gcode runout_check]** <br>
    *Filament Runout Distance.* 
  
  - **[M600]** <br> 
    *Filament Change.*
  
  - **[FILAMENT_LOAD]** <br>
    *Filament Load 100mm.*
  
  - **[FILAMENT_UNLOAD]** <br>
    *Filament Unload 100mm.*
  
  - **[Nozzle_Clean]** <br>
    *Wipe nozzle by brush.* 

  - **[Quick_Nozzle_Clean]** <br>
    *Quick nozzle clean with a brush (for start print bed mesh procedures)* 

  - **[FAKE_POSITION]** <br>
    *Set Fake position: X100 Y100 Z100.*
	
  - **[steppers_off]** <br>
    *All steppers OFF.*
  
  - **[e_stepper_off]** <br>
    *E Stepper OFF.*
  
  - **[Park_Toolhead]** <br>
    *Park Toolhead.*

  - **[idle_timeout]** <br>
    *Turns off steppers, heaters etc. after 8 minutes of inactivity.*
	
  - **[ACTIVATE_POWER_OFF], [DEACTIVATE_POWER_OFF], [POWER_OFF_PRINTER_CHECK_ACT] and [_POWER_OFF_PRINTER]** <br>
    *To turn OFF the printer at the end of printing.*

    
### 💡 lights_chamber.cfg:

  - **[delayed_gcode restore_lights_onstartup]** <br>
    *Chamber lights, Extruder LEDs and LCD Display:*<br>
    *Restores saved lights settings on printer start / restart.*

  - **[SET_LED]** <br>
    *SET_LED rename to SET_SAVE_LED - Persistent saving of all configured lights, ensuring that their states are restored after a printer restart.*

  - **[SET_LED_BLINK]** <br>
    *Makro helper for Led blinks.*   
	
  - **[lights_max]** <br>
    *Chamber lights on Maximum.*
	
  - **[lights_ON_OFF], [lights_on], [lights_off]**  <br>
    *Chamber Lights ON/OFF (Toggle macro button).*
		
  - **[Extruder_LED_ON_OFF], [nozzle_led_on], [nozzle_led_off]** <br>
    *Extruder nozzle LEDs ON/OFF (Toggle macro button).*	

  - **[Display_LED_ON_OFF], [display_on], [display_off]** <br>
    *Display backlight ON/OFF (Toggle macro button).*


### 🌪️ fans_and_chamber_heating.cfg:

  - **[M141]** <br>
    *Target chamber temperature for automatic Cooling/Filtering.*

  - **[M191]** <br>
    *Wait until the chamber has warmed up to the minimum temperature.*
	

### ⚙️ mainsail_custom.cfg:

  - **[point_unretract]** <br>
    *The final mini fill nozzle when toolhead is back to the print pause point.*

  - #### Defined macros by Mainsail:
    - **[_CLIENT_VARIABLE]** <br>
      *List of user-defined variables.*
	  
    - **[CANCEL_PRINT]** <br>
      *Cancel the actual running print.*
	  
    - **[PAUSE]** <br>
      *Pause the actual running print.*
	  
    - **[RESUME]** <br>
      Resume the actual running print.*
	  
    - **[SET_PAUSE_NEXT_LAYER]** <br>
      *Enable a pause if the next layer is reached.*
	  
    - **[SET_PAUSE_AT_LAYER]** <br>
      *Enable/disable a pause if a given layer number is reached.*
	  
    - **[SET_PRINT_STATS_INFO]** <br>

    - **[_TOOLHEAD_PARK_PAUSE_CANCEL]** <br>
      *Helper: park toolhead used in PAUSE and CANCEL_PRINT.*

    - **[_CLIENT_EXTRUDE]** <br>
      *Extrudes, if the extruder is hot enough.*

    - **[_CLIENT_RETRACT]** <br>
      *Retracts, if the extruder is hot enough.*

    - **[_CLIENT_LINEAR_MOVE]** <br>
      *Linear move with save and restore of the gcode state.*


### 🚦 start_end_gcodes.cfg:
  - **[print_msg_info]** <br>
    *Print start info message: Print Settings, Filament, Extruder temp, Bed temp and Chamber temp* <br>
  - **[start_gcode]** <br>
  - **[end_gcode]** <br>

### 📭 messages_on_startup.cfg:

  - **[delayed_gcode lcd_message]** <br> 
    *LCD message on printer startup.*

  - **[delayed_gcode clear_display]** <br> 
    *Message showed on empty LCD (for auto-clear LCD display, with 25sec delay).*

  - **[delayed_gcode update_message]** <br>
    *Post-install/update message (run once).*


### 🖥️ display.cfg:

  - **[M300]** <br>
    *M300 gcode for LCD Beeper.*
	
  - **[alert_beep]** <br>
    *Macro tone for alert beep.*

  - **[SET_MENU_LANGUAGE]** <br>
    *To change the language using the LCD menu*.

  - **[knob_feedback]** and **[delayed_gcode knob_return]** <br>
    *Knob LED feedback when gcode macro is triggered via LCD menu.*

### 📱 display.cfg - Offer structure (English version):

 + **Content:**
   + **Adjust print:**
       + Ex0:000 (0000)
       + Bed:000 (0000)
       + Speed: 000%
       + Flow: 000%
       + Offset Z:00.00
       + Fan speed
   + **SD print:**
       + Start printing
       + Resume printing            
       + Pause printing             
       + Cancel printing            
       + ... (files)
   + **Control:**
       + Move XYZ,E
         + Move 10mm
             + Move X:000.0
             + Move Y:000.0
             + Move Z:000.0
             + Move E:+000.0
         + Move 1mm
             + Move X:000.0
             + Move Y:000.0
             + Move Z:000.0
             + Move E:+000.0
         + Move 0.1mm
             + Move X:000.0
             + Move Y:000.0
             + Move Z:000.0
             + Move E:+000.0
       + Home All
       + Home X/Y
       + Home Z
       + Park toolhead
       + Steppers off
       + E Stepper off
       + Fan: OFF
       + Fan speed: 000%
   + **Temperature:**
       + Ex0:000 (0000)
       + Bed:000 (0000)
       + Preheat PLA
           + Preheat all
           + Preheat hotend
           + Preheat hotbed
       + Preheat PETG
           + Preheat all
           + Preheat hotend
           + Preheat hotbed
       + Preheat ABS
           + Preheat all
           + Preheat hotend
           + Preheat hotbed
       + Preheat PROBE
           + Preheat all
           + Preheat hotend
           + Preheat hotbed
       + Cooldown
           + Cooldown all
           + HotEnd off
           + HotBed off
   + **Filament:**
       + Ex0:000 (0000)
       + Load Fil.
           + Load PLA
           + Load PETG
           + Load ABS
       + Unload Fil.
           + Unload PLA
           + Unload PETG
           + Unload ABS   
       + Change Fil.
           + Change PLA
           + Change PETG
           + Change ABS
       + Move E: 000.0 mm
       + E Stepper off
   + **Lights:**
       + lights: ON/OFF
       + Bright: 0.3
       + lights on max.
       + Nozzle: ON/OFF
       + Red: 0.30
       + Green: 0.30
       + Blue: 0.30
   + **Chamber:**
       + Current: Temperature °C
       + Heating: 0°C
       + Cooling: 0°C
       + All OFF
   + **Setup:**
       + Power Management
           + Restart
           + Restart FW
           + Power Off
       + Calibration
           + Preheat: 
              + Preheat all      
              + Preheat hotend   
              + Preheat hotbed   
           + Home All
           + Bed Mesh            
           + Z Tilt 
           + PID tuning
              + Tune Hotend PID
              + Tune Hotbed PID
           + Z ENDSTOP CALIBRATE
           + PROBE CALIBRATE
           + Save config
       + Language
           + English
           + Cestina
           + Deutsch
       + Filament sensor
           + Extension: ON/OFF
           + Distance: 930mm
       + Display knob
           + Feedback: ON/OFF
        
       
