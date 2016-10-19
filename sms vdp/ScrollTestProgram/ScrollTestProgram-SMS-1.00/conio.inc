;----------------------------------------------------------------------------
; conio.inc
;----------------------------------------------------------------------------

conio_init:
                        ld      hl, $4000
                        rst     10h
                        ld      hl, font
                        ld      bc, font_len
load_font:              ld      a, (hl)
                        out     ($BE), a
                        xor     a
                        out     ($BE), a
                        out     ($BE), a
                        out     ($BE), a
                        inc     hl
                        dec     bc
                        ld      a, c
                        or      b
                        jr      nz, load_font
                        ret
; bc = position
gotoxy:
                        push    af
                        push    bc
                        push    hl

                        push    bc
                        pop     hl

                        ld      a, h    
                        sla     a       
                        sla     a       
                        sla     a       
                        sla     a       
                        sla     a       
                        sla     a       
                        and     $C0     
                        ld      c, a    

                        ld      a, h    
                        sra     a       
                        sra     a       
                        and     $07
                        ld      b, a

                        ld      a, l    
                        sla     a       
                        and     $3E
                        ld      l, a    
                        ld      a, c    
                        or      l       
                        and     $FE     
                        ld      c, a    

                        ld      a, b    
                        and     $07     
                        or      $38     
                        or      $40     
                        ld      b, a
                        push    bc
                        pop     hl
                        rst     10h

                        pop     hl
                        pop     bc
                        pop     af
                        ret
printf:
                        push    af
                        push    bc
                        push    hl

                        call    gotoxy
printf_next:
                        ld      a, (hl)
                        inc     hl
                        cp      $00
                        jr      z, printf_done
                        cp      1
                        jr      z, printf_newline
                        out     ($BE), a
                        ld      a, $00
                        out     ($BE), a
                        jr      printf_next
printf_newline:
                        inc     b
                        call    gotoxy
                        jr      printf_next
printf_done:
                        pop     hl
                        pop     bc
                        pop     af
                        ret
printhexb:
                        push    af
                        push    bc
                        push    hl

                        call    gotoxy

                        push    af
                        ld      hl, hex_table
                        srl     a
                        srl     a
                        srl     a
                        srl     a
                        and     $0F
                        ld      b, a
                        ld      a, l
                        add     a, b
                        ld      l, a
                        ld      a, (hl)
                        out     ($BE), a
                        xor     a
                        out     ($BE), a

                        pop     af      
                        ld      hl, hex_table
                        and     $0F
                        ld      b, a
                        ld      a, l
                        add     a, b
                        ld      l, a
                        ld      a, (hl)
                        out     ($BE), a
                        xor     a
                        out     ($BE), a

                        pop     hl
                        pop     bc
                        pop     af
                        ret

printhexd:
                        push    af
                        push    bc
                        push    hl

                        call    gotoxy

                        ld      hl, hex_table
                        and     $0F
                        ld      b, a
                        ld      a, l
                        add     a, b
                        ld      l, a
                        ld      a, (hl)
                        out     ($BE), a
                        xor     a
                        out     ($BE), a

                        pop     hl
                        pop     bc
                        pop     af
                        ret


font:                   .include        "vga.inc"
font_len                =       $-font
hex_table:              .db     "0123456789ABCDEF"

