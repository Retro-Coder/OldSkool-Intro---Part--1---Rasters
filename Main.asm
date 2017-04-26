; 10 SYS2064

*=$0801

    BYTE    $0B, $08, $0A, $00, $9E, $32, $30, $36, $34, $00, $00, $00
    
*=$0810

START                   SEI                             ; Set Interrupt disabled flag to prevent interrupts

                        LDA #$7F                        ; C64 has system set to recieve interrupts from CIA #1
                        STA $DC0D                       ; so we need to disable those 

                        LDA #<irq1                      ; Set lo-byte of 
                        STA $0314                       ; IRQ Vector
                        LDA #>irq1                      ; Set hi-byte on
                        STA $0315                       ; IRQ Vector
                        
                        LDA #$32                        ; Set rasterline 
                        STA $D012                       ; where we want interrupt
                        LDA #$1B                        ; Set default value of $D011 with highest bit clear because 
                        STA $D011                       ; it serve as highest bit of rasterline (for lines 256 - ...)
                        
                        LDA $DC0D                       ; Acknowledge CIA #1 interrupts incase they happened
                        LDA #$FF                        ; Acknowledge all VIC II
                        STA $D019                       ; interrupts
                        
                        LDA #$01                        ; And as LAST thing, enable raster interrupts on
                        STA $D01A                       ; VIC II 
                        
                        CLI                             ; Clear Interrupt disabled flag to allow interrupts again
                        
@waitSpace              LDA $DC01                       ; Check if 
                        AND #$10                        ; space is pressed?
                        BNE @waitSpace                  ; If not, keep waiting...

                        JMP $FCE2                       ; Reset C64...

irq1                    LDY $D012                       ; Load current rasterline to Y register
                        LDX #$3F                        ; We want 64 lines of rasters, so load X with value 63 ($3f hex)
@rasterColorLoop        LDA rasterColors,X              ; Load color from table of raster colors with offset of X
@rasterWait             CPY $D012                       ; is rasterline still same?
                        BEQ @rasterWait                 ; loop as long as it is
                        STA $D021                       ; set color if it's new rasterline
                        
                        INY                             ; increment Y register by 1 for next line comparison
                        DEX                             ; decrement X so we get different color for next line
                        BPL @rasterColorLoop            ; result is still positive we have lines left so loop...

                        LDX #$08                        ; Small delay loop
@dummyDelay             DEX                             ; to time next color change
                        BNE @dummyDelay                 ; 
                        LDA #$06                        ; change background                     
                        STA $D021                       ; color to dark blue
                        
                        ; NOP                           ; EXTRA DELAY for NTSC version of C64...
                                                        ; Correct timings are depending how many cycles there are
                                                        ; on each raster line... 
                        
                        LDA #$FF                        ; Acknowledge all VIC II
                        STA $D019                       ; interrupts

                        JSR moveRasters                 
                        
                        JMP $EA81                       ; Jump to last part of KERNALs regular interrupt service routine
                  
moveRasters             LDX #$37                        ; Loop
@moveLoop               LDA rasterColors,x              ; to move
                        STA rasterColors+8,x            ; raster colors 8 pixels different position
                        DEX                             ; to create one character high line of moving
                        BPL @moveLoop                   ; colorblocks
                        
                        LDX #$07                        ; We need 8 more colors (0..7 = 8)...
                        LDY colorPos                    ; Read position in our colorbar table to Y
@newColorsLoop          TYA                             ; Transfer Y to A
                        AND #$3F                        ; 64 colors in colorBars, so limit value to $00..$3f (0..64 dec) 
                        TAY                             ; Transfer A back to Y
                        LDA colorBars,Y                 ; load color from colorBars with offset of Y
                        STA rasterColors,X              ; store new color to rasterColors with offset of X
                        INY                             ; Increment Y
                        DEX                             ; Decrement X
                        BPL @newColorsLoop              ; result is still positive we have lines left so loop...
                        INC colorPos                    ; Increase value of colorPosition with 1
                        RTS                             ; We're done so RETURN
                                  
colorPos                BYTE $00                        ; Position in our colorBar table

rasterColors            DCB $40, $00                    ; Define Constant Bytes, $40 bytes (64 dec) of value $00

colorBars               BYTE $00, $00, $09, $09, $08, $08, $0A, $0A     ; brown orange
                        BYTE $07, $07, $01, $01, $07, $07, $0A, $0A     ; yellowish
                        BYTE $08, $08, $09, $09, $00, $00, $00, $00     ; color bar
                        BYTE $00, $00, $00, $00, $00, $00, $00, $00     ; 

                        BYTE $00, $00, $0B, $0B, $05, $05, $03, $03     ; greenish
                        BYTE $0D, $0D, $01, $01, $0D, $0D, $03, $03     ; color bar
                        BYTE $05, $05, $0B, $0B, $00, $00, $00, $00     ; 
                        BYTE $00, $00, $00, $00, $00, $00, $00, $00     ; 