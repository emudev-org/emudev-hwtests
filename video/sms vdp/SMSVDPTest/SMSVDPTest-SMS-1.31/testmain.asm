
.define Mem_Ctrl $3e
.define IO_Ctrl $3f
.define VCounter $7e
.define HCounter $7f
.define VDP_Data $be
.define VDP_Ctrl $bf
.define IO_PortA $dc
.define IO_PortB $dd

.define NMI_row			$c800
.define HVScroll		$c802
.define Timer1			$c804
.define Timer2			$c806
.define stdout_col		$c810
.define stdout_row		$c811
.define KEY1_old		$c812
.define KEY1_pressed	$c813
.define KEY1_released	$c814
.define KEY1_current	$c815
.define MENU_POS		$c816
.define MENU_POS_OLD	$c817
.define TEMP_REGISTERS	$c818
.define HBL_JUMP		$c81a

.define TestScratch		$c880

.define TestResult01	$c900
.define TestResult02	$c901
.define TestResult03	$c902
.define TestResult04	$c903
.define TestResult05	$c904
.define TestResult06	$c905
.define TestResult07	$c906
.define TestResult08	$c907
.define TestResult09	$c908
.define TestResult10	$c909
.define TestResult11	$c90a
.define TestResult12	$c90b
.define TestResult13	$c90c
.define TestResult14	$c90d
.define TestResult15	$c90e
.define TestResult16	$c90f
.define TestResult17	$c910
.define TestResult18	$c911
.define TestResult19	$c912
.define TestResult20	$c913
.define TestResult21	$c914
.define TestResult22	$c915
.define TestResult23	$c916
.define TestResult24	$c917
.define TestResult25	$c918
.define TestResult26	$c919
.define TestResult27	$c91a
.define TestResult28	$c91b
.define TestResult29	$c91c
.define TestResult30	$c91d
.define TestResult31	$c91e
.define TestResult32	$c91f
.define TestResult33	$c920
.define TestResult34	$c921
.define TestResult35	$c922
.define TestResult36	$c923
.define TestResult37	$c924
.define TestResult38	$c925
.define TestResult39	$c926
.define TestResult40	$c927
.define TestResult41	$c928
.define TestResult42	$c929
.define TestResult43	$c92A
.define TestResult44	$c92B
.define TestResult45	$c92C
.define TestResult46	$c92D
.define TestResult47	$c92E
.define TestResult48	$c92F
.define TestResult49	$c930
.define TestResult50	$c931
.define TestResult51	$c932
.define TestResult52	$c933
.define TestResult53	$c934
.define TestResult54	$c935
.define TestResult55	$c936
.define TestResult56	$c937
.define TestResult57	$c938
.define TestResult58	$c939
.define TestResult59	$c93A
.define TestResult60	$c93B

.define HCValueHBlank	$c980
.define HCValueVBlank	$c981
.define HCValueNMI		$c982
.define HCValueLine		$c983
.define VCValueHBlank	$c984
.define VCValueVBlank	$c985
.define VCValueNMI		$c986
.define VCValueLine		$c987
.define TestAreaHC		$ca00
.define TestAreaVC		$cc00
.define SpriteArea		$ce00
.define RegisterArea	$dc00

.define NameTableAddress    $3800   ; must be a multiple of $800; usually $3800; fills $700 bytes (unstretched)
.define SpriteTableAddress  $3f00   ; must be a multiple of $100; usually $3f00; fills $100 bytes
.define VDP_Mode_Read		$0000	;Read mode for the VDP
.define VDP_Mode_Write		$4000	;Write mode for the VDP
.define VDP_Mode_Register	$8000	;Register mode for the VDP
.define VDP_Mode_Palette	$C000	;Palette mode for the VDP

.define STDOUT_START_COL	$01		;can be changed to handle GG and other things.
.define STDOUT_START_ROW	$00		;can be changed to handle GG and other things.
.define STDOUT_END_COL		$20		;can be changed to handle GG and other things.
.define STDOUT_END_ROW		$18		;can be changed to handle GG and other things.

.define KEY_UP			$01
.define KEY_DOWN		$02
.define KEY_LEFT		$04
.define KEY_RIGHT		$08
.define KEY_1			$10
.define KEY_2			$20
;==============================================================
; WLA-DX banking setup
;==============================================================
.memorymap
defaultslot 0
slotsize $4000
slot 0 $0000
slot 1 $4000
slot 2 $8000
.endme


.rombankmap
bankstotal 2
banksize $4000
banks 2
.endro

; Memory map (for Phantasy Star tilemap decompression)
.enum $c000
TileMapData: dsb 32*24*2

.ende

;==============================================================
; SDSC tag and SMS rom header
;==============================================================
.sdsctag 1.30,"SMSVDPTest","Test the SMS VDP","FluBBa"

.bank 0 slot 0
.org $0000

.include "colours.inc"
.include "Phantasy Star decompressors.inc"

;==============================================================
; Boot section
;==============================================================
.org $0000
.section "Boot section" force
ColdReset:
;	di				; disable interrupts
;	im 1			; Interrupt mode 1
	jp DumpAllRegisters			;10 cyc
;	jp main			; jump to main program
.ends

;==============================================================
; Quick access to HL to VDP CTRL, by using rst $10
;==============================================================
.org $0010
.section "VDP Ctrl section" force
	push af						;11cyc
	ld a,l						;4cyc
	out (VDP_Ctrl),a			;11cyc
	ld a,h						;4cyc
	out (VDP_Ctrl),a			;11cyc
	pop af						;10cyc
	ret							;12cyc?
.ends

;==============================================================
; IRQ handler
;==============================================================
.org $0038
.section "IRQ handler" force
	; Only acknowledge irq, 13 cycles
	push af						;11 cyc
	in a,(VDP_Ctrl)				;11 cyc
	and $80						;7 cyc
	jr NZ,doVBL					;12/7 cyc
	push hl						;11 cyc
	ld hl,(HBL_JUMP)
	jp (hl)
doVBL
	in a,(VCounter)				;11 cyc
	ld (VCValueVBlank),a		;13 cyc
	push hl						;11 cyc
	ld hl,(Timer1)				;16 cyc
	inc hl						;6 cyc
	ld (Timer1),hl				;16 cyc
	pop hl						;10 cyc
	pop af						;10 cyc
	ei							;4 cyc
	reti						;14 cyc, total 136 cyc.

.ends

;==============================================================
; Pause button handler, NMI
;==============================================================
.org $0066
.section "Pause button handler" force
	; Only acknowledge nmi, 11 cycles
	push af						;11 cyc
	in a,(VCounter)				;11 cyc
	ld (VCValueNMI),a			;13 cyc
	pop af						;10 cyc

	retn						;14
.ends

;==============================================================
; HBlank handlers
;==============================================================
.section "HBL handler" free
doHBL
	in a,(VCounter)				;11 cyc
	ld (VCValueHBlank),a		;13 cyc
	ld a,(Timer2)				;13 cyc
	inc a						;4 cyc
	ld (Timer2),a				;13 cyc
	pop hl						;10 cyc
	pop af						;10 cyc
	ei							;4 cyc
	reti						;14 cyc, total 112 cyc.
.ends



;==============================================================
; Main program
;==============================================================
.section "Main program" free
WarmReset:
	di
	im 1
main:
	ld sp, $dff0
	ld hl,doHBL
	ld (HBL_JUMP),hl

	; Initialise VDP
	call VDP_DefaultInitialise
	;call VDP_ClearVRAM

	call VDP_SpritesOff ; they mess things up


	; Load tiles
	ld de,$4000
	ld hl,chartiles
	call LoadTiles4BitRLENoDI

	; Write some cubes to the tilemap
;	call Write_Cubes0_0
;	call Write_Cubes0_1
;	call VDP_ScreenOn
;	ei
;	ld b,$80
;	call WaitForBFrames
;	call VDP_ScreenOff

	; Load palette
	ld hl,$c000						; palette index 0 write address
	call VDP_VRAMToHL
	ld hl,charpalette				; data
	ld bc,charpalettesize			; size
	ld bc,5							; size
	call VDP_WriteToVRAM

	call StdOut_Init

	ld hl,menu_text
	call StdOut_Write
	call VDP_ScreenOn
	call WaitForNoButton
	ld a,$00
	ld (KEY1_current),a	;init old keys.

MenuStart:
	ld a,$00
	ld (MENU_POS),a		;init menu pos
	ld (MENU_POS_OLD),a	;init menu pos
	ei
-:	halt
	call ReadKeys
	ld a,(MENU_POS)
	ld (MENU_POS_OLD),a
	ld d,a
	ld a,(KEY1_pressed)
	cp KEY_1
	jr z,RunMenu
	cp KEY_UP
	jr nz,+
	dec d
+:
	cp KEY_DOWN
	jr nz,+
	inc d
+:
	ld a,d
	cp $FF
	jr nz,+
	ld a,$00
+:
	cp $05
	jr nz,+
	ld a,$04
+:
	ld (MENU_POS),a

	ld c,$01
	ld a,(MENU_POS_OLD)
	add a,$03
	ld b,a
	ld (stdout_col),bc
	call StdOut_SetVRAMPointer
	ld hl,space_text
	call StdOut_Write
	
	ld c,$01
	ld a,(MENU_POS)
	add a,$03
	ld b,a
	ld (stdout_col),bc
	call StdOut_SetVRAMPointer
	ld hl,marker_text
	call StdOut_Write

	jr -

RunMenu:
	ld a,(MENU_POS)
	cp $00
	jr z,DoSMSTest
	cp $01
	jr z,DoMDTest
	cp $02
	jr z,DoMDPaletteTest
	cp $03
	jr z,DoHCTest
	cp $04
	jr z,DoShowRegisters
	jp MenuStart

ReadKeys:
	ld a,(KEY1_current)
	ld (KEY1_old),a
	ld d,a			;save old keys
	in a,(IO_PortA) ; get input
	cpl             ; invert bits
	ld (KEY1_current),a
	ld e,a
	xor d			;which keys have changed
	ld d,a			;save a
	and e			;mask out keys currently pressed
	ld (KEY1_pressed),a
	ld a,e
	cpl
	ld e,a
	ld a,d
	and e
	ld (KEY1_released),a

	ret

DoSMSTest:
	di              ; disable interrupts
	call VDP_ScreenOff
	call StdOut_Cls
	jp StartSMSTest

DoMDTest:
	di              ; disable interrupts
	call VDP_ScreenOff
	call StdOut_Cls
	jp StartMDTest

DoHCTest:
	di              ; disable interrupts
	call VDP_ScreenOff
	call StdOut_Cls
	jp StartHCTest

DoMDPaletteTest:
	di              ; disable interrupts
	call VDP_ScreenOff
	call StdOut_Cls
	jp StartMDPaletteTest

DoShowRegisters:
	di              ; disable interrupts
	call VDP_ScreenOff
	call StdOut_Cls
	jp StartShowRegisters

;==============================================================
StartSMSTest:
;==============================================================
	ld hl,sms_test1_text
	call StdOut_Write

	call RunTest1
	call RunTest2
	call RunTest3
	call RunTest4
	call RunTest5
	call RunTest6
	call RunTest7
	call RunTest8
	call RunTest9
	call RunTest10
	call RunTest11
	call RunTest12
	call RunTest13
	call RunTest14
	call RunTest15
	call RunTest16
	call RunTest17
	call RunTest18
	call RunTest19

	call StdOut_SetVRAMPointer

	ld hl,res_text_1
	ld a,(TestResult01)
	call WriteResult
	ld hl,res_text_2
	ld a,(TestResult02)
	call WriteResult
	ld hl,res_text_3
	ld a,(TestResult03)
	call WriteResult
	ld hl,res_text_4
	ld a,(TestResult04)
	call WriteResult
	ld hl,res_text_5
	ld a,(TestResult05)
	call WriteResult
	ld hl,res_text_6
	ld a,(TestResult06)
	call WriteResult
	ld hl,res_text_7
	ld a,(TestResult07)
	call WriteResult
	ld hl,res_text_8
	ld a,(TestResult08)
	call WriteResult
	ld hl,res_text_9
	ld a,(TestResult09)
	call WriteResult
	ld hl,res_text_10
	ld a,(TestResult10)
	call WriteResult
	ld hl,res_text_11
	ld a,(TestResult11)
	call WriteResult
	ld hl,res_text_12
	ld a,(TestResult12)
	call WriteResult
	ld hl,res_text_13
	ld a,(TestResult13)
	call WriteResult
	ld hl,res_text_14
	ld a,(TestResult14)
	call WriteResult
	ld hl,res_text_15
	ld a,(TestResult15)
	call WriteResult
	ld hl,res_text_16
	ld a,(TestResult16)
	call WriteResult
	ld hl,res_text_17
	ld a,(TestResult17)
	call WriteResult
	ld hl,res_text_18
	ld a,(TestResult18)
	call WriteResult
	ld hl,res_text_19
	ld a,(TestResult19)
	call WriteResult

	
	ld hl,continue1_text
	call StdOut_Write
	call VDP_ScreenOn
	ei
	call WaitForButton
;==============================================================
SMSTest2:
	di              ; disable interrupts
	call VDP_ScreenOff
	call StdOut_Cls
	ld hl,sms_test2_text
	call StdOut_Write

	call RunTest21
	call RunTest22
	call RunTest23
	call RunTest24
	call RunTest25
	call RunTest26
	call RunTest27
	call RunTest28
	call RunTest29
	call RunTest30
	call RunTest31
	call RunTest32
	call RunTest33
	call RunTest34
	call RunTest35
	call RunTest36


	call StdOut_SetVRAMPointer

	ld hl,res_text_21
	ld a,(TestResult21)
	call WriteResult_VCount
	ld hl,res_text_22
	ld a,(TestResult22)
	call WriteResult
	ld hl,res_text_23
	ld a,(TestResult23)
	call WriteResult
	ld hl,res_text_24
	ld a,(TestResult24)
	call WriteResult
	ld hl,res_text_25
	ld a,(TestResult25)
	call WriteResult
	ld hl,res_text_26
	ld a,(TestResult26)
	call WriteResult
	ld hl,res_text_27
	ld a,(TestResult27)
	call WriteResult
	ld hl,res_text_28
	ld a,(TestResult28)
	call WriteResult
	ld hl,res_text_29
	ld a,(TestResult29)
	call WriteResult
	ld hl,res_text_30
	ld a,(TestResult30)
	call WriteResult
	ld hl,res_text_31
	ld a,(TestResult31)
	call WriteResult
	ld hl,res_text_32
	ld a,(TestResult32)
	call WriteResult
	ld hl,res_text_33
	ld a,(TestResult33)
	call WriteResult
	ld hl,res_text_34
	ld a,(TestResult34)
	call WriteResult
	ld hl,res_text_35
	ld a,(TestResult35)
	call WriteResult
	ld hl,res_text_36
	ld a,(TestResult36)
	call WriteResult

	ld hl,continue2_text
	call StdOut_Write
	call VDP_ScreenOn
	ei
	call WaitForButton
;==============================================================
SMSTest3:
	di              ; disable interrupts
	call VDP_ScreenOff
	call StdOut_Cls
	ld hl,sms_test3_text
	call StdOut_Write

	call RunTest41
	call RunTest42
	call RunTest43
	call RunTest44
	call RunTest45
	call RunTest46
	call RunTest47
	call RunTest48
	call RunTest49
	call RunTest50
	call RunTest51
	call RunTest52
	call RunTest53
	call RunTest54
	call RunTest55
	call RunTest56
	call RunTest57
	call RunTest58
	call RunTest59
	call RunTest60

	call VDP_SpritesOff
	call StdOut_SetVRAMPointer

	ld hl,res_text_41
	ld a,(TestResult41)
	call WriteResult
	ld hl,res_text_42
	ld a,(TestResult42)
	call WriteResult
	ld hl,res_text_43
	ld a,(TestResult43)
	call WriteResult
	ld hl,res_text_44
	ld a,(TestResult44)
	call WriteResult
	ld hl,res_text_45
	ld a,(TestResult45)
	call WriteResult
	ld hl,res_text_46
	ld a,(TestResult46)
	call WriteResult
	ld hl,res_text_47
	ld a,(TestResult47)
	call WriteResult
	ld hl,res_text_48
	ld a,(TestResult48)
	call WriteResult
	ld hl,res_text_49
	ld a,(TestResult49)
	call WriteResult
	ld hl,res_text_50
	ld a,(TestResult50)
	call WriteResult
	ld hl,res_text_51
	ld a,(TestResult51)
	call WriteResult
	ld hl,res_text_52
	ld a,(TestResult52)
	call WriteResult
	ld hl,res_text_53
	ld a,(TestResult53)
	call WriteResult
	ld hl,res_text_54
	ld a,(TestResult54)
	call WriteResult
	ld hl,res_text_55
	ld a,(TestResult55)
	call WriteResult
	ld hl,res_text_56
	ld a,(TestResult56)
	call WriteResult
	ld hl,res_text_57
	ld a,(TestResult57)
	call WriteResult
	ld hl,res_text_58
	ld a,(TestResult58)
	call WriteResult
	ld hl,res_text_59
	ld a,(TestResult59)
	call WriteResult
	ld hl,res_text_60
	ld a,(TestResult60)
	call WriteResult

	ld hl,continue_text
	call StdOut_Write
	call VDP_ScreenOn
	ei
	call WaitForButton


;==============================================================
	call RunTest90
;	call RunTest91			NOT WORKING.
;	call RunTest92
;	call RunTest93
;==============================================================
SMSTest4:
	di
	call VDP_ScreenOff
	call StdOut_Cls
	ld hl,hc_page2_text
	call StdOut_Write
	ld hl,TestAreaHC
	ld b,229
	call StdOut_Write_Hex_Bytes
	call VDP_ScreenOn
	ei
	call WaitForButton
	jp WarmReset

;==============================================================
StartMDTest:
;==============================================================
	ld hl,md_test1_text
	call StdOut_Write

	call RunTest1
	call RunTest2
	call RunTest3
	call RunTest4
	call RunTest5
	call RunTest6_MD
	call RunTest7
	call RunTest8
	call RunTest9_MD
	call RunTest10_MD
	call RunTest11_MD
	call RunTest12_MD
	call RunTest13
	call RunTest14
	call RunTest15
	call RunTest16
	call RunTest17
	call RunTest18
	call RunTest19

	call StdOut_SetVRAMPointer

	ld hl,res_text_1
	ld a,(TestResult01)
	call WriteResult
	ld hl,res_text_2
	ld a,(TestResult02)
	call WriteResult
	ld hl,res_text_3
	ld a,(TestResult03)
	call WriteResult
	ld hl,res_text_4
	ld a,(TestResult04)
	call WriteResult
	ld hl,res_text_5
	ld a,(TestResult05)
	call WriteResult
	ld hl,res_text_6
	ld a,(TestResult06)
	call WriteResult
	ld hl,res_text_7
	ld a,(TestResult07)
	call WriteResult
	ld hl,res_text_8
	ld a,(TestResult08)
	call WriteResult
	ld hl,res_text_9_md
	ld a,(TestResult09)
	call WriteResult
	ld hl,res_text_10_md
	ld a,(TestResult10)
	call WriteResult
	ld hl,res_text_11_md
	ld a,(TestResult11)
	call WriteResult
	ld hl,res_text_12_md
	ld a,(TestResult12)
	call WriteResult
	ld hl,res_text_13
	ld a,(TestResult13)
	call WriteResult
	ld hl,res_text_14
	ld a,(TestResult14)
	call WriteResult
	ld hl,res_text_15
	ld a,(TestResult15)
	call WriteResult
	ld hl,res_text_16
	ld a,(TestResult16)
	call WriteResult
	ld hl,res_text_17
	ld a,(TestResult17)
	call WriteResult
	ld hl,res_text_18
	ld a,(TestResult18)
	call WriteResult
	ld hl,res_text_19
	ld a,(TestResult19)
	call WriteResult

	
	ld hl,continue1_text
	call StdOut_Write
	call VDP_ScreenOn
	ei
	call WaitForButton
;==============================================================
MDTest2:
	di              ; disable interrupts
	call VDP_ScreenOff
	call StdOut_Cls
	ld hl,md_test2_text
	call StdOut_Write

	call RunTest21
	call RunTest22
	call RunTest23
	call RunTest24
	call RunTest25_MD
	call RunTest26_MD
	call RunTest27
	call RunTest28
	call RunTest29
	call RunTest30
	call RunTest31
	call RunTest32_MD
	call RunTest33
	call RunTest34_MD
	call RunTest35_MD
	call RunTest36


	call StdOut_SetVRAMPointer

	ld hl,res_text_21
	ld a,(TestResult21)
	call WriteResult_VCount
	ld hl,res_text_22
	ld a,(TestResult22)
	call WriteResult
	ld hl,res_text_23
	ld a,(TestResult23)
	call WriteResult
	ld hl,res_text_24
	ld a,(TestResult24)
	call WriteResult
	ld hl,res_text_25
	ld a,(TestResult25)
	call WriteResult
	ld hl,res_text_26
	ld a,(TestResult26)
	call WriteResult
	ld hl,res_text_27
	ld a,(TestResult27)
	call WriteResult
	ld hl,res_text_28
	ld a,(TestResult28)
	call WriteResult
	ld hl,res_text_29
	ld a,(TestResult29)
	call WriteResult
	ld hl,res_text_30
	ld a,(TestResult30)
	call WriteResult
	ld hl,res_text_31
	ld a,(TestResult31)
	call WriteResult
	ld hl,res_text_32
	ld a,(TestResult32)
	call WriteResult
	ld hl,res_text_33
	ld a,(TestResult33)
	call WriteResult
	ld hl,res_text_34
	ld a,(TestResult34)
	call WriteResult
	ld hl,res_text_35
	ld a,(TestResult35)
	call WriteResult
	ld hl,res_text_36
	ld a,(TestResult36)
	call WriteResult

	ld hl,continue2_text
	call StdOut_Write
	call VDP_ScreenOn
	ei
	call WaitForButton
;==============================================================
MDTest3:
	di              ; disable interrupts
	call VDP_ScreenOff
	call StdOut_Cls
	ld hl,md_test3_text
	call StdOut_Write

	call RunTest41
	call RunTest42
	call RunTest43
	call RunTest44
	call RunTest45
	call RunTest46_MD
	call RunTest47
	call RunTest48
	call RunTest49
	call RunTest50
	call RunTest51
	call RunTest52_MD
	call RunTest53
	call RunTest54_MD
	call RunTest55
	call RunTest56
	call RunTest57
	call RunTest58
	call RunTest59
	call RunTest60_MD

	call VDP_SpritesOff
	call StdOut_SetVRAMPointer

	ld hl,res_text_41
	ld a,(TestResult41)
	call WriteResult
	ld hl,res_text_42
	ld a,(TestResult42)
	call WriteResult
	ld hl,res_text_43
	ld a,(TestResult43)
	call WriteResult
	ld hl,res_text_44
	ld a,(TestResult44)
	call WriteResult
	ld hl,res_text_45
	ld a,(TestResult45)
	call WriteResult
	ld hl,res_text_46_MD
	ld a,(TestResult46)
	call WriteResult
	ld hl,res_text_47
	ld a,(TestResult47)
	call WriteResult
	ld hl,res_text_48
	ld a,(TestResult48)
	call WriteResult
	ld hl,res_text_49
	ld a,(TestResult49)
	call WriteResult
	ld hl,res_text_50
	ld a,(TestResult50)
	call WriteResult
	ld hl,res_text_51
	ld a,(TestResult51)
	call WriteResult
	ld hl,res_text_52
	ld a,(TestResult52)
	call WriteResult
	ld hl,res_text_53
	ld a,(TestResult53)
	call WriteResult
	ld hl,res_text_54_MD
	ld a,(TestResult54)
	call WriteResult
	ld hl,res_text_55
	ld a,(TestResult55)
	call WriteResult
	ld hl,res_text_56
	ld a,(TestResult56)
	call WriteResult
	ld hl,res_text_57
	ld a,(TestResult57)
	call WriteResult
	ld hl,res_text_58
	ld a,(TestResult58)
	call WriteResult
	ld hl,res_text_59
	ld a,(TestResult59)
	call WriteResult
	ld hl,res_text_60
	ld a,(TestResult60)
	call WriteResult

	ld hl,continue_text
	call StdOut_Write
	call VDP_ScreenOn
	ei
	call WaitForButton

;==============================================================
	call RunTest90_MD
;==============================================================
MDTest4:
	di
	call VDP_ScreenOff
	call StdOut_Cls
	ld hl,hc_page2_text
	call StdOut_Write
	ld hl,TestAreaHC
	ld b,229
	call StdOut_Write_Hex_Bytes
	call VDP_ScreenOn
	ei
	call WaitForButton
	jp WarmReset
;==============================================================
StartHCTest:
;==============================================================
	ld hl,hcount_info_text
	call StdOut_Write
	ld a,10
	ld (stdout_row),a
	call StdOut_SetVRAMPointer
	ld hl,continue_text
	call StdOut_Write
	call VDP_ScreenOn
	ei
	call WaitForButton


	di
	call VDP_ScreenOff
	call StdOut_Cls
	ld hl,hc_page2_text
	call StdOut_Write
	call RunTest24
	ld hl,TestAreaHC
	ld b,229
	call StdOut_Write_Hex_Bytes
	call VDP_ScreenOn
	ei
	call WaitForButton


	call VDP_ScreenOff
	call RunTest100
	call StdOut_Cls
	ld hl,hc_page3_text
	call StdOut_Write
	ld a,8
	ld (stdout_row),a
	call StdOut_SetVRAMPointer
	ld hl,hbl_vbl_text
	call StdOut_Write

	ld bc,$080F
	ld (stdout_col),bc
	call StdOut_SetVRAMPointer
	ld a,(HCValueLine)
	call StdOut_Write_Hex_Reg_A

	ld bc,$090F
	ld (stdout_col),bc
	call StdOut_SetVRAMPointer
	ld a,(HCValueHBlank)
	call StdOut_Write_Hex_Reg_A

	ld bc,$0A0F
	ld (stdout_col),bc
	call StdOut_SetVRAMPointer
	ld a,(HCValueVBlank)
	call StdOut_Write_Hex_Reg_A

	call VDP_ScreenOn
	ei
	call WaitForButton

	jp WarmReset
	
;==============================================================
StartShowRegisters:
;==============================================================
	call VDP_ScreenOff
	call StdOut_Cls
	ld hl,cpu_regs_text
	call StdOut_Write


	ld hl,reg_text_sp
	ld de,(RegisterArea+$00)
	call WriteRegisterValue
	ld hl,reg_text_ir
	ld de,(RegisterArea+$02)
	call WriteRegisterValue
	ld hl,reg_text_af
	ld de,(RegisterArea+$04)
	call WriteRegisterValue
	ld hl,reg_text_bc
	ld de,(RegisterArea+$06)
	call WriteRegisterValue
	ld hl,reg_text_de
	ld de,(RegisterArea+$08)
	call WriteRegisterValue
	ld hl,reg_text_hl
	ld de,(RegisterArea+$0A)
	call WriteRegisterValue
	ld hl,reg_text_ix
	ld de,(RegisterArea+$0C)
	call WriteRegisterValue
	ld hl,reg_text_iy
	ld de,(RegisterArea+$0e)
	call WriteRegisterValue
	ld hl,reg_text_af2
	ld de,(RegisterArea+$10)
	call WriteRegisterValue
	ld hl,reg_text_bc2
	ld de,(RegisterArea+$12)
	call WriteRegisterValue
	ld hl,reg_text_de2
	ld de,(RegisterArea+$14)
	call WriteRegisterValue
	ld hl,reg_text_hl2
	ld de,(RegisterArea+$16)
	call WriteRegisterValue
	ld hl,reg_text_iff2
	ld de,(RegisterArea+$18)
	call WriteRegisterValue
	ld hl,reg_text_vc
	ld de,(RegisterArea+$1A)
	call WriteRegisterValue
	ld hl,reg_text_hc
	ld de,(RegisterArea+$1C)
	call WriteRegisterValue

	call VDP_ScreenOn
	ei
	call WaitForButton
	jp WarmReset
;==============================================================
.ends

;==============================================================
; Set Border Color.
;==============================================================
; A=color, Clobbers A & d
;==============================================================
.section "Set Bd color" free
VDP_SetBdColor:
;set palette 0
  ld d,a						;4 cyc
  ld a,$10						;7 cyc
  out (VDP_Ctrl),a				;11 cyc
  ld a,$c0						;7 cyc
  out (VDP_Ctrl),a				;11 cyc

  ld a,d						;4 cyc
  out (VDP_Data),a				;11 cyc

  ret							;10 cyc
.ends							;65 cycles total

;==============================================================
; Set Background Color.
;==============================================================
; A=color, Clobbers A & d
;==============================================================
.section "Set Bg color" free
VDP_SetBgColor:
;set palette 0
  ld d,a						;4 cyc
  ld a,$00						;7 cyc
  out (VDP_Ctrl),a				;11 cyc
  ld a,$c0						;7 cyc
  out (VDP_Ctrl),a				;11 cyc

  ld a,d						;4 cyc
  out (VDP_Data),a				;11 cyc

  ret							;10 cyc
.ends							;65 cycles total

;==============================================================
; Set up VDP registers (default values)
;==============================================================
; Call DefaultInitialiseVDP to set up VDP to default values.
; Also defines NameTableAddress, SpriteTableAddress and SpriteSet
; which can be used after this code in the source file.
; To change the values used, copy and paste the modified data
; and code into the main source. Data is commented to help.
;==============================================================
.section "Initialise VDP to defaults" free
VDP_DefaultInitialise:
    push hl
    push bc
        ld hl,_Data
        ld b,_End-_Data
        ld c,VDP_Ctrl
        otir
    pop bc
    pop hl
    ret

.define SpriteSet           0       ; 0 for sprites to use tiles 0-255, 1 for 256+

_Data:
    .db %00000100,$80
    ;    |||||||`- Disable sync
    ;    ||||||`-- M2, Enable extra height modes
    ;    |||||`--- SMS mode instead of SG
    ;    ||||`---- Shift sprites left 8 pixels
    ;    |||`----- Enable line interrupts
    ;    ||`------ Blank leftmost column for scrolling
    ;    |`------- Fix top 2 rows during horizontal scrolling
    ;    `-------- Fix right 8 columns during vertical scrolling
    .db %00100000,$81
    ;     |||||||`- Zoomed sprites -> 16x16 pixels
    ;     ||||||`-- Doubled sprites -> 2 tiles per sprite, 8x16
    ;     |||||`--- MD mode instead of SMS
    ;     |||`---- 30 row/240 line mode
    ;     ||`----- 28 row/224 line mode
    ;     |`------ Enable VBlank interrupts
    ;     `------- Enable display

    .db (NameTableAddress>>10) |%11110001,$82
	.db $FF,$83
	.db %00000011,$84
    .db (SpriteTableAddress>>7)|%10000001,$85
    .db (SpriteSet<<2)         |%11111011,$86
    .db $00,$87
    ;    `-------- Border palette colour (from sprite palette)
    .db $00,$88
    ;    ``------- Horizontal scroll
    .db $00,$89
    ;    ``------- Vertical scroll
    .db $FF,$8a
    ;    ``------- Line interrupt spacing ($ff to disable)
_End:
.ends

;==============================================================
; Clear VRAM
;==============================================================
; Sets all of VRAM to zero
;==============================================================
.section "Clear VRAM" free
VDP_ClearVRAM:
	push af
	push hl
		ld hl,$0000|VDP_Mode_Write
		call VDP_VRAMToHL
		; Output 16KB of zeroes
		ld hl, $4000     ; Counter for 16KB of VRAM
		ld a,$00         ; Value to write
		call VDP_FillVRAM
	pop hl
	pop af
	ret
.ends

;==============================================================
;Fill VRAM
;==============================================================
; Fills a section of VRAM to with contents of a
; hl number of bytes
;==============================================================
.section "Fill VRAM" free
VDP_FillVRAM:
	push bc
		ld b,a
-:		ld a,b				; Value to write
		out (VDP_Data),a	; Output to VRAM address, which is auto-incremented after each write
		dec hl
		ld a,h
		or l
		jp nz,-
	pop bc
	ret
.ends

;==============================================================
; VRAM to HL
;==============================================================
; Sets VRAM write address to hl
;==============================================================
.section "VRAM to HL" free
VDP_VRAMToHL:
	push af
		ld a,l
		out (VDP_Ctrl),a
		ld a,h
		out (VDP_Ctrl),a
	pop af
	ret
.ends

;==============================================================
; VRAM writer
;==============================================================
; Writes BC bytes from HL to VRAM
; Clobbers HL, BC, A
;==============================================================
.section "Raw VRAM writer" free
VDP_WriteToVRAM:
-:	ld a,(hl)
	out (VDP_Data),a
	inc hl
	dec bc
	ld a,c
	or b
	jp nz,-
	ret
VDP_WriteToVRAM_Short:
-:	ld a,(hl)
	out (VDP_Data),a
	inc hl
	djnz -
	ret
.ends

;==============================================================
; VRAM text writer
;==============================================================
; Writes text from HL to VRAM, stops at a 0.
; Clobbers HL, A
;==============================================================
.section "SdtOut writer" free
StdOut_Write:
-:
	ld a,(hl)
	inc hl
	or a
	jp z,+
	call StdOut_Char
	jr -
+:
	ret
StdOut_Char:
	or a
	ret z
	cp $0a
	jp z,StdOut_NewLine
	sub 32
StdOut_Raw:
	ex af,af'
-:	ld a,(stdout_col)
	inc a
	ld (stdout_col),a
	cp STDOUT_END_COL
	jr nz,+
	call z,StdOut_NewLine
	jr -
+:	ex af,af'
	out (VDP_Data),a
	ld a,0
	out (VDP_Data),a
	ret
.ends

;==============================================================
; VRAM hex writer
;==============================================================
; Writes hex from HL to VRAM until b=0.
; Clobbers HL, B, A
;==============================================================
.section "SdtOut hex writer" free
StdOut_Write_Hex:
-:	ld a,(hl)
	inc hl
	call StdOut_Write_Hex_Reg_A
	djnz -
	ret

StdOut_Write_Hex_Bytes:
-:	ld a,(hl)
	inc hl
	call StdOut_Write_Hex_Reg_A
	ld a,0
	call StdOut_Raw
	djnz -
	ret

StdOut_Write_Hex_Reg_A:
-:
	push de
	ld d,a
	srl a
	srl a
	srl a
	srl a
	cp $0A
	jr C,+
	add a,$07
+:
	add a,$10
	call StdOut_Raw

	ld a,d
	and $0F
	cp $0A
	jr C,+
	add a,$07
+:
	add a,$10
	pop de
	jp StdOut_Raw
.ends



;==============================================================
.section "StdOut Misc" free
;==============================================================
; StdOut Init
;==============================================================
StdOut_Init:
	ld hl,NameTableAddress | VDP_Mode_Write
	rst $10
	ld a,$00
	out (VDP_Data),a	; Output to VRAM address, which is auto-incremented after each write
	out (VDP_Data),a	; Output to VRAM address, which is auto-incremented after each write
;	jp StdOut_Cls

;==============================================================
; StdOut Clear Screen
;==============================================================
StdOut_Cls:
	call StdOut_Home
	ld hl,$600		; Counter for 32x24 Tilemap
	ld a,$00		; Value to write
	call VDP_FillVRAM

;==============================================================
; StdOut Reset VRAM Pointer
;==============================================================
StdOut_Home:
	push bc
	ld c,STDOUT_START_COL		;reset col
	ld b,STDOUT_START_ROW		;reset row
	ld (stdout_col),bc
	pop bc
;==============================================================
; Set VRAM pointer to stdout col/row
;==============================================================
StdOut_SetVRAMPointer:
	push bc
	push hl
	ld bc,(stdout_col)
	ld a,b
	sla a
	sla a
	sla a
	sla a
	sla a
	or c
	sla a
	ld c,a
	ld a,b
	srl a
	srl a
	ld b,a
	ld hl,NameTableAddress | VDP_Mode_Write
	add hl,bc
	call VDP_VRAMToHL
	pop hl
	pop bc
	ret
.ends

;==============================================================
; StdOut NewLine
;==============================================================
.section "StdOut NewLine" free
StdOut_NewLine:
	push bc
	ld bc,(stdout_col)
	ld c,STDOUT_START_COL		;reset col
	inc b						;increase row
	ld (stdout_col),bc
	pop bc
	jp StdOut_SetVRAMPointer
.ends


;==============================================================
; Sprite disabler
;==============================================================
; Sets sprite 1 to y=208
; Clobbers HL, A
;==============================================================
.section "No sprites" free
VDP_SpritesOff:
	ld hl,SpriteTableAddress | VDP_Mode_Write
	call VDP_VRAMToHL
	ld a,208
	out (VDP_Data),a
	ret
.ends

;==============================================================
; Turn on screen, wait for button, turn off screen.
;==============================================================
; Clobbers A
;==============================================================
.section "Screen Wait" free
ScreenWait:
	call VDP_ScreenOn
	call WaitForButton
	call VDP_ScreenOff
	ret
.ends

;==============================================================
; Turn on screen.
;==============================================================
; Clobbers A
;==============================================================
.section "Screen On" free
VDP_ScreenOn:
	ld a,%01100000				;$60=vblank irq
	jp VDP_SetReg1
.ends

;==============================================================
; Turn off screen.
;==============================================================
; Clobbers A
;==============================================================
.section "Screen Off" free
VDP_ScreenOff:
	ld a,$20
	jp VDP_SetReg1
.ends

;==============================================================
; Set VDP reg0.
; Clobbers A
;==============================================================
.section "Set VDP reg 0" free
VDP_SetReg0:
	out (VDP_Ctrl),a
	ld a,$80
	out (VDP_Ctrl),a
	ret
.ends

;==============================================================
; Set VDP reg1.
; Clobbers A
;==============================================================
.section "Set VDP reg 1" free
VDP_SetReg1:
	out (VDP_Ctrl),a
	ld a,$81
	out (VDP_Ctrl),a
	ret
.ends

;==============================================================
; Set VDP reg2.
; Clobbers A
;==============================================================
.section "Set VDP reg 2" free
VDP_SetReg2:
	out (VDP_Ctrl),a
	ld a,$82
	out (VDP_Ctrl),a
	ret
.ends

;==============================================================
; Set VDP reg3.
; Clobbers A
;==============================================================
.section "Set VDP reg 3" free
VDP_SetReg3:
	out (VDP_Ctrl),a
	ld a,$83
	out (VDP_Ctrl),a
	ret
.ends

;==============================================================
; Set VDP reg4.
; Clobbers A
;==============================================================
.section "Set VDP reg 4" free
VDP_SetReg4:
	out (VDP_Ctrl),a
	ld a,$84
	out (VDP_Ctrl),a
	ret
.ends

;==============================================================
; Set VDP reg5.
; Clobbers A
;==============================================================
.section "Set VDP reg 5" free
VDP_SetReg5:
	out (VDP_Ctrl),a
	ld a,$85
	out (VDP_Ctrl),a
	ret
.ends

;==============================================================
; Set VDP reg6.
; Clobbers A
;==============================================================
.section "Set VDP reg 6" free
VDP_SetReg6:
	out (VDP_Ctrl),a
	ld a,$86
	out (VDP_Ctrl),a
	ret
.ends

;==============================================================
; Set VDP reg7.
; Clobbers A
;==============================================================
.section "Set VDP reg 7" free
VDP_SetReg7:
	out (VDP_Ctrl),a
	ld a,$87
	out (VDP_Ctrl),a
	ret
.ends

;==============================================================
; Set VDP reg8.
; Clobbers A
;==============================================================
.section "Set VDP reg 8" free
VDP_SetReg8:
	out (VDP_Ctrl),a
	ld a,$88
	out (VDP_Ctrl),a
	ret
.ends

;==============================================================
; Set VDP reg9.
; Clobbers A
;==============================================================
.section "Set VDP reg 9" free
VDP_SetReg9:
	out (VDP_Ctrl),a
	ld a,$89
	out (VDP_Ctrl),a
	ret
.ends

;==============================================================
; Set VDP regA.
; Clobbers A
;==============================================================
.section "Set VDP reg A" free
VDP_SetRegA:
	out (VDP_Ctrl),a
	ld a,$8A
	out (VDP_Ctrl),a
	ret
.ends

;==============================================================
; Wait for button press
;==============================================================
; Clobbers A
; Not very efficient, I'm aiming for simplicity here
;==============================================================
.section "Waiting routines" free
WaitForButton:
-:	in a,(IO_PortA) ; get input
	cpl             ; invert bits
	or a            ; test bits
	jr nz,-         ; wait for no button press
-:	halt
	in a,(IO_PortA) ; get input
	cpl             ; invert bits
	or a            ; see if any are set
	jr z,-
	ret
WaitForNoButton:
-:	in a,(IO_PortA) ; get input
	cpl             ; invert bits
	or a            ; test bits
	jr nz,-         ; wait for no button press
	ret
;==============================================================
; Wait B number of frames.
; B = number of frames.
;==============================================================
WaitForBFrames:
-:	halt
	djnz -
	ret
.ends

;==============================================================
; Write out test results.
; hl = result text.
; a = test result (0 or FF)
;==============================================================
.section "WriteTestResult" free
WriteResult:
	push af
	call StdOut_Write
	pop af				;pop test result
	cp $00
	jr nz,ResErr
	ld hl,ok_text
	jp StdOut_Write
ResErr
	ld hl,error_text
	jp StdOut_Write

WriteResult_VCount:
	push af
	call StdOut_Write
	pop af				;pop test result
	cp $01
	jr nz,VCPALErr
	ld hl,pal_ok_text
	jp StdOut_Write
VCPALErr
	cp $02
	jr nz,VCNTSCErr
	ld hl,ntsc_ok_text
	jp StdOut_Write
VCNTSCErr
	ld hl,error_text
	jp StdOut_Write
.ends


;==============================================================
; Write out test results.
; hl = text.
; de = registervalue
;==============================================================
.section "WriteRegisterValue" free
WriteRegisterValue:
	call StdOut_Write
	ld hl,TEMP_REGISTERS
	ld b,d					;switch de around.
	ld d,e
	ld e,b
	ld (TEMP_REGISTERS),de
	ld b,2					;length chars.
	call StdOut_Write_Hex
	ld a,$0a
	jr StdOut_Char
.ends

;==============================================================
; Save all registers
;==============================================================
.section "save register" free
DumpAllRegisters:
	ld (RegisterArea+$00),sp	;20cyc
	ld (RegisterArea+$06),bc	;20cyc
	ld sp,$DFFE					;10cyc
	push af						;11cyc

	ld a,r						;affects the f-reg
	ld c,a
	ld a,i						;affects the f-reg
	ld b,a

	push af						;11cyc. save V flag for iff2

	ld a,$05					;7cyc. IO ports set to output low
	out (IO_Ctrl),a				;11cyc
	ld a,$FF					;7cyc. flip HL in/out so HCounter gets latched.
	out (IO_Ctrl),a				;11cyc
	in a,(HCounter)				;11cyc
	ld (RegisterArea+$1C),a		;13 cyc

	in a,(VCounter)				;11cyc		113+11 cyc = new raster row.
	ld (RegisterArea+$1A),a		;13cyc
	ld a,$00					;7cyc
	ld (RegisterArea+$19),a		;13cyc
	ld (RegisterArea+$1B),a		;13cyc
	ld (RegisterArea+$1D),a		;13cyc

	ld (RegisterArea+$02),bc	;ir

	pop bc
	ld a,c
	and $04
	ld (RegisterArea+$18),a		;13 cyc, iff2

	pop bc
	ld (RegisterArea+$04),bc	;af
	ld (RegisterArea+$08),de
	ld (RegisterArea+$0A),hl
	ld (RegisterArea+$0C),ix
	ld (RegisterArea+$0E),iy
	ex af,af'
	push af
	pop bc
	ld (RegisterArea+$10),bc	;af'
	ex af,af'
	exx
	ld (RegisterArea+$12),bc	;bc'
	ld (RegisterArea+$14),de	;de'
	ld (RegisterArea+$16),hl	;hl'
	exx

	di				; disable interrupts
	im 1			; Interrupt mode 1

	call VDP_ScreenOff
DumpVRAMToSRAM
	ld a,$08
	ld ($FFFC),a				; Turn on SRAM

	ld hl,$0000|VDP_Mode_Write
	rst $10
	ld b,$FF				;CLear VRAM in Mode4
	ld c,VDP_Data
	ld de,$4000
-:	out (c),b
	dec de
	ld a,d
	or e
	jr nz,-

	ld hl,$0000|VDP_Mode_Write
	rst $10
	ld hl,$0000
	ld c,VDP_Data
	ld de,$2000
-:	out (c),h
	nop
	nop
	out (c),l
	inc hl
	dec de
	ld a,d
	or e
	jr nz,-


;	ld hl,$0000
;	rst $10
;	ld de,$2000
;	ld c,VDP_Data
;	ld hl,$8000
;-:	ini						;Read from port (c), write to (hl)++
;	dec de
;	ld a,d
;	or e
;	jr nz,-

;Dump VRAM in mode5.
	ld hl,$8124				;turn on mode5, VRAM address lines are different.
	rst $10
	ld hl,$8004				;Make sure we get the right palette
	rst $10
	ld hl,$8F01				;Make sure we set the autoincrement
	rst $10

	ld b,$F0
-:	in a,(VDP_Ctrl)
	bit 1,a					; wait for dma to finnish
	jr z,+
	djnz -
+:
	ld hl,$0000
	rst $10
	ld hl,$0000				;VRAM Read
	rst $10
	ld de,$4000
	ld c,VDP_Data
	ld hl,$8000
-:	ini						;Read from port (c), write to (hl)++
	dec de
	ld a,d
	or e
	jr nz,-
;Dump CRAM,
	ld hl,$0001
	rst $10
	ld hl,$0020				;CRAM Read
	rst $10
	ld de,$80
	ld c,VDP_Data
	ld hl,$BF80
-:	ini						;Read from port (c), write to (hl)++
	dec de
	ld a,d
	or e
	jr nz,-

	ld hl,$8F00				;Make sure we set the autoincrement
	rst $10
	ld hl,$8120				;turn off mode5, VRAM address lines are different.
	rst $10
;Dump internal WorkRAM to SRAM bank2.
	ld a,$0C
	ld ($FFFC),a			; Turn on SRAM, bank 2
	ld hl,$C000
	ld de,$8000
	ld bc,$2000
-:	ld a,(hl)
	inc hl
	ld (de),a
	inc de
	dec bc
	ld a,b
	or c
	jr nz,-

	ld a,$B8				;Turn off internal RAM
	out (Mem_Ctrl),a
	ld hl,$C000
	ld bc,$2000
-:	ld a,(hl)
	inc hl
	ld (de),a
	inc de
	dec bc
	ld a,b
	or c
	jr nz,-

	ld a,$A8				;Turn internal RAM back on
	out (Mem_Ctrl),a
	ld a,$00
	ld ($FFFC),a			; Turn off SRAM

;==============================================================
; Write some cubes on the screen to show startup palette
;==============================================================

	call VDP_DefaultInitialise
	call VDP_SpritesOff ; they mess things up

	; Load tiles
	ld de,$4000
	ld hl,chartiles
	call LoadTiles4BitRLENoDI

	; Write some cubes to the tilemap
	call Write_Cubes0_0
	call Write_Cubes0_1
	call VDP_ScreenOn
	ei
	ld b,$80
	call WaitForBFrames
	call VDP_ScreenOff
	di
	jp main					; jump to main program
.ends

;==============================================================
; test1 test
;==============================================================
.section "Tests" free
RunTest1:
	ld hl,NameTableAddress + $600 | VDP_Mode_Write
	call VDP_VRAMToHL
	ld hl,test_data1
	call WriteTestDataToVRAM

	ld hl,NameTableAddress + $600 | VDP_Mode_Read
	call VDP_VRAMToHL
	ld hl,test_data1
	call CompareTestDataToVRAM

	ld (TestResult01),a
	ret

RunTest2:
	ld hl,NameTableAddress + $600 | VDP_Mode_Write
	call VDP_VRAMToHL
	ld hl,test_data2
	call WriteTestDataToVRAM

	ld hl,NameTableAddress + $600 | VDP_Mode_Write
	call VDP_VRAMToHL
	in a,(VDP_Data)
	ld hl,test_data2
	call CompareTestDataToVRAM

	ld (TestResult02),a
	ret

RunTest3:
	ld hl,NameTableAddress + $600 | VDP_Mode_Write
	call VDP_VRAMToHL
	ld hl,test_data1
	call WriteTestDataToVRAM

	ld hl,NameTableAddress + $600 | VDP_Mode_Register
	call VDP_VRAMToHL
	in a,(VDP_Data)
	ld hl,test_data1
	call CompareTestDataToVRAM

	ld (TestResult03),a
	ret

RunTest4:
	ld hl,NameTableAddress + $600 | VDP_Mode_Write
	call VDP_VRAMToHL
	ld hl,test_data2
	call WriteTestDataToVRAM

	ld hl,NameTableAddress + $600 | VDP_Mode_Palette
	call VDP_VRAMToHL
	in a,(VDP_Data)
	ld hl,test_data2
	call CompareTestDataToVRAM

	ld (TestResult04),a
	ret

RunTest5:
	ld hl,NameTableAddress + $5FF | VDP_Mode_Read
	call VDP_VRAMToHL
	ld hl,test_data1
	call WriteTestDataToVRAM

	ld hl,NameTableAddress + $600 | VDP_Mode_Read
	call VDP_VRAMToHL
	ld hl,test_data1
	call CompareTestDataToVRAM

	ld (TestResult05),a
	ret

RunTest6:
	ld hl,NameTableAddress + $600 | VDP_Mode_Register
	call VDP_VRAMToHL
	ld hl,test_data2
	call WriteTestDataToVRAM

	ld hl,NameTableAddress + $600 | VDP_Mode_Read
	call VDP_VRAMToHL
	ld hl,test_data2
	call CompareTestDataToVRAM

	ld (TestResult06),a
	ret

RunTest6_MD:
	ld hl,NameTableAddress + $610 | VDP_Mode_Write
	call VDP_VRAMToHL
	ld hl,test_data3
	call WriteTestDataToVRAM

	ld hl,NameTableAddress + $610 | VDP_Mode_Register
	call VDP_VRAMToHL
	ld hl,test_data4
	call WriteTestDataToVRAM

	ld hl,NameTableAddress + $610 | VDP_Mode_Read
	call VDP_VRAMToHL
	ld hl,test_data3
	call CompareTestDataToVRAM

	ld (TestResult06),a
	ret

RunTest7:
	ld hl,NameTableAddress + $610 | VDP_Mode_Write
	call VDP_VRAMToHL
	ld hl,test_data3
	call WriteTestDataToVRAM

	ld hl,NameTableAddress + $610 | VDP_Mode_Palette
	call VDP_VRAMToHL
	ld hl,test_data4
	call WriteTestDataToVRAM

	ld hl,NameTableAddress + $610 | VDP_Mode_Read
	call VDP_VRAMToHL
	ld hl,test_data3
	call CompareTestDataToVRAM

	ld (TestResult07),a
	ret

RunTest8:
	ld hl,NameTableAddress + $600 | VDP_Mode_Write
	call VDP_VRAMToHL
	ld hl,test_data2
	call WriteTestDataToVRAM

	in a,(VDP_Data)
	in a,(VDP_Data)
	ld hl,test_data1
	call WriteTestDataToVRAM

	ld hl,NameTableAddress + $600 | VDP_Mode_Read
	call VDP_VRAMToHL
	ld hl,test_data2
	call CompareTestDataToVRAM

	ld (TestResult08),a
	cp $00
	ret nz

	in a,(VDP_Data)
	in a,(VDP_Data)
	ld hl,test_data1
	call CompareTestDataToVRAM

	ld (TestResult08),a
	ret

RunTest9:
	ld hl,NameTableAddress + $600 | VDP_Mode_Write
	call VDP_VRAMToHL
	ld hl,test_data1
	call WriteTestDataToVRAM

	ld hl,NameTableAddress + $600 | VDP_Mode_Write
	call VDP_VRAMToHL
	in a,(VDP_Data)
	ld hl,test_data1+15
	cp (hl)
	jr nz,t9_error

	in a,(VDP_Data)
	ld hl,test_data1
	cp (hl)
	jr nz,t9_error

	ld a,$66
	out (VDP_Data),a
	nop
	nop
	ld a,$99
	nop
	nop
	in a,(VDP_Data)
	cp $66
	jr nz,t9_error

	ld a,$00
	ld (TestResult09),a
	ret

t9_error:
	ld a,$FF
	ld (TestResult09),a
	ret

RunTest9_MD:
	ld hl,NameTableAddress + $600 | VDP_Mode_Write
	call VDP_VRAMToHL
	ld hl,test_data1
	call WriteTestDataToVRAM

	ld hl,NameTableAddress + $60F | VDP_Mode_Write
	call VDP_VRAMToHL
	in a,(VDP_Data)
	ld hl,NameTableAddress + $610 | VDP_Mode_Write
	call VDP_VRAMToHL
	ld hl,test_data2
	call WriteTestDataToVRAM
	in a,(VDP_Data)
	ld hl,test_data1+15
	cp (hl)
	jr nz,t9_error_md

	ld hl,NameTableAddress + $600 | VDP_Mode_Write
	call VDP_VRAMToHL
	in a,(VDP_Data)

	ld a,$66
	out (VDP_Data),a
	nop
	nop
	ld a,$99
	nop
	ld hl,test_data1
	in a,(VDP_Data)
	cp (hl)
	jr nz,t9_error_md

	ld a,$00
	ld (TestResult09),a
	ret

t9_error_md:
	ld a,$FF
	ld (TestResult09),a
	ret

RunTest10:
	ld hl,NameTableAddress + $610 | VDP_Mode_Write
	call VDP_VRAMToHL
	ld hl,test_data4
	call WriteTestDataToVRAM

	ld hl,NameTableAddress + $610 | VDP_Mode_Palette
	call VDP_VRAMToHL
	in a,(VDP_Data)
	ld hl,test_data4+15
	cp (hl)
	jr nz,t10_error

	ld a,$77
	out (VDP_Data),a
	nop
	nop
	ld a,$EE
	nop
	nop
	in a,(VDP_Data)
	cp $77
	jr nz,t10_error

	ld a,$BB
	out (VDP_Data),a
	nop
	nop
	ld a,$33
	nop
	nop
	in a,(VDP_Data)
	cp $BB
	jr nz,t10_error

	ld a,$00
	ld (TestResult10),a
	ret

t10_error:
	ld a,$FF
	ld (TestResult10),a
	ret

RunTest10_MD:
	ld hl,NameTableAddress + $600 | VDP_Mode_Write
	call VDP_VRAMToHL
	ld hl,test_data1
	call WriteTestDataToVRAM
	ld hl,test_data4
	call WriteTestDataToVRAM

	ld hl,NameTableAddress + $60F | VDP_Mode_Write
	call VDP_VRAMToHL
	in a,(VDP_Data)
	ld hl,NameTableAddress + $610 | VDP_Mode_Palette
	call VDP_VRAMToHL
	ld hl,test_data2
	call WriteTestDataToVRAM
	in a,(VDP_Data)
	ld hl,test_data1+15
	cp (hl)
	jr nz,t10_error_md

	ld hl,NameTableAddress + $610 | VDP_Mode_Palette
	call VDP_VRAMToHL
	in a,(VDP_Data)

	ld a,$66
	out (VDP_Data),a
	nop
	nop
	ld a,$99
	nop
	ld hl,test_data4
	in a,(VDP_Data)
	cp (hl)
	jr nz,t10_error_md

	ld a,$00
	ld (TestResult10),a
	ret

t10_error_md:
	ld a,$FF
	ld (TestResult10),a
	ret

RunTest11:
	ld hl,NameTableAddress + $600 | VDP_Mode_Write
	call VDP_VRAMToHL
	ld hl,test_data4
	call WriteTestDataToVRAM
	ld hl,test_data1
	call WriteTestDataToVRAM
	ld hl,test_data3
	call WriteTestDataToVRAM
	ld hl,test_data2
	call WriteTestDataToVRAM

	ld hl,NameTableAddress + $658 | VDP_Mode_Read
	call VDP_VRAMToHL

	ld a,$10
	out (VDP_Ctrl),a		;Set low part of address
	in a,(VDP_Data)
	ld hl,test_data1
	call CompareTestDataToVRAM
	ld (TestResult11),a
	cp $00
	ret nz

	ld a,$30
	out (VDP_Ctrl),a		;Set low part of address
	in a,(VDP_Data)
	ld hl,test_data2
	call CompareTestDataToVRAM
	ld (TestResult11),a
	cp $00
	ret nz

	ld a,$20
	out (VDP_Ctrl),a		;Set low part of address
	in a,(VDP_Data)
	ld hl,test_data3
	call CompareTestDataToVRAM
	ld (TestResult11),a
	cp $00
	ret nz

	ld a,$00
	out (VDP_Ctrl),a		;Set low part of address
	in a,(VDP_Data)
	ld hl,test_data4
	call CompareTestDataToVRAM
	ld (TestResult11),a
	ret

RunTest11_MD:
	ld hl,NameTableAddress + $600 | VDP_Mode_Write
	call VDP_VRAMToHL
	ld hl,test_data4
	call WriteTestDataToVRAM
	ld hl,test_data1
	call WriteTestDataToVRAM
	ld hl,test_data3
	call WriteTestDataToVRAM
	ld hl,test_data2
	call WriteTestDataToVRAM

	ld hl,NameTableAddress + $600 | VDP_Mode_Read
	call VDP_VRAMToHL

	ld a,$10
	out (VDP_Ctrl),a		;Set low part of address
	ld hl,test_data4
	call CompareTestDataToVRAM
	ld (TestResult11),a
	cp $00
	ret nz

	ld a,$30
	out (VDP_Ctrl),a		;Set low part of address
	ld hl,test_data1
	call CompareTestDataToVRAM
	ld (TestResult11),a
	cp $00
	ret nz

	ld a,$20
	out (VDP_Ctrl),a		;Set low part of address
	ld hl,test_data3
	call CompareTestDataToVRAM
	ld (TestResult11),a
	cp $00
	ret nz

	ld a,$00
	out (VDP_Ctrl),a		;Set low part of address
	ld hl,test_data2
	call CompareTestDataToVRAM
	ld (TestResult11),a
	ret

RunTest12:
	ld hl,NameTableAddress + $672 | VDP_Mode_Write
	call VDP_VRAMToHL

	ld a,$30
	out (VDP_Ctrl),a		;Set low part of address
	ld hl,test_data4
	call WriteTestDataToVRAM
	ld a,$00
	out (VDP_Ctrl),a		;Set low part of address
	ld hl,test_data1
	call WriteTestDataToVRAM
	ld a,$20
	out (VDP_Ctrl),a		;Set low part of address
	ld hl,test_data3
	call WriteTestDataToVRAM
	ld a,$10
	out (VDP_Ctrl),a		;Set low part of address
	ld hl,test_data2
	call WriteTestDataToVRAM

	ld hl,NameTableAddress + $600 | VDP_Mode_Read
	call VDP_VRAMToHL

	ld hl,test_data1
	call CompareTestDataToVRAM
	ld (TestResult12),a
	cp $00
	ret nz

	ld hl,test_data2
	call CompareTestDataToVRAM
	ld (TestResult12),a
	cp $00
	ret nz

	ld hl,test_data3
	call CompareTestDataToVRAM
	ld (TestResult12),a
	cp $00
	ret nz

	ld hl,test_data4
	call CompareTestDataToVRAM
	ld (TestResult12),a
	ret

RunTest12_MD:
	ld hl,NameTableAddress + $600 | VDP_Mode_Write
	call VDP_VRAMToHL

	ld a,$30
	out (VDP_Ctrl),a		;Set low part of address
	ld hl,test_data1
	call WriteTestDataToVRAM
	ld a,$00
	out (VDP_Ctrl),a		;Set low part of address
	ld hl,test_data2
	call WriteTestDataToVRAM
	ld a,$20
	out (VDP_Ctrl),a		;Set low part of address
	ld hl,test_data3
	call WriteTestDataToVRAM
	ld a,$10
	out (VDP_Ctrl),a		;Set low part of address
	ld hl,test_data4
	call WriteTestDataToVRAM

	ld hl,NameTableAddress + $600 | VDP_Mode_Read
	call VDP_VRAMToHL

	ld hl,test_data1
	call CompareTestDataToVRAM
	ld (TestResult12),a
	cp $00
	ret nz

	ld hl,test_data2
	call CompareTestDataToVRAM
	ld (TestResult12),a
	cp $00
	ret nz

	ld hl,test_data3
	call CompareTestDataToVRAM
	ld (TestResult12),a
	cp $00
	ret nz

	ld hl,test_data4
	call CompareTestDataToVRAM
	ld (TestResult12),a
	ret

RunTest13:
	ld hl,NameTableAddress + $600 | VDP_Mode_Write
	call VDP_VRAMToHL
	ld hl,test_data3
	call WriteTestDataToVRAM
	ld hl,test_data2
	call WriteTestDataToVRAM

	ld hl,NameTableAddress + $610 | VDP_Mode_Palette
	call VDP_VRAMToHL
	ld a,$10
	out (VDP_Ctrl),a
	ld hl,test_data1
	call WriteTestDataToVRAM

	ld hl,NameTableAddress + $600 | VDP_Mode_Read
	call VDP_VRAMToHL
	ld hl,test_data3
	call CompareTestDataToVRAM
	ld (TestResult13),a
	cp $00
	ret nz

	ld hl,test_data2
	call CompareTestDataToVRAM
	ld (TestResult13),a
	ret

RunTest14:
	ld hl,$3FF0 | VDP_Mode_Write
	call VDP_VRAMToHL
	ld hl,test_data1
	call WriteTestDataToVRAM
	ld hl,test_data4
	call WriteTestDataToVRAM

	ld hl,$3FF0 | VDP_Mode_Read
	call VDP_VRAMToHL
	ld hl,test_data1
	call CompareTestDataToVRAM
	ld (TestResult14),a
	cp $00
	ret nz

	ld hl,test_data4
	call CompareTestDataToVRAM
	ld (TestResult14),a
	cp $00
	ret nz

	ld hl,$0000 | VDP_Mode_Read
	call VDP_VRAMToHL
	ld hl,test_data4
	call CompareTestDataToVRAM
	ld (TestResult14),a

	ld hl,$3FF0 | VDP_Mode_Write
	call VDP_VRAMToHL
	ld a,$00
	ld hl,$0020
	call VDP_FillVRAM
	ret

RunTest15:
	ld hl,NameTableAddress + $600 | VDP_Mode_Write
	call VDP_VRAMToHL
	ld hl,test_data3
	call WriteTestDataToVRAM
	ld hl,test_data2
	call WriteTestDataToVRAM
	ld hl,test_data1
	call WriteTestDataToVRAM

	ld hl,NameTableAddress + $600 | VDP_Mode_Read
	call VDP_VRAMToHL
	ld hl,test_data3
	call CompareTestDataToVRAM
	ld (TestResult15),a
	cp $00
	ret nz

	ld hl,NameTableAddress + $610 | VDP_Mode_Palette
	call VDP_VRAMToHL
	ld hl,test_data4
	call WriteTestDataToVRAM

	in a,(VDP_Data)
	ld hl,test_data1
	call CompareTestDataToVRAM
	ld (TestResult15),a
	ret

RunTest16:
	ld hl,NameTableAddress + $600 | VDP_Mode_Write
	call VDP_VRAMToHL
	ld hl,test_data2
	call WriteTestDataToVRAM
	ld hl,test_data3
	call WriteTestDataToVRAM

	ld a,$11
	out (VDP_Ctrl),a		;Set low part of address
	nop
	in a,(VDP_Ctrl)			;Reset latch
	ld hl,NameTableAddress + $600 | VDP_Mode_Read
	call VDP_VRAMToHL
	ld hl,test_data2
	call CompareTestDataToVRAM
	ld (TestResult16),a
	ret

RunTest17:
	ld hl,NameTableAddress + $600 | VDP_Mode_Write
	call VDP_VRAMToHL
	ld hl,test_data4
	call WriteTestDataToVRAM
	ld hl,test_data1
	call WriteTestDataToVRAM

	ld a,$1F
	out (VDP_Ctrl),a		;Set low part of address
	nop
	in a,(VDP_Data)			;Reset latch
	ld hl,NameTableAddress + $600 | VDP_Mode_Read
	call VDP_VRAMToHL
	ld hl,test_data4
	call CompareTestDataToVRAM
	ld (TestResult17),a
	ret

RunTest18:
	ld hl,NameTableAddress + $600 | VDP_Mode_Write
	call VDP_VRAMToHL
	ld hl,test_data1
	call WriteTestDataToVRAM
	ld hl,test_data3
	call WriteTestDataToVRAM

	ld a,$04
	out (VDP_Ctrl),a		;Set low part of address
	nop
	out (VDP_Data),a		;Reset latch
	ld hl,NameTableAddress + $610 | VDP_Mode_Read
	call VDP_VRAMToHL
	ld hl,test_data3
	call CompareTestDataToVRAM
	ld (TestResult18),a
	ret

;==============================================================
RunTest19:
	call SetUnknownRegsToCrap
	ld hl,NameTableAddress + $600 | VDP_Mode_Write
	call VDP_VRAMToHL
	ld hl,test_data1
	call WriteTestDataToVRAM

	call SetUnknownRegsToNormal
	ld hl,NameTableAddress + $600 | VDP_Mode_Read
	call VDP_VRAMToHL
	ld hl,test_data1
	call CompareTestDataToVRAM
	ld (TestResult19),a
	cp $00
	ret nz

	call SetUnknownRegsToNormal
	ld hl,NameTableAddress + $600 | VDP_Mode_Write
	call VDP_VRAMToHL
	ld hl,test_data2
	call WriteTestDataToVRAM

	call SetUnknownRegsToCrap
	ld hl,NameTableAddress + $600 | VDP_Mode_Read
	call VDP_VRAMToHL
	ld hl,test_data2
	call CompareTestDataToVRAM
	ld (TestResult19),a
	ret

SetUnknownRegsToCrap:
	ld hl,$8B04				; mode reg3 = 4
	call VDP_VRAMToHL
	ld hl,$8C04				; mode reg4 = 4
	call VDP_VRAMToHL
	ld hl,$8D04				; hscroll tbl adr = 4
	call VDP_VRAMToHL
	ld hl,$8E04				; unknown = 4
	call VDP_VRAMToHL
	ld hl,$8F04				; autoincrement = 4
	call VDP_VRAMToHL
	ret
SetUnknownRegsToNormal:
	ld hl,$8B00				; mode reg3 = 0
	call VDP_VRAMToHL
	ld hl,$8C00				; mode reg4 = 0
	call VDP_VRAMToHL
	ld hl,$8D00				; hscroll tbl adr = 0
	call VDP_VRAMToHL
	ld hl,$8E00				; unknown = 0
	call VDP_VRAMToHL
	ld hl,$8F01				; autoincrement = 1
	call VDP_VRAMToHL
	ret


;==============================================================
RunTest21:
	ld c,VCounter
	call VCount_Test
	ld (TestResult21),a
	ret
	
VCount_Test
	ld de,320
-:	in a,(c)
	cp $ff
	jr z,saveVertical
	cp b
	jr z,-
	ld b,a
	dec de
	ld a,d
	or e
	jr nz,-

saveVertical:
	ld hl,TestAreaVC
	ld de,313
	ld b,a
-:	in a,(VCounter)			;11 cyc, Read VCounter values
	cp b					;4 cyc
	jr z,-					;12/7 cyc
	ld b,a
	ld (hl),a
	inc hl
	dec de
	ld a,d
	or e
	jr nz,-

checkVertical:
	ld de,313
	ld hl,TestAreaVC
	exx
	ld hl,VCounterValues
	exx
-:	exx
	ld a,(hl)
	inc hl
	exx
	cp (hl)
	jr nz,checkVerticalNTSC
	inc hl
	dec de
	ld a,d
	or e
	jr nz,-

	ld a,$01				; PAL OK
	ret

checkVerticalNTSC:
	exx
	ld hl,VCounterNTSC
	exx
	ld a,e
	sub 51
	ld e,a
-:	exx
	ld a,(hl)
	inc hl
	exx
	cp (hl)
	jr nz,t21_error
	inc hl
	dec de
	ld a,d
	or e
	jr nz,-

	ld a,$02				; NTSC OK
	ret

t21_error:
	ld a,$FF				;VCount Error
	ret

;==============================================================
RunTest22:
	ld b,254
	in a,(HCounter)
	ld d,a
-:	in a,(HCounter)
	cp d
	jr nz,t22_error
	djnz -

	ld a,$00				; OK
	ld (TestResult22),a
	ret

t22_error:
	ld a,$FF				;HCount Error
	ld (TestResult22),a
	ret

;==============================================================
RunTest23:
	ld c,HCounter
	ld b,254
	call Do_hc_test_2
	ld (TestResult23),a
	ret


Do_hc_test_2
	ld a,$05				;IO ports set to output low
	out (IO_Ctrl),a
	in a,(c)
	ld d,a
-:	in a,(c)
	cp d
	jr nz,t23_error
	ld a,$FF				;flip HL in/out so HCounter gets latched.
	out (IO_Ctrl),a
	in a,(c)
	cp d
	jr z,t23_error
	ld d,a
	ld a,$05				;IO ports set to output low
	out (IO_Ctrl),a
	djnz -

	ld a,$00				; OK
	ret

t23_error:
	ld a,$FF				;HCount Error
	ret

;==============================================================
RunTest24:
	ld hl,TestAreaHC
	ld b,232
-:	ld a,$55				;7 cycles
	out (IO_Ctrl),a			;11 cycles
	ld a,$FF				;7 cycles, flip HL in/out so HCounter gets latched.
	out (IO_Ctrl),a			;11 cycles
	in a,(HCounter)			;Read HCounter value, loop 229 cycles
	ld (hl),a
	inc hl

	ld de,($C000)			;20 cycles each
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,$C000				;10 cycles
	dec de					;6 cycles

	djnz -

	ld b,228
	exx
	ld hl,TestAreaHC
	ld a,(hl)
	inc hl
	cp (hl)
	jr z,skip_repeated_value
	dec hl
skip_repeated_value
	exx
	ld hl,HCounterValues-1
-:	inc hl
	cp (hl)
	jr z,+
	djnz -
+:
	inc hl
	cp (hl)
	jr z,skip_repeated_value_2
	dec hl
skip_repeated_value_2

	ld b,229
-:	exx
	ld a,(hl)
	inc hl
	exx
	cp (hl)
	jr nz,t24_error
	inc hl
	djnz -

	ld a,$00
	ld (TestResult24),a
	ret

t24_error:
	ld a,$FF
	ld (TestResult24),a
	ret

;==============================================================
RunTest25:
	in a,(VDP_Ctrl)			;Clear any pending irqs.
	ld hl,$8004				; hblank off
	rst $10
	ei

	ld hl,t25_hblank
	ld (HBL_JUMP),hl
	halt					;wait for vblank
	ld hl,$8A61				; hblank irq on row $61.
	rst $10
	ld hl,$8014				; hblank on
	rst $10
	halt					;wait for hblank done.
	ld hl,$8004				; hblank off
	rst $10

	ld hl,doHBL
	ld (HBL_JUMP),hl

	ld hl,TestScratch
	ld b,(hl)
	inc hl
	ld c,(hl)
	inc hl
	ld a,(hl)
	sub c
	jr nz,t25_error
	ld a,c
	sub b
	cp $01
	jr nz,t25_error

	ld a,$00
	ld (TestResult25),a
	ret
t25_error:
	ld a,$FF
	ld (TestResult25),a
	ret

t25_hblank
	ld hl,$0200				;10cyc.
	ld d,d					;4cyc.
-:
	ld de,($C000)			;20cyc each.
	ld de,($C000)
	ld de,($C000)
	inc de					;6cyc.
	inc de					;6cyc.
	ld a,h					;4cyc.
	or l					;4cyc.
	jr z,+					;12cyc at branch, 7 otherwise
	ld a,$55				;7cyc.
	out (IO_Ctrl),a			;11cyc.
	ld a,$FF				;7cyc. Flip HL in/out so HCounter gets latched.
	out (IO_Ctrl),a			;11cyc. Probably around 0x56
	in a,(HCounter)			;11cyc. Read HCounter value, loop 229 cycles
	dec hl					;6cyc.

	ld de,($C000)			;20cyc each.
	ld de,($C000)
	ld de,($C000)
	ld de,$C000				;10cyc.

	cp $F1					;7cyc.
	jr nz,-					;12cyc at branch, 7 otherwise

	ld de,($C000)			;20cyc each.
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)

	in a,(VCounter)			;11cyc.
	ld (TestScratch),a		;13 cyc
	ld a,a					;4cyc.
	inc hl					;6cyc.
	inc hl					;6cyc.

	in a,(VCounter)			;11cyc. VCount is changed on HCount 0xF4 on SMS. 0xF6 on MD.
	ld (TestScratch+1),a	;13 cyc

	ld de,($C000)			;20cyc each.
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,$C000				;10cyc.
	ld (TestScratch+1),a	;13 cyc. Total 227 cycles. Both reads from VCount should return same value.

	in a,(VCounter)			;11cyc.
	ld (TestScratch+2),a	;13cyc
+:	pop hl						;10cyc
	pop af						;10cyc
	ei							;4cyc
	reti						;14cyc.
;==============================================================
RunTest25_MD:
	in a,(VDP_Ctrl)			;Clear any pending irqs.
	ld hl,$8004				; hblank off
	rst $10
	ei

	ld hl,t25_hblank_md
	ld (HBL_JUMP),hl
	halt					;wait for vblank
	ld hl,$8A61				; hblank irq on row $61.
	rst $10
	ld hl,$8014				; hblank on
	rst $10
	halt					;wait for hblank done.
	ld hl,$8004				; hblank off
	rst $10

	ld hl,doHBL
	ld (HBL_JUMP),hl

	ld hl,TestScratch
	ld b,(hl)
	inc hl
	ld c,(hl)
	inc hl
	ld a,(hl)
	sub c
	jr nz,t25_error_md
	ld a,c
	sub b
	cp $01
	jr nz,t25_error_md

	ld a,$00
	ld (TestResult25),a
	ret
t25_error_md:
	ld a,$FF
	ld (TestResult25),a
	ret

t25_hblank_md
	ld hl,$0200				;10cyc.
	ld d,d					;4cyc.
-:
	ld de,($C000)			;20cyc each.
	ld de,($C000)
	ld de,($C000)
	inc de					;6cyc.
	inc de					;6cyc.
	ld a,h					;4cyc.
	or l					;4cyc.
	jr z,+					;12cyc at branch, 7 otherwise
	ld a,$55				;7cyc.
	out (IO_Ctrl),a			;11cyc.
	ld a,$FF				;7cyc. Flip HL in/out so HCounter gets latched.
	out (IO_Ctrl),a			;11cyc. Probably around 0x56
	in a,(HCounter)			;11cyc. Read HCounter value, loop 229 cycles
	dec hl					;6cyc.

	ld de,($C000)			;20cyc each.
	ld de,($C000)
	ld de,($C000)
	ld de,$C000				;10cyc.

	cp $F1					;7cyc.
	jr nz,-					;12cyc at branch, 7 otherwise

	ld de,($C000)			;20cyc each.
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)

	in a,(VCounter)			;11cyc.
	ld (TestScratch),a		;13 cyc
	ld a,$55				;7cyc.
	inc hl					;6cyc.
	inc hl					;6cyc.

	in a,(VCounter)			;11cyc. VCount is changed on HCount 0xF6 on MD. 0xF4 on SMS.
	ld (TestScratch+1),a	;13 cyc

	ld de,($C000)			;20cyc each.
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,$C000				;10cyc.
	ld (TestScratch+1),a	;13 cyc. Total 227 cycles. Both reads from VCount should return same value.

	in a,(VCounter)			;11cyc.
	ld (TestScratch+2),a	;13cyc
+	pop hl						;10cyc
	pop af						;10cyc
	ei							;4cyc
	reti						;14cyc.
;==============================================================
RunTest26:
	in a,(VDP_Ctrl)			;Clear any pending irqs.
	ei
	halt					;wait for vblank
	ld hl,$8014				; hblank on
	call VDP_VRAMToHL
	ld hl,$8A80				; hblank row $80
	call VDP_VRAMToHL
	ld a,$00
	ld (Timer2),a

	halt					;wait for hblank
	ld hl,$8004				; hblank off
	call VDP_VRAMToHL
	ld a,(Timer2)
	cp $00
	jr z,t26_error
;---------------	
	halt					;wait for vblank
	ld hl,$9014				; hblank on (mirror 1 of reg0)
	call VDP_VRAMToHL
	ld a,$00
	ld (Timer2),a

	halt					;wait for hblank
	ld hl,$8004				; hblank off
	call VDP_VRAMToHL
	ld a,(Timer2)
	cp $00
	jr z,t26_error
;---------------	
	halt					;wait for vblank
	ld hl,$A014				; hblank on (mirror 2 of reg0)
	call VDP_VRAMToHL
	ld a,$00
	ld (Timer2),a

	halt					;wait for hblank
	ld hl,$8004				; hblank off
	call VDP_VRAMToHL
	ld a,(Timer2)
	cp $00
	jr z,t26_error
;---------------	
	halt					;wait for vblank
	ld hl,$B014				; hblank on (mirror 3 of reg0)
	call VDP_VRAMToHL
	ld a,$00
	ld (Timer2),a

	halt					;wait for hblank
	ld hl,$8004				; hblank off
	call VDP_VRAMToHL
	ld a,(Timer2)
	cp $00
	jr z,t26_error
;---------------	

	ld hl,$8AFF				; hblank row $FF
	call VDP_VRAMToHL
	ld a,$00
	ld (TestResult26),a
	di
	ret

t26_error:
	ld hl,$8AFF				; hblank row $FF
	call VDP_VRAMToHL
	ld a,$FF
	ld (TestResult26),a
	di
	ret


RunTest26_MD:
	in a,(VDP_Ctrl)			;Clear any pending irqs.
	ei
	halt					;wait for vblank
	ld hl,$8014				; hblank on
	call VDP_VRAMToHL
	ld hl,$8A80				; hblank row $80
	call VDP_VRAMToHL
	ld a,$00
	ld (Timer2),a

	halt					;wait for hblank
	ld hl,$8004				; hblank off
	call VDP_VRAMToHL
	ld a,(Timer2)
	cp $00
	jr z,t26_error_md
;---------------	
	halt					;wait for vblank
	ld hl,$A014				; hblank on (mirror of reg0)
	call VDP_VRAMToHL
	ld a,$00
	ld (Timer2),a

	halt					;wait for hblank
	ld hl,$8004				; hblank off
	call VDP_VRAMToHL
	ld a,(Timer2)
	cp $00
	jr z,t26_error_md
;---------------	
	halt					;wait for vblank
	ld hl,$9014				; hblank on (not mirror of reg0 on MD)
	call VDP_VRAMToHL
	ld a,$00
	ld (Timer2),a

	halt					;wait for hblank
	ld hl,$8004				; hblank off
	call VDP_VRAMToHL
	ld a,(Timer2)
	cp $00
	jr nz,t26_error_md
;---------------	
	halt					;wait for vblank
	ld hl,$B014				; hblank on (not mirror of reg0 on MD)
	call VDP_VRAMToHL
	ld a,$00
	ld (Timer2),a

	halt					;wait for hblank
	ld hl,$8004				; hblank off
	call VDP_VRAMToHL
	ld a,(Timer2)
	cp $00
	jr nz,t26_error_md
;---------------	


	ld hl,$8AFF				; hblank row $FF
	call VDP_VRAMToHL
	ld a,$00
	ld (TestResult26),a
	di
	ret


t26_error_md:
	ld hl,$8AFF				; hblank row $FF
	call VDP_VRAMToHL
	ld a,$FF
	ld (TestResult26),a
	di
	ret

;==============================================================
RunTest27:
	ld c,$80
-:	call t27_test_vdp_ports
	cp $00
	jr nz,t27_error
	inc c
	inc c
	ld a,c
	cp $BE
	jr nz,-
	ld a,$00
t27_error:
	ld (TestResult27),a
	ret

t27_test_vdp_ports:
	ld hl,NameTableAddress + $600 | VDP_Mode_Write
	call VDP_VRAMToHL
	ld hl,test_data1
	call T27_WriteToVRAM

	ld hl,NameTableAddress + $600 | VDP_Mode_Read
	call VDP_VRAMToHL
	ld hl,test_data1
	call T27_CompareToVRAM
	cp $00
	jr nz,t27_error

	ld hl,NameTableAddress + $600 | VDP_Mode_Write
	call VDP_VRAMToHL
	ld hl,test_data2
	call T27_WriteToVRAM

	ld hl,NameTableAddress + $600 | VDP_Mode_Read
	call VDP_VRAMToHL
	ld hl,test_data2
	call T27_CompareToVRAM
	ret

T27_WriteToVRAM:
	ld b,$10
-:	ld a,(hl)
	out (c),a
	inc hl
	djnz -
	ret

T27_CompareToVRAM:
	ld b,$10
-:	in a,(c)
	cp (hl)
	jr nz,t27_cp_error
	inc hl
	djnz -
	ld a,$00
	ret
t27_cp_error:
	ld a,$FF
	ret

;==============================================================
RunTest28:
	ld c,$81
-:	call t28_test_vdp_ports
	cp $00
	jr nz,t28_error
	inc c
	inc c
	ld a,c
	cp $BF
	jr nz,-
	ld a,$00
	ld (TestResult28),a
	ret

t28_error:
	ld (TestResult28),a
	ret

t28_test_vdp_ports:
	ld hl,NameTableAddress + $600 | VDP_Mode_Write
	call T28_VDP_VRAMToHL
	ld hl,test_data1
	call WriteTestDataToVRAM

	ld hl,NameTableAddress + $600 | VDP_Mode_Read
	call T28_VDP_VRAMToHL
	ld hl,test_data1
	call CompareTestDataToVRAM
	cp $00
	jr nz,t28_error

	ld hl,NameTableAddress + $600 | VDP_Mode_Write
	call T28_VDP_VRAMToHL
	ld hl,test_data2
	call WriteTestDataToVRAM

	ld hl,NameTableAddress + $600 | VDP_Mode_Read
	call T28_VDP_VRAMToHL
	ld hl,test_data2
	call CompareTestDataToVRAM
	ret

T28_VDP_VRAMToHL:
	push af
		ld a,l
		out (c),a
		ld a,h
		out (c),a
	pop af
	ret

;==============================================================
RunTest29:
	ld c,$40
-:	call VCount_Test
	cp $FF
	jr z,t29_error
	inc c
	inc c
	ld a,c
	cp $7E
	jr nz,-
	ld a,$00
t29_error:
	ld (TestResult29),a
	ret

;==============================================================
RunTest30:
	ld c,$41
-:	ld b,127
	call Do_hc_test_2
	cp $00
	jr nz,t30_error
	inc c
	inc c
	ld a,c
	cp $7F
	jr nz,-
	ld a,$00
t30_error:
	ld (TestResult30),a
	ret

;==============================================================
RunTest31:
	ld a,(VCValueVBlank)
	sub $C1
	jr nz,t31_error
	ld (TestResult31),a
	ret
t31_error:
	ld a,$FF
	ld (TestResult31),a
	ret

;==============================================================
RunTest32:						; FrameIRQ HCount value.
;==============================================================
	ld hl,$8004					; hblank off
	rst $10
	in a,(VDP_Ctrl)				;Clear any pending irqs.
;-------------
	ld hl,$0200					;10cyc.
-:
	ld de,($C000)				;20cyc each.
	ld de,($C000)
	ld de,($C000)
	inc de						;6cyc.
	inc de						;6cyc.
	ld a,h						;4cyc.
	or l						;4cyc.
	jr z,+						;12cyc at branch, 7 otherwise
	ld a,$55					;7cyc.
	out (IO_Ctrl),a				;11cyc.
	ld a,$FF					;7cyc. Flip HL in/out so HCounter gets latched.
	out (IO_Ctrl),a				;11cyc. Probably around 0x56
	in a,(HCounter)				;11cyc. Read HCounter value, loop 229 cycles
	dec hl						;6cyc.

	ld de,($C000)				;20cyc each.
	ld de,($C000)
	ld de,($C000)
	ld de,$C000					;10cyc.

	cp $F2						;7cyc. $F1, $F2, $F3
	jr nz,-						;12cyc at branch, 7 otherwise
+:
;-------------
;	ld (TestScratch+1),a		;13cyc. just timing 1cyc delay
;	dec hl						;6 cyc. just timing 2cyc delay
;	ld a,$55					;7 cyc, just timing 3cyc delay
	ei							;4 cyc.

	ld a,$55					;7 cyc
	out (IO_Ctrl),a				;11cyc set HL to low out.
	halt						;wait for vblank
	dec hl						;6 cyc. just timing
	ld a,$FF					;7 cyc
	out (IO_Ctrl),a				;11 cyc, flip HL to high so we latch HC
	di
	in a,(HCounter)
	cp $82						; $7F, $7D, $7D
	jr nz,t32_error				;usigned higher or same


;-------------
	ld hl,$0200					;10cyc.
-:
	ld de,($C000)				;20cyc each.
	ld de,($C000)
	ld de,($C000)
	inc de						;6cyc.
	inc de						;6cyc.
	ld a,h						;4cyc.
	or l						;4cyc.
	jr z,+						;12cyc at branch, 7 otherwise
	ld a,$55					;7cyc.
	out (IO_Ctrl),a				;11cyc.
	ld a,$FF					;7cyc. Flip HL in/out so HCounter gets latched.
	out (IO_Ctrl),a				;11cyc. Probably around 0x56
	in a,(HCounter)				;11cyc. Read HCounter value, loop 229 cycles
	dec hl						;6cyc.

	ld de,($C000)				;20cyc each.
	ld de,($C000)
	ld de,($C000)
	ld de,$C000					;10cyc.

	cp $F1						;7cyc. $F1, $F2, $F3
	jr nz,-						;12cyc at branch, 7 otherwise
+:
;-------------
;	ld (TestScratch+1),a		;13cyc. just timing 1cyc delay
;	dec hl						;6 cyc. just timing 2cyc delay
;	ld a,$55					;7 cyc, just timing 3cyc delay
	ei							;4 cyc.

	ld a,$55					;7 cyc.
	out (IO_Ctrl),a				;set HL to low out.
	halt						;wait for vblank
	dec hl						;6 cyc. just timing
	ld a,$FF					;7 cyc
	out (IO_Ctrl),a				;11 cyc, flip HL to high so we latch HC
	di
	in a,(HCounter)
	cp $84						; $86, $87, $88, $89
	jr nz,t32_error
;-------------
	ld a,$00
	ld (TestResult32),a
	ret
t32_error:
	ld a,$FF
	ld (TestResult32),a
	ret

;==============================================================
RunTest32_MD:
	ld hl,$8004				; hblank off
	rst $10
	in a,(VDP_Ctrl)			;Clear any pending irqs.
;-------------
	ld hl,$0200					;10cyc.
	ld d,d						;4cyc.
-:
	ld de,($C000)				;20cyc each.
	ld de,($C000)
	ld de,($C000)
	inc de						;6cyc.
	inc de						;6cyc.
	ld a,h						;4cyc.
	or l						;4cyc.
	jr z,+						;12cyc at branch, 7 otherwise
	ld a,$55					;7cyc.
	out (IO_Ctrl),a				;11cyc.
	ld a,$FF					;7cyc. Flip HL in/out so HCounter gets latched.
	out (IO_Ctrl),a				;11cyc. Probably around 0x56
	in a,(HCounter)				;11cyc. Read HCounter value, loop 229 cycles
	dec hl						;6cyc.

	ld de,($C000)				;20cyc each.
	ld de,($C000)
	ld de,($C000)
	ld de,$C000					;10cyc.

	cp $F2						;7cyc.
	jr nz,-						;12cyc at branch, 7 otherwise
+:
;-------------
	ei

	ld a,$55
	out (IO_Ctrl),a			;set HL to low out.
	halt					;wait for vblank
	ld a,$FF				;7 cyc
	out (IO_Ctrl),a			;11 cyc, flip HL to high so we latch HC
	di
	in a,(HCounter)
	cp $7F
	jr c,t32_error			;usigned lower
	cp $81
	jr nc,t32_error			;usigned higher or same
	ld a,$00
	ld (TestResult32),a
	ret

;==============================================================
RunTest33:
	in a,(VDP_Ctrl)			;Clear any pending irqs.
	ei

	ld a,$DD
	ld (VCValueHBlank),a	;bogus value
	halt					;wait for vblank
	ld hl,$8A00				; hblank irq every row.
	rst $10
	ld hl,$8014				; hblank on
	rst $10
	halt					;wait for hblank
	di
	ld hl,$8004				; hblank off
	rst $10
	ld a,(VCValueHBlank)
	cp $00
	jr nz,t33_error
	ei

	halt					;wait for vblank
	ld hl,$8014				; hblank on
	rst $10
	ld hl,$8A61				; hblank row $61
	rst $10
	halt					;wait for hblank
	ld hl,$8004				; hblank off
	rst $10
	ld a,(VCValueHBlank)
	cp $61
	jr nz,t33_error

	halt					;wait for vblank
	ld hl,$8014				; hblank on
	rst $10
	ld hl,$8A80				; hblank row $80
	rst $10
	halt					;wait for hblank
	ld hl,$8004				; hblank off
	rst $10
	ld a,(VCValueHBlank)
	cp $80
	jr nz,t33_error

	halt					;wait for vblank
	ld hl,$8014				; hblank on
	rst $10
	ld hl,$8AAF				; hblank row $AF
	rst $10
	halt					;wait for hblank
	ld hl,$8004				; hblank off
	rst $10
	ld a,(VCValueHBlank)
	cp $AF
	jr nz,t33_error

	halt					;wait for vblank
	ld hl,$8014				; hblank on
	rst $10
	ld hl,$8AC0				; hblank row $C0
	rst $10
	halt					;wait for hblank
	ld hl,$8004				; hblank off
	rst $10
	ld a,(VCValueHBlank)
	cp $C0
	jr nz,t33_error

t33_ok:
	ld a,$00
	jr +
t33_error:
	ld a,$FF
+:	ld (TestResult33),a
	ld hl,$8AFF				; hblank row $FF
	rst $10
	di
	ret

;==============================================================
RunTest34:
	ld hl,$8004				; hblank off
	rst $10
	in a,(VDP_Ctrl)			;Clear any pending irqs.
;-------------
	ld hl,$0200					;10cyc.
	ld d,d						;4cyc.
-:
	ld de,($C000)				;20cyc each.
	ld de,($C000)
	ld de,($C000)
	inc de						;6cyc.
	inc de						;6cyc.
	ld a,h						;4cyc.
	or l						;4cyc.
	jr z,+						;12cyc at branch, 7 otherwise
	ld a,$55					;7cyc.
	out (IO_Ctrl),a				;11cyc.
	ld a,$FF					;7cyc. Flip HL in/out so HCounter gets latched.
	out (IO_Ctrl),a				;11cyc. Probably around 0x56
	in a,(HCounter)				;11cyc. Read HCounter value, loop 229 cycles
	dec hl						;6cyc.

	ld de,($C000)				;20cyc each.
	ld de,($C000)
	ld de,($C000)
	ld de,$C000					;10cyc.

	cp $F2						;7cyc.
	jr nz,-						;12cyc at branch, 7 otherwise
+:
;-------------
	ei
	halt						;wait for vblank
	ld a,$55
	out (IO_Ctrl),a				;set HL to low out.
	ld hl,$8014					; hblank on
	rst $10
	ld hl,$8A80					; hblank row $80
	rst $10

	halt						;wait for hblank
	dec hl						;6 cyc. just timing
	ld a,$FF					;7 cyc
	out (IO_Ctrl),a				;11 cyc, flip HL to high so we latch HC
	di
	in a,(HCounter)
	cp $88
	jr nz,t34_error				;usigned higher or same

;-------------
	ld hl,$0200					;10cyc.
	ld d,d						;4cyc.
-:
	ld de,($C000)				;20cyc each.
	ld de,($C000)
	ld de,($C000)
	inc de						;6cyc.
	inc de						;6cyc.
	ld a,h						;4cyc.
	or l						;4cyc.
	jr z,+						;12cyc at branch, 7 otherwise
	ld a,$55					;7cyc.
	out (IO_Ctrl),a				;11cyc.
	ld a,$FF					;7cyc. Flip HL in/out so HCounter gets latched.
	out (IO_Ctrl),a				;11cyc.
	in a,(HCounter)				;11cyc. Read HCounter value, loop 229 cycles
	dec hl						;6cyc.

	ld de,($C000)				;20cyc each.
	ld de,($C000)
	ld de,($C000)
	ld de,$C000					;10cyc.

	cp $F1						;7cyc.
	jr nz,-						;12cyc at branch, 7 otherwise
+:
;-------------
	ei
	halt						;wait for vblank
	ld a,$55
	out (IO_Ctrl),a				;set HL to low out.
	ld hl,$8014					; hblank on
	rst $10
	ld hl,$8A80					; hblank row $80
	rst $10
	halt						;wait for hblank
	dec hl						;6 cyc. just timing
	ld a,$FF					;7 cyc
	out (IO_Ctrl),a				;11 cyc, flip HL to high so we latch HC
	di
	in a,(HCounter)
	cp $8A
	jr nz,t34_error				;usigned higher or same


	ld a,$00
	ld (TestResult34),a
	ret
t34_error:
	ld a,$FF
	ld (TestResult34),a
	ret
;==============================================================
RunTest34_MD:
	ld hl,$8004					; hblank off
	rst $10
	in a,(VDP_Ctrl)				;Clear any pending irqs.
;-------------
	ld hl,$0200					;10cyc.
	ld d,d						;4cyc.
-:
	ld de,($C000)				;20cyc each.
	ld de,($C000)
	ld de,($C000)
	inc de						;6cyc.
	inc de						;6cyc.
	ld a,h						;4cyc.
	or l						;4cyc.
	jr z,+						;12cyc at branch, 7 otherwise
	ld a,$55					;7cyc.
	out (IO_Ctrl),a				;11cyc.
	ld a,$FF					;7cyc. Flip HL in/out so HCounter gets latched.
	out (IO_Ctrl),a				;11cyc. Probably around 0x56
	in a,(HCounter)				;11cyc. Read HCounter value, loop 229 cycles
	dec hl						;6cyc.

	ld de,($C000)				;20cyc each.
	ld de,($C000)
	ld de,($C000)
	ld de,$C000					;10cyc.

	cp $F2						;7cyc.
	jr nz,-						;12cyc at branch, 7 otherwise
+:
;-------------
	ei

	halt						;wait for vblank

	ld a,$55
	out (IO_Ctrl),a				;set HL to low out.
	ld hl,$8014					; hblank on
	rst $10
	ld hl,$8A80					; hblank row $80
	rst $10
	halt						;wait for hblank
	ld a,$FF					;7 cyc
	out (IO_Ctrl),a				;11 cyc, flip HL to high so we latch HC
	di
	in a,(HCounter)
	cp $85
	jr c,t34_error				;usigned lower
	cp $87
	jr nc,t34_error				;usigned higher or same
	ld a,$00
	ld (TestResult34),a
	ret

;==============================================================
RunTest35:
	ld a,$DD				;Bogus
	ld (TestScratch),a
	ld (TestScratch+1),a
	in a,(VDP_Ctrl)			;Clear any pending irqs.
	ld hl,$8004				; hblank off
	rst $10
	ei

	ld hl,t35_hblank0
	ld (HBL_JUMP),hl
	halt					;wait for vblank
	ld hl,$8AB0				; hblank irq on row $B0.
	rst $10
	ld hl,$8014				; hblank on
	rst $10
	halt					;wait for hblank done.
	ld hl,$8004				; hblank off
	rst $10

	ld hl,t35_hblank1
	ld (HBL_JUMP),hl
	halt					;wait for vblank
	ld hl,$8AB0				; hblank irq on row $B0.
	rst $10
	ld hl,$8014				; hblank on
	rst $10
	halt					;wait for hblank done.
	ld hl,$8004				; hblank off
	rst $10

	ld hl,doHBL
	ld (HBL_JUMP),hl

	ld hl,TestScratch
	ld a,(hl)
	cp $00
	jr nz,t35_error
	inc hl
	ld a,(hl)
	cp $00
	jr nz,t35_error

	ld a,$00
	ld (TestResult35),a
	ret
t35_error:
	ld a,$FF
	ld (TestResult35),a
	ret


t35_hblank0
	ld hl,$0200					;10cyc.
	ld d,d						;4cyc.
-:
	ld de,($C000)				;20cyc each.
	ld de,($C000)
	ld de,($C000)
	inc de						;6cyc.
	inc de						;6cyc.
	ld a,h						;4cyc.
	or l						;4cyc.
	jr z,+						;12cyc at branch, 7 otherwise
	ld a,$55					;7cyc.
	out (IO_Ctrl),a				;11cyc.
	ld a,$FF					;7cyc. Flip HL in/out so HCounter gets latched.
	out (IO_Ctrl),a				;11cyc. Probably around 0x56
	in a,(HCounter)				;11cyc. Read HCounter value, loop 229 cycles
	dec hl						;6cyc.

	ld de,($C000)				;20cyc each.
	ld de,($C000)
	ld de,($C000)
	ld de,$C000					;10cyc.

	cp $F1						;7cyc.
	jr nz,-						;12cyc at branch, 7 otherwise

-:
	ld de,($C000)				;20cyc each.
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,$C000					;10cyc.
	ld d,d						;4cyc.
	ld d,d						;4cyc.

	in a,(VCounter)				;11cyc.
	cp $C0						;7cyc.
	jr nz,-						;12cyc at branch, 7 otherwise

	ld de,($C000)				;20cyc
	ld de,($C000)				;20cyc
	ld de,($C000)				;20cyc
	ld de,($C000)				;20cyc
	ld de,($C000)				;20cyc
	ld de,($C000)				;20cyc
	ld d,d						;4cyc.
	in a,(VDP_Ctrl)				;11 cyc, HCount 0xF4, VINT flag not set.
	and $80						;7 cyc
	jr NZ,+						;12/7 cyc
	ld a,$00
	ld (TestScratch),a			;13cyc
+:	pop hl						;10cyc
	pop af						;10cyc
	ei							;4cyc
	reti						;14cyc.

t35_hblank1
	ld hl,$0200					;10cyc.
	ld d,d						;4cyc.
-:
	ld de,($C000)				;20cyc each.
	ld de,($C000)
	ld de,($C000)
	inc de						;6cyc.
	inc de						;6cyc.
	ld a,h						;4cyc.
	or l						;4cyc.
	jr z,+						;12cyc at branch, 7 otherwise
	ld a,$55					;7cyc.
	out (IO_Ctrl),a				;11cyc.
	ld a,$FF					;7cyc. Flip HL in/out so HCounter gets latched.
	out (IO_Ctrl),a				;11cyc. Probably around 0x56
	in a,(HCounter)				;11cyc. Read HCounter value, loop 229 cycles
	dec hl						;6cyc.

	ld de,($C000)				;20cyc each.
	ld de,($C000)
	ld de,($C000)
	ld de,$C000					;10cyc.

	cp $F1						;7cyc.
	jr nz,-						;12cyc at branch, 7 otherwise

-:
	ld de,($C000)				;20cyc each.
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,$C000					;10cyc.
	ld d,d						;4cyc.
	ld d,d						;4cyc.

	in a,(VCounter)				;11cyc.
	cp $C0						;7cyc.
	jr nz,-						;12cyc at branch, 7 otherwise

	ld de,($C000)				;20cyc
	ld de,($C000)				;20cyc
	ld de,($C000)				;20cyc
	ld de,($C000)				;20cyc
	ld de,($C000)				;20cyc
	ld de,$C000					;10cyc.
	ld d,d						;4cyc.
	ld d,d						;4cyc.
	ld a,$00					;7 cyc
	in a,(VDP_Ctrl)				;11 cyc, HCount 0xF5, VINT flag set.
	and $80						;7 cyc
	jr Z,+						;12/7 cyc
	ld a,$00
	ld (TestScratch+1),a		;13cyc
+:	pop hl						;10cyc
	pop af						;10cyc
	ei							;4cyc
	reti						;14cyc.

;==============================================================
RunTest35_MD:
	ld a,$DD				;Bogus
	ld (TestScratch),a
	ld (TestScratch+1),a
	in a,(VDP_Ctrl)			;Clear any pending irqs.
	ld hl,$8004				; hblank off
	rst $10
	ei

	ld hl,t35_hblank0_MD
	ld (HBL_JUMP),hl
	halt					;wait for vblank
	ld hl,$8AB0				; hblank irq on row $B0.
	rst $10
	ld hl,$8014				; hblank on
	rst $10
	halt					;wait for hblank done.
	ld hl,$8004				; hblank off
	rst $10

	ld hl,t35_hblank1_MD
	ld (HBL_JUMP),hl
	halt					;wait for vblank
	ld hl,$8AB0				; hblank irq on row $B0.
	rst $10
	ld hl,$8014				; hblank on
	rst $10
	halt					;wait for hblank done.
	ld hl,$8004				; hblank off
	rst $10

	ld hl,doHBL
	ld (HBL_JUMP),hl

	ld hl,TestScratch
	ld a,(hl)
	cp $00
	jr nz,t35_error_MD
	inc hl
	ld a,(hl)
	cp $00
	jr nz,t35_error_MD

	ld a,$00
	ld (TestResult35),a
	ret
t35_error_MD:
	ld a,$FF
	ld (TestResult35),a
	ret


t35_hblank0_MD
	ld hl,$0200					;10cyc.
	ld d,d						;4cyc.
-:
	ld de,($C000)				;20cyc each.
	ld de,($C000)
	ld de,($C000)
	inc de						;6cyc.
	inc de						;6cyc.
	ld a,h						;4cyc.
	or l						;4cyc.
	jr z,+						;12cyc at branch, 7 otherwise
	ld a,$55					;7cyc.
	out (IO_Ctrl),a				;11cyc.
	ld a,$FF					;7cyc. Flip HL in/out so HCounter gets latched.
	out (IO_Ctrl),a				;11cyc. Probably around 0x56
	in a,(HCounter)				;11cyc. Read HCounter value, loop 229 cycles
	dec hl						;6cyc.

	ld de,($C000)				;20cyc each.
	ld de,($C000)
	ld de,($C000)
	ld de,$C000					;10cyc.

	cp $F1						;7cyc.
	jr nz,-						;12cyc at branch, 7 otherwise

-:
	ld de,($C000)				;20cyc each.
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,$C000					;10cyc.
	ld d,d						;4cyc.
	ld d,d						;4cyc.

	in a,(VCounter)				;11cyc.
	cp $C0						;7cyc.
	jr nz,-						;12cyc at branch, 7 otherwise

	ld de,($C000)				;20cyc
	ld de,($C000)				;20cyc
	ld de,($C000)				;20cyc
	ld de,($C000)				;20cyc
	ld de,($C000)				;20cyc
	ld de,($C000)				;20cyc
	inc hl						;6cyc.
	in a,(VDP_Ctrl)				;11 cyc, HCount first 0xF6, VINT flag not set.
	and $80						;7 cyc
	jr NZ,+						;12/7 cyc
	ld a,$00
	ld (TestScratch),a			;13cyc
+:	pop hl						;10cyc
	pop af						;10cyc
	ei							;4cyc
	reti						;14cyc.

t35_hblank1_MD
	ld hl,$0200					;10cyc.
	ld d,d						;4cyc.
-:
	ld de,($C000)				;20cyc each.
	ld de,($C000)
	ld de,($C000)
	inc de						;6cyc.
	inc de						;6cyc.
	ld a,h						;4cyc.
	or l						;4cyc.
	jr z,+						;12cyc at branch, 7 otherwise
	ld a,$55					;7cyc.
	out (IO_Ctrl),a				;11cyc.
	ld a,$FF					;7cyc. Flip HL in/out so HCounter gets latched.
	out (IO_Ctrl),a				;11cyc. Probably around 0x56
	in a,(HCounter)				;11cyc. Read HCounter value, loop 229 cycles
	dec hl						;6cyc.

	ld de,($C000)				;20cyc each.
	ld de,($C000)
	ld de,($C000)
	ld de,$C000					;10cyc.

	cp $F1						;7cyc.
	jr nz,-						;12cyc at branch, 7 otherwise

-:
	ld de,($C000)				;20cyc each.
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,$C000					;10cyc.
	ld d,d						;4cyc.
	ld d,d						;4cyc.

	in a,(VCounter)				;11cyc.
	cp $C0						;7cyc.
	jr nz,-						;12cyc at branch, 7 otherwise

	ld de,($C000)				;20cyc
	ld de,($C000)				;20cyc
	ld de,($C000)				;20cyc
	ld de,($C000)				;20cyc
	ld de,($C000)				;20cyc
	ld de,($C000)				;20cyc
	ld a,$00					;7 cyc
	in a,(VDP_Ctrl)				;11 cyc, HCount second 0xF6, VINT flag set.
	and $80						;7 cyc
	jr Z,+						;12/7 cyc
	ld a,$00
	ld (TestScratch+1),a		;13cyc
+:	pop hl						;10cyc
	pop af						;10cyc
	ei							;4cyc
	reti						;14cyc.

;==============================================================
RunTest36:
	di							;make sure we don't get any interrupts that read VDP_Ctrl
	in a,(VDP_Ctrl)			;Clear any pending irqs.
	ld hl,$8004				; hblank off
	rst $10
	call VDP_ScreenOn

-:
	in a,(VCounter)				;11cyc.
	cp $B0						;7cyc.
	jr nz,-						;12cyc at branch, 7 otherwise

-:
	in a,(VCounter)				;11cyc.
	cp $10						;7cyc.
	jr nz,-						;12cyc at branch, 7 otherwise

	in a,(VDP_Ctrl)				;read ctrl, check spr collision.
	and $80
	jr z,t36_error

	in a,(VDP_Ctrl)				;read ctrl, collision flag should be clear.
	and $80
	jr nz,t36_error

	ld a,$00
	ld (TestResult36),a
	call VDP_ScreenOff
	ret
t36_error:
	ld a,$FF
	ld (TestResult36),a
	call VDP_ScreenOff
	ret


;==============================================================
RunTest41:
	ld a,$60					;ypos spr0 & spr1
	ld hl,SpriteArea
	ld (hl),a
	inc hl
	ld (hl),a
	ld a,$D0					;ypos spr2, stop
	inc hl
	ld (hl),a

	ld a,$78					;xpos spr0
	ld hl,SpriteArea + $80
	ld (hl),a
	ld a,$41					;attrib spr0
	inc hl
	ld (hl),a
	ld a,$80					;xpos spr1
	inc hl
	ld (hl),a
	ld a,$41					;attrib spr1
	inc hl
	ld (hl),a

	ld hl,SpriteTableAddress | VDP_Mode_Write
	rst $10						;HL to VDP Ctrl
	ld hl,SpriteArea			; data
	ld bc,$100					; size
	call VDP_WriteToVRAM
	call VDP_ScreenOn

-:
	in a,(VCounter)				;11cyc.
	cp $10						;7cyc.
	jr nz,-						;12cyc at branch, 7 otherwise

	in a,(VDP_Ctrl)				;read ctrl, clear bits.

-:
	in a,(VCounter)				;11cyc.
	cp $70						;7cyc.
	jr nz,-						;12cyc at branch, 7 otherwise

	in a,(VDP_Ctrl)				;read ctrl, check spr collision.
	and $20
	jr nz,t41_error

	ld a,$00
	ld (TestResult41),a
	call VDP_ScreenOff
	ret
t41_error:
	ld a,$FF
	ld (TestResult41),a
	call VDP_ScreenOff
	ret

;==============================================================
RunTest42:
	call VDP_ScreenOff
	ld a,$60					;ypos spr0 & spr1
	ld hl,SpriteArea
	ld (hl),a
	inc hl
	ld (hl),a
	ld a,$D0					;ypos spr2, stop
	inc hl
	ld (hl),a

	ld a,$7C					;xpos spr0
	ld hl,SpriteArea + $80
	ld (hl),a
	ld a,$41					;attrib spr0
	inc hl
	ld (hl),a
	ld a,$7C					;xpos spr1
	inc hl
	ld (hl),a
	ld a,$41					;attrib spr1
	inc hl
	ld (hl),a

	ld hl,SpriteTableAddress | VDP_Mode_Write
	rst $10						;HL to VDP Ctrl
	ld hl,SpriteArea			; data
	ld bc,$100					; size
	call VDP_WriteToVRAM

-:
	in a,(VCounter)				;11cyc.
	cp $10						;7cyc.
	jr nz,-						;12cyc at branch, 7 otherwise

	in a,(VDP_Ctrl)				;read ctrl, clear bits.

-:
	in a,(VCounter)				;11cyc.
	cp $70						;7cyc.
	jr nz,-						;12cyc at branch, 7 otherwise

	in a,(VDP_Ctrl)				;read ctrl, check spr collision.
	and $20
	jr nz,t42_error

	ld a,$00
	ld (TestResult42),a
	ret
t42_error:
	ld a,$FF
	ld (TestResult42),a
	ret

;==============================================================
RunTest43:
	call Setup9Sprites
	call VDP_ScreenOn

-:
	in a,(VCounter)				;11cyc.
	cp $10						;7cyc.
	jr nz,-						;12cyc at branch, 7 otherwise

	in a,(VDP_Ctrl)				;read ctrl, clear bits.

-:
	in a,(VCounter)				;11cyc.
	cp $70						;7cyc.
	jr nz,-						;12cyc at branch, 7 otherwise

	in a,(VDP_Ctrl)				;read ctrl, check spr collision.
	and $20
	jr nz,t43_error

	ld a,$00
	ld (TestResult43),a
	call VDP_ScreenOff
	ret
t43_error:
	ld a,$FF
	ld (TestResult43),a
	call VDP_ScreenOff
	ret

;==============================================================
RunTest44:
	ld a,$60					;ypos spr0 & spr1
	ld hl,SpriteArea
	ld (hl),a
	inc hl
	ld (hl),a
	ld a,$D0					;ypos spr2, stop
	inc hl
	ld (hl),a

	ld a,$7C					;xpos spr0
	ld hl,SpriteArea + $80
	ld (hl),a
	ld a,$07					;attrib spr0
	inc hl
	ld (hl),a
	ld a,$7C					;xpos spr1
	inc hl
	ld (hl),a
	ld a,$0E					;attrib spr1
	inc hl
	ld (hl),a

	ld hl,SpriteTableAddress | VDP_Mode_Write
	rst $10						;HL to VDP Ctrl
	ld hl,SpriteArea			; data
	ld bc,$100					; size
	call VDP_WriteToVRAM
	call VDP_ScreenOn

-:
	in a,(VCounter)				;11cyc.
	cp $10						;7cyc.
	jr nz,-						;12cyc at branch, 7 otherwise

	in a,(VDP_Ctrl)				;read ctrl, clear bits.

-:
	in a,(VCounter)				;11cyc.
	cp $70						;7cyc.
	jr nz,-						;12cyc at branch, 7 otherwise

	in a,(VDP_Ctrl)				;read ctrl, check spr collision.
	and $20
	jr nz,t44_error

	ld a,$00
	ld (TestResult44),a
	call VDP_ScreenOff
	ret
t44_error:
	ld a,$FF
	ld (TestResult44),a
	call VDP_ScreenOff
	ret

;==============================================================
RunTest45:					;test sprite collision in Horizontal border (shouldn't happen).
	ld a,$60					;ypos spr0 & spr1
	ld hl,SpriteArea
	ld (hl),a
	inc hl
	ld (hl),a
	inc hl
;	ld (hl),a						;set 2 sprites in the left border as well?
;	inc hl
;	ld (hl),a
;	inc hl
	ld a,$D0					;ypos spr2, stop
	ld (hl),a

	ld a,$FF					;xpos spr0
	ld hl,SpriteArea + $80
	ld (hl),a
	ld a,$5C					;attrib spr0
	inc hl
	ld (hl),a
	ld a,$FF					;xpos spr1
	inc hl
	ld (hl),a
	ld a,$5C					;attrib spr1
	inc hl
	ld (hl),a

	ld hl,SpriteTableAddress | VDP_Mode_Write
	rst $10						;HL to VDP Ctrl
	ld hl,SpriteArea			; data
	ld bc,$100					; size
	call VDP_WriteToVRAM
	call VDP_ScreenOn

-:
	in a,(VCounter)				;11cyc.
	cp $10						;7cyc.
	jr nz,-						;12cyc at branch, 7 otherwise

	in a,(VDP_Ctrl)				;read ctrl, clear bits.

-:
	in a,(VCounter)				;11cyc.
	cp $70						;7cyc.
	jr nz,-						;12cyc at branch, 7 otherwise

	in a,(VDP_Ctrl)				;read ctrl, check spr collision.
	and $20
	jr nz,t45_error

	ld a,$00
	ld (TestResult45),a
	call VDP_ScreenOff
	ret
t45_error:
	ld a,$FF
	ld (TestResult45),a
	call VDP_ScreenOff
	ret

;==============================================================
RunTest46:					;test sprite collision in Vertical border (happens on SMS1).
	ld a,$F0					;ypos spr0 & spr1
	ld hl,SpriteArea
	ld (hl),a
	inc hl
	ld (hl),a
	ld a,$D0					;ypos spr2, stop
	inc hl
	ld (hl),a

	ld a,$7C					;xpos spr0
	ld hl,SpriteArea + $80
	ld (hl),a
	ld a,$41					;attrib spr0
	inc hl
	ld (hl),a
	ld a,$7C					;xpos spr1
	inc hl
	ld (hl),a
	ld a,$41					;attrib spr1
	inc hl
	ld (hl),a

	ld hl,SpriteTableAddress | VDP_Mode_Write
	rst $10						;HL to VDP Ctrl
	ld hl,SpriteArea			; data
	ld bc,$100					; size
	call VDP_WriteToVRAM
	call VDP_ScreenOn
	di

	in a,(VDP_Ctrl)				;read ctrl, clear bits.
-:
	in a,(VCounter)				;11cyc.
	cp $11						;7cyc.
	jr nz,-						;12cyc at branch, 7 otherwise

-:
	in a,(VCounter)				;11cyc.
	cp $10						;7cyc.
	jr nz,-						;12cyc at branch, 7 otherwise

	in a,(VDP_Ctrl)				;read ctrl, check spr collision.
	and $20
	jr z,t46_error

	ld a,$00
	ld (TestResult46),a
	call VDP_ScreenOff
	ret
t46_error:
	ld a,$FF
	ld (TestResult46),a
	call VDP_ScreenOff
	ret

;==============================================================
RunTest46_MD:					;test sprite collision in Vertical border (shouldn't happen on MD).
	ld a,$F0					;ypos spr0 & spr1
	ld hl,SpriteArea
	ld (hl),a
	inc hl
	ld (hl),a
	ld a,$D0					;ypos spr2, stop
	inc hl
	ld (hl),a

	ld a,$7C					;xpos spr0
	ld hl,SpriteArea + $80
	ld (hl),a
	ld a,$41					;attrib spr0
	inc hl
	ld (hl),a
	ld a,$7C					;xpos spr1
	inc hl
	ld (hl),a
	ld a,$41					;attrib spr1
	inc hl
	ld (hl),a

	ld hl,SpriteTableAddress | VDP_Mode_Write
	rst $10						;HL to VDP Ctrl
	ld hl,SpriteArea			; data
	ld bc,$100					; size
	call VDP_WriteToVRAM
	call VDP_ScreenOn
	di

	in a,(VDP_Ctrl)				;read ctrl, clear bits.
-:
	in a,(VCounter)				;11cyc.
	cp $11						;7cyc.
	jr nz,-						;12cyc at branch, 7 otherwise

-:
	in a,(VCounter)				;11cyc.
	cp $10						;7cyc.
	jr nz,-						;12cyc at branch, 7 otherwise

	in a,(VDP_Ctrl)				;read ctrl, check spr collision.
	and $20
	jr nz,t46_error_MD

	ld a,$00
	ld (TestResult46),a
	call VDP_ScreenOff
	ret
t46_error_MD:
	ld a,$FF
	ld (TestResult46),a
	call VDP_ScreenOff
	ret

;==============================================================
RunTest47:					;check collision between spr0 & spr1.
	ld a,$60					;ypos spr0 & spr1
	ld hl,SpriteArea
	ld (hl),a
	inc hl
	ld (hl),a
	ld a,$D0					;ypos spr2, stop
	inc hl
	ld (hl),a

	ld a,$7C					;xpos spr0
	ld hl,SpriteArea + $80
	ld (hl),a
	ld a,$41					;attrib spr0
	inc hl
	ld (hl),a
	ld a,$7C					;xpos spr1
	inc hl
	ld (hl),a
	ld a,$41					;attrib spr1
	inc hl
	ld (hl),a

	ld hl,SpriteTableAddress | VDP_Mode_Write
	rst $10						;HL to VDP Ctrl
	ld hl,SpriteArea			; data
	ld bc,$100					; size
	call VDP_WriteToVRAM
	call VDP_ScreenOn

-:
	in a,(VCounter)				;11cyc.
	cp $08						;7cyc.
	jr nz,-						;12cyc at branch, 7 otherwise

	in a,(VDP_Ctrl)				;read ctrl, clear bits.

-:
	in a,(VCounter)				;11cyc.
	cp $70						;7cyc.
	jr nz,-						;12cyc at branch, 7 otherwise

	in a,(VDP_Ctrl)				;read ctrl, check spr collision.
	and $20
	jr z,t47_error

	ld a,$00
	ld (TestResult47),a
	call VDP_ScreenOff
	ret
t47_error:
	ld a,$FF
	ld (TestResult47),a
	call VDP_ScreenOff
	ret

;==============================================================
RunTest48:					;check collision at line 0 in new frame.
	ld a,$60					;ypos spr0 & spr1
	ld hl,SpriteArea
	ld (hl),a
	inc hl
	ld (hl),a
	ld a,$D0					;ypos spr2, stop
	inc hl
	ld (hl),a

	ld a,$7C					;xpos spr0
	ld hl,SpriteArea + $80
	ld (hl),a
	ld a,$41					;attrib spr0
	inc hl
	ld (hl),a
	ld a,$7C					;xpos spr1
	inc hl
	ld (hl),a
	ld a,$41					;attrib spr1
	inc hl
	ld (hl),a

	ld hl,SpriteTableAddress | VDP_Mode_Write
	rst $10						;HL to VDP Ctrl
	ld hl,SpriteArea			; data
	ld bc,$100					; size
	call VDP_WriteToVRAM
	call VDP_ScreenOn
	di							;make sure we don't get any interrupts that read VDP_Ctrl

-:
	in a,(VCounter)				;11cyc.
	cp $10						;7cyc.
	jr nz,-						;12cyc at branch, 7 otherwise

	in a,(VDP_Ctrl)				;read ctrl, clear bits.

-:
	in a,(VCounter)				;11cyc.
	cp $B0						;7cyc.
	jr nz,-						;12cyc at branch, 7 otherwise

-:
	in a,(VCounter)				;11cyc.
	cp $10						;7cyc.
	jr nz,-						;12cyc at branch, 7 otherwise

	in a,(VDP_Ctrl)				;read ctrl, check spr collision.
	and $20
	jr z,t48_error

	in a,(VDP_Ctrl)				;read ctrl, collision flag should be clear.
	and $20
	jr nz,t48_error

	ld a,$00
	ld (TestResult48),a
	call VDP_ScreenOff
	ret
t48_error:
	ld a,$FF
	ld (TestResult48),a
	call VDP_ScreenOff
	ret

;==============================================================
RunTest49:					;check collision between spr0 & spr1 between a covering tile.
	ld hl,NameTableAddress | VDP_Mode_Write | ((12*32+15)*2)
	rst $10						;HL to VDP Ctrl
	ld a,$5F					;tile number
	out (VDP_Data),a
	ld a,$10					;Prio set
	out (VDP_Data),a

	ld a,$5F					;ypos spr0 & spr1
	ld hl,SpriteArea
	ld (hl),a
	inc hl
	ld (hl),a
	ld a,$D0					;ypos spr2, stop
	inc hl
	ld (hl),a

	ld a,$78					;xpos spr0
	ld hl,SpriteArea + $80
	ld (hl),a
	ld a,$41					;attrib spr0
	inc hl
	ld (hl),a
	ld a,$78					;xpos spr1
	inc hl
	ld (hl),a
	ld a,$41					;attrib spr1
	inc hl
	ld (hl),a

	ld hl,SpriteTableAddress | VDP_Mode_Write
	rst $10						;HL to VDP Ctrl
	ld hl,SpriteArea			; data
	ld bc,$100					; size
	call VDP_WriteToVRAM
	call VDP_ScreenOn

-:
	in a,(VCounter)				;11cyc.
	cp $08						;7cyc.
	jr nz,-						;12cyc at branch, 7 otherwise

	in a,(VDP_Ctrl)				;read ctrl, clear bits.

-:
	in a,(VCounter)				;11cyc.
	cp $B0						;7cyc.
	jr nz,-						;12cyc at branch, 7 otherwise

	in a,(VDP_Ctrl)				;read ctrl, check spr collision.
	and $20
	jr z,t49_error

	ld a,$00
	ld (TestResult49),a
	call VDP_ScreenOff
	ret
t49_error:
	ld a,$FF
	ld (TestResult49),a
	call VDP_ScreenOff
	ret

;==============================================================
RunTest50:					;check collision is on correct line between spr0 & spr1.
	ld a,$60					;ypos spr0 & spr1
	ld hl,SpriteArea
	ld (hl),a
	inc hl
	ld (hl),a
	ld a,$D0					;ypos spr2, stop
	inc hl
	ld (hl),a

	ld a,$7C					;xpos spr0
	ld hl,SpriteArea + $80
	ld (hl),a
	ld a,$21					;attrib spr0
	inc hl
	ld (hl),a
	ld a,$7C					;xpos spr1
	inc hl
	ld (hl),a
	ld a,$21					;attrib spr1
	inc hl
	ld (hl),a

	ld hl,SpriteTableAddress | VDP_Mode_Write
	rst $10						;HL to VDP Ctrl
	ld hl,SpriteArea			; data
	ld bc,$100					; size
	call VDP_WriteToVRAM
	call VDP_ScreenOn

-:
	in a,(VCounter)				;11cyc.
	cp $10						;7cyc.
	jr nz,-						;12cyc at branch, 7 otherwise

	in a,(VDP_Ctrl)				;read ctrl, clear bits.

-:
	in a,(VCounter)				;11cyc.
	cp $60						;7cyc.
	jr nz,-						;12cyc at branch, 7 otherwise

	in a,(VDP_Ctrl)				;read ctrl, collision shouldn't be set yet.
	and $20
	jr nz,t50_error

-:
	in a,(VCounter)				;11cyc.
	cp $62						;7cyc.
	jr nz,-						;12cyc at branch, 7 otherwise

	in a,(VDP_Ctrl)				;read ctrl, collision should be set here.
	and $20
	jr z,t50_error

	ld a,$00
	ld (TestResult50),a
	call VDP_ScreenOff
	ret
t50_error:
	ld a,$FF
	ld (TestResult50),a
	call VDP_ScreenOff
	ret

;==============================================================
RunTest51:					;check collision is set on several line between spr0 & spr1.
	ld a,$60					;ypos spr0 & spr1
	ld hl,SpriteArea
	ld (hl),a
	inc hl
	ld (hl),a
	ld a,$D0					;ypos spr2, stop
	inc hl
	ld (hl),a

	ld a,$7C					;xpos spr0
	ld hl,SpriteArea + $80
	ld (hl),a
	ld a,$21					;attrib spr0
	inc hl
	ld (hl),a
	ld a,$7C					;xpos spr1
	inc hl
	ld (hl),a
	ld a,$21					;attrib spr1
	inc hl
	ld (hl),a

	ld hl,SpriteTableAddress | VDP_Mode_Write
	rst $10						;HL to VDP Ctrl
	ld hl,SpriteArea			; data
	ld bc,$100					; size
	call VDP_WriteToVRAM
	call VDP_ScreenOn

-:
	in a,(VCounter)				;11cyc.
	cp $10						;7cyc.
	jr nz,-						;12cyc at branch, 7 otherwise

	in a,(VDP_Ctrl)				;read ctrl, clear bits.

-:
	in a,(VCounter)				;11cyc.
	cp $60						;7cyc.
	jr nz,-						;12cyc at branch, 7 otherwise

	in a,(VDP_Ctrl)				;read ctrl, collision shouldn't be set yet.
	and $20
	jr nz,t51_error

-:
	in a,(VCounter)				;11cyc.
	cp $62						;7cyc.
	jr nz,-						;12cyc at branch, 7 otherwise

	in a,(VDP_Ctrl)				;read ctrl, collision should be set here.
	and $20
	jr z,t51_error

-:
	in a,(VCounter)				;11cyc.
	cp $64						;7cyc.
	jr nz,-						;12cyc at branch, 7 otherwise

	in a,(VDP_Ctrl)				;read ctrl, collision should be set again.
	and $20
	jr z,t51_error

	ld a,$00
	ld (TestResult51),a
	call VDP_ScreenOff
	ret
t51_error:
	ld a,$FF
	ld (TestResult51),a
	call VDP_ScreenOff
	ret

;==============================================================
RunTest52:					;Check collision HCount between spr0 & spr1.
	ld a,$60					;ypos spr0 & spr1
	ld hl,SpriteArea
	ld (hl),a
	inc hl
	ld (hl),a
	ld a,$D0					;ypos spr2, stop
	inc hl
	ld (hl),a

	ld a,$80					;xpos spr0, this is tweaked to line up with the flag test code.
	ld hl,SpriteArea + $80
	ld (hl),a
	ld a,$5C					;attrib spr0
	inc hl
	ld (hl),a
	ld a,$80					;xpos spr1
	inc hl
	ld (hl),a
	ld a,$5C					;attrib spr1
	inc hl
	ld (hl),a

	ld hl,SpriteTableAddress | VDP_Mode_Write
	rst $10						;HL to VDP Ctrl
	ld hl,SpriteArea			; data
	ld bc,$100					; size
	call VDP_WriteToVRAM
	call VDP_ScreenOn

	ld a,$DD				;Bogus
	ld (TestScratch),a
	ld (TestScratch+1),a
	in a,(VDP_Ctrl)			;Clear any pending irqs.
	ld hl,$8004				; hblank off
	rst $10
	ei

	ld hl,t52_hblank0
	ld (HBL_JUMP),hl
	halt					;wait for vblank
	ld hl,$8A50				; hblank irq on row $50.
	rst $10
	ld hl,$8014				; hblank on
	rst $10
	halt					;wait for hblank done.
	ld hl,$8004				; hblank off
	rst $10

	ld hl,t52_hblank1
	ld (HBL_JUMP),hl
	halt					;wait for vblank
	ld hl,$8A50				; hblank irq on row $50.
	rst $10
	ld hl,$8014				; hblank on
	rst $10
	halt					;wait for hblank done.
	ld hl,$8004				; hblank off
	rst $10

	ld hl,doHBL
	ld (HBL_JUMP),hl

	ld hl,TestScratch
	ld a,(hl)
	cp $00
	jr nz,t52_error
	inc hl
	ld a,(hl)
	cp $00
	jr nz,t52_error

	ld a,$00
	ld (TestResult52),a
	call VDP_ScreenOff
	ret
t52_error:
	ld a,$FF
	ld (TestResult52),a
	call VDP_ScreenOff
	ret


t52_hblank0
	ld hl,$0200					;10cyc.
	ld d,d						;4cyc.
-:
	ld de,($C000)				;20cyc each.
	ld de,($C000)
	ld de,($C000)
	inc de						;6cyc.
	inc de						;6cyc.
	ld a,h						;4cyc.
	or l						;4cyc.
	jr z,+						;12cyc at branch, 7 otherwise
	ld a,$55					;7cyc.
	out (IO_Ctrl),a				;11cyc.
	ld a,$FF					;7cyc. Flip HL in/out so HCounter gets latched.
	out (IO_Ctrl),a				;11cyc. Probably around 0x56
	in a,(HCounter)				;11cyc. Read HCounter value, loop 229 cycles
	dec hl						;6cyc.

	ld de,($C000)				;20cyc each.
	ld de,($C000)
	ld de,($C000)
	ld de,$C000					;10cyc.

	cp $F1						;7cyc.
	jr nz,-						;12cyc at branch, 7 otherwise

-:
	ld de,($C000)				;20cyc each.
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,$C000					;10cyc.
	ld d,d						;4cyc.
	ld d,d						;4cyc.

	in a,(VCounter)				;11cyc.
	cp $61						;7cyc.
	jr nz,-						;12cyc at branch, 7 otherwise

	ld a,$00					;7 cyc
	in a,(VDP_Ctrl)				;11 cyc, HCount first 0x47, COL flag not set.
	and $20						;7 cyc
	jr NZ,+						;12/7 cyc
	ld a,$00
	ld (TestScratch),a			;13cyc
+:	pop hl						;10cyc
	pop af						;10cyc
	ei							;4cyc
	reti						;14cyc.

t52_hblank1
	ld hl,$0200					;10cyc.
	ld d,d						;4cyc.
-:
	ld de,($C000)				;20cyc each.
	ld de,($C000)
	ld de,($C000)
	inc de						;6cyc.
	inc de						;6cyc.
	ld a,h						;4cyc.
	or l						;4cyc.
	jr z,+						;12cyc at branch, 7 otherwise
	ld a,$55					;7cyc.
	out (IO_Ctrl),a				;11cyc.
	ld a,$FF					;7cyc. Flip HL in/out so HCounter gets latched.
	out (IO_Ctrl),a				;11cyc. Probably around 0x56
	in a,(HCounter)				;11cyc. Read HCounter value, loop 229 cycles
	dec hl						;6cyc.

	ld de,($C000)				;20cyc each.
	ld de,($C000)
	ld de,($C000)
	ld de,$C000					;10cyc.

	cp $F1						;7cyc.
	jr nz,-						;12cyc at branch, 7 otherwise

-:
	ld de,($C000)				;20cyc each.
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,$C000					;10cyc.
	ld d,d						;4cyc.
	ld d,d						;4cyc.

	in a,(VCounter)				;11cyc.
	cp $61						;7cyc.
	jr nz,-						;12cyc at branch, 7 otherwise

	ld d,d						;4cyc.
	ld d,d						;4cyc.
	in a,(VDP_Ctrl)				;11 cyc, HCount second 0x47, COL flag set.
	and $20						;7 cyc
	jr Z,+						;12/7 cyc
	ld a,$00
	ld (TestScratch+1),a		;13cyc
+:	pop hl						;10cyc
	pop af						;10cyc
	ei							;4cyc
	reti						;14cyc.

;==============================================================
RunTest52_MD:				;Check collision HCount between spr0 & spr1.
	ld a,$60					;ypos spr0 & spr1
	ld hl,SpriteArea
	ld (hl),a
	inc hl
	ld (hl),a
	ld a,$D0					;ypos spr2, stop
	inc hl
	ld (hl),a

	ld a,$80					;xpos spr0, this is tweaked to line up with the flag test code.
	ld hl,SpriteArea + $80
	ld (hl),a
	ld a,$5C					;attrib spr0
	inc hl
	ld (hl),a
	ld a,$80					;xpos spr1
	inc hl
	ld (hl),a
	ld a,$5C					;attrib spr1
	inc hl
	ld (hl),a

	ld hl,SpriteTableAddress | VDP_Mode_Write
	rst $10						;HL to VDP Ctrl
	ld hl,SpriteArea			; data
	ld bc,$100					; size
	call VDP_WriteToVRAM
	call VDP_ScreenOn

	ld a,$DD					;Bogus
	ld (TestScratch),a
	ld (TestScratch+1),a
	in a,(VDP_Ctrl)				;Clear any pending irqs.
	ld hl,$8004					; hblank off
	rst $10
	ei

	ld hl,t52_hblank0_MD
	ld (HBL_JUMP),hl
	halt						;wait for vblank
	ld hl,$8A50					; hblank irq on row $50.
	rst $10
	ld hl,$8014					; hblank on
	rst $10
	halt						;wait for hblank done.
	ld hl,$8004					; hblank off
	rst $10

	ld hl,t52_hblank1_MD
	ld (HBL_JUMP),hl
	halt						;wait for vblank
	ld hl,$8A50					; hblank irq on row $50.
	rst $10
	ld hl,$8014					; hblank on
	rst $10
	halt						;wait for hblank done.
	ld hl,$8004					; hblank off
	rst $10

	ld hl,doHBL
	ld (HBL_JUMP),hl

	ld hl,TestScratch
	ld a,(hl)
	cp $00
	jr nz,t52_error_MD
	inc hl
	ld a,(hl)
	cp $00
	jr nz,t52_error_MD

	ld a,$00
	ld (TestResult52),a
	call VDP_ScreenOff
	ret
t52_error_MD:
	ld a,$FF
	ld (TestResult52),a
	call VDP_ScreenOff
	ret


t52_hblank0_MD
	ld hl,$0200					;10cyc.
	ld d,d						;4cyc.
-:
	ld de,($C000)				;20cyc each.
	ld de,($C000)
	ld de,($C000)
	inc de						;6cyc.
	inc de						;6cyc.
	ld a,h						;4cyc.
	or l						;4cyc.
	jr z,+						;12cyc at branch, 7 otherwise
	ld a,$55					;7cyc.
	out (IO_Ctrl),a				;11cyc.
	ld a,$FF					;7cyc. Flip HL in/out so HCounter gets latched.
	out (IO_Ctrl),a				;11cyc. Probably around 0x56
	in a,(HCounter)				;11cyc. Read HCounter value, loop 229 cycles
	dec hl						;6cyc.

	ld de,($C000)				;20cyc each.
	ld de,($C000)
	ld de,($C000)
	ld de,$C000					;10cyc.

	cp $F1						;7cyc.
	jr nz,-						;12cyc at branch, 7 otherwise

-:
	ld de,($C000)				;20cyc each.
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,$C000					;10cyc.
	ld d,d						;4cyc.
	ld d,d						;4cyc.

	in a,(VCounter)				;11cyc.
	cp $60						;7cyc.
	jr nz,-						;12cyc at branch, 7 otherwise

	ld de,($C000)				;20cyc
	ld de,($C000)				;20cyc
	ld de,($C000)				;20cyc
	ld de,($C000)				;20cyc
	ld de,($C000)				;20cyc
	ld de,($C000)				;20cyc
	inc hl						;6cyc
	ld a,$00					;7cyc
	in a,(VDP_Ctrl)				;11 cyc, HCount first 0xFE, COL flag not set.
	and $20						;7 cyc
	jr NZ,+						;12/7 cyc
	ld a,$00
	ld (TestScratch),a			;13cyc
+:	pop hl						;10cyc
	pop af						;10cyc
	ei							;4cyc
	reti						;14cyc.

t52_hblank1_MD
	ld hl,$0200					;10cyc.
	ld d,d						;4cyc.
-:
	ld de,($C000)				;20cyc each.
	ld de,($C000)
	ld de,($C000)
	inc de						;6cyc.
	inc de						;6cyc.
	ld a,h						;4cyc.
	or l						;4cyc.
	jr z,+						;12cyc at branch, 7 otherwise
	ld a,$55					;7cyc.
	out (IO_Ctrl),a				;11cyc.
	ld a,$FF					;7cyc. Flip HL in/out so HCounter gets latched.
	out (IO_Ctrl),a				;11cyc. Probably around 0x56
	in a,(HCounter)				;11cyc. Read HCounter value, loop 229 cycles
	dec hl						;6cyc.

	ld de,($C000)				;20cyc each.
	ld de,($C000)
	ld de,($C000)
	ld de,$C000					;10cyc.

	cp $F1						;7cyc.
	jr nz,-						;12cyc at branch, 7 otherwise

-:
	ld de,($C000)				;20cyc each.
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,$C000					;10cyc.
	ld d,d						;4cyc.
	ld d,d						;4cyc.

	in a,(VCounter)				;11cyc.
	cp $60						;7cyc.
	jr nz,-						;12cyc at branch, 7 otherwise

	ld de,($C000)				;20cyc
	ld de,($C000)				;20cyc
	ld de,($C000)				;20cyc
	ld de,($C000)				;20cyc
	ld de,($C000)				;20cyc
	ld de,($C000)				;20cyc
	ld de,$C000					;10cyc
	ld d,d						;4cyc.
	in a,(VDP_Ctrl)				;11 cyc, HCount first 0xFF, COL flag set.
	and $20						;7 cyc
	jr Z,+						;12/7 cyc
	ld a,$00
	ld (TestScratch+1),a		;13cyc
+:	pop hl						;10cyc
	pop af						;10cyc
	ei							;4cyc
	reti						;14cyc.

;==============================================================
RunTest53:					;check sprite overflow with 2 sprites.
	ld a,$60					;ypos spr0 & spr1
	ld hl,SpriteArea
	ld (hl),a
	inc hl
	ld (hl),a
	ld a,$D0					;ypos spr2, stop
	inc hl
	ld (hl),a

	ld a,$78					;xpos spr0
	ld hl,SpriteArea + $80
	ld (hl),a
	ld a,$41					;attrib spr0
	inc hl
	ld (hl),a
	ld a,$80					;xpos spr1
	inc hl
	ld (hl),a
	ld a,$41					;attrib spr1
	inc hl
	ld (hl),a

	ld hl,SpriteTableAddress | VDP_Mode_Write
	rst $10						;HL to VDP Ctrl
	ld hl,SpriteArea			; data
	ld bc,$100					; size
	call VDP_WriteToVRAM
	call VDP_ScreenOn
	di

-:
	in a,(VCounter)				;11cyc.
	cp $10						;7cyc.
	jr nz,-						;12cyc at branch, 7 otherwise

	in a,(VDP_Ctrl)				;read ctrl, clear bits.

-:
	in a,(VCounter)				;11cyc.
	cp $70						;7cyc.
	jr nz,-						;12cyc at branch, 7 otherwise

	in a,(VDP_Ctrl)				;read ctrl, check spr overflow.
	and $40
	jr nz,t53_error

	ld a,$00
	ld (TestResult53),a
	call VDP_ScreenOff
	ret
t53_error:
	ld a,$FF
	ld (TestResult53),a
	call VDP_ScreenOff
	ret

;==============================================================
RunTest54:					; test sprite overflow bit when screen off, happens on my SMS1
	call VDP_ScreenOff
	call Setup9Sprites

-:
	in a,(VCounter)				;11cyc.
	cp $10						;7cyc.
	jr nz,-						;12cyc at branch, 7 otherwise

	in a,(VDP_Ctrl)				;read ctrl, clear bits.

-:
	in a,(VCounter)				;11cyc.
	cp $70						;7cyc.
	jr nz,-						;12cyc at branch, 7 otherwise

	in a,(VDP_Ctrl)				;read ctrl, check spr overflow.
	and $40
	jr z,t54_error

	ld a,$00
	ld (TestResult54),a
	ret
t54_error:
	ld a,$FF
	ld (TestResult54),a
	ret

;==============================================================
RunTest54_MD:					; test sprite overflow bit when screen off, it shouldn't happen.
	call VDP_ScreenOff
	call Setup9Sprites

-:
	in a,(VCounter)				;11cyc.
	cp $10						;7cyc.
	jr nz,-						;12cyc at branch, 7 otherwise

	in a,(VDP_Ctrl)				;read ctrl, clear bits.

-:
	in a,(VCounter)				;11cyc.
	cp $70						;7cyc.
	jr nz,-						;12cyc at branch, 7 otherwise

	in a,(VDP_Ctrl)				;read ctrl, check spr overflow.
	and $40
	jr nz,t54_error_MD

	ld a,$00
	ld (TestResult54),a
	ret
t54_error_MD:
	ld a,$FF
	ld (TestResult54),a
	ret

;==============================================================
RunTest55:					; test sprite overflow bit, when sprites off-screen
	ld a,$F0					;ypos spr0 & spr1
	ld b,$09
	ld hl,SpriteArea
-:
	ld (hl),a
	inc hl
	djnz -

	ld a,$D0					;ypos spr10, stop
	ld (hl),a

	ld de,$4160
	ld hl,SpriteArea + $80
	ld b,$09
-:
	ld a,e						;xpos
	ld (hl),a
	inc hl
	add a,$08
	ld e,a
	ld a,d						;attrib
	ld (hl),a
	inc hl
	djnz -

	ld hl,SpriteTableAddress | VDP_Mode_Write
	rst $10						;HL to VDP Ctrl
	ld hl,SpriteArea			; data
	ld bc,$100					; size
	call VDP_WriteToVRAM
	call VDP_ScreenOn
	di

	in a,(VDP_Ctrl)				;read ctrl, clear bits.
-:
	in a,(VCounter)				;11cyc.
	cp $11						;7cyc.
	jr nz,-						;12cyc at branch, 7 otherwise

-:
	in a,(VCounter)				;11cyc.
	cp $10						;7cyc.
	jr nz,-						;12cyc at branch, 7 otherwise

	in a,(VDP_Ctrl)				;read ctrl, check spr overflow.
	and $40
	jr nz,t55_error

	ld a,$00
	ld (TestResult55),a
	call VDP_ScreenOff
	ret
t55_error:
	ld a,$FF
	ld (TestResult55),a
	call VDP_ScreenOff
	ret

;==============================================================
RunTest56:					; test sprite overflow bit
	call Setup9Sprites
	call VDP_ScreenOn

-:
	in a,(VCounter)				;11cyc.
	cp $10						;7cyc.
	jr nz,-						;12cyc at branch, 7 otherwise

	in a,(VDP_Ctrl)				;read ctrl, clear bits.

-:
	in a,(VCounter)				;11cyc.
	cp $70						;7cyc.
	jr nz,-						;12cyc at branch, 7 otherwise

	in a,(VDP_Ctrl)				;read ctrl, check spr overflow.
	and $40
	jr z,t56_error

	ld a,$00
	ld (TestResult56),a
	call VDP_ScreenOff
	ret
t56_error:
	ld a,$FF
	ld (TestResult56),a
	call VDP_ScreenOff
	ret

;==============================================================
RunTest57:					;check overflow at line 0 in new frame.
	call Setup9Sprites
	call VDP_ScreenOn
	di							;make sure we don't get any interrupts that read VDP_Ctrl

-:
	in a,(VCounter)				;11cyc.
	cp $10						;7cyc.
	jr nz,-						;12cyc at branch, 7 otherwise

	in a,(VDP_Ctrl)				;read ctrl, clear bits.

-:
	in a,(VCounter)				;11cyc.
	cp $B0						;7cyc.
	jr nz,-						;12cyc at branch, 7 otherwise

-:
	in a,(VCounter)				;11cyc.
	cp $10						;7cyc.
	jr nz,-						;12cyc at branch, 7 otherwise

	in a,(VDP_Ctrl)				;read ctrl, check spr overflow.
	and $40
	jr z,t57_error

	in a,(VDP_Ctrl)				;read ctrl, overflow flag should be clear.
	and $40
	jr nz,t57_error

	ld a,$00
	ld (TestResult57),a
	call VDP_ScreenOff
	ret
t57_error:
	ld a,$FF
	ld (TestResult57),a
	call VDP_ScreenOff
	ret

;==============================================================
RunTest58:					;check overflow on correct line.
	call Setup9Sprites
	call VDP_ScreenOn
	di							;make sure we don't get any interrupts that read VDP_Ctrl

-:
	in a,(VCounter)				;11cyc.
	cp $10						;7cyc.
	jr nz,-						;12cyc at branch, 7 otherwise

	in a,(VDP_Ctrl)				;read ctrl, clear bits.

-:
	in a,(VCounter)				;11cyc.
	cp $60						;7cyc.
	jr nz,-						;12cyc at branch, 7 otherwise

	in a,(VDP_Ctrl)				;read ctrl, overflow shouldn't be set yet.
	and $40
	jr nz,t58_error

-:
	in a,(VCounter)				;11cyc.
	cp $61						;7cyc.
	jr nz,-						;12cyc at branch, 7 otherwise

	in a,(VDP_Ctrl)				;read ctrl, overflow should be set here.
	and $40
	jr z,t58_error

	ld a,$00
	ld (TestResult58),a
	call VDP_ScreenOff
	ret
t58_error:
	ld a,$FF
	ld (TestResult58),a
	call VDP_ScreenOff
	ret

;==============================================================
RunTest59:					;check overflow on correct line.
	call Setup9Sprites
	call VDP_ScreenOn
	di							;make sure we don't get any interrupts that read VDP_Ctrl

-:
	in a,(VCounter)				;11cyc.
	cp $10						;7cyc.
	jr nz,-						;12cyc at branch, 7 otherwise

	in a,(VDP_Ctrl)				;read ctrl, clear bits.

-:
	in a,(VCounter)				;11cyc.
	cp $60						;7cyc.
	jr nz,-						;12cyc at branch, 7 otherwise

	in a,(VDP_Ctrl)				;read ctrl, overflow shouldn't be set yet.
	and $40
	jr nz,t59_error

-:
	in a,(VCounter)				;11cyc.
	cp $61						;7cyc.
	jr nz,-						;12cyc at branch, 7 otherwise

	in a,(VDP_Ctrl)				;read ctrl, overflow should be set here.
	and $40
	jr z,t59_error
	in a,(VDP_Ctrl)				;read ctrl, overflow should be set here.
	and $40
	jr nz,t59_error
-:
	in a,(VCounter)				;11cyc.
	cp $62						;7cyc.
	jr nz,-						;12cyc at branch, 7 otherwise

	in a,(VDP_Ctrl)				;read ctrl, overflow should be set here.
	and $40
	jr z,t59_error

	ld a,$00
	ld (TestResult59),a
	call VDP_ScreenOff
	ret
t59_error:
	ld a,$FF
	ld (TestResult59),a
	call VDP_ScreenOff
	ret

;==============================================================
RunTest60:					;Check overflow HCount.
	call Setup9Sprites
	call VDP_ScreenOn

	ld a,$DD				;Bogus
	ld (TestScratch),a
	ld (TestScratch+1),a
	in a,(VDP_Ctrl)			;Clear any pending irqs.
	ld hl,$8004				; hblank off
	rst $10
	ei

	ld hl,t60_hblank0
	ld (HBL_JUMP),hl
	halt					;wait for vblank
	ld hl,$8A50				; hblank irq on row $50.
	rst $10
	ld hl,$8014				; hblank on
	rst $10
	halt					;wait for hblank done.
	ld hl,$8004				; hblank off
	rst $10

	ld hl,t60_hblank1
	ld (HBL_JUMP),hl
	halt					;wait for vblank
	ld hl,$8A50				; hblank irq on row $50.
	rst $10
	ld hl,$8014				; hblank on
	rst $10
	halt					;wait for hblank done.
	ld hl,$8004				; hblank off
	rst $10

	ld hl,doHBL
	ld (HBL_JUMP),hl

	ld hl,TestScratch
	ld a,(hl)
	cp $00
	jr nz,t60_error
	inc hl
	ld a,(hl)
	cp $00
	jr nz,t60_error

	ld a,$00
	ld (TestResult60),a
	call VDP_ScreenOff
	ret
t60_error:
	ld a,$FF
	ld (TestResult60),a
	call VDP_ScreenOff
	ret


t60_hblank0
	ld hl,$0200					;10cyc.
	ld d,d						;4cyc.
-:
	ld de,($C000)				;20cyc each.
	ld de,($C000)
	ld de,($C000)
	inc de						;6cyc.
	inc de						;6cyc.
	ld a,h						;4cyc.
	or l						;4cyc.
	jr z,+						;12cyc at branch, 7 otherwise
	ld a,$55					;7cyc.
	out (IO_Ctrl),a				;11cyc.
	ld a,$FF					;7cyc. Flip HL in/out so HCounter gets latched.
	out (IO_Ctrl),a				;11cyc. Probably around 0x56
	in a,(HCounter)				;11cyc. Read HCounter value, loop 229 cycles
	dec hl						;6cyc.

	ld de,($C000)				;20cyc each.
	ld de,($C000)
	ld de,($C000)
	ld de,$C000					;10cyc.

	cp $F1						;7cyc.
	jr nz,-						;12cyc at branch, 7 otherwise

-:
	ld de,($C000)				;20cyc each.
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,$C000					;10cyc.
	ld d,d						;4cyc.
	ld d,d						;4cyc.

	in a,(VCounter)				;11cyc.
	cp $60						;7cyc.
	jr nz,-						;12cyc at branch, 7 otherwise

	ld de,($C000)				;20cyc
	ld de,($C000)				;20cyc
	ld de,($C000)				;20cyc
	ld de,($C000)				;20cyc
	ld de,($C000)				;20cyc
	ld de,($C000)				;20cyc
	ld d,d						;4cyc.
	in a,(VDP_Ctrl)				;11 cyc, HCount 0xF4, OVR flag not set.
	and $40						;7 cyc
	jr NZ,+						;12/7 cyc
	ld a,$00
	ld (TestScratch),a			;13cyc
+:	pop hl						;10cyc
	pop af						;10cyc
	ei							;4cyc
	reti						;14cyc.

t60_hblank1
	ld hl,$0200					;10cyc.
	ld d,d						;4cyc.
-:
	ld de,($C000)				;20cyc each.
	ld de,($C000)
	ld de,($C000)
	inc de						;6cyc.
	inc de						;6cyc.
	ld a,h						;4cyc.
	or l						;4cyc.
	jr z,+						;12cyc at branch, 7 otherwise
	ld a,$55					;7cyc.
	out (IO_Ctrl),a				;11cyc.
	ld a,$FF					;7cyc. Flip HL in/out so HCounter gets latched.
	out (IO_Ctrl),a				;11cyc. Probably around 0x56
	in a,(HCounter)				;11cyc. Read HCounter value, loop 229 cycles
	dec hl						;6cyc.

	ld de,($C000)				;20cyc each.
	ld de,($C000)
	ld de,($C000)
	ld de,$C000					;10cyc.

	cp $F1						;7cyc.
	jr nz,-						;12cyc at branch, 7 otherwise

-:
	ld de,($C000)				;20cyc each.
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,$C000					;10cyc.
	ld d,d						;4cyc.
	ld d,d						;4cyc.

	in a,(VCounter)				;11cyc.
	cp $60						;7cyc.
	jr nz,-						;12cyc at branch, 7 otherwise

	ld de,($C000)				;20cyc
	ld de,($C000)				;20cyc
	ld de,($C000)				;20cyc
	ld de,($C000)				;20cyc
	ld de,($C000)				;20cyc
	ld de,$C000					;10cyc.
	ld d,d						;4cyc.
	ld d,d						;4cyc.
	ld a,$00					;7 cyc
	in a,(VDP_Ctrl)				;11 cyc, HCount 0xF5, OVR flag set.
	and $40						;7 cyc
	jr Z,+						;12/7 cyc
	ld a,$00
	ld (TestScratch+1),a		;13cyc
+:	pop hl						;10cyc
	pop af						;10cyc
	ei							;4cyc
	reti						;14cyc.

;==============================================================
RunTest60_MD:				;Check overflow HCount.
	call Setup9Sprites
	call VDP_ScreenOn

	ld a,$DD					;Bogus
	ld (TestScratch),a
	ld (TestScratch+1),a
	in a,(VDP_Ctrl)				;Clear any pending irqs.
	ld hl,$8004					; hblank off
	rst $10
	ei

	ld hl,t60_hblank0_MD
	ld (HBL_JUMP),hl
	halt						;wait for vblank
	ld hl,$8A50					; hblank irq on row $50.
	rst $10
	ld hl,$8014					; hblank on
	rst $10
	halt						;wait for hblank done.
	ld hl,$8004					; hblank off
	rst $10

	ld hl,t60_hblank1_MD
	ld (HBL_JUMP),hl
	halt						;wait for vblank
	ld hl,$8A50					; hblank irq on row $50.
	rst $10
	ld hl,$8014					; hblank on
	rst $10
	halt						;wait for hblank done.
	ld hl,$8004					; hblank off
	rst $10

	ld hl,doHBL
	ld (HBL_JUMP),hl

	ld hl,TestScratch
	ld a,(hl)
	cp $00
	jr nz,t60_error_MD
	inc hl
	ld a,(hl)
	cp $00
	jr nz,t60_error_MD

	ld a,$00
	ld (TestResult60),a
	call VDP_ScreenOff
	ret
t60_error_MD:
	ld a,$FF
	ld (TestResult60),a
	call VDP_ScreenOff
	ret


t60_hblank0_MD
	ld hl,$0200					;10cyc.
	ld d,d						;4cyc.
-:
	ld de,($C000)				;20cyc each.
	ld de,($C000)
	ld de,($C000)
	inc de						;6cyc.
	inc de						;6cyc.
	ld a,h						;4cyc.
	or l						;4cyc.
	jr z,+						;12cyc at branch, 7 otherwise
	ld a,$55					;7cyc.
	out (IO_Ctrl),a				;11cyc.
	ld a,$FF					;7cyc. Flip HL in/out so HCounter gets latched.
	out (IO_Ctrl),a				;11cyc. Probably around 0x56
	in a,(HCounter)				;11cyc. Read HCounter value, loop 229 cycles
	dec hl						;6cyc.

	ld de,($C000)				;20cyc each.
	ld de,($C000)
	ld de,($C000)
	ld de,$C000					;10cyc.

	cp $F1						;7cyc.
	jr nz,-						;12cyc at branch, 7 otherwise

-:
	ld de,($C000)				;20cyc each.
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,$C000					;10cyc.
	ld d,d						;4cyc.
	ld d,d						;4cyc.

	in a,(VCounter)				;11cyc.
	cp $60						;7cyc.
	jr nz,-						;12cyc at branch, 7 otherwise

	ld de,($C000)				;20cyc
	ld de,($C000)				;20cyc
	ld de,($C000)				;20cyc
	ld de,($C000)				;20cyc
	ld de,($C000)				;20cyc
	ld de,($C000)				;20cyc
	inc hl						;6cyc.
	in a,(VDP_Ctrl)				;11 cyc, HCount first 0xF6, OVR flag not set.
	and $40						;7 cyc
	jr NZ,+						;12/7 cyc
	ld a,$00
	ld (TestScratch),a			;13cyc
+:	pop hl						;10cyc
	pop af						;10cyc
	ei							;4cyc
	reti						;14cyc.

t60_hblank1_MD
	ld hl,$0200					;10cyc.
	ld d,d						;4cyc.
-:
	ld de,($C000)				;20cyc each.
	ld de,($C000)
	ld de,($C000)
	inc de						;6cyc.
	inc de						;6cyc.
	ld a,h						;4cyc.
	or l						;4cyc.
	jr z,+						;12cyc at branch, 7 otherwise
	ld a,$55					;7cyc.
	out (IO_Ctrl),a				;11cyc.
	ld a,$FF					;7cyc. Flip HL in/out so HCounter gets latched.
	out (IO_Ctrl),a				;11cyc. Probably around 0x56
	in a,(HCounter)				;11cyc. Read HCounter value, loop 229 cycles
	dec hl						;6cyc.

	ld de,($C000)				;20cyc each.
	ld de,($C000)
	ld de,($C000)
	ld de,$C000					;10cyc.

	cp $F1						;7cyc.
	jr nz,-						;12cyc at branch, 7 otherwise

-:
	ld de,($C000)				;20cyc each.
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,$C000					;10cyc.
	ld d,d						;4cyc.
	ld d,d						;4cyc.

	in a,(VCounter)				;11cyc.
	cp $60						;7cyc.
	jr nz,-						;12cyc at branch, 7 otherwise

	ld de,($C000)				;20cyc
	ld de,($C000)				;20cyc
	ld de,($C000)				;20cyc
	ld de,($C000)				;20cyc
	ld de,($C000)				;20cyc
	ld de,($C000)				;20cyc
	ld a,$00					;7 cyc
	in a,(VDP_Ctrl)				;11 cyc, HCount second 0xF6, OVR flag set.
	and $40						;7 cyc
	jr Z,+						;12/7 cyc
	ld a,$00
	ld (TestScratch+1),a		;13cyc
+:	pop hl						;10cyc
	pop af						;10cyc
	ei							;4cyc
	reti						;14cyc.


;==============================================================
RunTest90:					;Show xscroll latch time.
	di							; disable interrupts
	call VDP_ScreenOff
	call StdOut_Cls
	ld hl,column1_text
	call StdOut_Write


	in a,(VDP_Ctrl)				;Clear any pending irqs.
	ld hl,$8004					;hblank off
	rst $10

	ld hl,t90_hblank0
	ld (HBL_JUMP),hl
	ld hl,$8A61					; hblank irq on row $61.
	rst $10
	ld hl,$8014					; hblank on
	rst $10
	ei

	call VDP_ScreenOn
	call WaitForButton

	ld hl,$8004					;hblank off
	rst $10
	ld hl,doHBL
	ld (HBL_JUMP),hl

	call VDP_ScreenOff
	ret


t90_hblank0
	ld hl,$0200					;10cyc.
	ld d,d						;4cyc.
-:
	ld de,($C000)				;20cyc each.
	ld de,($C000)
	ld de,($C000)
	inc de						;6cyc.
	inc de						;6cyc.
	ld a,h						;4cyc.
	or l						;4cyc.
	jr z,+						;12cyc at branch, 7 otherwise
	ld a,$55					;7cyc.
	out (IO_Ctrl),a				;11cyc.
	ld a,$FF					;7cyc. Flip HL in/out so HCounter gets latched.
	out (IO_Ctrl),a				;11cyc. Probably around 0x56
	in a,(HCounter)				;11cyc. Read HCounter value, loop 229 cycles
	dec hl						;6cyc.

	ld de,($C000)				;20cyc each.
	ld de,($C000)
	ld de,($C000)
	ld de,$C000					;10cyc.

	cp $F1						;7cyc.
	jr nz,-						;12cyc at branch, 7 otherwise
+:
-:
	ld de,($C000)				;20cyc each.
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,$C000					;10cyc.
	ld d,d						;4cyc.
	ld d,d						;4cyc.

	in a,(VCounter)				;11cyc.
	cp $6F						;7cyc.
	jr nz,-						;12cyc at branch, 7 otherwise

	ld de,($C000)				;20cyc
	ld de,($C000)				;20cyc
	ld de,($C000)				;20cyc
	ld de,($C000)				;20cyc
	in a,(VDP_Ctrl)				;11cyc
	ld d,d						;4cyc
	ld d,d						;4cyc
	ld a,$80					;7cyc. Scroll X value
	out (VDP_Ctrl),a			;11 cyc
	ld a,$88					;7cyc. Scroll X register
	out (VDP_Ctrl),a			;11 cyc, HCount second 0xF3, cycle after latch.

	ld de,($C000)				;20cyc
	ld de,($C000)				;20cyc
	ld de,($C000)				;20cyc
	ld de,($C000)				;20cyc
	ld de,($C000)				;20cyc
	ld de,($C000)				;20cyc
	ld de,($C000)				;20cyc
	ld de,($C000)				;20cyc
	ld de,($C000)				;20cyc
	in a,(VDP_Ctrl)				;11 cyc
	ld a,$00					;7cyc. Scroll X value
	out (VDP_Ctrl),a			;11 cyc
	ld a,$88					;7cyc. Scroll X register
	out (VDP_Ctrl),a			;11 cyc, HCount first 0xF3, cycle before latch.

	pop hl						;10cyc
	pop af						;10cyc
	ei							;4cyc
	reti						;14cyc.

;==============================================================
RunTest91:					;Show nametable latch time.
; NOT WORKING! NameTables are updated through out the scanline.
;==============================================================
	di							; disable interrupts
	call VDP_ScreenOff
	call StdOut_Cls
	ld hl,column2_text
	call StdOut_Write


	in a,(VDP_Ctrl)				;Clear any pending irqs.
	ld hl,$8004					;hblank off
	rst $10

	ld hl,t91_hblank0
	ld (HBL_JUMP),hl
	ld hl,$8A61					; hblank irq on row $61.
	rst $10
	ld hl,$8014					; hblank on
	rst $10
	ei

	call VDP_ScreenOn
	call WaitForButton

	ld hl,$8004					;hblank off
	rst $10
	ld hl,doHBL
	ld (HBL_JUMP),hl

	call VDP_ScreenOff
	ret


t91_hblank0
	ld hl,$0200					;10cyc.
	ld d,d						;4cyc.
-:
	ld de,($C000)				;20cyc each.
	ld de,($C000)
	ld de,($C000)
	inc de						;6cyc.
	inc de						;6cyc.
	ld a,h						;4cyc.
	or l						;4cyc.
	jr z,+						;12cyc at branch, 7 otherwise
	ld a,$55					;7cyc.
	out (IO_Ctrl),a				;11cyc.
	ld a,$FF					;7cyc. Flip HL in/out so HCounter gets latched.
	out (IO_Ctrl),a				;11cyc. Probably around 0x56
	in a,(HCounter)				;11cyc. Read HCounter value, loop 229 cycles
	dec hl						;6cyc.

	ld de,($C000)				;20cyc each.
	ld de,($C000)
	ld de,($C000)
	ld de,$C000					;10cyc.

	cp $F1						;7cyc.
	jr nz,-						;12cyc at branch, 7 otherwise
+:
-:
	ld de,($C000)				;20cyc each.
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,$C000					;10cyc.
	ld d,d						;4cyc.
	ld d,d						;4cyc.

	in a,(VCounter)				;11cyc.
	cp $6F						;7cyc.
	jr nz,-						;12cyc at branch, 7 otherwise

	ld de,($C000)				;20cyc
	ld de,($C000)				;20cyc
	ld de,($C000)				;20cyc
	ld de,($C000)				;20cyc
	ld de,($C000)				;20cyc extra
	in a,(VDP_Ctrl)				;11cyc
	ld d,d						;4cyc
	ld d,d						;4cyc
	ld d,d						;4cyc
	ld d,d						;4cyc extra
	ld d,d						;4cyc extra
;	ld a,$03					;7cyc. NameTableBase value
	ld a,$03					;7cyc. NameTableBase value
	out (VDP_Ctrl),a			;11 cyc
	ld a,$82					;7cyc. NameTableBase register
	out (VDP_Ctrl),a			;11 cyc, HCount second 0xF3, cycle after latch.

	ld de,($C000)				;20cyc
	ld de,($C000)				;20cyc
	ld de,($C000)				;20cyc
	ld de,($C000)				;20cyc
	ld de,($C000)				;20cyc
	ld de,($C000)				;20cyc
	ld de,($C000)				;20cyc
	ld de,($C000)				;20cyc
	ld de,($C000)				;20cyc
	in a,(VDP_Ctrl)				;11 cyc
	ld a,$0F					;7cyc. NameTableBase value
	out (VDP_Ctrl),a			;11 cyc
	ld a,$82					;7cyc. NameTableBase register
	out (VDP_Ctrl),a			;11 cyc, HCount first 0xF3, cycle before latch.

	pop hl						;10cyc
	pop af						;10cyc
	ei							;4cyc
	reti						;14cyc.

;==============================================================
RunTest92:					;Show spriteattributetable latch time.
	di							; disable interrupts
	call VDP_ScreenOff
	call StdOut_Cls
	ld hl,column3_text
	call StdOut_Write
	call SetupSpriteColumn
	; Load palette
	ld hl,$c010						; palette index 16 write address
	call VDP_VRAMToHL
	ld hl,charpalette				; data
	ld bc,16						; size
	call VDP_WriteToVRAM


	in a,(VDP_Ctrl)				;Clear any pending irqs.
	ld hl,$8004					;hblank off
	rst $10

	ld hl,$8603					; sprite tile selection
	rst $10

	ld hl,t92_hblank0
	ld (HBL_JUMP),hl
	ld hl,$8A61					; hblank irq on row $61.
	rst $10
	ld hl,$8014					; hblank on
	rst $10
	ei

	call VDP_ScreenOn
	call WaitForButton

	ld hl,$8004					;hblank off
	rst $10
	ld hl,doHBL
	ld (HBL_JUMP),hl

	call VDP_ScreenOff
	ret


t92_hblank0
	ld hl,$0200					;10cyc.
	ld d,d						;4cyc.
-:
	ld de,($C000)				;20cyc each.
	ld de,($C000)
	ld de,($C000)
	inc de						;6cyc.
	inc de						;6cyc.
	ld a,h						;4cyc.
	or l						;4cyc.
	jr z,+						;12cyc at branch, 7 otherwise
	ld a,$55					;7cyc.
	out (IO_Ctrl),a				;11cyc.
	ld a,$FF					;7cyc. Flip HL in/out so HCounter gets latched.
	out (IO_Ctrl),a				;11cyc. Probably around 0x56
	in a,(HCounter)				;11cyc. Read HCounter value, loop 229 cycles
	dec hl						;6cyc.

	ld de,($C000)				;20cyc each.
	ld de,($C000)
	ld de,($C000)
	ld de,$C000					;10cyc.

	cp $F1						;7cyc.
	jr nz,-						;12cyc at branch, 7 otherwise
+:
-:
	ld de,($C000)				;20cyc each.
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,$C000					;10cyc.
	ld d,d						;4cyc.
	ld d,d						;4cyc.

	in a,(VCounter)				;11cyc.
	cp $6F						;7cyc.
	jr nz,-						;12cyc at branch, 7 otherwise

	ld de,($C000)				;20cyc
	ld de,($C000)				;20cyc
	ld de,($C000)				;20cyc
	ld de,($C000)				;20cyc
	in a,(VDP_Ctrl)				;11cyc
	ld d,d						;4cyc
	ld d,d						;4cyc
	ld a,$03					;7cyc. SpriteTableBase value
	out (VDP_Ctrl),a			;11 cyc
	ld a,$85					;7cyc. SpriteTableBase register
	out (VDP_Ctrl),a			;11 cyc, HCount second 0xF3, cycle after latch.

	ld de,($C000)				;20cyc
	ld de,($C000)				;20cyc
	ld de,($C000)				;20cyc
	ld de,($C000)				;20cyc
	ld de,($C000)				;20cyc
	ld de,($C000)				;20cyc
	ld de,($C000)				;20cyc
	ld de,($C000)				;20cyc
	ld de,($C000)				;20cyc
	in a,(VDP_Ctrl)				;11 cyc
	ld a,$7F					;7cyc. SpriteTableBase value
	out (VDP_Ctrl),a			;11 cyc
	ld a,$85					;7cyc. SpriteTableBase register
	out (VDP_Ctrl),a			;11 cyc, HCount first 0xF3, cycle before latch.

	pop hl						;10cyc
	pop af						;10cyc
	ei							;4cyc
	reti						;14cyc.

;==============================================================
RunTest93:					;Show SpriteTileOffset latch time.
	di							; disable interrupts
	call VDP_ScreenOff
	call StdOut_Cls
	ld hl,column4_text
	call StdOut_Write
	call SetupSpriteColumn
	; Load palette
	ld hl,$c010						; palette index 16 write address
	call VDP_VRAMToHL
	ld hl,charpalette				; data
	ld bc,16						; size
	call VDP_WriteToVRAM


	in a,(VDP_Ctrl)				;Clear any pending irqs.
	ld hl,$8004					;hblank off
	rst $10

	ld hl,t92_hblank0
	ld (HBL_JUMP),hl
	ld hl,$8A61					; hblank irq on row $61.
	rst $10
	ld hl,$8014					; hblank on
	rst $10
	ei

	call VDP_ScreenOn
	call WaitForButton

	ld hl,$8004					;hblank off
	rst $10
	ld hl,doHBL
	ld (HBL_JUMP),hl

	call VDP_ScreenOff
	ret


t93_hblank0
	ld hl,$0200					;10cyc.
	ld d,d						;4cyc.
-:
	ld de,($C000)				;20cyc each.
	ld de,($C000)
	ld de,($C000)
	inc de						;6cyc.
	inc de						;6cyc.
	ld a,h						;4cyc.
	or l						;4cyc.
	jr z,+						;12cyc at branch, 7 otherwise
	ld a,$55					;7cyc.
	out (IO_Ctrl),a				;11cyc.
	ld a,$FF					;7cyc. Flip HL in/out so HCounter gets latched.
	out (IO_Ctrl),a				;11cyc. Probably around 0x56
	in a,(HCounter)				;11cyc. Read HCounter value, loop 229 cycles
	dec hl						;6cyc.

	ld de,($C000)				;20cyc each.
	ld de,($C000)
	ld de,($C000)
	ld de,$C000					;10cyc.

	cp $F1						;7cyc.
	jr nz,-						;12cyc at branch, 7 otherwise
+:
-:
	ld de,($C000)				;20cyc each.
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,$C000					;10cyc.
	ld d,d						;4cyc.
	ld d,d						;4cyc.

	in a,(VCounter)				;11cyc.
	cp $6F						;7cyc.
	jr nz,-						;12cyc at branch, 7 otherwise

	ld de,($C000)				;20cyc
	ld de,($C000)				;20cyc
	ld de,($C000)				;20cyc
	ld de,($C000)				;20cyc
	in a,(VDP_Ctrl)				;11cyc
	ld d,d						;4cyc
	ld d,d						;4cyc
	ld a,$07					;7cyc. SpriteTileBase value
	out (VDP_Ctrl),a			;11 cyc
	ld a,$86					;7cyc. SpriteTileBase register
	out (VDP_Ctrl),a			;11 cyc, HCount second 0xF3, cycle after latch.

	ld de,($C000)				;20cyc
	ld de,($C000)				;20cyc
	ld de,($C000)				;20cyc
	ld de,($C000)				;20cyc
	ld de,($C000)				;20cyc
	ld de,($C000)				;20cyc
	ld de,($C000)				;20cyc
	ld de,($C000)				;20cyc
	ld de,($C000)				;20cyc
	in a,(VDP_Ctrl)				;11 cyc
	ld a,$03					;7cyc. SpriteTileBase value
	out (VDP_Ctrl),a			;11 cyc
	ld a,$86					;7cyc. SpriteTileBase register
	out (VDP_Ctrl),a			;11 cyc, HCount first 0xF3, cycle before latch.

	pop hl						;10cyc
	pop af						;10cyc
	ei							;4cyc
	reti						;14cyc.

;==============================================================
RunTest90_MD:				;Show xscroll latch time.
	di							; disable interrupts
	call VDP_ScreenOff
	call StdOut_Cls
	ld hl,column1_text
	call StdOut_Write


	in a,(VDP_Ctrl)				;Clear any pending irqs.
	ld hl,$8004					;hblank off
	rst $10

	ld hl,t90_hblank0_MD
	ld (HBL_JUMP),hl
	ld hl,$8A61					; hblank irq on row $61.
	rst $10
	ld hl,$8014					; hblank on
	rst $10
	ei

	call VDP_ScreenOn
	call WaitForButton

	ld hl,$8004					;hblank off
	rst $10
	ld hl,doHBL
	ld (HBL_JUMP),hl

	call VDP_ScreenOff
	ret


t90_hblank0_MD
	ld hl,$0200					;10cyc.
	ld d,d						;4cyc.
-:
	ld de,($C000)				;20cyc each.
	ld de,($C000)
	ld de,($C000)
	inc de						;6cyc.
	inc de						;6cyc.
	ld a,h						;4cyc.
	or l						;4cyc.
	jr z,+						;12cyc at branch, 7 otherwise
	ld a,$55					;7cyc.
	out (IO_Ctrl),a				;11cyc.
	ld a,$FF					;7cyc. Flip HL in/out so HCounter gets latched.
	out (IO_Ctrl),a				;11cyc. Probably around 0x56
	in a,(HCounter)				;11cyc. Read HCounter value, loop 229 cycles
	dec hl						;6cyc.

	ld de,($C000)				;20cyc each.
	ld de,($C000)
	ld de,($C000)
	ld de,$C000					;10cyc.

	cp $F1						;7cyc.
	jr nz,-						;12cyc at branch, 7 otherwise
+:
-:
	ld de,($C000)				;20cyc each.
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,($C000)
	ld de,$C000					;10cyc.
	ld d,d						;4cyc.
	ld d,d						;4cyc.

	in a,(VCounter)				;11cyc.
	cp $6F						;7cyc.
	jr nz,-						;12cyc at branch, 7 otherwise

	ld de,($C000)				;20cyc
	ld de,($C000)				;20cyc
	ld de,($C000)				;20cyc
	ld de,($C000)				;20cyc
	in a,(VDP_Ctrl)				;11cyc
	ld d,d						;4cyc
	ld a,$00					;7cyc.
	ld a,$80					;7cyc. Scroll X value
	out (VDP_Ctrl),a			;11 cyc
	ld a,$88					;7cyc. Scroll X register
	out (VDP_Ctrl),a			;11 cyc, HCount first 0xF6, cycle after latch.

	ld de,($C000)				;20cyc
	ld de,($C000)				;20cyc
	ld de,($C000)				;20cyc
	ld de,($C000)				;20cyc
	ld de,($C000)				;20cyc
	ld de,($C000)				;20cyc
	ld de,($C000)				;20cyc
	ld de,($C000)				;20cyc
	ld de,($C000)				;20cyc
	in a,(VDP_Ctrl)				;11 cyc
	ld a,$00					;7cyc. Scroll X value
	out (VDP_Ctrl),a			;11 cyc
	ld a,$88					;7cyc. Scroll X register
	out (VDP_Ctrl),a			;11 cyc, HCount 0xF5, cycle before latch.

	pop hl						;10cyc
	pop af						;10cyc
	ei							;4cyc
	reti						;14cyc.


;==============================================================
RunTest100:					; test of HC after H/V-Blank
;==============================================================
	in a,(VDP_Ctrl)			;Clear any pending irqs.
	ei
	ld a,$55
	out (IO_Ctrl),a			;set HL to low out.
	halt					;wait for vblank
	ld a,$FF				;7 cyc
	out (IO_Ctrl),a			;11 cyc, flip HL to high so we latch HC
	in a,(HCounter)
	ld (HCValueVBlank),a

	ld hl,$8014				; hblank on
	call VDP_VRAMToHL
	ld hl,$8A80				; hblank row $80
	call VDP_VRAMToHL
	ld a,$55
	out (IO_Ctrl),a			;set HL to low out.

	halt					;wait for hblank
	ld a,$FF				;7 cyc
	out (IO_Ctrl),a			;11 cyc, flip HL to high so we latch HC
	in a,(HCounter)
	ld (HCValueHBlank),a
	ld hl,$8004				; hblank off
	call VDP_VRAMToHL
	ld a,$55				;7 cyc
	out (IO_Ctrl),a			;set HL to low out.

	ld b,$8D
-:	in a,(VCounter)			;11 cyc, Read VCounter values
	cp b					;4 cyc
	jr nz,-					;12/7 cyc
	ld a,$FF				;4 cyc
	out (IO_Ctrl),a			;11 cyc, flip HL to high so we latch HC
	in a,(HCounter)
	ld (HCValueLine),a

	di
	ret

;==============================================================
Setup9Sprites:
;==============================================================
	ld a,$60					;ypos spr0 & spr1
	ld b,$09
	ld hl,SpriteArea
-:
	ld (hl),a
	inc hl
	djnz -

	ld a,$D0					;ypos spr10, stop
	ld (hl),a

	ld de,$4160
	ld hl,SpriteArea + $80
	ld b,$08
-:
	ld a,e						;xpos
	ld (hl),a
	inc hl
	add a,$08
	ld e,a
	ld a,d						;attrib
	ld (hl),a
	inc hl
	djnz -

	ld a,$98					;xpos spr8
	ld (hl),a
	ld a,$41					;attrib spr8
	inc hl
	ld (hl),a

	ld hl,SpriteTableAddress | VDP_Mode_Write
	rst $10						;HL to VDP Ctrl
	ld hl,SpriteArea			; data
	ld bc,$100					; size
	jp VDP_WriteToVRAM

;==============================================================
SetupSpriteColumn:
;==============================================================
	ld a,$FF					;start ypos
	ld b,$18					; sprite count
	ld hl,SpriteArea
-:
	ld (hl),a
	inc hl
	add a,$08
	djnz -

	ld a,$D0					;ypos spr10, stop
	ld (hl),a

	ld de,$5F10
	ld hl,SpriteArea + $80
	ld b,$18
-:
	ld a,e						;xpos
	ld (hl),a
	inc hl
	ld a,d						;attrib
	ld (hl),a
	inc hl
	djnz -

	ld hl,SpriteTableAddress | VDP_Mode_Write
	rst $10						;HL to VDP Ctrl
	ld hl,SpriteArea			; data
	ld bc,$100					; size
	jp VDP_WriteToVRAM

;==============================================================
WriteTestDataToVRAM:
	ld b,$10
	jp VDP_WriteToVRAM_Short
	
CompareTestDataToVRAM:
	ld b,$10
-:	in a,(VDP_Data)
	cp (hl)
	jr nz,cp_error_1
	inc hl
	djnz -
	ld a,$00
	ret
cp_error_1:
	ld a,$FF
	ret

.ends

;==============================================================
; Switch to mode 5, set palette, switch to mode 4 to se palette
;==============================================================
.section "MD Palette test" FREE
StartMDPaletteTest:
	call Write_Cubes0_0
	call Write_Cubes0_1
	ld hl,$8124				;turn on mode5
	rst $10
	ld hl,$8004				;Make sure we get the right palette
	rst $10

	ld b,$F0
DMA_Wait:
	in a,(VDP_Ctrl)
	bit 1,a
	jr z,No_DMA_Wait
	djnz DMA_Wait
No_DMA_Wait
	ld hl,$8208
	rst $10					;set plane A base address ($2000)
	ld hl,$8402
	rst $10					;set plane B base address ($4000)
	ld hl,$8520
	rst $10					;set SAT address ($4000)
	ld hl,$8710				;color 10
	rst $10					;reg $07, border/bgr color
	ld hl,$8B00
	rst $10					;clear reg $0B
	ld hl,$8C00
	rst $10					;clear reg $0C
	ld hl,$8D10
	rst $10					;set H-scroll base address ($4000)
	ld hl,$8F01
	rst $10					;reg $0F, autoincrement 1
	ld hl,$9000
	rst $10					;clear reg $10
	ld hl,$9100
	rst $10					;clear reg $11
	ld hl,$9200
	rst $10					;clear reg $12

; Clear VSRAM
	ld hl,$4000
	rst $10
	ld hl,$0010
	rst $10
	ld bc,$50BE
	xor a
clr_vsram:
	out (c), a
	djnz clr_vsram
; Clear VRAM
	ld hl,$4000
	rst $10
	ld hl,$0001				; bit 14 of address set ($4000)
	rst $10
	ld bc,$C000
clr_vram:
	xor a
	out (VDP_Data), a
	dec bc
	ld a, c
	or b
	jr nz, clr_vram

	call Write_Cubes1
	call Write_Cubes2
	call Write_Cubes3
	call Write_Cubes4
	call Write_CubeTiles

	ld hl,$8164				;reg$01
	rst $10					;screen on, mode5.
	ei
	call WaitForButton

md_palette_setup:
	ld hl,$C000
	rst $10					;HL to VDP Ctrl
	ld hl,$0000
	rst $10					;HL to VDP Ctrl
	ld hl,cubes_md_palette
;	ld hl,counter_palette
	ld bc,$80BE
md_pal_loop:
	ld a,(hl)
	inc hl
	out (c),a
	djnz md_pal_loop

	ei
	call WaitForButton

	ld hl,$8F00
	rst $10					;reg $0F, autoincrement 0, gives increment 1 in mode4.
	ld hl,$8160				; mode5 off.
	rst $10

	ld hl,$C000
	rst $10					;HL to VDP Ctrl
	ld hl,black_palette
	ld bc,$20BE
-:
	ld a,(hl)
	inc hl
	out (c),a
	djnz -

	ld hl,$8164				; mode5 on.
	rst $10

	ei
	call WaitForButton

	ld hl,$8F00
	rst $10					;reg $0F, autoincrement 0, gives increment 1 in mode4.
	ld hl,$8160				; mode5 off.
	rst $10
	ld a,(NameTableAddress>>10) |%11110001
	call VDP_SetReg2				;set plane A base address.

	call WaitForButton
	jp WarmReset

Write_Cubes0_0:
	ld hl,(NameTableAddress + 64*2) | VDP_Mode_Write
	rst $10						;HL to VDP Ctrl
	ld hl,cubes_data1				; data
	ld bc,$40						; size
	call VDP_WriteToVRAM

	ld hl,(NameTableAddress + 64*3) | VDP_Mode_Write
	rst $10						;HL to VDP Ctrl
	ld hl,cubes_data1				; data
	ld bc,$40						; size
	jp VDP_WriteToVRAM

Write_Cubes0_1:
	ld hl,(NameTableAddress + 64*4) | VDP_Mode_Write
	rst $10						;HL to VDP Ctrl
	ld hl,cubes_data2				; data
	ld bc,$40						; size
	call VDP_WriteToVRAM

	ld hl,(NameTableAddress + 64*5) | VDP_Mode_Write
	rst $10						;HL to VDP Ctrl
	ld hl,cubes_data2				; data
	ld bc,$40						; size
	jp VDP_WriteToVRAM

Write_Cubes1:
	ld hl,($2000 + 64*4) | VDP_Mode_Write
	rst $10							;HL to VDP Ctrl
	ld hl,$0000
	rst $10							;HL to VDP Ctrl
	ld hl,cubes_data_md1			; data
	ld bc,$40						; size
	call VDP_WriteToVRAM

	ld hl,($2000 + 64*5) | VDP_Mode_Write
	rst $10							;HL to VDP Ctrl
	ld hl,$0000
	rst $10							;HL to VDP Ctrl
	ld hl,cubes_data_md1			; data
	ld bc,$40						; size
	call VDP_WriteToVRAM

	ld hl,($2000 + 64*6) | VDP_Mode_Write
	rst $10							;HL to VDP Ctrl
	ld hl,$0000
	rst $10							;HL to VDP Ctrl
	ld hl,cubes_data_md1l			; data
	ld bc,$40						; size
	call VDP_WriteToVRAM

	ld hl,($2000 + 64*7) | VDP_Mode_Write
	rst $10							;HL to VDP Ctrl
	ld hl,$0000
	rst $10							;HL to VDP Ctrl
	ld hl,cubes_data_md1l			; data
	ld bc,$40						; size
	jp VDP_WriteToVRAM

Write_Cubes2:
	ld hl,($2000 + 64*8) | VDP_Mode_Write
	rst $10							;HL to VDP Ctrl
	ld hl,$0000
	rst $10							;HL to VDP Ctrl
	ld hl,cubes_data_md2			; data
	ld bc,$40						; size
	call VDP_WriteToVRAM

	ld hl,($2000 + 64*9) | VDP_Mode_Write
	rst $10							;HL to VDP Ctrl
	ld hl,$0000
	rst $10							;HL to VDP Ctrl
	ld hl,cubes_data_md2			; data
	ld bc,$40						; size
	call VDP_WriteToVRAM

	ld hl,($2000 + 64*10) | VDP_Mode_Write
	rst $10							;HL to VDP Ctrl
	ld hl,$0000
	rst $10							;HL to VDP Ctrl
	ld hl,cubes_data_md2l			; data
	ld bc,$40						; size
	call VDP_WriteToVRAM

	ld hl,($2000 + 64*11) | VDP_Mode_Write
	rst $10							;HL to VDP Ctrl
	ld hl,$0000
	rst $10							;HL to VDP Ctrl
	ld hl,cubes_data_md2l			; data
	ld bc,$40						; size
	jp VDP_WriteToVRAM

Write_Cubes3:
	ld hl,($2000 + 64*12) | VDP_Mode_Write
	rst $10							;HL to VDP Ctrl
	ld hl,$0000
	rst $10							;HL to VDP Ctrl
	ld hl,cubes_data_md3			; data
	ld bc,$40						; size
	call VDP_WriteToVRAM

	ld hl,($2000 + 64*13) | VDP_Mode_Write
	rst $10							;HL to VDP Ctrl
	ld hl,$0000
	rst $10							;HL to VDP Ctrl
	ld hl,cubes_data_md3			; data
	ld bc,$40						; size
	call VDP_WriteToVRAM

	ld hl,($2000 + 64*14) | VDP_Mode_Write
	rst $10							;HL to VDP Ctrl
	ld hl,$0000
	rst $10							;HL to VDP Ctrl
	ld hl,cubes_data_md3l			; data
	ld bc,$40						; size
	call VDP_WriteToVRAM

	ld hl,($2000 + 64*15) | VDP_Mode_Write
	rst $10							;HL to VDP Ctrl
	ld hl,$0000
	rst $10							;HL to VDP Ctrl
	ld hl,cubes_data_md3l			; data
	ld bc,$40						; size
	jp VDP_WriteToVRAM

Write_Cubes4:
	ld hl,($2000 + 64*16) | VDP_Mode_Write
	rst $10							;HL to VDP Ctrl
	ld hl,$0000
	rst $10							;HL to VDP Ctrl
	ld hl,cubes_data_md4			; data
	ld bc,$40						; size
	call VDP_WriteToVRAM

	ld hl,($2000 + 64*17) | VDP_Mode_Write
	rst $10							;HL to VDP Ctrl
	ld hl,$0000
	rst $10							;HL to VDP Ctrl
	ld hl,cubes_data_md4			; data
	ld bc,$40						; size
	call VDP_WriteToVRAM

	ld hl,($2000 + 64*18) | VDP_Mode_Write
	rst $10							;HL to VDP Ctrl
	ld hl,$0000
	rst $10							;HL to VDP Ctrl
	ld hl,cubes_data_md4l			; data
	ld bc,$40						; size
	call VDP_WriteToVRAM

	ld hl,($2000 + 64*19) | VDP_Mode_Write
	rst $10							;HL to VDP Ctrl
	ld hl,$0000
	rst $10							;HL to VDP Ctrl
	ld hl,cubes_data_md4l			; data
	ld bc,$40						; size
	jp VDP_WriteToVRAM

Write_CubeTiles:
	ld hl,($0000) | VDP_Mode_Write
	rst $10							;HL to VDP Ctrl
	ld hl,$0000
	rst $10							;HL to VDP Ctrl
	ld a,$00
	ld b,$20
-:	out (VDP_Data),a
	djnz -

	ld hl,($0C00) | VDP_Mode_Write
	rst $10							;HL to VDP Ctrl
	ld hl,$0000
	rst $10							;HL to VDP Ctrl
	ld a,$11
cube_loop:
	ld b,$20
-:	out (VDP_Data),a
	djnz -
	add a,$11
	cp $10
	jr nz,cube_loop
	ret

.ends

;==============================================================
; Data
;==============================================================
.BANK 1 SLOT 1
.section "Data1" FREE
	menu_text:
	.db "  Please select a test!",$0a,$0a,$0a
	.db "  SMS VDP Test.",$0a
	.db "  MegaDrive VDP Test.",$0a
	.db "  MegaDrive Palette Test.",$0a
	.db "  HCount timing & more.",$0a
	.db "  Register Startup Values.",$0a
	.db "  CPU Test.",$0a
	.db 0

space_text:
	.db " ",$00

marker_text:
	.db "*",$00

continue3_text:
	.db $0a,$0a
continue2_text:
	.db $0a,$0a,$0a
continue1_text:
	.db $0a
continue_text:
	.db $0a
	.db "Push any button to continue!",0

sms_test1_text:
	.db "SMS VDP data test",$0a,$0a,0
sms_test2_text:
	.db "SMS VDP misc test",$0a,$0a,0
sms_test3_text:
	.db "SMS VDP sprite test",$0a,$0a,0
md_test1_text:
	.db "MegaDrive VDP data test",$0a,$0a,0
md_test2_text:
	.db "MegaDrive VDP misc test",$0a,$0a,0
md_test3_text:
	.db "MegaDrive VDP sprite test",$0a,$0a,0
hcount_info_text:
	.db "HCount values should be between $EA & $93, "
	.db "every third value repeated once.",0
hc_page2_text
	.db "HCounter Values:",$0a,0
hc_page3_text
	.db "HCount values for HBlank should be between "
	.db "$83 & $86. VBlank should be between $7D & $80.",$0a,0
hbl_vbl_text:
	.db "Line value:",$0a
	.db "HBlank value:",$0a
	.db "VBlank value:",0
cpu_regs_text:
	.db "Registers Startup Values",$0a,$0a,0

res_text_1:
	.db "Normal read/write:     ",0
res_text_2:
	.db "Read after code1 wr:   ",0
res_text_3:
	.db "Read after code2 wr:   ",0
res_text_4:
	.db "Read after code3 wr:   ",0
res_text_5:
	.db "Write after code0 wr:  ",0
res_text_6:
	.db "Write after code2 wr:  ",0
res_text_7:
	.db "Write after code3 wr:  ",0
res_text_8:
	.db "Mixed read/write:      ",0
res_text_9:
	.db "VRAM wr set VDPbuffer: ",0
res_text_9_md:
	.db "VRAM wr keep VDPbuffer:",0
res_text_10:
	.db "CRAM wr set VDPbuffer: ",0
res_text_10_md:
	.db "CRAM wr keep VDPbuffer:",0
res_text_11:
	.db "1byte wr sets rd adr:  ",0
res_text_11_md:
	.db "1byte wr keeps rd adr: ",0
res_text_12:
	.db "1byte wr sets wr adr:  ",0
res_text_12_md:
	.db "1byte wr keeps wr adr: ",0
res_text_13:
	.db "1byte wr keeps wr mode:",0
res_text_14:
	.db "Address wraps at $3FFF:",0
res_text_15:
	.db "VRAM & CRAM share adr: ",0
res_text_16:
	.db "Rd VDPCtrl reset latch:",0
res_text_17:
	.db "Rd VDPData reset latch:",0
res_text_18:
	.db "Wr VDPData reset latch:",0
res_text_19:
	.db "Unused regs, no effect:",0

res_text_21:
	.db "VCounter values:",0
res_text_22:
	.db "HCounter keeps value:",0
res_text_23:
	.db "HC change on TH 0->1:",0
res_text_24:
	.db "HCounter correct:    ",0
res_text_25:
	.db "VCounter chg time:   ",0
res_text_26:
	.db "VDP Register mirrors:",0
res_text_27:
	.db "VDP data mirrors:    ",0
res_text_28:
	.db "VDP ctrl mirrors:    ",0
res_text_29:
	.db "VCounter mirrors:    ",0
res_text_30:
	.db "HCounter mirrors:    ",0
res_text_31:
	.db "Frame IRQ VCount:    ",0
res_text_32:
	.db "Frame IRQ HCount:    ",0
res_text_33:
	.db "Line IRQ VCount:     ",0
res_text_34:
	.db "Line IRQ HCount:     ",0
res_text_35:
	.db "VINT flag HCount:    ",0
res_text_36:
	.db "VINT flag keept:     ",0

res_text_41:
	.db "No sprite collision: ",0
res_text_42:
	.db "No disp, no spr col: ",0
res_text_43:
	.db "9th sprite no col:   ",0
res_text_44:
	.db "Transp pixl, no col: ",0
res_text_45:
	.db "Offscreen X, no col: ",0
res_text_46:
	.db "Offscreen Y, col:    ",0
res_text_46_MD:
	.db "Offscreen Y, no col: ",0
res_text_47:
	.db "Sprite collision:    ",0
res_text_48:
	.db "Colflag keept in vbl:",0
res_text_49:
	.db "Spr col behind tile: ",0
res_text_50:
	.db "Spr col correct line:",0
res_text_51:
	.db "Spr col many lines:  ",0
res_text_52:
	.db "Spr col correct HC:  ",0
res_text_53:
	.db "No sprite overflow:  ",0
res_text_54:
	.db "No disp, spr ovr:    ",0
res_text_54_MD:
	.db "No disp, no spr ovr: ",0
res_text_55:
	.db "Offscreen Y, no ovr: ",0
res_text_56:
	.db "Sprite overflow:     ",0
res_text_57:
	.db "Ovrflag keept in vbl:",0
res_text_58:
	.db "Spr ovr correct line:",0
res_text_59:
	.db "Spr ovr many lines:  ",0
res_text_60:
	.db "Spr ovr correct HC:  ",0


reg_text_sp:
	.db "Z80 SP:   $",0
reg_text_ir:
	.db "Z80 IR:   $",0
reg_text_af:
	.db "Z80 AF:   $",0
reg_text_bc:
	.db "Z80 BC:   $",0
reg_text_de:
	.db "Z80 DE:   $",0
reg_text_hl:
	.db "Z80 HL:   $",0
reg_text_ix:
	.db "Z80 IX:   $",0
reg_text_iy:
	.db "Z80 IY:   $",0
reg_text_af2:
	.db "Z80 AF':  $",0
reg_text_bc2:
	.db "Z80 BC':  $",0
reg_text_de2:
	.db "Z80 DE':  $",0
reg_text_hl2:
	.db "Z80 HL':  $",0
reg_text_iff2:
	.db "Z80 IFF2: $",0
reg_text_vc:
	.db "VDP VC:   $",0
reg_text_hc:
	.db "VDP HC:   $",0
reg_text_stack_value
	.db "Stack val:$",0
reg_text_adr_value
	.db "Adr val:  $",0


ok_text:
	.db " Ok.",$0a,0
error_text:
	.db " Error.",$0a,0
pal_ok_text:
	.db "  PAL Ok.",$0a,0
ntsc_ok_text:
	.db " NTSC Ok.",$0a,0

column1_text:
	.db $20,$7F," Testing X-Scroll latchtime",$0a
	.db $20,$7F," Column should be straight",$0a
	.db $20,$7F,$0a
	.db $20,$7F,$0a
	.db $20,$7F,$0a
	.db $20,$7F,$0a
	.db $20,$7F,$0a
	.db $20,$7F,$0a
	.db $20,$7F,$0a
	.db $20,$7F,$0a
	.db $20,$7F,$0a
	.db $20,$7F,$0a
	.db $20,$7F,$0a
	.db $20,$7F,$0a
	.db $20,$7F,$0a
	.db $20,$7F,$0a
	.db $20,$7F,$0a
	.db $20,$7F,$0a
	.db $20,$7F,$0a
	.db $20,$7F,$0a
	.db $20,$7F,$0a
	.db $20,$7F,$0a
	.db $20,$7F,$0a
	.db $20,$7F,$0a
	.db $00

column2_text:
	.db $20,$7F," Testing NameTable latchtime",$0a
	.db $20,$7F," Column should be straight",$0a
	.db $20,$7F,$0a
	.db $20,$7F,$0a
	.db $20,$7F,$0a
	.db $20,$7F,$0a
	.db $20,$7F,$0a
	.db $20,$7F,$0a
	.db $20,$7F,$0a
	.db $20,$7F,$0a
	.db $20,$7F,$0a
	.db $20,$7F,$0a
	.db $20,$7F,$0a
	.db $20,$7F,$0a
	.db $20,$7F,$7F,$0a
	.db $20,$7F,$0a
	.db $20,$7F,$0a
	.db $20,$7F,$0a
	.db $20,$7F,$0a
	.db $20,$7F,$0a
	.db $20,$7F,$0a
	.db $20,$7F,$0a
	.db $20,$7F,$0a
	.db $20,$7F,$0a
	.db $00

column3_text:
	.db $20,$20," Testing SprAtrTbl latchtime",$0a
	.db $20,$20," Column should be straight",$0a,$00

column4_text:
	.db $20,$20," Testing SprPtrOfs latchtime",$0a
	.db $20,$20," Column should be straight",$0a,$00

cubes_data1:
	.dw $0000,$0000,$0060,$0060,$0061,$0061,$0062,$0062,$0063,$0063,$0064,$0064,$0065,$0065,$0066,$0066
	.dw $0067,$0067,$0068,$0068,$0069,$0069,$006a,$006a,$006b,$006b,$006c,$006c,$006d,$006d,$006e,$006e
cubes_data2:
	.dw $0800,$0800,$0860,$0860,$0861,$0861,$0862,$0862,$0863,$0863,$0864,$0864,$0865,$0865,$0866,$0866
	.dw $0867,$0867,$0868,$0868,$0869,$0869,$086a,$086a,$086b,$086b,$086c,$086c,$086d,$086d,$086e,$086e
cubes_data_md1:
	.dw $8000,$8000,$8060,$8060,$8061,$8061,$8062,$8062,$8063,$8063,$8064,$8064,$8065,$8065,$8066,$8066
	.dw $8067,$8067,$8068,$8068,$8069,$8069,$806a,$806a,$806b,$806b,$806c,$806c,$806d,$806d,$806e,$806e
cubes_data_md2:
	.dw $A000,$A000,$A060,$A060,$A061,$A061,$A062,$A062,$A063,$A063,$A064,$A064,$A065,$A065,$A066,$A066
	.dw $A067,$A067,$A068,$A068,$A069,$A069,$A06a,$A06a,$A06b,$A06b,$A06c,$A06c,$A06d,$A06d,$A06e,$A06e
cubes_data_md3:
	.dw $C000,$C000,$C060,$C060,$C061,$C061,$C062,$C062,$C063,$C063,$C064,$C064,$C065,$C065,$C066,$C066
	.dw $C067,$C067,$C068,$C068,$C069,$C069,$C06a,$C06a,$C06b,$C06b,$C06c,$C06c,$C06d,$C06d,$C06e,$C06e
cubes_data_md4:
	.dw $E000,$E000,$E060,$E060,$E061,$E061,$E062,$E062,$E063,$E063,$E064,$E064,$E065,$E065,$E066,$E066
	.dw $E067,$E067,$E068,$E068,$E069,$E069,$E06a,$E06a,$E06b,$E06b,$E06c,$E06c,$E06d,$E06d,$E06e,$E06e
cubes_data_md1l:
	.dw $0000,$0000,$0060,$0060,$0061,$0061,$0062,$0062,$0063,$0063,$0064,$0064,$0065,$0065,$0066,$0066
	.dw $0067,$0067,$0068,$0068,$0069,$0069,$006a,$006a,$006b,$006b,$006c,$006c,$006d,$006d,$006e,$006e
cubes_data_md2l:
	.dw $2000,$2000,$2060,$2060,$2061,$2061,$2062,$2062,$2063,$2063,$2064,$2064,$2065,$2065,$2066,$2066
	.dw $2067,$2067,$2068,$2068,$2069,$2069,$206a,$206a,$206b,$206b,$206c,$206c,$206d,$206d,$206e,$206e
cubes_data_md3l:
	.dw $4000,$4000,$4060,$4060,$4061,$4061,$4062,$4062,$4063,$4063,$4064,$4064,$4065,$4065,$4066,$4066
	.dw $4067,$4067,$4068,$4068,$4069,$4069,$406a,$406a,$406b,$406b,$406c,$406c,$406d,$406d,$406e,$406e
cubes_data_md4l:
	.dw $6000,$6000,$6060,$6060,$6061,$6061,$6062,$6062,$6063,$6063,$6064,$6064,$6065,$6065,$6066,$6066
	.dw $6067,$6067,$6068,$6068,$6069,$6069,$606a,$606a,$606b,$606b,$606c,$606c,$606d,$606d,$606e,$606e
cubes_md_palette:
	.dw $000C,$0EEE,$0CCC,$0AAA,$0888,$0666,$0444,$0222,$0000,$00E0,$00C0,$00A0,$0080,$0060,$0040,$0020
	.dw $0C00,$0EE0,$0CC0,$0AA0,$0880,$0660,$0440,$0220,$0000,$0E00,$0C00,$0A00,$0800,$0600,$0400,$0200
	.dw $00C0,$00EE,$00CC,$00AA,$0088,$0066,$0044,$0022,$0000,$000E,$000C,$000A,$0008,$0006,$0004,$0002
	.dw $00E0,$0E0E,$0C0C,$0A0A,$0808,$0606,$0404,$0202,$0000,$02E2,$04C4,$06A6,$0888,$0A6A,$0C4C,$0E2E
default_md_palette:
	.dw $0EEE,$0EEE,$0EEE,$08EE,$0AEE,$0EEE,$0EEE,$0EEE,$0EEE,$0CEE,$0EEE,$0EEE,$0EEE,$0EEE,$0EEE,$0EEE
	.dw $0006,$0802,$0400,$0000,$0EEE,$0EEE,$0EEE,$08EE,$0CEE,$0EEE,$0EEE,$0EEE,$0EEE,$0EEE,$0E6E,$0EEE
	.dw $0EEE,$0EEE,$0EEE,$0EEE,$0EEE,$0EEE,$0ECE,$08EE,$0EEE,$0EEE,$06EE,$0EEE,$0EEE,$0EEE,$0EEE,$0EEE
	.dw $0E6E,$0EEE,$0EEA,$08EE,$0EEE,$0EEE,$0EEE,$0EEE,$0EEE,$0EEE,$0EEE,$0EEE,$0CEE,$0EEE,$0EEE,$0EAE
counter_palette:
	.dw $0000,$0222,$0444,$0666,$0888,$0AAA,$0CCC,$0EEE,$0000,$0222,$0444,$0666,$0888,$0AAA,$0CCC,$0EEE
	.dw $0000,$0222,$0444,$0666,$0888,$0AAA,$0CCC,$0EEE,$0000,$0222,$0444,$0666,$0888,$0AAA,$0CCC,$0EEE
	.dw $0EEE,$0EEE,$0EEE,$0EEE,$0EEE,$0EEE,$0ECE,$08EE,$0EEE,$0EEE,$06EE,$0EEE,$0EEE,$0EEE,$0EEE,$0EEE
	.dw $0E6E,$0EEE,$0EEA,$08EE,$0EEE,$0EEE,$0EEE,$0EEE,$0EEE,$0EEE,$0EEE,$0EEE,$0CEE,$0EEE,$0EEE,$0EAE
black_palette:
	.db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

test_data1:
	.db $00,$FF,$55,$AA,$01,$02,$04,$08,$10,$20,$40,$80,"Test"
test_data2:
	.db "TESt",$AA,$55,$FF,$00,$80,$40,$20,$10,$08,$04,$02,$01
test_data3:
	.db "GuefsPoaLeYit",$AA,$55,$00
test_data4:
	.db $AA,$00,$55,"TeHuGuefsPoaL"


HCounterValues:				;MegaDrive can have double values in all places (eg FF or 00 or 01).
	.db $00,$01,$02,$02,$03,$04,$05,$05,$06,$07,$08,$08,$09,$0A,$0B,$0B
	.db $0C,$0D,$0E,$0E,$0F,$10,$11,$11,$12,$13,$14,$14,$15,$16,$17,$17
	.db $18,$19,$1A,$1A,$1B,$1C,$1D,$1D,$1E,$1F,$20,$20,$21,$22,$23,$23
	.db $24,$25,$26,$26,$27,$28,$29,$29,$2A,$2B,$2C,$2C,$2D,$2E,$2F,$2F
	.db $30,$31,$32,$32,$33,$34,$35,$35,$36,$37,$38,$38,$39,$3A,$3B,$3B
	.db $3C,$3D,$3E,$3E,$3F,$40,$41,$41,$42,$43,$44,$44,$45,$46,$47,$47
	.db $48,$49,$4A,$4A,$4B,$4C,$4D,$4D,$4E,$4F,$50,$50,$51,$52,$53,$53
	.db $54,$55,$56,$56,$57,$58,$59,$59,$5A,$5B,$5C,$5C,$5D,$5E,$5F,$5F
	.db $60,$61,$62,$62,$63,$64,$65,$65,$66,$67,$68,$68,$69,$6A,$6B,$6B
	.db $6C,$6D,$6E,$6E,$6F,$70,$71,$71,$72,$73,$74,$74,$75,$76,$77,$77
	.db $78,$79,$7A,$7A,$7B,$7C,$7D,$7D,$7E,$7F,$80,$80,$81,$82,$83,$83
	.db $84,$85,$86,$86,$87,$88,$89,$89,$8A,$8B,$8C,$8C,$8D,$8E,$8F,$8F
	.db $90,$91,$92,$92,$93,$E9,$EA,$EA,$EB,$EC,$ED,$ED,$EE,$EF,$F0,$F0
	.db $F1,$F2,$F3,$F3,$F4,$F5,$F6,$F6,$F7,$F8,$F9,$F9,$FA,$FB,$FC,$FC
	.db $FD,$FE,$FF,$FF

	.db $00,$01,$02,$02,$03,$04,$05,$05,$06,$07,$08,$08,$09,$0A,$0B,$0B
	.db $0C,$0D,$0E,$0E,$0F,$10,$11,$11,$12,$13,$14,$14,$15,$16,$17,$17
	.db $18,$19,$1A,$1A,$1B,$1C,$1D,$1D,$1E,$1F,$20,$20,$21,$22,$23,$23
	.db $24,$25,$26,$26,$27,$28,$29,$29,$2A,$2B,$2C,$2C,$2D,$2E,$2F,$2F
	.db $30,$31,$32,$32,$33,$34,$35,$35,$36,$37,$38,$38,$39,$3A,$3B,$3B
	.db $3C,$3D,$3E,$3E,$3F,$40,$41,$41,$42,$43,$44,$44,$45,$46,$47,$47
	.db $48,$49,$4A,$4A,$4B,$4C,$4D,$4D,$4E,$4F,$50,$50,$51,$52,$53,$53
	.db $54,$55,$56,$56,$57,$58,$59,$59,$5A,$5B,$5C,$5C,$5D,$5E,$5F,$5F
	.db $60,$61,$62,$62,$63,$64,$65,$65,$66,$67,$68,$68,$69,$6A,$6B,$6B
	.db $6C,$6D,$6E,$6E,$6F,$70,$71,$71,$72,$73,$74,$74,$75,$76,$77,$77
	.db $78,$79,$7A,$7A,$7B,$7C,$7D,$7D,$7E,$7F,$80,$80,$81,$82,$83,$83
	.db $84,$85,$86,$86,$87,$88,$89,$89,$8A,$8B,$8C,$8C,$8D,$8E,$8F,$8F
	.db $90,$91,$92,$92,$93,$E9,$EA,$EA,$EB,$EC,$ED,$ED,$EE,$EF,$F0,$F0
	.db $F1,$F2,$F3,$F3,$F4,$F5,$F6,$F6,$F7,$F8,$F9,$F9,$FA,$FB,$FC,$FC
	.db $FD,$FE,$FF,$FF

VCounterValues:
	.db $00,$01,$02,$03,$04,$05,$06,$07,$08,$09,$0A,$0B,$0C,$0D,$0E,$0F
	.db $10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$1A,$1B,$1C,$1D,$1E,$1F
	.db $20,$21,$22,$23,$24,$25,$26,$27,$28,$29,$2A,$2B,$2C,$2D,$2E,$2F
	.db $30,$31,$32,$33,$34,$35,$36,$37,$38,$39,$3A,$3B,$3C,$3D,$3E,$3F
	.db $40,$41,$42,$43,$44,$45,$46,$47,$48,$49,$4A,$4B,$4C,$4D,$4E,$4F
	.db $50,$51,$52,$53,$54,$55,$56,$57,$58,$59,$5A,$5B,$5C,$5D,$5E,$5F
	.db $60,$61,$62,$63,$64,$65,$66,$67,$68,$69,$6A,$6B,$6C,$6D,$6E,$6F
	.db $70,$71,$72,$73,$74,$75,$76,$77,$78,$79,$7A,$7B,$7C,$7D,$7E,$7F
	.db $80,$81,$82,$83,$84,$85,$86,$87,$88,$89,$8A,$8B,$8C,$8D,$8E,$8F
	.db $90,$91,$92,$93,$94,$95,$96,$97,$98,$99,$9A,$9B,$9C,$9D,$9E,$9F
	.db $A0,$A1,$A2,$A3,$A4,$A5,$A6,$A7,$A8,$A9,$AA,$AB,$AC,$AD,$AE,$AF
	.db $B0,$B1,$B2,$B3,$B4,$B5,$B6,$B7,$B8,$B9,$BA,$BB,$BC,$BD,$BE,$BF
	.db $C0,$C1,$C2,$C3,$C4,$C5,$C6,$C7,$C8,$C9,$CA,$CB,$CC,$CD,$CE,$CF
	.db $D0,$D1,$D2,$D3,$D4,$D5,$D6,$D7,$D8,$D9,$DA,$DB,$DC,$DD,$DE,$DF
	.db $E0,$E1,$E2,$E3,$E4,$E5,$E6,$E7,$E8,$E9,$EA,$EB,$EC,$ED,$EE,$EF
	.db $F0,$F1,$F2
VCounterPAL:
	.db $BA,$BB,$BC,$BD,$BE,$BF
	.db $C0,$C1,$C2,$C3,$C4,$C5,$C6,$C7,$C8,$C9,$CA,$CB,$CC,$CD,$CE,$CF
	.db $D0,$D1,$D2,$D3,$D4
;PAL continues here...
VCounterNTSC:
	.db                     $D5,$D6,$D7,$D8,$D9,$DA,$DB,$DC,$DD,$DE,$DF
	.db $E0,$E1,$E2,$E3,$E4,$E5,$E6,$E7,$E8,$E9,$EA,$EB,$EC,$ED,$EE,$EF
	.db $F0,$F1,$F2,$F3,$F4,$F5,$F6,$F7,$F8,$F9,$FA,$FB,$FC,$FD,$FE,$FF


	chartiles:
	.incbin "smscharset (tiles).pscompr"
	charpalette:
	.incbin "smscharset (palette).bin" fsize charpalettesize
.ends



