; Ping Pong
; Domenic Simone
; 2019

*=$0801                 ; Entry Point

player_pos = $0334      ; Player Y position

ball_posx = $0335       ; Ball X position
ball_posy = $0336       ; Ball Y position
ball_dx = $0337         ; Ball speed X
ball_dy = $0338         ; Ball speed Y
ball_dir = $0339        ; Ball dicrection of movement 
                        ;#%0000 x off = left, #%0001 x on = right
                        ;#%0000 y off = up, #%0010 y on = down

; Load from BASIC
        BYTE $0c,$08,$0a,$00,$9e,$20,$32,$30,$36,$32,$00,$00,$00


; Screen setup
        lda #$00
        sta $d020
        sta $d021
        ldx #$00  

; Clear screen
clear   lda #$20
        sta $0400,x
        sta $0500,x
        sta $0600,x
        sta $0700,x 
        lda #$0f
        sta $d800,x
        sta $d900,x
        sta $da00,x
        sta $dae8,x
        inx
        bne clear

; Stage setup
        ldx #$00        ; load stage data into screen memory
lds     lda _stage_data,x
        sta $0400,x
        lda _stage_data+#$0100,x
        sta $0500,x
        lda _stage_data+#$0200,x
        sta $0600,x
        lda _stage_data+#$0300,x
        sta $0700,x
        inx
        bne lds

; Clear sprite area
        lda #$00
        ldx #$ff
clsp    sta $3ec0,x
        dex
        bne clsp

; Sprites Setup
; Sprite 0 Player
; Sprite 1 Ball
        lda #$80      
        sta $07f8       ; Set pointer of sprite 0
        lda #$81
        sta $07f9       ; Set pointer of sprite 1
        lda #$03        
        sta $d015       ; Enable sprite 0 and 1
        lda #$01
        sta $d010       ; Sprite 0 256 flag on 
        sta $d017       ; Double sprite 0 height
        lda #$40        
        sta $d000       ; Sprite 0 X to 256 + 64 = 320
        lda #$60
        sta player_pos
        sta $d001       ; Sprite 0 Y to 96
        lda #$0D
        sta $d027       ; Sprite 0 Color 13
        lda #$80
        sta ball_posx
        sta ball_posy
        sta $d002       ; Sprite 1 X
        sta $d003       ; Sprite 1 Y
        lda #$01
        sta ball_dx     ; Ball X speed 1
        sta ball_dy     ; Ball Y speed 1
        lda #$03
        sta ball_dir    ; Ball dir x on, y on

hk      lda $dc00       ; Wait for fire button
        and #$10
        cmp #$10
        beq hk

_game_loop
; Check Joystick/Player
        lda $dc00       ; Joystick
        and #$01        ; Mask Up
        cmp #$01        ; If not up
        beq no_up       ; then skip
        lda player_pos
        sbc #$01
        sta player_pos  ; Move player up
no_up
        lda $dc00       ; Joystick
        and #$02        ; Mask Down
        cmp #$02        ; If not down
        beq no_down     ; then skip
        lda player_pos
        adc #$02
        sta player_pos  ; Move player down
no_down
; Check Ball
        lda $D01E       ; Get sprite hit detection
        and #$02        ; Mask Sprite 1
        cmp #$02        ; If sprite 1 not hit
        bne hit_skip    ; then skip
        lda ball_dir    ; Change ball dir
        and #$02        ; turn x off
        sta ball_dir
hit_skip
        lda ball_dir    ; If ball dir
        and #$01        ; x
        cmp #$01        ; is not 1
        bne ballx_skip  ; then skip
        lda ball_posx   ; If ball pos x
        cmp #$fe        ; is not 254
        bne ballx_skip  ; then skip
        lda #$03        ; update ball x 256 flag on
        sta $d010
        lda #$ff
        sta ball_posx
ballx_skip
        lda ball_dir    ; If ball dir
        and #$01        ; x
        cmp #$01        ; is 1
        beq ballx_rh    ; then skip
        lda ball_posx   ; If ball pos x
        cmp #32         ; is not 32
        bne ballx_ls    ; then skip
        lda ball_dir    ; Change ball dir
        ora #$01        ; turn x on
        sta ball_dir
ballx_ls
        lda ball_posx   ; If ball x
        cmp #$01        ; is not 1
        bne ballx_rh    ; then skip
        lda #$01        ; update ball x 256 flag off
        sta $d010
        lda ball_dir    ; update ball dir
        and #$02        ; x off
        sta ball_dir
        lda #$fe        ; update ball x pos
        sta ball_posx
ballx_rh
        lda ball_posy   ; If ball y
        cmp #$de        ; is not 222
        bne bd_yu_skip  ; then skip
        lda ball_dir    ; update ball dir
        and #$01        ; y off
        sta ball_dir    
bd_yu_skip
        lda ball_posy   ; If ball y
        cmp #$38        ; is not 56
        bne bd_yd_skip  ; then skip
        lda ball_dir    ; update ball dir
        ora #$02        ; y on
        sta ball_dir    
bd_yd_skip
        lda ball_dir    ; Update ball pos
        and #$01        ; if x
        cmp #$01        ; is on
        beq adc_x_ball  ; skip
        lda ball_posx   
        sbc ball_dx     ; move ball left
        sta ball_posx   ; Update Ball x
        jmp cball_y
adc_x_ball              ; else
        lda ball_posx
        adc ball_dx     ; Move ball right
        sta ball_posx   ; Update Ball x
cball_y
        lda ball_dir    ; If ball dir
        and #$02        ; y
        cmp #$02        ; is not on
        beq adc_y_ball  ; skip
        lda ball_posy
        sbc ball_dy     ; move ball up
        sta ball_posy
        jmp fwait
adc_y_ball              ; else
        lda ball_posy
        adc ball_dy     ; move ball down
        sta ball_posy   ; Update Ball y

fwait   lda #$ff        ; Wait for next frame
        cmp $d012
        bne fwait
        lda ball_posx   ; Update sprites
        sta $d002       ; Update sprite 1 x
        lda ball_posy
        sta $d003       ; Update sprite 1 y
        lda player_pos
        sta $d001       ; Update sprite 0 y
        jmp _game_loop
        rts             ; Return to basic 

; Stage 1 -  Screen data
_stage_data
        BYTE    $6C,$62,$62,$62,$62,$62,$62,$62,$62,$62,$62,$62,$62,$62,$62,$62,$62,$62,$62,$62,$62,$62,$62,$62,$62,$62,$62,$62,$62,$62,$62,$62,$62,$62,$62,$62,$62,$62,$62,$62
        BYTE    $E1,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$E1,$61,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
        BYTE    $E1,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$E1,$61,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
        BYTE    $E1,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$E1,$61,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
        BYTE    $E1,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
        BYTE    $E1,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$E1,$61,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
        BYTE    $E1,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$E1,$61,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
        BYTE    $E1,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$E1,$61,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
        BYTE    $E1,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
        BYTE    $E1,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$E1,$61,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
        BYTE    $E1,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$E1,$61,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
        BYTE    $E1,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$E1,$61,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
        BYTE    $E1,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
        BYTE    $E1,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$E1,$61,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
        BYTE    $E1,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$E1,$61,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
        BYTE    $E1,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$E1,$61,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
        BYTE    $E1,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
        BYTE    $E1,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$E1,$61,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
        BYTE    $E1,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$E1,$61,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
        BYTE    $E1,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$E1,$61,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
        BYTE    $E1,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
        BYTE    $E1,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$E1,$61,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
        BYTE    $E1,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$E1,$61,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
        BYTE    $E1,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$E1,$61,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
        BYTE    $7C,$E2,$E2,$E2,$E2,$E2,$E2,$E2,$E2,$E2,$E2,$E2,$E2,$E2,$E2,$E2,$E2,$E2,$E2,$E2,$E2,$E2,$E2,$E2,$E2,$E2,$E2,$E2,$E2,$E2,$E2,$E2,$E2,$E2,$E2,$E2,$E2,$E2,$E2,$E2

; Player Sprite
*=$2000
        INCBIN "paddle.bin"
; Ball Sprite
*=$2040
        INCBIN "ball.bin"
