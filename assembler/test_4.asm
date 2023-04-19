; this program tests all data manipulation instructions except LDAR
; check
0: LDA 16       ; load 10 from M[16]
1: SHL 
2: STA 0       ; M[0] becomes 20
3: SHR
4: STA 1       ; M[1] becomes 10
5: SHL4 
6: STA 2       ; M[2] becomes 0b10100000 (160)
7: ROL          ;
8: STA 3       ; M[3] becomes 0b01000001 (65)
9: ROR
10: STA 4      ; M[4] becomes 160
11: DEC         
12: STA 5      ; M[5] becomes 159
13: CLR         
14: INV
15: STA 6      ; M[6] becomes 255
16: DATA 10  