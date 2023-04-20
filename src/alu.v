`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: New York University
// Engineer: ChatGPT GPT-4 Mar 23 version; Hammond Pearce (prompting)
// 
// Last Edited Date: 04/19/2023
//////////////////////////////////////////////////////////////////////////////////


module alu (
    input wire [7:0] A,
    input wire [7:0] B,
    input wire [3:0] opcode,
    output reg [7:0] Y
);

always @(*) begin
    case (opcode)
        4'b0000: Y = A + B;               // ADD
        4'b0001: Y = A - B;               // SUB
        4'b0010: Y = A & B;               // AND
        4'b0011: Y = A | B;               // OR
        4'b0100: Y = A ^ B;               // XOR
        4'b0101: Y = A << 1;              // SHL
        4'b0110: Y = A >> 1;              // SHR
        4'b0111: Y = A << 4;              // SHL4
        4'b1000: Y = {A[6:0], A[7]};      // ROL
        4'b1001: Y = {A[0], A[7:1]};      // ROR
        4'b1010: Y = A - 1;               // DEC
        4'b1011: Y = ~A;                  // INV
        //4'b1100: Y = 8'b00000000;         // CLR
        default: Y = 8'b00000000;         // Default case: CLR (undefined operation)
    endcase
end

endmodule
