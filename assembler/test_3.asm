; this program tests all variable-data operands
0: LDA 16       ; load 10 from M[16]
1: ADDI 1       ; add 1 to 10
2: STA 0        ; set M[0] to 11
3: ADD 16       ; add M[16](10) to 11 = 21
4: STA 1        ; set M[1] to 21
5: SUB 16       ; sub M[16](10) from 21 = 11
6: STA 2        ; set M[2] to 11
7: AND 15       ; AND M[15](0xF) to 11(0b1011), should become 11
8: STA 3        ; set M[3] to 11
9: OR 14        ; OR M[14](4) to 11, should become 15
10: STA 4       ; set M[4] to 15
11: XOR 13      ; XOR M[13](ff) with 15, should become f0
12: STA 5       ; set M[5] to f0
13: HLT
14: DATA 4
15: DATA 15
16: DATA 10