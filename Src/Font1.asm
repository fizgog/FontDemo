;-------------------------------------------------------------------------
; Mode 1 Font Test
;-------------------------------------------------------------------------

MAPCHAR '0','9',0
MAPCHAR ' ',10
MAPCHAR 'A','Z',11

oswrch = &FFEE
osbyte = &FFF4

; Colours
PAL_black	    = 0
PAL_red		    = 1 
PAL_yellow	    = 2 
PAL_white	    = 3 

; Key codes
keyCodeESCAPE   = &8F

; Define some zp locations
ORG 0

.saveA          SKIP 1
.saveX          SKIP 1
.saveY          SKIP 1
.counter        SKIP 1
.temp           SKIP 1
.right_bit      SKIP 1
.left_bit       SKIP 1
.chrFontColour  SKIP 1

.textstartaddr  SKIP 2
.chrFontAddr    SKIP 2
.screenAddr     SKIP 2

ORG &1900
GUARD &3000

.start

;-------------------------------------------------------------------------
; Initialise
;-------------------------------------------------------------------------
.Initialise

    LDY #$00   
.init_loop
    LDA setup_screen,Y
    CMP #$FF
    BEQ init_done
    JSR oswrch
    INY
    BNE init_loop
.init_done
    
    ; Simple test to plot 3 coloured rows of font characters

    LDA #LO(scoreboard1) : STA textstartaddr
    LDA #HI(scoreboard1) : STA textstartaddr+1

    LDA #PAL_red        ; colour 1
	LDX #$00            ; x pos
	LDY #$30            ; y pos
    JSR PrintString

    LDA #LO(scoreboard1) : STA textstartaddr
    LDA #HI(scoreboard1) : STA textstartaddr+1

    LDA #PAL_yellow     ; colour 2
	LDX #$80            ; x pos
	LDY #$32            ; y pos
    JSR PrintString

    LDA #LO(scoreboard1) : STA textstartaddr
    LDA #HI(scoreboard1) : STA textstartaddr+1

    LDA #PAL_white      ; colour 3
	LDX #$00            ; x pos
	LDY #$35            ; y pos
    JSR PrintString
    
;-------------------------------------------------------------------------
; MainLoop - Game
;-------------------------------------------------------------------------
.MainLoop

    LDA #1
    JSR VsyncDelay

    LDX #keyCodeESCAPE
    JSR isKeyPressed
    BNE MainLoop
    
.exitGame
    JMP (&FFFE)


;-------------------------------------------------------------------------
; PrintString
;-------------------------------------------------------------------------
; On entry  : A contains font colour
;           : X and Y contain screen address
; On exit   : A,X and Y are undefined  
;-------------------------------------------------------------------------
.PrintString
{
    STA chrFontColour               
    STX screenAddr          
    STY screenAddr+1        
    LDY #0
.loop
    LDA (textstartaddr),Y
    BMI finished
    JSR PrintChar
    INY
    BNE loop
.finished    
    RTS
}

;-------------------------------------------------------------------------
; PrintChar
;-------------------------------------------------------------------------
; On entry  : A contains font character
; On exit   : A, X and Y are preserved
;-------------------------------------------------------------------------
.PrintChar
{
    STA saveA
    STX saveX
    STY saveY
    
    LDA #0
    STA temp            ; clear temp

    LDA saveA           ; Get font character
    CLC                 ; clear carry
    ASL A               ; *2
    ASL A               ; *4
    ASL A               ; *8
    ROL temp            ; Store carry in temp 
    STA chrFontAddr  
    
    ADC #LO(font_data)
    STA chrFontAddr     ; Calculate and store font offset low byte

    LDA #0
    ADC temp            ; Add temp
    ADC #HI(font_data)
    STA chrFontAddr+1   ; Calculate and store font offset high byte

    LDY #7              
    STY left_bit   
    LDY #15
    STY right_bit  
    
.font_loop
    LDY left_bit            ; use left_bit pointer to index into font address 7 - 0
    LDA (chrFontAddr),Y     ; Point to font data
    PHA                     ; Save font byte for left bit
    AND #$0F                ; %00001111 
    JSR GetColour           ; Get masked colour

    LDY right_bit 
    STA (screenAddr),Y      ; Draw right hand bit

    PLA                     ; Restore font byte for left bit
    LSR A                   ; /2
    LSR A                   ; /4
    LSR A                   ; /8
    LSR A                   ; /16
    JSR GetColour           ; Get masked colour

    LDY left_bit   
    STA (screenAddr),Y      ; Draw left hasnd bit

    DEC right_bit
    DEC left_bit

    LDY left_bit
    BPL font_loop           ; less than 0?
    
    ; Advance to next character position
    CLC
    LDA screenAddr
    ADC #16
    STA screenAddr
    BCC finished
    INC screenAddr+1

.finished    
    LDA saveA
    LDX saveX
    LDY saveY
    RTS
}

;-------------------------------------------------------------------------
; GetColour
;-------------------------------------------------------------------------
; On entry  : A contains bit
; On exit   : A contains coloured bit   
;-------------------------------------------------------------------------
.GetColour
{
    TAX
    LDY chrFontColour   ; Font colour
    CPY #$02            ; Colour 2
    BCC exit            ; less than 2
    LDA colour_mask,X   ; get correct colour mask data  
    CPY #$03            ; Colour 3
    BEQ exit            ; equals 3
    AND #$F0            ; %11110000
.exit
    RTS
}

.colour_mask
EQUB $00,$11,$22,$33,$44,$55,$66,$77,$88,$99,$AA,$BB,$CC,$DD,$EE,$FF

;-------------------------------------------------------------------------
; IsKeyPressed
;-------------------------------------------------------------------------
; On entry  : X contains inkey value
; On exit   : A is preserved
;           : X contains key value
;           : Y is underfined
;-------------------------------------------------------------------------
.isKeyPressed
{
    LDA #$81
    LDY #$FF
    JSR osbyte
    CPX #$FF
    RTS
}

;-------------------------------------------------------------------------
; VsyncDelay
;-------------------------------------------------------------------------
; On entry  : A contains duration
; On exit   : A contains 19   
;           : X and Y are underfined
;-------------------------------------------------------------------------
.VsyncDelay
{
    STA counter
.vsync_delayloop    
    LDA #19
    JSR osbyte

    DEC counter
    BNE vsync_delayloop
    CLI
    RTS
}

;-------------------------------------------------------------------------

.setup_screen
EQUB $16,$01                                    ; Mode 1
EQUB $17,$01,$00,$00,$00,$00,$00,$00,$00,$00    ; Hide cursor
EQUB $FF

.scoreboard1
EQUS "0123456789 ABCDEFGHIJKLMNOPQRSTUVWXYZ",$FF

.font_data
INCBIN "Fonts.bin"

\ ******************************************************************
\ *	End address to be saved
\ ******************************************************************
.end

\ ******************************************************************
\ *	Save the code
\ ******************************************************************

SAVE "Font1", start, end

\\ run command line with this
\\ beebasm -v -i Font1.asm -do Font1.ssd



