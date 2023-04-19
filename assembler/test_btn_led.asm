; this program tests the btn and LEDs
; after each BTN is low then BTN is high it will toggle the LEDs between 
; two values
; BTNs and LEDS are at address 17, btn at LSB
0: LDA 17 ; load the btn and LEDS
1: AND 16 ; mask the btn
2: BNE_BWD ; if btn&1 is not zero then branch back to 0
3: LDA 17 ; load the btn and LEDS
4: AND 16 ; mask the btn
5: BEQ_BWD ; if btn&1 is zero then branch back to 3
;
; the button has now done a transition from low to high
;
6: LDA 14 ; load the counter toggle
7: XOR 16 ; toggle the counter using the btn mask
8: STA 14 ; store the counter value
9: ADDI 14 ; get the counter value offset (if 0, will be 14 (which is 0), if 1, 15)
10: LDAR ; load the counter LED pattern
11: STA 17 ; store the LED pattern
12: CLR
13: JMP
;
; data
;
14: DATA 0; toggle and LED pattern 0
15: DATA 24; LED pattern of ON (test for led_out=value 12, since 24>>1 == 12)
16: DATA 1 ; btn and counter mask
