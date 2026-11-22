<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

This device contains two ring oscillators with the ability to rout not gates between the two rings to achieve different frequencies.

additionally a bypass path is made available which allows for defects in combinations of gates to be robustly routed around to ensure operation even with ageing and damage present. 

lastly the device contains a final block with the ability to break any of the three paths to test routing around the device.

## How to test

the ring must be fed a 27 bit configuration bitstream the reset value is 0x000 0000 or all NOT gates on the slow loop none on the fast loop no gates bypassed no defects introduced.
the bits map to 12 pairs of bits XY
the bit X is:
    0: low loop in maps to low loop out
       high loop in maps to high loop out
       low loop in maps to bypass loop out
    1: Low loop in maps to high loop out
       High loop in maps to low loop out
       high loop in maps to bypass out
the bit Y is:
    0: Low loop in maps to low loop out
       bypass loop in maps to high loop out
    1: high loop in maps to high loop out
       bypass loop in maps to low loop out
these bits repeat for 12 sets of XY for each of the 12 stages of the loop
the last three bits XYZ and be used to:
   X: 1 breaks the low loop
   Y: 1 break the high loop
   Z: 1 breaks the bypass loop 
   0 is normal operation for all

low a bit stream and monitor the high and low loop outputs or the beat frequency depending on goals

## External hardware

2 buttons are needed to clock in the bit stream 3 leds can be used to visualize the divided down loop outputs or an oscilloscope can be used to view the non divided outputs
