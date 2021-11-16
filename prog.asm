.const pwm_cycles, 100
.const cycles_in_sin, 10

;timer 0 -> generuje PWM
;timer 1 -> modyfikuje timerowi 0 jaki PWM generuje

.port ct_lbyte, 0xc0

.port ct_config0, 0xc1
.port ct_ocr0_h, 0xc2
.port ct_icr0_h, 0xc3
.port ct_tcr0_h, 0xc4

.port ct_config1, 0xc5
.port ct_ocr1_h, 0xc6
.port ct_icr1_h, 0xc7
.port ct_tcr1_h, 0xc8


.port ct_status, 0xc9
.port ct_int_mask, 0xca

;gpio:
.port gpio_b_in, 0x21
.port gpio_b_out, 0x21

.port gpio_d_in, 0x23
.port gpio_d_out, 0x23
.port gpio_d_dir, 0x2b


.reg sF, sin_location



.dseg
sin: .db 50,79,98,98,79,21,2,2,21


; 392 415 440 466 493 523 554 587 522 659 698 739 784 830 932 987 [Hz]
;the following values are 10^6 / f
notes: .dw 0x9f7, 0x969, 0x8e0, 0x861, 0x7ec, 0x778, 0x70d, 0x6a7, 0x77b, 0x5ed, 0x598, 0x549, 0x4fb, 0x4b4, 0x430, 0x3f5

.cseg
main:
;set timer1 data:
load s0, 0b00101000
out s0, ct_config1
;set timer0 data:
load s0, 0b00110000
out s0, ct_config0
;enable interrupts from timer1 overflow:
load s0, 0b01000000
out s0, ct_int_mask

;set gpio at D to out:



jump main

;s0 must be filled with the number representing number of note
setFrequency:

ret

serve_int:

reti

.cseg 1023
jump serve_int