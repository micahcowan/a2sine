;#define CFGFILE apple2-asm.cfg
;#link "signlib.s"
;#link "sinecalc.s"


.import Sine, SineCalcRun, SineCalcTimersAdvance

.org $803

Mon_HOME = $FC58
Mon_CH   = $24
Mon_CV   = $25
Mon_BASL = $28
Mon_BASH = $29
Mon_VTAB = $FC22
Mon_WAIT = $FCA8
COUT	 = $FDED

MsgAddrL = $6
MsgAddrH = $7
PrevBASL = $8
PrevBASH = $9

VCenter    = 12
VAmp      = 12
HCenter   = 20
HAmp      = 8
Delay     = $20

SineStart:
	jsr Mon_HOME
        lda #<Message
        sta MsgAddrL
        lda #>Message
        sta MsgAddrH
        ; Set up message position
        lda #VCenter
        sta Mon_CV
        jsr Mon_VTAB
        lda #HCenter
        sta Mon_CH
        ; Add to BASL
        clc
        adc Mon_BASL
        sta Mon_BASL
SineAnimLoop:
	;; Print the message
        jsr EraseMsg
	jsr PrintMsg
        
        lda Mon_BASL
        sta PrevBASL
        lda Mon_BASH
        sta PrevBASH

.if 0
VPhase   = $1D
HPhase   = $1E
        ;; Find the new vert position
        lda #VAmp
        ldx VPhase
        jsr Sine
        clc
        ; Add to "center"
        adc #VCenter
	sta Mon_CV
        
        ;; Find the new horiz position
        
        lda #HAmp
        ldx HPhase
        jsr Sine
        clc
        adc #HCenter
        sta Mon_CH
.else
	lda #<SC_VObj
        ldy #>SC_VObj
        jsr SineCalcRun
        sta Mon_CV
        
        lda #<SC_HObj
        ldy #>SC_HObj
        jsr SineCalcRun
        sta Mon_CH
.endif

	; Recalc screen locations
        jsr Mon_VTAB
        ; Add to BASL
        clc
        lda Mon_CH
        adc Mon_BASL
        sta Mon_BASL
        
        jsr Advance ; advance sine period (x-reg)
	lda Mon_CH ; Load for message-printing
        jmp SineAnimLoop

Advance:
	; incrementing every frame is way too
        ; freaking fast. Slow it down.
        lda #Delay
        jsr Mon_WAIT
        lda #<Timers
        ldy #>Timers
        jsr SineCalcTimersAdvance
        rts

EraseMsg: ; print and return to original CH
	ldy #0
        lda Mon_CH
@lp:    lda (MsgAddrL),y
        beq @out
        lda #$A0
        sta (PrevBASL),y
        iny
        bne @lp
@out:   rts

PrintMsg: ; print and return to original CH
	ldy #0
        lda Mon_CH
@lp:    lda (MsgAddrL),y
        beq @out
        sta (Mon_BASL),y
        iny
        bne @lp
@out:   rts

EmitYSpaces:
	dey
        iny
        beq @spaceEnd
        lda #$A0
@spaceLoop:
	jsr COUT
        dey
        bne @spaceLoop
@spaceEnd:
	rts

Message:
	.byte "HELLO",0

HCalc:
	.byte HAmp
        .byte 0
        .byte 'T' | $80 ; timer 0
        .byte 'S' | $80 ; sine
        .byte HCenter
        .byte '+' | $80 ; add
        .byte 'R' | $80 ; return
        
VCalc:
	.byte VAmp
        .byte 0
        .byte 'T' | $80 ; timer 0
        .byte $40
        .byte '+' | $80 ; add #$40
        .byte 'S' | $80 ; sine
        .byte VCenter
        .byte '+' | $80 ; add center
        .byte 'R' | $80 ; return

SC_HObj:
	.word HCalc
        ; timer info: 1 timer: rise / run, val (offset)
        .word Timers

SC_VObj:
	.word VCalc
        ; timer info: 1 timer: rise / run, val
        .word Timers
        
Timers:
	.byte 1
        .byte 1, 1, 0
