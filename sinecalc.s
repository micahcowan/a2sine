.import Sine
.export SineCalcRun, SineCalcTimersAdvance

InstrPtr = $0
TimersPtr= $2

;; NOT RE-ENTRANT
SineCalcRun:
	sta SavedA
        stx SavedX
        sty SavedY
        jsr SaveAndInstallZp
        ;
        ldy #0
        sty StackCtr
        jmp FirstIter
NextInstr:
	inc InstrPtr
        bne FirstIter
        inc InstrPtr+1
FirstIter:
        ; Get an instruction
        ldy #0
        lda (InstrPtr),y
        cmp #$80 ; is it an isntruction?
        bcs IsInstr ; yes -> handle
        ; Not an instruction: push to internal stack
        jsr PushVal
        jmp NextInstr
IsInstr:; If we get here, it's an instruction.
	and #$7F ; just get at ASCII val of instr
	cmp #'T'
        bne :+
        jmp TimerPop
:       cmp #'+'
	bne :+
        jmp HandleAdd
:       cmp #'S'
        bne :+
        jmp HandleSine
:       ; 'R' or unrecognized cmd: fall thru
SineCalcOut:
	;
        jsr RestoreZp
        ldx SavedX
        jsr PopVal
	rts
SavedA:
	.byte 0
SavedX:
	.byte 0
SavedY:
	.byte 0
StackCtr:
	.byte 0
        
SaveAndInstallZp:
	jsr SaveZp
        ; First, copy A, Y addr into ZP
        lda SavedA
        sta $0
        ldy SavedY
        sty $1
        ; Copy timers addr into ZP
        ldy #TimersPtr
        lda ($0),y
        sta $2
        iny
        lda ($0),y
        sta $3
        ; Now copy commands addr, overwriting $0
        ldy #InstrPtr
        lda ($0),y
        tax
        iny
        lda ($0),y
        stx $0
        sta $1
	rts

SaveZp:
	ldx #0
@lp:    lda $0,x
        sta SavedZp, x
        inx
        cpx #SavedZpLen
        bcc @lp
@out:   rts
        
RestoreZp:
        ldx #0
@lp:    lda SavedZp, x
        sta $0,x
        inx
        cpx #SavedZpLen
        bcc @lp
@out:   rts

SineCalcTimersAdvance:
        sta SavedA
        sty SavedY
        lda TimersPtr
        pha
        lda TimersPtr+1
        pha
            lda SavedA
            sta TimersPtr
            lda SavedY
            sta TimersPtr+1
            ;
            ; FIXME: for now, assume there is 1 timer
            ldy #3
            lda (TimersPtr),y
            clc
            adc #1
            sta (TimersPtr),y
        pla
        sta TimersPtr+1
        pla
        sta TimersPtr
	rts

PushVal:
	;; WARNING: unguarded stack access!
	ldy StackCtr
	sta SCStack, y
        inc StackCtr
        rts

PopVal:
	;; WARNING: unguarded stack access!
        dec StackCtr
        ldy StackCtr
        lda SCStack, y
        rts

;;;; Instruction Handlers ;;;;

; Input: TIM#
; Output: TVAL
TimerPop:
	jsr PopVal
	; FIXME: For now, assume it was timer 0 of 1
        ldy #3
        lda (TimersPtr),y
        jsr PushVal
	jmp NextInstr

; Input: AMP PHASE
; Output: SINE
HandleSine:
	jsr PopVal
        tax
        jsr PopVal
        jsr Sine
        jsr PushVal
        jmp NextInstr

; Input: A B
; Output: SUM
HandleAdd:
	jsr PopVal
        sta @tmp
        jsr PopVal
        clc
        adc @tmp
        jsr PushVal
        jmp NextInstr
@tmp: .byte 0

;;;;

SavedZp:
	.res 4
SavedZpLen = * - SavedZp

SCStack:
	.res 16
SCStackLen = * - SCStack
