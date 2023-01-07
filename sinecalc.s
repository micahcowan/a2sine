.import Sine
.export SineCalcRun, SineCalcTimersAdvance

SineCalcRun:
	jsr SineCalcRunReal
	lda #11
VPhase   = $1D
        ;; Find the new vert position
        lda #10
        ldx VPhase
        jsr Sine
        clc
        ; Add to "center"
        adc #11
	rts

XXXPreloadZp:
	lda #1
        sta $0
        lda #2
        sta $1
        lda #3
        sta $2
        lda #4
        sta $3
        lda #$60
        sta XXXPreloadZp
	rts

;; NOT RE-ENTRANT
SineCalcRunReal:
	sta SavedA
        stx SavedX
        sty SavedY
	jsr XXXPreloadZp
        jsr SaveAndInstallZp
        nop
        jsr RestoreZp
	rts
SavedA:
	.byte 0
SavedX:
	.byte 0
SavedY:
	.byte 0
        
SaveAndInstallZp:
	jsr SaveZp
        ; First, copy A, Y addr into ZP
        lda SavedA
        sta $0
        ldy SavedY
        sty $1
        ; Copy timers addr into ZP
        ldy #2
        lda ($0),y
        sta $2
        iny
        lda ($0),y
        sta $3
        ; Now copy commands addr, overwriting $0
        ldy #0
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
	inc VPhase
	rts

SavedZp:
	.res 4
SavedZpLen = * - SavedZp
