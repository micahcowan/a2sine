;#define CFGFILE apple2-asm.cfg
;#link "signlib.s"

.import Sine

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
VPhase   = $1D
HPhase   = $1E

VCenter    = 12
VAmp      = 12
HCenter   = 20
HAmp      = 8
Delay     = $20

SineStart:
	jsr Mon_HOME
        ldx #0
        stx VPhase
        ldx #$40
        stx HPhase
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
        inc VPhase
        inc HPhase
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
