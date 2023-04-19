; this program will load the value at address 15, decrement it in a loop till its zero, then 
; starting from 0b11111111, overflow it, then increment once more to get to 1
; tests: M[15] = 0
;        M[14] = 1
0: LDA 15       ; load value from address 10 to accumulator
1: BEQ_FWD      ; if accumulator is zero, skip to 4
2: DEC          ; decrement the accumulator
3: STA 15       ; store accumulator value at address 10
4: BNE_BWD      ; if accumulator is not zero, jump back to 2
5: ADDI 15      ; the accumulator is set to 15
6: SHL4
7: ADDI 15      ; the accumulator is now 0b11111111
8: ADDI 1
9: STA 14       ; store accumulator at 14
10: BEQ_BWD     ; jump back to 8 if zero
11: HLT

15: DATA 16     ; store the initial value (16) at address 10
