Guide to SMS test program.
------------------------------

Before you start thinking about running these tests on your emulator make sure
it passes the ZEXALL (or at least ZEXDOC if there is such a thing) test and
that you emulate exactly 228 cpu cycles per scanline.
Some tests will also be dependant that other tests work ok, hopefully I can
explain those here in this guide.

The newest version should be available at www.ndsretro.com


HCounter test:
	The HCounter value from io port $7F should be constant in normal conditions.
	Setting the TH pin to 0 and then 1 will latch the current HCounter value,
	this can be done from the actual joystick port or from software by changing
	port $3F.
	The values are the HClock (-47 -> 294) divided by 2 or
	the MClock (0 -> 683)-94 divided by 4.



VINT occur at HClock -18 (HCount 0xF3), -14 (Hcount 0xF6) on MD.
HINT occur at HClock -17 (HCount 0xF3), -13 (Hcount 0xF6) on MD.
NMI occur at HClock -16 (HCount 0xF4).
VCount change at HClock -16 (HCount 0xF4), -13 (HCount 0xF6) on MD.
VINT flag is set at HClock -15 (HCount 0xF5). -13 (HCount 0xF6) on MD.
OVR flag is set at HClock -15 (HCount 0xF5). -13 (HCount 0xF6) on MD.
COL flag is set at the pixel it occurs. -13 (HCount 0xFF) on MD.
XScroll is latched between HClock -18 & -17 (HCount 0xF3), HClock -15 & -14 (HCount 0xF5 & 0xF6) on MD.
YScroll is latched between HClock ? & ? (HCount ?) on line ?
	HClock ? & ? (HCount ? & ?) on MD.

NameTable base is not latched, it's updated through out the scanline.





The tests:
----------

Normal read/write:
	Use code0 for read and code1 for write.
Read after code1 wr:
Read after code2 wr:
Read after code3 wr:
	Using any other code than 0 for read just means that there is no prefetch
	of data from VRAM after setting address, other than that it's the same.
Write after code0 wr:
	Using code0 just mean that the VRAM address is increased by one from the value set.
Write after code2 wr:
	This is normaly used for setting registers but it also sets the VRAM address.
Write after code3 wr:
	Write to palette.
Mixed read/write:
	Mixing reads and writes should work, the address is one and the same.
VRAM wr set VDPbuffer:
CRAM wr set VDPbuffer:
	Data writes to the VDP sets the "readbuffer".
1byte wr sets rd adr:
1byte wr sets wr adr:
	First ctrl write to the VDP should set the low byte of the address.
1byte wr keeps wr mode:
	Changing address should not change between VRAM and CRAM.
Address wraps at $3FFF:
	Just checking for wrap around issues.
VRAM & CRAM share adr:
	There is just one address in the VDP, it just switches destination RAM and mask
Rd VDPCtrl reset latch:
Rd VDPData reset latch:
Wr VDPData reset latch:
	All these operations should reset the address latch/flipflop.
Unused regs, no effect:
	Setting VDP regs 0x0B-0x0F should not affect anything.

VCounter values:
	This checks all VCount values to make sure they are valid PAL or NTSC 256x192 displays.
HCounter keeps value:
	Just polling HCount port should return a constant value in normal conditions.
HC change on TH 0->1:
	Toggling line TH of port 0x3F from 0 to 1 latches current HCount value,
	this is crucial for a lot of the timing dependent tests.
HCounter correct:
	This tests all HCount values to make sure they are correct, my MegaDrive
	behaves different from time to time.
VCounter chg time:
	Tests the HCount time the VCounter changes.
VDP Register mirrors:
	This tests that bit 12 & 13 of VDP register doesn't have an effect.
VDP data mirrors:
VDP ctrl mirrors:
VCounter mirrors:
HCounter mirrors:
	This tests some IO port mirros
Frame IRQ VCount:
	Tests that Frame IRQ (VINT) happens on the correct scanline.
Frame IRQ HCount:
	Tests the HCount time the Frame IRQ (VINT) happens.
Line IRQ VCount:
	Tests a couple of different scanline IRQs to
	make sure they happen on the correct ones.
Line IRQ HCount:
	Tests the HCount time the Line IRQ happens.
VINT flag HCount:
	Tests the HCount time the VINT flag is set.
VINT flag keept:
	Tests that the VINT flag is set as long as VDPCtrl is not read.

No sprite collision:
	This sets out 2 sprites that are not colliding and test the result.
No disp, no spr col:
	When display is off COL flag should not be set.
9th sprite no col:
	You can only have 8 sprites per scanline so the
	9th sprite can not collide with other sprites.
Transp pixl, no col:
	Even if 2 sprites are the same location but they have
	no overlapping pixel a collision will not happen.
Offscreen X, no col:
	If all the colliding pixels are off screen (at least right)
	there is no collision.
Offscreen Y, col:
	Somhow sprites that are colliding and offscreen in
	top/bottom border still set the collision flag.
Sprite collision:
	This sets 2 sprites at the same location in the middle of the screen.
Colflag keept in vbl:
	Tests that COL flag is set until VDPCtrl is read.
Spr col behind tile:
	Tests that sprites still collide even if they are behind background tiles.
Spr col correct line:
	This tests that the COL flag is set on the correct line (more or less).
Spr col many lines:
	This tests that the COL flag is set on every row colliding pixels exist.
Spr col correct HC:
	This checks that the COL flag is set at the correct HCount.
	This test is very limited, it only checks that colliding pixels
	at xpos 0x83 gives a HCount of (second) 0x47.
No sprite overflow:
	This test puts out less than 9 sprites on a row
	to make sure the COL flag is not set by accident.
No disp, spr ovr:
	According to this test, sprite overflow still happens when the display is off.
Offscreen Y, no ovr:
	Sprites that are offscreen in the top/bottom border doesn't set the OVR flag.
Sprite overflow:
	Sets up 9 sprites on a row to test the OVR flag.
Ovrflag keept in vbl:
	Tests that the OVR flag is only reset by reading VDPCtrl.
Spr ovr correct line:
	Tests that the OVR flag is set on the correct scanline (more or less).
Spr ovr many lines:
	Tests that the OVR flag is set on every line the overflow occurs.
Spr ovr correct HC:
	This checks that the OVR flag is set at the correct HCount.

The first straight column tests at what (HCount) time HScroll value is latched.

The second straight column tests at what (HCount) time NameTable value is latched.


