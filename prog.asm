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
.port gpio_b_dir, 0x29

.port gpio_d_in, 0x23
.port gpio_d_out, 0x23
.port gpio_d_dir, 0x2b

.port int_status, 0xe0
.port int_mask, 0xe1

.reg sF, sin_location
.reg sE, currentNote

.dseg
;sin: .db 50,79,98,98,79,50,21,2,2,21
sin: .db 50, 51, 53, 53, 51, 50, 48, 47, 47, 48

; 392 415 440 466 493 523 554 587 522 659 698 739 784 830 932 987 [Hz]
;the following values are 10^6 / f
notes: .dw 0x9f7, 0x969, 0x8e0, 0x861, 0x7ec, 0x778, 0x70d, 0x6a7, 0x77b, 0x5ed, 0x598, 0x549, 0x4fb, 0x4b4, 0x430, 0x3f5

.cseg
main:
eint
; - - - - - - - - - Timer setup:

;set timer0 data:
load s0, 0b00110000
out s0, ct_config0

;set timer0 ocr:
load s0, 100
out s0, ct_lbyte
load s0, 0
out s0, ct_ocr0_h
/;
load s0, 75
out s0, ct_lbyte
load s0, 0
out s0, ct_icr0_h
;/

;enable interrupts from timer1 overflow:
load s0, 0b00010000
out s0, ct_int_mask
load s0, 0b00100000
out s0, int_mask

load s0, 0b00001000
out s0, gpio_d_dir

load s0, 0b00001000
out s0, gpio_d_out

load s0, 0b00001111
out s0, gpio_b_dir


; - - - - - - - - - initialize sin_location
load sin_location, 9

load s0, 15

mainloop:

; col
load s2, 0b00010000
load s5, 0
load s6, 0
columnloop:
load s3, s2
xor s3, 0xff
out s3, gpio_b_out
in s4, gpio_b_in
xor s4, 0xff
sr0 s4
sr0 s4
sr0 s4
sr0 s4
; row:
load s7, 0b00001000
rowloop:
add s6, 1
test s4, s7
jump z, if_dont_set
jump endloop
if_dont_set:
sr0 s7
jump nz, rowloop

sr0 s2
jump nz, columnloop
endloop:
comp s6, 16
jump z, if_not_pushed
load s0, s6
comp s0, currentNote
jump z, mainloop
load currentNote, s0
call setFrequency
jump mainloop
if_not_pushed:
call switchOff

jump mainloop

;s0 must be filled with the number representing number of note. Number '16' in s0 denotes no note (no note is going to be played)
setFrequency:
sl1 s0
add s0, notes
fetch s1, s0
out s1, ct_lbyte
sub s0, 1
fetch s1, s0
out s1, ct_ocr1_h
;set timer1 data:
load s0, 0b00101000
out s0, ct_config1
ret

switchOff:
load s0, 0
out s0, ct_config1
ret

serve_int:
in s0, int_status
;test s0, 0b00100000
;jump z, serve_handleGPIO
serve_handleTimer:
fetch s0, sin_location
load s1, 0
out s0, ct_lbyte
out s1, ct_icr0_h

sub sin_location, 1
;was there an overflow, loop it back to high values
jump nc, end_looping_location
load sin_location, 9
end_looping_location:

serve_handleGPIO:
;is there anything to do here?
load s0, 0
out s0, ct_status
out s0, int_status
reti

.cseg 1023
jump serve_int