;----------------------------------------------------------------------------
; Scroll test program
;----------------------------------------------------------------------------

                        .org    $0000
                        di
                        im      1
                        ld      sp, $DFF0
                        jp      main

                        .org    $0010
                        ld      a, l
                        out     ($BF), a
                        ld      a, h
                        out     ($BF), a
                        ret

                        .org    $0018
                        ld      a, l
                        out     ($BE), a
                        ld      a, h
                        out     ($BE), a
                        ret


                        .org    $0038
                        in      a, ($BF)
                        call    irq_routine
                        ei
                        reti

                        .org    $0066
                        retn

;----------------------------------------------------------------------------
irq_routine:
                        ld      a, ($C002)
                        inc     a
                        ld      ($C002), a

                        ; Set Y scroll
                        ld      l, a
                        ld      h, $89
                        rst     10h

                        ld      a, ($C003)
                        dec     a
                        ld      ($C003), a

                        ; Set X scroll
                        ld      l, a
                        ld      h, $88
                        rst     10h

                        ret

;----------------------------------------------------------------------------
main:
                        call    vdp_init
                        call    conio_init

                        ; Lock top 2 rows, right 8 columns
                        ld      hl, $80C6
                        rst     10h

                        ; Enable screen and line ints
                        ld      hl, $81E2
                        rst     10h
                        ei
main_loop:

                        ; Line 40
w40:                    in      a, ($7E)
                        cp      $40
                        jr      nz, w40

                        ld      a, ($C000)
                        inc     a
                        ld      ($C000), a

                        ld      a, ($C000)
                        out     ($BF), a
                        ld      a, $88
                        out     ($BF), a

                        ld      a, ($C000)
                        out     ($BF), a
                        ld      a, $89
                        out     ($BF), a

                        ; Line 80
w80:                    in      a, ($7E)
                        cp      $80
                        jr      nz, w80
                        ld      a, ($C001)
                        dec     a
                        ld      ($C001), a

                        ld      a, ($C001)
                        out     ($BF), a
                        ld      a, $88
                        out     ($BF), a

                        ld      a, ($C001)
                        out     ($BF), a
                        ld      a, $89
                        out     ($BF), a


                        jp      main_loop

;----------------------------------------------------------------------------

                        .include "vdp.inc"
                        .include "conio.inc"

sdsc_program_name:      .db     "Scroll Test Program",0
sdsc_release_notes:     .db     "Author: Charles MacDonald",0


                        ; SDSC data

                        .org    $7FE0
                        .db     "SDSC"
                        .db     $01, $00
                        .db     $30
                        .db     $07
                        .db     $01, $20
                        .db     $00, $00
                        .dw     sdsc_program_name
                        .dw     sdsc_release_notes

                        ; SEGA data

                        .org    $7FF0
                        .db     "TMR SEGA"
                        .dw     $FFFF
                        .db     $00, $00
                        .db     $00, $00
                        .db     $00
                        .db     $00

                        .end

