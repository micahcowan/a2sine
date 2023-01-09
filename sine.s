;#define CFGFILE apple2-asm.cfg
;#link "signlib.s"
;#link "sinecalc.s"


.import Sine, SineCalcRun, SineCalcTimersAdvance

.macpack apple2

.org $803

Mon_HOME = $FC58
Mon_CH   = $24
Mon_CV   = $25
Mon_BASL = $28
Mon_BASH = $29
Mon_VTAB = $FC22
Mon_WAIT = $FCA8
COUT	 = $FDED

KBD	 = $C000
KBDSTROBE= $C010

MsgAddrL = $6
MsgAddrH = $7
PrevBASL = $8
PrevBASH = $9

VCenter   = 12
VAmp      = 11
HCenter   = 17
HAmp      = 17
Delay     = $19

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
        jsr LoadNextAnim
SineAnimLoop:
	;; Print static messages
        lda Mon_BASL
        pha
        lda Mon_BASH
        pha
        lda MsgAddrL
        pha
        lda MsgAddrH
        pha
        ;
        lda #$00
        sta Mon_BASL
        lda #$04
        sta Mon_BASH
        ; Print "PRESS ANY KEY"
        lda #<PressKeyMsg
        sta MsgAddrL
        lda #>PressKeyMsg
        sta MsgAddrH
        jsr PrintMsg
        ; Print effect number
        lda CurAnimNum
        ora #$B0
        ldy #20
        sta (Mon_BASL),y
        ; Print animation label
        lda #22
        sta Mon_BASL
        lda CurLabel
        sta MsgAddrL
        lda CurLabel+1
        sta MsgAddrH
        jsr PrintMsg
        ;
        pla
        sta MsgAddrH
        pla
        sta MsgAddrL
        pla
        sta Mon_BASH
        pla
        sta Mon_BASL
	;; Print the message
        jsr EraseMsg
	jsr PrintMsg
        
        lda Mon_BASL
        sta PrevBASL
        lda Mon_BASH
        sta PrevBASH

	lda #<SC_VObj
        ldy #>SC_VObj
        jsr SineCalcRun
        sta Mon_CV
        
        lda #<SC_HObj
        ldy #>SC_HObj
        jsr SineCalcRun
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
        lda #<Timers
        ldy #>Timers
        jsr SineCalcTimersAdvance
        jsr CheckAnimSwitch
        rts

CheckAnimSwitch:
	bit KBD
        bpl LoadAnimDone
        bit KBDSTROBE
LoadNextAnim:
        ; Key is pressed! Advance to next animation
        inc CurAnimNum
        lda CurAnim
        clc
        adc #6
        sta CurAnim
        lda CurAnim+1
        adc #0 ; for carry
        sta CurAnim+1
        ; Did we go past the end?
        cmp #>AnimsEnd
        bcc @setCurrent
        bne @loopToFirst ; past the end, go to first anim
        ; If we get here, hi byte is eq, check lo
        lda CurAnim
        cmp #<AnimsEnd
        bcc @setCurrent
@loopToFirst:
	lda #0
        sta CurAnimNum
	lda #<AnimsStart
        sta CurAnim
        lda #>AnimsStart
        sta CurAnim+1
@setCurrent:
	txa
        pha
        tya
        pha
	lda $0
        pha
        lda $1
        pha
            lda CurAnim
            sta $0
            lda CurAnim+1
            sta $1
            ;
            ldy #0
            lda ($0),y
            sta SC_HObj,y
            iny
            lda ($0),y
            sta SC_HObj,y
            iny
            lda ($0),y
            ldx #0
            sta SC_VObj,x
            inx
            iny
            lda ($0),y
            sta SC_VObj,x
            iny
            lda ($0),y
            sta CurLabel
            iny
            lda ($0),y
            sta CurLabel+1
        pla
        sta $1
        pla
        sta $0
        pla
        tay
        pla
        tax
LoadAnimDone:
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
	scrcode "HELLO"
        .byte 0
	.byte 'H' & $1F
        .byte 'E' & $1F
        .byte 'L' & $1F
        .byte 'L' & $1F
        .byte 'O' & $1F
        .byte 0
PressKeyMsg:
	scrcode "PRESS ANY KEY"
        .byte 0

HCircle:
	.byte HAmp
        .byte 0
        .byte 'T' | $80 ; timer 0
        .byte 'S' | $80 ; sine
        .byte HCenter
        .byte '+' | $80 ; add
        .byte 'R' | $80 ; return

HTreble:
	.byte HAmp
        .byte 3
        .byte 'T' | $80 ; timer 0
        .byte 'S' | $80 ; sine
        .byte HCenter
        .byte '+' | $80 ; add
        .byte 'R' | $80 ; return
        
VCircle:
	.byte VAmp
        .byte 0
        .byte 'T' | $80 ; timer 0
        .byte $60
        .byte '+' | $80 ; add #$C0
        .byte $60
        .byte '+' | $80
        .byte 'S' | $80 ; sine
        .byte VCenter
        .byte '+' | $80 ; add center
        .byte 'R' | $80 ; return
        
VTreble:
	.byte VAmp
        .byte 2
        .byte 'T' | $80 ; timer 0
        .byte $40
        .byte '+' | $80 ; add #$40
        .byte 'S' | $80 ; sine
        .byte VCenter
        .byte '+' | $80 ; add center
        .byte 'R' | $80 ; return
        
VWobble:
	.byte VAmp
        .byte 1
        .byte 'T' | $80 ; timer 0
        .byte $40
        .byte '+' | $80 ; add #$40
        .byte 'S' | $80 ; sine
        .byte VCenter
        .byte '+' | $80 ; add center
        .byte 'R' | $80 ; return
        
HSpiral:
	.byte HAmp
        ; subtract a few
        .byte 8
        .byte '-' | $80
        .byte 4
        .byte 4
        .byte 'T' | $80 ; timer 0
        .byte $60
        .byte '+' | $80
        .byte $60
        .byte '+' | $80
        .byte 'S' | $80 ; sine
        .byte '+' | $80
        .byte 0
        .byte 'T' | $80 ; timer 0
        .byte 'S' | $80 ; sine
        .byte HCenter
        .byte '+' | $80 ; add
        .byte 'R' | $80 ; return
        
VSpiral:
	.byte VAmp
        ; subtract a few
        .byte 5
        .byte '-' | $80
        .byte 4
        .byte 4
        .byte 'T' | $80 ; timer 0
        .byte $60
        .byte '+' | $80
        .byte $60
        .byte '+' | $80
        .byte 'S' | $80 ; sine
        .byte '+' | $80
        .byte 0
        .byte 'T' | $80 ; timer 0
        .byte $60
        .byte '+' | $80 ; add #$C0
        .byte $60
        .byte '+' | $80
        .byte 'S' | $80 ; sine
        .byte VCenter
        .byte '+' | $80 ; add center
        .byte 'R' | $80 ; return

HTickTock:
	; sinusoidal amp input to "main" movement
        .byte 0
	.byte HAmp
        .byte '-' | $80
        .byte 5
        .byte 'T' | $80
        .byte 'S' | $80
        ; end amplitude
        .byte 6
        .byte 'T' | $80 ; timer 0
        .byte 'S' | $80 ; sine
        .byte HCenter
        .byte '+' | $80 ; add
        .byte 'R' | $80 ; return

VTickTock:
	; sinusoidal amp input to "main" movement
	.byte VAmp
        .byte 5
        .byte 'T' | $80
        .byte $40
        .byte '+' | $80
        .byte 'S' | $80
        ; end amplitude
        .byte 6
        .byte 'T' | $80 ; timer 0
        .byte 'S' | $80 ; sine
        .byte VCenter-1
        .byte '+' | $80 ; add
        .byte 'R' | $80 ; return

AnimsStart:
.word HCircle, VCircle, LCircle
.word HTreble, VTreble, LTreble
.word HCircle, VWobble, LWobble
.word HTickTock, VTickTock, LTickTock
.word HSpiral, VSpiral, LSpiral
AnimsEnd:

LCircle:
	scrcode "CIRCLE    "
        .byte 0
LTreble:
	scrcode "TREBLE    "
        .byte 0
LWobble:
	scrcode "WOBBLE    "
        .byte 0
LTickTock:
	scrcode "TICK-TOCK"
        .byte 0
LSpiral:
	scrcode "SPIRAL    "
        .byte 0

CurAnimNum:
	.byte 0
CurAnim:
	.word AnimsEnd
CurLabel:
	.word 0

SC_HObj:
	.word 0
        ; timer info: 1 timer: rise / run, val (offset)
        .word Timers

SC_VObj:
	.word 0
        ; timer info: 1 timer: rise / run, val
        .word Timers
        
Timers:
	.byte 7
	.byte 1,1,0,0
	.byte 39,41,0,0
        .byte 25,18,0,0
	.byte 17,29,0,0
        .byte 1,8,0,0
        .byte 1,41,0,0
        .byte 11,5,0,0
