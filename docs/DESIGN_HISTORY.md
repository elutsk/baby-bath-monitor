# Design History

The project went through several hardware revisions. This document keeps the original circuit description of revision 2.1 and summarises what changed on the way to the final design described in [TECHNICAL.md](TECHNICAL.md).

## Revision 2.1 → final design

| | Rev. 2.1 (November 2011) | Final (2012–2013) |
|---|---|---|
| MCU | ATtiny261A (2 KB flash) | ATtiny861A (8 KB flash) |
| Supply | Battery through two series diodes (VD1, VD2): 4.1–5.1 V | NCP583 3.3 V LDO with LC-filtered AVCC |
| Display | 3 × single-digit LED displays (KCSA02-102 / KCSC02-102, common anode), 560 Ω segment resistors | 3-digit LTC-2687 display, 330 Ω segment resistors |
| Digit 2 anode | Switched from the **battery** by the same transistor as the LM35 | Switched from VCC; the LM35 has its own switch (VT8), controlled from digit 2 |
| Water sensor | Digital: level change on PB6 / INT0 | Analog on ADC9, with adjustable sensitivity and self-test (short / wet / open) |
| Buzzer | — | Self-powering bridge driver on a TS3702 comparator |
| Firmware size | Had to fit into 2 KB | 5.6 KB |

What stayed the same from rev. 2.1 onwards:

- The display digit drivers also power the sensors, so the temperature and keyboard measurements are tied to the digit 2 and digit 1 time slots.
- The keyboard is a resistor ladder on PA2, used both as an interrupt (wake-up) and as an ADC input.
- The LM35 is powered from the full battery voltage and read on ADC7 against the internal reference.
- All digit selects are active-low: PB0 → digit 1, PB1 → digit 2, PB2 → digit 3.

---

## Revision 2.1 circuit description

*Translated from the original Russian document (`design_notes_v2.1_ru.doc`, 27.11.2011). Reference designators refer to the rev. 2.1 schematic, which is not included in this repository, and differ from the final schematic.*

### Power supply

The device is powered by two CR2032 lithium cells with a total voltage of 5.5–6.5 V. Diodes VD1 and VD2 drop this to 4.1–5.1 V for the ATtiny261A microcontroller.

### Temperature sensor

The LM35 temperature sensor is powered from the full battery voltage through the transistor switch VT1. The same transistor also connects the LED anodes of display digit H2 to the battery. Temperature can therefore be measured either while digit H2 is being displayed, or at any other time by driving PB1 low. The sensor's output voltage is measured by the microcontroller's ADC (ADC7) against the internal voltage reference.

### Display

Three LED displays (KCSA02-102 or KCSC02-102, common anode) are multiplexed. The segment lines are connected in parallel and driven by the microcontroller through 560 Ω resistors (R1–R5, R7–R9), which limit the current to 3.5–5 mA per segment. A digit is selected by setting the corresponding output low: PB0 selects H1, PB1 selects H2, PB2 selects H3.

### Keyboard

The keyboard has two operating modes: passive and active.

In **passive** mode the device only detects that some button has been pressed. The microcontroller can be in any operating or power-saving mode at this time, which is what allows a button press to switch the device on. When a button is pressed, the microcontroller sees the level on PA2 (INT1) change from 1 to 0 and generates an interrupt. PA2 is then switched from INT1 to ADC2, which puts the keyboard into active mode.

In **active** mode the pressed button is identified by measuring the voltage across a resistor divider (VT2, R15, R16, R18, R23, R19, R14) with the ADC (ADC2). To reduce the influence of the supply voltage on the result, the microcontroller's supply voltage is used as the ADC reference. The measurement can be made either while digit H1 is being displayed, or at any other time by driving PB0 low.

### Water-level sensor

The water-level sensor is a contact type with immersed electrodes and no galvanic isolation. It works by detecting the change in resistance between the electrodes when they are immersed in water. This does not work with distilled water or water purified by reverse osmosis. The microcontroller detects the level change from 0 to 1 on input PB6 and generates an INT0 interrupt, which indicates that the water has reached the set level.
