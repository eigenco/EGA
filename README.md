[EGA.PAS] Test program for EGA monitors with 64 color palette in 320x200 resolution support when VSYNC polarity is negative.

![EGA64C](https://github.com/eigenco/EGA/assets/42321684/6a913a5a-7ecf-46b6-90d3-7f246e4dfbde)

[EGA64.ASM] TSR for enabling VSYNC- with Ironman (DOS game) which supports EGA64, but doesn't set VSYNC-.

Difference demonstrated below (first is regular EGA16, second is EGA64).

![EGA16](https://github.com/eigenco/EGA/assets/42321684/fd8846b0-8382-401e-9b5d-99aae28368ce)
![EGA64](https://github.com/eigenco/EGA/assets/42321684/3c9ae760-0e7c-49ba-ada4-9ed6d1cda90a)

[NOEGA64.ASM] TSR for setting 640x200 instead of 640x350 in Lemmings (DOS game) menus. We force the resolution and drop every second scanline to make graphics visible on monitors supporting only low resolution EGA (15 kHz only displays).

![EGA320LEMM](https://github.com/eigenco/EGA/assets/42321684/8188226c-b66d-4fe7-a7e2-220402df0109)

Coppers are also doable with EGA64 both in mode 0dh and 10h. This allows more than 16 simultaneous colors on screen (but at most 16 colors per scanline).

![EGA64_0D_COPPERS](https://github.com/eigenco/EGA/assets/42321684/e7d8b5d8-e86d-43f3-8825-66582eb31a7a)

[EKEF200.PAS, EKEF350.PAS] Kefrens Bars in 320x200 and 640x350. The 320x200 mode with 64 EGA colors doesn't work properly in dosbox, but 640x350 with 64 EGA colors does work (in dosbox-x at least). To see 320x200 with 64 EGA colors, real hardware with compatible monitor or 86box is needed.

![kefrens](https://github.com/user-attachments/assets/9f421bf0-65c9-46a3-ab95-b605d10fcda7)

[EKEFEXT4.PAS] EGA copper bars (with Kefrens bars) using higher number of "fake" colors with temporal and spatial dithering for the coppers.

<img width="320" height="200" alt="Screenshot (1523)" src="https://github.com/user-attachments/assets/64d00023-8022-4c50-8298-921fa79563fd" />

[ETEXTCOP.PAS] EGA copper bars for minimum of 286/10 MHz (1WS) or 286/8 MHz (0WS) in textmode.

<img width="640" height="400" alt="Monitor_1_20260127-094201-902" src="https://github.com/user-attachments/assets/377bde5b-3273-4377-a047-4d1257228977" />

[ETXTK6.PAS] Kefrens Bars and Copper Bars with 64 EGA colors. Runs on 286/10 MHz (0WS) in textmode (mode 3h).

<img width="640" height="400" alt="Monitor_1_20260127-150910-548" src="https://github.com/user-attachments/assets/de9f026f-2bbc-42c9-849e-43aeae0b3fed" />

