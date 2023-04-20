; this program tests the 7seg output
; the segment patterns are located at out-of-bounds addr 19-28 (0-9)
; the value "19" is stored at out-of-bounds addr "18"
; this means you can load the value you want to display to ACC,
; then ADD 19, then LDAR to get the pattern you want
; we'll store a counter at address 16
0: LDA 16
1: ADD 18
2: LDAR
3: STA 17
4: LDA 16
5: ADDI 1
6: STA 16
7: CLR
8: JMP
16: DATA 0