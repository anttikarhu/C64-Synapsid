; ALLOWS ONE TO START THE APPLICATION WITH RUN
; SYS 2064
*=$0801 
         BYTE $0C, $08, $0A, $00, $9E, $20, $32, $30, $36, $34, $00, $00, $00, $00, $00

CIA1IRQ         = $DC0D
RASTERREG       = $D011
IRQRASTER       = $D012
IRQADDRMSB      = $0314
IRQADDRLSB      = $0315
IRQCTRL         = $D01A
IRQFLAG         = $D019
IRQFINISH       = $EA31
PORTREGA        = $DC00
PORTREGB        = $DC01
DATADIRA        = $DC02
DATADIRB        = $DC03

F_LSB1          = $D400
F_MSB1          = $D401
CTRL1           = $D404
ATT_DEC1        = $D405
SUS_REL1        = $D406
VFMODE          = $D418


INIT    LDA #%01111111 ; SWITCH OFF CIA-1 INTERRUPTS
        STA CIA1IRQ

        AND RASTERREG ; CLEAR VIC RASTER REGISTER
        STA RASTERREG

        LDA #250 ; SETUP PLAY INTERRUPT AT RASTER LINE 250 FOR TIMING
        STA IRQRASTER
        LDA #<PLAYIRQ
        STA IRQADDRMSB
        LDA #>PLAYIRQ
        STA IRQADDRLSB

        LDA #%00000001 ; RE-ENABLE RASTER INTERRUPTS ONLY AFTER SETUP
        STA IRQCTRL

        ; INITIALIZE FREQUENCIES. NOTE "A-3" ACCORDING TO http://sta.c64.org/cbm64sndfreq.html
        LDA #$8F
        STA F_LSB1
        LDA #$0E
        STA F_MSB1

        ; SETUP VOICE 1
        ; SAW TOOTH (BIT 5), CLOSED GATE (BIT 0)
        LDA #%00100000
        STA CTRL1
        ; FAST ATTACH (BITS 7-4) & DECAY (BITS 3-0)
        LDA #%00000000
        STA ATT_DEC1
        ; LONG SUSTAIN (BITS 7-4) AND FAST RLEASE (BITS 3-0)
        LDA #%11110000
        STA SUS_REL1
        ; NO FILTERS (BITS 7-4) AND FULL VOLUME (BITS 3-0)
        LDA #%00001111
        STA VFMODE

        ; TODO:
        ; EXPLAIN TO MYSELF HOW KEYBOARD READ WORKS
        ; TODO:
        ; NOW KEYS ARE CHECKED AND NOTES ARE UPDATED CONSTANTLY, 
        ; MAYBE SHOULD DETECT 'KEYPRESS EVENTS' INSTEAD AND CHANGE NOTES
        ; ONLY WHEN THE KEYPRESSES CHANGE? THIS WAY I QUESS THE ADSR STUFF
        ; SHOULD WORK BETTER THAN NOW.    
LOOP    LDA #%11111111
        STA DATADIRA           
        LDA #%00000000
        STA DATADIRB   

CHK_C   ; DETECT KEY 'Z' DOWN
        LDA #%11111101
        STA PORTREGA
        LDA PORTREGB
        AND #%00010000 
        BEQ NOTE_C

CHK_D   ; 'X'
        LDA #%11111011
        STA PORTREGA
        LDA PORTREGB
        AND #%10000000 
        BEQ NOTE_D

CHK_E   ; 'C'
        LDA #%11111011
        STA PORTREGA
        LDA PORTREGB
        AND #%00010000 
        BEQ NOTE_E

CHK_F   ; 'V'
        LDA #%11110111
        STA PORTREGA
        LDA PORTREGB
        AND #%10000000 
        BEQ NOTE_F

CHK_G   ; 'B'
        LDA #%11110111
        STA PORTREGA
        LDA PORTREGB
        AND #%00010000 
        BEQ NOTE_G

CHK_A   ; 'N'
        LDA #%11101111
        STA PORTREGA
        LDA PORTREGB
        AND #%10000000 
        BEQ NOTE_A

CHK_B   ; 'M'
        LDA #%11101111
        STA PORTREGA
        LDA PORTREGB
        AND #%00010000 
        BEQ NOTE_B

CHK_C2  ; ','
        LDA #%11011111
        STA PORTREGA
        LDA PORTREGB
        AND #%10000000 
        BEQ NOTE_C2

CHK_Q   ; 'STOP'
        LDA #%01111111
        STA PORTREGA
        LDA PORTREGB
        AND #%10000000 
        BEQ QUIT

NO_NOTE ; NO KEYS PRESSED
        LDA #%00100000
        STA CTRL1
        JMP LOOP

NOTE_C  ; SET FREQUENCEY FOR 'C-3' AND OPEN GATE
        LDX #$A8
        LDY #$08
        JSR PLAYNOTE
        JMP LOOP

NOTE_D  
        LDX #$B7
        LDY #$09
        JSR PLAYNOTE
        JMP LOOP

NOTE_E
        LDX #$E8
        LDY #$0A
        JSR PLAYNOTE
        JMP LOOP

NOTE_F
        LDX #$8E
        LDY #$0B
        JSR PLAYNOTE
        JMP LOOP

NOTE_G
        LDX #$F8
        LDY #$0C
        JSR PLAYNOTE
        JMP LOOP

NOTE_A
        LDX #$8F
        LDY #$0E
        JSR PLAYNOTE
        JMP LOOP

NOTE_B
        LDX #$57
        LDY #$10
        JSR PLAYNOTE
        JMP LOOP

NOTE_C2
        LDX #$50
        LDY #$11
        JSR PLAYNOTE
        JMP LOOP

QUIT    LDA #0 ; CLEAR SID VOLUME AND FILTERS,
        STA VFMODE
        LDA #0 ; CLEAR VOICE 1 CONTROL,
        STA CTRL1
        RTS ; AND THEN QUIT

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PLAYNOTE
        ; SUBROUTINE THAT SETS A FREQUENCY AND OPENS GATE FOR VOICE 1
        ; X REGISTER = FREQ LSB
        ; Y REGISTER = FREQ MSB
        STX X_ST ; STORE X AND Y TEMPORARILY
        STY Y_ST
        PHA ; PUSH A, X AND Y TO STACK TO BE A GOOD CITIZEN,
        TXA
        PHA
        TYA
        PHA
        LDX X_ST ; AND GET X AND Y BACK FROM MEMORY
        LDY Y_ST
     
        STX F_LSB1
        STA F_MSB1
        LDA #%00100001
        STA CTRL1

        PLA ; GET Y, X AND A BACK FROM THE STACK,
        TAY
        PLA
        TAX
        PLA
        RTS ; AND END THE SUBROUTINE.
X_ST    BYTE $00
Y_ST    BYTE $00
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PLAYIRQ 
        ASL IRQFLAG ; RESET IRQ FLAG
        JMP IRQFINISH ; LET MACHINE HANDLE OTHER IRQS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;