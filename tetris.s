.data
.align 4

board:
    .zero 200

fixed_board:
    .zero 200

mino_data:
    // I
    .word 0, 1, 2, 3
    .word 0, 10, 20, 30
    .word 0, 1, 2, 3
    .word 0, 10, 20, 30
    // O
    .word 0, 1, 10, 11
    .word 0, 1, 10, 11
    .word 0, 1, 10, 11
    .word 0, 1, 10, 11
    // T
    .word 0, 1, 2, 11
    .word 0, 10, 11, 20
    .word 1, 10, 11, 12
    .word 1, 10, 11, 21
    // S
    .word 1, 2, 10, 11
    .word 0, 10, 11, 21
    .word 1, 2, 10, 11
    .word 0, 10, 11, 21
    // Z
    .word 0, 1, 11, 12
    .word 1, 10, 11, 20
    .word 0, 1, 11, 12
    .word 1, 10, 11, 20
    // J
    .word 0, 10, 11, 12
    .word 0, 1, 10, 20
    .word 0, 1, 2, 12
    .word 1, 11, 20, 21
    // L
    .word 2, 10, 11, 12
    .word 0, 10, 20, 21
    .word 0, 1, 2, 10
    .word 0, 1, 11, 21

current_type:
    .word 0
current_rot:
    .word 0

msg_block:
    .ascii "X"
msg_dot:
    .ascii "."
msg_newline:
    .ascii "\n"
msg_gameover:
    .ascii "GAME OVER\n"
msg_score:
    .ascii "Lines: "
score:
    .word 0

color_reset:  .ascii "\033[0m"
color_cyan:   .ascii "\033[36m"
color_yellow: .ascii "\033[33m"
color_purple: .ascii "\033[35m"
color_green:  .ascii "\033[32m"
color_red:    .ascii "\033[31m"
color_blue:   .ascii "\033[34m"
color_white:  .ascii "\033[37m"

.align 4
clear_screen:
    .ascii "\033[H\033[J"

.align 8
color_table:
    .quad 0
    .quad color_cyan
    .quad color_yellow
    .quad color_purple
    .quad color_green
    .quad color_red
    .quad color_blue
    .quad color_white

termios_orig:
    .zero 72
termios_new:
    .zero 72

timeout:
    .quad 0
    .quad 500000

input_buf:
    .byte 0


.text
.global _main
.align 2

_main:
    stp x29, x30, [sp, #-16]!

    mov x0, #0
    adrp x1, termios_orig@PAGE
    add x1, x1, termios_orig@PAGEOFF
    bl _tcgetattr

    adrp x0, termios_new@PAGE
    add x0, x0, termios_new@PAGEOFF
    adrp x1, termios_orig@PAGE
    add x1, x1, termios_orig@PAGEOFF
    mov x2, #72
    bl _memcpy

    adrp x0, termios_new@PAGE
    add x0, x0, termios_new@PAGEOFF
    ldr w1, [x0, #24]
    mov w2, #0x108
    bic w1, w1, w2
    str w1, [x0, #24]

    mov w3, #0
    strb w3, [x0, #48]
    strb w3, [x0, #49]

    mov x0, #0
    mov x1, #0
    adrp x2, termios_new@PAGE
    add x2, x2, termios_new@PAGEOFF
    bl _tcsetattr

    mov w20, #4
    mov w21, #0
    mov w22, #0

game_loop:
    mov x0, #1
    adrp x1, clear_screen@PAGE
    add x1, x1, clear_screen@PAGEOFF
    mov x2, #7
    mov x16, #4
    svc #0x80

    adrp x0, board@PAGE
    add x0, x0, board@PAGEOFF
    adrp x1, fixed_board@PAGE
    add x1, x1, fixed_board@PAGEOFF
    mov x2, #200
    bl _memcpy

    // ミノ描画（w21+1の値を書き込む）
    mov w8, w21
    lsl w8, w8, #2
    add w8, w8, w22
    lsl w8, w8, #4
    adrp x9, mino_data@PAGE
    add x9, x9, mino_data@PAGEOFF
    add x9, x9, w8, uxtw

    adrp x0, board@PAGE
    add x0, x0, board@PAGEOFF
    mov w1, w21
    add w1, w1, #1       // 1〜7の値

    ldr w8, [x9, #0]
    add w8, w8, w20
    strb w1, [x0, w8, uxtw]
    ldr w8, [x9, #4]
    add w8, w8, w20
    strb w1, [x0, w8, uxtw]
    ldr w8, [x9, #8]
    add w8, w8, w20
    strb w1, [x0, w8, uxtw]
    ldr w8, [x9, #12]
    add w8, w8, w20
    strb w1, [x0, w8, uxtw]

    // 描画
    mov w10, #0
    mov w11, #10

draw_loop:
    adrp x0, board@PAGE
    add x0, x0, board@PAGEOFF
    ldrb w6, [x0, w10, uxtw]

    cmp w6, #0
    b.eq print_dot

    // 色を設定
    adrp x0, color_table@PAGE
    add x0, x0, color_table@PAGEOFF
    lsl w8, w6, #3
    ldr x1, [x0, w8, uxtw]
    mov x0, #1
    mov x2, #5
    mov x16, #4
    svc #0x80

    // X表示
    adrp x1, msg_block@PAGE
    add x1, x1, msg_block@PAGEOFF
    mov x0, #1
    mov x2, #1
    mov x16, #4
    svc #0x80

    // 色リセット
    adrp x1, color_reset@PAGE
    add x1, x1, color_reset@PAGEOFF
    mov x0, #1
    mov x2, #4
    mov x16, #4
    svc #0x80

    b after_print

print_dot:
    adrp x1, msg_dot@PAGE
    add x1, x1, msg_dot@PAGEOFF
    mov x0, #1
    mov x2, #1
    mov x16, #4
    svc #0x80

after_print:
    sub w11, w11, #1
    cmp w11, #0
    b.ne next_step

    mov x0, #1
    adrp x1, msg_newline@PAGE
    add x1, x1, msg_newline@PAGEOFF
    mov x2, #1
    mov x16, #4
    svc #0x80
    mov w11, #10

next_step:
    add w10, w10, #1
    cmp w10, #200
    b.lt draw_loop

    // select待機
    sub sp, sp, #128
    mov x29, sp
    mov x0, sp
    mov x1, #0
    mov x2, #128
    bl _memset

    mov w1, #1
    str w1, [sp]

    adrp x0, timeout@PAGE
    add x0, x0, timeout@PAGEOFF
    mov x1, #0
    str x1, [x0]
    mov x1, #33920
    movk x1, #7, lsl #16
    str x1, [x0, #8]

    mov x0, #1
    mov x1, sp
    mov x2, #0
    mov x3, #0
    adrp x4, timeout@PAGE
    add x4, x4, timeout@PAGEOFF
    mov x16, #93
    svc #0x80

    add sp, sp, #128

    cmp x0, #0
    b.le do_fall

    mov x0, #0
    adrp x1, input_buf@PAGE
    add x1, x1, input_buf@PAGEOFF
    mov x2, #1
    mov x16, #3
    svc #0x80

    adrp x1, input_buf@PAGE
    add x1, x1, input_buf@PAGEOFF
    ldrb w7, [x1]

    cmp w7, #'q'
    b.eq quit_game
    cmp w7, #'a'
    b.eq move_left
    cmp w7, #'d'
    b.eq move_right
    cmp w7, #'w'
    b.eq do_rotate
    b do_fall

move_left:
    mov w8, w21
    lsl w8, w8, #2
    add w8, w8, w22
    lsl w8, w8, #4
    adrp x9, mino_data@PAGE
    add x9, x9, mino_data@PAGEOFF
    add x9, x9, w8, uxtw

    mov w3, #10

    ldr w8, [x9, #0]
    add w8, w8, w20
    udiv w6, w8, w3
    msub w6, w6, w3, w8
    cmp w6, #0
    b.eq do_fall

    ldr w8, [x9, #4]
    add w8, w8, w20
    udiv w6, w8, w3
    msub w6, w6, w3, w8
    cmp w6, #0
    b.eq do_fall

    ldr w8, [x9, #8]
    add w8, w8, w20
    udiv w6, w8, w3
    msub w6, w6, w3, w8
    cmp w6, #0
    b.eq do_fall

    ldr w8, [x9, #12]
    add w8, w8, w20
    udiv w6, w8, w3
    msub w6, w6, w3, w8
    cmp w6, #0
    b.eq do_fall

    sub w20, w20, #1
    b do_fall

move_right:
    mov w8, w21
    lsl w8, w8, #2
    add w8, w8, w22
    lsl w8, w8, #4
    adrp x9, mino_data@PAGE
    add x9, x9, mino_data@PAGEOFF
    add x9, x9, w8, uxtw

    mov w3, #10

    ldr w8, [x9, #0]
    add w8, w8, w20
    udiv w6, w8, w3
    msub w6, w6, w3, w8
    cmp w6, #9
    b.eq do_fall

    ldr w8, [x9, #4]
    add w8, w8, w20
    udiv w6, w8, w3
    msub w6, w6, w3, w8
    cmp w6, #9
    b.eq do_fall

    ldr w8, [x9, #8]
    add w8, w8, w20
    udiv w6, w8, w3
    msub w6, w6, w3, w8
    cmp w6, #9
    b.eq do_fall

    ldr w8, [x9, #12]
    add w8, w8, w20
    udiv w6, w8, w3
    msub w6, w6, w3, w8
    cmp w6, #9
    b.eq do_fall

    add w20, w20, #1
    b do_fall

do_rotate:
    add w22, w22, #1
    cmp w22, #4
    b.lt do_fall
    mov w22, #0
    b do_fall

do_fall:
    mov w8, w21
    lsl w8, w8, #2
    add w8, w8, w22
    lsl w8, w8, #4
    adrp x9, mino_data@PAGE
    add x9, x9, mino_data@PAGEOFF
    add x9, x9, w8, uxtw

    adrp x0, fixed_board@PAGE
    add x0, x0, fixed_board@PAGEOFF

    ldr w8, [x9, #0]
    add w8, w8, w20
    add w8, w8, #10
    cmp w8, #200
    b.ge fix_block
    ldrb w6, [x0, w8, uxtw]
    cmp w6, #0
    b.ne fix_block

    ldr w8, [x9, #4]
    add w8, w8, w20
    add w8, w8, #10
    cmp w8, #200
    b.ge fix_block
    ldrb w6, [x0, w8, uxtw]
    cmp w6, #0
    b.ne fix_block

    ldr w8, [x9, #8]
    add w8, w8, w20
    add w8, w8, #10
    cmp w8, #200
    b.ge fix_block
    ldrb w6, [x0, w8, uxtw]
    cmp w6, #0
    b.ne fix_block

    ldr w8, [x9, #12]
    add w8, w8, w20
    add w8, w8, #10
    cmp w8, #200
    b.ge fix_block
    ldrb w6, [x0, w8, uxtw]
    cmp w6, #0
    b.ne fix_block

    add w20, w20, #10
    b game_loop

fix_block:
    mov w8, w21
    lsl w8, w8, #2
    add w8, w8, w22
    lsl w8, w8, #4
    adrp x9, mino_data@PAGE
    add x9, x9, mino_data@PAGEOFF
    add x9, x9, w8, uxtw

    adrp x0, fixed_board@PAGE
    add x0, x0, fixed_board@PAGEOFF
    mov w1, w21
    add w1, w1, #1       // 1〜7の値で固定

    ldr w8, [x9, #0]
    add w8, w8, w20
    strb w1, [x0, w8, uxtw]
    ldr w8, [x9, #4]
    add w8, w8, w20
    strb w1, [x0, w8, uxtw]
    ldr w8, [x9, #8]
    add w8, w8, w20
    strb w1, [x0, w8, uxtw]
    ldr w8, [x9, #12]
    add w8, w8, w20
    strb w1, [x0, w8, uxtw]

    add w21, w21, #1
    cmp w21, #7
    b.lt check_lines
    mov w21, #0
    b check_lines

check_lines:
    mov w23, #19

check_line_loop:
    cmp w23, #0
    b.lt set_next

    mov w24, #0
    mov w25, #0

    adrp x0, fixed_board@PAGE
    add x0, x0, fixed_board@PAGEOFF

    mov w26, w23
    mov w3, #10
    mul w26, w26, w3

count_loop:
    ldrb w6, [x0, w26, uxtw]
    cmp w6, #0
    b.eq count_next
    add w25, w25, #1     // 0以外ならカウント
count_next:
    add w26, w26, #1
    add w24, w24, #1
    cmp w24, #10
    b.lt count_loop

    cmp w25, #10
    b.eq erase_line

    sub w23, w23, #1
    b check_line_loop

erase_line:
    mov w24, w23

shift_loop:
    cmp w24, #0
    b.eq clear_top_line

    adrp x0, fixed_board@PAGE
    add x0, x0, fixed_board@PAGEOFF

    sub w26, w24, #1
    mov w3, #10
    mul w26, w26, w3
    mul w27, w24, w3

    mov w4, #0
copy_row:
    ldrb w6, [x0, w26, uxtw]
    strb w6, [x0, w27, uxtw]
    add w26, w26, #1
    add w27, w27, #1
    add w4, w4, #1
    cmp w4, #10
    b.lt copy_row

    sub w24, w24, #1
    b shift_loop

clear_top_line:
    adrp x0, score@PAGE
    add x0, x0, score@PAGEOFF
    ldr w1, [x0]
    add w1, w1, #1
    str w1, [x0]

    adrp x0, fixed_board@PAGE
    add x0, x0, fixed_board@PAGEOFF
    mov w4, #0
    mov w6, #0
clear_top:
    strb w6, [x0, w4, uxtw]
    add w4, w4, #1
    cmp w4, #10
    b.lt clear_top

    b check_line_loop

set_next:
    mov w22, #0
    mov w20, #4

    mov w8, w21
    lsl w8, w8, #2
    lsl w8, w8, #4
    adrp x9, mino_data@PAGE
    add x9, x9, mino_data@PAGEOFF
    add x9, x9, w8, uxtw

    adrp x0, fixed_board@PAGE
    add x0, x0, fixed_board@PAGEOFF

    ldr w8, [x9, #0]
    add w8, w8, w20
    ldrb w6, [x0, w8, uxtw]
    cmp w6, #0
    b.ne game_over

    ldr w8, [x9, #4]
    add w8, w8, w20
    ldrb w6, [x0, w8, uxtw]
    cmp w6, #0
    b.ne game_over

    ldr w8, [x9, #8]
    add w8, w8, w20
    ldrb w6, [x0, w8, uxtw]
    cmp w6, #0
    b.ne game_over

    ldr w8, [x9, #12]
    add w8, w8, w20
    ldrb w6, [x0, w8, uxtw]
    cmp w6, #0
    b.ne game_over

    b game_loop

game_over:
    mov x0, #0
    mov x1, #0
    adrp x2, termios_orig@PAGE
    add x2, x2, termios_orig@PAGEOFF
    bl _tcsetattr

    mov x0, #1
    adrp x1, msg_gameover@PAGE
    add x1, x1, msg_gameover@PAGEOFF
    mov x2, #10
    mov x16, #4
    svc #0x80

    mov x0, #1
    adrp x1, msg_score@PAGE
    add x1, x1, msg_score@PAGEOFF
    mov x2, #7
    mov x16, #4
    svc #0x80

    adrp x0, score@PAGE
    add x0, x0, score@PAGEOFF
    ldr w20, [x0]

    sub sp, sp, #16
    mov w21, #0

    cmp w20, #0
    b.ne convert_loop
    mov w1, #'0'
    strb w1, [sp]
    mov w21, #1
    b print_score

convert_loop:
    cmp w20, #0
    b.eq print_score_setup
    mov w3, #10
    udiv w2, w20, w3
    msub w1, w2, w3, w20
    add w1, w1, #'0'
    strb w1, [sp, w21, uxtw]
    add w21, w21, #1
    mov w20, w2
    b convert_loop

print_score_setup:
    sub w21, w21, #1

print_score:
    cmp w21, #0
    b.lt print_newline
    ldrb w1, [sp, w21, uxtw]
    strb w1, [sp, #8]
    mov x0, #1
    add x1, sp, #8
    mov x2, #1
    mov x16, #4
    svc #0x80
    sub w21, w21, #1
    b print_score

print_newline:
    mov x0, #1
    adrp x1, msg_newline@PAGE
    add x1, x1, msg_newline@PAGEOFF
    mov x2, #1
    mov x16, #4
    svc #0x80

    add sp, sp, #16
    ldp x29, x30, [sp], #16
    mov x0, #0
    mov x16, #1
    svc #0x80

quit_game:
    mov x0, #0
    mov x1, #0
    adrp x2, termios_orig@PAGE
    add x2, x2, termios_orig@PAGEOFF
    bl _tcsetattr

    ldp x29, x30, [sp], #16
    mov x0, #0
    mov x16, #1
    svc #0x80