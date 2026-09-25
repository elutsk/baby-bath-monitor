# Baby Bath Monitor — User Manual

*English translation of the original Russian manual (`user_manual_ru.doc`, September 2012), updated to match the final firmware (2013). Sections that describe features added after the original manual was written are marked **[firmware 2013]**.*

---

## Controls

The device has four buttons and a hardware reset button:

| Button | Function |
|---|---|
| **ENTER** | Open the menu / confirm a value / go to the next menu item |
| **+** | Increase a value; outside the menu — toggle °C / °F |
| **−** | Decrease a value; outside the menu — toggle °C / °F |
| **CANCEL** | Discard changes / leave the menu; hold to switch off; press during an alarm to silence it |
| **RESET** | Hardware reset of the microcontroller |

---

## 1. Inserting the batteries or pressing RESET

After the batteries are inserted or the hardware RESET button is pressed, all user settings are restored to their factory defaults (upper temperature limit 40 °C, lower limit off, water-level alarm on). Service settings (sensor calibration, sensitivity, timeouts) are kept.

The device then runs a self-test of the water-level sensor and shows the result in the third digit of the display:

| Code | Meaning |
|---|---|
| **0** | Sensor OK |
| **1** | Electrodes short-circuited |
| **2** | Electrodes are wet |
| **3** | Open circuit in the sensor wiring |

> **Note.** The original manual listed code 1 as *open circuit* and code 3 as *short circuit*. The table above follows the actual firmware logic (`water_analyze` routine).

If an error is detected, the buzzer sounds and the error code is stored in the water-level alarm setting (see section 3, item **SE**). In this case the water-level alarm is disabled. After the self-test the device switches to normal temperature measurement and display.

## 2. Changing the temperature units

Outside the menu, pressing **+** or **−** toggles the displayed temperature between Celsius and Fahrenheit. Celsius is shown with one decimal place (e.g. `36.6`) below 100 °C; Fahrenheit is shown in whole degrees.

## 3. User menu

Press **ENTER** to enter the menu. Each menu item first shows its name for about one second, then the current value.

- Change the value with **+** and **−** (holding a button auto-repeats with acceleration).
- Press **ENTER** to confirm and go to the next item.
- Press **CANCEL** to discard the change; press **CANCEL** again to leave the menu.

| Display | Setting | Range | Description |
|---|---|---|---|
| `HI` | Upper temperature limit | 0…100 °C | Exceeding this temperature triggers the high-temperature alarm. **0** disables it. |
| `LO` | Lower temperature limit | 0…100 °C | Falling below this temperature triggers the low-temperature alarm. **0** disables it. |
| `SI` | Pre-alarm zone **[firmware 2013]** | −99…+99 °C | Width of the "warning" zone around the limits (see below). **0** — no warning zone. |
| `SE` | Water-level alarm | `On` / `OFF` | Enables or disables the water-level alarm. If the self-test found a sensor fault, this item shows `E0x` (x — error code), is read-only, and the alarm stays disabled. |

**How the `SI` zone works.** The temperature alarms have two levels: a short, intermittent *warning* tone and a continuous *alarm* tone.

- **Negative `SI`** — early warning. For example, with `HI = 38` and `SI = −2`, the warning tone starts at 36 °C and the continuous alarm at 38 °C.
- **Positive `SI`** — tolerance band. With `HI = 38` and `SI = +2`, the warning tone sounds from 38 °C and the continuous alarm starts at 40 °C.

The lower limit works the same way, mirrored.

## 4. Service menu

The service menu contains calibration and advanced settings. It can only be entered at power-up: insert the batteries (or press RESET) while holding **ENTER**, **CANCEL**, **+** and **−** together, and keep them pressed for 1.5–2 seconds. While the self-test is running, a `−` sign moves along the display; a beep confirms entry into the service menu. Settings are changed the same way as in the user menu.

| Display | Setting | Range | Description |
|---|---|---|---|
| `SEn` | Water sensor sensitivity | 0…100 | Higher values make the water-level sensor trigger more easily. |
| `Cr0` | Temperature offset correction **[firmware 2013]** | −10…+10 | Shifts the reading by roughly 0.1 °C per step. |
| `CrA` | Temperature scale correction **[firmware 2013]** | −15…+15 | Fine-tunes the ADC reference value (1 step = 1 mV of the 1.1 V reference, ≈ 0.1 % of the reading). |
| `Con` | Display timeout **[firmware 2013]** | 1…999 s | How long the display stays on after the last button press. |
| `ALr` | Alarm hold time **[firmware 2013]** | 0…60 s | How long an alarm keeps sounding after the alarm condition has cleared. |

## 5. Power-saving mode

If no button is pressed within the display timeout (5 s by default, adjustable with `Con`), the device enters power-saving mode and switches the display off. It continues to check the water-level sensor and measure the temperature once per second, and all alarms remain active. Press any button to switch the display back on.

## 6. Switching off and on

To switch the device off, press and hold **CANCEL** until the display goes dark (2–3 s), then release it. The device switches off about four seconds later. In the off state no measurements are made.

To switch it on, briefly press any button.

## 7. Saving user settings

Settings made in any menu are saved to the microcontroller's non-volatile memory (EEPROM). This happens automatically when the device is switched off with **CANCEL**, but only if the battery voltage is normal (not below 4 V). Otherwise, to prevent data corruption, the write is skipped and the previously saved settings will be used after power-on.

## 8. Battery monitoring

The supply voltage is checked once per second. If it falls below 4 V, an intermittent tone sounds and `Chr` is shown on the display (if the display is currently on).

## 9. Sound signals

| Signal | Meaning |
|---|---|
| Intermittent tone, 1 kHz | Water-level sensor triggered (highest priority) |
| Continuous tone, 1.5 kHz | Temperature is above the upper limit (`HI`) |
| Intermittent tone, 1.5 kHz | Temperature is in the warning zone near the upper limit **[firmware 2013]** |
| Continuous tone, 600 Hz | Temperature is below the lower limit (`LO`) |
| Intermittent tone, 600 Hz | Temperature is in the warning zone near the lower limit **[firmware 2013]** |
| Short beeps, ≈2 kHz | Low battery |
| Short click | Button press confirmation |

**Silencing an alarm [firmware 2013].** Press **CANCEL** (outside the menu) while an alarm is sounding to mute it for about 30 seconds. If the alarm condition persists, the alarm resumes afterwards.
